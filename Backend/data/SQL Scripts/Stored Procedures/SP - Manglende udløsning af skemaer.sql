Opslag: Manglende udløsning af skemaer
*/
CREATE PROCEDURE [dbo].[TAS_CheckForMissingReloadSchema] 
    
    @DaysBack INT = 5-- Default is 7 days, but can be changed when called
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @RowCount INT;
    DECLARE @EmailBody NVARCHAR(MAX) = '';
    DECLARE @Recipients NVARCHAR(MAX) = 'test@formpipe.com'; -- Recipient email addresses
    DECLARE @Subject NVARCHAR(MAX);

    -- Get today's date and calculate the date @DaysBack days ago
    DECLARE @Today DATETIME = GETDATE();
    DECLARE @StartDate DATETIME = DATEADD(DAY, -@DaysBack, @Today);

    SELECT 
        SAG.ORDNING, 
        SAG.PROJEKTTYPE, 
        SAGSLOG.ID_SAG AS SAGSID, 
        SAG.JOURNAL_NR AS JOURNALNR, 
        SAGSLOG.SAGSLOG_ID AS SAGSLOGID, 
        SAGSLOG.AKTIVITET_ID AS AKTIVITETSID, 
        AKTIVITET.TEKST AS AKTIVITET, 
        SAGSLOG.TEKST AS BESKRIVELSE,
        SAGSLOG.STATUS_FRA AS "STATUS FRA", 
        SAGSLOG.STATUS_TIL AS "STATUS TIL", 
        SAGSLOG.NOTE_ID AS NOTEID, 
        SAGSLOG.REGISTRERET_INIT AS REGISTRERINGSINIT, 
        SAGSLOG.REGISTRERET_DATO AS REGISTRERINGSDATO, 
        SAGSLOG.GODKENDT_INIT AS GODKENDELSESINIT, 
        SAGSLOG.GODKENDT_DATO AS GODKENDELSESDATO, 
        SAGSLOG.FORTRUDT
    INTO #TempResults
    FROM SAGSLOG
    INNER JOIN SAG ON SAG.ID_SAG = SAGSLOG.ID_SAG
    INNER JOIN AKTIVITET ON SAGSLOG.AKTIVITET_ID = AKTIVITET.AKTIVITET_ID
    WHERE SAGSLOG.SAGSLOG_ID IN (
        SELECT SAGSLOG_ID
        FROM SAG_FORSYSTEM_AKTIVITET
        WHERE SAGSLOG_ID_LAAST IS NULL
          AND AKTIVITET_ID_LAAST IS NULL
          AND OBJEKT = 'DynamicFrontSystem'
          AND FORSYSTEM_ID > 2
          AND SAGSLOG_ID NOT IN (
              SELECT CaseLogid
              FROM DynamicFrontsystem
          )
    )
    AND SAGSLOG.REGISTRERET_DATO BETWEEN @StartDate AND @Today
    ORDER BY SAGSLOG.REGISTRERET_DATO;

    -- Count the number of rows in the result
    SELECT @RowCount = COUNT(*) FROM #TempResults;

    -- If there are results, build email with details
    IF @RowCount > 0
    BEGIN

 SET @EmailBody ='Følgende skema er ikke udløst:' + CHAR(13) + CHAR(10)+ CHAR(13) + CHAR(10);
        -- Construct the email body
        SELECT @EmailBody = @EmailBody + 
            'ORDNING: ' + COALESCE(ORDNING, '') + CHAR(13)+CHAR(10) +
            'PROJEKTTYPE: ' + COALESCE(PROJEKTTYPE, '') + CHAR(13)+CHAR(10) +
            'SAGSID: ' + CAST(SAGSID AS NVARCHAR(50)) + CHAR(13)+CHAR(10) +
            'JOURNALNR: ' + COALESCE(JOURNALNR, '') + CHAR(13)+CHAR(10) +
            'SAGSLOGID: ' + CAST(SAGSLOGID AS NVARCHAR(50)) + CHAR(13)+CHAR(10) +
            'AKTIVITETSID: ' + CAST(AKTIVITETSID AS NVARCHAR(50)) + CHAR(13)+CHAR(10) +
            'AKTIVITET: ' + COALESCE(AKTIVITET, '') + CHAR(13)+CHAR(10) +
            'BESKRIVELSE: ' + COALESCE(BESKRIVELSE, '') + CHAR(13)+CHAR(10) +
            'STATUS FRA: ' + COALESCE(CAST([STATUS FRA] AS NVARCHAR(MAX)), '') + CHAR(13)+CHAR(10) +
            'STATUS TIL: ' + COALESCE(CAST([STATUS TIL] AS NVARCHAR(MAX)), '') + CHAR(13)+CHAR(10) +
            'NOTEID: ' + CAST(NOTEID AS NVARCHAR(50)) + ', ' +
            'REGISTRERINGSINIT: ' + COALESCE(REGISTRERINGSINIT, '') + CHAR(13)+CHAR(10) +
            'REGISTRERINGSDATO: ' + COALESCE(CAST(REGISTRERINGSDATO AS NVARCHAR(50)), '') + CHAR(13)+CHAR(10) +
            'GODKENDELSESINIT: ' + COALESCE(GODKENDELSESINIT, '') + ', ' +
            'GODKENDELSESDATO: ' + COALESCE(CAST(GODKENDELSESDATO AS NVARCHAR(50)), '') + CHAR(13)+CHAR(10) +
            'FORTRUDT: ' + COALESCE(FORTRUDT, '') + CHAR(13) + CHAR(10)+ CHAR(13) + CHAR(10) 
        FROM #TempResults;

        SET @Subject = 'Der er fundet Manglende udløsning af skemaer';

        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ExternalSMTPProfile',
            @recipients = @Recipients,
            @subject = @Subject,
            @body = @EmailBody;
    END
    ELSE
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ExternalSMTPProfile',
            @recipients = @Recipients,
            @subject = 'Ingen manglende udløsning af skemaer',
            @body = 'Alle skemaer er udløst.';
    END

    DROP TABLE #TempResults;
END;
