<%@ Application Language="C#" %>

<script runat="server">

    void Application_Start(object sender, EventArgs e) 
    {
        //在应用程序启动时运行的代码

    }
    
    void Application_End(object sender, EventArgs e) 
    {
        //在应用程序关闭时运行的代码

    }
        
    void Application_Error(object sender, EventArgs e) 
    {
        Exception ex = Server.GetLastError();
        if (ex != null)
        {
            AS.Common.Utils.WebUtils.LogWrite("Application_Error", ex.ToString());
            Response.Redirect("/HttpErrors/404.htm");
        }
        Server.ClearError();
    }

    void Session_Start(object sender, EventArgs e) 
    {
        //在新会话启动时运行的代码

    }

    void Session_End(object sender, EventArgs e) 
    {
        //在会话结束时运行的代码。 
        // 注意: 只有在 Web.config 文件中的 sessionstate 模式设置为
        // InProc 时，才会引发 Session_End 事件。如果会话模式 
        //设置为 StateServer 或 SQLServer，则不会引发该事件。

    }

    //在接收到一个应用程序请求时触发。对于一个请求来说，它是第一个被触发的事件，请求一般是用户输入的一个页面请求（URL）。
    void Application_BeginRequest(object sender, EventArgs e)
    {
        if (Request.Cookies != null)
        {
            if (safe_360.CookieData())
            {
                Response.Write("您提交的Cookie数据有恶意字符！");
                Response.End();

            }

        }
        if (Request.UrlReferrer != null)
        {
            if (safe_360.referer())
            {
                Response.Write("您提交的Referrer数据有恶意字符！");
                Response.End();
            }
        }
        if (Request.RequestType.ToUpper() == "POST")
        {
            if (safe_360.PostData())
            {
                Response.Write("您提交的Post数据有恶意字符！");
                Response.End();
            }
        }
        if (Request.RequestType.ToUpper() == "GET")
        {
            if (safe_360.GetData())
            {
                Response.Write("您提交的Get数据有恶意字符！");
                Response.End();
            }
        }         
    }
       
</script>

