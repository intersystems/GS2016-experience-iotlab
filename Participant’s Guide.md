# InterSystems Global Summit 2016 -IoT Experience Lab - Participant’s Guide

Introduction
============

The Internet of Things opens up a whole new world of business opportunities. In this experience, you will use Ensemble and its new Java Business Hosts to connect data produced by an IoT device with business processes and workflows. Live data will be available from an IoT device and Ensemble will be used to trigger events on that device. Ultimately, you will visualize data captured throughout the experience on your mobile device or in a web browser.

For this experience, you will use your laptop to work with a container that provides you with your own InterSystems Ensemble environment. There is no need to install anything locally. This guide gives detailed step-by-step instructions to work through the IoT experience.

When asked for username / password, please use gs16 / gs16.

Task \#1: Connecting your devices and launching your personal container
=======================================================================

What you will do
----------------

During this task, you will connect your laptop and optionally your mobile device to the WiFi network provided for this experience. You will then launch your own personal Ensemble container and explore the launch page.

Steps
-----

To get access to your personal container that you can use during this experience, please connect your computer to the WiFi network with the following credentials:

SSID: Devex2016

Password: Devex2016

Once connected, use a web browser to navigate to the following URL:

InterSystems.com/exp-iot

Follow the instructions on the web page to get your own personal container to work with during this experience.

Once the container is successfully started, a launch page will open automatically It contains links to all places required to complete the following tasks.

Task \#2: Connecting device-generated data streams
==================================================

What you will do
----------------

There is a huge variety of different device types out there, using many different protocols to communicate. For most of these, there are existing Java libraries, both open-source and commercial.

Ensemble’s upcoming new Java Business Hosts allows you to easily make use of such Java libraries by allowing you to write Ensemble Business Services and Ensemble Business Operations purely in Java. Once written, all you need to do is to tell Ensemble how to use it.

In this task, you will plug such a Java Business Service into an Ensemble production to receive MQTT messages from the Red Box. Then, you will have a look at the incoming messages.

Steps
-----

1.  <span id="_Ref446488590" class="anchor"></span>From your launch page, start the Ensemble Management Portal

2.  For your convenience you will find links to places used during this experience under ‘Favorites’:
    
    <img src="http://i.imgur.com/VfsFGtM.png" width="457" height="303" />

3.  Under Favorites, click “Production”. Have a quick look at the components (note the JavaGWInitiator), then start the production.

4.  Under Favorites, click “Java Business Hosts”. Or navigate to Ensemble / Build / Java Business Hosts

5.  Fill out the form with the following values (case-sensitive), then press “‘Generate”:
    > (remember, you can use the copy box!)

    > <img src="http://i.imgur.com/hT885ZC.png" width="385" height="342" />

1.  Navigate back to production configuration (“Home” / “Production”-favorite)

2.  Add the new Business Service component to the production, name it “IoTBS” (case sensitive!):
    > <img src="http://i.imgur.com/Ub1XhSh.png" width="334" height="157" />
    > <img src="http://i.imgur.com/3C3lGLg.png" width="334" height="213" />

3.  The new configuration item should now be added to the production. Verify that it is shown in green.

4.  Restart the production by using the Start and Stop buttons at the top.

5.  Navigate back to “Home”, then click on the “Messages” favorite. This will bring you to the message viewer. You should see some messages with source “IoTBS” in the list.

6.  Select one of these messages, then look at its content and its message trace – it should look similar to this:
    <img src="http://i.imgur.com/uJ3iO7b.png" width="188" height="169" /> <img src="http://i.imgur.com/unPCXgl.png" width="188" height="169" />
    Note how the message trace stops at the MsgRouter. In the next task, you will configure your production to actually process the messages.

Task \#3: Integrating device-generated data with business processes
===================================================================

What you will do
----------------

First, you will have a quick look at an existing Ensemble Business Process. Then you will make sure that the events created by the Red Box will trigger this Business Process by working with a Routing Rule.

Steps
-----

