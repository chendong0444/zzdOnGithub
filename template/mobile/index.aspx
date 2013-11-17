<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.FBasePage" %>

<%@ Import Namespace="AS.GroupOn.App" %>
<%@ Import Namespace="AS.Common.Utils" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="System.Collections.Generic" %>
<script runat="server">
    protected IList<ITeam> list_team = null;
    protected TeamFilter filter = new TeamFilter();
    protected IPagers<ITeam> pager = null;
    protected string url = "";
    protected string pagerhtml = "";
    protected ICatalogs catalog = null;
    protected int catalogid = 0;
    protected string cataname = "全部分类";
    public int page = 0;
    public string errtext = String.Empty;
    public string suctext = String.Empty;
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        CookieUtils.SetCookie("pcversion", "0");    //设为触屏版

        if (PageValue.CurrentCity != null)
        {
            CookieUtils.SetCookie("cityid", PageValue.CurrentCity.Id.ToString(), DateTime.Now.AddYears(1));
        }
        else
        {
            CookieUtils.SetCookie("cityid", "0", DateTime.Now.AddYears(1));
        }
        if (Session["err"] != null)
        {
            int type = AS.Common.Utils.Helper.GetInt(Session["type"], 1);
            if (type == 1) errtext = Session["err"].ToString();
            if (type == 2) suctext = Session["err"].ToString();
            Session.Remove("err");
            Session.Remove("type");
        }
        PageValue.Title = PageValue.CurrentSystem.abbreviation + "触屏版";
        if (Request["cataid"] != "" && Request["cataid"] != null)
        {
            catalogid = Helper.GetInt(Request["cataid"], 0);
        }
        if (catalogid > 0)
        {
            using (IDataSession session = Store.OpenSession(false))
            {
                catalog = session.Catalogs.GetByID(catalogid);
            }
        }
        if (catalog != null)
        {
            cataname = catalog.catalogname;
            WebUtils systemmodel = new WebUtils();
            NameValueCollection values = new NameValueCollection();
            NameValueCollection newvalues = new NameValueCollection();
            values = WebUtils.GetSystem();
            if (values["zuijin"] == null)
            {
                values.Add("zuijin", catalogid.ToString());
            }
            else if (!values["zuijin"].ToString().Contains(catalogid.ToString()))
            {
                values.Add("zuijin", catalogid.ToString());
                string[] evalue = values["zuijin"].ToString().Split(',');

                if (evalue.Length > 9)
                {
                    for (int i = 1; i < evalue.Length; i++)
                    {
                        newvalues.Add("zuijin", evalue[i]);
                    }
                }
            }
            systemmodel.CreateSystemByNameCollection(newvalues);
        }
        InitData(catalogid);
    }
    private void InitData(int catalogid)
    {
        ICatalogs catalogs = null;
        CatalogsFilter cataft = new CatalogsFilter();
        IList<ICatalogs> catalis = null;
        string catids = String.Empty;
        if (catalogid > 0)
        {
            using (IDataSession session = Store.OpenSession(false))
            {
                catalogs = session.Catalogs.GetByID(catalogid);
            }
            if (catalogs.parent_id == 0)
            {
                cataft.parent_id = catalogid;
                using (IDataSession session = Store.OpenSession(false))
                {
                    catalis = session.Catalogs.GetList(cataft);
                }
                if (catalis != null && catalis.Count > 0)
                {
                    foreach (ICatalogs item in catalis)
                    {
                        catids = catids + item.id + ",";
                    }
                    filter.CataIDin = catids.Trim(',');
                }
                else
                {
                    filter.CataIDin = catalogid.ToString();
                }
            }
            else
            {
                filter.CataIDin = catalogid.ToString();
            }
        }
        if (ASSystem != null)
        {
            if (CurrentCity != null)
                filter.CityID = Helper.GetInt(CurrentCity.Id, 0);
            page = Helper.GetInt(Request["page"], 1);
            filter.teamcata = 0;
            filter.ToBegin_time = DateTime.Now;
            filter.FromEndTime = DateTime.Now;
            filter.TypeIn = "'normal','draw','goods','seconds'";
            filter.Cityblockothers = Helper.GetInt(CurrentCity.Id, 0);
            filter.PageSize = 30;
            filter.CurrentPage = page;
            filter.AddSortOrder(TeamFilter.Sort_Order_DESC);
            filter.AddSortOrder(TeamFilter.Begin_time_DESC);
            filter.AddSortOrder(TeamFilter.ID_DESC);
            using (IDataSession session = Store.OpenSession(false))
            {
                pager = session.Teams.GetPager(filter);
            }
            list_team = pager.Objects;
            url = GetUrl("手机版首页", "index.aspx?page={0}");
            pagerhtml = WebUtils.GetMBPagerHtml(30, pager.TotalRecords, pager.CurrentPage, url);

        }
    }
    private string GetTeamType(ITeam teammodel)
    {
        string str = String.Empty;
        if (teammodel != null)
        {
            if (teammodel.teamhost == 1)
            {
                str = "<span class=\"mark new\"><i></i>新单</span>";
            }
            else if (teammodel.teamhost == 2)
            {
                str = "<span class=\"mark new\"><i></i>热销</span>";
            }
        }
        return str;
    }
</script>
<%LoadUserControl("_htmlheader.ascx", null); %>
<header>
        <h1 id="logo">
            <a  href="<%=GetUrl("手机版首页","index.aspx") %>"><span><%=PageValue.CurrentSystem.sitename%></span></a>
        </h1>
        <a class="city" href="<%=GetUrl("手机版城市","city.aspx") %>"><%=PageValue.CurrentCity.Name%></a>
        <div id="nav">
            <a class="account"  href="<%=GetUrl("手机版个人中心","account_index.aspx") %>">我的<%=PageValue.CurrentSystem.sitename%></a>
            <a class="category"  href="<%=GetUrl("手机版分类","category.aspx") %>">分类</a>
            <a class="search"  href="<%=GetUrl("手机版搜索","search.aspx") %>">搜索</a>
        </div>
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
<body id='index'>
    <div class="current-category">
        您当前的分类：<%=cataname%></div>
    <div id="deals">
        <%if (list_team != null && list_team.Count > 0)
          {%>
        <% foreach (var item in list_team)
           {%>
        <div>
            <a href="<%=GetMobilePageUrl(item.Id) %>">
                <%=GetTeamType(item) %>
                <img data-src="<%=TeamMethod.GetWapImgUrl(item.PhoneImg)%>" width="122" height="74"
                    alt="<%=item.Product %>" />
                <detail>
                    <ul>
                        <li class="brand"><%=StringUtils.SubString(item.Product,50)%></li>
                        <li class="title indent"><%=StringUtils.SubString(item.Title,50)%></li>
 <li class="price"><strong><%=GetMoney(item.Team_price)%></strong>元<del><%=GetMoney(item.Market_price)%>元</del><span><%=item.Now_number%>人</span></li>
                    </ul>
                </detail>
            </a>
        </div>
        <%}%>
        <%}
          else
          {%>
        <div class="isEmpty">
            抱歉，<%=cataname%>分类下暂时没有项目！敬请稍后关注</div>
        <%}%>
    </div>
    <nav class="pageinator">
    <div id="nav-page">
          <%=pagerhtml%>
    </div>
    <div id="nav-top">
        <span class="nav-button"><span>回到顶部</span></span>
    </div>
</nav>
    <%LoadUserControl("_footer.ascx", null); %>
    <%LoadUserControl("_htmlfooter.ascx", null); %>