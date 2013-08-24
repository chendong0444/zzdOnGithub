﻿<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.AdminPage" %>
<%@ Import Namespace="AS.GroupOn" %>
<%@ Import Namespace="AS.Common" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Accessor" %>
<%@ Import Namespace="System.Collections.Generic" %>
<script runat="server">
    protected IFareTemplate faretempalte = null;
    protected FareTemplateFilter ftfilter = new FareTemplateFilter();
    protected IList<IFareTemplate> faretemlist = null;
    protected ProductFilter productfilter = new ProductFilter();
    protected IList<IProduct> productlist = null;
    protected IList<ICatalogs> catalogslist = null;
    protected CatalogsFilter catalogsfilter = new CatalogsFilter();
    protected IList<ICategory> categorylist = null;
    protected IList<ICategory> categorylist2 = null;
    protected IList<ICategory> categorylistpinpai = null;
    protected IList<ICategory> categorylistcity = null;
    public bool ispoint = false;//判断如果是积分项目，那么用户选择了优惠券无法进行提交
    protected CategoryFilter categoryfilter = new CategoryFilter();
    protected CategoryFilter categoryfilterapi = new CategoryFilter();
    protected CategoryFilter categoryfilter2 = new CategoryFilter();
    protected CategoryFilter categoryfiltercity = new CategoryFilter();

    protected IProduct productmodel = null;
    protected System.Data.DataTable categorydt = new System.Data.DataTable();
    protected System.Data.DataTable catalogsdt = new System.Data.DataTable();

    public string isDisplay = "";
    public string bulletin = "";
    public string inven = "";
    public string strcitys = "";
    public bool blag;
    protected string state = "0";
    public ISystem system = null;
    public NameValueCollection _system = null;
    ITeam team = AS.GroupOn.App.Store.CreateTeam();
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        _system = AS.Common.Utils.WebUtils.GetSystem();
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            system = session.System.GetByID(1);
        }
        //分类
        catalogsfilter.type = 0;
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            catalogslist = session.Catalogs.GetList(catalogsfilter);
        }
        catalogsdt = AS.Common.Utils.Helper.ToDataTable(catalogslist.ToList());

        productfilter.Status = 1;
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            productlist = session.Product.GetList(productfilter);
        }

        int titlelenth = Encoding.Default.GetByteCount(title.Value);
        if (titlelenth > 500)
        {
            
            SetError("项目标题长度不能大于500个字符！");
            Response.Redirect("Project_XinjianXiangmu.aspx");
            Response.End();
            return;
           
        }
        if (Request["commit"] == "好了，提交")//Request.HttpMethod=="POST"
        {
            addContent();
            TeamFilter teamft = new TeamFilter();
            teamft.AddSortOrder(TeamFilter.ID_DESC);
            
            ITeam team = null;
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                team = session.Teams.Get(teamft);
            }
            if (team.open_invent != 1)
            {
                Response.Redirect("Project_DangqianXiangmu.aspx", true);
            }
        }
        if (!IsPostBack)
        {
            //产品
            initdorp();
            //项目分类
            BindData(catalogsdt, "0", "", "parent_id", this.ddlparent, "catalogname", "id");
            selectContent();
            setcity();
        }
    }

    /// <summary>
    /// 绑定产品列表
    /// </summary>
    protected void initdorp()
    {

        //快递模版
        ftfilter.AddSortOrder(FareTemplateFilter.ID_DESC);
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            faretemlist = session.FareTemplate.GetList(ftfilter);
        }
        System.Data.DataTable faretemdt = AS.Common.Utils.Helper.ToDataTable(faretemlist.ToList());
        for (int i = 0; i < faretemdt.Rows.Count; i++)
        {
            System.Data.DataRow row = faretemdt.Rows[i];
            faretemplate_drop.Items.Add(new ListItem(row["name"].ToString(), row["id"].ToString()));
        }
        //产品列表
        ddlProduct.Items.Add(new ListItem("---------", "0"));

        System.Data.DataTable productdt = AS.Common.Utils.Helper.ToDataTable(productlist.ToList());

        if (productdt != null)
        {
            if (productdt.Rows.Count > 0)
            {
                for (int i = 0; i < productdt.Rows.Count; i++)
                {
                    ddlProduct.Items.Add(new ListItem(productdt.Rows[i]["id"].ToString() + ":" + productdt.Rows[i]["Productname"].ToString(), productdt.Rows[i]["id"].ToString()));
                }
            }
        }
        ddlProduct.DataBind();
    }
    /// <summary>
    /// 绑定下拉框列表
    /// </summary>
    /// <param name="dt"></param>
    /// <param name="id">ID 值 </param>
    /// <param name="blank">是否需要加符号?不加为null</param>
    /// <param name="sqlvalue">筛选为 ID值 的数据</param>
    /// <param name="listName"> 这里是需要绑定的下拉列表控件ID</param>
    private void BindData(System.Data.DataTable dt, string id, string blank, string sqlvalue, DropDownList listName, string name, string value)
    {

        if (dt != null && dt.Rows.Count > 0)
        {
            System.Data.DataView dv = new System.Data.DataView(dt);
            if (sqlvalue != null && sqlvalue != "")
            {
                dv.RowFilter = sqlvalue + "= " + id;
            }

            if (id != "0" && blank != null)
            {
                blank += "|─";
            }
            foreach (System.Data.DataRowView drv in dv)
            {
                listName.Items.Add(new ListItem(blank + "" + drv[name].ToString(), drv[value].ToString()));
                BindData(dt, drv[value].ToString(), blank, sqlvalue, listName, name, value);
            }
        }

    }


    private void selectContent()
    {
        begintime.Value = System.DateTime.Now.AddDays(1).ToString("yyyy-MM-dd HH:mm:ss");
        endtime.Value = System.DateTime.Now.AddDays(2).ToString("yyyy-MM-dd HH:mm:ss");
        createStarttime.Value = System.DateTime.Now.AddDays(3).ToString("yyyy-MM-dd");
        expiretime.Value = System.DateTime.Now.AddDays(4).ToString("yyyy-MM-dd");
        rech_time.Value = System.DateTime.Now.AddDays(5).ToString("yyyy-MM-dd HH:mm:ss");
        //开启库存费提醒
        ListItem inventory2 = new ListItem();
        inventory2.Text = "否";
        inventory2.Value = "0";
        ListItem inventory1 = new ListItem();
        inventory1.Text = "是";
        inventory1.Value = "1";
        //抽奖短信开启
        ListItem code2 = new ListItem();
        code2.Text = "否";
        code2.Value = "no";
        ListItem code1 = new ListItem();
        code1.Text = "是";
        code1.Value = "yes";
        ddlcode.Items.Add(code1);
        ddlcode.Items.Add(code2);
        //开启库存报警
        ListItem inven_war2 = new ListItem();
        inven_war2.Text = "否";
        inven_war2.Value = "0";
        ListItem inven_war1 = new ListItem();
        inven_war1.Text = "是";
        inven_war1.Value = "1";

        if (_system != null)
        {
            if (_system["inventory"] != null)
            {
                if (_system["inventory"] == "1")
                {
                    inventory1.Selected = true;
                }
                else
                {
                    inventory2.Selected = true;
                }
            }
            if (_system["invent_war"] != null)
            {
                if (_system["invent_war"] == "1")
                {
                    inven_war1.Selected = true;
                }
                else
                {
                    inven_war2.Selected = true;
                }
            }
            if (_system["inventmobile"] != null)
            {
                inventmobile.Value = _system["inventmobile"];
            }
        }

        ddlinventory.Items.Add(inventory2);
        ddlinventory.Items.Add(inventory1);


        ddlinven_war.Items.Add(inven_war2);
        ddlinven_war.Items.Add(inven_war1);

        this.ddlinven_war.DataBind();
        this.ddlinventory.DataBind();

        //品牌分类
        categoryfilter.Zone = "brand";
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            categorylistpinpai = session.Category.GetList(categoryfilter);
        }
        ddlbrand.Items.Clear();
        this.ddlbrand.Items.Add(new ListItem("====请品牌分类=====", "0"));
        foreach (ICategory item in categorylistpinpai)
        {
            this.ddlbrand.Items.Add(new ListItem(item.Name, item.Id.ToString()));
        }
        //添加城市
        ICategory cateby = null;
        string s = AsAdmin.City_id.ToString();
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            cateby = session.Category.GetByID(AsAdmin.City_id);
        }
        if (cateby!=null)
        {
            this.citys.Items.Add(new ListItem(cateby.Name, cateby.Id.ToString()));
        }
        

        //api分类
        BindApiClassData();


        //添加商户        
        IList<IPartner> listPartner = null;
        PartnerFilter partnerFilter = new PartnerFilter();
        partnerFilter.AddSortOrder(PartnerFilter.ID_DESC);
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            listPartner = session.Partners.GetList(partnerFilter);
        }
        shanghu.Items.Clear();
        this.shanghu.Items.Add(new ListItem("===========请选择商户============", "0"));
        foreach (IPartner item in listPartner)
        {
            this.shanghu.Items.Add(new ListItem(item.Title, item.Id.ToString()));
        }

    }

    /// <summary>
    /// api分类初始化  
    /// </summary>
    protected void BindApiClassData()
    {
        categoryfilterapi.Zone = "group";
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            categorylist = session.Category.GetList(categoryfilterapi);
        }
        categorydt = AS.Common.Utils.Helper.ToDataTable(categorylist.ToList());
        groupType.Items.Clear();
        this.groupType.Items.Add(new ListItem("==请选择api分类==", "0"));
        BindData(categorydt, "0", null, "City_pid", this.groupType, "name", "id");
    }

    /// <summary>
    /// 产品列表选择事件
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void ddlProduct_SelectedIndexChanged(object sender, EventArgs e)
    {
        setcity();

        //api分类初始化  
        BindApiClassData();

        int ip = this.ddlProduct.SelectedIndex;
        string productid = this.ddlProduct.SelectedValue;

        if (productid != "0")
        {
            state = "1";
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                productmodel = session.Product.GetByID(AS.Common.Utils.Helper.GetInt(productid, 0));
            }
            if (productmodel != null)
            {
                createproduct.Value = productmodel.productname;
                market_price.Value = productmodel.price.ToString();
                #region 项目的颜色或者尺寸
                string[] bulletinteam = productmodel.bulletin.Replace("{", "").Replace("}", "").Split(',');
                if (productmodel.bulletin.Replace("{", "").Replace("}", "") != "")
                {
                    isDisplay = "style='display:none;'";
                }
                for (int i = 0; i < bulletinteam.Length; i++)
                {
                    string txt = bulletinteam[i];

                    if (bulletinteam[i] != "")
                    {


                        if (bulletinteam[i].Split(':')[0] != "" && bulletinteam[i].Split(':')[1] != "")
                        {
                            bulletin += "<tr>";
                            bulletin += "<td>";

                            if (state == "0")
                            {
                                bulletin += "属性：<input type=\"text\" name=\"StuNamea" + i + "\" value=" + bulletinteam[i].Split(':')[0] + ">数值：<input type=\"text\" name=\"Stuvaluea" + i + "\" value=" + bulletinteam[i].Split(':')[1].Replace("[", "").Replace("]", "") + " >";
                                bulletin += "<input type=\"button\" value=\"删除\" onclick='deleteitem(this," + '"' + "tb" + '"' + ");'>";
                            }
                            else
                            {
                                bulletin += "属性：<input type=\"text\" name=\"StuNamea" + i + "\" value=" + bulletinteam[i].Split(':')[0] + " readonly>数值：<input type=\"text\" name=\"Stuvaluea" + i + "\" value=" + bulletinteam[i].Split(':')[1].Replace("[", "").Replace("]", "") + " readonly>";
                            }
                            bulletin += "</td>";
                            bulletin += "</tr>";

                        }
                    }
                }
                #endregion

                ddlinventory.SelectedValue = productmodel.open_invent.ToString();
                ddlinventory.Enabled = false;
                createdetail.Value = productmodel.detail;

                ImageSet.InnerText = productmodel.imgurl;
                inven = productmodel.inventory.ToString();
                shanghu.SelectedValue = productmodel.partnerid.ToString();
                shanghu.Enabled = false;
                teamPrice.Value = productmodel.team_price.ToString();

                categoryfilter.Zone = "group";
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    blag = session.Category.getCount1(productmodel.brand_id);
                }
                //如果产品的品牌已删除，品牌不选中
                if (blag)
                {
                    ddlbrand.SelectedValue = productmodel.brand_id.ToString();
                }
                else
                {
                    ddlbrand.SelectedValue = "0";
                }
                createsummary.Value = productmodel.summary;
            }


        }
        else
        {
            createproduct.Value = "";
            market_price.Value = "1";
            bulletin = "";
            createdetail.Value = "";
            ImageSet.InnerText = "";
            inven = "";
            shanghu.SelectedValue = "0";
            ddlinventory.Enabled = true;
            shanghu.Enabled = true;
            teamPrice.Value = "1";
            createsummary.Value = "";

        }
    }

    private void setcity()
    {
        StringBuilder sb1 = new StringBuilder();

        categoryfilter2.Zone = "city";
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            categorylist2 = session.Category.GetList(categoryfilter);
        }

        foreach (ICategory category in categorylist2)
        {
            sb1.Append("<input type='checkbox' name='city_id' value='" + category.Id + "' disabled />&nbsp;" + category.Name + "&nbsp;&nbsp;");
        }
        strcitys = sb1.ToString();
    }

    /// <summary>
    /// 添加项目
    /// </summary>
    private void addContent()
    {
        string createUpload = "";
       
        team.User_id = AdminPage.AsAdmin.Id;
        if (projectType.Value != "")
        {
            team.Team_type = projectType.Value;
        }
        if (int.Parse(citys.SelectedItem.Value) > -1)
        {
            team.City_id = int.Parse(citys.SelectedItem.Value);

        }
        if (int.Parse(Request.Form["groupType"].ToString()) > -1)
        {
            team.Group_id = int.Parse(Request.Form["groupType"].ToString());
        }
        team.City_id = AsAdmin.City_id;
        team.catakey = Request["birds"];
        team.cataid = AS.Common.Utils.Helper.GetInt(Request["parent"], 0);//项目分类的编号
        team.commentscore = AS.Common.Utils.Helper.GetDecimal(commentscore.Value, 0);//评论返利的金额
        team.Conduser = Conduse.SelectedItem.Value;
        team.Buyonce = Buyonce.SelectedItem.Value;
        int titlelenth = Encoding.Default.GetByteCount(title.Value);
        if (titlelenth > 500)
        {
            SetError("项目标题长度不能大于500个字符！");
            Response.Redirect("Project_XinjianXiangmu.aspx");
            Response.End();
            return;
        }
        team.Title = HttpUtility.HtmlEncode(title.Value);
        team.Market_price = Convert.ToDecimal(market_price.Value);
        team.Team_price = Convert.ToDecimal(teamPrice.Value);
        team.Min_number = int.Parse(minnumber.Value);
        team.Max_number = int.Parse(maxnumber.Value);
        team.Per_number = int.Parse(pernumber.Value);
        DateTime btime = AS.Common.Utils.Helper.GetDateTime(begintime.Value, DateTime.MinValue);
        DateTime etime = AS.Common.Utils.Helper.GetDateTime(endtime.Value, DateTime.MinValue);
        team.teamscore = Convert.ToInt32(teamscore.Value);
        team.brand_id = Convert.ToInt32(this.ddlbrand.SelectedValue);
        team.invent_war = Convert.ToInt32(invent_war.Value);
        team.score = Convert.ToInt32(score.Value);
        team.seotitle = Request["seotitle"];
        team.seokeyword = Request["seokeyword"];
        team.seodescription = Request["seodescription"];
        team.Per_minnumber = Convert.ToInt32(per_minnumber.Value);
        team.shanhu = Convert.ToInt32(Request["shanhu"]);
        team.codeswitch = (this.ddlcode.SelectedValue);//抽奖短信是否开启
        team.teamcata = 0;//团购项目
        team.othercity = Request.Form["city_id"];//其他城市
        if (Request.Form["ddlarea"] != null)
        {
            team.areaid = int.Parse(Request.Form["ddlarea"].ToString());
        }
        if (Request.Form["ddlcircle"] != null)
        {
            team.circleid = int.Parse(Request.Form["ddlcircle"].ToString());
        }

        if (projectType.Value == "goods" || projectType.Value == "point")
        {
            team.isPredict = 0;
        }
        else
        {
            team.isPredict = AS.Common.Utils.Helper.GetInt(Request["isPredict"], 1);
        }
        if (rech_time.Value != "")
        {
            try
            {
                team.Reach_time = DateTime.Parse(rech_time.Value);
            }
            catch (Exception ex)
            {
                SetError("您输入的成团日期格式不正确,请重新输入");
                Response.Redirect("Project_XinjianXiangmu.aspx");
                Response.End();
            }
        }
        else
        {
            team.Reach_time = null;
        }
        if (btime == DateTime.MinValue)
        {
        }
        else
        {
            if (etime == DateTime.MinValue)
            {
            }
            else
            {
                TimeSpan ts = etime - btime;
                if (expiretime.Value != "")
                {
                    team.Expire_time = Convert.ToDateTime(expiretime.Value.ToString() + " 23:59:59");
                }
                else
                {
                    team.Expire_time = Convert.ToDateTime(AS.Common.Utils.Helper.GetDateTime(begintime.Value, DateTime.Now).ToString("yyyy-MM-dd 23:59:59"));
                }

            }
        }
        team.System = "N";
        team.Begin_time = Convert.ToDateTime(begintime.Value.ToString());
        team.End_time = Convert.ToDateTime(endtime.Value.ToString());
        team.Summary = createsummary.Value;
        team.Notice = creatnotice.Value;
        team.Sort_order = int.Parse(createsort_order.Value);
        if (int.Parse(shanghu.SelectedItem.Value) > 0)
        {
            team.Partner_id = int.Parse(shanghu.SelectedItem.Value);
        }
        else
        {
            team.Partner_id = 0;
        }
        //在项目表中添加sale_id 同时更新到partner表中
        if (Request.Form["xiaoshou"] != null)
        {
            int saleId = int.Parse(Request.Form["xiaoshou"].ToString());
            if (shanghu.SelectedIndex > 0)
            {
                if (saleId > 0)
                {
                    team.sale_id = saleId;
                }
            }
            else
            {
                team.sale_id = 0;
            }
        }

        ///添加分站id
        if (Request.Form["fenzhan"] != null)
        {
            team.branch_id = int.Parse(Request.Form["fenzhan"].ToString());
        }

        team.Card = int.Parse(createcard.Value);
        team.Bonus = int.Parse(createbonus.Value);
        team.Product = createproduct.Value;
        if (Image.FileName != null || Image1.FileName != null || Image2.FileName != null)
        {
            createUpload = setUpload();
        }
        if (Image.FileName != null && Image.FileName != "")
        {
            string uploadName = Image.FileName;//获取待上传图片的完整路径，包括文件名 
            string pictureName = "";//上传后的图片名，以当前时间为文件名，确保文件名没有重复 
            if (Image.FileName != "")
            {
                int idx = uploadName.LastIndexOf(".");
                string suffix = uploadName.Substring(idx);//获得上传的图片的后缀名 
                if (suffix.ToLower() == ".jpg" || suffix.ToLower() == ".png" || suffix.ToLower() == ".gif" || suffix.ToLower() == ".jpeg" || suffix.ToLower() == ".bmp")
                {
                    pictureName = DateTime.Now.Ticks.ToString() + suffix;
                }
                else
                {
                    SetError("图片格式不正确！");
                    Response.Redirect("Project_XinjianXiangmu.aspx");
                    return;
                }
            }
            try
            {
                if (uploadName != "")
                {
                    string path = Server.MapPath(createUpload);
                    if (!System.IO.Directory.Exists(path))
                    {
                        System.IO.Directory.CreateDirectory(path);
                    }
                    Image.PostedFile.SaveAs(path + pictureName);
                    //生成缩略图
                    string strOldUrl = path + pictureName;
                    string strNewUrl = path + "small_" + pictureName;
                    AS.Common.Utils.ImageHelper.CreateThumbnailNobackcolor(strOldUrl, strNewUrl, 235, 150);

                    //图片加水印
                    string drawuse = "";
                    string drawimgType = "";
                    AS.Common.Utils.ImageHelper.DrawImgWord(createUpload + "\\" + pictureName, ref drawuse, ref drawimgType, _system);
                }
            }
            catch (Exception ex)
            {
                Response.Write(ex);
            }
            team.Image = createUpload.Replace("~", "") + pictureName;
        }
        else
        {
            if (Request["imget"] != "")
            {
                team.Image = Request["imget"];
            }
            else if (ImageSet.InnerText != "")
            {
                team.Image = ImageSet.InnerText;
            }
        }
        if (team.Image == null || team.Image == "")
        {
            SetError("图片不能为空！");
            Response.Redirect("Project_XinjianXiangmu.aspx");
            Response.End();
        }
        if (Image1.FileName != null && Image1.FileName != "")
        {
            string uploadName = Image1.FileName;//获取待上传图片的完整路径，包括文件名 
            string pictureName = "";//上传后的图片名，以当前时间为文件名，确保文件名没有重复 
            if (Image1.FileName != "")
            {
                int idx = uploadName.LastIndexOf(".");
                string suffix = uploadName.Substring(idx);//获得上传的图片的后缀名 
                if (suffix.ToLower() == ".jpg" || suffix.ToLower() == ".png" || suffix.ToLower() == ".gif" || suffix.ToLower() == ".jpeg" || suffix.ToLower() == ".bmp")
                {
                    pictureName = DateTime.Now.Ticks.ToString() + 1 + suffix;
                }
                else
                {
                    SetError("图片格式不正确！");
                    Response.Redirect("Project_XinjianXiangmu.aspx");
                    return;
                }
            }
            try
            {
                if (uploadName != "")
                {
                    string path = Server.MapPath(createUpload);
                    if (!System.IO.Directory.Exists(path))
                    {
                        System.IO.Directory.CreateDirectory(path);
                    }
                    Image1.PostedFile.SaveAs(path + pictureName);
                    //图片加水印
                    string drawuse = "";
                    string drawimgType = "";
                    AS.Common.Utils.ImageHelper.DrawImgWord(createUpload + "\\" + pictureName, ref drawuse, ref drawimgType, _system);
                }
            }
            catch (Exception ex)
            {
                Response.Write(ex);
            }
            team.Image1 = createUpload.Replace("~", "") + pictureName;
        }
        else
        {

            if (Request["imget1"] != "")
            {
                team.Image1 = Request["imget1"];
            }
        }
        if (Image2.FileName != null && Image2.FileName != "")
        {
            string uploadName = Image2.FileName;//获取待上传图片的完整路径，包括文件名 
            string pictureName = "";//上传后的图片名，以当前时间为文件名，确保文件名没有重复 
            if (Image2.FileName != "")
            {
                int idx = uploadName.LastIndexOf(".");
                string suffix = uploadName.Substring(idx);//获得上传的图片的后缀名 

                if (suffix.ToLower() == ".jpg" || suffix.ToLower() == ".png" || suffix.ToLower() == ".gif" || suffix.ToLower() == ".jpeg" || suffix.ToLower() == ".bmp")
                {
                    pictureName = DateTime.Now.Ticks.ToString() + 2 + suffix;
                }
                else
                {
                    SetError("图片格式不正确！");
                    Response.Redirect("Project_XinjianXiangmu.aspx");
                    return;
                }
            }
            try
            {
                if (uploadName != "")
                {
                    string path = Server.MapPath(createUpload);
                    if (!System.IO.Directory.Exists(path))
                    {
                        System.IO.Directory.CreateDirectory(path);
                    }
                    Image2.PostedFile.SaveAs(path + pictureName);
                    //图片加水印
                    string drawuse = "";
                    string drawimgType = "";
                    AS.Common.Utils.ImageHelper.DrawImgWord(createUpload + "\\" + pictureName, ref drawuse, ref drawimgType, _system);
                }
            }
            catch (Exception ex)
            {
                Response.Write(ex);
            }
            team.Image2 = createUpload.Replace("~", "") + pictureName;
        }
        else
        {
            if (Request["imget2"] != null)
            {
                team.Image2 = Request["imget2"];
            }
        }
        team.Flv = createflv.Value;
        team.Detail = createdetail.Value;
        team.Userreview = createuserreview.Value;
        team.Systemreview = creatsystemreview.Value;
        team.Delivery = Request.Form["radio"].ToString();
        if (createStarttime.Value != null && createStarttime.Value != "")
        {
            team.start_time = Convert.ToDateTime(createStarttime.Value);
        }
        else
        {
            team.start_time = Convert.ToDateTime(begintime.Value);
        }
        if (Request.Form["radio"].ToString() == "coupon")
        {
            if (team.Team_type == "point")
            {
                ispoint = true;
            }            
            try
            {
                team.Credit = Convert.ToInt32(createcredit.Value);

            }
            catch (Exception)
            {
                SetError("您输入的消费返利格式不正确,请重新输入");
                Response.Redirect("Project_XinjianXiangmu.aspx");
                Response.End();
            }
        }
        else
        {

            team.Credit = 0;
            if (AS.Common.Utils.Helper.GetInt(Request["freighttype"], 0) == 0)
            {
                try
                {
                    team.Fare = Convert.ToInt32(createfare.Value);
                }
                catch (Exception)
                {

                    SetError("您输入的快递费用格式不正确,请重新输入");
                    Response.Redirect("Project_XinjianXiangmu.aspx");
                    Response.End();
                }
                try
                {
                    team.Farefree = int.Parse(createfarefree.Value);
                }
                catch (Exception)
                {

                    SetError("您输入的免单数量格式不正确,请重新输入");
                    Response.Redirect("Project_XinjianXiangmu.aspx");
                    Response.End();
                }
                team.cashOnDelivery = AS.Common.Utils.Helper.GetString(ddlCashOnDelivery.SelectedValue, "0");
            }
            else//使用快递模板
            {
                if (faretemplate_drop.SelectedIndex == -1)
                {
                    SetError("您没有选择快递模板");
                    Response.Redirect("Project_XinjianXiangmu.aspx");
                    Response.End();
                    return;
                }
                else
                {
                    team.freighttype = AS.Common.Utils.Helper.GetInt(faretemplate_drop.SelectedValue, 0);
                    team.Farefree = AS.Common.Utils.Helper.GetInt(farefree2.Value, 0);
                    team.cashOnDelivery = AS.Common.Utils.Helper.GetString(ddlCashOnDelivery.SelectedValue, "0");
                }
            }
            team.Express = createexpress.Value;
        }
        // 库存和报警设置
        team.open_invent = Convert.ToInt32(this.ddlinventory.SelectedValue);
        team.open_war = Convert.ToInt32(this.ddlinven_war.SelectedValue);
        team.warmobile = Request["inventmobile"];
        if (team.Delivery == "coupon")
            team.teamway = this.ddlway.SelectedValue;//项目购买的方式
        else
            team.teamway = expressway.SelectedValue;

        if (team.Delivery == "coupon")
            team.isrefund = this.ddlrefund.SelectedValue;//项目退款的方式
        else
            team.isrefund = "N";
        team.cost_price = Convert.ToDecimal(Cost_price.Value);//商户成本价格
        team.teamscore = AS.Common.Utils.Helper.GetInt(teamscore.Value, 0);
        team.Mobile = createmobile.Value;
        team.Address = createaddress.Value;
        team.teamhost = AS.Common.Utils.Helper.GetInt(Request["host"], 0);//首页推荐热销
        team.drawType = AS.Common.Utils.Helper.GetInt(Request["dtype"], 0);//抽奖方式，0:默认为随机,1按顺序生成
        team.apiopen = AS.Common.Utils.Helper.GetInt(Request["apiopen"], 0);
        //判断状态       //购买数量
        OrderFilter orderft = new OrderFilter();
        IList<IOrder> orderlist = null;
        orderft.State = "pay";
        orderft.Team_id = team.Id;

        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            orderlist = session.Orders.GetList(orderft);
        }
        int count = orderlist.Count;
        //判断选择的内容
        if (team.Conduser == "Y")
        {
            //以购买成功人数成团      //订单数达到最低数量就成功，反则失败，如果订单数达到最高数量就属于卖光状态。
            if (System.DateTime.Now > Convert.ToDateTime(endtime.Value))
            {
                if (count > team.Min_number && team.State != "soldout")
                {
                    team.State = "success";
                }
                else
                {
                    team.State = "failure";
                }
            }
            else
            {
                if (count > team.Max_number)
                {
                    team.State = "soldout";
                }
                else
                {
                    team.State = "none";
                }
            }
        }
        else
        {
            //以产品购买数量成团          //每个订单的购买数量*订单数大于最低数量就成功，反则失败，如果大于最高数量就属于卖光状态。
            int sumNumber = 0;
            foreach (IOrder item in orderlist)
            {
                sumNumber += item.Quantity;
            }
            if (System.DateTime.Now > Convert.ToDateTime(endtime.Value))
            {
                if (sumNumber > team.Min_number && team.State != "soldout")
                {
                    team.State = "success";
                }
                else
                {
                    team.State = "failure";
                }
            }
            else
            {
                if (sumNumber > team.Max_number)
                {
                    team.State = "soldout";
                }
                else
                {
                    team.State = "none";
                }
            }
        }
        team.update_value = 0;
        team.time_interval = 0;
        team.time_state = 0;
        //添加颜色或者尺寸
        if (ddlProduct.SelectedValue != "0")
        {
            IProduct promodel = null;
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                promodel = session.Product.GetByID(int.Parse(ddlProduct.SelectedValue));
            }
            if (promodel != null)
            {
                if (promodel.bulletin == "{}")
                {
                    team.bulletin = "";
                }
                else
                {
                    team.bulletin = promodel.bulletin;
                }
                team.invent_result = promodel.invent_result;
                team.inventory = promodel.inventory;
            }
        }
        else
        {
            team.bulletin = addcolor();
        }
        team.productid = int.Parse(ddlProduct.SelectedValue);


        if (team.productid != 0 && team.bulletin != "" && team.Delivery != "express")
        {
            SetError("友情提示：该项目的产品有规格只能选择快递的递送方式");
            Response.Redirect("Project_XinjianXiangmu.aspx");
            Response.End();
            
        }

        if (Request.Form["ddllevelcity"] != null)
        {
            team.level_cityid = AS.Common.Utils.Helper.GetInt(Request.Form["ddllevelcity"].ToString(), 0);
        }
        if (team.Team_type == "point" && team.teamscore <= 0)
        {
            SetError("友情提示：积分项目兑换积分数目必须大于0");
            Response.Redirect("Project_XinjianXiangmu.aspx");
            Response.End();
        }
        if (ispoint && team.teamscore > 0)
        {
            SetSuccess("友情提示：积分项目无法选择优惠券");
            Response.Redirect("Project_XinjianXiangmu.aspx");
            Response.End();
        }
        else
        {
            if (team.Delivery == "coupon" && AS.Common.Utils.Utility.Getbulletin(team.bulletin) != "")
            {
                team.bulletin = "";
                int a = 0;
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    a = session.Teams.Insert(team);
                }
                if (a > 0)
                {
                    if (AS.Common.Utils.Helper.GetInt(team.open_invent, 0) == 1)//开启库存
                    {
                        if (team.productid == 0)
                        {
                          
       
                        }
                        else
                        {
                            SetSuccess("友情提示：添加项目成功");
                            Response.Redirect("Project_DangqianXiangmu.aspx");
                            Response.End();
                        }
                    }
                    else
                    {
                        SetSuccess("友情提示：优惠券项目添加成功，此项目没有规格");
                        Response.Redirect("Project_DangqianXiangmu.aspx");
                        Response.End();
                    }
                }
            }
            else
            {
                int a = 0;
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    a = session.Teams.Insert(team);
                }
                if (a > 0)
                {
                    if (AS.Common.Utils.Helper.GetInt(team.open_invent, 0) == 1)//开启库存
                    {
                        if (team.productid == 0)
                        {
                            
                        }
                        else
                        {
                            SetSuccess("友情提示：添加项目成功");
                            Response.Redirect("Project_DangqianXiangmu.aspx");
                            Response.End();
                        }
                    }
                    else
                    {
                        SetSuccess("友情提示：添加项目成功");
                        Response.Redirect("Project_DangqianXiangmu.aspx");
                        Response.End();
                    }

                }
            }
        }
    }
    /// <summary>
    /// 显示文件夹信息
    /// </summary>

    public string setUpload()
    {
        string result1 = "~/upload/team/";
        string path = Server.MapPath("~/upload/team/");
        if (!System.IO.Directory.Exists(path))
        {
            System.IO.Directory.CreateDirectory(path);
        }
        result1 = result1 + DateTime.Now.Year + "/";
        path = path + DateTime.Now.Year + "/";
        if (!System.IO.Directory.Exists(path))
            System.IO.Directory.CreateDirectory(path);
        path = path + DateTime.Now.ToString("MMdd");
        if (!System.IO.Directory.Exists(path))
            System.IO.Directory.CreateDirectory(path);
        result1 = result1 + DateTime.Now.ToString("MMdd") + "/";


        return result1;
    }
    public string addcolor()
    {
        string str = "";
        try
        {
            if (Request["totalNumber"] != null && Request["totalNumber"] != "")
            {
                int num = Convert.ToInt32(Request["totalNumber"]);
                str += "{";
                for (int i = 0; i < Convert.ToInt32(Request["totalNumber"]); i++)
                {
                    if (Request["StuName" + i] != null && Request["Stuvalue" + i] != null && Request["StuName" + i].ToString() != "" && Request["Stuvalue" + i].ToString() != "")
                    {
                        str += Request["StuName" + i].Replace(":", "").Replace("-", "").Replace("[", "").Replace("]", "").Replace("{", "").Replace("}", "").Replace(".", "").Replace(",", "") + ":";
                        str += "[";
                        str += Request["Stuvalue" + i].Replace(":", "").Replace("-", "").Replace("[", "").Replace("]", "").Replace("{", "").Replace("}", "").Replace(".", "").Replace(",", "");
                        str += "]";
                        str += ",";
                    }
                }
                str += "}";
            }
        }
        catch (Exception ex)
        {
            SetError("友情提示：项目格式不正确");
        }
        return str;
    }
