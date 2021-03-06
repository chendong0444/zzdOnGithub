﻿<%@ Page Language="C#" EnableViewState="false" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.AdminPage" %>

<%@ Import Namespace="AS.GroupOn" %>
<%@ Import Namespace="AS.Common" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Accessor" %>
<%@ Import Namespace="AS.Common.Utils" %>
<%@ Import Namespace="AS.GroupOn.App" %>
<script runat="server">
    protected IPagers<IOrder> pager = null;
    protected IList<IOrder> list_order = null;
    protected OrderFilter filter = new OrderFilter();
    protected string pagerHtml = String.Empty;
    protected string url = "";
    protected string durl = "";
    protected int id = 0;
    protected string type_name = "";
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        //判断管理员是否有此操作

        if (AdminPage.IsAdmin && AdminPage.CheckUserOptionAuth(PageValue.CurrentAdmin, ActionEnum.Option_Order_Cancle_ListView))
        {
            SetError("你不具有查看取消订单列表的权限！");
            Response.Redirect("index_index.aspx");
            return;
        }
        if (Request.QueryString["item"] != null)
        {
            if (AdminPage.IsAdmin && AdminPage.CheckUserOptionAuth(PageValue.CurrentAdmin, ActionEnum.Option_Order_Delete))
            {
                SetError("你不具有删除订单信息的权限！");
                Response.Redirect("index_index.aspx");
                return;
            }
            string items = Request.QueryString["item"];
            string[] item = items.Split(';');
            int j = 0;
            foreach (string ids in item)
            {
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    int i = 0;
                    i = session.Orders.Delete(Helper.GetInt(ids, 0));
                    if (i > 0)
                    {
                        j++;
                        WebUtils.LogWrite("管理员删除订单", "订单ID:" + i + "管理员ID:" + AS.Common.Utils.WebUtils.GetLoginAdminID());
                    }
                    else
                    {
                        SetError("删除选中失败！");
                        Response.Redirect(Request.Url.ToString().Replace("&item=" + items, ""));
                    }
                }
            }
            SetSuccess("删除选中成功,共删除" + j + "条订单记录");
            string key = AS.Common.Utils.FileUtils.GetKey();
            AS.AdminEvent.ConfigEvent.AddOprationLog(AS.Common.Utils.Helper.GetInt(AS.Common.Utils.CookieUtils.GetCookieValue("admin", key), 0), "删除订单记录", "删除订单记录 ID:" + Request.QueryString["item"].ToString(), DateTime.Now);
            Response.Redirect(Request.Url.ToString().Replace("&item=" + items, ""));
        }
        if (!string.IsNullOrEmpty(Request.QueryString["begintime"]))
        {
            url = url + "&begintime=" + Request.QueryString["begintime"];
            filter.FromCreate_time = Helper.GetDateTime(Convert.ToDateTime(Request.QueryString["begintime"]).ToString("yyyy-MM-dd 0:0:0"), DateTime.Now);
        }
        if (!string.IsNullOrEmpty(Request.QueryString["endtime"]))
        {
            url = url + "&endtime=" + Request["endtime"];
            filter.ToCreate_time = Helper.GetDateTime(Convert.ToDateTime(Request.QueryString["endtime"]).ToString("yyyy-MM-dd 23:59:59"), DateTime.Now);
        }
        if (!string.IsNullOrEmpty(Request.QueryString["fromfinishtime"]))
        {
            url = url + "&fromfinishtime=" + Request["fromfinishtime"];
            filter.FromPay_time = Helper.GetDateTime(Convert.ToDateTime(Request.QueryString["fromfinishtime"]).ToString("yyyy-MM-dd 0:0:0"), DateTime.Now);
        }
        if (!string.IsNullOrEmpty(Request.QueryString["endfinishtime"]))
        {
            url = url + "&endfinishtime=" + Request.QueryString["endfinishtime"];
            filter.ToPay_time = Helper.GetDateTime(Convert.ToDateTime(Request.QueryString["endfinishtime"]).ToString("yyyy-MM-dd 23:59:59"), DateTime.Now);
        }
        if (!string.IsNullOrEmpty(Request.QueryString["select_type"]))
        {
            IUser uses = null;
            UserFilter u_filter = new UserFilter();
            url = url + "&select_type=" + Request.QueryString["select_type"];
            type_name = Request.QueryString["type_name"];
            if (Request.QueryString["select_type"] == "1" || Request.QueryString["select_type"] == "2")
            {
                if (Request.QueryString["select_type"] == "1")
                    u_filter.Username = type_name;
                else
                    u_filter.Email = type_name;
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    uses = session.Users.Get(u_filter);
                }
                if (uses != null)
                    filter.User_id = uses.Id;
                else
                    return;
            }
            else if (Request.QueryString["select_type"] == "4")
            {
                filter.Id = Helper.GetInt(type_name, 0);
            }
            else if (Request.QueryString["select_type"] == "8")
            {
                filter.Team_In = Helper.GetInt(type_name, 0);
            }
            else if (Request.QueryString["select_type"] == "16")
            {
                filter.Pay_id = Helper.GetString(type_name, String.Empty);
            }
            else if (Request.QueryString["select_type"] == "32")
            {
                filter.Express_no = Helper.GetString(type_name, String.Empty);
            }
            else if (Request.QueryString["select_type"] == "64")
            {
                filter.Mobile = Helper.GetString(type_name, String.Empty);
            }
            else if (Request.QueryString["select_type"] == "128")
            {
                filter.Realname = Helper.GetString(type_name, String.Empty);
            }
            else if (Request.QueryString["select_type"] == "256")
            {
                filter.Address = Helper.GetString(type_name, String.Empty);
            }
            url = url + "&type_name=" + Request.QueryString["type_name"];
        }
        InitData();
    }
    private void InitData()
    {
        StringBuilder sb1 = new StringBuilder();
        StringBuilder sb2 = new StringBuilder();
        IUser user = Store.CreateUser();
        ITeam team = Store.CreateTeam();
        IList<ITeam> teamlist = null;
        IList<IOrderDetail> orderlist = null;
      
        durl = "Dingdan_QuxiaoDingdan.aspx?" + url + "&page=" + AS.Common.Utils.Helper.GetInt(Request.QueryString["page"], 1)+"";
        url = url + "&page={0}";
        url = "Dingdan_QuxiaoDingdan.aspx?" + url.Substring(1);
        if (Request["key"] == "4")
        {
            filter.Wheresql1 = " state!='scorepay' and state!='scoreunpay'";
        }
        
            filter.State = "cancel";
        
        filter.PageSize = 30;
        filter.AddSortOrder(OrderFilter.ID_DESC);
        filter.CurrentPage = AS.Common.Utils.Helper.GetInt(Request.QueryString["page"], 1);
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            pager = session.Orders.GetPager(filter);
        }
        list_order = pager.Objects;
        int i = 0;
        if (list_order != null && list_order.Count > 0)
        {
            foreach (IOrder order in list_order)
            {
                user = order.User;
                team = order.Team;
                if (i % 2 != 0)
                    sb2.Append("<tr>");
                else
                    sb2.Append("<tr class='alt'>");
                i++;
                sb2.Append("<td><input type='checkbox' id='check' name='check' value=" + order.Id + " /></td>");
                sb2.Append("<td>" + order.Id + "</td>");
                sb2.Append("<td>");
                if (order.Team_id == 0)
                {
                    orderlist = order.OrderDetail;
                    foreach (IOrderDetail detail in orderlist)
                    {
                        sb2.Append("项目ID:" + detail.Team.Id + "(<a class='deal-title' href='" + getTeamPageUrl(detail.Team.Id) + "' target='_blank'>" + StringUtils.SubString(detail.Team.Title, 70) + "..." + "</a>)");
                        sb2.Append(StringUtils.SubString(AS.Common.Utils.WebUtils.Getbulletin(detail.result), 0, "<br>"));
                    }
                }
                else
                {
                    if (team != null)
                    {
                        sb2.Append("项目ID:" + order.Team_id + "(<a class='deal-title' href='" + getTeamPageUrl(team.Id) + "' target='_blank'>" + StringUtils.SubString(team.Title, 70) + "..." + "</a>)");
                    }
                    if (order.result != null)
                        sb2.Append(StringUtils.SubString(AS.Common.Utils.WebUtils.Getbulletin(order.result), 0, "<br>"));
                }
                if (order.Parent_orderid != null && order.Parent_orderid != 0)
                    sb2.Append("<font style='color:#0D6D00;font-weight:bold;'>该订单父ID:" + order.Parent_orderid + "</font>");
                sb2.Append("</td>");
                if (user != null)
                {
                    sb2.Append("<td><a class='ajaxlink' href='ajax_manage.aspx?action=userview&Id=" + order.User_id + "'>" + user.Email + "<br>" + user.Username + "</a>&nbsp;»&nbsp;<a class='ajaxlink' href='ajax_manage.aspx?action=sms&v=" + user.Mobile + "'>短信</a></td>");
                }
                else
                {
                    sb2.Append("<td>该用户已被删除</td>");
                }
                sb2.Append("<td>" + order.Quantity + "</td>");
                sb2.Append("<td>" + order.Origin + "</td>");
                sb2.Append("<td>" + WebUtils.GetPayText(order.State, order.Service) + "</td>");
                sb2.Append("<td>" + order.Credit + "</td>");
                sb2.Append("<td>" + (order.Service == "cashondelivery" ? order.cashondelivery.ToString("0.00") : order.Money.ToString("0.00")) + "</td>");
                sb2.Append("<td>" + GetOrderExpress(order) + "</td>");
                sb2.Append("<td class='op'>");
                if (order.State == "cancel" || order.State == "nocod")
                {
                    sb2.Append("<a class='ajaxlink' href='ajax_manage.aspx?action=orderview&orderview=" + order.Id + "'>详情</a>");
                }
                sb2.Append("</td></tr>");
            }
            if (pager.TotalRecords >= 30)
            {
                pagerHtml = AS.Common.Utils.WebUtils.GetPagerHtml(30, pager.TotalRecords, pager.CurrentPage, url);
            }
        }
        Literal2.Text = sb2.ToString();
    }
