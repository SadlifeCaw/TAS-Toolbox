CREATE PROCEDURE [dbo].[TAS_CheckForMissingReceipts]
    @DaysBack INT = 14 -- Standardværdien er 14 dage, men kan ændres ved kald
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowCount INT;
    DECLARE @EmailBody NVARCHAR(MAX);
    DECLARE @Recipients NVARCHAR(MAX) = 'TEST@formpipe.com'; -- Modtagernes email adresser
    DECLARE @Subject NVARCHAR(255);

    -- Få dagens dato og beregn datoen for @DaysBack dage siden
    DECLARE @Today DATETIME;
    DECLARE @StartDate DATETIME;
    
    SET @Today = GETDATE();
    SET @StartDate = DATEADD(DAY, -@DaysBack, @Today);

    -- Udfør SELECT forespørgslen og gem resultatet i en midlertidig tabel
    SELECT SAG.ORDNING, SAG.PROJEKTTYPE, SAGSLOG.ID_SAG AS SAGSID, 
           SAG.JOURNAL_NR AS JOURNALNR, SAGSLOG.SAGSLOG_ID AS SAGSLOGID, 
           SAGSLOG.AKTIVITET_ID AS AKTIVITETSID, SAGSLOG.AKTIVITET_TEKST AS AKTIVITET, 
           SAGSLOG.TEKST AS BESKRIVELSE, SAGSLOG.STATUS_FRA AS "STATUS FRA", 
           SAGSLOG.STATUS_TIL AS "STATUS TIL", SAGSLOG.NOTE_ID AS NOTEID, 
           SAGSLOG.GODKENDT_INIT AS GODKENDELSESINIT, SAGSLOG.GODKENDT_DATO AS GODKENDELSESDATO, 
           SAGSLOG.EMAILATTACHMENTTYPE
    INTO #TempResults
    FROM SAGSLOG
    JOIN SAG ON SAG.ID_SAG = SAGSLOG.ID_SAG
    WHERE SAGSLOG.AKTIVITET_ID IN ( ---Aktivitet med kvittering
        SELECT AKTIVITET_ID
        FROM AKTIVITET
        WHERE PublicAvailableForApplicationService = 1
        AND DisplayTaskOverviewTab = 1
    )
    AND SAGSLOG.GODKENDT_INIT NOT LIKE 'B%' ---Uden andre end ansøger
    AND SAGSLOG.GODKENDT_INIT NOT LIKE 'Y%'
    AND SAGSLOG.GODKENDT_INIT NOT LIKE 'P-X%'
    AND SAGSLOG.GODKENDT_INIT NOT LIKE 'adm1'
    AND SAGSLOG.FORTRUDT = 'N'
    AND SAGSLOG.GODKENDT_DATO IS NOT NULL ---Godkendt aktivitet
    AND SAGSLOG.SAGSLOG_ID NOT IN ( ---Godkendt aktivitet uden kvittering
        SELECT sagslog_id
        FROM sagslog_dokumenter
        WHERE dokument_id IN (
            SELECT DOKUMENT_ID
            FROM DOKUMENT
            WHERE DocumentAreaType = 2
        )
        AND sagslog_id > 0
    )
    AND SAGSLOG.GODKENDT_DATO BETWEEN @StartDate AND @Today;

    -- Tæl antallet af rækker i resultatet
    SELECT @RowCount = COUNT(*) FROM #TempResults;

    -- Hvis der er resultater, opbyg email med detaljer
    IF @RowCount > 0
    BEGIN
        -- Sæt emne og start på email body
        SET @Subject = 'Notification: Manglende kvittering fundet';
        SET @EmailBody = 'Følgende sager mangler kvittering:' + CHAR(13) + CHAR(10);

        -- Tilføj hver række til email body
        SELECT @EmailBody = @EmailBody + CHAR(13) + CHAR(10) +
            'Journal Nr: ' + CAST(JOURNALNR AS NVARCHAR(50)) + CHAR(13) + CHAR(10) +
            'Sagslog ID: ' + CAST(SAGSLOGID AS NVARCHAR(50))  + CHAR(13) + CHAR(10) +
            'Aktivitet: ' + AKTIVITET  + CHAR(13) + CHAR(10) +
            'Godkendt Dato: ' + CAST(GODKENDELSESDATO AS NVARCHAR(50)) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
        FROM #TempResults
        ORDER BY GODKENDELSESDATO DESC;
    END
    ELSE
    BEGIN
        -- Sæt emne og email body for ingen resultater
        SET @Subject = 'Notification: Ingen manglende kvitteringer';
        SET @EmailBody = 'Der er ingen manglende kvitteringer fundet.';
    END

    -- Send email
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'ExternalSMTPProfile',
        @recipients = @Recipients,
        @subject = @Subject,
        @body = @EmailBody;

    -- Ryd op
    DROP TABLE #TempResults;
END;
