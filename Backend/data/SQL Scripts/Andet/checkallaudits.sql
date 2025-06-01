DECLARE @sql AS NVARCHAR(MAX) = '';
DECLARE @username AS NVARCHAR(50) = 'P-X107257';
DECLARE @errorMessage AS NVARCHAR(100);

BEGIN TRY
    -- Build the dynamic SQL to select from all 'audit%' tables on USERNAME = 'adm1'
    SELECT @sql = @sql + 
        'SELECT * FROM ' + 'audit.' + QUOTENAME(table_name) + 
        ' WHERE USERNAME = @username UNION ALL '
    FROM INFORMATION_SCHEMA.TABLES
    WHERE table_name LIKE '%_AUDIT';  -- Filter for tables ending with '_AUDIT'

    -- Remove the last 'UNION ALL'
    SET @sql = LEFT(@sql, LEN(@sql) - 10);

    -- Execute the dynamic SQL
    EXEC sp_executesql @sql, N'@username NVARCHAR(50)', @username;
END TRY
BEGIN CATCH
    -- In case of an error, handle it by defaulting to a simple SELECT
    SET @errorMessage = ERROR_MESSAGE();
    PRINT 'Error: ' + @errorMessage;

    -- Default query in case of error
    SELECT @sql = 'SELECT * FROM ' + 'audit.' + QUOTENAME(table_name) + 
        ' WHERE USERNAME = @username UNION ALL '
    FROM INFORMATION_SCHEMA.TABLES
    WHERE table_name LIKE '%_AUDIT';  -- Filter for tables ending with '_AUDIT'

    -- Remove the last 'UNION ALL'
    SET @sql = LEFT(@sql, LEN(@sql) - 10);

    -- Execute the default query
    EXEC sp_executesql @sql, N'@username NVARCHAR(50)', @username;
END CATCH;