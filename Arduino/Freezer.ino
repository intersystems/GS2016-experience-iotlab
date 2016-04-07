// Freezerz, Inc.
// IoT Freezer
// powered by InterSystems

#include <Wire.h> 
#include <LiquidCrystal_I2C.h>
#include <NewPing.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <SPI.h>
#include <Ethernet.h>
#include <PubSubClient.h>

//uncomment this for debug mode
// #define DM 1

// Declare Pins
int tinPin=3;           // Inside temperature
int doorPin=8;          // Door sensor (reed switch)
int currentPin = A1;    // Current sensor
int usTrigger=7;        // Ultrasound (trigger)
int usEcho=6;           // Ultrasound (echo)
int fanPin=2;           // Fan RPM sensor (hall sensor)

// Timing
#define tDoor 0
#define tUS 1
#define tTemp 2
#define tFan 3
#define tCurrent 4
#define tMQTTConnect 5

// Arrays to store timing values for non-blocking 'waiting'
long prevMillis[]={0, 0, 0, 0, 0, -5000};
long intervals[]={500, 1000, 2000, 1000, 500, 5000};

// General variables
// 16x4 LCD
LiquidCrystal_I2C lcd(0x3f,16,4);

// HC-SR04 ultrasound sensor
int usMaxDist=200;
NewPing us(usTrigger,usEcho,usMaxDist);

// DS1820
OneWire ds(tinPin);
DallasTemperature ds1820(&ds);
DeviceAddress insideThermometer, outsideThermometer;

// Ethernet
// Update these with values suitable for your network.
byte mac[]    = {  0xDE, 0xED, 0xBA, 0xFE, 0xFE, 0xED };


IPAddress ip(192, 168, 178, 99);
//IPAddress server(192, 168, 0, 126);

/*
IPAddress ip(192, 168, 178, 10);
IPAddress server(192, 168, 178, 150);
*/
//int serverPort=1883;

IPAddress server(104, 154, 19, 82);
int serverPort=16476;

//IPAddress ip(172, 27, 1, 154);
//IPAddress server(172, 27,1,100);

EthernetClient ethClient;

// MQTT
PubSubClient client(ethClient); 
char MQTTClientName[20]="RedBox";

// Other
unsigned long currentMillis=0;
const String topicPrefix="/Freezerz/RedBox/";
String inTopic="/Freezerz/RedBox/toDevice";

String supplyState="";
long refillMessageCount=0;

// Thermometers
float tin=0;
float tout=0;

// Current sensor
int cur=0;
const int curNumReadings=40;
int curReadings[curNumReadings];
int curIndex=0;
int curTotal=0;
int curAvg=0;

// Ultrasound sensor
int stock=0;
const int stockNumReadings=2;
int stockReadings[stockNumReadings];
int stockIndex=0;
int stockTotal=0;
int stockAvg=0;

// Fan RPM
volatile int fanRPMCount=0;     // Volatile so we can use it with interrupts
long fanRPM=0;
long fanInt=1000;              // Read interval (millis) - should be 1000
unsigned long fanPreMill=0;   // previous millis

// -------------------------------------------------------------------------
// MQTT

void callback(char* topic, byte* payload, unsigned int length) {
  #if defined(DM)  
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  #endif
  
  String pl="";
  for (int i=0;i<length;i++) {
    pl=pl+(char)payload[i];
    #if defined(DM)
    Serial.print((char)payload[i]);
    #endif
  }

  if (pl.equals("refill")) {
    refillMessageCount++;
    supplyState="Refill underway     ";
  }

  if (pl.equals("full")) {
    refillMessageCount=0;
    supplyState="                    ";
  }

  if (pl.equals("maint")) {
    supplyState="Service is notified ";
  }
  
  #if defined(DM)
  Serial.print(pl);
  Serial.println();
  #endif
  
  lcd.setCursor(0,3);
  lcd.print(supplyState);
  lcd.setCursor(17,2);
  lcd.print(refillMessageCount);
}

// Reconnect (non-blocking) to MQTT broker
boolean reconnect() {
  if (client.connect(MQTTClientName)) {
    // Subscribe to inTopic to receive messages

    int lt=inTopic.length()+1;    
    char topicChars[lt];
    inTopic.toCharArray(topicChars,lt);
        
    client.subscribe(topicChars);
    
  }
  return client.connected();
}

// -------------------------------------------------------------------------
// setup

