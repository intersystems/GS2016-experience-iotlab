package IoT;

import com.intersys.gateway.BusinessOperation;

import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

import java.io.StringReader;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

// As messages will be sent to the device only occasionally, we'll open 
// up a connection to the MQTT target every time we're sending a message
public class MQTTBO implements BusinessOperation {
	
	public static final String SETTINGS="MQTTBroker,MQTTClientId,MQTTDefaultTopic";	
	
	private String MQTTBroker="tcp://localhost:1883";
	private String MQTTClientId="Ensemble";
	private String MQTTDefaultTopic="/Freezerz/RedBox/toDevice";
    
	
	@Override
	public boolean onInitBO(String[] arg0) throws Exception {

		try {
			
			// Get Business Operation setting
            for (int i = 0; i < arg0.length-1; i++) {
                if (arg0[i] != null && arg0[i].equals("-MQTTBroker")) {
                	MQTTBroker = arg0[++i];
                }
                if (arg0[i] != null && arg0[i].equals("-MQTTClientId")) {
                	MQTTClientId = arg0[++i];
                }	  
                if (arg0[i] != null && arg0[i].equals("-MQTTDefaultQueue")) {
                	MQTTDefaultTopic = arg0[++i];
                }		                
            }
    
		} catch (Exception e) {
			
			e.printStackTrace();
			
		}
		return true;
	}

	@Override
	public boolean onMessage(String arg0) throws Exception {

	    int qos = 0;
	    MemoryPersistence persistence = new MemoryPersistence();
	    MqttMessage message=null;	
	    String MQTTTopic="";
	    String MQTTValue="";
	    
	    try {

	    	// Parse xml
	    	InputSource is = new InputSource(new StringReader(arg0));
	    	Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(is);   
	    	doc.getDocumentElement().normalize();
	    	
	    	// Get topic from xml document (if any)
	    	NodeList nl=doc.getElementsByTagName("topic");
	    	if (nl.getLength()>0) {
	    			MQTTTopic=nl.item(0).getTextContent();
	    			if (MQTTTopic.length()<1) {
	    				MQTTTopic=MQTTDefaultTopic;
	    			}
	    	}
	    	
	    	// Get value from xml
	    	MQTTValue=doc.getElementsByTagName("value").item(0).getTextContent();
	    	
	        MqttClient mqttClient = new MqttClient(MQTTBroker, MQTTClientId, persistence);
	        MqttConnectOptions connOpts = new MqttConnectOptions();
	        connOpts.setCleanSession(true);
	        
	        mqttClient.connect(connOpts);

	        message = new MqttMessage(MQTTValue.getBytes());
	        message.setQos(qos);
	        mqttClient.publish(MQTTTopic, message);       
	        
	        mqttClient.disconnect();

	    } catch (Exception e) {
	    	throw e;
	    	
	    }
		return true;
	}

	@Override
	public boolean onTearDownBO() throws Exception {
		// TODO Auto-generated method stub
		return true;
	}

}
