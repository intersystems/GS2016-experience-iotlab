Class IoT.IoTBusinessService Extends (java.lang.Object, com.intersys.gateway.BusinessService) [ Inheritance = right, ProcedureBlock ]
{

Parameter IMPORTTIMESTAMP As STRING = "2016-03-01 17:05:43.0";

Method %OnNew(ByRef p0 As %ObjectHandle) As %Status
{
	Quit:'$D(p0) $$$OK
	Quit ..%Constructor(p0,"IoT.IoTBusinessService",0)
}

Method onInitBS(ByRef p0 As %ObjectHandle) As %ObjectHandle
{
	Quit ..%IR("onInitBS",.p0)
}

Method onTearDownBS() As %ObjectHandle
{
	Quit ..%IR("onTearDownBS")
}

Parameter SETTINGS As STRING = "MQTTBrokerURL,MQTTClientId,MQTTTopics";

}
