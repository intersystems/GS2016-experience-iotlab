/// A service responsible for starting, monitoring and stopping the Java Gateway Server in a production.
/// Also instantiates Java services associated with instances of Ens.Java.BusinessService found
/// within the production.
Class EnsLib.JavaGateway.Initiator Extends EnsLib.JavaGateway.Service
{

Parameter pSuperClassBS As %String [ Internal ] = "Ens.Java.BusinessService";

Parameter pSuperClassBO As %String [ Internal ] = "Ens.Java.BusinessOperation";

Parameter pExtremeJarFile As %String [ Internal ] = "cache-extreme-2.0.0.jar";

Property JavaGateway As EnsLib.JavaGateway.JavaGateway [ Internal ];

ClassMethod OnProductionStart(pConfigName As %String) As %Status
{
	// prettify some of our settings
	Set ^CacheMsg("EnsColumns","en-us","JavaHome") = "Java Home"
	Set ^CacheMsg("EnsColumns","en-us","JavaDebug") = "Java Debug"

	Quit ##super(pConfigName)
}

Method OnInit() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.StatusException
	
	Set tSC = ##super()
	Quit:$$$ISERR(tSC) tSC

	#dim tProdName As %String = ##class(Ens.Director).GetActiveProductionName()
	Quit:(tProdName="") $$$ERROR($$$GeneralError, "GetActiveProductionName()")

	#dim tProd As Ens.Config.Production = ##class(Ens.Config.Production).%OpenId(tProdName)
	Quit:'$ISOBJECT(tProd) $$$ERROR($$$GeneralError, "Production '"_tProdName_"'")

	// connect to the Java Gateway
	#dim tJavaGateway as EnsLib.JavaGateway.JavaGateway
	#dim tEndpoint As %String = ..Address_";"_..Port_";"_$NAMESPACE
	Set tSC = ..ConnectGateway(tEndpoint, .tJavaGateway)
	Quit:$$$ISERR(tSC) tSC
	Set ..JavaGateway = tJavaGateway
	
	// add required Cache Extreme to class path
	#dim tExtremeDir As %String = ##class(%File).ManagerDirectory()_"../dev/java/lib/"_..JDKVersion_"/"
	#dim tExtremeJarFile As %String = ##class(%File).NormalizeFilename(..#pExtremeJarFile, tExtremeDir)
	Quit:'##class(%File).Exists(tExtremeJarFile) $$$ERROR($$$JarFileDoesNotExist, tExtremeJarFile)

	#dim tClassPaths As %ListOfDataTypes = ##class(%ListOfDataTypes).%New()
	Set:$$$ISOK(tSC) tSC = tClassPaths.Insert(tExtremeJarFile)
	Quit:$$$ISERR(tSC) tSC
	
	Set tSC = ..JavaGateway.%AddToCurrentClassPath(tClassPaths)
	Quit:$$$ISERR(tSC) tSC
	
	// import generic implementation of Java Business Hosts
	Quit:$$$ISERR(tSC) tSC	
	Set tSC = ..JavaGateway.%Import("com.intersys.gateway.ProductionConcrete", .tJavaClasses)
	Quit:$$$ISERR(tSC) tSC	
	Set tSC = ..JavaGateway.%Import("com.intersys.gateway.BusinessOperationConcrete", .tJavaClasses)
	Quit:$$$ISERR(tSC) tSC	

	// find and start up all of the Java services of type Ens.Java.BusinessService
	// which are currently enabled
	#dim tConfigItems As list of Ens.Config.Item = tProd.Items
	#dim tConfigItemsCount As %Integer = tConfigItems.Count()
	For i=1:1:tConfigItemsCount {
		Set tConfigItem = tConfigItems.GetAt(i)
		Set tClassName = tConfigItem.ClassName
		#dim tEnabled As %Boolean = tConfigItem.Enabled
		#dim tTargetClass As %Boolean = $CLASSMETHOD(tClassName, "%Extends", ..#pSuperClassBS)
		If tEnabled && tTargetClass {
			Set tSC = $this.DoLogin(tConfigItem, ..JavaGateway)
			Return:$$$ISERR(tSC) tSC
		}
	}

	Quit $$$OK
}

