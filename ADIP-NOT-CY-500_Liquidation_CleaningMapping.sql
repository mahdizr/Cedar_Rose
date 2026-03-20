USE [ADIP]
GO

/****** Object:  StoredProcedure [dbo].[ADIP-NOT-CY-500_Liquidation_CleaningMapping]    Script Date: 20/03/2026 1:58:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Vivek
-- Create date: <10/03/2026>
-- Description:	<Description,,>
-- =============================================
-- EXEC [dbo].[ADIP-NOT-AE401_CleaningMapping]
CREATE PROCEDURE [dbo].[ADIP-NOT-CY-500_Liquidation_CleaningMapping]
	@DatasetUniqueID Int = 0
AS
BEGIN
	SET NOCOUNT ON;

	--insert into [ADIP].[dbo].ErrorLogs ([Date],[Action],[Type],[Import],[Value], [DatasetUniqueID], [IdStatus])
	--select getdate(),'EISAR - Datetime Cleaning Start','Info','EISAR_Cleaning',Null,@DatasetUniqueID,1

	----------------------------------- Cleaning -----------------------------------

	IF OBJECT_ID ('[ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation]', 'U') IS NOT NULL
	BEGIN
		DROP TABLE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation];
	END

	BEGIN 
	select * into [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation]
		FROM (
			SELECT [Detail_Page_URL]
			,[Registration No# of Company]
			,[Company Name]
			,[Company Address]
			,[Procedure Type]
			,[File Number]
			,[Court Application Number]
			,[Application Date]
			,[Court that issued the Order]
			,[Application by]
			,[Winding Up Order Date]
			,[Publication Date of the Winding Up Order]
			,[Annulment Date of the Winding Up Order]
			,[Way of Annulment]
			,[Examiners Name]
			,[Jurisdiction: Main, Secondary, Local]
			,[Completion Date of the Main Procedure]
			,[Deadline for Appeals Against the Order for Initializing the Proc]
			,[Competent Court for Appeals Against the Order for Initializing t]
			,[Deadline for Debt Verification Submissions]
			,[Name of Liquidator]
			,[Liquidator's Appointment Date]
			,[Liquidator's Address]
			,[Liquidator's Email]
			,[Date of First Meeting of Creditors]
			,[Date of First Meeting of Shareholders]
			,[?????????? ????????? ?????]
			,[Reason for suspension]
			,[Company Dissolution Date]
			,[Publication date of Dissolution]
			,[Date of Liquidator's Discharge]
			,[???????????]
			,[Name of Receiver/Manager]
			,[Address of Receiver/Manager]
			,[Receiver/Manager Appointment Date]
			,[Receiver/Manager Resignation Date]
			,[Name of Provisional Liquidator]
			,[Address of Provisional Liquidator]
			,[Date of Appointment of Provisional Liquidator]	  
			FROM [ADIP-NOT-CY-500].[dbo].[ADIP-NOT-CY500-merged_company_liquidation]
		) n
	END

	
	--Duplicate Records

	;WITH CTE AS (
	 SELECT *,
		 row_number() OVER(PARTITION BY [Detail_Page_URL]
		,[Registration No# of Company]
		,[Company Name]
		,[Company Address]
		,[Procedure Type]
		,[File Number]
		,[Court Application Number]
		,[Application Date]
		,[Court that issued the Order]
		,[Application by]
		,[Winding Up Order Date]
		,[Publication Date of the Winding Up Order]
		,[Annulment Date of the Winding Up Order]
		,[Way of Annulment]
		,[Examiners Name]
		,[Jurisdiction: Main, Secondary, Local]
		,[Completion Date of the Main Procedure]
		,[Deadline for Appeals Against the Order for Initializing the Proc]
		,[Competent Court for Appeals Against the Order for Initializing t]
		,[Deadline for Debt Verification Submissions]
		,[Name of Liquidator]
		,[Liquidator's Appointment Date]
		,[Liquidator's Address]
		,[Liquidator's Email]
		,[Date of First Meeting of Creditors]
		,[Date of First Meeting of Shareholders]
		,[?????????? ????????? ?????]
		,[Reason for suspension]
		,[Company Dissolution Date]
		,[Publication date of Dissolution]
		,[Date of Liquidator's Discharge]
		,[???????????]
		,[Name of Receiver/Manager]
		,[Address of Receiver/Manager]
		,[Receiver/Manager Appointment Date]
		,[Receiver/Manager Resignation Date]
		,[Name of Provisional Liquidator]
		,[Address of Provisional Liquidator]
		,[Date of Appointment of Provisional Liquidator]				  
			ORDER BY [Registration No# of Company] ) AS [rn]
		FROM [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation]
	)
	--select * 
	Delete 
	from CTE WHERE [rn] > 1

	ALTER TABLE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation]
	ADD ID INT NOT NULL IDENTITY(1,1),		
		IDATOM INT NULL,
		Found INT NULL,
		CompanyName NVARCHAR(500),
		CompanyNameLocal NVARCHAR(500),
		IsMain bit,
		IdTown INT NULL,
		PostalCode INT NULL,
		BuildingNo INT NULL,
		IdStreet INT NULL,
		IdContact INT NULL,
		LiquidatorIdTown INT NULL,
		LiquidatorPostalCode INT NULL,
		LiquidatorBuildingNo INT NULL,
		LiquidatorIdStreet INT NULL,
		LiquidatorIdContact INT NULL,
		ReceiverIdTown INT NULL,
		ReceiverPostalCode INT NULL,
		ReceiverBuildingNo INT NULL,
		ReceiverIdStreet INT NULL,
		ReceiverIdContact INT NULL,
		ProvisionalLiquidatorIdTown INT NULL,
		ProvisionalLiquidatorPostalCode INT NULL,
		ProvisionalLiquidatorBuildingNo INT NULL,
		ProvisionalLiquidatorIdStreet INT NULL,
		ProvisionalLiquidatorIdContact INT NULL,
		LiquidationOrganizationId INT NULL,
		ExaminersIsCompany INT NULL,
		LiquidatorIsCompany INT NULL,
		ReceiverIsCompany INT NULL,
		ProvisionalLiquidatorIsCompany INT NULL,
		HasOrder Bit,
		ignore bit,
		IdAnnoucementtype INT,
		LiquidatorPersonIdatom INT,
		ReceiverPersonIdatom INT,
		ExaminerPersonIdatom INT,
		ProvisionalLiquidatorPersonIdatom INT,
		[Application Date new] DATE,
		[Liquidator's Appointment Date new] DATE,
		[Publication date of Dissolution new] DATE,
		[Date of Liquidator's Discharge new] DATE,
		[Receiver/Manager Appointment Date new] DATE,
		[Receiver/Manager Resignation Date new] DATE,
		[Date of Appointment of Provisional Liquidator new] DATE,
		[Name of Liquidator 2] NVARCHAR(100),
		[Name of Receiver/Manager 2] NVARCHAR(100),
		[Name of Provisional Liquidator 2] NVARCHAR(100),
		Liquidator2PersonIdatom INT,
		Receiver2PersonIdatom INT,
		ProvisionalLiquidator2PersonIdatom INT,
		Liquidator2IsCompany INT NULL,
		Receiver2IsCompany INT NULL,
		ProvisionalLiquidator2IsCompany INT NULL

	-----------------------------Cleaning Start main file

	----[Company_name_english]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = [Company Name]


	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'!',' ') where [CompanyName] like N'%!%'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'"',' ') where [CompanyName] like N'%"%'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N',','.') where [CompanyName] like N'%[0-9],[0-9]%'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'`',' ') where [CompanyName] like N'%`%'  																																						
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'~',' ') where [CompanyName] like N'%~%'  																																																																						
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'@',' ') where [CompanyName] like N'%@%'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'%',' ') where [CompanyName] like N'%[%]%'  																																
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = left(CompanyName, len(CompanyName) -1) where [CompanyName] like N'%&'	 																																					
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'(',' ') where [CompanyName] like N'%(%' and [CompanyName] not like N'%)%'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'(',' ') where [CompanyName] not like N'%(%' and [CompanyName] like N'%)%'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = left([CompanyName], len([CompanyName]) -1) where [CompanyName] like N'%-'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'_',' ') where [CompanyName] like N'%[_]%'  	
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'+',' ') where [CompanyName] like N'%+%'  																																
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'\',' ') where [CompanyName] like N'%\%'  	
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'}',' ') where [CompanyName] like N'%}%'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'{',' ') where [CompanyName] like N'%{%'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N']',' ') where [CompanyName] like N'%]%'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'[',' ') where [CompanyName] like N'%]%'  																																
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N':',' ') where [CompanyName] like N'%:%'  																																						
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N';',' ') where [CompanyName] like N'%;%'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'/',' ') where [CompanyName] like N'%/%'  																																									
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'>',' ') where [CompanyName] like N'%>%'  																																						
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N',',' ') where [CompanyName] like N'%,%'	 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'<',' ') where [CompanyName] like N'%<%'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'  ',' ') where [CompanyName] like N'%  %'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'  ',' ') where [CompanyName] like N'%  %'  
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] Set [CompanyName] = REPLACE([CompanyName],N'  ',' ') where [CompanyName] like N'%  %'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [CompanyName] = null where isnull([CompanyName], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [CompanyName] = null where [CompanyName] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [CompanyName] = null where [CompanyName] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [CompanyName] = LTRIM(RTRIM([CompanyName])) 

	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ignore = 1 where [CompanyName] is null

	----[Registration No# of Company]
	
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Registration No# of Company] = REPLACE([Registration No# of Company],N'  ',' ') where [Registration No# of Company] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Registration No# of Company] = null where isnull([Registration No# of Company], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Registration No# of Company] = null where [Registration No# of Company] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Registration No# of Company] = null where [Registration No# of Company] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Registration No# of Company] = LTRIM(RTRIM([Registration No# of Company])) 

	----[Company Address]

	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Address] = REPLACE([Company Address],N'  ',' ') where [Company Address] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Address] = null where isnull([Company Address], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Address] = null where [Company Address] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Address] = null where [Company Address] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Address] = LTRIM(RTRIM([Company Address])) 
		
	----[Procedure Type]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Procedure Type] = REPLACE([Procedure Type],N'  ',' ') where [Procedure Type] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Procedure Type] = null where isnull([Procedure Type], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Procedure Type] = null where [Procedure Type] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Procedure Type] = null where [Procedure Type] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Procedure Type] = LTRIM(RTRIM([Procedure Type])) 

	----[Application Date]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date] = REPLACE([Application Date],N'  ',' ') where [Application Date] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date] = null where isnull([Application Date], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date] = null where [Application Date] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date] = null where [Application Date] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date] = LTRIM(RTRIM([Application Date])) 

	--[Application Date new]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date new] = RIGHT([Application Date], 4)+'-'+RIGHT(LEFT([Application Date],5),2)+'-'+LEFT(LEFT([Application Date],5),2)
	where [Application Date] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Application Date new] = null where isnull([Application Date new],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Application Date new] = LTRIM(RTRIM([Application Date new]))

	----[File Number]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [File Number] = REPLACE([File Number],N'  ',' ') where [File Number] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [File Number] = null where isnull([File Number], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [File Number] = null where [File Number] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [File Number] = null where [File Number] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [File Number] = LTRIM(RTRIM([File Number]))  

	----[Court Application Number]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court Application Number] = REPLACE([Court Application Number],N'  ',' ') where [Court Application Number] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court Application Number] = null where isnull([Court Application Number], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court Application Number] = null where [Court Application Number] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court Application Number] = null where [Court Application Number] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court Application Number] = LTRIM(RTRIM([Court Application Number])) 

	----[Court that issued the Order]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = REPLACE([Court that issued the Order],N'  ',' ') where [Court that issued the Order] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = null where isnull([Court that issued the Order], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = null where [Court that issued the Order] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = null where [Court that issued the Order] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = null where [Court that issued the Order] = '31/06/2021'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = null where [Court that issued the Order] = '31/02/2020'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Court that issued the Order] = LTRIM(RTRIM([Court that issued the Order])) 
	
	----[Winding Up Order Date]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Winding Up Order Date] = null where [Winding Up Order Date] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Winding Up Order Date] = REPLACE([Winding Up Order Date],N'  ',' ') where [Winding Up Order Date] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Winding Up Order Date] = null where isnull([Winding Up Order Date], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Winding Up Order Date] = null where [Winding Up Order Date] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Winding Up Order Date] = LTRIM(RTRIM([Winding Up Order Date])) 

	----[Publication Date of the Winding Up Order]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication Date of the Winding Up Order] = REPLACE([Publication Date of the Winding Up Order],N'  ',' ') where [Publication Date of the Winding Up Order] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication Date of the Winding Up Order] = null where isnull([Publication Date of the Winding Up Order], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication Date of the Winding Up Order] = null where [Publication Date of the Winding Up Order] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication Date of the Winding Up Order] = null where [Publication Date of the Winding Up Order] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication Date of the Winding Up Order] = LTRIM(RTRIM([Publication Date of the Winding Up Order])) 

	----[Annulment Date of the Winding Up Order]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Annulment Date of the Winding Up Order] = REPLACE([Annulment Date of the Winding Up Order],N'  ',' ') where [Annulment Date of the Winding Up Order] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Annulment Date of the Winding Up Order] = null where isnull([Annulment Date of the Winding Up Order], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Annulment Date of the Winding Up Order] = null where [Annulment Date of the Winding Up Order] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Annulment Date of the Winding Up Order] = null where [Annulment Date of the Winding Up Order] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Annulment Date of the Winding Up Order] = LTRIM(RTRIM([Annulment Date of the Winding Up Order])) 

	----[Way of Annulment]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Way of Annulment] = REPLACE([Way of Annulment],N'  ',' ') where [Way of Annulment] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Way of Annulment] = null where isnull([Way of Annulment], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Way of Annulment] = null where [Way of Annulment] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Way of Annulment] = null where [Way of Annulment] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Way of Annulment] = LTRIM(RTRIM([Way of Annulment])) 

	----[Examiners Name]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Examiners Name] = REPLACE([Examiners Name],N'  ',' ') where [Examiners Name] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Examiners Name] = null where isnull([Examiners Name], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Examiners Name] = null where [Examiners Name] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Examiners Name] = null where [Examiners Name] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Examiners Name] = LTRIM(RTRIM([Examiners Name])) 

	----[Jurisdiction: Main, Secondary, Local]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Jurisdiction: Main, Secondary, Local] = REPLACE([Jurisdiction: Main, Secondary, Local],N'  ',' ') where [Jurisdiction: Main, Secondary, Local] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Jurisdiction: Main, Secondary, Local] = null where isnull([Jurisdiction: Main, Secondary, Local], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Jurisdiction: Main, Secondary, Local] = null where [Jurisdiction: Main, Secondary, Local] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Jurisdiction: Main, Secondary, Local] = null where [Jurisdiction: Main, Secondary, Local] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Jurisdiction: Main, Secondary, Local] = LTRIM(RTRIM([Jurisdiction: Main, Secondary, Local])) 

	----[Completion Date of the Main Procedure]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Completion Date of the Main Procedure] = REPLACE([Completion Date of the Main Procedure],N'  ',' ') where [Completion Date of the Main Procedure] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Completion Date of the Main Procedure] = null where isnull([Completion Date of the Main Procedure], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Completion Date of the Main Procedure] = null where [Completion Date of the Main Procedure] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Completion Date of the Main Procedure] = null where [Completion Date of the Main Procedure] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Completion Date of the Main Procedure] = LTRIM(RTRIM([Completion Date of the Main Procedure])) 

	----[Deadline for Appeals Against the Order for Initializing the Proc]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Appeals Against the Order for Initializing the Proc] = REPLACE([Deadline for Appeals Against the Order for Initializing the Proc],N'  ',' ') where [Deadline for Appeals Against the Order for Initializing the Proc] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Appeals Against the Order for Initializing the Proc] = null where isnull([Deadline for Appeals Against the Order for Initializing the Proc], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Appeals Against the Order for Initializing the Proc] = null where [Deadline for Appeals Against the Order for Initializing the Proc] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Appeals Against the Order for Initializing the Proc] = null where [Deadline for Appeals Against the Order for Initializing the Proc] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Appeals Against the Order for Initializing the Proc] = LTRIM(RTRIM([Deadline for Appeals Against the Order for Initializing the Proc])) 

	----[Competent Court for Appeals Against the Order for Initializing t]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Competent Court for Appeals Against the Order for Initializing t] = REPLACE([Competent Court for Appeals Against the Order for Initializing t],N'  ',' ') where [Competent Court for Appeals Against the Order for Initializing t] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Competent Court for Appeals Against the Order for Initializing t] = null where isnull([Competent Court for Appeals Against the Order for Initializing t], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Competent Court for Appeals Against the Order for Initializing t] = null where [Competent Court for Appeals Against the Order for Initializing t] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Competent Court for Appeals Against the Order for Initializing t] = null where [Competent Court for Appeals Against the Order for Initializing t] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Competent Court for Appeals Against the Order for Initializing t] = LTRIM(RTRIM([Competent Court for Appeals Against the Order for Initializing t])) 

	----[Deadline for Debt Verification Submissions]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Debt Verification Submissions] = REPLACE([Deadline for Debt Verification Submissions],N'  ',' ') where [Deadline for Debt Verification Submissions] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Debt Verification Submissions] = null where isnull([Deadline for Debt Verification Submissions], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Debt Verification Submissions] = null where [Deadline for Debt Verification Submissions] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Debt Verification Submissions] = null where [Deadline for Debt Verification Submissions] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Deadline for Debt Verification Submissions] = LTRIM(RTRIM([Deadline for Debt Verification Submissions])) 

	----[Name of Liquidator]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = REPLACE([Name of Liquidator],N'  ',' ') where [Name of Liquidator] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = null where isnull([Name of Liquidator], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = null where [Name of Liquidator] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = null where [Name of Liquidator] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = LTRIM(RTRIM([Name of Liquidator])) 

	----[Name of Liquidator 2]
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Liquidator 2] = Right([Name of Liquidator],len([Name of Liquidator])-charindex('/',[Name of Liquidator])) WHERE [Name of Liquidator] like '%/%'
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Liquidator] = SUBSTRING([Name of Liquidator],0,CHARINDEX('/',[Name of Liquidator],0)) WHERE [Name of Liquidator] like '%/%' 	
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = REPLACE([Name of Liquidator],'  ',' ') where [Name of Liquidator] like '% %' 
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator 2] = REPLACE([Name of Liquidator 2],'  ',' ') where [Name of Liquidator 2] like '%  %'
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Liquidator] = NULL WHERE ISNULL([Name of Liquidator],'') = ''
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator] = LTRIM(RTRIM([Name of Liquidator]))
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Liquidator 2] = NULL WHERE ISNULL([Name of Liquidator 2],'') = ''
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Liquidator 2] = LTRIM(RTRIM([Name of Liquidator 2]))

	----[Liquidator's Appointment Date]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date] = REPLACE([Liquidator's Appointment Date],N'  ',' ') where [Liquidator's Appointment Date] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date] = null where isnull([Liquidator's Appointment Date], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date] = null where [Liquidator's Appointment Date] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date] = null where [Liquidator's Appointment Date] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date] = LTRIM(RTRIM([Liquidator's Appointment Date])) 

	---[Liquidator's Appointment Date new]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date new] = RIGHT([Liquidator's Appointment Date], 4)+'-'+RIGHT(LEFT([Liquidator's Appointment Date],5),2)+'-'+LEFT(LEFT([Liquidator's Appointment Date],5),2)
	where [Liquidator's Appointment Date] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Liquidator's Appointment Date new] = null where isnull([Liquidator's Appointment Date new],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Appointment Date new] = LTRIM(RTRIM([Liquidator's Appointment Date new]))

	----[Liquidator's Address]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Address] = REPLACE([Liquidator's Address],N'  ',' ') where [Liquidator's Address] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Address] = null where isnull([Liquidator's Address], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Address] = null where [Liquidator's Address] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Address] = null where [Liquidator's Address] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Address] = LTRIM(RTRIM([Liquidator's Address])) 

	----[Liquidator's Email]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Email] = REPLACE([Liquidator's Email],N'  ',' ') where [Liquidator's Email] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Email] = null where isnull([Liquidator's Email], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Email] = null where [Liquidator's Email] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Email] = null where [Liquidator's Email] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Liquidator's Email] = LTRIM(RTRIM([Liquidator's Email])) 

	----[Date of First Meeting of Creditors]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Creditors] = REPLACE([Date of First Meeting of Creditors],N'  ',' ') where [Date of First Meeting of Creditors] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Creditors] = null where isnull([Date of First Meeting of Creditors], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Creditors] = null where [Date of First Meeting of Creditors] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Creditors] = null where [Date of First Meeting of Creditors] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Creditors] = LTRIM(RTRIM([Date of First Meeting of Creditors])) 

	----[Date of First Meeting of Shareholders]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Shareholders] = REPLACE([Date of First Meeting of Shareholders],N'  ',' ') where [Date of First Meeting of Shareholders] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Shareholders] = null where isnull([Date of First Meeting of Shareholders], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Shareholders] = null where [Date of First Meeting of Shareholders] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Shareholders] = null where [Date of First Meeting of Shareholders] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of First Meeting of Shareholders] = LTRIM(RTRIM([Date of First Meeting of Shareholders])) 

	----[?????????? ????????? ?????]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [?????????? ????????? ?????] = REPLACE([?????????? ????????? ?????],N'  ',' ') where [?????????? ????????? ?????] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [?????????? ????????? ?????] = null where isnull([?????????? ????????? ?????], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [?????????? ????????? ?????] = null where [?????????? ????????? ?????] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [?????????? ????????? ?????] = null where [?????????? ????????? ?????] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [?????????? ????????? ?????] = LTRIM(RTRIM([?????????? ????????? ?????])) 

	----[Reason for suspension]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Reason for suspension] = REPLACE([Reason for suspension],N'  ',' ') where [Reason for suspension] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Reason for suspension] = null where isnull([Reason for suspension], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Reason for suspension] = null where [Reason for suspension] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Reason for suspension] = null where [Reason for suspension] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Reason for suspension] = LTRIM(RTRIM([Reason for suspension]))
	
	----[Company Dissolution Date]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Dissolution Date] = REPLACE([Company Dissolution Date],N'  ',' ') where [Company Dissolution Date] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Dissolution Date] = null where isnull([Company Dissolution Date], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Dissolution Date] = null where [Company Dissolution Date] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Dissolution Date] = null where [Company Dissolution Date] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Company Dissolution Date] = LTRIM(RTRIM([Company Dissolution Date])) 

	----[Publication date of Dissolution]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution] = REPLACE([Publication date of Dissolution],N'  ',' ') where [Publication date of Dissolution] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution] = null where isnull([Publication date of Dissolution], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution] = null where [Publication date of Dissolution] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution] = null where [Publication date of Dissolution] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution] = LTRIM(RTRIM([Publication date of Dissolution])) 

	---[Publication date of Dissolution new]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution new] = RIGHT([Publication date of Dissolution], 4)+'-'+RIGHT(LEFT([Publication date of Dissolution],5),2)+'-'+LEFT(LEFT([Publication date of Dissolution],5),2)
	where [Publication date of Dissolution] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Publication date of Dissolution new] = null where isnull([Publication date of Dissolution new],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Publication date of Dissolution new] = LTRIM(RTRIM([Publication date of Dissolution new]))

	----[Date of Liquidator's Discharge]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge] = REPLACE([Date of Liquidator's Discharge],N'  ',' ') where [Date of Liquidator's Discharge] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge] = null where isnull([Date of Liquidator's Discharge], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge] = null where [Date of Liquidator's Discharge] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge] = null where [Date of Liquidator's Discharge] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge] = LTRIM(RTRIM([Date of Liquidator's Discharge])) 

	---[Date of Liquidator's Discharge new]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge new] = RIGHT([Date of Liquidator's Discharge], 4)+'-'+RIGHT(LEFT([Date of Liquidator's Discharge],5),2)+'-'+LEFT(LEFT([Date of Liquidator's Discharge],5),2)
	where [Date of Liquidator's Discharge] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Date of Liquidator's Discharge new] = null where isnull([Date of Liquidator's Discharge new],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Liquidator's Discharge new] = LTRIM(RTRIM([Date of Liquidator's Discharge new]))

	----[???????????]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [???????????] = REPLACE([???????????],N'  ',' ') where [???????????] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [???????????] = null where isnull([???????????], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [???????????] = null where [???????????] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [???????????] = null where [???????????] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [???????????] = LTRIM(RTRIM([???????????])) 

	----[Name of Receiver/Manager]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = REPLACE([Name of Receiver/Manager],N'  ',' ') where [Name of Receiver/Manager] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = null where isnull([Name of Receiver/Manager], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = null where [Name of Receiver/Manager] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = null where [Name of Receiver/Manager] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = LTRIM(RTRIM([Name of Receiver/Manager])) 

	----[Name of Receiver/Manager 2]
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Receiver/Manager 2] = Right([Name of Receiver/Manager],len([Name of Receiver/Manager])-charindex('/',[Name of Receiver/Manager])) WHERE [Name of Receiver/Manager] like '%/%'
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Receiver/Manager] = SUBSTRING([Name of Receiver/Manager],0,CHARINDEX('/',[Name of Receiver/Manager],0)) WHERE [Name of Receiver/Manager] like '%/%' 	
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = REPLACE([Name of Receiver/Manager],'  ',' ') where [Name of Receiver/Manager] like '% %' 
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager 2] = REPLACE([Name of Receiver/Manager 2],'  ',' ') where [Name of Receiver/Manager 2] like '%  %'
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Receiver/Manager] = NULL WHERE ISNULL([Name of Receiver/Manager],'') = ''
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager] = LTRIM(RTRIM([Name of Receiver/Manager]))
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Receiver/Manager 2] = NULL WHERE ISNULL([Name of Receiver/Manager 2],'') = ''
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Receiver/Manager 2] = LTRIM(RTRIM([Name of Receiver/Manager 2]))

	----[Address of Receiver/Manager]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Receiver/Manager] = REPLACE([Address of Receiver/Manager],N'  ',' ') where [Address of Receiver/Manager] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Receiver/Manager] = null where isnull([Address of Receiver/Manager], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Receiver/Manager] = null where [Address of Receiver/Manager] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Receiver/Manager] = null where [Address of Receiver/Manager] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Receiver/Manager] = LTRIM(RTRIM([Address of Receiver/Manager])) 

	----[Receiver/Manager Appointment Date]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date] = REPLACE([Receiver/Manager Appointment Date],N'  ',' ') where [Receiver/Manager Appointment Date] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date] = null where isnull([Receiver/Manager Appointment Date], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date] = null where [Receiver/Manager Appointment Date] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date] = null where [Receiver/Manager Appointment Date] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date] = LTRIM(RTRIM([Receiver/Manager Appointment Date])) 

	---[Receiver/Manager Appointment Date new]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date new] = RIGHT([Receiver/Manager Appointment Date], 4)+'-'+RIGHT(LEFT([Receiver/Manager Appointment Date],5),2)+'-'+LEFT(LEFT([Receiver/Manager Appointment Date],5),2)
	where [Receiver/Manager Appointment Date] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Receiver/Manager Appointment Date new] = null where isnull([Receiver/Manager Appointment Date new],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Appointment Date new] = LTRIM(RTRIM([Receiver/Manager Appointment Date new]))

	----[Receiver/Manager Resignation Date]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date] = REPLACE([Receiver/Manager Resignation Date],N'  ',' ') where [Receiver/Manager Resignation Date] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date] = null where isnull([Receiver/Manager Resignation Date], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date] = null where [Receiver/Manager Resignation Date] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date] = null where [Receiver/Manager Resignation Date] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date] = LTRIM(RTRIM([Receiver/Manager Resignation Date])) 

	---[Receiver/Manager Resignation Date new]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date new] = RIGHT([Receiver/Manager Resignation Date], 4)+'-'+RIGHT(LEFT([Receiver/Manager Resignation Date],5),2)+'-'+LEFT(LEFT([Receiver/Manager Resignation Date],5),2)
	where [Receiver/Manager Resignation Date] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Receiver/Manager Resignation Date new] = null where isnull([Receiver/Manager Resignation Date new],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Receiver/Manager Resignation Date new] = LTRIM(RTRIM([Receiver/Manager Resignation Date new]))

	----[Name of Provisional Liquidator]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = REPLACE([Name of Provisional Liquidator],N'  ',' ') where [Name of Provisional Liquidator] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = null where isnull([Name of Provisional Liquidator], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = null where [Name of Provisional Liquidator] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = null where [Name of Provisional Liquidator] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = LTRIM(RTRIM([Name of Provisional Liquidator])) 

	----[Name of Provisional Liquidator 2]
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Provisional Liquidator 2] = Right([Name of Provisional Liquidator],len([Name of Provisional Liquidator])-charindex('/',[Name of Provisional Liquidator])) WHERE [Name of Provisional Liquidator] like '%/%'
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Provisional Liquidator] = SUBSTRING([Name of Provisional Liquidator],0,CHARINDEX('/',[Name of Provisional Liquidator],0)) WHERE [Name of Provisional Liquidator] like '%/%' 	
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = REPLACE([Name of Provisional Liquidator],'  ',' ') where [Name of Provisional Liquidator] like '% %' 
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator 2] = REPLACE([Name of Provisional Liquidator 2],'  ',' ') where [Name of Provisional Liquidator 2] like '%  %'
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Provisional Liquidator] = NULL WHERE ISNULL([Name of Provisional Liquidator],'') = ''
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator] = LTRIM(RTRIM([Name of Provisional Liquidator]))
	UPDATE [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] SET [Name of Provisional Liquidator 2] = NULL WHERE ISNULL([Name of Provisional Liquidator 2],'') = ''
	update [ADIP-NOT-TN-200].[dbo].[CY500-merged_company_liquidation] set [Name of Provisional Liquidator 2] = LTRIM(RTRIM([Name of Provisional Liquidator 2]))

	----[Address of Provisional Liquidator]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Provisional Liquidator] = REPLACE([Address of Provisional Liquidator],N'  ',' ') where [Address of Provisional Liquidator] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Provisional Liquidator] = null where isnull([Address of Provisional Liquidator], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Provisional Liquidator] = null where [Address of Provisional Liquidator] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Provisional Liquidator] = null where [Address of Provisional Liquidator] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Address of Provisional Liquidator] = LTRIM(RTRIM([Address of Provisional Liquidator])) 

	----[Date of Appointment of Provisional Liquidator]
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = REPLACE([Date of Appointment of Provisional Liquidator],N'  ',' ') where [Date of Appointment of Provisional Liquidator] like N'%  %' 
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = null where isnull([Date of Appointment of Provisional Liquidator], '') = ''
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = null where [Date of Appointment of Provisional Liquidator] = 'N/A'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = null where [Date of Appointment of Provisional Liquidator] = 'NA'
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = LTRIM(RTRIM([Date of Appointment of Provisional Liquidator])) 
	
	---[Date of Appointment of Provisional Liquidator]
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = RIGHT([Date of Appointment of Provisional Liquidator], 4)+'-'+RIGHT(LEFT([Date of Appointment of Provisional Liquidator],5),2)+'-'+LEFT(LEFT([Date of Appointment of Provisional Liquidator],5),2)
	where [Date of Appointment of Provisional Liquidator] is not null
	Update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] SET [Date of Appointment of Provisional Liquidator] = null where isnull([Date of Appointment of Provisional Liquidator],'')='' 
	UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set [Date of Appointment of Provisional Liquidator] = LTRIM(RTRIM([Date of Appointment of Provisional Liquidator]))
	

	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ExaminersIsCompany = 1 where ExaminersIsCompany is Null and [Examiners Name] LIKE N'%????%'

	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set LiquidatorIsCompany = 1 where LiquidatorIsCompany is Null and [Name of Liquidator] LIKE N'%????%'

	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Liquidator2IsCompany = 1 where Liquidator2IsCompany is Null and [Name of Liquidator 2] LIKE N'%????%'
	
	
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ReceiverIsCompany = 1 where ReceiverIsCompany is Null and [Name of Receiver/Manager] LIKE N'%????%'

	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set Receiver2IsCompany = 1 where Receiver2IsCompany is Null and [Name of Receiver/Manager 2] LIKE N'%????%'

	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidatorIsCompany = 1 where ProvisionalLiquidatorIsCompany is Null and [Name of Provisional Liquidator] LIKE N'%????%'

	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%&%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'??????'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????? ??? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????? ???????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????? ??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%LTD %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%LIMITED%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%LLC%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%L.L.C%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'% Co'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Company%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Corp%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Group%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Trading%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%General%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Import%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Export%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%International%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Industrial%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Techn%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Services%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Logistics%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Clinic%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Medical%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Center%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Lab%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Arabia%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Middle East%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Travels%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Agency%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Workshop%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Global%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Industries%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Food%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Electric%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Metering%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Wellness%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Healthcare%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????? ???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????? ?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????? ????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???? %'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Access%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Advance%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Co%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%CONTRACTING%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Defined%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Design%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Diamond%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Display%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Est%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Estate%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Excellence%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Facilities%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%For%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%FZ%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Multi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%OMRAN%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Pearl%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Pro%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Real%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Saudi%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Systems%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Tech%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Technology%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Telecom%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%Trust%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%United%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%???????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%??????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%?????%'
	update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ProvisionalLiquidator2IsCompany = 1 where ProvisionalLiquidator2IsCompany is Null and [Name of Provisional Liquidator 2] LIKE N'%????%'


	----check which one is main
	--consider the main one with the most recent announcement date and all other will be added as history.Ex : for older announcement dates , the banckrutcy details will be ticked as history and company name will be added to trading name history and legal form also as history."
	-------------------- Main Companies
	--;WITH CTE as (
	--			select distinct ID,[Registration nbr], [Date new],
	--			row_number() OVER(PARTITION BY [Registration nbr] ORDER BY [Date new] desc) AS [rn]
	--			from [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation]
	--			where [Registration nbr] is not null
	--)
	--UPDATE E SET ignore = 1
	--FROM CTE c
	--JOIN [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] E on c.[Registration nbr] = e.[Registration nbr] and e.[Date new] = c.[Date new]  
	--WHERE c.rn > 1

	--;WITH CTE as (
	--			select distinct ID,CompanyName, [Date new],
	--			row_number() OVER(PARTITION BY CompanyName ORDER BY [Date new] desc) AS [rn]
	--			from [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation]
	--			where CompanyName is not null
	--)
	--UPDATE E SET ignore = 1
	--FROM CTE c
	--JOIN [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] E on e.CompanyName = c.CompanyName and c.[Date new] = e.[Date new]   
	--WHERE c.rn > 1 and ignore is null
	--update [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set ignore=null

	--select * 
	----UPDATE E
	----SET ignore = 1
	--FROM [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] E
	--WHERE E.[Registration nbr] IS NULL
	--AND EXISTS (
	--	SELECT 1
	--	FROM [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] X
	--	WHERE X.ID = E.ID
	--		AND X.[Registration nbr] IS NOT NULL
	--);



	----------------------------------------------Mapping------------------------------------------------

	--UPDATE [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] set IdRegister = a.[IdRegister]
	--FROM [TestCrifis2].[dbo].[SaudiRegisterPrefix] a
	--inner join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] b on left([CR Nbr], 4) = a.[Prefix]

	---------address_town in main table 
	UPDATE s set s.LiquidatorIdTown = t.id 
	from [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s 
	join TestCrifis2.dbo.tblDic_GeoTowns t on s.[Liquidator's Address] = t.townlocal 
	join TestCrifis2.dbo.tbldic_geodistricts d on d.id = t.IdDistrict
	join TestCrifis2.dbo.tbldic_geocountries c on c.id = d.IdCountry
	where c.ID = 36 and s.IdTown is null and isnull(s.[Liquidator's Address],'') <>''
	
	--select * from ADIP.dbo.ADIP_Mapping a where FieldValue =N'?????? - ?????'

	update s set s.LiquidatorIdTown = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Liquidator's Address] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'Town'
	and a.MappToID is not null and s.LiquidatorIdTown is null 

	update s set s.LiquidatorPostalCode = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Liquidator's Address] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'PostalCode'
	and a.MappToID is not null and s.LiquidatorPostalCode is null 

	update s set s.LiquidatorIdStreet = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Liquidator's Address] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'Street'
	and a.MappToID is not null and s.LiquidatorIdStreet is null 

	update s set s.LiquidatorBuildingNo = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Liquidator's Address] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'BuildingNo'
	and a.MappToID is not null and s.LiquidatorBuildingNo is null 

	update s set s.ReceiverIdTown = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Receiver/Manager] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'Town'
	and a.MappToID is not null and s.ReceiverIdTown is null 

	update s set s.ReceiverPostalCode = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Receiver/Manager] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'PostalCode'
	and a.MappToID is not null and s.ReceiverPostalCode is null 

	update s set s.ReceiverIdStreet = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Receiver/Manager] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'Street'
	and a.MappToID is not null and s.ReceiverIdStreet is null 

	update s set s.ReceiverBuildingNo = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Receiver/Manager] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'BuildingNo'
	and a.MappToID is not null and s.ReceiverBuildingNo is null 

	update s set s.ProvisionalLiquidatorIdTown = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Provisional Liquidator] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'Town'
	and a.MappToID is not null and s.ProvisionalLiquidatorIdTown is null 

	update s set s.ProvisionalLiquidatorPostalCode = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Provisional Liquidator] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'PostalCode'
	and a.MappToID is not null and s.ProvisionalLiquidatorPostalCode is null 

	update s set s.ProvisionalLiquidatorIdStreet = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].Cyprus.[CY500-merged_company_liquidation] s on s.[Address of Provisional Liquidator] = a.FieldValue 
	and a.CountryName = 'Tunisia' and MappingType = 'Street'
	and a.MappToID is not null and s.ProvisionalLiquidatorIdStreet is null 

	update s set s.ProvisionalLiquidatorIdStreet = a.MappToID 
	from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Address of Provisional Liquidator] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'BuildingNo'
	and a.MappToID is not null and s.ProvisionalLiquidatorIdStreet is null 

	--update s set s.IdAnnoucementtype= a.MappToID from ADIP.dbo.ADIP_Mapping a
	--join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Bankruptcy Type] = a.FieldValue 
	--and a.CountryName = 'Cyprus' and MappingType = 'Bankruptcy Type'
	--and a.MappToID is not null and s.IdAnnoucementtype is null 

	update s set s.LiquidationOrganizationId= a.MappToID from ADIP.dbo.ADIP_Mapping a
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] s on s.[Court that issued the Order] = a.FieldValue 
	and a.CountryName = 'Cyprus' and MappingType = 'Liquidation Organization'
	and a.MappToID is not null and s.LiquidationOrganizationId is null 


	------------------------------------------------------------------- Update Found (Comapnies Identification)-----------------------------------------------------

	Update q set q.IDATOM = c.idatom, q.Found = 1
	from TestCrifis2.dbo.tblcompanyids c
	join [ADIP-NOT-CY-500].[dbo].[CY500-merged_company_liquidation] q on c.number = q.[Registration No# of Company]
	join TestCrifis2.dbo.tblatoms a on a.idatom = c.idatom and ISNULL(a.IsDeleted,0) = 0
	join TestCrifis2.dbo.tblCompanies com on ISNULL(com.RegisteredName,com.[Name]) = q.[Company Name]
	where 
	q.[Registration No# of Company] is not null and q.[Company Name] is not null
	and IdOrganisation = 4024813 and c.IdRegister = 4074755
	and q.IDATOM is null
	and c.idtype = 4047632


	
END
GO


