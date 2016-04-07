Class GS16.IoTExperience.Util
{

ClassMethod Export(pFileName As %String = "c:\test\GS16IoTExperience.xml")
{
	do $System.OBJ.Export("GS16IoTExperience.prj,Ens.Conf.CredentialsD.gbl,Ens.Config.DefaultSettingsD.gbl",pFileName)
}

}
