--with xmlnamespaces(default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem')
BEGIN tran

DECLARE @caselogid varchar(max), @id varchar(max), @str varchar(max), @value varchar(max), @schemaId INT;

SET @schemaId = 565

/*
	Getting the caselogIds and ids (Period inside the XML template), which is used to find the exact places to make changes. 
	You can change to following query, depending on which schema that needs to be changed and per the requirements.
	
	NOTE. MAKE SURE THAT YOU RETRIEVE 'CaselogId' and 'Id'. 
*/
DECLARE cursor_isclosed CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select 
	dfs.CaseLogId,
	Field.value('(Id)[1]','varchar(max)') AS Id
	from DynamicFrontsystem dfs
	left join SAG_FORSYSTEM_AKTIVITET sa
		on dfs.CaselogId = sa.SAGSLOGID
	cross apply dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period') AS a(Field)
	where FrontSystemId = @schemaId AND Field.value('(IsClosed)[1]','varchar(max)') = 'false' AND sa.AKTIVITET_ID_LAAST IS NOT NULL AND sa.SAGSLOG_ID_LAAST IS NOT NULL

OPEN cursor_isclosed;

FETCH NEXT FROM cursor_isclosed INTO @caselogid, @id	

/*
	Looping through all caselogid and ids (periods inside the XML) can make the change to close/open schema
*/
WHILE @@FETCH_STATUS = 0
BEGIN
	Print @id
	Print @caselogid

	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
	Update DynamicFrontsystem 
	set FrontSystemXml.modify('replace value of (/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period[Id=sql:variable("@id")]/IsClosed/text())[1] with "true"')
	where CaseLogId = @caselogid

	FETCH NEXT FROM cursor_isclosed INTO @caselogid, @id	
END;

CLOSE cursor_isclosed;
DEALLOCATE cursor_isclosed;

ROLLBACK TRAN