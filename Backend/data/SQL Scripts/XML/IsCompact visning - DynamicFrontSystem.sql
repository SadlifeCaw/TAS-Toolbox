BEGIN TRAN

DECLARE @schemaId INT, @caselogid varchar(max) ,@id varchar(max), @count INT = 0;

SET @schemaId = 487;

DECLARE cursor_compact CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select dfs.CaseLogId,
TemplateNodes.value('(Id)[1]','varchar(max)') AS Id
from DynamicFrontSystem dfs
cross apply dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Tabs/Tab/SetBlocks/SetBlock') AS a(TemplateNodes)
where TemplateNodes.value('(IsCompact)[1]','varchar(max)') = 'false' AND dfs.FrontSystemId = @schemaId 

OPEN cursor_compact;

FETCH NEXT FROM cursor_compact INTO @caselogid, @id	

--select *
--from DynamicFrontSystem
--where CaseLogId = @caselogid

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @count = @count + 1
	
	print @caselogid
	print @id
	
	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	Update DynamicFrontsystem 
	set FrontSystemXml.modify('replace value of (/DynamicFrontSystemXmlRoot/Tabs/Tab/SetBlocks/SetBlock[Id=sql:variable("@id")]/IsCompact/text())[1] with "true"')
	where CaseLogId = @caselogid

	FETCH NEXT FROM cursor_compact INTO @caselogid, @id	

END

--select *
--from DynamicFrontSystem
--where CaseLogId = @caselogid

CLOSE cursor_compact;
DEALLOCATE cursor_compact;

ROLLBACK TRAN
