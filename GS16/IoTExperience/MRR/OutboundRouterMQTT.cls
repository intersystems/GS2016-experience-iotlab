/// 
Class GS16.IoTExperience.MRR.OutboundRouterMQTT Extends Ens.Rule.Definition
{

Parameter RuleAssistClass = "EnsLib.MsgRouter.RuleAssist";

XData RuleDefinition [ XMLNamespace = "http://www.intersystems.com/rule" ]
{
<ruleDefinition alias="" context="EnsLib.MsgRouter.RoutingEngine" production="IoT.ENS.Production">
<ruleSet name="" effectiveBegin="" effectiveEnd="">
<rule name="">
<constraint name="msgClass" value="Ens.StringRequest"></constraint>
<when condition="1">
<send transform="GS16.IoTExperience.DT.StringRequestToMQTTXML" target="MQTTBO"></send>
<return></return>
</when>
</rule>
</ruleSet>
</ruleDefinition>
}

}
