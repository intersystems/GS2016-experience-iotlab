Class GS16.IoTExperience.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="GS16.IoTExperience.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="Supplier" Category="" ClassName="EnsLib.Workflow.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="AutoCreateRole">0</Setting>
  </Item>
  <Item Name="HandleStockLevels" Category="" ClassName="GS16.IoTExperience.BP.HandleStockLevels" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="JavaGWInitiator" Category="" ClassName="EnsLib.JavaGateway.Initiator" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="ClassPath">/usr/cachesys/dev/java/lib/JDK18/cache-gateway-2.0.jar:/usr/cachesys/dev/java/lib/JDK18/cachejdbc.jar:/usr/cachesys/dev/java/lib/JDK18/cache-jdbc-2.0.jar:/usr/cachesys/csp/ensemble/org.eclipse.paho.client.mqttv3-1.0.2.jar:/usr/cachesys/csp/ensemble/commons-math3-3.6.jar</Setting>
    <Setting Target="Host" Name="JDKVersion">JDK18</Setting>
    <Setting Target="Host" Name="JavaHome">/usr/lib/jvm/jre</Setting>
    <Setting Target="Host" Name="Port">55555</Setting>
  </Item>
  <Item Name="MsgRouter" Category="" ClassName="EnsLib.MsgRouter.VDocRoutingEngine" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="Validation"></Setting>
    <Setting Target="Host" Name="BusinessRuleName">GS16.IoTExperience.MRR.MainRouter</Setting>
  </Item>
  <Item Name="OutboundRouterMQTT" Category="" ClassName="EnsLib.MsgRouter.RoutingEngine" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="Validation"></Setting>
    <Setting Target="Host" Name="BusinessRuleName">GS16.IoTExperience.MRR.OutboundRouterMQTT</Setting>
  </Item>
  <Item Name="MQTTBO" Category="" ClassName="GS16.MQTTBO" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="MQTTClientId">ENS</Setting>
    <Setting Target="Host" Name="MQTTDefaultTopic">/Freezerz/RedBox/toDevice</Setting>
  </Item>
</Production>
}

}
