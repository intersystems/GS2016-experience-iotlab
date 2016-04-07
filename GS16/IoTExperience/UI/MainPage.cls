Class GS16.IoTExperience.UI.MainPage Extends %ZEN.Mojo.basePage [ ProcedureBlock ]
{

Parameter APPLICATION;

Parameter CSSINCLUDES = "jquery.mobile-1.4.3.min.css";

Parameter DOMAIN;

Parameter JSINCLUDES = "jquery-2.0.3.min.js,jquery.mobile-1.4.3.min.js,highcharts/js/highcharts.js,highcharts/js/themes/sand-signika.js";

Parameter PAGENAME;

Parameter PROVIDERLIST = "data,layout";

Parameter TEMPLATECLASS = "GS16.IoTExperience.UI.Template";

XData Style
{
<style type="text/css">

</style>
}

XData pageContents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane
 xmlns="http://www.intersystems.com/zen"
 xmlns:mojo="http://www.intersystems.com/zen/mojo"
 layout="none"
>
 <mojo:documentView
 id="mainView"
ongetdata="return zenPage.getContent('data',key,criteria,true);"
ongetlayout="return zenPage.getContent('layout',key,criteria);"
initialDocumentKey="home"
initialLayoutKey="home"
developerMode="true"

>
<mojo:jQM-1.4.3-PageManager jQueryAnimation="fade">
<mojo:jQM-1.4.3-Helper/>
<mojo:highCharts-4.0.4-Helper/>
</mojo:jQM-1.4.3-PageManager>
</mojo:documentView>
</pane>
}

/// This callback is called at the start of the HTML HEAD section of the page (just after the title).<br/>
/// It allows a page to write out meta tags, if desired.
/// (default implementation is a simple expression).
Method %OnDrawHTMLMeta() As %Status
{
	// Make it so that, when the user has selected IE compatibility mode, we ignore it and use the most recent IE version available
	//Write "<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"" />"
	// turn off unless this is actually mobile
	Write "<meta name=""viewport"" content=""width=device-width, initial-scale=1.0,maximum-scale=1, user-scalable=no""/>"
	Quit $$$OK
}

}
