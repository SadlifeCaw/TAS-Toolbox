
DECLARE @Regels�t NVARCHAR(50) = 'xtet2'

DECLARE @ID INT = (select REGELSAET_ID from REGELSAET where TEKST = @Regels�t)


BEGIN TRAN 

delete from AKTIVITET_REGEL_GENEREL
where REGELSAET_ID = @ID

rollback TRAN