</script>
<%LoadUserControl("_header.ascx", null); %>
<%if (AS.Common.Utils.Helper.GetInt(team.open_invent, 0) == 1)
  {%>
<script language='javascript'>
    if (!confirm('友情提示：已开启库存功能，是否进行出入库操作！')) { location.href = 'Project_DangqianXiangmu.aspx' } else { X.get('/manage/ajax_coupon.aspx?action=invent&p=d&inventid=<%=team.Id %>') }</script>
  <%}%>
<script type="text/javascript" language="javascript">
    function setTimeTxt(obj) {
        var type = obj.value;
        if (type == "seconds" || type == "normal") {

            var begin = document.getElementById("begintime").value + " 00:00:00";
            var end = document.getElementById("endtime").value + " 00:00:00";
            if (begin.length > 19) {
                begin = begin.substring(0, 19);
            }
            if (end.length > 19) {
                end = end.substring(0, 19);
            }
            document.getElementById("begintime").value = begin;
            document.getElementById("endtime").value = end;
            jQuery("#begintime").attr("datatype", "datetime");
            jQuery("#endtime").attr("datatype", "datetime");
            document.getElementById("projectype").value = type;
        }
        else {

            var begin = document.getElementById("begintime").value;
            var end = document.getElementById("endtime").value;
            if (begin.length > 10) {

                begin = begin.substring(0, 10);
            }
            document.getElementById("begintime").value = begin;

            if (end.length > 10) {
                end = end.substring(0, 10);
            }

            document.getElementById("endtime").value = end;
            jQuery("#begintime").attr("datatype", "date");
            jQuery("#endtime").attr("datatype", "date");
            jQuery("#begintime").each(function () { this.onfocus = ""; });
            jQuery("#endtime").each(function () { this.onfocus = ""; });
        }
        ischange(obj);
    }


    jQuery(function () {
        if (document.getElementById("zonediv2").checked == true) 
    { 
            $("#express_zone_coupon").hide();
            $("#express_zone_express").show();
            //$("#expressmemo").show();

            $("#fanli").hide();
            $("#start").hide();
            $("#way").hide();
            $("#refund").hide();
            $("#drawmobile").hide();
            $("#drawtype").hide();
        }
        $("input[type=radio]").click(function () {


            if ($("input[type=radio]:checked").val() == "coupon") {

                $("#express_zone_express").hide();
                $("#express_zone_coupon").show();
                $("#fanli").show();
                $("#start").show();
                $("#way").show();
                $("#refund").show();
                $("#drawmobile").hide();
                $("#drawtype").hide();
            }
            else if ($("input[type=radio]:checked").val() == "express") {
                $("#express_zone_coupon").hide();
                $("#express_zone_express").show();
                //$("#expressmemo").show();

                $("#fanli").hide();
                $("#start").hide();
                $("#way").hide();
                $("#refund").hide();
                $("#drawmobile").hide();
                $("#drawtype").hide();
            } else if ($("input[type=radio]:checked").val() == "draw") {
                $("#express_zone_coupon").hide();
                $("#express_zone_express").hide();
                $("#fanli").hide();
                $("#start").hide();
                $("#way").hide();
                $("#refund").hide();
                $("#drawmobile").show();
                $("#drawtype").show();

            } else if ($("input[type=radio]:checked").val() == "pcoupon") {
                $("#express_zone_express").hide();
                $("#express_zone_coupon").show();
                $("#fanli").hide();
                $("#start").show();
                $("#way").hide();
                $("#refund").hide();
                $("#drawmobile").hide();
                $("#drawtype").hide();
            }

            if ($(this).attr("id") == "freighttype0") {
                $("#type0").show();
                $("#type1").hide();
            }
            else if ($(this).attr("id") == "freighttype1") {
                $("#type1").show();
                $("#type0").hide();
            }

        });
    });

    function show(mydiv) {
        var str = "img" + mydiv;
        alert(str);

        var obj = document.getElementById("img0");
        alert(obj.value);
    }


    var num = 0;

    function upload() {
        document.getElementById("status").innerHTML = "文件上传中...";
        multiUploadForm.submit();
    }

    function ischange(obj) {
        if (obj.value == "goods") {
            $("#divIsPredict").hide();
        } else {
            if (obj.value != "point") {
                $("#divIsPredict").show();
            }
        }

        if (obj.value == "point") {

            $("#dparent").hide();
            $("#dbrand").hide();
            $("#dhost").hide();
            $("#field_notice").hide();
            $("#summery").hide();
            $("#field_userreview").hide();
            $("#field_systemreview").hide();
            $("#express_zone_coupon").hide();
            $("#express_zone_express").show();
            $("#fanli").hide();
            $("#start").hide();
            $("#way").hide();
            $("#refund").hide();
            $("#drawmobile").hide();
            $("#coupon").hide();
            $("#pcoupon").hide();
            $("#express").show();
            $("#draw").hide();
            document.getElementById("zonediv2").checked = true;
            $("#price").hide();
            $("#pscore").show();
            $("#ctime").hide();
            $("#bkey").hide();
            $("#apitype").hide();
            $("#fscore").hide();
            $("#divIsPredict").hide();

        } else {

            $("#dparent").show();
            $("#dbrand").show();
            $("#dhost").show();
            $("#field_notice").show();
            $("#summery").show();
            $("#field_userreview").show();
            $("#field_systemreview").show();
            $("#express_zone_express").hide();
            $("#express_zone_coupon").show();
            $("#fanli").show();
            $("#start").show();
            $("#way").show();
            $("#refund").show();
            $("#drawmobile").hide();
            document.getElementById("zonediv1").checked = true;
            $("#coupon").show();
            $("#pcoupon").show();
            $("#express").show();
            $("#draw").show();
            $("#price").show();
            $("#pscore").hide();
            $("#ctime").show();
            $("#bkey").show();
            $("#apitype").show();
            $("#fscore").show();
            if (obj.value != "goods") {
                $("#divIsPredict").show();
            }
        }
    }

    function additem(id) {
        var row, cell, str;
        row = document.getElementById(id).insertRow(-1);
        if (row != null) {
            cell = row.insertCell(-1);
            cell.innerHTML = "属性：<input type=\"text\" name=\"StuName" + num + "\">数值：<input type=\"text\" name=\"Stuvalue" + num + "\"><input type=\"button\" value=\"删除\" onclick='deleteitem(this," + '"' + "tb" + '"' + ");'>";
        }
        num++
        document.getElementsByName("totalNumber")[0].value = num;
    }
    function deleteitem(obj, id) {
        var rowNum, curRow;
        curRow = obj.parentNode.parentNode;
        rowNum = document.getElementById(id).rows.length - 1;
        document.getElementById(id).deleteRow(curRow.rowIndex);
    }
    function callback(msg) {
        document.getElementById("status").innerHTML = "文件上传完成...<br>" + msg;
    }

    function getkey(obj) {

        if (obj.value != 0) {
            $.ajax({
                type: "POST",
                url: "ajax_key.aspx?key=" + obj.value + "",

                success: function (msg) {
                    if (msg != "") {
                        $("#aa").html(msg);
                    }

                }
            });
        } else {
            $("#key").html("");
        }


    }

    function checkallcity() {
        var str = $("#cityall").attr('checked');

        if (str) {

            $('[name=city_id]').attr('checked', true);
        }
        else {

            $('[name=city_id]').attr('checked', false);
        }

    }
       
