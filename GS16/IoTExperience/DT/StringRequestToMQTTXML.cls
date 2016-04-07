Class GS16.IoTExperience.DT.StringRequestToMQTTXML Extends Ens.DataTransformDTL [ DependsOn = (Ens.StringRequest, EnsLib.EDI.XML.Document) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='Ens.StringRequest' targetClass='EnsLib.EDI.XML.Document' targetDocType='IoT MQTT:body' create='new' language='objectscript' >
<assign value='$p(source.StringValue,":",1)' property='target.{topic}' action='set' />
<assign value='$p(source.StringValue,":",2)' property='target.{value}' action='set' />
</transform>
}

}
