---Skemaobjekt på sagen
 
select *
from SAG_FORSYSTEM_AKTIVITET
where ID_SAG = 294959 and SAGSLOG_ID = 2889023 ---Tilret sagsid og sagslogid
 
---SAGSLOG_ID_LAAST OG AKTIVITET_ID_LAAST parametre på skemaobjektet
 
select top 10 *
from SAG_FORSYSTEM_AKTIVITET
where FORSYSTEM_ID = 275 ---Tilret skemanummer
 
---Låsning af skemaet
 
BEGIN TRAN
 
UPDATE SAG_FORSYSTEM_AKTIVITET
set SAGSLOG_ID_LAAST = NULL , AKTIVITET_ID_LAAST = NULL ---Tilret værdier
where ID_SAG = 294959 and SAGSLOG_ID = 2889023
 
ROLLBACK TRAN
 
---Set IsClosed = TRUE
 
BEGIN tran 
 
DECLARE @caselogid varchar(max), @id varchar(max), @str varchar(max), @value varchar(max), @schemaId INT, @count INT; 
 
SET @schemaId = 473 ---Erstat schemaId
 
SET @count = 0;
 
DECLARE cursor_isclosed CURSOR
FOR 
WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
select 
    dfs.CaseLogId,
    Field.value('(Id)[1]','varchar(max)') AS Id
    from DynamicFrontsystem dfs
    left join SAG_FORSYSTEM_AKTIVITET sa
        on dfs.CaselogId = sa.SAGSLOG_ID
    cross apply dfs.FrontSystemXml.nodes('/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period') AS a(Field)
    where FrontSystemId = @schemaId AND dfs.CaseLogId = 2307686 AND Field.value('(IsClosed)[1]','varchar(max)') = 'false' AND sa.AKTIVITET_ID_LAAST IS NOT NULL AND sa.SAGSLOG_ID_LAAST IS NOT NULL 
	---Erstat CaseLogId
 
OPEN cursor_isclosed; 
 
FETCH NEXT FROM cursor_isclosed INTO @caselogid, @id
 
WHILE @@FETCH_STATUS = 0
BEGIN
    Print @id
    Print @caselogid    
 
	;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema-instance' as i, default 'http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem' )
    Update DynamicFrontsystem 
    set FrontSystemXml.modify('replace value of (/DynamicFrontSystemXmlRoot/Sets/Set/Periods/Period[Id=sql:variable("@id")]/IsClosed/text())[1] with "true"')
    where CaseLogId = @caselogid   
 
	SET @count = @count + 1;
 
	FETCH NEXT FROM cursor_isclosed INTO @caselogid, @id    
END; 
 
CLOSE cursor_isclosed;
DEALLOCATE cursor_isclosed; 
 
PRINT @count;
rollback TRAN