CREATE PROCEDURE [dbo].[TAS_CheckFaildDatasyncjob]
 
@DaysBack INT = 5-- Default is 30days, but can be changed when called 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowCount INT;
    DECLARE @EmailBody NVARCHAR(MAX);
    DECLARE @Recipients NVARCHAR(MAX) = 'Casper.skourup@gmail.com'; -- Recipients' email addresses 
    DECLARE @Subject NVARCHAR(255);

    -- Get today's date and calculate the date for @DaysBack days ago
    DECLARE @Today DATETIME;
    DECLARE @StartDate DATETIME;
    
    SET @Today = GETDATE();
    SET @StartDate = DATEADD(DAY, -@DaysBack, @Today);

    -- Execute the SELECT query and store the result in a temporary table
    SELECT 
        s.JOURNAL_NR,
        s.ID_SAG,
        o.TEKST AS Ordning,
        dj.DATASYNC_JOB_ID,
        dj.JOBNAME,
        dj.SAGSLOG_ID,
        dj.STATUS,
        dj.RETRY_COUNT,
        dj.SUCCESS,
        dj.CREATED_DATE,
        dj.LASTUPDATE,
        dj.MESSAGE,
        dj.CREATED_INIT,
        CASE WHEN dj.SUCCESS = 0 THEN 0 ELSE 1 END AS SortOrder
    INTO #TempResults
    FROM SAG s 
    INNER JOIN DATASYNC_JOB AS dj ON s.ID_SAG = dj.ID_SAG
    LEFT JOIN ORDNING AS o ON o.ORDNING = s.ORDNING
    WHERE (dj.SUCCESS IN (0) OR dj.SUCCESS IS NULL) AND dj.CREATED_DATE > @StartDate;

    -- Count the number of rows in the result
    SELECT @RowCount = COUNT(*) FROM #TempResults;

    -- If there are results, build email with details
    IF @RowCount > 0
    BEGIN
        -- Set subject and start of email body
        SET @Subject = 'Notification: Her er det fejlede datasyncjob';
        SET @EmailBody = '<html><body><p>Følgende datasyncjob er fejlet:</p><br/>';

        -- Add each row to the email body
        SELECT @EmailBody = @EmailBody + 
            '<b>Journal Nr:</b> ' + ISNULL(CAST(JOURNAL_NR AS NVARCHAR(50)), 'N/A') + '<br/>' +
            '<b>ID Sag:</b> ' + ISNULL(CAST(ID_SAG AS NVARCHAR(50)), 'N/A') + '<br/>' +
            '<b>Ordning:</b> ' + ISNULL(Ordning, 'N/A') + '<br/>' +
            '<b>Datasync Job ID:</b> ' + ISNULL(CAST(DATASYNC_JOB_ID AS NVARCHAR(50)), 'N/A') + '<br/>' +
            '<b>Jobname:</b> ' + ISNULL(JOBNAME, 'N/A') + '<br/>' +
            '<b>Sagslog ID:</b> ' + ISNULL(CAST(SAGSLOG_ID AS NVARCHAR(50)), 'N/A') + '<br/>' +
            '<b>Status:</b> ' + ISNULL(CAST(STATUS AS NVARCHAR(50)), 'N/A') + '<br/>' +
            '<b>Retry Count:</b> ' + ISNULL(CAST(RETRY_COUNT AS NVARCHAR(50)), 'N/A') + '<br/>' +
            '<b>Success:</b> ' +
            CASE 
                WHEN SUCCESS = 0 THEN '<span style="background-color:red;">datasyncJob er gået i stået</span>'
                WHEN SUCCESS IS NULL THEN '<span style="background-color:yellow;">[ Være opmærksom her, fejl skydes af SB der har annulleret aktiviteten der udløse datasyncJob]</span>'
            END + '<br/>' +
            '<b>Created Date:</b> ' + ISNULL(CONVERT(NVARCHAR, CREATED_DATE, 120), 'N/A') + '<br/>' +
            '<b>Last Update:</b> ' + ISNULL(CONVERT(NVARCHAR, LASTUPDATE, 120), 'N/A') + '<br/>' +
            '<b>Message:</b> ' + ISNULL(MESSAGE, 'N/A') + '<br/>' +
            '<b>Created Init:</b> ' + ISNULL(CREATED_INIT, 'N/A') + '<br/><br/>'

        FROM #TempResults
        ORDER BY SortOrder, CREATED_DATE DESC;

        -- Close the HTML tags
        SET @EmailBody = @EmailBody + '</body></html>';
    END
    ELSE
    BEGIN
        -- Set subject and email body for no results
        SET @Subject = 'Notification: Ingen fejl i datasync';
        SET @EmailBody = '<html><body>Alle datasyncjob er kørt uden fejl.</body></html>';
    END

    -- Send HTML email
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'ExternalSMTPProfile',
        @recipients = @Recipients,
        @subject = @Subject,
        @body = @EmailBody,
        @body_format = 'HTML';  -- Specify the body format as HTML

    -- Clean up
    DROP TABLE #TempResults;
	
END;
