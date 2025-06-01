USE [XXXX]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_indsendNotifikation]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cnt INT;

    DECLARE @jnr TABLE (
        jnr VARCHAR(20)
    );

    -- Indsæt unikke journalnumre ved brug af JOIN i stedet for IN
    INSERT INTO @jnr (jnr)
    SELECT DISTINCT s.JOURNAL_NR
    FROM SAG s
    INNER JOIN DATASYNC_JOB dj ON s.ID_SAG = dj.ID_SAG
    INNER JOIN SAGSLOG sl ON dj.SAGSLOG_ID = sl.SAGSLOG_ID
    INNER JOIN AKTIVITET_EMAIL ae ON sl.AKTIVITET_ID = ae.AKTIVITET_ID
    WHERE ae.KATEGORITYPE = 'P'
      AND dj.MESSAGE LIKE '%ex.Message:%'
      AND dj.CREATED_DATE > '2025-05-16'
      AND dj.JOBNAME IN ('AUTO_JOURNALING', 'NY_FLET_JOURNALISER')
      AND (dj.SUCCESS = 0 OR dj.SUCCESS IS NULL)
      AND dj.STATUS IN (0, 1000);

    SELECT @cnt = COUNT(*) FROM @jnr;

    IF @cnt > 0
    BEGIN
        -- Opdater DATASYNC_JOB med samme JOIN-logik
        UPDATE dj
        SET dj.SUCCESS = 1,
            dj.STATUS = 1000
        FROM DATASYNC_JOB dj
        INNER JOIN SAGSLOG sl ON dj.SAGSLOG_ID = sl.SAGSLOG_ID
        INNER JOIN AKTIVITET_EMAIL ae ON sl.AKTIVITET_ID = ae.AKTIVITET_ID
        WHERE ae.KATEGORITYPE = 'P'
          AND dj.MESSAGE LIKE '%ex.Message:%'
          AND dj.CREATED_DATE > '2025-05-22'
          AND dj.JOBNAME IN ('AUTO_JOURNALING', 'NY_FLET_JOURNALISER')
          AND (dj.SUCCESS = 0 OR dj.SUCCESS IS NULL)
          AND dj.STATUS IN (0, 1000);

        -- Indsæt log med alias på jnr
        INSERT INTO DEVEL_LOG ([timestamp], LOG_TYPE, ERR_CODE, LOG_TEXT)
        SELECT CURRENT_TIMESTAMP, 'Info', 0, CONCAT('Indsend notifikation ', j.jnr)
        FROM @jnr j;
    END
END
