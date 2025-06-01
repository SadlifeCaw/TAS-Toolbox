/****** Object:  StoredProcedure [dbo].[CloseActivity]    Script Date: 7/3/2023 9:01:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CloseActivity]
	-- Add the parameters for the stored procedure here
	@SagslogId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	PRINT @SagslogId
	PRINT 'Før ændring'

	SELECT SAGSLOG_ID, ID_SAG, GODKENDT_DATO, GODKENDT_INIT
	FROM SAGSLOG
	WHERE SAGSLOG_ID = @SagslogId

    -- Insert statements for procedure here
	UPDATE SAGSLOG
	SET GODKENDT_DATO = (select CURRENT_TIMESTAMP), TEKST = 'Godkendt aktiviteten via databasen', GODKENDT_INIT = 'ADM1'
	WHERE SAGSLOG_ID = @SagslogId

	PRINT 'Efter ændring'

	SELECT SAGSLOG_ID, ID_SAG, GODKENDT_DATO, GODKENDT_INIT
	FROM SAGSLOG
	WHERE SAGSLOG_ID = @SagslogId

	PRINT 'Aktiviteten er godkendt.'
END
GO