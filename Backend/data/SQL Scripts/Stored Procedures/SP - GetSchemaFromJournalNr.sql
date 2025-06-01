USE [NORDEA_TAS_PROD]
GO

/****** Object:  StoredProcedure [dbo].[GetSchemaFromJournalNr]    Script Date: 11/22/2023 9:51:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[NEAL_GetSchemaFromJournalNr] @jrnl nvarchar(50)
	
AS
BEGIN
	select ID_SAG
	,sa.FORSYSTEM_ID
	,f.TEKST
	,AKTIVITET_ID
	,SAGSLOG_ID
	,SAGSLOG_ID_LAAST
	,SAGSLOG_ID_GENAABEN
	,AKTIVITET_ID_LAAST
	,sa.OBJEKT
from SAG_FORSYSTEM_AKTIVITET sa
left join FORSYSTEM f
on sa.FORSYSTEM_ID = f.FORSYSTEM_ID
where ID_SAG IN(select ID_SAG from SAG where JOURNAL_NR = @jrnl)
order by SAGSLOG_ID desc
END
GO

