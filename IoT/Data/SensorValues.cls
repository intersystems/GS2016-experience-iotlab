Class IoT.Data.SensorValues Extends (%Persistent, %XML.Adaptor)
{

Property Timestamp As %TimeStamp;

Property Device As %String;

Property Sensor As %String;

Property Value As %String;

ClassMethod Add(pTS As %String, pDev As %String, pSensor As %String, pValue As %String) As %String
{
	
	#Dim tSV as IoT.Data.SensorValues
	#Dim ex as %Exception.AbstractException
	
	try {
		set tSV=..%New()
		set tSV.Timestamp=pTS
		set tSV.Device=pDev
		set tSV.Sensor=pSensor
		set tSV.Value=pValue
		set sc=tSV.%Save() $$$ThrowOnError(sc)
		
	} catch (ex) {
		w !,ex.DisplayString()
		set sc=ex.AsStatus()
		
	}
	
	quit +sc
}

Storage Default
{
<Data name="SensorValuesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Timestamp</Value>
</Value>
<Value name="3">
<Value>Device</Value>
</Value>
<Value name="4">
<Value>Sensor</Value>
</Value>
<Value name="5">
<Value>Value</Value>
</Value>
</Data>
<DataLocation>^IoT.Data.SensorValuesD</DataLocation>
<DefaultData>SensorValuesDefaultData</DefaultData>
<ExtentSize>30309</ExtentSize>
<IdLocation>^IoT.Data.SensorValuesD</IdLocation>
<IndexLocation>^IoT.Data.SensorValuesI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>1</AverageFieldSize>
<OutlierSelectivity>.998659:</OutlierSelectivity>
<Selectivity>0.0134%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>4.66</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="Device">
<AverageFieldSize>6</AverageFieldSize>
<OutlierSelectivity>.998659:"RedBox"</OutlierSelectivity>
<Selectivity>0.0134%</Selectivity>
</Property>
<Property name="Sensor">
<AverageFieldSize>7.49</AverageFieldSize>
<Selectivity>20.0000%</Selectivity>
</Property>
<Property name="Timestamp">
<AverageFieldSize>22.88</AverageFieldSize>
<Selectivity>0.0033%</Selectivity>
</Property>
<Property name="Value">
<AverageFieldSize>2.72</AverageFieldSize>
<OutlierSelectivity>.455939:0</OutlierSelectivity>
<Selectivity>1.0024%</Selectivity>
</Property>
<SQLMap name="$SensorValues">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="IDKEY">
<BlockCount>-952</BlockCount>
</SQLMap>
<SQLMap name="idxDevice">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="idxSensor">
<BlockCount>-16</BlockCount>
</SQLMap>
<SQLMap name="idxTS">
<BlockCount>-236</BlockCount>
</SQLMap>
<StreamLocation>^IoT.Data.SensorValuesS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

Index idxTS On Timestamp;

Index idxDevice On Device [ Type = bitmap ];

Index idxSensor On Sensor [ Type = bitmap ];

}