</script>
<script type="text/javascript">
    function getcircle() {
        var str = jQuery("#ddlarea").val();

        $.ajax({
            type: "POST",
            url: "manage_ajax_Areadroplist.aspx?zone=circle",
            data: { "cityid": str },
            success: function (msg) {
                $("#lblcircle").html(msg);
            }
        });


    }

    function getlevelcity() {
        var levelcity = jQuery("#ddllevelcity").val();

        $.ajax({
            type: "POST",
            url: "manage_ajax_othercitys.aspx",
            data: { "lcity": levelcity },
            success: function (msg) {

                $("#cityother").html(msg);
            }
        });

        $.ajax({
            type: "POST",
            url: "manage_ajax_Areadroplist.aspx?zone=levelcity",
            data: { "cityid": levelcity },
            success: function (msg) {
                $("#lblarea").html(msg);
                $("#lblcircle").html("");
            }
        });


    }

    $(document).ready(function () {

            var str = jQuery("#citys").val();

            if (str != "") {

                if (str == "0") {
                    $('[name=cityall]').attr('disabled', true);
                } else {
                    $('[name=cityall]').attr('disabled', false);
                }
                $.ajax({
                    type: "POST",
                    url: "manage_ajax_othercitys.aspx",
                    data: { "cityid": str },
                    success: function (msg) {

                        $("#cityother").html(msg);
                    }
                });

                $.ajax({
                    type: "POST",
                    url: "manage_ajax_Areadroplist.aspx?zone=area",
                    data: { "cityid": str },
                    success: function (msg) {
                        $("#lblcircle").html("");
                        var msgarray = msg.split('&');
                        if (msgarray[0] == "1") {
                            $("#lblarea").html(msgarray[1]);
                            $("#level_city").hide();
                            $("#level_city").html("");
                        }
                        else {
                            $("#level_city").show();
                            $("#level_city").html(msgarray[1]);
                            $("#lblarea").html("");
                        }
                    }
                });
            }
        });


