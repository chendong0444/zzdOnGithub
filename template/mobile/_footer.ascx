<%@ Control Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.BaseUserControl" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<footer>
    <div class="wrap">
        <%if (IsLogin && AsUser.Id != 0)
          {%>
        <div class="user">
            <strong><a href="<%=GetUrl("手机版个人中心","account_index.aspx")%>"><%=AsUser.Username %></a></strong>
            <a id="logout" href="<%=GetUrl("手机版退出","loginout.aspx") %>">退出</a>
        </div>
        <%}
          else
          {%>
        <div class="account">
            <a class="nav-button login" href="<%=GetUrl("手机版登录","account_login.aspx") %>">登录</a>
            <a class="nav-button singup" href="<%=GetUrl("手机版注册","account_signup.aspx") %>">注册</a>
        </div>
        <%}%>
        <div class="city">
            <strong><%=PageValue.CurrentCity.Name %></strong>
            <a href="<%=GetUrl("手机版城市","city.aspx") %>">切换城市</a>
        </div>
    </div>
    <nav>
        <ul class="cf">
            <li><a  href="<%=GetUrl("手机版首页","index.aspx") %>">首页</a></li>
            <li><a  href="<%=GetUrl("手机版个人中心订单","account_orders.aspx") %>">订单</a></li>
            <%if (PageValue.CurrentSystemConfig["openwapindex"] != "1")
              {%>
               <li><a  href="<%=PageValue.CurrentSystem.domain %>?PCVersion=1">电脑版</a></li>   
              <%} %>
            <li><a  href="<%=GetUrl("手机版用户购买帮助","help_pay.aspx") %>">帮助</a></li>
        </ul>
    </nav>
    <div class="copyright"><span class="copyright">©2013<%=ASSystem.sitename %></span><p></p>
    </div>
</footer>
    <script type='text/javascript' src="<%=PageValue.CurrentSystem.domain+PageValue.WebRoot %>upfile/js/Mobile/Zepto.js"></script>
    <script type='text/javascript' src="<%=PageValue.CurrentSystem.domain+PageValue.WebRoot %>upfile/js/Mobile/mobile.js"></script>