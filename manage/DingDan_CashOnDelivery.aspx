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
    protected IList<ICategory> list_category = null;
    protected OrderFilter filter = new OrderFilter();
    protected UserFilter uf = new UserFilter();
    protected PageValue PageValue = new PageValue();
    protected string pagerHtml = String.Empty;
    protected bool result = true;
    protected string url = "";
    protected int id = 0;
    protected string all_id = string.Empty;
    protected string type_name = "";
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        //判断管理员是否有此操作
        if (AdminPage.IsAdmin && AdminPage.CheckUserOptionAuth(PageValue.CurrentAdmin, ActionEnum.Option_Order_Express_ExpressCompany_NoSelectList))
        {

            SetError("你不具有查看未选择快递公司订单列表的权限！");
            Response.Redirect("index_index.aspx");
            Response.End();
            return;
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
            if (Request.QueryString["select_type"] == "1")
            {
                u_filter.Username = type_name;
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    uses = session.Users.Get(u_filter);
                }
                if (uses != null)
                    filter.User_id = uses.Id;
            }
            else if (Request.QueryString["select_type"] == "2")
            {
                u_filter.Email = type_name;
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    uses = session.Users.Get(u_filter);
                }
                if (uses != null)
                    filter.User_id = uses.Id;
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
        
        url = url + "&page={0}";
        url = "DingDan_CashOnDelivery.aspx?" + url.Substring(1);

        filter.State = "nocod";
        filter.PageSize = 30;
        filter.Express_id = 0;
        filter.Express = "Y";
        filter.Service = "cashondelivery";

        filter.AddSortOrder(OrderFilter.ID_DESC);
        filter.CurrentPage = AS.Common.Utils.Helper.GetInt(Request.QueryString["page"], 1);


        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            pager = session.Orders.GetPager(filter);
        }

        list_order = pager.Objects;

        //得到所有的订单id
        foreach (IOrder order in list_order)
        {
            all_id += order.Id + ",";
        }
        pagerHtml = AS.Common.Utils.WebUtils.GetPagerHtml(30, pager.TotalRecords, pager.CurrentPage, url);

    }

    
    private string expresshtml = String.Empty;
    protected string ExpressHtml
    {
        get
        {
            if (expresshtml == String.Empty)
            {
                expresshtml = "<select id='order_express_id_{0}'>";
                //添加快递名称
                CategoryFilter CF = new CategoryFilter();
                CF.Zone = "express";
                CF.AddSortOrder(CategoryFilter.Sort_Order_DESC);

                using (IDataSession seion = AS.GroupOn.App.Store.OpenSession(false))
                {
                    list_category = seion.Category.GetList(CF);
                }

                if (list_category != null && list_category.Count > 0)
                {
                    foreach (ICategory category in list_category)
                    {
                        expresshtml = expresshtml + "<option value=" + category.Id + ">" + category.Name + "</option>";
                    }
                }

                expresshtml = expresshtml + "</select>";

            }
            return expresshtml;
        }
    }

    protected string GetExpressHtml(object orderid)
    {
        return String.Format(ExpressHtml, orderid);
    }


</script>
<%LoadUserControl("_header.ascx", null); %>
<script type="text/javascript">
    var locksubmit;

    $(document).ready(function () {
        $("input[oid]").bind("keydown", function (event) {
         
            locksubmit = true;
            if (event.keyCode == 13) {
                var val = $(this).attr("oid");
                if (val != "undefined") {
                    updateorder(val);
                    var expressid = getnextexpressid($(this).val());
                    var nextsort = parseInt($(this).attr("sort")) + 1;
                    var obj = $("input[sort='" + nextsort + "']");
                    if (obj.length == 1) {
                        $(obj).val(expressid);
                        $(obj).focus();
                    }
                }
                return false;
            }
        });

        $("input[type='button'][oid]").click(function () {
            updateorder($(this).attr("oid"));
        });

        $("form").bind("submit", function (event) {
            if (locksubmit) {
                locksubmit = false;
                return false;
            }
        });

        $(function () {

            $("#checkall").click(function () {
                $("input[id='check']").attr("checked", $("#checkall").attr("checked"));
            });
        })

    });

    function GetOrdersId() {
        var str = "";
        $("input[id='check']:checked").each(function () {
            str += $(this).val() + ",";
        });

        if (str.length > 0) {
            var istrue = window.confirm("您确定批量操作所选订单吗？？");
            if (istrue) {
                X.get(webroot + "manage/ajax_print.aspx?expressid=" + $("#expresses").val() + "&action=selectexpress&all_id=" + str);
            }

        }
        else {
            alert("您还没有选择订单！ ");
        }

    }

    function updateorder(orderid) {
        var no = $("#order_express_no_" + orderid).val();
        X.get(webroot + "manage/ajax_manage.aspx?action=updateorder&orderid=" + orderid + "&expressid=" + $("#order_express_id_" + orderid).val());
    }

