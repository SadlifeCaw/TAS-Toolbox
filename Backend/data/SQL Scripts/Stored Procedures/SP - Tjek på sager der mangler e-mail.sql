
CREATE PROCEDURE [dbo].[TAS_CheckForMissingEmailOnCase]
 @DaysBack INT = 7 -- Default is 7 days, but can be changed when called
AS 
BEGIN 
    SET NOCOUNT ON;

    DECLARE @RowCount INT;
    DECLARE @EmailBody NVARCHAR(MAX) = '';
    DECLARE @Recipients NVARCHAR(MAX) = 'robert.niyonsenga@formpipe.com'; -- Recipient email addresses
    DECLARE @Subject NVARCHAR(MAX);

    -- Get today's date and calculate the date @DaysBack days ago
    DECLARE @Today DATETIME;
    DECLARE @StartDate DATETIME;
    
    SET @Today = GETDATE();
    SET @StartDate = DATEADD(DAY, -@DaysBack, @Today);

    WITH OrdningData AS (
        SELECT 'BYP' AS ORDNING
        UNION ALL
        SELECT 'ENP'
        UNION ALL
        SELECT 'SUF'
        UNION ALL
        SELECT 'SKO'
	UNION ALL
	SELECT 'KOM'
    )
    SELECT 
        OD.ORDNING, 
        SAG.PROJEKTTYPE, 
        SAG.ID_SAG AS SAGSID, 
        SAG.JOURNAL_NR AS JOURNALNR, 
        SAG.PROJEKTTITEL, 
        SECURITY_USERS.INTERESSENT_ID AS INTERESSENTID, 
        SAG_INTERESSENT_ROLLE_SECURITY_USER.INTERESSENT_ROLLE AS INTERESSENTROLLE, 
        SECURITY_USERS.DESCRIPTION AS NAVN, 
        SECURITY_USERS.IS_MANUALLY_CREATED AS "MANUELT OPRETTET", 
        SECURITY_USERS.AKTIV, 
        SECURITY_USERS.EmailNotification AS EMAILNOTIFIKATION, 
        SECURITY_USERS.CVRMUSTCHOOSEINSTITUTION
    INTO #TempResults
    FROM OrdningData OD
    JOIN SAG ON SAG.ORDNING = OD.ORDNING
    JOIN SAG_INTERESSENT_ROLLE_SECURITY_USER ON SAG.ID_SAG = SAG_INTERESSENT_ROLLE_SECURITY_USER.ID_SAG
    JOIN SECURITY_USERS ON SECURITY_USERS.NAME = SAG_INTERESSENT_ROLLE_SECURITY_USER.SECURITY_USER_NAME
    WHERE SECURITY_USERS.email IS NULL
      AND SECURITY_USERS.EmailNotification = 1
      AND SECURITY_USERS.NAME IN (
          SELECT SECURITY_USER_NAME
          FROM SAG_INTERESSENT_ROLLE_SECURITY_USER
          WHERE INTERESSENT_ROLLE IN (
              SELECT INTERESSENT_ROLLE
              FROM INTERESSENT_ROLLE
              WHERE SECURITY_USER_NAME IS NOT NULL
          )
      )
      AND SAG.status NOT LIKE 'ENP01'
      AND SECURITY_USERS.DESCRIPTION NOT LIKE 'Pseudonym'
    ORDER BY SAG.ID_SAG;

    -- Collect distinct ORDNING values
    DECLARE @OrdningList NVARCHAR(MAX);
    SELECT @OrdningList = STUFF((
        SELECT DISTINCT ', ' + ORDNING
        FROM #TempResults
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    -- Count the number of rows in the result
    SELECT @RowCount = COUNT(*) FROM #TempResults;

    -- If there are results, build email with details
    IF @RowCount > 0
    BEGIN
        -- Start constructing the email body as an HTML table
        SET @EmailBody = '<html><body><h3>Der er fundet sag med manglende e-mail på følgende ordning: ' + @OrdningList + '</h3><table border="1" cellpadding="5" cellspacing="0"><tr>' +
                         '<th>ORDNING</th><th>PROJEKTTYPE</th><th>SAGSID</th><th>JOURNALNR</th><th>PROJEKTTITEL</th>' +
                         '<th>INTERESSENTID</th><th>INTERESSENTROLLE</th><th>NAVN</th><th>MANUELT OPRETTET</th>' +
                         '<th>AKTIV</th><th>EMAILNOTIFIKATION</th><th>CVRMUSTCHOOSEINSTITUTION</th></tr>';

        -- Loop through the results and append each row to the email body
        SELECT @EmailBody = @EmailBody + 
            '<tr>' +
            '<td>' + COALESCE(ORDNING, '') + '</td>' +
            '<td>' + COALESCE(PROJEKTTYPE, '') + '</td>' +
            '<td>' + CAST(SAGSID AS NVARCHAR(50)) + '</td>' +
            '<td>' + COALESCE(JOURNALNR, '') + '</td>' +
            '<td>' + COALESCE(PROJEKTTITEL, '') + '</td>' +
            '<td>' + CAST(INTERESSENTID AS NVARCHAR(50)) + '</td>' +
            '<td>' + COALESCE(INTERESSENTROLLE, '') + '</td>' +
            '<td>' + COALESCE(NAVN, '') + '</td>' +
            '<td>' + COALESCE(CAST([MANUELT OPRETTET] AS NVARCHAR(50)), '') + '</td>' +
            '<td>' + COALESCE(CAST(AKTIV AS NVARCHAR(50)), '') + '</td>' +
            '<td>' + COALESCE(CAST(EMAILNOTIFIKATION AS NVARCHAR(50)), '') + '</td>' +
            '<td>' + COALESCE(CAST(CVRMUSTCHOOSEINSTITUTION AS NVARCHAR(50)), '') + '</td>' +
            '</tr>'
        FROM #TempResults;

        -- Close the HTML table
        SET @EmailBody = @EmailBody + '</table></body></html>';

        SET @Subject = 'Der er fundet sag med manglende e-mail på følgende ordninger: ' + @OrdningList;

        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ExternalSMTPProfile',
            @recipients = @Recipients,
            @subject = @Subject,
            @body = @EmailBody,
            @body_format = 'HTML';
    END
    ELSE
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ExternalSMTPProfile',
            @recipients = @Recipients,
            @subject = 'Ingen manglende e-mail',
            @body = 'Ingen sag der mangler e-mail.';
    END

    DROP TABLE #TempResults;
END;
