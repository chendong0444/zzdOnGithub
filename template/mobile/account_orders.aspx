﻿<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.FBasePage" %>

<%@ Import Namespace="AS.GroupOn" %>
<%@ Import Namespace="AS.Common" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Accessor" %>
<%@ Import Namespace="AS.Common.Utils" %>
<%@ Import Namespace="AS.GroupOn.App" %>
<%@ Import Namespace="System.Collections.Generic" %>
<script runat="server">
    protected OrderFilter ordermodel = new OrderFilter();
    protected ITeam teammodel = null;
    protected IList<IOrderDetail> detaillist = null;
    protected string pagerhtml = string.Empty;
    string strpage = string.Empty;//内容部分
    protected IPagers<IOrder> pager = null;
    protected IList<IOrder> list_order = null;
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        PageValue.Title = "订单";
        MobileNeedLogin();
        InitData();
    }
    //订单(未付款)
    public void InitData()
    {
        UserFilter usermodel = new UserFilter();
        ordermodel.PageSize = 15;
        ordermodel.CurrentPage = AS.Common.Utils.Helper.GetInt(Request.QueryString["page"], 1);
        ordermodel.AddSortOrder(OrderFilter.ID_DESC);
        string strtable = "(select * from [Order] where Id in ( select * from ( select id from [Order] where"
            + " isnull(State,'')<>'cancel' and User_id=" + AsUser.Id + " and (State='unpay' or State='nocod') and (Team_id in ( select Id from Team where teamcata=0 and Team_type='normal') ) ) as a union "
            + " select * from ( select Order_id from orderdetail where Order_id in ( select id from [Order] where"
            + " isnull(State,'')<>'cancel' and User_id=" + AsUser.Id + " and (State='unpay' or State='nocod') and Team_id=0  ) and Order_id not in ("
            + " select max(Order_id) from orderdetail where Order_id in ( select id from [Order] where isnull(State,'')<>'cancel' and User_id=" + AsUser.Id + " and (State='unpay' or State='nocod') and Team_id=0"
            + " ) group by Order_id having COUNT(*)>1 ) and Teamid in(select id from Team where teamcata=0 and Team_type='normal') ) as b ) ) as c";

        ordermodel.table = strtable;
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            pager = session.Orders.GetBranchPage(ordermodel);
        }
        list_order = pager.Objects;
        if (list_order != null && list_order.Count > 0)
        {
            pagerhtml = WebUtils.GetMBPagerHtml(15, pager.TotalRecords, pager.CurrentPage, GetUrl("手机版个人中心订单", "account_orders.aspx?page={0}"));
        }
    }
    //根据订单编号，查询项目内容
    public string GetTeam(string orderid, string state)
    {
        StringBuilder HtmlBuilder = new StringBuilder();
        IOrder orders = null;
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            orders = session.Orders.GetByID(Helper.GetInt(orderid, 0));
        }
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            teammodel = session.Teams.GetByID(Convert.ToInt32(orders.Team_id));
        }
        if (teammodel != null && teammodel.teamcata == 0)
        {
            if (state == "pay" || state == "unpay" || state == "nocod" || state == "refund" || state == "cancel")
            {
                string imgurl = PageValue.CurrentSystem.domain + WebRoot + (teammodel.PhoneImg == null ? String.Empty : teammodel.PhoneImg);
                if (teammodel.Begin_time <= DateTime.Now && teammodel.End_time > DateTime.Now)
                {
                    HtmlBuilder.AppendFormat("<a href='{0}'>", GetUrl("手机版订单购买", "team_buy.aspx") + teammodel.Id);
                    HtmlBuilder.AppendFormat("<img src='{0}' alt='{1}' width='122' height='74'/>", imgurl, teammodel.Product);
                    HtmlBuilder.AppendFormat("<h3>{0}</h3>", teammodel.Product);
                    HtmlBuilder.Append("<ul>");
                    HtmlBuilder.AppendFormat("<li>数量：{0} 总价：{1}", orders.Quantity, ASSystem.currency + orders.Origin);
                    HtmlBuilder.Append("</ul>");
                    HtmlBuilder.Append("<p class='c-submit c-small'><input type='submit' value='付款'/></p>");
                    HtmlBuilder.Append("</a>");
                }
                else
                {
                    HtmlBuilder.AppendFormat("<a href='{0}'>", "#");
                    HtmlBuilder.AppendFormat("<img src='{0}' alt='{1}' width='122' height='74'/>", imgurl, teammodel.Product);
                    HtmlBuilder.AppendFormat("<h3>{0}</h3>", teammodel.Product);
                    HtmlBuilder.Append("<ul>");
                    HtmlBuilder.AppendFormat("<li>数量：{0} 总价：{1}", orders.Quantity, ASSystem.currency + orders.Origin);
                    HtmlBuilder.Append("</ul>");
                    HtmlBuilder.Append("<p class='c-submit c-small' style='background: none repeat scroll 0 0 #CCCCCC;border: 1px solid #CCCCCC;box-shadow: 1px 1px 4px #CCCCCC;'><input type='submit' value='已过期' style='background: none repeat scroll 0 0 #CCCCCC;'/></p>");
                    HtmlBuilder.Append("</a>");
                }
            }
        }
        else
        {
            OrderDetailFilter orderdatefile = new OrderDetailFilter();
            orderdatefile.Order_ID = Convert.ToInt32(orderid);
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                detaillist = session.OrderDetail.GetList(orderdatefile);
            }
            if (detaillist != null)
            {
                foreach (IOrderDetail model in detaillist)
                {
                    using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                    {
                        teammodel = session.Teams.GetByID(Convert.ToInt32(model.Teamid));
                    }
                    if (teammodel != null && teammodel.teamcata == 0)
                    {
                        string imgurl = PageValue.CurrentSystem.domain + WebRoot + (teammodel.PhoneImg == null ? String.Empty : teammodel.PhoneImg);
                        if (teammodel.Begin_time <= DateTime.Now && teammodel.End_time > DateTime.Now)
                        {
                            if (state == "pay" || state == "unpay" || state == "nocod" || state == "refund" || state == "cancel")
                            {
                                HtmlBuilder.AppendFormat("<a href='{0}'>", GetUrl("手机版订单购买", "team_buy.aspx") + teammodel.Id);
                            }
                            HtmlBuilder.AppendFormat("<img src='{0}' alt='{1}' width='122' height='74'/>", imgurl, teammodel.Product);
                            HtmlBuilder.AppendFormat("<h3>{0}</h3>", teammodel.Product);
                            HtmlBuilder.Append("<ul>");
                            HtmlBuilder.AppendFormat("<li>数量：{0} 总价：{1}", orders.Quantity, ASSystem.currency + orders.Origin);
                            HtmlBuilder.Append("</ul>");
                            HtmlBuilder.Append("<p class='c-submit c-small'><input type='submit' value='付款'/></p>");
                            HtmlBuilder.Append("</a>");
                        }
                        else
                        {
                            if (state == "pay" || state == "unpay" || state == "nocod" || state == "refund" || state == "cancel")
                            {
                                HtmlBuilder.AppendFormat("<a href='{0}'>", "#");
                            }
                            HtmlBuilder.AppendFormat("<img src='{0}' alt='{1}' width='122' height='74'/>", imgurl, teammodel.Product);
                            HtmlBuilder.AppendFormat("<h3>{0}</h3>", teammodel.Product);
                            HtmlBuilder.Append("<ul>");
                            HtmlBuilder.AppendFormat("<li>数量：{0} 总价：{1}", orders.Quantity, ASSystem.currency + orders.Origin);
                            HtmlBuilder.Append("</ul>");
                            HtmlBuilder.Append("<p class='c-submit c-small' style='background: none repeat scroll 0 0 #CCCCCC;border: 1px solid #CCCCCC;box-shadow: 1px 1px 4px #CCCCCC;'><input type='submit' value='已过期' style='background: none repeat scroll 0 0 #CCCCCC;'/></p>");
                            HtmlBuilder.Append("</a>");
                        }
                    }
                }
            }
        }
        return HtmlBuilder.ToString();
    }