</script>
<body class="newbie">
    <div id="pagemasker">
    </div>
    <div id="dialog">
    </div>
    <div id="doc">
        <div id="bdw" class="bdw">
            <div id="bd" class="cf">
                <div id="coupons">
                    <div id="content" class="box-content clear mainwide">
                        <div class="box clear">
                            <div class="box-content">
                                <div class="head">
                                    <h2>
                                        未选择快递</h2>
                                </div>
                                <form id="Form1" runat="server" method="get">
                                <div class="search" style="margin-left:20px;">
                                    生成订单时间：<input type="text" style=" margin-right:0px;" class="h-input" datatype="date" name="begintime"
                                        <%if(!string.IsNullOrEmpty(Request.QueryString["begintime"])){ %>value="<%=Request.QueryString["begintime"] %>"
                                        <%} %> />--<input type="text" class="h-input" datatype="date" name="endtime" <%if(!string.IsNullOrEmpty(Request.QueryString["endtime"])){ %>value="<%=Request.QueryString["endtime"] %>"
                                            <%} %> />&nbsp;&nbsp; 完成订单时间：<input type="text" class="h-input" style=" margin-right:0px;" datatype="date" name="fromfinishtime"
                                                <%if(!string.IsNullOrEmpty(Request.QueryString["fromfinishtime"])){ %>value="<%=Request.QueryString["fromfinishtime"] %>"
                                                <%} %> />--<input type="text" class="h-input" datatype="date" name="endfinishtime"
                                                    <%if(!string.IsNullOrEmpty(Request.QueryString["endfinishtime"])){ %>value="<%=Request.QueryString["endfinishtime"] %>"
                                                    <%} %> />&nbsp;&nbsp; 筛选条件：<select name="select_type">
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
                                                    </select>&nbsp;&nbsp; 内容：<input type="text" style="width: 120px;" name="type_name" class="h-input"
                                                        <%if(!string.IsNullOrEmpty(Request.QueryString["type_name"])){ %>value="<%=Request.QueryString["type_name"] %>"
                                                        <%} %> />&nbsp;&nbsp;
                                    <input type="submit" value="查询" class="formbutton" /></div>
                                </form>
                                <div class="sect">
                                    <table id="orders-list" cellspacing="0" cellpadding="0" border="0" class="coupons-table">
                                        <tr>
                                        <th width="5%"><input type="checkbox" name="checkall" id="checkall" />全选</th>
                                            <th width="10%">
                                                ID
                                            </th>
                                            <th class="xiangmu" width="20%">
                                                项目
                                            </th>
                                            <th width="20%">
                                                用户
                                            </th>
                                            <th width="20%">
                                                派送地址
                                            </th>
                                            <th width="10%">
                                                快递公司
                                            </th>
                                            <th width="15%">
                                                操作
                                            </th>
                                        </tr>
                                        <%    
                                   IUser user = Store.CreateUser();
                                   ITeam team = Store.CreateTeam();
                                   IList<ITeam> teamlist = null;
                                   IList<IOrderDetail> orderlist = null;
                                   int i = 0;      
                                           
                                    foreach (IOrder order in list_order)
                                    {
                                        user = order.User;
                                        team = order.Team;

                                        if (i % 2 != 0)
                                        { %>
                                        <tr>
                                            <%  }
                                        else
                                        { %>
                                        <tr class='alt'>
                                            <%   
}
                                        i++;
                                            %>

                                         <td> <input type="checkbox" name="check" id="check" value='<%=order.Id %>' /></td>
                                            <td >
                                                <% =order.Id%>
                                            </td>
                                            <td class='xiangmu'>
                                                <% 
if (order.Team_id == 0)
{
    teamlist = order.Teams;
    orderlist = order.OrderDetail;
    foreach (IOrderDetail teams in order.OrderDetail)
    {
                                                %>
                                                项目ID:<%= teams.Teamid%>
                                                (<a class="deal-title" href='<%=getTeamPageUrl(teams.Teamid)%>' target="_blank"><% =StringUtils.SubString(teams.Team.Title, 70) + "..."%></a>)<%=StringUtils.SubString(AS.Common.Utils.WebUtils.Getbulletin(teams.result), 0, "<br>")%>
                                                <%
}
}
else
{ %>
                                                项目ID:<%=order.Team_id%>
                                                (<a class="deal-title" href='<%=getTeamPageUrl(order.Team_id)%>' target="_blank">
                                                    <%=StringUtils.SubString(team.Title, 70) + "..."%>
                                                </a>)
                                                <% 
}
if (order.result != null)
    StringUtils.SubString(AS.Common.Utils.WebUtils.Getbulletin(order.result), 0, "<br>");
                                                %>
                                            </td>
                                            <td>
                                            <%if (user != null)
                                              {%>
                                              
                                                <a class="ajaxlink" href='ajax_manage.aspx?action=userview&Id=<%=order.User_id %>'>
                                                    <%=user.Email%><br>
                                                    <%=user.Username%></a>&nbsp;»&nbsp;
                                                    <a class="ajaxlink" href='ajax_manage.aspx?action=sms&v=<%=user.Mobile %>'>短信</a>
                                            
                                            <%} %>
                                            </td>
                                            <td>
                                                <%=order.Address%>
                                            </td>
                                            <td >
                                            <%=GetExpressHtml(order.Id) %>
                                            </td>
                                            <td>
                                                <input type="button" value="保存" oid='<%=order.Id %>' id='orderbutton<%=order.Id %>'>
                                            </td>
                                        </tr>
                                        <% 
}

                                        %>
                                        <tr>

                                           <a onclick="javascript:location.replace(location.href);" href="#">刷新(过滤掉已设置为已发货状态的订单)</a>
                                            <td  colspan="8" >
                                                <% if (pagerHtml != "")
                                                   { %> 
                                                     <%=ExpressHtml.Replace("order_express_id_{0}", "expresses")%>
                                                    <input type="button" name="selexpress" value="批量选择" class="formbutton" style="padding: 1px 6px;" onClick='javascript:GetOrdersId();' />
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
<%LoadUserControl("_footer.ascx", null); %>
