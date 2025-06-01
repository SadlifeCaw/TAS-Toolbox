
BEGIN TRAN

DECLARE @id varchar(max), @val DECIMAL(18,2), @schema INT, @from varchar(max);

SET @schema = 218;
SET @from = 'bf_nettoudgifter';

DECLARE cursor_ CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select
	dfs.CaseId,
	CONVERT(DECIMAL, Field.value('(FieldValue)[1]','varchar(max)')) AS Val
from DynamicFrontsystem dfs
cross apply dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period/Fields/Field') AS a(Field)
where dfs.FrontSystemId = @schema AND Field.value('(Label)[1]','varchar(max)') IN (@from) --AND Field.value('(FieldValue)[1]','varchar(max)') is not Null

OPEN cursor_;

FETCH NEXT FROM cursor_ INTO @id, @val

select ID_SAG, ANSOGT_BELOEB from SAG where PROJEKTTYPE = 'AT24' and ORDNING = 'ARBMILJ'

WHILE @@FETCH_STATUS = 0
BEGIN 

	print @id
	print @val

	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	UPDATE SAG
	SET ANSOGT_BELOEB = @val
	where PROJEKTTYPE = 'AT24' and ORDNING = 'ARBMILJ' and ID_SAG = @Id

	FETCH NEXT FROM cursor_ INTO @id, @val
END

select ID_SAG, ANSOGT_BELOEB from SAG where PROJEKTTYPE = 'AT24' and ORDNING = 'ARBMILJ'

CLOSE cursor_;
DEALLOCATE cursor_;

ROLLBACK TRAN