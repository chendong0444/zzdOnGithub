﻿<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.AdminPage" %>


<%@ Import Namespace="AS.GroupOn" %>
<%@ Import Namespace="AS.Common" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Accessor" %>
<%@ Import Namespace="System.Data" %>
<script runat="server">
    
    protected IPagers<ICatalogs> pager = null;

    protected string pagerHtml = String.Empty;
    protected string url = "";
    protected System.Data.DataTable catalogsdt = null;
    protected IList<ICatalogs> catalogslist = null;
    protected StringBuilder sb2 = new StringBuilder();
    IUser usernew = AS.GroupOn.App.Store.CreateUser();
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            usernew = session.Users.GetByID(PageValue.CurrentAdmin.Id);
        }
        CatalogsFilter catalogsfilter = new CatalogsFilter();

        #region 删除动作
        if (Request["id"] != null)
        {
            ICatalogs catamodel = null;
            CatalogsFilter cataft = new CatalogsFilter();
            cataft.AddSortOrder(CatalogsFilter.ID_DESC);
            IList<ICatalogs> list = null;
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                catamodel = session.Catalogs.GetByID(AS.Common.Utils.Helper.GetInt(Request["id"], 0));
                list = session.Catalogs.GetList(cataft);
            }
            DataTable dt2 = null;
            dt2 = AS.Common.Utils.Helper.ToDataTable(list.ToList());
            if (catamodel != null)
            {
                Delete(dt2, catamodel.parent_id, "", catamodel.id);
            }
            Delete(AS.Common.Utils.Helper.GetInt(Request["id"], 0));
        }
        #endregion

        if (Request["btnselect"] == "筛选")
        {
            if (this.txtcatename.Text != null)
            {
                if (this.txtcatename.Text != "" && this.txtcatename.Text != null)
                {
                    catalogsfilter.catalognameLike = this.txtcatename.Text;
                    Literal2.Text = null;
                }

            }
        }


        //分类
        catalogsfilter.type = 0;
        url = url + "&page={0}";
        url = "Type_catalogs.aspx?" + url.Substring(1);
        //catalogsfilter.PageSize = 30;
        catalogsfilter.AddSortOrder(CatalogsFilter.ID_DESC);
        catalogsfilter.AddSortOrder(CatalogsFilter.Sort_Order_DESC);
        catalogsfilter.CurrentPage = AS.Common.Utils.Helper.GetInt(Request.QueryString["page"], 1);
        catalogsfilter.cityid =","+usernew.City_id.ToString()+",";
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            //pager = session.Catalogs.GetPager(catalogsfilter);
            catalogslist = session.Catalogs.GetList(catalogsfilter);
        }
        //catalogslist = pager.Objects;
        DataTable dt = AS.Common.Utils.Helper.ToDataTable(catalogslist.ToList());
        if (dt.Rows.Count>0)
        {
            BindData(dt, 0, "");
        }
        

        //pagerHtml = AS.Common.Utils.WebUtils.GetPagerHtml(30, pager.TotalRecords, pager.CurrentPage, url);
    }

    #region 根据编号删除分类
    public void Delete(int id)
    {
        CatalogsFilter cataft = new CatalogsFilter();
        cataft.parent_id = id;
        ICatalogs cata = null;
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            cata = session.Catalogs.Get(cataft);
        }

        if (cata != null)
        {
            SetError("友情提示：此类下面有子类，无法删除");
        }
        else
        {
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                int idd = session.Catalogs.Delete(id);
            }
            SetSuccess("友情提示：删除成功");
            Response.Redirect("Type_catalogs.aspx");
        }
    }
    #endregion
    public void Delete(System.Data.DataTable dt, int id, string blank, int cid)
    {
        System.Data.DataView dv = new System.Data.DataView(dt);
        dv.RowFilter = "id = " + id.ToString();
        if (id != 0)
        {
            blank += "|─";
        }
        ICatalogs camodel = null;
        ICatalogs catacmodel = null;
        foreach (DataRowView drv in dv)
        {
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                camodel = session.Catalogs.GetByID(Convert.ToInt32(drv["id"]));
                catacmodel = session.Catalogs.GetByID(cid);
            }
            if (camodel != null)
            {
                camodel.ids = camodel.ids.Replace("," + cid.ToString(), "").Replace(cid.ToString(), "");
                if (catacmodel.ids != "")
                {
                    string[] strcata = catacmodel.ids.Split(',');
                    for (int i = 0; i < strcata.Length; i++)
                    {
                        if (strcata[i] != "")
                        {
                            camodel.ids = camodel.ids.Replace("," + strcata[i], "").Replace(strcata[i], "");
                        }
                    }
                }
                if (AS.Common.Utils.Helper.GetString(camodel.ids, "") != "")
                {
                    if (AS.Common.Utils.Helper.GetString(camodel.ids, "").Substring(0, 1) == ",")
                    {
                        camodel.ids = camodel.ids.Substring(1, camodel.ids.Length - 1);
                    }
                }
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    int idd = session.Catalogs.Update(camodel);
                }
            }
            Delete(dt, Convert.ToInt32(drv["parent_id"]), blank, cid);
        }
    }

    private void BindData(DataTable dt, int id, string blank)
    {

        if (dt != null && dt.Rows.Count > 0)
        {
            DataView dv = new DataView(dt);

            dv.RowFilter = "parent_id = " + id.ToString();
            if (id != 0)
            {

                blank += "|─";
            }

            foreach (DataRowView dr in dv)
            {
                if (dr["parent_id"].ToString() == "0")
                {
                    sb2.Append("<tr class='alt'>");
                }
                else
                {
                    sb2.Append("<tr>");
                }
                sb2.Append("<td>" + dr["id"] + "</td>");
                sb2.Append("<td>" + blank + dr["catalogname"] + "</td>");
                sb2.Append("<td>" + dr["sort_order"] + "</td>");
                sb2.Append("<td>" + dr["parent_id"] + "</td>");
                sb2.Append("<td>" + GetCity(dr["cityid"].ToString()) + "</td>");
                if (dr["visibility"].ToString().Trim() == "0")
                {
                    sb2.Append("<td>显示</td>");
                }
                else
                {
                    sb2.Append("<td>隐藏</td>");
                }

                if (dr["catahost"].ToString().Trim() == "0")
                {
                    sb2.Append("<td>主推</td>");
                }
                else
                {
                    sb2.Append("<td></td>");
                }

                sb2.Append("<td class='op'>");
                sb2.Append("<a  href='Type_addcatalogs.aspx?id=" + dr["id"] + "'>编辑</a>｜");
                sb2.Append("<a  href='Type_catalogs.aspx?id=" + dr["id"] + "'   ask='确认删除吗？'>删除</a>");
                sb2.Append("</td>");
                sb2.Append("</tr>");
                BindData(dt, Convert.ToInt32(dr["id"]), blank);
            }

            Literal2.Text = sb2.ToString();
        }
    }


    public string GetCity(string cityid)
    {
        string mailcitys = String.Empty;
        if (cityid.Length > 0)
        {
            string[] mail = cityid.Split(',');

            for (int j = 0; j < mail.Length; j++)
            {
                ICategory catemodel = null;
                CategoryFilter catefilter = new CategoryFilter();

                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    catemodel = session.Category.GetByID(AS.Common.Utils.Helper.GetInt(mail[j], 0));
                }

                if (catemodel != null)
                {
                    mailcitys = mailcitys + catemodel.Name + ",";
                }
                else
                {
                    if (!mailcitys.Contains("全部城市"))
                    {
                        if (mail[j] == "0")
                        {
                            mailcitys = mailcitys + "全部城市,";
                        }
                    }

                }
            }
        }
        else
        {
            mailcitys = "全部城市";
        }
        return mailcitys;
        //if (mailcitys == String.Empty) mailcitys = "全部城市";

    }