</script>
<script type="text/javascript">
    $(document).ready(function () {
        var str = jQuery("#shanghu").val();
        if (str != "" & str != "0") {
            $("#saleceng").show();
            $.ajax({
                type: "POST",
                url: "manage_ajax_getsales.aspx",
                data: { "partnerid": str },
                success: function (msg) {

                    $("#all_Sales").html(msg);

                }
            });
        }
        else {
            $("#saleceng").hide();
        }

        jQuery("#shanghu").change(function () {
            //            $("#saleceng").show();
            var str = jQuery("#shanghu").val();
            //            if (str == "0") {
            //                $("#saleceng").hide();
            //            }

            if (str != "" & str != "0") {
                $("#saleceng").show();
                $.ajax({
                    type: "POST",
                    url:  "manage_ajax_getsales.aspx",
                    data: { "partnerid": str },
                    success: function (msg) {

                        $("#all_Sales").html(msg);

                    }
                });
            }
            else {
                $("#saleceng").hide();
            }
        });


        //分站
        if (str != "" & str != "0") {
            $("#branchzeng").show();
            $.ajax({
                type: "POST",
                url:  "manage_ajax_getbranch.aspx",
                data: { "partnerid": str },
                success: function (msg) {

                    $("#all_branch").html(msg);

                }
            });
        }
        else {
            $("#branchzeng").hide();
        }

        $("#shanghu").change(function () {
            var str = $("#shanghu").val();

            if (str != "" & str != "0") {
                $("#branchzeng").show();
                $.ajax({
                    type: "POST",
                    url: "manage_ajax_getbranch.aspx",
                    data: { "partnerid": str },
                    success: function (msg) {

                        $("#all_branch").html(msg);

                    }
                });
            }
            else {
                $("#branchzeng").hide();
            }
        });




    })