Method OnTearDown() As %Status
{
	// find and shut down all of the Java services of type Ens.Java.BusinessService
	// which are currently enabled
	
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.StatusException

	#dim tProdName As %String = ##class(Ens.Director).GetActiveProductionName()
	Quit:(tProdName="") $$$ERROR($$$GeneralError, "GetActiveProductionName()")

	#dim tProd As Ens.Config.Production = ##class(Ens.Config.Production).%OpenId(tProdName)
	Quit:'$ISOBJECT(tProd) $$$ERROR($$$GeneralError, "Error opening production '"_tProdName_"'")

	#dim tConfigItems As list of Ens.Config.Item = tProd.Items
	#dim tConfigItemsCount As %Integer = tConfigItems.Count()

	For i=1:1:tConfigItemsCount {
		#dim tConfigItem As Ens.Config.Item = tConfigItems.GetAt(i)
		#dim tClassName As %String = tConfigItem.ClassName
		#dim tEnabled As %Boolean = tConfigItem.Enabled
		#dim tTargetClass As %Boolean = $CLASSMETHOD(tClassName, "%Extends", ..#pSuperClassBS)
		If tEnabled && tTargetClass {
			Set tSC = $this.DoLogout(tConfigItem, ..JavaGateway)
			If $$$ISERR(tSC) {
				// don't bail out here: 1) other items to stop, and 2) want to ensure
				// that ##super() gets a chance to shut down the JVM
				$$$LOGERROR($system.Status.GetErrorText(tSC))
			}
		}
	}
	
	Quit ##super()
}

