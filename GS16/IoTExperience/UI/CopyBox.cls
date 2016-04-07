Class GS16.IoTExperience.UI.CopyBox Extends %CSP.Page
{

ClassMethod OnPage() As %Status
{
	&html<<html>
<head>
<title>	IoT experience - launch page </title>
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no" />
<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="qrcode.js"></script>
<style>	
	* {
		font-family: sans-serif;
		color:rgb(38,50,140);	
	}
	
	#container {
		margin:auto;
		padding:10px;
		padding-top:50px;
		width:600px;
		height:80%;	
		text-align:left;
	}
	
	#text {
		display:none;
	}
	
	#qrcode {
		width:200px; 
		height:200px; 
		margin-left: 50px;
		margin-top:20px;	
	}
	
	.link {
		
		display:block;
		margin-left:50px;
		margin-top:1.5em;
		font-size:1.5em;
		
		
	}
	h1 {
		
		margin-bottom:24px;	
		
		
	}
	.body-text {
		line-height: 1.6em;	
		
	}
	
</style>


</head>
<body>>
	
	
	
	&html<	
	
<div id="container">
<img src="GS16.png" alt="InterSystems Global Summit 2016" />
<h1>IoT experience</h1>

<p class="body-text">
This page contains text fragments used during the experience. <br />You can copy/paste individual entries from here.
</p>

>

 &html<
 	<h2>Task #1</h2>
 	<p>/opt/gs16/GS16BS.jar</p>
 	<p>IoT.IoTBusinessService</p>
 	<p>GS16.IoTBS</p>
 >




	&html<</body>
</html>>
	Quit $$$OK
}

}