1.  In Home/Favorites, click on “Business Processes”

2.  Look at the business process – it will be triggered by incoming messages indicating stock level changes and handle these. In the next step, you will configure the MsgRouter component of your production to send make sure that these (and only these) messages are routed to this business process.

3.  Navigate to the production configuration (Home/Favorites – Production), select the MsgRouter and open its routing rules:
    > <img src="http://i.imgur.com/rmWtBMx.png" width="539" height="283" />

4.  The rule definition is already there, it just needs to be enabled. Enable the rule by double-clicking the “disabled” box, then click “Save”.

5.  Navigate to the message viewer (Home/Favorites – Messages) and look at some of the message traces initiated by the source “IoTBS”. Try to find one that looks like this:
    > <img src="http://i.imgur.com/RukHa3q.png" width="527" height="276" />
    > Note that the Workflow.TaskRequest does not have a response – it waits for someone to take care of it. In the next task, you will use Ensemble’s Workflow capabilities to answer the task request.
    > Leave the browser tab/window with this visual trace open for now, you will need to come back to it in the next task.

Task \#4: Using Ensemble Workflow to complete the business process
==================================================================

What you will do
----------------

You will now use Ensemble’s workflow capabilities to send supplies to the Red Box by working with a workflow task.

Then you will have a look at how your production sends feedback to the Red Box and how the refill count on the display of the device grows as your peers take care of their own workflow task requests.

Steps
-----

1.  From the launch page, navigate to the DeepSee User portal.
    > When required, log in with gs16 / gs16.

2.  Your Workflow Inbox should have at least one item:
    > <img src="http://i.imgur.com/Gq7a26L.png" width="359" height="203" />
    > Go ahead and open your workflow inbox.

3.  Select the first task in the list and claim the task by clicking “Accept”:
    > <img src="http://i.imgur.com/ZdRilf0.png" width="465" height="241" />
    > Note how the task now shows additional action buttons. The actions available here are controlled by the workflow task request you saw earlier in your production.

4.  To simulate shipping of supplies to the Red Box click on the button “Ship supplies”. Note how the task is now gone from your inbox.

5.  Now go back to the visual trace from the last task and refresh the browser tab/windows.
    > (should you have closed the browser tab/window with the visual trace from the last task, repeat the steps described there to open it again).
    > Note how there is now a Workflow.TaskResponse, followed by some more messages:
    > <img src="http://i.imgur.com/JPaim0x.png" width="503" height="275" />

6.  Click on messages following the Workflow.TaskResponse (\[6\] and \[8\] in the example above) and look at their content. Message \[8\] is sent back to the Red Box via a Java Business Operation.
    > Each of these messages from you and your peer’s productions increases a counter on the device. Once the counter exceeds a certain threshold, the Red Box will be refilled manually, simulating the arrival of the new supplies.

7.  Once the Red Box has been refilled, another message will be sent to your production. The production will check its content and update the display on the Red Box appropriately:
    > <img src="http://i.imgur.com/zYh1aYo.png" width="545" height="201" />
    > Try to find this message trace and look at the content of the message sent to MQTTBO. Its value should be the string “full” – which will cause the Red Box to clear the information on its display saying the refill is underway.

Task \#5: View data on your mobile device
=========================================

What you will do
----------------

In the previous tasks you have seen how Ensemble can be used to connect certain events generated by an IoT device with business processes and human workflow. This is something typically done with discrete events.

However, analyzing continuous data generated by devices can also be very valuable. The Java Business Service you used in your production did store some additional data streams from the Red Box in Ensemble’s database where it should now be ready to be visualized.

You will use a browser-based mobile app created with Zen Mojo to have a quick look at this data. You can use your mobile device or a web browser on your laptop for this.

Steps
-----

1.  From the launch page, scan the QR code with your mobile device. If you do not want to use a mobile device click on the link to open the mobile app in your web browser.

2.  See how the diagrams visualize some of the data streams generated by the Red Box during this session.


