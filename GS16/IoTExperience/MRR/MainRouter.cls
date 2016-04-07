/// 
Class GS16.IoTExperience.MRR.MainRouter Extends Ens.Rule.Definition
{

Parameter RuleAssistClass = "EnsLib.MsgRouter.VDocRuleAssist";

XData RuleDefinition [ XMLNamespace = "http://www.intersystems.com/rule" ]
{
<ruleDefinition alias="" context="EnsLib.MsgRouter.VDocRoutingEngine" production="GS16.IoTExperience.Production">
<ruleSet name="" effectiveBegin="" effectiveEnd="">
<rule name="" disabled="true">
<constraint name="msgClass" value="EnsLib.EDI.XML.Document"></constraint>
<constraint name="docCategory" value="IoT MQTT"></constraint>
<constraint name="docName" value="body"></constraint>
<when condition="Document.{sensor}=&quot;stock&quot;">
<send transform="" target="HandleStockLevels"></send>
<return></return>
</when>
</rule>
</ruleSet>
</ruleDefinition>
}

}
