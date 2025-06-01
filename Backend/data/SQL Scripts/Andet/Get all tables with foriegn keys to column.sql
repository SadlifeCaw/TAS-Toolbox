DECLARE @ColumnName SYSNAME = 'YourColumnNameHere'; -- Replace with the column name you're looking for

SELECT  
    fk.name AS ForeignKeyName,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS ReferencingSchema,
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ReferencingColumn,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ReferencedColumn
FROM  
    sys.foreign_keys AS fk
INNER JOIN 
    sys.foreign_key_columns AS fc 
    ON fk.object_id = fc.constraint_object_id
WHERE 
    @ColumnName IS NULL
    OR COL_NAME(fc.parent_object_id, fc.parent_column_id) = @ColumnName
    OR COL_NAME(fc.referenced_object_id, fc.referenced_column_id) = @ColumnName
ORDER BY 
    fk.name;
