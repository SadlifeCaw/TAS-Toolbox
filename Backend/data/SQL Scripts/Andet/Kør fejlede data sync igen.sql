
DECLARE @date DATETIME2 = '2023-06-12 00:00:00.000'


BEGIN TRAN

-- oversigt over alle fejlede datasync given dato
select *
from DATASYNC_JOB
where SUCCESS = 0  and CREATED_DATE > @date --and CREATED_DATE > '2023-06-11 00:00:00.000'
order by 1 desc


-- køre det fejlede data sync igen
UPDATE DATASYNC_JOB
SET STATUS = 0, SUCCESS = NULL, LASTUPDATE = NULL, MESSAGE = NULL, DUE_DATE = NULL
where DATASYNC_JOB_ID IN(select DATASYNC_JOB_ID
from DATASYNC_JOB
where SUCCESS = 0  and CREATED_DATE > @date)


-- oversigt over alle datasync job for given dato
select *
from DATASYNC_JOB
where CREATED_DATE > @date
order by 1 desc


ROLLBACK TRAN