</script>
<script type="text/javascript">
    $(function () {
        function split(val) {
            return val.split(/,\s*/);
        }
        function extractLast(term) {
            return split(term).pop();
        }
        $("#pernumber").blur(function () {

            var minnum = $("#per_minnumber").val();
            var pernum = $("#pernumber").val();
            if (parseInt(pernum) < parseInt(minnum) && parseInt(pernum) != 0) {

                $("#pernumber").attr("class", "number errorInput");
            }

        });

        $("#birds")
        // don't navigate away from the field on tab when selecting an item
			.bind("keydown", function (event) {
			    if (event.keyCode === $.ui.keyCode.TAB &&
						$(this).data("autocomplete").menu.active) {
			        event.preventDefault();
			    }
			})
			.autocomplete({

			    source: function (request, response) {
			        $.getJSON("ajax_key.aspx?key=" + $("#birds").val(), {
			            term: extractLast(request.term)
			        }, response);
			    },


			    search: function () {
			        // custom minLength
			        var term = extractLast(this.value);
			        if (term.length < 1) {
			            return false;
			        }
			    },
			    focus: function () {
			        // prevent value inserted on focus
			        return false;
			    },
			    select: function (event, ui) {
			        var terms = split(this.value);
			        // remove the current input
			        terms.pop();
			        // add the selected item
			        terms.push(ui.item.value);
			        // add placeholder to get the comma-and-space at the end
			        terms.push("");
			        this.value = terms.join(", ");
			        return false;
			    }
			});
    });
