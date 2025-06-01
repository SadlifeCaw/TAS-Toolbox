BEGIN TRAN

DECLARE @schema INT, @id varchar(max), @count int;

SET @count = 0;
/*
	Getting the schema ids and ids ('TemplateGroup' inside the XML template), which is used to find the exact places to make changes. 
	You can change to following query, depending on which schema that needs to be changed and per the requirements.
	
	NOTE. MAKE SURE THAT YOU RETRIEVE 'FrontSystemId' and 'Id'. 
*/
DECLARE cursor_IsMulti CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select dfs.FrontSystemId,
	GroupNodes.value('(Id)[1]','varchar(max)') AS Id
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/Templates/Template') AS a(TemplateNodes)
cross apply TemplateNodes.nodes('DataFieldGroups/TemplateGroup') AS b(GroupNodes)
where GroupNodes.value('(IsMultipleRowsPossible)[1]','varchar(max)') = 'true' --AND dfs.FrontSystemId IS NULL -- Only if you have to change schema with viewgroup

OPEN cursor_IsMulti;

FETCH NEXT FROM cursor_IsMulti INTO @schema, @id	


/*
	Looping through all schemas and ids (TemplateGroup inside the XML) can make the changes.
*/
WHILE @@FETCH_STATUS = 0
BEGIN
	Print @id
	Print @schema

	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	Update DynamicFrontSystemTemplate 
	set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/Templates/Template/DataFieldGroups/TemplateGroup[Id=sql:variable("@id")]/IsMultipleRowsPossible/text())[1] with "false"')
	where FrontSystemId = @schema --OR FrontSystemId IS NULL -- Only if you have to change schema with viewgroup

	SET @count = @count + 1;

	FETCH NEXT FROM cursor_IsMulti INTO @schema, @id

END

CLOSE cursor_IsMulti;
DEALLOCATE cursor_IsMulti;

PRINT @count;

ROLLBACK TRAN