void setup()
{
  // start serial connection
  Serial.begin(9600);
  
  // set pin modes
  pinMode(doorPin, INPUT_PULLUP);         // This saves an external pullup resistor
  pinMode(fanPin,INPUT_PULLUP);           // This saves an external pullup resistor
  attachInterrupt(0,rpm_fan, FALLING);    // Interrupt #0 is on pin 2!

  // DS1810
  ds1820.begin();
  #if defined(DM)
  Serial.print("Found ");
  Serial.print(ds1820.getDeviceCount(), DEC);
  Serial.println(" devices."); 
  #endif
  
  boolean foundOutSideProbe=ds1820.getAddress(outsideThermometer, 0);
  boolean foundInSideProbe=ds1820.getAddress(insideThermometer, 1);
  #if defined(DM)
    if (!foundOutSideProbe) Serial.println("Unable to find address for Device 0"); 
    if (!foundInSideProbe) Serial.println("Unable to find address for Device 1"); 
  
    // show the addresses we found on the bus
    Serial.print("outside thermometer address: ");
    printAddress(outsideThermometer);
    Serial.println();
  
    Serial.print("inside thermometer address: ");
    printAddress(insideThermometer);
    Serial.println();
  #endif
  
  // set the resolution to 9 bit (Each Dallas/Maxim device is capable of several different resolutions)
  ds1820.setResolution(insideThermometer, 12);
  ds1820.setResolution(outsideThermometer, 12);
    
  // initialize lcd
  lcd.init();                      
  lcd.backlight();
  lcd.setCursor(2,0);
  lcd.print("Freezers, Inc.");
  lcd.setCursor(2,1);
  lcd.print("IoT Freezer 2.0");
  lcd.setCursor(5,2);
  lcd.print("powered by");
  lcd.setCursor(4,3);
  lcd.print("InterSystems");
  delay(2000);

  
  // Initialize smoothing arrays
  for (int i=0;i<curNumReadings;i++) { curReadings[i]=0;}
  for (int i=0;i<stockNumReadings;i++) { stockReadings[i]=0;}

  // Configure MQTT client
  client.setServer(server, serverPort);
  client.setCallback(callback);

  // Start network
  Ethernet.begin(mac, ip);

  // Print ip adresses to lcd
  lcd.setCursor(4,2);
  for (byte thisByte = 0; thisByte < 4; thisByte++) {
    // print the value of each byte of the IP address:
    lcd.print(server[thisByte], DEC);
      if (thisByte<3) {
    lcd.print(".");
    }
  }
  lcd.setCursor(4,3);
  lcd.print("               ");
  lcd.setCursor(4,3);
  lcd.print(Ethernet.localIP());
  
  
  // Allow the hardware to sort itself out
  delay(2000);
  
  lcd.clear();  
}

// -------------------------------------------------------------------------
// Loop

void loop()
{
  // Process sensors
  processDoor();  
  processCurrent();
  processStock();
  processThermometers();
  processFan();

  // Are we connected to MQTT broker?
  if (!client.connected()) {

    if (checkTiming(tMQTTConnect)) {
      // No, try to reconnect
      reconnect();
    }
  } else {
    // Connected to MQTT broker, process subscriptions
    client.loop();
  }
}

// Checks if the current interval for the specified
// 'what' has passed. Returns true if is has, false otherwise
// To be used for non-blocking 'waiting'
boolean checkTiming(int what) {
  
  currentMillis=millis();
  if (currentMillis - prevMillis[what] >= intervals[what]) {
    prevMillis[what] = currentMillis;
    return true;
  } else {
    return false;
  }
  
}

// Helper function for LCD display
void lcdClearLine(int line=0) {
  lcd.setCursor(0,line);
  lcd.print("                ");
}

// Helper function to send MQTT messages
// using Strings for both topic and content
void sendMQTTString(String topic, String content) {

    // Prepend prefix to topic
    String topicFull=topicPrefix+topic;
    
    // Convert topic string to char array
    int lt=topicFull.length()+1;    
    char topicChars[lt];
    topicFull.toCharArray(topicChars,lt);

    // Convert content string to char array
    int lc=content.length()+1;       
    char contentChars[lc];
    content.toCharArray(contentChars,lc);

    // Send out MQTT message
    client.publish(topicChars,contentChars);
}

// -------------------------------------------------------------------------
// Fan RPM

// Interrupt routine for fan
void rpm_fan(){ /* this code will be executed every time the interrupt 0 (pin2) gets low.*/
  fanRPMCount++;
}

