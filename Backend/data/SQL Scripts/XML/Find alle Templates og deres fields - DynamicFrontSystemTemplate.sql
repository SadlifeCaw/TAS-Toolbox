--with xmlnamespaces(default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem')
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select distinct dfs.FrontSystemId, 
	f.TEKST AS SkemaNavn,
	TemplateNodes.value('(Title)[1]','varchar(max)') AS TemplateTitle,
	TemplateNodes.value('(Label)[1]','varchar(max)') AS TemplateLabel,
	GroupNodes.value('(Title)[1]','varchar(max)') AS GroupTitle,
	GroupNodes.value('(Label)[1]','varchar(max)') AS GroupLabel,
	FieldNodes.value('(Title)[1]','varchar(max)') AS FieldTitle,
	FieldNodes.value('(Label)[1]','varchar(max)') AS FieldLabel
from DynamicFrontSystemTemplate dfs
LEFT JOIN FORSYSTEM f
	ON dfs.FrontSystemId = f.FORSYSTEM_ID
cross apply dfs.FrontSystemTemplateXml.nodes('/TemplateDynamicFrontSystem/Templates/Template') AS a(TemplateNodes)
cross apply TemplateNodes.nodes('DataFieldGroups/TemplateGroup') AS b(GroupNodes)
cross apply TemplateNodes.nodes('DataFields/TemplateField') AS c(FieldNodes)
where 
	GroupNodes.value('(Id)[1]','varchar(max)') = FieldNodes.value('(GroupId)[1]','varchar(max)')
--where FieldNodes.value('(Label)[1]','varchar(max)') like '%-%' -- Hvis I skal søge på '_', skal man skrive det sådan : '[_]'

