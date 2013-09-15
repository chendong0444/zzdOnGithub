<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.AdminPage" %>


<%@ Import Namespace="AS.GroupOn" %>
<%@ Import Namespace="AS.Common" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Accessor" %>
<%@ Import Namespace="AS.Common.Utils" %>
<%@ Import Namespace="ASDHTSMS.ASDHTSMSService" %>
<%@ Import Namespace="AS.GroupOn.App" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    protected IList<ISmsLog> smsLogs = null;
    protected IPagers<ISmsLog> pager = null;
    protected List<Hashtable> data = null;
    protected string pagerHtml = String.Empty;
    protected string url = "";
    protected int page = 1;
    protected int pagesize = 30;

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        //判断管理员是否有此操作
        if (AdminPage.IsAdmin && AdminPage.CheckUserOptionAuth(PageValue.CurrentAdmin, ActionEnum.Option_SMS_SendLog))
        {
            SetError("你不具有查看短信发送记录的权限！");
            Response.Redirect("index_index.aspx");
            Response.End();
            return;

        }
        if (!Page.IsPostBack)
        {
            databind();
        }
        if (Request["btnselect"] == "筛选")
        {
            databind();
        }

    }
    private void databind()
    {
        ISystem system = Store.CreateSystem();
        string mobile = "";
        if (Request.QueryString["mobile"] != null && Request.QueryString["mobile"].ToString() != "")
        {
            url = url + "&mobile=" + Request.QueryString["mobile"];
            mobile = Request.QueryString["mobile"].ToString();
        }
        if (mobile != "")
        {
            if (!StringUtils.ValidateString(mobile, "mobile"))
            {
                Response.Redirect("asdht_chinanet_sms_send.aspx");
                SetError("输入的手机号码格式不正确！");
            }
        }
        string starttime = "";
        string endtime = "";
        if (Request.QueryString["startTime"] != null && Request.QueryString["startTime"].ToString() != "")
        {
            url = url + "&startTime=" + Request.QueryString["startTime"];
            starttime = Request.QueryString["startTime"].ToString();
        }

        if (Request.QueryString["endTime"] != null && Request.QueryString["endTime"].ToString() != "")
        {
            url = url + "&endTime=" + Request.QueryString["endTime"];
            endtime = Request.QueryString["endTime"].ToString();
        }
        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
        {
            system = session.System.GetByID(1);
        }
        if (!String.IsNullOrEmpty(system.smspass) && !String.IsNullOrEmpty(system.smsuser))
        {
            try
            {
                url = url + "&page={0}";
                url = "asdht_chinanet_sms_send.aspx?" + url.Substring(1);

                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    data=session.GetData.GetDataList("select top 100 * from smslog order by sendtime desc");
                    
                    
                    //SmsLogFilter smsLogFilter = new SmsLogFilter();
                    //smsLogFilter.CurrentPage = AS.Common.Utils.Helper.GetInt(Request.QueryString["page"], 1);
                    //smsLogFilter.PageSize = pagesize;
                    //smsLogFilter.AddSortOrder(SmsLogFilter.SENDTIME_DESC);
                    //pager = session.SmsLog.GetPager(smsLogFilter);

                    //smsLogs = pager.Objects;
                }
                //if (smsLogs != null)
                //{
                //    pagerHtml = AS.Common.Utils.WebUtils.GetPagerHtml(pagesize, pager.TotalRecords, pager.CurrentPage, url);
                //}
            }
            catch (Exception ex)
            {
                System.IO.File.WriteAllText(AppDomain.CurrentDomain.BaseDirectory + "sms.log", ex.Message);

            }
        }
    }
</script>
<%LoadUserControl("_header.ascx", null); %>
<body class="newbie">
    <form id="form1" runat="server" method="get">
    <div id="pagemasker">
    </div>
    <div id="dialog">
    </div>
    <div id="doc">
        
        <div id="bdw" class="bdw">
            <div id="bd" class="cf">
                <div id="coupons">
                    <div id="content" class="box-content clear mainwide">
                        <div class="box clear ">
                            <div class="box-content">
                                <div class="head">
                                    <h2>电信通道短信发送记录</h2>
                                        <div class="search">
                                        手机号：<input type="text" name="mobile" value="<%=Request.QueryString["mobile"] %>" group="a"
                                            datatype="mobile" class="h-input number" />
                                            时&nbsp;间：
                                            <input type="text" value="<%=Request.QueryString["startTime"] %>" name="startTime"
                                                onfocus="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'});" class="date" style="width: 110px" />到&nbsp;&nbsp;&nbsp;<input
                                                    type="text" name="endTime" value='<%=Request.QueryString["endTime"] %>'
                                                    onfocus="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'});" class="date" style="width: 110px" />
                                            &nbsp;&nbsp;<input type="submit" value="筛选" id="btnselect" runat="server" class="formbutton validator"
                                                group="a" name="btnselect" style="padding: 1px 6px;" />
                                    <ul class="filter">
                                       
                                    </ul></div>
                                </div>
                                <div class="sect">
                                    <table id="orders-list" cellspacing="0" cellpadding="0" border="0" class="coupons-table">
                                        <tr>
                                            <th width='15%'>
                                                手机号
                                            </th>
                                            <th width='20%'>
                                                发送时间
                                            </th>
                                            <th width='10%'>
                                                所用点数
                                            </th>
                                            <th width='55%'>
                                                发送内容
                                            </th>
                                        </tr>
                                        <%if (data != null)
                                          {
                                              int ii = 0;
                                              foreach(Hashtable smsLog in data)
                                              {
                                                  if (ii % 2 == 0)
                                                  {%>
                                                  <tr>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["mobiles"]%>
                                                      </div>
                                                  </td>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["sendTime"].ToString()%>
                                                      </div>
                                                  </td>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["points"]%>
                                                      </div>
                                                  </td>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["content"]%>
                                                      </div>
                                                  </td>
                                              </tr>
                                                 <% }
                                                  else
                                                  {%>
                                                  <tr class="alt">
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden;'>
                                                          <%=smsLog["mobiles"]%>
                                                      </div>
                                                  </td>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["sendTime"].ToString()%>
                                                      </div>
                                                  </td>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["points"]%>
                                                      </div>
                                                  </td>
                                                  <td>
                                                      <div style='word-wrap: break-word; overflow: hidden; '>
                                                          <%=smsLog["content"]%>
                                                      </div>
                                                  </td>
                                              </tr>
                                                  <%}
                                                  ii++;
                                                }
                                          } %>
                                        <tr>
                                            <td colspan="4">
                                                <%=pagerHtml %>
                                               
                                            </td>
                                        </tr>
                                    </table>
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