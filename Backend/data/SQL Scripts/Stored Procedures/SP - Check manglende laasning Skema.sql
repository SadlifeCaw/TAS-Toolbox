
CREATE PROCEDURE [dbo].[TAS_CheckmanglendelaaseSkema]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowCount INT;
    DECLARE @EmailBody NVARCHAR(MAX);
    DECLARE @Recipients NVARCHAR(MAX) = 'robert.niyonsenga@formpipe.com'; -- Recipients' email addresses
    DECLARE @Subject NVARCHAR(255);
    DECLARE @SkemaID INT = 529; -- Insert SkemaID

    -- Execute the SELECT query and store the result in a temporary table
    ;WITH xmlnamespaces(DEFAULT 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem')
    SELECT DISTINCT
        s.ordning AS Ordning,
        s.PROJEKTTYPE AS Projekttype,
        dfs.CaseId AS Sagsid,
        s.JOURNAL_NR AS Journalnr,
        s.STATUS AS Statuskode,
        st.TEKST AS Status,
        dfs.CaseLogId AS Sagslogid,
        dfs.ActivityId AS Aktivitetsid,
        n.AKTIVITET_KODE AS Aktivitetskode,
        p.TEKST AS Aktivitet,
        r.REGISTRERET_DATO AS Registreringsdato,
        r.GODKENDT_DATO AS Godkendelsesdato,
        dfs.FrontSystemId AS Skemaid,
        c.TEKST AS Skema
    INTO #TempResults
    FROM DynamicFrontsystem dfs
    LEFT JOIN SAG s ON dfs.CaseId = s.ID_SAG
    LEFT JOIN FORSYSTEM c ON dfs.FrontSystemId = c.FORSYSTEM_ID
    LEFT JOIN AKTIVITET p ON dfs.ActivityId = p.AKTIVITET_ID
    LEFT JOIN SAGSLOG r ON dfs.CaseLogId = r.SAGSLOG_ID
    LEFT JOIN STATUS st ON s.STATUS = st.STATUS
    LEFT JOIN AKTIVITET n ON p.AKTIVITET_ID = n.AKTIVITET_ID
    CROSS APPLY dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Sets/Set') AS a(SetNodes)
    CROSS APPLY SetNodes.nodes('Periods/Period') AS b(FieldNodes)
    WHERE dfs.CaseLogId IN (
        SELECT SAGSLOG_ID
        FROM SAG_FORSYSTEM_AKTIVITET
        WHERE AKTIVITET_ID IN (
            SELECT AKTIVITET_ID
            FROM SAG_FORSYSTEM_AKTIVITET
            WHERE objekt = 'DynamicFrontSystem'
        )
        AND sagslog_id_laast IS NOT NULL
        AND aktivitet_id_laast IS NOT NULL
    )
    AND dfs.FrontSystemId = @SkemaID
    AND Fieldnodes.value('(IsClosed)[1]', 'varchar(max)') = 'false'
    ORDER BY Godkendelsesdato;

    -- Count the number of rows in the result
    SELECT @RowCount = COUNT(*) FROM #TempResults;

    -- Initialize the email body as an HTML table
    SET @EmailBody = 
        '<html>' +
        '<head><style>table { border-collapse: collapse; width: 100%; } th, td { border: 1px solid black; padding: 8px; text-align: left; } th { background-color: #f2f2f2; }</style></head>' +
        '<body><p>Følgende skemafelter mangler at blive låst:</p>' +
        '<table>' +
        '<tr>' +
        '<th>Journal Nr</th>' +
        '<th>Sag ID</th>' +
        '<th>Ordning</th>' +
        '<th>PROJEKTTYPE</th>' +
        '<th>Statuskode</th>' +
        '<th>Aktivitet</th>' +
        '<th>Status</th>' +
        '<th>Sagslogid</th>' +
        '<th>Aktivitetskode</th>' +
        '<th>Registreringsdato</th>' +
        '<th>Godkendelsesdato</th>' +
        '<th>Skema</th>' +
        '</tr>';

    -- If there are results, add each row to the HTML table
    IF @RowCount > 0
    BEGIN
        DECLARE @Journalnr NVARCHAR(255);
        DECLARE @Sagsid NVARCHAR(255);
        DECLARE @Ordning NVARCHAR(255);
        DECLARE @Projekttype NVARCHAR(255);
        DECLARE @Statuskode NVARCHAR(255);
        DECLARE @Aktivitet NVARCHAR(255);
        DECLARE @Status NVARCHAR(255);
        DECLARE @Sagslogid NVARCHAR(255);
        DECLARE @Aktivitetskode NVARCHAR(255);
        DECLARE @Registreringsdato NVARCHAR(255);
        DECLARE @Godkendelsesdato NVARCHAR(255);
        DECLARE @Skema NVARCHAR(255);

        DECLARE cur CURSOR FOR
        SELECT Journalnr, Sagsid, Ordning, Projekttype, Statuskode, Aktivitet, Status, Sagslogid, Aktivitetskode, Registreringsdato, Godkendelsesdato, Skema
        FROM #TempResults;

        OPEN cur;
        FETCH NEXT FROM cur INTO @Journalnr, @Sagsid, @Ordning, @Projekttype, @Statuskode, @Aktivitet, @Status, @Sagslogid, @Aktivitetskode, @Registreringsdato, @Godkendelsesdato, @Skema;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @EmailBody = @EmailBody + 
                '<tr>' +
                '<td>' + @Journalnr + '</td>' +
                '<td>' + @Sagsid + '</td>' +
                '<td>' + @Ordning + '</td>' +
                '<td>' + @Projekttype + '</td>' +
                '<td>' + @Statuskode + '</td>' +
                '<td>' + @Aktivitet + '</td>' +
                '<td>' + @Status + '</td>' +
                '<td>' + @Sagslogid + '</td>' +
                '<td>' + @Aktivitetskode + '</td>' +
                '<td>' + @Registreringsdato + '</td>' +
                '<td>' + @Godkendelsesdato + '</td>' +
                '<td>' + @Skema + '</td>' +
                '</tr>';

            FETCH NEXT FROM cur INTO  @Journalnr, @Sagsid, @Ordning, @Projekttype, @Statuskode, @Aktivitet, @Status, @Sagslogid, @Aktivitetskode, @Registreringsdato, @Godkendelsesdato, @Skema;
        END;

        CLOSE cur;
        DEALLOCATE cur;

        -- Close the HTML table
        SET @EmailBody = @EmailBody + '</table></body></html>';

        SET @Subject = 'Notification: Der mangler låsning af skemafelter';
        -- Send email with HTML body
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ExternalSMTPProfile', -- Use the created profile
            @recipients = @Recipients,
            @subject = @Subject,
            @body = @EmailBody,
            @body_format = 'HTML';
    END
    ELSE
    BEGIN
        SET @EmailBody = '<html><body><p>Der er ingen manglende låst skemafelter fundet.</p></body></html>';
        SET @Subject = 'Notification: Ingen skemafelter der mangler at blive låst';
        
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ExternalSMTPProfile',
            @recipients = @Recipients,
            @subject = @Subject,
            @body = @EmailBody,
            @body_format = 'HTML';
    END
    -- Clean up
    DROP TABLE #TempResults;
END;
