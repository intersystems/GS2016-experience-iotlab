/// 
Class GS16.IoTExperience.BP.HandleStockLevels Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='EnsLib.EDI.XML.Document' response='Ens.Response' height='2000' width='2000' >
<sequence xend='200' yend='1500' >
<code name='Update stored device status' xpos='200' ypos='250' >
<![CDATA[ set ^devices(request.GetValueAt("device"),request.GetValueAt("sensor"),"value")=request.GetValueAt("value")
  set ^devices(request.GetValueAt("device"),request.GetValueAt("sensor"),"values",request.GetValueAt("timestamp"))=request.GetValueAt("value")]]>
</code>
<if name='request.{value}&lt;6' condition='request.GetValueAt("value")&lt;6' xpos='200' ypos='350' xend='200' yend='1400' >
<true>
<if name='Already re-ordering?' condition='$g(^devices(request.GetValueAt("device"),request.GetValueAt("sensor"),"status"))="re-ordered"' xpos='740' ypos='500' xend='740' yend='1300' >
<false>
<code name='set status to &apos;re-ordering&apos;' xpos='875' ypos='650' >
<![CDATA[ set ^devices(request.GetValueAt("device"),request.GetValueAt("sensor"),"status")="re-ordered"]]>
</code>
<if name='testing' condition='1=0' xpos='875' ypos='750' xend='875' yend='1100' >
<false>
<call name='Re-order via Ensemble WF' target='Supplier' async='1' xpos='1010' ypos='900' >
<request type='EnsLib.Workflow.TaskRequest' >
<assign property="callrequest.%Actions" value="&quot;Ship supplies&quot;" action="set" />
<assign property="callrequest.%Subject" value="&quot;Device needs refill&quot;" action="set" />
<assign property="callrequest.%Message" value="&quot;Device &quot;_request.GetValueAt(&quot;device&quot;)" action="set" />
</request>
<response type='Ens.Response' />
</call>
<sync name='Wait for user to ship supplies' calls='Re-order via Ensemble WF' type='any' xpos='1010' ypos='1000' />
</false>
</if>
<call name='Send feedback to device' target='OutboundRouterMQTT' async='1' xpos='875' ypos='1200' >
<request type='Ens.StringRequest' >
<assign property="callrequest.StringValue" value="&quot;:refill&quot;" action="set" />
</request>
</call>
</false>
</if>
</true>
<false>
<if name='Already re-ordering?' condition='$g(^devices(request.GetValueAt("device"),request.GetValueAt("sensor"),"status"))="re-ordered"' xpos='200' ypos='500' xend='200' yend='850' >
<true>
<code name='Set status to &apos;refill-arrived&apos;' xpos='335' ypos='650' >
<![CDATA[ set ^devices(request.GetValueAt("device"),request.GetValueAt("sensor"),"status")="refill arrived"]]>
</code>
<call name='Send feedback to device' target='OutboundRouterMQTT' async='1' xpos='335' ypos='750' >
<request type='Ens.StringRequest' >
<assign property="callrequest.StringValue" value="&quot;:full&quot;" action="set" />
</request>
</call>
</true>
</if>
</false>
</if>
</sequence>
</process>
}

Storage Default
{
<Type>%Library.CacheStorage</Type>
}

}
