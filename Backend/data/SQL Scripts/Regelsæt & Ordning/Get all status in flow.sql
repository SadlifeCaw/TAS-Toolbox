DECLARE @StartStatus NVARCHAR(10) = 'AT24001';

WITH StatusFlow AS (
    SELECT 
        STATUS_FRA,
        STATUS_TIL,
        CAST(STATUS_FRA + '->' + STATUS_TIL AS NVARCHAR(MAX)) AS Path
    FROM AKTIVITET_REGEL
    WHERE STATUS_FRA = @StartStatus

    UNION ALL

    SELECT 
        ar.STATUS_FRA,
        ar.STATUS_TIL,
        sf.Path + '->' + ar.STATUS_TIL
    FROM AKTIVITET_REGEL ar
    INNER JOIN StatusFlow sf ON ar.STATUS_FRA = sf.STATUS_TIL
    WHERE sf.Path NOT LIKE '%' + ar.STATUS_TIL + '%'
)

SELECT s.*
FROM STATUS s
INNER JOIN (
    SELECT DISTINCT STATUS_TIL
    FROM StatusFlow
) reachable
ON s.STATUS = reachable.STATUS_TIL
OPTION (MAXRECURSION 32767)
