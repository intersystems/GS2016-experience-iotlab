Class IoT.MQTTListener Extends (java.lang.Object, org.eclipse.paho.client.mqttv3.MqttCallback) [ Inheritance = right, ProcedureBlock ]
{

Parameter IMPORTTIMESTAMP As STRING = "2016-03-01 17:05:43.0";

Method %OnNew(ByRef p0 As %ObjectHandle) As %Status
{
	Quit:'$D(p0) $$$OK
	Quit ..%Constructor(p0,"IoT.MQTTListener",0)
}

Method connectionLost(ByRef p0 As %ObjectHandle)
{
	Do ..%I("connectionLost",.p0)
}

Method messageArrived(ByRef p0 As %ObjectHandle, ByRef p1 As %ObjectHandle)
{
	Do ..%I("messageArrived",.p0,.p1)
}

Method deliveryComplete(ByRef p0 As %ObjectHandle)
{
	Do ..%I("deliveryComplete",.p0)
}

Method setproduction(p1 As %ObjectHandle)
{
	Do ..%Set("setproduction",p1)
}

Method getproduction() As %ObjectHandle
{
	Quit ..%Get("getproduction")
}

Method setpersister(p1 As %ObjectHandle)
{
	Do ..%Set("setpersister",p1)
}

Method getpersister() As %ObjectHandle
{
	Quit ..%Get("getpersister")
}

}
