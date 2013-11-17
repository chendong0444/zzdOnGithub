<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.AdminPage" %>
<%@ Import Namespace="AS.GroupOn" %>
<%@ Import Namespace="AS.Common" %>
<%@ Import Namespace="AS.GroupOn.Controls" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.DataAccess.Accessor" %>
<%@ Import Namespace="AS.Common.Utils" %>
<%@ Import Namespace="AS.GroupOn.App" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<script runat="server">
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        
        sendMails();
    }

    private string sendMail(string content)
    {
        bool ok = false;
        System.Collections.Generic.List<string> list = new System.Collections.Generic.List<string>();
        list.Add("zbtg000001@gmail.com");
        string result = EmailMethod.sendMail("Test Mail", content, "info@zzdtuan.com.cn", "宗正大团 团购生活 轻松到家！", list, "smtp.ym.163.com", 25, "info@zzdtuan.com.cn", "shjk778899", false, "info@zzdtuan.com.cn", out ok);
        
        WebUtils.LogWrite(DateTime.Now.ToString("yyyy-MM-dd") + "_senmail", result + ok);
        
        return result + ok;
    }

    private static List<Hashtable> mailprovider = null; //保存邮件服务商。不用每次读取了
    public static Hashtable mailtask = null;//正在发送的邮件任务
    public static bool run = false;//邮件群发正在执行

    private void sendMails()
    {

        NameValueCollection _system = PageValue.CurrentSystemConfig;
        // System.IO.File.AppendAllText(AppDomain.CurrentDomain.BaseDirectory + "测试邮件群发.txt", "3333333333\r\n");
        if (!run)
        {
            run = true;
            try
            {
                double time =  Helper.GetDouble(_system["time"], 0);
                int samesendcount =  Helper.GetInt(_system["fucount"], 0);//同一邮件服务商的群发数量
                int sendmaxcount =  Helper.GetInt(_system["maxcount"], -1);//每次最多发送数量
                if (time > 0 && samesendcount > 0 && sendmaxcount > -1)
                {
                    //设置计时器间隔时间
                    IMailtasks mailtask = null;
                    IList<Imailserviceprovider> mailprovider = null;
                    MailtasksFilter mf = new MailtasksFilter();
                    MailserviceproviderFilter mp = new MailserviceproviderFilter();
                    mf.Top = 1;
                    mf.state = 1;
                    using (IDataSession session = Store.OpenSession(false))
                    {
                        mailtask = session.Mailtasks.Get(mf);
                    }
                    if (mailtask != null)
                    {
                        if (mailprovider == null)//判断缓存里是否有用户的邮件服务商列表
                        {
                            mp.mailtasks_id = mailtask.id;
                            using (IDataSession session = Store.OpenSession(false))
                            {
                                mailprovider = session.Mailserviceprovider.GetList(mp);
                            }
                        }
                        if (mailprovider == null || mailprovider.Count == 0)//如果邮件服务商列表里没有记录则删除数据库中邮件任务对应的服务商列表，并设置邮件任务为发送完毕状态。
                        {
                            mailtask.state = 2;
                            mailtask.sendcount = mailtask.totalcount;
                            using (IDataSession session = Store.OpenSession(false))
                            {
                                session.Mailserviceprovider.Delete(mailtask.id);
                                session.Mailtasks.Update(mailtask);
                            }
                            //db.SqlExec("update mailer set sendmailids=REPLACE(sendmailids,'," + mailtask["id"] + ",','')");
                            mailprovider = null;
                            mailtask = null;
                        }
                    }
                    if (mailprovider != null && mailprovider.Count > 0) //邮件服务商列表不为空则执行发送任务
                    {
                        //执行发送功能
                        int sendcount = 0;//此轮已发送数量
                        string cityidin = String.Empty;
                        if (!Utility.isEmpity(mailtask.cityid)) cityidin = " and city_id in(" + mailtask.cityid + ")";
                        ISystem system = Store.CreateSystem();
                        using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                        {
                            system = session.System.GetByID(1);
                        }
                        List<Hashtable> maildto = new List<Hashtable>();
                        IList<IMailserver> mailserver = null;
                        var sum = 0;
                        using (IDataSession session = Store.OpenSession(false))
                        {
                            mailserver = session.Mailserver.GetList(null);
                        }
                        if (mailserver != null)
                        {
                            sum = (from p in mailserver select p.sendcount).Sum();
                        }
                        if (sum > 0)
                        {
                            for (int i = mailprovider.Count; i > 0; i--)
                            {
                                Imailserviceprovider provider = mailprovider[i - 1];
                                if (sendcount >= sendmaxcount && sendmaxcount > 0) break;
                                string sql = "select top " + sum + "  u.[Id] as uid , m.Email,m.id from mailer m inner join [user] u on m.email=u.email where m.Email like '%" + provider.serviceprovider + "' " + cityidin + " and (sendmailids is null or sendmailids not like '%," + mailtask.id + ",%')";
                                using (IDataSession session = Store.OpenSession(false))
                                {
                                    maildto = session.Custom.Query(sql);
                                }
                                if (maildto.Count == 0)
                                {
                                    using (IDataSession session = Store.OpenSession(false))
                                    {
                                        session.Mailserviceprovider.Delete(provider.id);
                                    }
                                    mailprovider.Remove(provider);
                                }
                                else
                                {
                                    int servernumber = 0;//开始发送
                                    int s = 0;//已发送数量初始值
                                    for (int j = 0; j < maildto.Count; j++)
                                    {
                                        IMailer mailmodel = null;
                                        while (servernumber < mailserver.Count)
                                        {
                                            string updatemailerids = String.Empty;//记录更新已发送的订阅邮件的id
                                            if (mailserver.Count > servernumber && mailserver[servernumber].sendcount > s)
                                            {
                                                IMailserver mailserverrow = mailserver[servernumber];
                                                List<string> address = new List<string>();
                                                address.Add(maildto[j]["Email"].ToString());
                                                bool ok = false;
                                                bool ssl = false;
                                                if (mailserverrow.ssl == 1)
                                                {
                                                    ssl = true;
                                                }
                                                sendMail(mailtask.content.Replace("{uid}", maildto[j]["uid"].ToString()) + "<img style='display:none' src='" + AS.GroupOn.UrlRewrite.HttpModule.domain + WebRoot + "mailview.aspx?taskid=" + mailtask.id + "&mailerid=" + maildto[j]["id"] + "' />");
                                                sendcount = sendcount + 1;
                                                s = s + 1;
                                                updatemailerids = maildto[j]["id"].ToString();
                                                using (IDataSession session = Store.OpenSession(false))
                                                {
                                                    mailmodel = session.Mailers.GetByID(Helper.GetInt(updatemailerids, 0));
                                                }
                                                if (mailmodel != null)
                                                {
                                                    mailmodel.sendmailids = mailmodel.sendmailids + "'," + mailtask.id + ",'";
                                                    using (IDataSession session = Store.OpenSession(false))
                                                    {
                                                        session.Mailers.Update(mailmodel);
                                                    }
                                                }
                                                break;
                                            }
                                            else
                                            {
                                                servernumber = servernumber + 1;
                                                s = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else if (system.mailhost.Length > 0 && system.mailport.Length > 0 && system.mailuser.Length > 0 && system.mailpass.Length > 0 && system.mailfrom.Length > 0)
                        {
                            // System.IO.File.AppendAllText(AppDomain.CurrentDomain.BaseDirectory + "测试邮件群发.txt", "777777777\r\n");
                            for (int i = mailprovider.Count; i > 0; i--)
                            {
                                IMailer mailmodel = null;
                                Imailserviceprovider provider = mailprovider[i - 1];
                                if (sendcount >= sendmaxcount && sendmaxcount > 0) break;
                                string sql = "select top " + samesendcount + " u.[Id] as uid , m.Email,m.id from mailer m inner join [user] u on m.email=u.email where m.Email like '%" + provider.serviceprovider + "' " + cityidin + " and (sendmailids is null or sendmailids not like '%," + mailtask.id + ",%')";
                                using (IDataSession session = Store.OpenSession(false))
                                {
                                    maildto = session.Custom.Query(sql);
                                }
                                if (maildto.Count == 0)
                                {
                                    using (IDataSession session = Store.OpenSession(false))
                                    {
                                        session.Mailserviceprovider.Delete(provider.id);
                                    }
                                    mailprovider.Remove(provider);
                                }
                                else
                                {
                                    string updatemailerids = String.Empty;//记录更新已发送的订阅邮件的id
                                    for (int j = 0; j < maildto.Count; j++)
                                    {
                                        if (sendcount >= sendmaxcount && sendmaxcount > 0) break;
                                        List<string> address = new List<string>();
                                        if (maildto[j]["Email"] != null && maildto[j]["Email"].ToString() != "")
                                        {
                                            address.Add(maildto[j]["Email"].ToString());
                                            sendMail(mailtask.content.Replace("{uid}", maildto[j]["uid"].ToString()) + "<img style='display:none' src='" + AS.GroupOn.UrlRewrite.HttpModule.domain + WebRoot + "mailview.aspx?taskid=" + mailtask.id + "&mailerid=" + maildto[j]["id"] + "' />");
                                            sendcount = sendcount + 1;
                                            updatemailerids = updatemailerids + "," + maildto[j]["id"];
                                        }
                                    }
                                    if (updatemailerids.Length > 0)
                                    {
                                        updatemailerids = updatemailerids.Substring(1);
                                        using (IDataSession session = Store.OpenSession(false))
                                        {
                                            mailmodel = session.Mailers.GetByID(Helper.GetInt(updatemailerids, 0));
                                        }
                                        if (mailmodel != null)
                                        {
                                            mailmodel.sendmailids = mailmodel.sendmailids + "'," + mailtask.id + ",'";
                                            using (IDataSession session = Store.OpenSession(false))
                                            {
                                                session.Mailers.Update(mailmodel);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if (sendcount > 0)
                        {
                            IMailtasks mt = null;
                            using (IDataSession session = Store.OpenSession(false))
                            {
                                mt = session.Mailtasks.GetByID(mailtask.id);
                            }
                            if (mt != null)
                            {
                                mt.sendcount = mt.sendcount + sendcount;
                                using (IDataSession session = Store.OpenSession(false))
                                {
                                    session.Mailtasks.Update(mt);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                WebUtils.LogWrite(DateTime.Now.ToString("yyyy-MM-dd") + "_senmail", ex.Message);
            }
            run = false;
        }
    }
    
</script>
