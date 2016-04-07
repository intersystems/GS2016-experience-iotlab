Class GS16.IoTExperience.UI.LaunchPage Extends %CSP.Page
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
	.linkremark {
		
		display:block;
		margin-left:50px;
		
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

<p class="body-text">Use the following links to launch the pages needed to follow the IoT experience.<br />
It is recommended to keep this page open for easy navigation.<br />
When asked for login credentials, use 'gs16' for both username and password.</p>

>

	// Ensemble Management Portal
	// http://localhost:57772/csp/sys/%25CSP.Portal.Home.zen?$NAMESPACE=ENSEMBLE
	write "<a class=""link"" target=""_new"" title=""Open Ensemble Management Portal in a new browser tab"" href="
	write "/csp/sys/%25CSP.Portal.Home.zen?$NAMESPACE=ENSEMBLE&CacheUserName=gs16&CachePassword=gs16  style=""width:80%"" >Ensemble Management Portal</a> "

	// Copy box
	// http://localhost:57772/csp/ensemble/_DeepSee.UserPortal.Home.zen?$NAMESPACE=ENSEMBLE&$NAMESPACE=ENSEMBLE&
	write "<a class=""link"" target=""_new"" title=""Text fragments for copy/paste""  href="
	write "/csp/ensemble/GS16.IoTExperience.UI.CopyBox.cls?CacheUserName=gs16&CachePassword=gs16  style=""width:80%"">Text fragments for copy/paste</a> "
	write "<p class=""linkremark"" >(hold SHIFT when clicking this to open the copy box in a new window instead of a new browser tab)</p>"

	// DeepSee User Portal
	// http://localhost:57772/csp/ensemble/_DeepSee.UserPortal.Home.zen?$NAMESPACE=ENSEMBLE&$NAMESPACE=ENSEMBLE&
	write "<a class=""link"" target=""_new"" title=""Open DeepSee User Portal in a new browser tab""  href="
	//write $System.INetInfo.HostNameToAddr($System.INetInfo.LocalHostName())
	write "/csp/ensemble/_DeepSee.UserPortal.Home.zen?$NAMESPACE=ENSEMBLE&$NAMESPACE=ENSEMBLE&CacheUserName=gs16&CachePassword=gs16 style=""width:80%"">DeepSee User Portal</a> "

	// Mobile app
	// http://localhost:57772/csp/ensemble/GS16.IoTExperience.UI.MainPage.cls
	write "<a class=""link"" target=""_new"" title=""View mobile app in a new web browser tab""  href="
	write "/csp/ensemble/GS16.IoTExperience.UI.MainPage.cls?CacheUserName=gs16&CachePassword=gs16 style=""width:80%"">View mobile app in web browser</a> "
	write "<p class=""linkremark"" >(hold SHIFT when clicking this to open the mobile app in a new window instead of a new browser tab)</p>"
	
	// QR-Code (hidden text field, value is picked up by the js library generating the QR code)
	write "<input id=""text"" type=""text"" value="
	write "/csp/ensemble/GS16.IoTExperience.UI.MainPage.cls?CacheUserName=gs16&CachePassword=gs16 style=""width:80%"" /><br /> "
	

	&html<
	
	<p class="body-text">Scan the QR code below with your mobile device to access the mobile app.</p>
	
<div id="qrcode"></div>

	<p class="body-text">&copy; InterSystems 2016</p>

</div>
<script type="text/javascript">
var qrcode = new QRCode(document.getElementById("qrcode"), {
	width : 200,
	height : 200
});

function makeCode () {		
	var elText = document.getElementById("text");
	
	if (!elText.value) {
		alert("no URL provided");
		elText.focus();
		return;
	}
	
	var url=window.location.href;
	var arr = url.split("/");
	var result = arr[0] + "//" + arr[2]+elText.value;

	qrcode.makeCode(result);
}

makeCode();

$("#text").
	on("blur", function () {
		makeCode();
	}).
	on("keydown", function (e) {
		if (e.keyCode == 13) {
			makeCode();
		}
	});
</script>	
	
	
	
	>
	&html<</body>
</html>>
	Quit $$$OK
}

}
