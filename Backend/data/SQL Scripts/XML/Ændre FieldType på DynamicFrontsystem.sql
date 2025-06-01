
BEGIN TRAN

DECLARE @caselogId INT, @id varchar(max), @schema INT, @from varchar(max), @to varchar(max);

SET @schema = 441;
SET @from = 'FieldString';
SET @to = 'FieldHtmlString';

DECLARE cursor_ CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select dfs.CaseLogId,
	Field.value('(Id)[1]','varchar(max)') AS Id
from DynamicFrontsystem dfs
cross apply dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period/Fields/Field') AS a(Field)
where dfs.FrontSystemId = @schema AND Field.value('(@i:type)[1]','varchar(max)') = @from AND Field.value('(Label)[1]','varchar(max)') IN ('aarstal')

OPEN cursor_;

FETCH NEXT FROM cursor_ INTO @caselogId, @id

WHILE @@FETCH_STATUS = 0
BEGIN 

	print @caselogId
	print @id

	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	Update DynamicFrontsystem 
	set FrontSystemXml.modify('replace value of (/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period/Fields/Field[Id=sql:variable("@id")]/@i:type)[1] with sql:variable("@to")')
	where CaseLogId = @caselogId

	FETCH NEXT FROM cursor_ INTO @caselogId, @id
END

CLOSE cursor_;
DEALLOCATE cursor_;


ROLLBACK TRAN
