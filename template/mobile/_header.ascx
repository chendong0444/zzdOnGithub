<%@ Control Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.BaseUserControl" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<script runat="server">
    public override void UpdateView()
    {
        ShowMessage();
    }
</script>
<body id="<%=PageValue.WapBodyID %>">
    <header>
            <div class="left-box">
                <a class="go-back" href="javascript:history.back()"><span>返回</span></a>
            </div>
        <h1><%=PageValue.Title%></h1>
    </header>
    <%if (suctext != String.Empty)
      { %>
    <div id="okMsg" style="opacity: 1;">
        <%=suctext %></div>
    <%} %>
    <%if (errtext != String.Empty)
      { %>
    <div id="errMsg" style="opacity: 1;">
        <%=errtext %></div>
    <%}%>