</script>
<body class="newbie">
    <form id="form1" runat="server" type="post">
    <div id="pagemasker">
    </div>
    <div id="dialog">
    </div>
    <div id="doc">
        <div id="bdw" class="bdw">
            <div id="bd" class="cf">
                <div id="coupons">
                    <div id="content" class="box-content">
                        <div class="box clear">
                            <div class="box-content clear mainwide">
                                <div class="head">
                                    <h2>
                                        新建项目</h2>
                                </div>
                                <div class="sect">
                                    <div class="wholetip clear">
                                        <h3>
                                            1、基本信息</h3>
                                    </div>
                                    <div class="field">
                                        <label>
                                            产品</label>
                                        <asp:DropDownList ID="ddlProduct" name="ddlProduct" runat="server" class="f-input"
                                            Style="width: 360px;" AutoPostBack="True" OnSelectedIndexChanged="ddlProduct_SelectedIndexChanged">
                                        </asp:DropDownList>
                                        <input type="hidden" name="Productid" id="Productid" value="<%=ddlProduct.SelectedIndex%>" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            项目类型</label>
                                        <select id="projectType" class="f-input" style="width: 160px;" onChange="setTimeTxt(this)"
                                            name="projectType" runat="server">
                                            <option value="normal" selected="selected">团购项目</option>
                                            <option value="seconds">秒杀项目</option>
                                            <option value="goods">热销商品</option>
                                            <option value="point">积分项目</option>
                                        </select>
                                    </div>
                                    <div class="field" id="divIsPredict">
                                        <label>
                                            团购预告</label>
                                        <select id="selIsPredict" name="isPredict" style="float: left;">
                                            <option value="1">开启</option>
                                            <option value="0">关闭</option>
                                        </select>
                                    </div>
                                    <div class="field" id="dparent">
                                        <label>
                                            项目分类</label>
                                        <asp:DropDownList ID="ddlparent" runat="server">
                                        </asp:DropDownList>
                                    </div>
                                    <div class="field" id="bkey">
                                        <label for="birds">
                                            关键字:
                                        </label>
                                        <input id="birds" size="30" name="birds" type="text" />
                                        <span class="hint" id="SPAN4">请输入关键词前几个字符，系统会自动匹配分类中类似的关键词。多个关键词以"，"号隔开。</span>
                                    </div>
                                    <div class="field" id="apitype">
                                        <label>
                                            api分类</label>
                                        <asp:DropDownList ID="groupType" name="groupType" class="f-input" runat="server"
                                            Style="width: 160px;">
                                        </asp:DropDownList>
                                    </div>
                                    <div class="field" id="dbrand">
                                        <label>
                                            品牌分类</label>
                                        <asp:DropDownList ID="ddlbrand" name="ddlbrand" class="f-input" runat="server" Style="width: 160px;">
                                        </asp:DropDownList>
                                    </div>
                                    <div class="field" id="dhost">
                                        <label>
                                            首页推荐</label>
                                        <select id="host" name="host" style="width: 160px;" class="f-input">
                                            <option value="0">请选择</option>
                                            <option value="1">新品</option>
                                            <option value="2">推荐</option>
                                        </select>
                                        <span class="hint" id="SPAN5">仅一日多团4和一日多团5可用</span>
                                    </div>
                                    <div class="field" id="field_city" style="height: 38px;">
                                        <label id="label1" runat="server">
                                            城市</label>
                                        <asp:DropDownList ID="citys" name="citys" class="f-input" runat="server" Style="width: 160px;">
                                        </asp:DropDownList>
                                        <label id="level_city">
                                        </label>
                                        <label id="lblarea">
                                        </label>
                                        <label id="lblcircle">
                                        </label>
                                    </div>
                                   
                                    <div class="field" id="field_limit">
                                        <label>
                                            限制条件</label>
                                        <asp:DropDownList ID="Conduse" runat="server" class="f-input" Style="width: 160px;">
                                            <asp:ListItem Value="Y" Selected="True">以购买成功人数成团</asp:ListItem>
                                            <asp:ListItem Value="N">以产品购买数量成团</asp:ListItem>
                                        </asp:DropDownList>
                                        <asp:DropDownList ID="Buyonce" runat="server" class="f-input" Style="width: 160px;">
                                            <asp:ListItem Value="Y" Selected="True">仅购买一次</asp:ListItem>
                                            <asp:ListItem Value="N">可购买多次</asp:ListItem>
                                        </asp:DropDownList>
                                    </div>
                                    <div class="field">
                                        <label>
                                            项目标题</label>
                                        <input type="text" size="100" name="title" id="title" class="f-input" group="g" require="true"
                                            datatype="require" runat="server" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            SEO标题</label>
                                        <input type="text" size="30" name="seotitle" id="seotitle" maxlength="250" class="f-input"
                                            group="g" /><span class="inputtip"></span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            SEO关键字</label>
                                        <input type="text" size="30" name="seokeyword" id="seokeyword" maxlength="250" class="f-input"
                                            group="g" /><span class="inputtip"></span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            SEO描述</label>
                                        <input type="text" size="30" name="seodescription" maxlength="1000" id="seodescription"
                                            class="f-input" group="g" /><span class="inputtip"></span>
                                    </div>
                                    <%if (state == "0")
                                      { %>
                                    <div class="field">
                                        <label>
                                            项目规格</label>
                                        <input type="button" name="btnAddFile" class="formbutton" value="添加" onClick="additem('tb')" /><font
                                            style='color: red; margin-left:10px;'>例如：属性填写：颜色 数值填写：红色|黄色|蓝色</font>
                                    </div>
                                    <%} %>
                                    <div class="field">
                                        <label>
                                        </label>
                                        <table id="tb">
                                            <%=bulletin%>
                                        </table>
                                        <input type="hidden" name="totalNumber" value="" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            市场价</label>
                                        <input type="text" size="10" name="market_price" id="market_price" class="number"
                                            value="1" datatype="money" group="g" require="true" runat="server" />
                                        <div id="price">
                                            <label>
                                                网站价</label>
                                            <input type="text" size="10" name="team_price" id="teamPrice" class="number" value="1"
                                                group="g" datatype="double" require="true" runat="server" />
                                        </div>
                                        <div id="pscore" style="display: none;">
                                            <label>
                                                兑换积分</label>
                                            <input type="text" size="10" name="teamscore" id="teamscore" class="number" value="0"
                                                group="g" datatype="number" runat="server" />
                                        </div>
                                        <label>
                                            最低购买数量</label>
                                        <input type="text" size="10" name="per_minnumber" id="per_minnumber" class="number"
                                            value="1" maxlength="6" group="g" datatype="number" require="true" runat="server" />
                                    </div>
                                    <div class="field" id="field_num">
                                        <label>
                                            成团最低数量</label>
                                        <input type="text" size="10" name="min_number" id="minnumber" class="number" value="1"
                                            maxlength="6" datatype="number" group="g" require="true" runat="server" />
                                        <label>
                                            最高数量</label>
                                        <input type="text" size="10" name="max_number" id="maxnumber" class="number" value="0"
                                            maxlength="6" datatype="number" group="g" require="true" runat="server" />
                                        <label>
                                            每单限购</label>
                                        <input type="text" size="10" name="per_number" id="pernumber" class="number" value="1"
                                            maxlength="6" group="g" datatype="number" require="true" runat="server" />
                                        <span class="hint">最低数量必须大于0，最高数量/每人限购：0 表示没最高上限 （产品数|人数 由成团条件决定）</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            开始时间</label>
                                        <input type="text" name="begin_time" id="begintime"  onclick="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'});"
                                            group="g" require="true" datatype="require" class="date" value="" runat="server" />
                                        <label>
                                            结束时间</label><input type="text" name="end_time"  onclick="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'});"
                                                id="endtime" group="g" require="true" datatype="require" class="date" runat="server" />
                                        <div id="ctime">
                                            <label>
                                                优惠券有效期</label>
                                            <input type="text" size="10" name="expire_time" id="expiretime" onClick="WdatePicker({dateFmt:'yyyy-MM-dd'});"
                                                class="number" maxlength="10" group="g" datatype="date" runat="server" />
                                            <span class="hint" id="SPAN1" runat="server">时间格式：hh:ii:ss (例：14:05:58)，日期格式：YYYY-MM-DD
                                                （例：2010-06-10）</span>
                                        </div>
                                    </div>
                                    <div class="field">
                                        <label>
                                            成本价</label>
                                        <input type="text" name="Cost_price" id="Cost_price" group="g" datatype="money" class="date"
                                            value="0" runat="server" />
                                        <span class="hint" id="SPAN6" runat="server">用于商户结算</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            成团时间</label>
                                        <input type="text" name="rech_time" id="rech_time" group="g" onFocus="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'});"
                                            datatype="datetime" class="date" value="" runat="server" />
                                        <span class="hint" id="SPAN3" runat="server">日期格式:（例：2010-06-10 00:00:00）</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            排序</label>
                                        <input type="text" size="10" name="sort_order" id="createsort_order" class="number"
                                            value="0" group="g" datatype="number" runat="server" /><span class="inputtip">请填写数字，数值大到小排序，主推团购应设置较大值</span>
                                    </div>
                                    <div class="field" id="fscore">
                                        <label>
                                            返利积分值</label>
                                        <input type="text" size="10" name="score" id="score" class="number" value="0" group="g"
                                            datatype="number" runat="server" /><span class="inputtip">积分值</span>
                                    </div>
                                    <div class="field" id="summery">
                                        <label>
                                            本单简介</label>
                                        <div style="float: left;">
                                            <textarea cols="45" rows="5" name="createsummary" id="createsummary" class="f-textarea xheditor {upImgUrl:'../upload.aspx?immediate=1&t=0',urlType:'abs'}"
                                                runat="server"></textarea></div>
                                    </div>
                                    <div class="field" id="field_notice">
                                        <label>
                                            特别提示</label>
                                        <div style="float: left;">
                                            <textarea cols="45" rows="5" name="notice" id="creatnotice" class="f-textarea xheditor {upImgUrl:'../upload.aspx?immediate=1&t=0',urlType:'abs'}"
                                                runat="server"></textarea></div>
                                        <span class="hint">关于本单项目的有效期及使用说明</span>
                                    </div>
                                    <!--kxx 增加-->
                                    <div class="wholetip clear">
                                        <h3>
                                            2、库存信息</h3>
                                    </div>
                                    <div class="field">
                                        <label>
                                            启用库存</label>
                                        <asp:DropDownList ID="ddlinventory" Style="float: left;" runat="server">
                                        </asp:DropDownList>
                                        <span class="inputtip">是否开启库存功能</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            启用库存报警</label>
                                        <asp:DropDownList ID="ddlinven_war" Style="float: left;" runat="server">
                                        </asp:DropDownList>
                                        <span class="inputtip">是否开启库存报警功能</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            库存报警电话</label>
                                        <input id="inventmobile" type="text" class="number" name="inventmobile" value="0"
                                            runat="server" datatype="money" group="go" />
                                        <span class="inputtip">当库存报警是，系统会自动给库存报警电话，发送短信信息</span>
                                    </div>
                                    <%if (inven != "")
                                      { %>
                                    <div class="field">
                                        <label>
                                            库存数量</label>
                                        <span class="inputtip">
                                            <%=inven%></span>
                                    </div>
                                    <%} %>
                                    <div class="field">
                                        <label>
                                            报警数量</label>
                                        <input type="text" size="10" name="invent_war" id="invent_war" class="number" value="0"
                                            group="g" datatype="number" runat="server" /><span class="inputtip">请填写数字，库存报警数量</span>
                                    </div>
                                    <!--xxk-->
                                    <input type="hidden" name="guarantee" value="Y" id="Hidden1" runat="server" />
                                    <input type="hidden" name="system" value="Y" id="Hidden2" runat="server" />
                                    <div class="wholetip clear">
                                        <h3>
                                            3、项目信息</h3>
                                    </div>
                                    <div class="field">
                                        <label>
                                            商户</label><div>
                                        <asp:DropDownList ID="shanghu" runat="server" CssClass="f-shinput">
                                        </asp:DropDownList>
                                        </div>
                                        <span class="inputtip">商户为可选项</span>
                                    </div>
                                    <%-- 商户分站id --%>
                                    <div class="field" id="branchzeng" style="display: none;">
                                        <label>
                                            选择分站</label><div id="all_branch">
                                            </div>
                                        <span class="inputtip">分站为可选项</span>
                                    </div>
                                    <%-- 增加销售人员id --%>
                                    <div class="field" id="saleceng" style="display: none;">
                                        <label>
                                            销售人员</label><div id="all_Sales">
                                            </div>
                                        <span class="inputtip">销售人员为可选项</span>
                                    </div>
                                    <div class="field" id="Div4">
                                        <label>
                                              项目详情页展示</label>
                                        <select id="shanhu" name="shanhu"  style="float: left;width:10%;" class="f-input">
                                            <%if (system != null)
                                              { %>
                                            <%if (system.teamwhole == 1)
                                              { %>
                                            <option value="0" selected="selected">左右两列</option>
                                            <option value="1">通栏模式</option>
                                            <% }
                                              else if (system.teamwhole == 0)
                                              {%>
                                            <option value="0">左右两列</option>
                                            <option value="1" selected="selected">通栏模式</option>
                                            <% }
                                              else
                                              {%>
                                            <option value="0">左右两列</option>
                                            <option value="1">通栏模式</option>
                                            <% }%>
                                            <% }
                                              else
                                              {%>
                                            <option value="0">左右两列</option>
                                            <option value="1">通栏模式</option>
                                            <% }%>
                                        </select>
                                        <span class="inputtip"></span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            api输出</label>
                                        <select id="Select1" name="apiopen" style="float: left;">
                                            <option value="0">开启</option>
                                            <option value="1">关闭</option>
                                        </select>
                                        <span class="inputtip">是否开启api输出</span>
                                    </div>
                                    <div class="field" id="field_card">
                                        <label>
                                            代金券使用</label>
                                        <input type="text" size="10" name="card" id="createcard" class="number" value="0"
                                            group="g" require="true" datatype="money" runat="server" />
                                        <span class="inputtip">可使用代金券最大面额</span>
                                    </div>
                                    <div class="field" id="Div1">
                                        <label>
                                            邀请返利</label>
                                        <input type="text" size="10" name="bonus" id="createbonus" class="number" require="true"
                                            datatype="number" runat="server" value="0" />
                                        <span class="inputtip">邀请好友参与本单商品购买时的返利金额</span>
                                    </div>
                                    <div class="field" id="Div3">
                                        <label>
                                            评论返利</label>
                                        <input type="text" size="10" name="commentscore" id="commentscore" class="number"
                                            require="true" datatype="money" runat="server" value="0" />
                                        <span class="inputtip">评论之后的返利金额</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            商品名称</label>
                                        <input type="text" size="30" name="product" id="createproduct" class="f-input" group="g"
                                            datatype="require" require="true" runat="server" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            商品图片</label>
                                        <asp:FileUpload ID="Image" name="Image" class="f-input" Height="26px" Width="694px"
                                            runat="server" />
                                        <span class="hint">至少得上传一张商品图片</span>&nbsp;
                                        <label id="ImageSet" class="hint" runat="server">
                                        </label>
                                        <%-- <a href="javascript:show(0)">引用其他图片</a>--%>
                                    </div>
                                    <div id="img0" class="field">
                                        <label>
                                            引用其他图片</label>
                                        <input type="text" size="30" name="imget" id="imget" class="f-input" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            商品图片1</label>
                                        <asp:FileUpload ID="Image1" runat="server" class="f-input" Height="26px" Width="694px" />&nbsp;
                                        <%--  <a href="javascript:show(1)">引用其他图片</a>--%>
                                    </div>
                                    <div id="img1" class="field">
                                        <label>
                                            引用其他图片1</label>
                                        <input type="text" size="30" name="imget1" id="Text2" class="f-input" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            商品图片2</label>
                                        <asp:FileUpload ID="Image2" runat="server" class="f-input" Height="26px" Width="694px" />&nbsp;
                                        <%--  <a href="javascript:show(2)">引用其他图片</a>--%>
                                    </div>
                                    <div id="img2" class="field">
                                        <label>
                                            引用其他图片2</label>
                                        <input type="text" size="30" name="imget2" id="Text3" class="f-input" />
                                    </div>
                                    <div class="field">
                                        <label>
                                            FLV视频短片</label>
                                        <input type="text" size="30" name="flv" id="createflv" class="f-input" runat="server" />
                                        <span class="hint" id="SPAN2" runat="server">形式如：http://.../video.flv</span>
                                    </div>
                                    <div class="field">
                                        <label>
                                            本单详情</label>
                                        <div style="float: left;">
                                            <textarea cols="45" style="height: 500px;" rows="5" name="detail" id="createdetail"
                                                class="f-textarea xheditor {upImgUrl:'../upload.aspx?immediate=1&t=0',urlType:'abs'}"
                                                runat="server"></textarea></div>
                                    </div>
                                    <div class="field" id="field_userreview">
                                        <label>
                                            网友点评</label>
                                        <div style="float: left;">
                                            <textarea cols="45" rows="5" name="userreview" id="createuserreview" class="f-textarea"
                                                runat="server"></textarea></div>
                                        <span class="hint">格式：“真好用|小兔|http://ww....|XXX网”，每行写一个点评</span>
                                    </div>
                                    <div class="field" id="field_systemreview">
                                        <label>
                                            <%--<%=ASSystemArr["abbreviation"] %>--%>推广辞</label>
                                        <div style="float: left;">
                                            <textarea cols="45" rows="5" name="systemreview" id="creatsystemreview" class="f-textarea xheditor {upImgUrl:'../upload.aspx?immediate=1&t=0',urlType:'abs'}"
                                                runat="server"></textarea></div>
                                    </div>
                                    <div class="wholetip clear">
                                        <h3>
                                            4、配送信息</h3>
                                    </div>
                                    <div class="field">
                                        <label>
                                            递送方式</label>
                                        <div style="margin-top: 5px;">
                                            <div id="coupon" <%=isDisplay %>>
                                                <input id="zonediv1" type="radio" name="radio" value="coupon" checked="checked" />优惠券</div>
                                            <div id="draw" <%=isDisplay %>>
                                                <input id="zonediv3" type="radio" name="radio" value="draw" />抽奖</div>
                                            <div id="express" class="daoru">
                                                <%if (isDisplay == "style='display:none;'")
                                                  { %>
                                                <input id="zonediv2" type="radio" name="radio" value="express" checked="checked" /><%}
                                                  else
                                                  { %><input id="zonediv2" type="radio" name="radio" value="express" />
                                                <%} %>快递</div>
                                            <div id="pcoupon" <%=isDisplay %>>
                                                <input id="Radio1" type="radio" name="radio" value="pcoupon" />导入站外券</div>
                                        </div>
                                    </div>
                                    <div class="field" id="drawmobile" style="display: none;">
                                        <label>
                                            短信验证</label>
                                        <asp:DropDownList ID="ddlcode" runat="server" Style="float: left; width: 45px;">
                                        </asp:DropDownList>
                                        <span class="inputtip">抽奖项目是否需要短信验证</span>
                                    </div>
                                    <div class="field" id="drawtype" style="display: none;">
                                        <label>
                                            抽奖方式</label>
                                        <input id="Radio2" type="radio" name="dtype" value="0" checked="checked" />按随机
                                        <input id="Radio3" type="radio" name="dtype" value="1" />按顺序 <span class="inputtip">
                                        </span>
                                    </div>
                                    <div id="express_zone_coupon" style="display: block;">
                                        <div class="field" id="fanli">
                                            <label>
                                                消费返利</label>
                                            <input type="text" size="10" name="credit" id="createcredit" class="number" value="0"
                                                datatype="money" require="true" runat="server" />
                                            <span class="inputtip">消费优惠券时，获得账户余额返利，单位CNY元</span>
                                        </div>
                                        <div class="field" id="start">
                                            <label>
                                                优惠券开始时间</label>
                                            <input type="text" size="10" name="start_time" readonly="readonly" onFocus="WdatePicker({dateFmt:'yyyy-MM-dd'});"
                                                id="createStarttime" class="date" group="g" runat="server" />
                                            <span class="inputtip">生成优惠券时的开始时间 （格式：2011-01-01）</span>
                                        </div>
                                        <div class="field" id="way">
                                            <label>
                                                结算方式</label>
                                            <asp:DropDownList ID="ddlway" runat="server" class="f-input" Style="width: 160px;">
                                                <asp:ListItem Value="N" Selected="True">按实际消费的数量</asp:ListItem>
                                                <asp:ListItem Value="Y">按实际购买的数量</asp:ListItem>
                                            </asp:DropDownList>
                                        </div>
                                        <div class="field" id="refund">
                                            <label>
                                                退款方式</label>
                                            <asp:DropDownList ID="ddlrefund" runat="server" class="f-input" Style="width: 210px;">
                                                <asp:ListItem Value="N" Selected="True">不支持7天退款以及过期退款</asp:ListItem>
                                                <asp:ListItem Value="S">仅支持7天退款</asp:ListItem>
                                                <asp:ListItem Value="G">仅支持过期退款</asp:ListItem>
                                                <asp:ListItem Value="Y">支持7天退款以及过期退款</asp:ListItem>
                                            </asp:DropDownList>
                                        </div>
                                    </div>
                                    <div id="express-zone-pickup" style="display: none;">
                                        <div class="field">
                                            <label>
                                                联系电话</label>
                                            <input type="text" size="10" name="mobile" id="createmobile" class="f-input" value=""
                                                runat="server" />
                                        </div>
                                        <div class="field">
                                            <label>
                                                自取地址</label>
                                            <input type="text" size="10" name="address" id="createaddress" class="f-input" value=""
                                                runat="server" />
                                        </div>
                                    </div>
                                    <div id="express_zone_express" style="display: none;">
                                        <div class="field" id="Div2">
                                            <label>
                                                结算方式</label>
                                            <asp:DropDownList ID="expressway" runat="server" class="f-input" Style="width: 280px;">
                                                <asp:ListItem Value="S" Selected="True">按实际发货数量(已填写快递单号的订单)</asp:ListItem>
                                                <asp:ListItem Value="Y">按实际购买数量</asp:ListItem>
                                            </asp:DropDownList>
                                        </div>
                                        <div class="field_xm">
                                            <label>
                                                <input name="freighttype" id="freighttype0" type="radio" checked="checked" value="0">填写快递费</label>
                                            <label>
                                                <input name="freighttype" id="freighttype1" type="radio" value="1">使用快递模板(<a href='fare_template.aspx'>编辑快递模板</a>)</label>
                                        </div>
                                        <div class="field" id="type1" style="display: none;">
                                            <label>
                                                快递费模板</label>
                                            <asp:DropDownList ID="faretemplate_drop" Style="float: left;" runat="server">
                                            </asp:DropDownList>
                                            <label>
                                                免单数量</label>
                                            <input type="text" size="10" id="farefree2" class="number" value="0" maxlength="6"
                                                datatype="money" require="true" runat="server" />
                                            <span class="hint">快递费用，免单数量：0表示不免运费，2表示，购买2件免运费</span>
                                        </div>
                                        <div class="field" id="type0">
                                            <label>
                                                快递费用</label>
                                            <input type="text" size="10" name="fare" id="createfare" class="number" value="5"
                                                maxlength="6" datatype="money" require="true" runat="server" />
                                            <label>
                                                免单数量</label>
                                            <input type="text" size="10" name="farefree" id="createfarefree" class="number" value="0"
                                                maxlength="6" datatype="money" runat="server" />
                                            <span class="hint">快递费用，免单数量：0表示不免运费，2表示，购买2件免运费</span>
                                        </div>
                                        <div class="field" id="expressmemo" style="display: none;">
                                            <label>
                                                快递配送说明</label>
                                            <div>
                                                <textarea cols="45" rows="5" name="express" id="createexpress" class="f-textarea"
                                                    runat="server"></textarea></div>
                                        </div>
                                        <div>
                                            <asp:HiddenField ID="HiddenField1" runat="server" />
                                        </div>
                                        <div class="field">
                                            <label>
                                                货到付款接口</label>
                                            <asp:DropDownList ID="ddlCashOnDelivery" Style="float: left;" runat="server">
                                                <asp:ListItem Value="0">关闭</asp:ListItem>
                                                <asp:ListItem Value="1">开启</asp:ListItem>
                                            </asp:DropDownList>
                                            <span class="inputtip">只有开启本功能的项目才支持货到付款</span>
                                        </div>
                                    </div>
                                    <div class="act">
                                     <input id="leadesubmit" name="commit" type="submit" value="好了，提交" group="g"   class="formbutton validator" onclick="return freighttype1_onclick()"/>
                                         
                                        <script type="text/javascript">
                                            function freighttype1_onclick() {
                                                if ($("#ImageSet").html().trim() == "" && $("#Image").val().trim() == "") {
                                                    alert("请上传商品图片");
                                                    return false;
                                                }

                                            }

                                            $(function () {
                                                $("form").submit(function () {
                                                    if ($("#ImageSet").html().trim() == "" && $("#Image").val().trim() == "") {
                                                        alert("请上传商品图片");
                                                        return false;
                                                    }
                                                });
                                            });
                                        </script>
                                    </div>
                                    <!--</form>-->
                                </div>
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
