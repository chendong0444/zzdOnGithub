<!--
* Name:360_mod.aspx(页面异常导致本地路径泄漏（IIS6.0+asp.net）一键修复脚本)
* Date:2013.3.2
* Author:draGxn
-->
<%@codePage="936"%>
<%@import Namespace="System.IO"%>
<%@import Namespace="System.Xml"%> 
<%@import Namespace="System.Xml.Xsl"%> 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
<script language="C#" runat="server"> 
void Page_Load(Object sender,EventArgs e) 
{ 
	const string strConfig = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><configuration><system.web><customErrors mode=\"On\" defaultRedirect=\"GenericErrorPage.htm\"><error statusCode=\"404\" redirect=\"/\"/> </customErrors><globalization fileEncoding=\"utf-8\" responseEncoding=\"utf-8\" /></system.web></configuration>";
	const string strConfig_75 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><configuration><system.webServer><httpErrors errorMode=\"Custom\" /></system.webServer><system.web><globalization fileEncoding=\"utf-8\" responseEncoding=\"utf-8\"/></system.web></configuration>";
	string version = Request["ver"];
	intro.Text = "页面异常导致本地路径泄漏漏洞一键修复脚本，适用环境：IIS6.0/IIS7.5 + ASP.NET<br><br>";
	if(File.Exists(Server.MapPath("~/web.config")))
	{
		if(version == "6.0"){
			XmlDocument xml=new XmlDocument();
			xml.Load(HttpContext.Current.Server.MapPath("~/web.config"));
			XmlNode xnl_node = xml.SelectSingleNode("/configuration/system.web/customErrors");
			
			string v = "";
			if(xnl_node != null && xnl_node.HasChildNodes) {
				XmlNodeList xnl = xnl_node.ChildNodes;
				foreach (XmlNode xn in xnl)
				{   
					if (xn.Name == "error" && xn.Attributes["statusCode"].Value == "404")
					{		
						v = xn.Name;
						break;
					}
				}
			}
			
			if(v == "") {
				string content = "";
				StreamReader rStream = new StreamReader(Server.MapPath("~/web.config"));
				content = rStream.ReadToEnd();
				rStream.Close();
				StreamWriter wStream = File.AppendText(Server.MapPath("~/web.config.bak"));
				wStream.WriteLine(content);
				wStream.Flush();
				wStream.Close();

				XmlNode root=xml.SelectSingleNode("/configuration");	
				XmlNodeList xkl = root.ChildNodes;
				string vv = "";
				foreach (XmlNode xk in xkl)
				{
					if(xk.Name == "system.web")
					{
						vv = xk.Name;
						break;
					}
				}
				if(vv != "") {
					root=xml.SelectSingleNode("/configuration/system.web");
					XmlElement node_cError=xml.CreateElement("customErrors");
					node_cError.SetAttribute("mode","On");
					node_cError.SetAttribute("defaultRedirect","GenericErrorPage.htm");
					root.AppendChild(node_cError);
					XmlElement node_Error=xml.CreateElement("error");
					node_Error.SetAttribute("statusCode","404");
					node_Error.SetAttribute("redirect","/");
					node_cError.AppendChild(node_Error);
				} else {
					root=xml.SelectSingleNode("/configuration");
					XmlElement node=xml.CreateElement("system.web");
					root.AppendChild(node);
					XmlElement node_cError=xml.CreateElement("customErrors");
					node_cError.SetAttribute("mode","On");
					node_cError.SetAttribute("defaultRedirect","GenericErrorPage.htm");
					node.AppendChild(node_cError);
					XmlElement node_Error=xml.CreateElement("error");
					node_Error.SetAttribute("statusCode","404");
					node_Error.SetAttribute("redirect","/");
					node_cError.AppendChild(node_Error);
				}
				xml.Save(HttpContext.Current.Server.MapPath("~/web.config"));
			}
		}
		if (version=="7.5") {
			XmlDocument xml=new XmlDocument();
			xml.Load(HttpContext.Current.Server.MapPath("~/web.config"));
			XmlNode xnl_node = xml.SelectSingleNode("/configuration/system.webServer/httpErrors");
			
			if(xnl_node == null) {	
				string content = "";
				StreamReader rStream = new StreamReader(Server.MapPath("~/web.config"));
				content = rStream.ReadToEnd();
				rStream.Close();
				StreamWriter wStream = File.AppendText(Server.MapPath("~/web.config.bak"));
				wStream.WriteLine(content);
				wStream.Flush();
				wStream.Close();

				XmlNode root=xml.SelectSingleNode("/configuration");	
				XmlNodeList xkl = root.ChildNodes;
				string vv = "";
				foreach (XmlNode xk in xkl)
				{
					if(xk.Name == "system.webServer")
					{
						vv = xk.Name;
						break;
					}
				}
				if(vv != "") {
					root=xml.SelectSingleNode("/configuration/system.webServer");
					XmlElement node_cError=xml.CreateElement("httpErrors");
					node_cError.SetAttribute("errorMode","Custom");
					root.AppendChild(node_cError);
				} else {
					root=xml.SelectSingleNode("/configuration");
					XmlElement node=xml.CreateElement("system.webServer");
					root.AppendChild(node);
					XmlElement node_cError=xml.CreateElement("httpErrors");
					node_cError.SetAttribute("errorMode","Custom");
					node.AppendChild(node_cError);
				}				
			}else {
				XmlElement root = (XmlElement)xnl_node;
				root.SetAttribute("errorMode","Custom");
			}
			xml.Save(HttpContext.Current.Server.MapPath("~/web.config"));
		}
		notice.Text="当前环境存在配置文件，已经修复成功！";
	} else{
		XmlDocument xml=new XmlDocument();
		if(version=="6.0"){
			xml.LoadXml(strConfig);
		}else if(version=="7.5") {
			xml.LoadXml(strConfig_75);
		}else {
			xml.LoadXml(strConfig);
		}		
		xml.Save(HttpContext.Current.Server.MapPath("~/web.config"));
		notice.Text = "当前环境不存在配置文件，已经添加并修复成功！";
	}
} 
</script> 
<body> 
<h3><font face="Verdana"></font></h3> 
<from runat=server> 
<asp:Label id="intro" runat="server"/> 
<asp:Label id="notice" runat="server"/> 
</from> 
</body> 
</html>