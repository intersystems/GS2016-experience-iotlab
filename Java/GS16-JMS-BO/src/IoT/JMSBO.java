package IoT;
import com.intersys.gateway.*;

import javax.jms.Connection;
import javax.jms.ConnectionFactory;
import javax.jms.Destination;
import javax.jms.JMSException;
import javax.jms.MessageProducer;
import javax.jms.Session;
import javax.jms.TextMessage;
import org.apache.activemq.ActiveMQConnection;
import org.apache.activemq.ActiveMQConnectionFactory;

public class JMSBO implements BusinessOperation {

	public static final String SETTINGS="JMSTargetQueueName";	
	
    private ConnectionFactory factory = null;
    private Connection connection = null;
    private Session session = null;
    private Destination destination = null;
    private MessageProducer producer = null;


    public void sendMessage(String inMsg) {

        try {

        	
            TextMessage message = session.createTextMessage();
            message.setText(inMsg);
            producer.send(message);
            System.out.println("Sent: " + message.getText());

        } catch (JMSException e) {
            e.printStackTrace();
        }
    }
	
	
	@Override
	public boolean onInitBO(String[] args) throws Exception {
        String JMSTargetQueue="";
		try {
			
			// Get JMSTargetQueueName setting
            for (int i = 0; i < args.length-1; i++) {
                if (args[i] != null && args[i].equals("-JMSTargetQueueName")) {
                	JMSTargetQueue = args[++i];
                }
            }
            
            if (JMSTargetQueue=="") {
            	JMSTargetQueue="SampleQueue";
            }

			// Connect to JMS provider
			factory = new ActiveMQConnectionFactory(
	                ActiveMQConnection.DEFAULT_BROKER_URL);
	        connection = factory.createConnection();
	        connection.start();
	        session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
	        destination = session.createQueue(JMSTargetQueue);
	        producer = session.createProducer(destination);
	        
			return true;
			
		} catch (JMSException e) {
			e.printStackTrace();

			
			return false;
			
		}
		

	}

	@Override
	public boolean onMessage(String arg0) throws Exception {
		
		try {
			
			this.sendMessage(arg0);
			return true;
			
		} catch (Exception e) {
			e.printStackTrace();
			return false;
			
		}
	}

	@Override
	public boolean onTearDownBO() throws Exception {
		
		session.close();
		connection.close();
		
		return true;
	}

}