void processFan() {
  currentMillis=millis();
  if (currentMillis - fanPreMill >= fanInt) {
    detachInterrupt(0);     // Disable interrupt while calculating
    fanRPM=fanRPMCount*60/2;

    // Display data on LCD
    lcd.setCursor(14,1);
    lcd.print(fanRPM);
    if (fanRPM<10000) {
      lcd.print(" ");      
    }

    // Send data via MQTT
    sendMQTTString("fan",(String)fanRPM);   
    
    fanRPMCount=0;
    fanPreMill = currentMillis;
    attachInterrupt(0,rpm_fan,FALLING);
  }
}

// -------------------------------------------------------------------------
// Stock level

// Process ultrasound sensor
void processStock() {
  
  if (checkTiming(tUS)) {

    // subtract last reading
    stockTotal=stockTotal-stockReadings[stockIndex];
    
    // Read sensor value
    long echoTime=us.ping_median(5);
    long cm=us.convert_cm(echoTime);
    
    stockReadings[stockIndex]=21-cm;

    // Add current value to the total
    stockTotal+=stockReadings[stockIndex];

    // advanve to the next position in the array
    stockIndex++;

    // turn over in array?
    // (processing stock level in here makes ensures
    // that we only use numbers from a full dataset in the array)
    if (stockIndex>=stockNumReadings) { 

      // yes, now calculate average 
      stockAvg=stockTotal/stockNumReadings;
      
      // Display average
      lcd.setCursor(0,1);
      String strStock="Stock: ";
      strStock+=stockAvg;
      strStock+="     ";
      lcd.print(strStock);
  
      // ...and send it out via MQTT
      sendMQTTString("stock",(String)stockAvg);  

      // Reset array index
      stockIndex=0;
    }
  } 
}

// -------------------------------------------------------------------------
// Electrical current

// Process current sensor
void processCurrent() {
  boolean send=false;
  
   if (checkTiming(tCurrent)) {

    // subtract last reading
    curTotal=curTotal-curReadings[curIndex];
    
    // Read sensor value
    curReadings[curIndex]=analogRead(currentPin);

    // Add current value to the total
    curTotal+=curReadings[curIndex];

    // advanve to the next position in the array
    curIndex++;
    if (curIndex>=curNumReadings) { 
      curIndex=0;
      send=true;
    }

    curAvg=curTotal/curNumReadings;

    // Display average
    /*
    lcd.setCursor(0,2);
    String strCurrent="Current: ";
    strCurrent+=curAvg;
    strCurrent+="     ";
    lcd.print(strCurrent);
    */
    
    #if defined(DM)
    Serial.println(strCurrent); 
    #endif
    
    // Send electrical current via MQTT
    // only every curNumReadings!
    if (send) {
      send=false;
      sendMQTTString("current",(String)curAvg);
    }   
  } 
}

// -------------------------------------------------------------------------
// Temperature probes
// function to print a OneWire device address
void printAddress(DeviceAddress deviceAddress)
{
  #if defined(DM)
  for (uint8_t i = 0; i < 8; i++)
  {
    if (deviceAddress[i] < 16) Serial.print("0");
    
    Serial.print(deviceAddress[i], HEX);  
  }
  #endif
  
}
// Process temperature probes
void processThermometers(){

  if (checkTiming(tTemp)) {

    ds1820.requestTemperatures();
    
    tin=ds1820.getTempC(insideThermometer);
    tout=ds1820.getTempC(outsideThermometer);
    
    // Display inside temp
    lcd.setCursor(0,0);
    String strTemps="Temp: ";
    strTemps+=tin;
    strTemps+="/";
    strTemps+=tout;
    lcd.print(strTemps);

    // Send temperatures via MQTT
    sendMQTTString("temperature/inside",(String)tin);
    sendMQTTString("temperature/outside",(String)tout);
  }
  
}

// -------------------------------------------------------------------------
// Door sensor

// Process door sensor
void processDoor() {

  // Read reed switch state (0 means closed, 1 means open)
  int doorState = digitalRead(doorPin);
  
  if (checkTiming(tDoor)) {
    String door=(String)doorState;

    lcd.setCursor(0,2);
    lcd.print("Door ");
    if (doorState==0) {
      lcd.print("closed");
    } else {
      lcd.print("open  ");  
    }
    
    
    sendMQTTString("door",door);
  }
}


