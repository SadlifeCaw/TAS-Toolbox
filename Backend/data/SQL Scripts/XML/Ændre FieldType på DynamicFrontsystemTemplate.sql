
BEGIN TRAN

DECLARE @frontid INT, @id varchar(max), @schema INT, @from varchar(max), @to varchar(max);

--SET @schema = 363

SET @from = 'tmp_budget_Ekstern bistand_konsulent_uvg';
SET @to = 'grp_eksterne_bistand_konsulent';

DECLARE cursor_ CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select dfs.FrontSystemId,
	GroupNodes.value('(Id)[1]','varchar(max)') AS Id
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/Templates/Template') AS a(TemplateNodes)
cross apply TemplateNodes.nodes('DataFieldGroups/TemplateGroup') AS b(GroupNodes)
cross apply TemplateNodes.nodes('DataFields/TemplateField') AS c(FieldNodes)
where GroupNodes.value('(Label)[1]','varchar(max)') = @from --and dfs.FrontSystemId = @schema


OPEN cursor_;

FETCH NEXT FROM cursor_ INTO @frontid, @id

	select *
	from DynamicFrontSystemTemplate
	where FrontSystemId = @frontid

WHILE @@FETCH_STATUS = 0
BEGIN 

	print @frontid
	print @id
	print @to

	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	Update DynamicFrontSystemTemplate
	set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/Templates/Template/DataFieldGroups/TemplateGroup[Id=sql:variable("@id")]/Title/text())[1] with sql:variable("@to")')
	where FrontSystemId = @frontid
	
	FETCH NEXT FROM cursor_ INTO @frontid, @id
END

	select *
	from DynamicFrontSystemTemplate
	where FrontSystemId = @frontid

CLOSE cursor_;
DEALLOCATE cursor_;


ROLLBACK TRAN
