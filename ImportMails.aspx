<%@ Page Language="C#" AutoEventWireup="true" Inherits="AS.GroupOn.Controls.FBasePage" %>

<%@ Import Namespace="AS.GroupOn.DataAccess.Filters" %>
<%@ Import Namespace="AS.GroupOn.Domain" %>
<%@ Import Namespace="AS.GroupOn.DataAccess" %>
<%@ Import Namespace="AS.GroupOn.Domain.Spi" %>

<script runat="server">
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        if (!IsPostBack)
        {
            string path = Server.MapPath("2013-11-10.txt");
            Response.Write(path + "<br>");
            var emails = System.IO.File.ReadLines(path);
            foreach (string mail in emails)
            {
                string email = FormatEmail(mail);
                Insert(email);

                Response.Write(email + "<br>");
            }
        }

    }

    Regex r = new Regex(@"^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$" , RegexOptions.Compiled);//email地址 
    private string FormatEmail(string email)
    {
        string[] coms = { ".com.cn",".com",".cn",".net",".tw",".org",".edu",".gov"};
        bool IsInComs = false;
        for (int i = 0; i < coms.Length; i++)
        {
            email = email ?? "";
            email = email.Trim().TrimEnd('_').ToLower();
            int idx = email.IndexOf(coms[i]);
            if(idx > 1 )
            {
                email = email.Substring(0, idx + coms[i].Length);
                IsInComs = true;
                break;
            }
        }
        if (!IsInComs)
            return "";
        return r.IsMatch(email) ? email : "";
    }

    private void Insert(string email)
    {
        if (!string.IsNullOrEmpty(email) || email.IndexOf("...")>0)
        {
            MailerFilter mailfilter = new MailerFilter();
            mailfilter.Email = email;
            mailfilter.AddSortOrder(MailerFilter.ID_ASC);

            IMailer mailerList = null;
            using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
            {
                mailerList = session.Mailers.Get(mailfilter);
            }
            if (mailerList == null)
            {
                IMailer mailer = new Mailer();
                mailer.City_id = CurrentCity.Id;
                string code = System.Guid.NewGuid().ToString();
                mailer.Secret = code.Substring(0, 32);
                mailer.Email = Server.HtmlEncode(email);
                using (IDataSession session = AS.GroupOn.App.Store.OpenSession(false))
                {
                    session.Mailers.Insert(mailer);
                }
            }
        }

    }


</script>
