package IoT;

import com.intersys.gateway.*;
import com.intersys.xep.EventPersister;
import com.intersys.xep.PersisterFactory;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;

import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.persist.*;

public class IoTBusinessService implements BusinessService {

	// Comma-separated list of settings - these will be made available in the production configuration
	public static final String SETTINGS="MQTTBrokerURL,MQTTClientId,MQTTTopics";	
	private MqttClient mqttclient;
	private EventPersister persister;

	@Override
	public boolean onInitBS(Production arg0) throws Exception {
		
		Production production=null;
		
		try {
			
		  // Open a TCP/IP connection
		  String host = "127.0.0.1";
		  int port = 1972;
		  String namespace = "ENSEMBLE";
		  String username = "_SYSTEM";
		  String password = "SYS";
		  persister = PersisterFactory.createPersister();
		  persister.connect(host, port, namespace,username,password);
			  
			production=arg0;

			// Retrieve settings from the production
			String MQTTBrokerURL=production.getSetting("MQTTBrokerURL");
			if(MQTTBrokerURL.isEmpty()) {
				MQTTBrokerURL="tcp://localhost:1883";
			}			
			
			String MQTTClientId=production.getSetting("MQTTClientId");
			if(MQTTClientId.isEmpty()) {
				MQTTClientId="EnsembleJavaBS";
			}
			
			// Try to find local ip address
			String ip="";
			Enumeration<NetworkInterface> e=NetworkInterface.getNetworkInterfaces();
			while(e.hasMoreElements()) {
				NetworkInterface n=(NetworkInterface) e.nextElement();
				Enumeration<InetAddress> ee=n.getInetAddresses();
				while (ee.hasMoreElements()) {
					InetAddress in=(InetAddress) ee.nextElement();

					if (in.isSiteLocalAddress()) {
						if (in.getHostAddress()!="127.0.0.1") {
							ip=in.getHostAddress();
						}
					}
					
				}
			}		
			
			MQTTClientId+=ip;

			String[] MQTTTopics=production.getSetting("MQTTTopics").split(",");
			if(production.getSetting("MQTTTopics").isEmpty()) {
				MQTTTopics=new String[]{"Topic1","Topic2"};
			}				
			
			// Create new MQTT client object, connect and subscribe the topics
			mqttclient=new MqttClient(MQTTBrokerURL,MQTTClientId, new MemoryPersistence());
			mqttclient.connect();
			mqttclient.subscribe(MQTTTopics);
			
			// Create a new MQTT listener object and tell the MQTT client to use it for its callbacks
			MQTTListener listener=new MQTTListener();
			listener.production=production;
			listener.persister=persister;
			mqttclient.setCallback(listener);		

		} catch (Exception e) {
			e.printStackTrace();
			
		}
		return true;
	}

	@Override
	public boolean onTearDownBS() throws Exception {
		// Disconnect from MQTT broker when the production or the config item is stopped
		mqttclient.disconnect();
		persister.close();
		
		return true;
	}

}


