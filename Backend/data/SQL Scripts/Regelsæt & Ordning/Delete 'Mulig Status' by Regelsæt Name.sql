DECLARE @Regelsæt NVARCHAR(50) = 'xtet2'

DECLARE @ID INT = (select REGELSAET_ID from REGELSAET where TEKST = @Regelsæt)

BEGIN TRAN

delete from AKTIVITET_REGEL
where REGELSAET_ID = @ID

delete from REGELSAET_STATUS
where REGELSAET_ID = @ID

rollback TRAN

/*

/* Getting the 'Mulig Status' data */

select *
from REGELSAET_STATUS
where REGELSAET_ID = @ID

select *
from AKTIVITET_REGEL
where REGELSAET_ID = @ID

*/

