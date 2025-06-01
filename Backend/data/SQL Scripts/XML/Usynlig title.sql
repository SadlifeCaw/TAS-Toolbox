BEGIN TRAN

DECLARE @frontid INT, @id varchar(max), @type varchar(max), @schema INT, @from nvarchar(max), @to nvarchar(max);

SET @schema = 688
SET @from = N'?';
SET @to = N'​';

DECLARE cursor_ CURSOR
FOR
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
--TEMPLATE IDS
select dfs.FrontSystemId, TemplateNodes.value('(Id)[1]','varchar(max)') AS Id, 'Template' AS type
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/Templates/Template') AS a(TemplateNodes)
where dfs.FrontSystemId = @schema and TemplateNodes.value('(Title)[1]','varchar(max)') = @from --+ '%'
union all
--GROUP IDS
select dfs.FrontSystemId, GroupNodes.value('(Id)[1]','varchar(max)') AS Id, 'Group' as Type
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/Templates/Template/DataFieldGroups/TemplateGroup') AS a(GroupNodes)
where dfs.FrontSystemId = @schema and GroupNodes.value('(Title)[1]','varchar(max)') = @from --+ '%'
union all
--FIELD IDS
select dfs.FrontSystemId, FieldNodes.value('(Id)[1]','varchar(max)') AS Id, 'Field' as Type
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/Templates/Template/DataFields/TemplateField') AS a(FieldNodes)
where dfs.FrontSystemId = @schema and FieldNodes.value('(Title)[1]','varchar(max)') = @from --+ '%'
union all
--TAB IDS
select dfs.FrontSystemId, TabNodes.value('(Id)[1]','varchar(max)') AS Id, 'Tab' as Type 
from DynamicFrontSystemTemplate dfs
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/TemplateTabs/TemplateTab') AS a(TabNodes)
where dfs.FrontSystemId = @schema and TabNodes.value('(Title)[1]','varchar(max)') = @from --+ '%'

OPEN cursor_;

FETCH NEXT FROM cursor_ INTO @frontid, @id, @type

	select *
	from DynamicFrontSystemTemplate
	where FrontSystemId = @frontid

WHILE @@FETCH_STATUS = 0
BEGIN 

	print @frontid
	print @id
	print @to
	
	IF @type = 'Template'
	BEGIN
		;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
		Update DynamicFrontSystemTemplate
		set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/Templates/Template[Id=sql:variable("@id")]/Title/text())[1] with sql:variable("@to")')
		where FrontSystemId = @frontid
	END
	IF @type = 'Group'
	BEGIN
		;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
		Update DynamicFrontSystemTemplate
		set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/Templates/Template/DataFieldGroups/TemplateGroup[Id=sql:variable("@id")]/Title/text())[1] with sql:variable("@to")')
		where FrontSystemId = @frontid
	END
	IF @type = 'Field'
	BEGIN
		;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
		Update DynamicFrontSystemTemplate
		set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/Templates/Template/DataFields/TemplateField[Id=sql:variable("@id")]/Title/text())[1] with sql:variable("@to")')
		where FrontSystemId = @frontid
	END
	IF @type = 'Tab'
	BEGIN
		;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
		Update DynamicFrontSystemTemplate
		set FrontSystemTemplateXml.modify('replace value of (/TemplateDynamicFrontSystem/TemplateTabs/TemplateTab[Id=sql:variable("@id")]/Title/text())[1] with sql:variable("@to")')
		where FrontSystemId = @frontid
	END
	
	FETCH NEXT FROM cursor_ INTO @frontid, @id, @type
END

	select *
	from DynamicFrontSystemTemplate
	where FrontSystemId = @frontid

CLOSE cursor_;
DEALLOCATE cursor_;


ROLLBACK TRAN