</script>
<%LoadUserControl("_header.ascx", null); %>
<body class="newbie">
    <div id="pagemasker">
    </div>
    <div id="dialog">
    </div>
    <div id="doc">
        <div id="bdw" class="bdw">
            <div id="bd" class="cf">
                <div id="coupons">
                    <div id="content" class="coupons-box clear mainwide">
                        <div class="box clear">
                            <div class="box-content">
                                <div class="head">
                                <%if (Request["key"] == "4")
                                  {%>
                                  <h2>
                                        用户取消订单</h2>
                                 <% }
                                  else
                                  {%>
                                  <h2>
                                        取消订单</h2>
                                 <% } %>
                                    <form id="Form1" runat="server" method="get">
                                <div class="search">
                                  生成订单时间：<input type="text" class="h-input" datatype="date" name="begintime"
                                        <%if(!string.IsNullOrEmpty(Request.QueryString["begintime"])){ %>value="<%=Request.QueryString["begintime"] %>"
                                        <%} %> />--<input type="text" class="h-input" datatype="date" name="endtime" <%if(!string.IsNullOrEmpty(Request.QueryString["endtime"])){ %>value="<%=Request.QueryString["endtime"] %>"
                                            <%} %> />&nbsp;&nbsp; 完成订单时间：<input type="text" class="h-input" datatype="date" name="fromfinishtime"
                                                <%if(!string.IsNullOrEmpty(Request.QueryString["fromfinishtime"])){ %>value="<%=Request.QueryString["fromfinishtime"] %>"
                                                <%} %> />--<input type="text" class="h-input" datatype="date" name="endfinishtime"
                                                    <%if(!string.IsNullOrEmpty(Request.QueryString["endfinishtime"])){ %>value="<%=Request.QueryString["endfinishtime"] %>"
                                                    <%} %> />&nbsp;&nbsp; 筛选条件：<select name="select_type" id="select_type"  class="h-input">
                                                        <option value="">全部</option>
                                                        <option value="1" <%if(Request.QueryString["select_type"] == "1"){ %>selected="selected"
                                                            <%} %>>用户名</option>
                                                        <option value="2" <%if(Request.QueryString["select_type"] == "2"){ %>selected="selected"
                                                            <%} %>>Email</option>
                                                        <option value="4" <%if(Request.QueryString["select_type"] == "4"){ %>selected="selected"
                                                            <%} %>>订单编号</option>
                                                        <option value="8" <%if(Request.QueryString["select_type"] == "8"){ %>selected="selected"
                                                            <%} %>>项目ID</option>
                                                        <option value="16" <%if(Request.QueryString["select_type"] == "16"){ %>selected="selected"
                                                            <%} %>>交易单号</option>
                                                        <option value="32" <%if(Request.QueryString["select_type"] == "32"){ %>selected="selected"
                                                            <%} %>>快递单号</option>
                                                        <option value="64" <%if(Request.QueryString["select_type"] == "64"){ %>selected="selected"
                                                            <%} %>>手机号</option>
                                                        <option value="128" <%if(Request.QueryString["select_type"] == "128"){ %>selected="selected"
                                                            <%} %>>收货人</option>
                                                        <option value="256" <%if(Request.QueryString["select_type"] == "256"){ %>selected="selected"
                                                            <%} %>>派送地址</option>
                                                    </select>&nbsp;&nbsp; 内容：<input class="h-input" type="text" style="width: 120px;" id="type_name"
                                                        name="type_name" <%if(!string.IsNullOrEmpty(Request.QueryString["type_name"])){ %>value="<%=Request.QueryString["type_name"] %>"
                                                        <%} %> />&nbsp;&nbsp;
                                    <input type="submit" name="search" value="筛选" onClick="return checkvale();" class="formbutton" style="padding: 1px 6px;
                                        width: 60px;" /></div>
                                </form>
                                </div>
                                
                                <div class="sect">
                                    <table id="orders-list" cellspacing="0" cellpadding="0" border="0" class="coupons-table">
                                        <tr >
                                            <th width='5%'><input type='checkbox' id='checkall' name='checkall' />全选</th>
                                            <th width='7%'>ID</th>
                                            <th width='22%'>项目</th>
                                            <th width='13%'>用户</th>
                                            <th width='5%'>数量</th>
                                            <th width='5%'>总款</th>
                                            <th width='5%' >支付方式</th>
                                            <th width='8%' >余付</th>
                                            <th width='10%' >在线支付货到付款</th>
                                            <th width='10%' >递送方式</th>
                                            <th width='10%'>操作</th>
                                        </tr>
                                        <asp:Literal ID="Literal2" runat="server"></asp:Literal>
                                        <tr>
                                            <td colspan="15">
                                                 <input id="items" runat="server" type="hidden" />
                                                 <%if (list_order != null && list_order.Count > 0)
                                                   { %>
                                                    <input value="删除选中" type="button" class="formbutton" style="padding: 1px 6px;" onClick="javascript:GetDeleteItem('<%=durl %>');" />
                                                 <%} %>
                                               <%=pagerHtml%>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
<script type="text/javascript">
    function checkvale() {
        if ($("#select_type").val() != "") {
            if ($("#type_name").val() == "") {
                var selectIndex = document.getElementById("select_type").selectedIndex;
                var selectText = document.getElementById("select_type").options[selectIndex].text
                alert("请输入您要进行筛选的" + selectText);
                return false;
            }
        }
        else {
            $("#type_name").val("");
        }
    }
    $(function () {
        $("#checkall").click(function () {
            $("input[id='check']").attr("checked", $("#checkall").attr("checked"));
        });
    })
    function GetDeleteItem(url) {
        var str = "";
        var urls = url;
        $("input[id='check']:checked").each(function () {
            str += $(this).val() + ";";
        });
        $("#items").val(str.substring(0, str.length - 1));
        if (str.length > 0) {
            var istrue = window.confirm("是否删除选中项？");
            if (istrue) {
                window.location = urls+"&item=" + $("#items").val();
            }
        }
        else {
            alert("你还没有选择删除项！ ");
        }
    }
</script>
<%LoadUserControl("_footer.ascx", null); %>
