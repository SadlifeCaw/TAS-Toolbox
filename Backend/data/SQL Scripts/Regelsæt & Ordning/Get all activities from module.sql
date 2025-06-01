-- Define the same CTE again if needed
WITH StatusFlow AS (
    SELECT 
        AKTIVITET_ID,
        STATUS_FRA,
        STATUS_TIL,
        CAST(STATUS_FRA + '->' + STATUS_TIL AS NVARCHAR(MAX)) AS Path,
        CAST(CAST(AKTIVITET_ID AS NVARCHAR(MAX)) AS NVARCHAR(MAX)) AS AktivitetIds
    FROM AKTIVITET_REGEL
    WHERE STATUS_FRA = 'STAR08'

    UNION ALL

    SELECT 
        ar.AKTIVITET_ID,
        ar.STATUS_FRA,
        ar.STATUS_TIL,
        sf.Path + '->' + ar.STATUS_TIL,
        sf.AktivitetIds + ',' + CAST(ar.AKTIVITET_ID AS NVARCHAR(MAX))
    FROM AKTIVITET_REGEL ar
    INNER JOIN StatusFlow sf ON ar.STATUS_FRA = sf.STATUS_TIL
    WHERE sf.Path NOT LIKE '%' + ar.STATUS_TIL + '%'
      AND sf.STATUS_TIL <> 'STAR22'
      AND sf.STATUS_TIL <> 'STAR27'
),

-- Create a tally table on-the-fly (up to 1000 characters, adjust if needed)
Numbers AS (
    SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
),

-- Split AktivitetIds manually
SplitAktivitetIds AS (
    SELECT 
        DISTINCT TRY_CAST(
            SUBSTRING(
                ',' + sf.AktivitetIds + ',', 
                n + 1, 
                CHARINDEX(',', ',' + sf.AktivitetIds + ',', n + 1) - n - 1
            ) 
        AS INT) AS AKTIVITET_ID
    FROM StatusFlow sf
    JOIN Numbers n ON n.n < LEN(sf.AktivitetIds)
    WHERE SUBSTRING(',' + sf.AktivitetIds + ',', n.n, 1) = ','
)

SELECT DISTINCT AKTIVITET_ID
FROM SplitAktivitetIds
WHERE AKTIVITET_ID IS NOT NULL
OPTION (MAXRECURSION 32767);
