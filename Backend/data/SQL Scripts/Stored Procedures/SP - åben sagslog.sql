SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[OpenActivity]
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

	UPDATE SAGSLOG
	SET GODKENDT_DATO = NULL, GODKENDT_INIT = NULL
	WHERE SAGSLOG_ID = @SagslogId

	PRINT 'Efter ændring'

	SELECT SAGSLOG_ID, ID_SAG, GODKENDT_DATO, GODKENDT_INIT
	FROM SAGSLOG
	WHERE SAGSLOG_ID = @SagslogId
	
	PRINT 'Aktiviteten er åben'

END
GO