/// Notify the Java service associated with a given configuration item that it has
/// been enabled (either explicitly or along with the production).
ClassMethod DoLogin(pConfigItem As Ens.Config.Item, pJavaGateway As EnsLib.JavaGateway.JavaGateway) As %Status [ Internal ]
{
	// we need to gather a boatload of information for the Java service, most of which
	// allows it to communicate back with Ensemble
	
	#dim tSC As %Status = $$$OK
	
	#dim tConfigName As %String = pConfigItem.Name
	#dim tClassName As %String = pConfigItem.ClassName

	// namespace
	#dim tNamespace As %String = $NAMESPACE
	
	// node
	#dim tNodeName As %String = ##class(%SYS.System).GetNodeName()

	// default port (taking special care to restore Namespace)
	#dim tDefaultPort As %Integer
	try {
		ZN "%SYS"
		#dim tProperties As %String
		Set tSC = ##Class(Config.Startup).Get(.tProperties)
		Return:$$$ISERR(tSC) tSC   
		Set tDefaultPort = tProperties("DefaultPort")
		Return:'$DATA(tDefaultPort) $$$ERROR($$$DataMissing, "Properties(""DefaultPort"")")
	} catch ex {
		ZN tNamespace
		Return ex.AsStatus()
	}
	ZN tNamespace
	
	// parameters
	#dim tSendMethod As %String = $PARAMETER(tClassName, "SendMethod")
	Quit:(tSendMethod="") $$$ERROR($$$ParameterNameRequired, "SendMethod")
	#dim tSettingMethod As %String = $PARAMETER(tClassName, "SettingMethod")
	Quit:(tSettingMethod="") $$$ERROR($$$ParameterNameRequired, "SettingMethod")
	#dim tLogMethod As %String = $PARAMETER(tClassName, "LogMethod")
	Quit:(tLogMethod="") $$$ERROR($$$ParameterNameRequired, "LogMethod")
	#dim tStatusMethod As %String = $PARAMETER(tClassName, "StatusMethod")
	Quit:(tStatusMethod="") $$$ERROR($$$ParameterNameRequired, "StatusMethod")
	#dim tJavaClass As %String = $PARAMETER(tClassName, "JavaClass")
	Quit:tJavaClass="" $$$ERROR($$$ParameterDoesNotExist, "JavaClass")
	#dim tJarFile As %String = $PARAMETER(tClassName, "JarFile")
	Quit:tJarFile="" $$$ERROR($$$ParameterDoesNotExist, "JarFile")

	// credentials and database location
	#dim tSettings As list of Ens.Config.Setting = pConfigItem.Settings
	#dim tSettingsLen As %Integer = tSettings.Count()
	#dim tUsername As %String = ""
	#dim tPassword As %String = ""
	#dim tLocation As %String = ""
	For j = 1:1:tSettingsLen {
		#dim tSetting As Ens.Config.Setting = tSettings.GetAt(j)
		#dim tSettingName As %String = tSetting.Name
		#dim tSettingValue As %String = tSetting.Value
		If tSettingName = "Credentials" {
			#dim tCredentials As Ens.Config.Credentials
			Set tCredentials = ##class(Ens.Config.Credentials).%OpenId(tSettingValue)
			Return:'$ISOBJECT(tCredentials) $$$ERROR($$$GetCredentialsFailed, tSettingValue)
			Set tUsername = tCredentials.Username
			Return:(tUsername="") $$$ERROR($$$GetCredentialsNoUsername, tSettingValue)
			Set tPassword = tCredentials.Password
		} ElseIf tSettingName = "Location" {
			Set tLocation = tSettingValue
		}
	}
	If tLocation = "" {
		Set tLocation = ##class(%GlobalStreamAdaptor).#STOREGLOBALNAME
		Return:(tLocation="") $$$ERROR($$$StorageNameRequired, tSettingValue)
	}
	// When using System Default Settings, we have to widen our search 
	If tUsername = "" {
	                Set tSC = ..GetSetting(pConfigItem.Name, "Credentials", .tSettingValue)
	                Quit:$$$ISERR(tSC) tSC
	                Set tCredentials = ##class(Ens.Config.Credentials).%OpenId(tSettingValue)
	                Return:'$ISOBJECT(tCredentials) $$$ERROR($$$GetCredentialsFailed, tSettingValue)
	                Set tUsername = tCredentials.Username
	                Return:(tUsername="") $$$ERROR($$$GetCredentialsNoUsername, tSettingValue)
	                Set tPassword = tCredentials.Password
	}

	// Test
	set x=1
	
	// create an argument list
	#dim argv As %ListOfDataTypes = ##class(%ListOfDataTypes).%New()
	Set tSC = argv.Clear()
	Set:$$$ISOK(tSC) tSC = argv.Insert("-namespace")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tNamespace)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-port")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tDefaultPort)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-configName")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tConfigName)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-nodeName")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tNodeName)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-username")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tUsername)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-password")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tPassword)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-location")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tLocation)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-className")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tClassName)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-sendMethod")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tSendMethod)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-settingMethod")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tSettingMethod)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-logMethod")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tLogMethod)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-statusMethod")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tStatusMethod)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-jarFile")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tJarFile)
	Set:$$$ISOK(tSC) tSC = argv.Insert("-javaClass")
	Set:$$$ISOK(tSC) tSC = argv.Insert(tJavaClass)
	Quit:$$$ISERR(tSC) tSC

	$$$LOGINFO("Starting config item "_tConfigName)

	Set tSC = ##class(com.intersys.gateway.ProductionConcrete).initBS(pJavaGateway, argv)
	Quit:$$$ISERR(tSC) $$$ERROR($$$ErrorExecutingJavaCommand, "initBS()"_" returned: """_tSC_"""")

	Quit $$$OK
}

/// Notify the Java service associated with a given configuration item that it has
/// been disabled (either explicitly or along with the production).
ClassMethod DoLogout(pConfigItem As Ens.Config.Item, pJavaGateway As EnsLib.JavaGateway.JavaGateway) As %Status [ Internal ]
{
	Set tSC = ##class(com.intersys.gateway.ProductionConcrete).tearDownBS(pJavaGateway, pConfigItem.Name)
	Quit:$$$ISERR(tSC) $$$ERROR($$$ErrorExecutingJavaCommand, "tearDownBS()"_" returned: """_tSC_"""")

	Quit $$$OK
}

/// Generates a Ens.Java.BusinessService subclass suitable for adding to a Production
ClassMethod GenerateBusinessService(pJarFile As %String, pJavaClass As %String, pSubClassName As %String) As %Status
{
	#dim tSC As %Status = $$$OK

	Set tSC = ..GenerateBusinessHost(pJarFile, pJavaClass, ..#pSuperClassBS, pSubClassName)
	Quit:$$$ISERR(tSC) tSC

	Quit tSC
}

/// Generates a Ens.Java.BusinessOperation subclass suitable for adding to a Production
ClassMethod GenerateBusinessOperation(pJarFile As %String, pJavaClass As %String, pSubClassName As %String) As %Status
{
	#dim tSC As %Status = $$$OK

	Set tSC = ..GenerateBusinessHost(pJarFile, pJavaClass, ..#pSuperClassBO, pSubClassName)
	Quit:$$$ISERR(tSC) tSC

	Quit tSC
}

/// Generates a subclass of the 'pSuperClassName' and then augments it with configuration settings
/// found in the specified Java service
ClassMethod GenerateBusinessHost(pJarFile As %String, pJavaClass As %String, pSuperClassName As %String, pSubClassName As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	// find an EnsLib.JavaGateway.Service
	#dim tGatewayConfigItem As Ens.Config.Item
	Set tSC = ..FindConfigItem("EnsLib.JavaGateway.Service", .tGatewayConfigItem)
	Quit:$$$ISERR(tSC) tSC
	#dim tGatewayConfigName As %String = tGatewayConfigItem.Name
	
	// get Address
	#dim tAddress As %String = ""
	Set tSC = ..GetSetting(tGatewayConfigName, "Address", .tAddress)
	Quit:$$$ISERR(tSC) tSC
	
	// get Port
	#dim tPort As %String = ""
	Set tSC = ..GetSetting(tGatewayConfigName, "Port", .tPort)
	Quit:$$$ISERR(tSC) tSC
	
	// get JavaGateway
	#dim tEndpoint As %String = tAddress_";"_tPort_";"_$NAMESPACE
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway;
	Set tSC = ..ConnectGateway(tEndpoint, .tJavaGateway)
	Quit:$$$ISERR(tSC) tSC

	// import custom implementations of Java Business Hosts
	// (expressly to look for Ensemble settings candidates)
	//
	// verify JAR file exists
	Quit:'##class(%File).Exists(pJarFile) $$$ERROR($$$JarFileDoesNotExist, pJarFile)
	// verify JAR file contains specified class
	Set tSC = tJavaGateway.%GetAllClasses(pJarFile, .tJavaClasses)
	Quit:$$$ISERR(tSC) tSC
	#dim tClassCount As %Integer = tJavaClasses.Count()
	Set tSC = $$$ERROR($$$ClassDoesNotExist, pJavaClass)
	For i=1:1:tClassCount {
		#dim tClassName As %String = tJavaClasses.GetAt(i)
		If tClassName=pJavaClass {
			Set tSC = $$$OK
			Quit
		}
	}
	Quit:$$$ISERR(tSC) tSC
	// do the import
	$$$LOGINFO("Importing "_pJarFile)
	Set tSC = tJavaGateway.%Import(pJarFile, .tJavaClasses)
	Quit:$$$ISERR(tSC) tSC	

	// create subclass of the COS-side Business Host
	#dim tSubClass As %Dictionary.ClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
	Set tSubClass.Name = pSubClassName
	Set tSubClass.Super = pSuperClassName
	Set tSubClass.GeneratedBy = $CLASSNAME()
	Set tSubClass.ClassVersion = 25
	
	// from here on out we use tSubclass.Name instead of pSubClassName because
	// %Dictionary.ClassDefinition may have altered it (e.g. prepended "User.")
		
	// add JarFile parameter
	#dim tJarFile As %Dictionary.ParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
	Set tJarFile.Name = "JarFile"
	Set tJarFile.Default = pJarFile
	Do tSubClass.Parameters.Insert(tJarFile)

	// add JavaClass parameter
	#dim tJavaClass As %Dictionary.ParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
	Set tJavaClass.Name = "JavaClass"
	Set tJavaClass.Default = pJavaClass
	Do tSubClass.Parameters.Insert(tJavaClass)
	
	// if we found Ensemble settings candidates, add them here
	#dim tSettings As %String = $PARAMETER(pJavaClass, "SETTINGS")
	If tSettings '= "" {
	
		// add SETTINGS parameter
		#dim tParam As %Dictionary.ParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
		Set tParam.Name = "SETTINGS"
		Set tParam.Default = tSettings
		Do tSubClass.Parameters.Insert(tParam)

		// add a property for each member of SETTINGS
		For i = 1:1:$LENGTH(tSettings, ",") {
			#dim tSetting As %String = $PIECE(tSettings, ",", i)

			#dim tProp As %Dictionary.PropertyDefinition
			Set tProp = ##class(%Dictionary.PropertyDefinition).%New()
			Set tProp.Name = tSetting
			Set tProp.Type = "%String"
			Set tSC = tProp.Parameters.SetAt(255, "MAXLEN")
			Return:$$$ISERR(tSC) tSC	
			Set tSC = tSubClass.Properties.Insert(tProp)
			Return:$$$ISERR(tSC) tSC
		}
	}
	
	// can't save without deleting first
	If tSubClass.%ExistsId(tSubClass.Name) {
		
		// make sure we're deleting a class we previously generated
		#dim tExisting As %Dictionary.ClassDefinition
		Set tExisting = ##class(%Dictionary.ClassDefinition).%OpenId(tSubClass.Name)
		Quit:'$ISOBJECT(tExisting) $$$ERROR($$$GeneralError, "Unable to find/open class "_tSubClass.Name)
		
		If '(tSubClass.Super=tExisting.Super)||'(tSubClass.GeneratedBy=tExisting.GeneratedBy) {
			Quit $$$ERROR($$$GeneralError, "Class "_tSubClass.Name_" already exists; choose another name")
		}

		Set tSC = tSubClass.%DeleteId(tSubClass.Name)
		Quit:$$$ISERR(tSC) tSC
	}

	// save and compile
	Set tSC = tSubClass.%Save()
	Quit:$$$ISERR(tSC) tSC
	
	// need to suppress output via "-d" else Zen complains
	Set tSC = $System.OBJ.Compile(tSubClass.Name, "-d")
	Quit:$$$ISERR(tSC) tSC

	Quit tSC
}

/// Returns the first config item which represents an instance of the passed-in class
ClassMethod FindConfigItem(pClassName As %String, Output pConfigItem As Ens.Config.Item) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.StatusException

	#dim tProdName As %String = ##class(Ens.Director).GetActiveProductionName()
	Quit:(tProdName="") $$$ERROR($$$GeneralError, "GetActiveProductionName()")

	#dim tProd As Ens.Config.Production = ##class(Ens.Config.Production).%OpenId(tProdName)
	Quit:'$ISOBJECT(tProd) $$$ERROR($$$GeneralError, "Production '"_tProdName_"'")

	#dim tConfigItems As list of Ens.Config.Item = tProd.Items
	#dim tConfigItemsCount As %Integer = tConfigItems.Count()

	for i=1:1:tConfigItemsCount {
		#dim tConfigItem As Ens.Config.Item = tConfigItems.GetAt(i)
		#dim tClassName As %String = tConfigItem.ClassName
		#dim tTargetClass As %Boolean = $CLASSMETHOD(tClassName, "%Extends", pClassName)
		If tTargetClass {
			Set pConfigItem = tConfigItem
			Return $$$OK
		}
	}

	Quit $$$ERROR($$$GeneralError, "No config items of type "_pClassName_" found")
}

/// Invoked when the Enabled state of an Ens.JavaBusinessService has changed.
/// Determines the new state and notifies the corresponding Java service.
ClassMethod UpdateBusinessService(pConfigItem As Ens.Config.Item) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tConfigName As %String = pConfigItem.Name

	// find an EnsLib.JavaGateway.Service
	#dim tGatewayConfigItem As Ens.Config.Item
	Set tSC = ..FindConfigItem("EnsLib.JavaGateway.Service", .tGatewayConfigItem)
	Quit:$$$ISERR(tSC) tSC
	#dim tGatewayConfigName As %String = tGatewayConfigItem.Name
	
	// get Address
	#dim tAddress As %String = ""
	Set tSC = ..GetSetting(tGatewayConfigName, "Address", .tAddress)
	Quit:$$$ISERR(tSC) tSC
	
	// get Port
	#dim tPort As %String = ""
	Set tSC = ..GetSetting(tGatewayConfigName, "Port", .tPort)
	Quit:$$$ISERR(tSC) tSC
	
	#dim tEndpoint As %String = tAddress_";"_tPort_";"_$NAMESPACE
	#dim tJavaGateway as EnsLib.JavaGateway.JavaGateway;
	Set tSC = ..ConnectGateway(tEndpoint, .tJavaGateway)
	Quit:$$$ISERR(tSC) tSC

	// notify Java about the state change
	#dim tIsEnabled As %Boolean = pConfigItem.Enabled
	If tIsEnabled {
		Set tSC = ..DoLogin(pConfigItem, tJavaGateway)
	} Else {
		Set tSC = ..DoLogout(pConfigItem, tJavaGateway)
	}
	
	Quit tSC
}

ClassMethod GetSetting(pConfigName As %String, pSettingName As %String, Output pSettingValue As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	
	#dim tData
	#dim tMetaData
	Set tSC = ##class(EnsPortal.Utils).ItemSettings(pConfigName, .tData, .tMetaData)
	Quit:$$$ISERR(tSC) tSC
	
	#dim tNameCol As %Integer = $LISTFIND(tMetaData, "Name")
	Quit:'tNameCol $$$ERROR($$$GeneralError, "Column not found: Name")

	#dim tValueCol As %Integer = $LISTFIND(tMetaData, "Value")
	Quit:'tValueCol $$$ERROR($$$GeneralError, "Column not found: Value")
	
	#dim tCtx As %String = ""
	For {
		Set tCtx = $Order(tData(tCtx))
		Quit:tCtx=""
		If $LISTGET(tData(tCtx),tNameCol) = pSettingName {
			Set pSettingValue = $LISTGET(tData(tCtx),tValueCol)
			Return tSC
		}
	}
	
	Set tSC = $$$ERROR($$$GeneralError, "Setting not found: "_pSettingName)
	Quit tSC
}

}
