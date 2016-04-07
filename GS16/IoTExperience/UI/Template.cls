Class GS16.IoTExperience.UI.Template Extends %ZEN.Mojo.Component.contentTemplate [ ProcedureBlock ]
{

Parameter DOMAIN = "GS16IoTExperience";

/// Server-side method to provide content to JSON providers.
/// <var>pProviderName</var> is the name of the provider.
/// <var>pKey</var> is an app-defined key that is used to indicate which content is to be served.
/// <var>pCriteria</var>is an object containing search criteria. This is used for searching.
/// <var>pParms</var> is an array of additional parameters from the JSON provider. (not current used).
/// <var>pObject</var> is the object that will be served to the client in JSON format.
/// <var>pLoad</var> is true is this is called when the page is first being served. In this case, this method will be 
/// called even though there may a client-side method used to load the content.
ClassMethod %OnGetJSONContent(pProviderName As %String, pKey As %String, ByRef pParms, Output pObject2 As %RegisteredObject, pCriteria As %RegisteredObject, pLoad As %Boolean = 0) As %Status
{
	#Dim tFan=""
	#Dim tTempInside=0
	#Dim tDoor=0

    // The standard technique is to have an outermost if/elseif construct  
    // based on the pProviderName argument; in this case there is only one 
    // possible value for pProviderName.
    if (pProviderName = "data") {
        
        // Within a pProviderName branch, the standard technique is to have an 
        // if/elseif construct based on the key argument.
        // In this case, there are no keys, so there is no need to branch

        // Create ZEN proxy object to configure chart
        set pObject = ##class(%ZEN.proxyObject).%New()        
		set pObject.options=..CreateChart("Technical details", "Temperature (???C))","Fan RPM")
		
		// define series
		set tSeries1=##class(%ZEN.proxyObject).%New()
		set tSeries1.name="Fan RPM"
		set tSeries1.data=##class(%ListOfDataTypes).%New()
		set tSeries1.yAxis=1
		Set tSeries1.color="rgb(81,79,120)"
		set tTooltip=##class(%ZEN.proxyObject).%New()
		set tTooltip.valueSuffix=" RPM"	
		set tSeries1.tooltip=tTooltip	
		set tSeries1.connectNulls=1
		
		set tSeries2=##class(%ZEN.proxyObject).%New()
		set tSeries2.name="Temperature"
		set tSeries2.data=##class(%ListOfDataTypes).%New()
		Set tSeries2.color="rgb(66,160,123)"
		set tTooltip=##class(%ZEN.proxyObject).%New()
		set tTooltip.valueSuffix=" ???C"	
		set tSeries2.tooltip=tTooltip
		set tSeries1.connectNulls=1	

		set tSeries3=##class(%ZEN.proxyObject).%New()
		set tSeries3.name="Text"
		set tSeries3.data=##class(%ListOfDataTypes).%New()
		Set tSeries3.color="red"
					
		// Get data and populate data series
		
		// Get start time
		&sql(select max(timestamp) into :tMaxTS from iot_data.sensorvalues)
		//set tMaxTS="2016-02-22 16:00:00"
		
		// Set interval length (minutes)
		set tInterval=1
		
		// Define number of intervals to be shown
		set tNumberOfIntervals=10
		
		#Dim tSS as %SQL.Statement
		#Dim tRS as %SQL.StatementResult
		
		set tSS=##class(%SQL.Statement).%New()
		
		set tSQL="SELECT IntervalNo, HHMM, round(avg(COALESCE(numVALUE,0)),0) as AvgValue,max(COALESCE(numVALUE,0)) as maxValue, count(numValue) as NumberOfValues "
		set tSQL=tSQL_"FROM iot_data.SP_Intervals(?,?,?) AS Intervals "
		set tSQL=tSQL_"LEFT OUTER JOIN (SELECT "
		set tSQL=tSQL_"CAST(""Value"" AS NUMERIC) AS numValue, "
		set tSQL=tSQL_"IoT_Data.SP_GetIntervalNo(""Timestamp"",?,?) As TSInterval " 
		set tSQL=tSQL_"FROM IoT_Data.Sensorvalues "
		set tSQL=tSQL_"where Sensor=? "
		set tSQL=tSQL_") as tsdata ON Intervals.IntervalNo=tsdata.TSInterval "
		set tSQL=tSQL_"GROUP BY IntervalNo "
		set tSQL=tSQL_"order by IntervalNo desc"

		set sc=tSS.%Prepare(tSQL)
		
		// Get aggregated data for fan
		set tSensor="fan"
		set tRS=tSS.%Execute(tMaxTS,tInterval,tNumberOfIntervals,tMaxTS,tInterval,tSensor)
	
		
		set i=0
		while tRS.%Next() {
			set i=i+1
			
			set tValue=tRS.%Get("AvgValue")
			
			// Use first data set to create categories for x-axis
			set tHHMM=tRS.%Get("HHMM")
			do pObject.options.xAxis.categories.Insert($e(tHHMM,1,2)_":"_$e(tHHMM,3,4))
			
			set tPoint=##class(%ZEN.proxyObject).%New()
			
			if tValue>0 {
				
				set tPoint.y=tValue+0
				set tName="#readings:"_tRS.%Get("NumberOfValues")_", timeslot "
				set tName=tName_tHHMM
				set tPoint.name=tName
				
				do tSeries1.data.Insert(tValue)			
			} else {

				
				do tSeries1.data.Insert("")	
			}
		}
		
		set tSensor="temperature/inside"
		set tRS=tSS.%Execute(tMaxTS,tInterval,tNumberOfIntervals,tMaxTS,tInterval,tSensor)
		
		set i=0
		while tRS.%Next() {
			set i=i+1
			
			set tValue=tRS.%Get("AvgValue")

			set tPoint=##class(%ZEN.proxyObject).%New()
			set tPoint.y=tValue+0
			
			set tName="#readings:"_tRS.%Get("NumberOfValues")_", timeslot "
			set tName=tName_tRS.%Get("HHMM")
			set tPoint.name=tName
			
			do tSeries2.data.Insert(tPoint)
		}

		// Fertige Serien in Diagramm einf???gen
		set pObject.options.series=##class(%ListOfObjects).%New()
		do pObject.options.series.Insert(tSeries1)
		do pObject.options.series.Insert(tSeries2)		
		//do pObject.options.series.Insert(tSeries3)
	
		set pObject2 = ##class(%ZEN.proxyObject).%New()
		set pObject2.c1=pObject		


		// Define second chart ----------------------------------------------------------------------------
		
        // Create ZEN proxy object to configure chart
        set pObject = ##class(%ZEN.proxyObject).%New()        
		set pObject.options=..CreateChart("Usage details", "Door state", "Stock level")
		
		// define series
		set tSeries1=##class(%ZEN.proxyObject).%New()
		set tSeries1.name="Stock level"
		set tSeries1.data=##class(%ListOfDataTypes).%New()
		set tSeries1.yAxis=1
		Set tSeries1.color="rgb(66,160,123)"
		set tTooltip=##class(%ZEN.proxyObject).%New()
		set tTooltip.valueSuffix=" cm"	
		set tSeries1.tooltip=tTooltip	
		
		set tSeries2=##class(%ZEN.proxyObject).%New()
		set tSeries2.name="Door state"
		set tSeries2.data=##class(%ListOfDataTypes).%New()
		Set tSeries2.color="rgb(81,79,120)"
		set tTooltip=##class(%ZEN.proxyObject).%New()
		set tTooltip.valueSuffix=""	
		set tSeries2.tooltip=tTooltip
		
		// Get data and populate data series
		
		// Get aggregated data for stock level
		set tSensor="stock"
		set tRS=tSS.%Execute(tMaxTS,tInterval,tNumberOfIntervals,tMaxTS,tInterval,tSensor)

	
		set i=0
		while tRS.%Next() {
			set i=i+1
			
			// Use first data set to create categories for x-axis
			set tHHMM=tRS.%Get("HHMM")
			do pObject.options.xAxis.categories.Insert($e(tHHMM,1,2)_":"_$e(tHHMM,3,4))
						
			set tValue=tRS.%Get("AvgValue")

			set tPoint=##class(%ZEN.proxyObject).%New()
			
			if tValue>0 {
				
				set tPoint.y=tValue+0
				set tName="#readings:"_tRS.%Get("NumberOfValues")_", timeslot "
				set tName=tName_tHHMM
				set tPoint.name=tName
				
				do tSeries1.data.Insert(tValue)			
			} else {
				do tSeries1.data.Insert("")	
			}
		}
		
		set tSensor="door"
		set tRS=tSS.%Execute(tMaxTS,tInterval,tNumberOfIntervals,tMaxTS,tInterval,tSensor)
		
		set i=0
		while tRS.%Next() {
			set i=i+1
			
			set tValue=tRS.%Get("maxValue")

			set tPoint=##class(%ZEN.proxyObject).%New()
			set tPoint.y=tValue+0
			
			set tName="#readings:"_tRS.%Get("NumberOfValues")_", timeslot "
			set tName=tName_tRS.%Get("HHMM")
			set tPoint.name=tName
			
			do tSeries2.data.Insert(tPoint)
		}

		// Add series to chart
		set pObject.options.series=##class(%ListOfObjects).%New()
		do pObject.options.series.Insert(tSeries1)
		do pObject.options.series.Insert(tSeries2)

		set pObject2.c2=pObject		

    } ; additional pProviderName branches would go here
    quit $$$OK
}

// Creates a chart template

ClassMethod CreateChart(pTitle As %String, pY1Title As %String = "y1", pY2Title As %String = "y2") As %ZEN.proxyObject
{

    set tOptions = ##class(%ZEN.proxyObject).%New()        

	set tOptions.credits=##class(%ZEN.proxyObject).%New()
	set tOptions.credits.enabled="0"

    set tOptions.chart=##class(%ZEN.proxyObject).%New()        
    //set tOptions.chart.zoomType="x"  //<-- enables zoom on the x-axis but prevents page scrolling on mobile devices      
    set tOptions.chart.zoomType=""
    
    set tOptions.chart.animation=##class(%ZEN.proxyObject).%New()
	set tOptions.chart.animation.duration=500
    		
	set tTitle=##class(%ZEN.proxyObject).%New()
	set tTitle.text=pTitle
	set tOptions.title=tTitle
	
	set tSubtitle=##class(%ZEN.proxyObject).%New()
	set tSubtitle.text=""
	set tOptions.subtitle=tSubtitle
	
	// Configure x axis
	// (tick marks will be added with data from first series)
	set tX=##class(%ZEN.proxyObject).%New()
	set tX.categories=##class(%ListOfDataTypes).%New()
	set tX.allowDecimals=0	
	set tOptions.xAxis=tX

	// configure Y-Axis'
	// primary axis (to the left)
	set tY=##class(%ZEN.proxyObject).%New()
	set tTitle=##class(%ZEN.proxyObject).%New()
	set tTitle.text=pY1Title
	set tTitle.rotation=270
	set tY.title=tTitle	
	set tLabels=##class(%ZEN.proxyObject).%New()
	set tStyle=##class(%ZEN.proxyObject).%New()
	set tStyle.color="rgb(66,160,123)"
	set tLabels.style=tStyle
	set tY.labels=tLabels	

	// secondary axis (right)
	set tY2=##class(%ZEN.proxyObject).%New()
	set tTitle=##class(%ZEN.proxyObject).%New()
	set tTitle.text=pY2Title
	set tTitle.rotation=270	
	set tY2.title=tTitle

	set tLabels=##class(%ZEN.proxyObject).%New()
	set tStyle=##class(%ZEN.proxyObject).%New()
	set tStyle.color="rgb(81,79,120)"
	set tLabels.style=tStyle
	set tY2.labels=tLabels
	set tY2.opposite=1

	
	// add axis definitions to chart configuration
	set tYs=##class(%ListOfObjects).%New()
	do tYs.Insert(tY)
	do tYs.Insert(tY2)		
	set tOptions.yAxis=tYs
	
	quit tOptions
}

/// Creates the layout object for the page
ClientMethod getLayout(key, criteria) [ Language = javascript ]
{
 	var layout = {};
 	
 	switch(key) { 
 		case 'home' : 

  			// add layout objects to the children array
			layout = {
				
		        children: [
		        	
		            //{ type: '$header', content: $$$Text('InterSystems IoT-Demonstrator'), fixed:true},
		            { type: '$header', content: '<img src="Freezerz-logo.png" alt="InterSystems" style="width:100%;" />', fixed:true},
		            
		            // {type:'$grid', children: [
		            
					//	{ type: '$button', caption: 'Refresh', key:'Refresh', inline:'true',dataiconpos:'top',dataicon:'refresh'},
					
		            // ]},
		            { type:'$linechart',key:'chart1',options:'=[c2.options]',width:'100%',height:'400px'},
		            
   		            { type:'$linechart',key:'chart1',options:'=[c1.options]',width:'100%',height:'400px'},

		        ]
 			}; 
			break;
 	} 

 	return layout;
}

/// Client-side content provider method.
/// <var>providerName</var> is the name of the json provider. 
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
ClientMethod onGetContent(providerName, key, criteria) [ Language = javascript ]
{
 	switch (providerName)
 	{ 
 		case 'layout': 
  			return this.getLayout(key,criteria);
 	} 	
 	// return null -> fetch data from server (if local cache is empty)
 	return null;
}

ClientMethod onselect(key, value, docViewId) [ Language = javascript ]
{
	console.log('select '+key);
 	var view = zen(docViewId);
 	var realKey = key.split(':')[0];

 	switch(realKey) {
	 	case 'Refresh':
	 		location.reload();
	 	break;
 	}
}

}
