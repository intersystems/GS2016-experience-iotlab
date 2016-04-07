package IoT;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;

import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import com.intersys.gateway.Production;
import com.intersys.gateway.Production.Status;
import com.intersys.xep.*;

import org.slf4j.Logger;

import java.sql.Timestamp;
import java.util.Calendar;

import org.apache.commons.math3.stat.descriptive.*;

// Callbacks in this object will be called from MQTT 
public class MQTTListener implements MqttCallback {
	
	// Holds a reference to the Ensemble production 
	public Production production;
	public EventPersister persister;
	
	DescriptiveStatistics fanStats=new DescriptiveStatistics(5);	
	double var_threshold=200;	// consecutive variance values above this threshold are counted
	int fanCounter=0;	// holds number of variance data points above variance threshold

	int lastStockValue=0;
	int lastDoorState=0;
	
	private static Timestamp getTimestamp() {
		return new java.sql.Timestamp(Calendar.getInstance().getTime().getTime());
	}
	
	private static String removeLastChar(String str) {
        return str.substring(0,str.length()-1);
    }
	
	// Extract device id from topic 
	// "/Freezerz/device4711/fan"
	private static String getDeviceId(String topic) {
		
		String deviceId="";
		String[] parts = topic.split("/");
		if (parts.length>=3) {
			deviceId=parts[2];
		}
		return deviceId;
	}
	
	// Extract sensor name from topic 
	// "/Freezerz/device4711/fan"
	private static String getSensorName(String topic) {
		
		String sensorName="";
		String[] parts = topic.split("/");
		if (parts.length>=4) {
			for (int i=3;i<=parts.length-1;i++){
				sensorName+=parts[i]+"/";
			}
			sensorName=removeLastChar(sensorName);
		}
		return sensorName;
	}	
	
	private static String createXML(String topic, MqttMessage msg) {
		
		String xmlMessage="<body>";
		xmlMessage+="<topic>"+topic+"</topic>";
		xmlMessage+="<device>"+getDeviceId(topic)+"</device>";
		xmlMessage+="<sensor>"+getSensorName(topic)+"</sensor>";
		xmlMessage+="<value>"+msg.toString()+"</value>";
		xmlMessage+="<timestamp>"+getTimestamp()+"</timestamp>";
		xmlMessage+="</body>";		
		
		return xmlMessage;
		
	}
	
	private void storeValue(String topic, MqttMessage msg) {

		  persister.callClassMethod("IoT.Data.SensorValues", "Add", getTimestamp().toString(),getDeviceId(topic), getSensorName(topic),msg.toString() );
		  
	}
	
	
	
	@Override
	public void connectionLost(Throwable arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken arg0) {
		// TODO Auto-generated method stub
	}

	@Override
	public void messageArrived(String topic, MqttMessage mqttMessage) throws Exception {
		
		Logger logger=production.getLogger(MQTTListener.class);

		double var=0;
		
		try {
			
			// Store value of any incoming message in Ensemble
			storeValue(topic, mqttMessage);
			
			// Detect certain events and run them through Ensemble
			// to trigger business-related actions
			if (topic.endsWith("fan")) {
				
				// Add value to data series in fanRPM
				fanStats.addValue(Double.parseDouble(mqttMessage.toString()));
				
				// Get variance value for current data value set
				var=fanStats.getVariance()/5;
				
				if (var>var_threshold) {
					// increase counter
					fanCounter+=1;
				} else {
					// reset counter if current var is below threshold
					fanCounter=0;
				}
				
				// if var was higher than var_threshold we have detected a change event
				if (fanCounter>3) {

					// Wrap sensor data in very simple XML
					String xmlMessage=createXML(topic, mqttMessage);
					
					// Send message into Ensemble production
					production.sendRequest(xmlMessage);	
					
					// reset counter so we don't fire the event twice
					fanCounter=0;					
				// 
				}
			} else if (topic.endsWith("stock")) {
				
				int currentStockValue=Integer.parseInt(mqttMessage.toString());
					
				// only send Ensemble message if current stock value is different from last value
				if (currentStockValue!=lastStockValue) {
					// Wrap sensor data in very simple XML
					String xmlMessage=createXML(topic, mqttMessage);
					
					// Send message into Ensemble production
					production.sendRequest(xmlMessage);						
					lastStockValue=currentStockValue;
				}
			} else if (topic.endsWith("door")) {
				
				int currentDoorState=Integer.parseInt(mqttMessage.toString());
					
				// only send Ensemble message if current door state is different from last one
				if (currentDoorState!=lastDoorState) {
					
					// Wrap sensor data in very simple XML
					String xmlMessage=createXML(topic, mqttMessage);
					
					// Send message into Ensemble production
					production.sendRequest(xmlMessage);						
					lastDoorState=currentDoorState;
				}
			}

		} catch (Exception e) {
			
			logger.error(e.toString());
			try {
				// Try to set status of config item to 'ERROR'
				production.setStatus(Status.ERROR);
				
			} catch (Exception e1) {
				e1.printStackTrace();
			}
		}				
	}
}