</script>
<%LoadUserControl("_htmlheader.ascx", null); %>
<body id='orders'>
    <header>
        <div class="left-box">
            <a class="go-back" href="<%=GetUrl("手机版首页","index.aspx") %>"><span>返回首页</span></a>
        </div>
        <h1>订单</h1>
    </header>
    <menu>
        <ul>
            <li class="current"><a href="<%=GetUrl("手机版个人中心订单","account_orders.aspx") %>">待付款</a></li>
            <li><a href="<%=GetUrl("手机版个人中心订单已退款","account_order_list_refund.aspx") %>">已退款</a></li>
            <li><a href="<%=GetUrl("手机版个人中心订单抽奖单","account_order_list_lottery.aspx") %>">抽奖单</a></li>
            <li><a href="<%=GetUrl("手机版个人中心订单已消费","account_order_list_used.aspx") %>">已付款</a></li>
        </ul>
    </menu>
    <div class="body">
        <div id="orders-tips" class="orders-tips">
            <p>订单状态可能会有延迟，请以实际消费情况为准</p>
        </div>
        <div id="orders-list">
            <%if (list_order != null && list_order.Count > 0)
              {
                  foreach (var order in list_order)
                  {%>
            <div class="order-box">
                <%=GetTeam(order.Id.ToString(), order.State)%>
            </div>
            <%    }
              }
              else
              { %>
            <p class="isEmpty">暂无订单</p>
            <%} %>

            <nav class="pageinator">
                <div id="nav-page">
                    <%=pagerhtml %>
                </div>
                <div id="nav-top">
                    <span class="nav-button" onclick="javascript:void(window.scrollTo(0, 0));"><span>回到顶部</span></span>
                </div>
            </nav>

        </div>
    </div>
<%LoadUserControl("_footer.ascx", null); %>
<%LoadUserControl("_htmlfooter.ascx", null); %>