</script>
<%LoadUserControl("_header.ascx", null); %>
<body class="newbie">
    <form id="form1" runat="server">
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
                                        项目分类</h2>
                                    <div class="search">
                                        父类名：<asp:TextBox  CssClass="h-input" ID="txtcatename" runat="server"></asp:TextBox><input id="btnselect"
                                            type="submit" group="a" value="筛选" name="btnselect" class="formbutton validator"
                                            style="padding: 1px 6px;" />
                                            </div>
                                    <ul class="filter">
                                        <li><a href="Type_addcatalogs.aspx">新建项目分类</a></li>
                                    </ul>
                                </div>
                                <div class="sect">
                                    <table id="orders-list" cellspacing="0" cellpadding="0" border="0" class="coupons-table">
                                        <tr>
                                            <th width='10%'>
                                                ID
                                            </th>
                                            <th width='20%'>
                                                分类名称
                                            </th>
                                            <th width='10%'>
                                                排序
                                            </th>
                                            <th width='10%'>
                                                父ID
                                            </th>
                                            <th width='10%'>
                                                城市
                                            </th>
                                            <th width='10%'>
                                                状态
                                            </th>
                                            <th width='10%'>
                                                是否主推
                                            </th>
                                            <th width='20%'>
                                                操作
                                            </th>
                                        </tr>
                                        <asp:Literal ID="Literal2" runat="server"></asp:Literal>
                                        <tr>
                                            <td colspan="6">
                                                <%=pagerHtml %>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- bd end -->
            </div>
            <!-- bdw end -->
        </div>
    </form>
</body>
<%LoadUserControl("_footer.ascx", null); %>
