--with xmlnamespaces(default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem')
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select dfs.FrontSystemId, 
	TemplateNodes.value('(Title)[1]','varchar(max)') AS TemplateTitle,
	TemplateNodes.value('(Label)[1]','varchar(max)') AS TemplateLabel,
	GroupNodes.value('(Title)[1]','varchar(max)') AS GroupTitle,
	GroupNodes.value('(Label)[1]','varchar(max)') AS GroupLabel,
	FieldNodes.value('(Title)[1]','varchar(max)') AS FiedlTitle,
	FieldNodes.value('(Label)[1]','varchar(max)') AS FieldLabel,
	FieldNodes.value('(FieldValue)[1]','varchar(max)') AS FieldValue
	--FieldNodes.value('(Formula)[1]','varchar(max)') AS FieldFormula
from DynamicFrontSystem dfs
cross apply dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Sets/Set') AS a(TemplateNodes)
cross apply TemplateNodes.nodes('Periods/Period') AS b(GroupNodes)
cross apply GroupNodes.nodes('Fields/Field') AS c(FieldNodes)
where FieldNodes.value('(Label)[1]','varchar(max)') like '%f_organisation%'
--where FieldNodes.value('(Label)[1]','varchar(max)') like '%-%' -- Hvis I skal søge på '_', skal man skrive det sådan : '[_]'
