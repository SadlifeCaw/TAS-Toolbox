BEGIN TRAN

DECLARE @schemaId INT, @frontSystemId varchar(max) ,@id varchar(max), @count INT = 0;

SET @schemaId = 579;

DECLARE cursor_compact CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select dfs.FrontSystemId,
TemplateNodes.value('(Id)[1]','varchar(max)') AS Id
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/TemplateTabs/TemplateTab/TemplateBlocks/TemplateBlock') AS a(TemplateNodes)
where TemplateNodes.value('(IsCompact)[1]','varchar(max)') = 'false' AND dfs.FrontSystemId = @schemaId 

OPEN cursor_compact;

FETCH NEXT FROM cursor_compact INTO @frontSystemId, @id	

--select *
--from DynamicFrontSystemTemplate
--where FrontSystemId = @schemaId

WHILE @@FETCH_STATUS = 0
BEGIN
	
	SET @count = @count + 1
	
	print @frontSystemId
	print @id
	
	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	Update DynamicFrontSystemTemplate 
	set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/TemplateTabs/TemplateTab/TemplateBlocks/TemplateBlock[Id=sql:variable("@id")]/IsCompact/text())[1] with "true"')
	where FrontSystemId = @frontSystemId

	FETCH NEXT FROM cursor_compact INTO @frontSystemId, @id	

END

PRINT 'Total changes' 
PRINT @count

--select *
--from DynamicFrontSystemTemplate
--where FrontSystemId = @schemaId

CLOSE cursor_compact;
DEALLOCATE cursor_compact;

ROLLBACK TRAN
