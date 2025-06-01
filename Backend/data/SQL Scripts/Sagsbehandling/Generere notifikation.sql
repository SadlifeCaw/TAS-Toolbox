begin tran

DECLARE @Mail NVARCHAR(MAX), @StoredEmailGuid UNIQUEIDENTIFIER, @StoredEmailReciverGuid UNIQUEIDENTIFIER, @CaseId int, @CaseLogId int

SET @CaseId = 17492
SET @CaseLogId = 281183


SET @StoredEmailGuid = NEWID()
SET @StoredEmailReciverGuid = NEWID()

SET @Mail = 
N'<p>
    Der er ny information&nbsp;p&aring; jeres sagsnr. 2022-137-0416 p&aring; STAR&#39;s tilskudsportal.&nbsp;<br /><br />
</p>
<p>
    Klik p&aring; f&oslash;lgende link for at g&aring; til din sag: 
    <a href="https://portal.star.dk/STAR_Dashboard/Tasportal/#ApplicationDetails&%7B%22entityId%22:%2215853%22%7D">
        https://portal.star.dk/STAR_Dashboard/Tasportal/#ApplicationDetails&%7B%22entityId%22:%2215853%22%7D
    </a>
</p>
<p>
    <br /><br />
    Med venlig hilsen
</p>
<p>
    Styrelsen for Arbejdsmarked og Rekruttering
</p>'



INSERT INTO StoredEmail (id, CaseId, CaseLogId, FromAddress, FromDisplayName, SenderAddress, ReplyToAddress, CreationDate, RowVersion)
VALUES (@StoredEmailGuid, @CaseId, @CaseLogId, NULL, NULL, 'puljestyring@star.dk', NULL, GETDATE(), NULL);

INSERT INTO StoredEmailReceiver (id, EmailAddress, DisplayName, Subject, Body, IsBodyHtml, SentDate, Status, StoredEmailId)
VALUES (@StoredEmailReciverGuid, 'casper.skourup@formpipe.com', NULL, 'Test Mail fra STAR', @Mail, 1, GETDATE(), 0, @StoredEmailGuid)

select * from StoredEmail where id = @StoredEmailGuid
select * from StoredEmailReceiver where id = @StoredEmailReciverGuid

rollback tran