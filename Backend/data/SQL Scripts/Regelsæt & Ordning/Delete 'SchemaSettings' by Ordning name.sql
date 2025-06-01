DECLARE @Ordning NVARCHAR(50) = 'FST2'

/* Delete the schema settings and their parameters */

BEGIN TRAN 

delete from DATASYNC_JOB_SETUP
where SchemeFrontSystemId IN (select ORDNING_FORSYSTEM_ID
		from ORDNING_FORSYSTEM_PARM
		where ORDNING = @Ordning)

delete from ORDNING_FORSYSTEM_PARM
where ORDNING = @Ordning


delete from ORDNING_FORSYSTEM
where ORDNING = @Ordning

rollback TRAN


/* Show all the data */
/*
select *
from ORDNING_FORSYSTEM
where ORDNING = @Ordning

select *
from ORDNING_FORSYSTEM_PARM
where ORDNING = @Ordning

select *
from DATASYNC_JOB_SETUP
where SchemeFrontSystemId IN (select ORDNING_FORSYSTEM_ID
		from ORDNING_FORSYSTEM_PARM
		where ORDNING = @Ordning)
*/
