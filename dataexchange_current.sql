USE [Crifis]
GO

/****** Object:  StoredProcedure [dbo].[sp_DataExchange_DataLoading]    Script Date: 2/27/2026 3:25:01 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Mahdi
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 04/09/2025 - JDP - Added code to transfer Additional Financial figures to Primary Financials and also generate Ratios
-- 22/10/2025: ATHOS: INSERT INTO tblCompanies_FinancialsAdditional to avoid DESYNC of IDs and violation of primary key.
-- 03/11/2025: Vivek: Changes to Financials, Added TRANSACT to the script.
-- 03/11/2025: Vivek: Changes to HistoricalManagement , ShareholderCompanies and null checks in import script.
--                    Added conditions to avoid Inserting data when Registers Data is not available
-- 11/11/2025: Vivek: Changes to street mappings uncommented.
-- 20/11/2025: Removed RankingId condition and changed source grading from B2 to A2.
-- 21/11/2025: Neeraj: Update - Fixed ShareholderIndividual JSON Import and removed condition to check if at least an activity exists in the company
-- 01/12/2025: JP: Added i.ManagerType='Company' on query for Companies with join on JDP_TMP_HistoricalManagements_Main
-- 08/12/2025: NB : ValueOfShare commented in UPDATE/INSERT
-- 26/01/2026: Vivek: Added UPPER keyword for Individual Names
--					  Modified Financial Date json import query in AdditionalFinancials
-- 27/01/2026: Vivek: Added DateStart column while updating/inserting data in tblCompanies2Status
-- 30/01/2026: Vivek: Added script for updating/inserting data in adddress that are not main in tblAddresses
-- 05/02/2026: Vivek: Commented all scripts related to ShortName/ShortNameLocal as requested in Consolidated Errors file
--					  Added script for adding Manager Companies
-- 25/02/2026: Vivek: Added town conditions while mapping Area and Street in the Address mapping section

-- =============================================
CREATE PROCEDURE [dbo].[sp_DataExchange_DataLoading]
	@JSON nvarchar(max), @orderid int = null,@SupplierId int
AS
BEGIN

	DECLARE @ErrorMessage NVARCHAR(max),@ErrorSeverity NVARCHAR(max),@ErrorState NVARCHAR(max)

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
        if(@orderid is not null)
		begin
			insert into [dbo].[tblDataLoading_JSON](OrderID, [JSON], SupplierId)
			values(@orderid, @JSON, @SupplierId);
		end

		--if(@NoTrace =1) 
		--begin
		--	select 2;
		--	return;
		--end

		BEGIN TRANSACTION;
		BEGIN TRY

		DECLARE @UID varchar(50),@UpdateDate DATE,@Subject NVARCHAR(100),@SubjectNativeName NVARCHAR(100),
		@COMPANYSHORTNAME nvarchar(100),@COMPANYSHORTNAMELOCAL nvarchar(100),@DATESTARTED DATE,@DATEREGISTERED DATE,
		@idatom int,@Country NVARCHAR(100),
	
		@SourceID INT = 11, @IntelligenceID INT = 6, @RankingID INT = 2,
		@DTRanking int = null
		Declare @DTSourceID nvarchar(10), @DTIntelligenceID nvarchar(10)

		SELECT 
		@UID=JSON_VALUE(@Json, '$.UID'),
		@UpdateDate=JSON_VALUE(@Json, '$.UPDATEDATE'),
		@Subject=JSON_VALUE(@Json, '$.SUBJECT'),
		@SubjectNativeName=JSON_VALUE(@Json, '$.SUBJECTNATIVENAME'),
		@COMPANYSHORTNAME=JSON_VALUE(@Json, '$.COMPANYSHORTNAME'),
		@COMPANYSHORTNAMELOCAL=JSON_VALUE(@Json, '$.COMPANYSHORTNAMELOCAL'),
		@DATESTARTED=JSON_VALUE(@Json, '$.DATESTARTED'),
		@DATEREGISTERED=JSON_VALUE(@Json, '$.DATEREGISTERED')
		
		SELECT @Country=JSON_VALUE(Addr.value, '$.COUNTRY')
		FROM OPENJSON(@Json, '$.ADDRESSES.ADDRESS') AS Addr


		
		--IF OBJECT_ID ('tempdb..tblRecordsSIranking', 'U') IS NOT NULL
		--DROP TABLE tblRecordsSIranking;

		--CREATE TABLE tblRecordsSIranking (
		--	Source NVARCHAR(1),
		--	Intelligence INT,
		--	Ranking INT
		--);

		--INSERT INTO tblRecordsSIranking (Source, Intelligence, Ranking) VALUES
		--('A', 1, 1),
		--('A', 2, 2),
		--('A', 3, 3),
		--('A', 4, 4),
		--('B', 1, 5),
		--('B', 2, 6),
		--('B', 3, 7),
		--('B', 4, 8),
		--('C', 1, 9),
		--('C', 2, 10),
		--('C', 3, 11),
		--('C', 4, 12),
		--('D', 1, 13),
		--('D', 2, 14),
		--('D', 3, 15),
		--('D', 4, 16)

		--SELECT @UID,@UpdateDate,@Subject,@SubjectNativeName,@COMPANYSHORTNAME,@COMPANYSHORTNAMELOCAL,@DATESTARTED,@DATEREGISTERED,@Country

		--------------------------------------------------TradingNames----------------------------------------------------

		IF OBJECT_ID ('tempdb..#TradingNames', 'U') IS NOT NULL
		DROP TABLE #TradingNames;

		CREATE TABLE #TradingNames (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		[Name] NVARCHAR(255),
		STARTDATE DATE,
		ENDDATE DATE,
		DateUpdated DATE,
		DateReported DATE,
		[Source] CHAR(1),
		Intelligence INT,
		IsNative BIT,
		IsHistory bit
		);

		INSERT INTO #TradingNames (Name, DateUpdated, DateReported, Source, Intelligence, IsNative, IsHistory)
		SELECT 
		JSON_VALUE(value, '$.NAME') AS Name,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEREPORTED'), 103) AS DATEREPORTED,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEUPDATED'), 103) AS DATEUPDATED,
		JSON_VALUE(value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		0 AS IsNative,
		0 AS IsHistory
		FROM OPENJSON(@json, '$.TRADINGNAMES')
		UNION ALL
		SELECT 
		JSON_VALUE(value, '$.NAME') AS Name,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEREPORTED'), 103) AS DATEREPORTED,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEUPDATED'), 103) AS DATEUPDATED,
		JSON_VALUE(value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		1 AS IsNative,
		0 AS IsHistory
		FROM OPENJSON(@json, '$.NATIVETRADINGNAMES')

		
		
		--------------------------------------------------FormerNames----------------------------------------------------

		----IF OBJECT_ID ('tempdb..#FormerNames', 'U') IS NOT NULL
		----DROP TABLE #FormerNames;

		----CREATE TABLE #FormerNames (
		----Name NVARCHAR(255),
		----DATEREPORTED DATE,
		----DATEUPDATED DATE,
		----SOURCE CHAR(1),
		----INTELLIGENCE INT,
		----IsNative BIT
		----);
		INSERT INTO #TradingNames (Name, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE,IsNative, IsHistory)
		SELECT 
		JSON_VALUE(value, '$.NAME') AS Name,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEREPORTED'), 103) AS DATEREPORTED,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEUPDATED'), 103) AS DATEUPDATED,
		JSON_VALUE(value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		0 AS IsNative,
		1 AS IsHistory
		FROM OPENJSON(@json, '$.FORMERNAMES')
		UNION ALL
		SELECT 
		JSON_VALUE(value, '$.NAME') AS Name,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEREPORTED'), 103) AS DATEREPORTED,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEUPDATED') , 103) AS DATEUPDATED,
		JSON_VALUE(value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		1 AS IsNative,
		1 AS IsHistory
		FROM OPENJSON(@json, '$.FORMERNATIVENAMES');


		--JP ADDED
		--select * from #TradingNames

		--------------------------------------------------TRADINGNAMESHISTORICAL----------------------------------------------------

		--IF OBJECT_ID ('tempdb..#TRADINGNAMESHISTORICAL', 'U') IS NOT NULL
		--DROP TABLE #TRADINGNAMESHISTORICAL;

		--CREATE TABLE #TRADINGNAMESHISTORICAL (
		--NAME NVARCHAR(255),
		--STARTDATE DATE,
		--ENDDATE DATE,
		--DATEREPORTED DATE,
		--DATEUPDATED DATE,
		--SOURCE CHAR(1),
		--INTELLIGENCE INT
		--)

		INSERT INTO #TradingNames (NAME, STARTDATE, ENDDATE, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE, IsNative, IsHistory)
		SELECT 
		JSON_VALUE(value, '$.NAME') AS NAME,
		CONVERT(DATE,JSON_VALUE(value, '$.STARTDATE')  , 103) AS STARTDATE,
		CONVERT(DATE,JSON_VALUE(value, '$.ENDDATE')  , 103) AS ENDDATE,
		CONVERT(DATE,JSON_VALUE(value, '$.DATEREPORTED')  , 103) AS DATEREPORTED,
		CONVERT(DATE,JSON_VALUE(value, '$.DATEUPDATED')  , 103) AS DATEUPDATED,
		JSON_VALUE(value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		CASE WHEN JSON_VALUE(value, '$.NAME') like '%[A-Za-z]%' THEN 0 when JSON_VALUE(value, '$.NAME') not like '%[A-Za-z]%' THEN 1 END,1
		FROM OPENJSON(@json, '$.TRADINGNAMESHISTORICAL.TRADINGNAMEHISTORICAL');

		----select * from #TRADINGNAMESHISTORICAL

		--------------------------------------------------REGISTEREDTRADINGNAMESHISTORICAL----------------------------------------------------

		--IF OBJECT_ID ('tempdb..#REGISTEREDTRADINGNAMESHISTORICAL', 'U') IS NOT NULL
		--DROP TABLE #REGISTEREDTRADINGNAMESHISTORICAL;

		--CREATE TABLE #REGISTEREDTRADINGNAMESHISTORICAL (
		--NAME NVARCHAR(255),
		--STARTDATE DATE,
		--ENDDATE DATE,
		--DATEREPORTED DATETIME,
		--DATEUPDATED DATETIME,
		--SOURCE CHAR(1),
		--INTELLIGENCE INT
		--);
		INSERT INTO #TradingNames (NAME, STARTDATE, ENDDATE, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE, IsNative, IsHistory)
		SELECT 
		JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.NAME') AS NAME,
		CONVERT(DATE,JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.STARTDATE')  , 103) AS STARTDATE,
		CONVERT(DATE,JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.ENDDATE')  , 103) AS ENDDATE,
		CONVERT(DATE,JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.DATEREPORTED')  , 103) AS DATEREPORTED,
		CONVERT(DATE,JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.DATEUPDATED')  , 103) AS DATEUPDATED,
		JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		CASE WHEN JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.NAME') like '%[A-Za-z]%' THEN 0 
		when JSON_VALUE(@json, '$.REGISTEREDTRADINGNAMESHISTORICAL.REGISTEREDTRADINGNAMEHISTORICAL.NAME') not like '%[A-Za-z]%' THEN 1 END,1;

		
		--------------------------------------------------Address----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Address', 'U') IS NOT NULL
		DROP TABLE #Address;

		CREATE TABLE #Address (
			ID INT IDENTITY(1,1) PRIMARY KEY,
			ADDRESSTYPE NVARCHAR(255),
			MAIN NVARCHAR(10),
			BUILDING NVARCHAR(255),
			BUILDINGNO NVARCHAR(50),
			STREET NVARCHAR(255),
			AREA NVARCHAR(255),
			TOWN NVARCHAR(255),
			COUNTRY NVARCHAR(255),
			POSTALCODE NVARCHAR(50),
			POBOX NVARCHAR(50),
			POSTALTOWN NVARCHAR(255),
			DATEREPORTED DATE,
			DATEUPDATED DATE,
			SOURCE NVARCHAR(10),
			Intelligence NVARCHAR(10),
			idtown int null,
			idarea int null,
			idstreet int null,
			idBuilding int null,
			Imported bit null,
			AddressTypeID INT null,
			IdTownPostal INT null
		)

		IF OBJECT_ID ('tempdb..#Contacts', 'U') IS NOT NULL
		DROP TABLE #Contacts;

		CREATE TABLE #Contacts (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		ADDRESSTYPE NVARCHAR(255),
		MAIN NVARCHAR(10),
		STREET NVARCHAR(255),
		AREA NVARCHAR(255),
		TOWN NVARCHAR(255),
		COUNTRY NVARCHAR(255),
		PHONETYPE NVARCHAR(50),
		PHONENUMBER NVARCHAR(50),
		WEB NVARCHAR(255),
		EMAIL NVARCHAR(255),
		IdAddress int null,
		Imported bit null,
		Idcontact INT
		)

		INSERT INTO #Address
		(
		ADDRESSTYPE, MAIN, BUILDING, BUILDINGNO, STREET, AREA, TOWN, COUNTRY,
		POSTALCODE, POBOX, POSTALTOWN, DATEREPORTED, DATEUPDATED,[SOURCE]
		)

		SELECT DISTINCT
		JSON_VALUE(Addr.value, '$.ADDRESSTYPE') AS [ADDRESSTYPE],
		JSON_VALUE(Addr.value, '$.MAIN') AS [MAIN],
		JSON_VALUE(Addr.value, '$.BUILDING') AS [BUILDING],
		JSON_VALUE(Addr.value, '$.BUILDINGNO') AS [BUILDINGNO],
		JSON_VALUE(Addr.value, '$.STREET') AS [STREET],
		JSON_VALUE(Addr.value, '$.AREA') AS [AREA],
		JSON_VALUE(Addr.value, '$.TOWN') AS [TOWN],
		JSON_VALUE(Addr.value, '$.COUNTRY') AS [COUNTRY],
		JSON_VALUE(Addr.value, '$.POSTALCODE') AS [POSTALCODE],
		JSON_VALUE(Addr.value, '$.POBOX') AS [POBOX],
		JSON_VALUE(Addr.value, '$.POSTALTOWN') AS [POSTALTOWN],
		CONVERT(DATE,JSON_VALUE(Addr.value, '$.DATEREPORTED'),103) AS [DATEREPORTED],
		CONVERT(DATE,JSON_VALUE(Addr.value, '$.DATEUPDATED'),103) AS [DATEUPDATED],
		JSON_VALUE(Addr.value, '$.SOURCE') AS [SOURCE]
		FROM OPENJSON(@Json, '$.ADDRESSES.ADDRESS') AS Addr


		INSERT INTO #Contacts
		(
		ADDRESSTYPE,Main, STREET, AREA, TOWN, COUNTRY, PHONETYPE, PHONENUMBER, WEB, EMAIL
		)

		SELECT DISTINCT
		JSON_VALUE(Addr.value, '$.ADDRESSTYPE') AS [ADDRESSTYPE],
		JSON_VALUE(Addr.value, '$.MAIN') AS [MAIN],
		JSON_VALUE(Addr.value, '$.STREET') AS [STREET],
		JSON_VALUE(Addr.value, '$.AREA') AS [AREA],
		JSON_VALUE(Addr.value, '$.TOWN') AS [TOWN],
		JSON_VALUE(Addr.value, '$.COUNTRY') AS [COUNTRY],
		JSON_VALUE(PHONE.value, '$.PHONETYPE') AS [PHONETYPE],
		JSON_VALUE(PHONE.value, '$.PHONENUMBER') AS [PHONENUMBER],
		JSON_VALUE(Addr.value, '$.WEBSITES.WEB') AS [WEB],
		JSON_VALUE(Addr.value, '$.EMAILS.EMAIL') AS [EMAIL]
		FROM OPENJSON(@Json, '$.ADDRESSES.ADDRESS') AS Addr
		CROSS APPLY OPENJSON(Addr.value, '$.PHONES.PHONE') AS PHONE
		
	
		--------------------------------------------------MANAGERSINDIVIDUALS----------------------------------------------------

		IF OBJECT_ID ('tempdb..#MANAGERSINDIVIDUALS', 'U') IS NOT NULL
		DROP TABLE #MANAGERSINDIVIDUALS;

		CREATE TABLE #MANAGERSINDIVIDUALS (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		CRiSNO NVARCHAR(50),
		MANAGERINDIVIDUALNAME NVARCHAR(255),
		MANAGERINDIVIDUALNAME_New NVARCHAR(255), ----Name without Title
		MANAGERINDIVIDUALLANGUAGE NVARCHAR(255),
		MANAGERINDIVIDUALGENDER NVARCHAR(50),
		MANAGERINDIVIDUALNATIONALITY NVARCHAR(255),
		MANAGERINDIVIDUALPOSITION NVARCHAR(255),
		MANAGERIDPOSITION INT,
		STARTDATE DATE NULL,
		DATEREPORTED DATE,
		DATEUPDATED DATE,
		[SOURCE] CHAR(1),
		INTELLIGENCE INT,
		PersonIdatom INT
		);

		INSERT INTO #MANAGERSINDIVIDUALS ( CRiSNO, MANAGERINDIVIDUALNAME, 
		MANAGERINDIVIDUALPOSITION, MANAGERINDIVIDUALLANGUAGE, STARTDATE, 
		DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE, MANAGERIDPOSITION,
		MANAGERINDIVIDUALGENDER,MANAGERINDIVIDUALNATIONALITY)
		SELECT 
		--TRY_CAST(JSON_VALUE(value, '$.ManagerRank') AS INT) AS ManagerRank,
		JSON_VALUE(value, '$.CRiSNO') AS CRiSNO,
		UPPER(JSON_VALUE(value, '$.MANAGERINDIVIDUALNAME')) AS MANAGERINDIVIDUALNAME,
		JSON_VALUE(value, '$.MANAGERINDIVIDUALPOSITION') AS MANAGERINDIVIDUALPOSITION,
		JSON_VALUE(value, '$.MANAGERINDIVIDUALLANGUAGE') AS MANAGERINDIVIDUALLANGUAGE,
		CONVERT(DATE, JSON_VALUE(value, '$.STARTDATE') ,103) AS STARTDATE,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEREPORTED') ,103) AS DATEREPORTED,
		CONVERT(DATE, JSON_VALUE(value, '$.DATEUPDATED') ,103) AS DATEUPDATED,
		JSON_VALUE(value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		JSON_VALUE(value, '$.MANAGERIDPOSITION') AS MANAGERIDPOSITION,
		JSON_VALUE(value, '$.MANAGERINDIVIDUALGENDER') AS MANAGERINDIVIDUALGENDER,
		JSON_VALUE(value, '$.MANAGERINDIVIDUALNATIONALITY') AS MANAGERINDIVIDUALNATIONALITY
		FROM OPENJSON(@json, '$.MANAGERSINDIVIDUALS.MANAGERSINDIVIDUAL');


		IF OBJECT_ID ('tempdb..#MANAGERSINDIVIDUALS_Main', 'U') IS NOT NULL
		DROP TABLE #MANAGERSINDIVIDUALS_Main;

		CREATE TABLE #MANAGERSINDIVIDUALS_Main (
		ID INT IDENTITY(1,1),
		CRiSNO NVARCHAR(50),
		MANAGERINDIVIDUALNAME NVARCHAR(255),
		MANAGERINDIVIDUALNAME_New NVARCHAR(255),
		MANAGERINDIVIDUALGENDER NVARCHAR(50),
		MANAGERINDIVIDUALNATIONALITY NVARCHAR(255),
		MANAGERINDIVIDUALLANGUAGE NVARCHAR(255),
		TITLE NVARCHAR(255),
		Idgender INT,
		IdNationality INT,
		IdTitle INT,
		IdLanguage INT,
		PersonIDATOM INT,
		[FirstNamePrefix] [nvarchar](250) NULL,
		[FirstName] [nvarchar](250) NULL,
		[MiddlePrefix1] [nvarchar](250) NULL,
		[MiddleName1] [nvarchar](250) NULL,
		[MiddlePrefix2] [nvarchar](250) NULL,
		[MiddleName2] [nvarchar](250) NULL,
		[MiddlePrefix3] [nvarchar](250) NULL,
		[MiddleName3] [nvarchar](250) NULL,
		[MiddlePrefix4] [nvarchar](250) NULL,
		[MiddleName4] [nvarchar](250) NULL,
		[MiddlePrefix5] [nvarchar](250) NULL,
		[MiddleName5] [nvarchar](250) NULL,
		[MiddlePrefix6] [nvarchar](250) NULL,
		[MiddleName6] [nvarchar](250) NULL,
		[LastNamePrefix] [nvarchar](250) NULL,
		[LastName] [nvarchar](250) NULL
		);

		INSERT INTO #MANAGERSINDIVIDUALS_Main (CRiSNO, MANAGERINDIVIDUALNAME, MANAGERINDIVIDUALGENDER, 
		MANAGERINDIVIDUALNATIONALITY,MANAGERINDIVIDUALLANGUAGE,TITLE)
		SELECT DISTINCT CRiSNO,
			MANAGERINDIVIDUALNAME, MANAGERINDIVIDUALGENDER, 
			MANAGERINDIVIDUALNATIONALITY ,MANAGERINDIVIDUALLANGUAGE,NULL--LEFT(MANAGERINDIVIDUALNAME,CHARINDEX(' ',MANAGERINDIVIDUALNAME))
		from #MANAGERSINDIVIDUALS
		
		
		--UPDATE #MANAGERSINDIVIDUALS_Main set MANAGERINDIVIDUALNAME_New = MANAGERINDIVIDUALNAME

		--JP AMENDED
		UPDATE #MANAGERSINDIVIDUALS_Main set MANAGERINDIVIDUALNAME_New = MANAGERINDIVIDUALNAME
		--SUBSTRING(MANAGERINDIVIDUALNAME,CHARINDEX(' ',MANAGERINDIVIDUALNAME)+1,LEN(MANAGERINDIVIDUALNAME))

		--------------------------------------------------MANAGERSCOMPANIES----------------------------------------------------

		IF OBJECT_ID ('tempdb..#MANAGERSCOMPANIES', 'U') IS NOT NULL
		DROP TABLE #MANAGERSCOMPANIES;

		CREATE TABLE #MANAGERSCOMPANIES
		(	ID INT IDENTITY(1,1),
			ManagerIDPosition        BIGINT,
			StartDate                DATE,
			DateReported             DATE,
			Address                  NVARCHAR(500),
			ManagerCompanyName       NVARCHAR(255),
			ManagerCompanyPosition   NVARCHAR(100),
			ManagerCompanyCountry    NVARCHAR(100),
			ManagerCompanyIdatom	 INT
		);

		INSERT INTO #MANAGERSCOMPANIES
		(
			ManagerIDPosition,
			StartDate,
			DateReported,
			Address,
			ManagerCompanyName,
			ManagerCompanyPosition,
			ManagerCompanyCountry
		)
		SELECT
			j.MANAGERIDPOSITION,
			CONVERT(date, j.STARTDATE, 112),
			CONVERT(date, j.DATEREPORTED, 103),
			j.ADDRESS,
			j.MANAGERCOMPANYNAME,
			j.MANAGERCOMPANYPOSITION,
			j.MANAGERCOMPANYCOUNTRY
		FROM OPENJSON(@json, '$.MANAGERSCOMPANIES.MANAGERSCOMPANY')
		WITH
		(
			MANAGERIDPOSITION        BIGINT        '$.MANAGERIDPOSITION',
			STARTDATE                CHAR(8)       '$.STARTDATE',
			DATEREPORTED             VARCHAR(10)   '$.DATEREPORTED',
			ADDRESS                  NVARCHAR(500) '$.ADDRESS',
			MANAGERCOMPANYNAME       NVARCHAR(255) '$.MANAGERCOMPANYNAME',
			MANAGERCOMPANYPOSITION   NVARCHAR(100) '$.MANAGERCOMPANYPOSITION',
			MANAGERCOMPANYCOUNTRY    NVARCHAR(100) '$.MANAGERCOMPANYCOUNTRY'
		) j;
		
		IF OBJECT_ID ('tempdb..#MANAGERSCOMPANIES_Distinct', 'U') IS NOT NULL
		DROP TABLE #MANAGERSCOMPANIES_Distinct;

		CREATE TABLE #MANAGERSCOMPANIES_Distinct
		(ID INT,
		CRiSNO NVARCHAR(50),
		MANAGERCOMPANYNAME NVARCHAR(255),
		MANAGERCOMPANYCOUNTRY NVARCHAR(100),
		ManagerCompanyIdatom INT,
		Idcountry INT
		);

		INSERT INTO #MANAGERSCOMPANIES_Distinct
		(ID,MANAGERCOMPANYNAME,MANAGERCOMPANYCOUNTRY)
		SELECT DISTINCT ID,MANAGERCOMPANYNAME,MANAGERCOMPANYCOUNTRY from #MANAGERSCOMPANIES

		--------------------------------------------------LEGALFORMINFO----------------------------------------------------

		IF OBJECT_ID ('tempdb..#LEGALFORMINFO', 'U') IS NOT NULL
		DROP TABLE #LEGALFORMINFO;

		CREATE TABLE #LEGALFORMINFO (
		LEGALFORM NVARCHAR(255),
		DATEREPORTED DATE,
		DATEUPDATED DATE,
		SOURCE CHAR(1),
		INTELLIGENCE INT,
		IdType INT,
		LegalFormStartDate DATE,
		LegalFormEndDate DATE,
		IsHistory BIT
		);

		INSERT INTO #LEGALFORMINFO (LEGALFORM, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE,IsHistory, LegalFormStartDate, LegalFormEndDate)
		SELECT 
		JSON_VALUE(@json, '$.LEGALFORMINFO.LEGALFORM') AS LEGALFORM,
		CONVERT(DATE,JSON_VALUE(@json, '$.LEGALFORMINFO.DATEREPORTED') ,103) AS DATEREPORTED,
		CONVERT(DATE,JSON_VALUE(@json, '$.LEGALFORMINFO.DATEUPDATED') ,103) AS DATEUPDATED,
		JSON_VALUE(@json, '$.LEGALFORMINFO.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(@json, '$.LEGALFORMINFO.INTELLIGENCE') AS INT) AS INTELLIGENCE,
		0 as IsHistory,NULL,NULL
		UNION ALL
		--INSERT INTO #LEGALFORMINFO (LEGALFORM, LegalFormStartDate, LegalFormEndDate,DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE,IsHistory)
		SELECT 
		JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.LEGALFORM') AS LegalForm,
		TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.DATEREPORTED'), 103) AS DateReported,
		TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.DATEUPDATED'), 103) AS DateUpdated,
		JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.SOURCE') AS Source,
		CAST(JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.INTELLIGENCE') AS INT) AS Intelligence,
		1 as IsHistory,
		TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.LEGALFORMSTARTDATE'), 113) AS LegalFormStartDate,
		TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALLEGALFORMINFO.LEGALFORMINFO.LEGALFORMENDDATE'), 113) AS LegalFormEndDate

		--select * from #LEGALFORMINFO
		DELETE FROM #LEGALFORMINFO WHERE ISNULL(LEGALFORM,'')=''

		--------------------------------------------------STATUS----------------------------------------------------

		IF OBJECT_ID ('tempdb..#STATUS', 'U') IS NOT NULL
		DROP TABLE #STATUS;

		CREATE TABLE #STATUS(
		CompanyStatus NVARCHAR(50),
		DateReported DATE,
		DateUpdated DATE,
		Source CHAR(1),
		Intelligence INT,
		idStatus INT);

		INSERT INTO #STATUS (CompanyStatus, DateReported, DateUpdated, Source, Intelligence)
		SELECT 
		JSON_VALUE(@json, '$.STATUS.COMPANYSTATUS'),
		CONVERT(DATE,JSON_VALUE(@json, '$.STATUS.DATEREPORTED'),103),
		CONVERT(DATE,JSON_VALUE(@json, '$.STATUS.DATEUPDATED'),103),
		JSON_VALUE(@json, '$.STATUS.SOURCE'),
		JSON_VALUE(@json, '$.STATUS.INTELLIGENCE');

		----select * from #STATUS

		--------------------------------------------------REGISTERS----------------------------------------------------

		IF OBJECT_ID ('tempdb..#REGISTERS', 'U') IS NOT NULL
		DROP TABLE #REGISTERS;

		CREATE TABLE #REGISTERS (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		NAME NVARCHAR(255) NULL,
		NATIVETRADEINGNAME NVARCHAR(255) NULL,
		REGISTERTYPEID INT,
		REGISTERTYPE NVARCHAR(255),
		REGISTERNAMEID INT,
		REGISTERNAME NVARCHAR(255),
		REGISTERMAINID INT,
		REGISTERMAIN NVARCHAR(255),
		REGISTERNUMBER NVARCHAR(255),
		REGISTERISSUEDATE DATE NULL,
		REGISTEREXPIRYDATE DATE NULL,
		REGISTERSTATUS NVARCHAR(50),
		DATEREPORTED DATE,
		DATEUPDATED DATETIME,
		SOURCE NVARCHAR(5),
		INTELLIGENCE INT,
		IdStatus INT
		)

		INSERT INTO #REGISTERS (
		NAME, NATIVETRADEINGNAME, REGISTERTYPEID, REGISTERTYPE, REGISTERNAMEID, 
		REGISTERNAME, REGISTERMAINID, REGISTERMAIN, REGISTERNUMBER, 
		REGISTERISSUEDATE, REGISTEREXPIRYDATE, REGISTERSTATUS, DATEREPORTED, 
		DATEUPDATED, SOURCE, INTELLIGENCE
		)
		SELECT 
		JSON_VALUE(j.value, '$.NAME'),
		JSON_VALUE(j.value, '$.NATIVETRADEINGNAME'),
		JSON_VALUE(j.value, '$.REGISTERTYPEID'),
		JSON_VALUE(j.value, '$.REGISTERTYPE'),
		JSON_VALUE(j.value, '$.REGISTERNAMEID'),
		JSON_VALUE(j.value, '$.REGISTERNAME'),
		JSON_VALUE(j.value, '$.REGISTERMAINID'),
		JSON_VALUE(j.value, '$.REGISTERMAIN'),
		JSON_VALUE(j.value, '$.REGISTERNUMBER'),
		CONVERT(DATE,JSON_VALUE(j.value, '$.REGISTERISSUEDATE'),103),
		CONVERT(DATE,JSON_VALUE(j.value, '$.REGISTEREXPIRYDATE') ,103),
		JSON_VALUE(j.value, '$.REGISTERSTATUS'),
		CONVERT(DATE,JSON_VALUE(j.value, '$.DATEREPORTED') ,103),
		CONVERT(DATE,JSON_VALUE(j.value, '$.DATEUPDATED') ,103),
		JSON_VALUE(j.value, '$.SOURCE'),
		JSON_VALUE(j.value, '$.INTELLIGENCE')
		FROM OPENJSON(@Json, '$.REGISTERS.REGISTER') AS j;

	

		--------------------------------------------------CAPITAL----------------------------------------------------

		IF OBJECT_ID ('tempdb..#CAPITAL', 'U') IS NOT NULL
		DROP TABLE #CAPITAL;

		CREATE TABLE #CAPITAL (
		CapitalAuthorised DECIMAL(18,2),
		CapitalIssued DECIMAL(18,2),
		CapitalPaidUp DECIMAL(18,2),
		NoOfShares DECIMAL(18,2),
		--ValueOfShare DECIMAL(18,2),
		Comment NVARCHAR(MAX),
		CapitalCurrency NVARCHAR(10),
		DateReported DATE,
		DateUpdated DATETIME,
		Source CHAR(1),
		Intelligence INT,
		IdCurrency INT null
		);

		INSERT INTO #CAPITAL (CapitalAuthorised, CapitalIssued, CapitalPaidUp, NoOfShares,
    --ValueOfShare,
    Comment, CapitalCurrency, DateReported, DateUpdated, Source, Intelligence)
		SELECT 
		JSON_VALUE(@Json, '$.CAPITAL.CAPITALAUTHORISED'),
		JSON_VALUE(@Json, '$.CAPITAL.CAPITALISSUED'),
		JSON_VALUE(@Json, '$.CAPITAL.CAPITALPAIDUP'),
		JSON_VALUE(@Json, '$.CAPITAL.NOOFSHARES'),
		--JSON_VALUE(@Json, '$.CAPITAL.VALUEOFSHARE'),
		JSON_VALUE(@Json, '$.CAPITAL.COMMENT'),
		JSON_VALUE(@Json, '$.CAPITAL.CAPITALCURRENCY'),
		CONVERT(DATE,JSON_VALUE(@Json, '$.CAPITAL.DATEREPORTED'),103),
		CONVERT(DATE,JSON_VALUE(@Json, '$.CAPITAL.DATEUPDATED'),103),
		JSON_VALUE(@Json, '$.CAPITAL.SOURCE'),
		JSON_VALUE(@Json, '$.CAPITAL.INTELLIGENCE');

		----select * from #CAPITAL

		--------------------------------------------------SHAREHOLDERSCOMPANIES----------------------------------------------------

		IF OBJECT_ID ('tempdb..#SHAREHOLDERSCOMPANIES', 'U') IS NOT NULL
		DROP TABLE #SHAREHOLDERSCOMPANIES;

		CREATE TABLE #SHAREHOLDERSCOMPANIES
		(ID INT IDENTITY(1,1) PRIMARY KEY,
		CRiSNO NVARCHAR(50),
		SHAREHOLDERSCOMPANYNAME NVARCHAR(255),
		STARTDATE DATE,
		SHAREHOLDERCOMPANYCOUNTRY NVARCHAR(100),
		SHARESNUMBER INT,
		SHAREHOLDERPERCENTAGE DECIMAL(28, 14),
		IsHistory BIT,
		DATEREPORTED DATE,
		DATEUPDATED DATETIME,
		SOURCE NVARCHAR(10),
		INTELLIGENCE INT,
		ShareHolderCompanyIdatom INT
		);

		INSERT INTO #SHAREHOLDERSCOMPANIES
		(
		CRiSNO,SHAREHOLDERSCOMPANYNAME,STARTDATE,SHAREHOLDERCOMPANYCOUNTRY,SHARESNUMBER,SHAREHOLDERPERCENTAGE,IsHistory,
		DATEREPORTED,DATEUPDATED,SOURCE,INTELLIGENCE)
		SELECT
		JSON_VALUE(Shareholder.value, '$.CRiSNO') AS CRiSNO,
		JSON_VALUE(Shareholder.value, '$.SHAREHOLDERSCOMPANYNAME') AS SHAREHOLDERSCOMPANYNAME,
		CONVERT(DATE, JSON_VALUE(Shareholder.value, '$.STARTDATE'), 112) AS STARTDATE,
		JSON_VALUE(Shareholder.value, '$.SHAREHOLDERCOMPANYCOUNTRY') AS SHAREHOLDERCOMPANYCOUNTRY,
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.SHARESNUMBER') AS INT) AS SHARESNUMBER,
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.SHAREHOLDERPERCENTAGE') AS DECIMAL(28,14)) AS SHAREHOLDERPERCENTAGE,
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.IsHistory') AS BIT) AS IsHistory,
		CONVERT(DATE, JSON_VALUE(Shareholder.value, '$.DATEREPORTED'), 103) AS DATEREPORTED,
		CONVERT(DATETIME, JSON_VALUE(Shareholder.value, '$.DATEUPDATED'), 103) AS DATEUPDATED,
		JSON_VALUE(Shareholder.value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE
		FROM OPENJSON(@Json, '$.SHAREHOLDERSCOMPANIES.SHAREHOLDERCOMPANY') AS Shareholder;

		IF OBJECT_ID ('tempdb..#SHAREHOLDERSCOMPANIES_Distinct', 'U') IS NOT NULL
		DROP TABLE #SHAREHOLDERSCOMPANIES_Distinct;

		CREATE TABLE #SHAREHOLDERSCOMPANIES_Distinct
		(ID INT,
		CRiSNO NVARCHAR(50),
		SHAREHOLDERSCOMPANYNAME NVARCHAR(255),
		SHAREHOLDERCOMPANYCOUNTRY NVARCHAR(100),
		ShareHolderCompanyIdatom INT,
		Idcountry INT
		);

		INSERT INTO #SHAREHOLDERSCOMPANIES_Distinct
		(ID,CRiSNO,SHAREHOLDERSCOMPANYNAME,SHAREHOLDERCOMPANYCOUNTRY)
		SELECT DISTINCT ID,CRiSNO,SHAREHOLDERSCOMPANYNAME,SHAREHOLDERCOMPANYCOUNTRY from #SHAREHOLDERSCOMPANIES

		CREATE INDEX IX_SHC_NameCountry ON #SHAREHOLDERSCOMPANIES_Distinct (SHAREHOLDERSCOMPANYNAME, IdCountry);
		CREATE INDEX IX_SHC_ID ON #SHAREHOLDERSCOMPANIES_Distinct (ID);

		--select * from #SHAREHOLDERSCOMPANIES
		--select * from #SHAREHOLDERSCOMPANIES_Distinct
		--return

		--------------------------------------------------SHAREHOLDERSINDIVIDUALS----------------------------------------------------

		IF OBJECT_ID ('tempdb..#SHAREHOLDERSINDIVIDUALS', 'U') IS NOT NULL
		DROP TABLE #SHAREHOLDERSINDIVIDUALS;

		CREATE TABLE #SHAREHOLDERSINDIVIDUALS (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		CRiSNO NVARCHAR(50),
		SHAREHOLDERINDIVIDUALNAME NVARCHAR(255),
		STARTDATE DATE,
		SHARESNUMBER INT,
		SHAREHOLDERPERCENTAGE DECIMAL(38,20),
		IsHistory BIT,
		DATEREPORTED DATE,
		DATEUPDATED DATE,
		SOURCE NVARCHAR(10),
		INTELLIGENCE INT,
		SHAREHOLDERINDIVIDUALNATIONALITY NVARCHAR(100),
		SHAREHOLDERCOMPANYCOUNTRY NVARCHAR(255),
		[ShareholderIdatom] INT,
		Idatom INT,
		--Idtitle INT,
		);
		INSERT INTO #SHAREHOLDERSINDIVIDUALS (CRiSNO, SHAREHOLDERINDIVIDUALNAME, STARTDATE, SHARESNUMBER, SHAREHOLDERPERCENTAGE, 
		IsHistory, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE, SHAREHOLDERINDIVIDUALNATIONALITY, SHAREHOLDERCOMPANYCOUNTRY)
		SELECT 
		JSON_VALUE(Shareholder.value, '$.CRiSNO'),
		UPPER(JSON_VALUE(Shareholder.value, '$.SHAREHOLDERINDIVIDUALNAME')),
		CONVERT(DATE, JSON_VALUE(Shareholder.value, '$.STARTDATE') ,103),
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.SHARESNUMBER') AS INT),
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.SHAREHOLDERPERCENTAGE') AS DECIMAL(38,20)),
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.IsHistory') AS BIT),
		CONVERT(DATE, JSON_VALUE(Shareholder.value, '$.DATEREPORTED'),103),
		CONVERT(DATE, JSON_VALUE(Shareholder.value, '$.DATEUPDATED'),103),
		JSON_VALUE(Shareholder.value, '$.SOURCE'),
		TRY_CAST(JSON_VALUE(Shareholder.value, '$.INTELLIGENCE') AS INT),
		JSON_VALUE(Shareholder.value, '$.SHAREHOLDERINDIVIDUALNATIONALITY'),
		JSON_VALUE(Shareholder.value, '$.SHAREHOLDERCOMPANYCOUNTRY')
		FROM OPENJSON(@Json, '$.SHAREHOLDERSINDIVIDUALS.SHAREHOLDERINDIVIDUAL') AS Shareholder;

		IF OBJECT_ID ('tempdb..#SHAREHOLDERSINDIVIDUALS_Distinct', 'U') IS NOT NULL
		DROP TABLE #SHAREHOLDERSINDIVIDUALS_Distinct;

		CREATE TABLE #SHAREHOLDERSINDIVIDUALS_Distinct (
		ID INT IDENTITY(1,1),
		SHAREHOLDERINDIVIDUALNAME NVARCHAR(255),
		CRiSNO NVARCHAR(255),
		SHAREHOLDERINDIVIDUALNAME_new NVARCHAR(255),
		SHAREHOLDERINDIVIDUALNATIONALITY NVARCHAR(100),
		SHAREHOLDERCOMPANYCOUNTRY NVARCHAR(255),
		[ShareholderIdatom] INT,
		Idatom INT,
		IdCountry INT,
		Idtitle INT,
		IdNationality INT,
		[FirstNamePrefix] [nvarchar](max) NULL,
		[FirstName] [nvarchar](max) NULL,
		[MiddlePrefix1] [nvarchar](max) NULL,
		[MiddleName1] [nvarchar](max) NULL,
		[MiddlePrefix2] [nvarchar](max) NULL,
		[MiddleName2] [nvarchar](max) NULL,
		[MiddlePrefix3] [nvarchar](max) NULL,
		[MiddleName3] [nvarchar](max) NULL,
		[MiddlePrefix4] [nvarchar](max) NULL,
		[MiddleName4] [nvarchar](max) NULL,
		[MiddlePrefix5] [nvarchar](max) NULL,
		[MiddleName5] [nvarchar](max) NULL,
		[MiddlePrefix6] [nvarchar](max) NULL,
		[MiddleName6] [nvarchar](max) NULL,
		[LastNamePrefix] [nvarchar](max) NULL,
		[LastName] [nvarchar](max) NULL
		);
		
		--alter table #SHAREHOLDERSINDIVIDUALS_Distinct add IdNationality INT
		INSERT INTO #SHAREHOLDERSINDIVIDUALS_Distinct (CRiSNO,SHAREHOLDERINDIVIDUALNAME,SHAREHOLDERINDIVIDUALNATIONALITY, SHAREHOLDERCOMPANYCOUNTRY)
		SELECT DISTINCT CRiSNO,SHAREHOLDERINDIVIDUALNAME,SHAREHOLDERINDIVIDUALNATIONALITY, SHAREHOLDERCOMPANYCOUNTRY
		from #SHAREHOLDERSINDIVIDUALS

		
		UPDATE #SHAREHOLDERSINDIVIDUALS_Distinct set SHAREHOLDERINDIVIDUALNAME_new = SHAREHOLDERINDIVIDUALNAME

		UPDATE #SHAREHOLDERSINDIVIDUALS_Distinct set SHAREHOLDERINDIVIDUALNAME_new = 
		SUBSTRING(SHAREHOLDERINDIVIDUALNAME,CHARINDEX('.',SHAREHOLDERINDIVIDUALNAME)+1,LEN(SHAREHOLDERINDIVIDUALNAME))
		where SHAREHOLDERINDIVIDUALNAME like '%.%'
	
		--------------------------------------------------Activities----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Activities', 'U') IS NOT NULL
		DROP TABLE #Activities;

		CREATE TABLE #Activities (
		ActivityID INT IDENTITY(1,1) PRIMARY KEY,
		IsPrimary BIT,
		IsHistory BIT,
		ActivityCode NVARCHAR(50) NULL,
		StartDate DATE,
		EndDate DATE NULL,
		DateReported DATE,
		DateUpdated DATE,
		Source NVARCHAR(5),
		Intelligence INT,
		IdDivisionUksic int null,
		IdGroupUksic int null,
		IdClassUksic int null,
		IdSubClassUksic int null
		);	
		INSERT INTO #Activities (IsPrimary, IsHistory, ActivityCode, StartDate, EndDate, DateReported, DateUpdated, Source, Intelligence)
		SELECT
		CAST(JSON_VALUE(A.value, '$.IsPrimary') AS BIT) AS IsPrimary,
		CAST(JSON_VALUE(A.value, '$.IsHistory') AS BIT) AS IsHistory,
		JSON_VALUE(A.value, '$.ACTIVITYCODE') AS ActivityCode,
		CONVERT(DATE,JSON_VALUE(A.value, '$.STARTDATE') ,103) AS StartDate,
		CONVERT(DATE,JSON_VALUE(A.value, '$.ENDDATE') ,103) AS EndDate,
		CONVERT(DATE,JSON_VALUE(A.value, '$.DATEREPORTED') ,103) AS DateReported,
		CONVERT(DATE,JSON_VALUE(A.value, '$.DATEUPDATED') ,103) AS DateUpdated,
		JSON_VALUE(A.value, '$.SOURCE') AS Source,
		CAST(JSON_VALUE(A.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@Json, '$.ACTIVITIES.ACTIVITY') AS A;

		delete from #Activities where ActivityCode is null
		---4077413 idstandard uksic
		
		--select top 10 * from tblCompanies2Activities where IdClassUksic is not null
		--select * from UKSIC2007_subclass
		--select * from #Activities
		--return

		--------------------------------------------------HistoricalActivities----------------------------------------------------

		IF OBJECT_ID ('tempdb..#HistoricalActivities', 'U') IS NOT NULL
		DROP TABLE #HistoricalActivities;

		CREATE TABLE #HistoricalActivities (
			ActivityStandard NVARCHAR(255),
			Activity NVARCHAR(500),
			StartDate DATE NULL,
			EndDate DATE NULL,
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			IdDivisionUksic int null,
			IdGroupUksic int null,
			IdClassUksic int null,
			IdSubClassUksic int null
			);

		INSERT INTO #HistoricalActivities (
			ActivityStandard, Activity, StartDate, EndDate, 
			DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.ACTIVITYSTANDARD') AS ActivityStandard,
			JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.ACTIVITY') AS Activity,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.STARTDATE'), 103) AS StartDate,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.ENDDATE'), 103) AS EndDate,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.SOURCE') AS Source,
			CAST(JSON_VALUE(@json, '$.HISTORICALACTIVITIES.HISTORICALACTIVITY.INTELLIGENCE') AS INT) AS Intelligence;

		--------------------------------------------------NUMBEROFEMPLOYEES----------------------------------------------------

		IF OBJECT_ID ('tempdb..#NUMBEROFEMPLOYEES', 'U') IS NOT NULL
		DROP TABLE #NUMBEROFEMPLOYEES;

		CREATE TABLE #NUMBEROFEMPLOYEES (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		Year INT,
		NumberFrom INT,
		Comment NVARCHAR(MAX),
		DateReported DATE,
		DateUpdated DATE,
		Source CHAR(1),
		Intelligence INT
		);

		INSERT INTO #NUMBEROFEMPLOYEES (Year, NumberFrom, Comment, DateReported, DateUpdated, Source, Intelligence)
		SELECT
		JSON_VALUE(Employee.value, '$.YEAR') AS Year,
		JSON_VALUE(Employee.value, '$.NUMBERFROM') AS NumberFrom,
		JSON_VALUE(Employee.value, '$.COMMENT') AS Comment,
		CONVERT(DATE,JSON_VALUE(Employee.value, '$.DATEREPORTED') ,103) AS DateReported,
		CONVERT(DATE,JSON_VALUE(Employee.value, '$.DATEUPDATED') ,103) AS DateUpdated,
		JSON_VALUE(Employee.value, '$.SOURCE') AS Source,
		CAST(JSON_VALUE(Employee.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@Json, '$.NUMBEROFEMPLOYEES.NUMBEROFEMPLOYEE') AS Employee;

		----select * from #NUMBEROFEMPLOYEES

		--------------------------------------------------HOLDINGS----------------------------------------------------

		IF OBJECT_ID ('tempdb..#HOLDINGS', 'U') IS NOT NULL
		DROP TABLE #HOLDINGS;

		CREATE TABLE #HOLDINGS (
		ID INT IDENTITY(1,1),
		CRiSNBR NVARCHAR(50),
		NAME NVARCHAR(255),
		ADDRESS NVARCHAR(255),
		PERCENTAGE DECIMAL(10,3),
		SHARES INT NULL,
		IsFormer BIT,
		DATEREPORTED DATE,
		DATEUPDATED DATE,
		SOURCE NVARCHAR(10),
		INTELLIGENCE INT,
		HoldingsIdatom INT,
		IdCountry INT
		);

		INSERT INTO #HOLDINGS (CRiSNBR, NAME, ADDRESS, PERCENTAGE, SHARES, IsFormer, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE)
		SELECT 
		JSON_VALUE(H.value, '$.CRiSNBR') AS CRiSNBR,
		JSON_VALUE(H.value, '$.NAME') AS NAME,
		JSON_VALUE(H.value, '$.ADDRESS') AS ADDRESS,
		TRY_CAST(JSON_VALUE(H.value, '$.PERCENTAGE') AS DECIMAL(10,3)) AS PERCENTAGE,
		TRY_CAST(JSON_VALUE(H.value, '$.SHARES') AS INT) AS SHARES,
		TRY_CAST(JSON_VALUE(H.value, '$.IsFormer') AS BIT) AS IsFormer,
		CONVERT(DATE,JSON_VALUE(H.value, '$.DATEREPORTED') ,103) AS DATEREPORTED,
		CONVERT(DATE,JSON_VALUE(H.value, '$.DATEUPDATED') ,103) AS DATEUPDATED,
		JSON_VALUE(H.value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(H.value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE
		FROM OPENJSON(@Json, '$.HOLDINGS.HOLDING') AS H;

		IF OBJECT_ID ('tempdb..#HOLDINGS_Distinct', 'U') IS NOT NULL
		DROP TABLE #HOLDINGS_Distinct;

		CREATE TABLE #HOLDINGS_Distinct (
		ID INT,
		CRiSNBR NVARCHAR(50),
		NAME NVARCHAR(255),
		ADDRESS NVARCHAR(255),
		HoldingsIdatom INT,
		idcountry INT
		);

		INSERT INTO #HOLDINGS_Distinct (ID, CRiSNBR, NAME, ADDRESS)
		SELECT DISTINCT ID, CRiSNBR, NAME,ADDRESS from #HOLDINGS

		----select * from #HOLDINGS

		--------------------------------------------------DIRECTORSHIPS----------------------------------------------------

		IF OBJECT_ID ('tempdb..#DIRECTORSHIPS', 'U') IS NOT NULL
		DROP TABLE #DIRECTORSHIPS;

		CREATE TABLE #DIRECTORSHIPS (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		CRiSNO NVARCHAR(50),
		Name NVARCHAR(255),
		NameLocal NVARCHAR(255) NULL,
		IsFormer BIT,
		Position NVARCHAR(100),
		OrganisationName NVARCHAR(100),
		RegisterName NVARCHAR(255) NULL,
		RegisterNumber NVARCHAR(100) NULL,
		Address NVARCHAR(255),
		CompanyStatus NVARCHAR(50),
		DATEREPORTED DATE,
		DATEUPDATED DATE,
		SOURCE NVARCHAR(10),
		INTELLIGENCE INT,
		DirectorIdatom INT,
		Idregister INT,
		IDStatus INT,
		Idcountry INT,
		IdPosition INT,
		idOrganisation INT
		);

		INSERT INTO #DIRECTORSHIPS (CRiSNO, Name, NameLocal, IsFormer, Position,OrganisationName, RegisterName, RegisterNumber, 
		Address, CompanyStatus, DATEREPORTED, DATEUPDATED, SOURCE, INTELLIGENCE)
		SELECT 
		JSON_VALUE(director.value, '$.CRiSNO') AS CRiSNO,
		JSON_VALUE(director.value, '$.Name') AS Name,
		JSON_VALUE(director.value, '$.NameLocal') AS NameLocal,
		CAST(JSON_VALUE(director.value, '$.IsFormer') AS BIT) AS IsFormer,
		JSON_VALUE(director.value, '$.Position') AS Position,
		JSON_VALUE(director.value, '$.OrganisationName') AS OrganisationName,
		JSON_VALUE(director.value, '$.RegisterName') AS RegisterName,
		JSON_VALUE(director.value, '$.RegisterNumber') AS RegisterNumber,
		JSON_VALUE(director.value, '$.Address') AS Address,
		JSON_VALUE(director.value, '$.CompanyStatus') AS CompanyStatus,
		CONVERT(DATE,JSON_VALUE(director.value, '$.DATEREPORTED') ,103) AS DATEREPORTED,
		CONVERT(DATE,JSON_VALUE(director.value, '$.DATEUPDATED') ,103) AS DATEUPDATED,
		JSON_VALUE(director.value, '$.SOURCE') AS SOURCE,
		TRY_CAST(JSON_VALUE(director.value, '$.INTELLIGENCE') AS INT) AS INTELLIGENCE
		FROM OPENJSON(@Json, '$.DIRECTORSHIPS.DIRECTORSHIP') AS director;

		IF OBJECT_ID ('tempdb..#DIRECTORSHIPS_Distinct', 'U') IS NOT NULL
		DROP TABLE #DIRECTORSHIPS_Distinct;

		CREATE TABLE #DIRECTORSHIPS_Distinct (
		ID INT IDENTITY(1,1),
		CRiSNO NVARCHAR(50),
		Name NVARCHAR(255),
		NameLocal NVARCHAR(255) NULL,
		Address NVARCHAR(255),
		DirectorIdatom INT,
		Idcountry INT
		);

		INSERT INTO #DIRECTORSHIPS_Distinct ( CRiSNO,Name, NameLocal, Address)
		SELECT DISTINCT CRiSNO, Name, NameLocal, Address from #DIRECTORSHIPS

		----select * from #DIRECTORSHIPS

		--------------------------------------------------Premises----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Premises', 'U') IS NOT NULL
		DROP TABLE #Premises;

		CREATE TABLE #Premises (
		ID INT IDENTITY(1,1) PRIMARY KEY,
		Type NVARCHAR(255),
		Ownership NVARCHAR(100),
		Number INT,
		Size NVARCHAR(100),
		DateReported DATE,
		DateUpdated DATE,
		Source NVARCHAR(10),
		Intelligence INT,
		idpremisetype INT,
		[IdStatus] INT,
		IdType INT,
		[IdCountry] INT,
		[IdSizeMeasure] INT
		);

		INSERT INTO #Premises (Type, Ownership, Number, Size, DateReported, DateUpdated, Source, Intelligence)
		SELECT 
		JSON_VALUE(premise.value, '$.TYPE') AS Type,
		JSON_VALUE(premise.value, '$.OWNERSHIP') AS Ownership,
		TRY_CAST(JSON_VALUE(premise.value, '$.NUMBER') AS INT) AS Number,
		JSON_VALUE(premise.value, '$.SIZE') AS Size,
		CONVERT(DATE,JSON_VALUE(premise.value, '$.DATEREPORTED') ,103) AS DateReported,
		CONVERT(DATE,JSON_VALUE(premise.value, '$.DATEUPDATED') ,103) AS DateUpdated,
		JSON_VALUE(premise.value, '$.SOURCE') AS Source,
		TRY_CAST(JSON_VALUE(premise.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@Json, '$.PREMISES.PREMISE') AS premise;


		--------------------------------------------------Financials----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Financials', 'U') IS NOT NULL
		DROP TABLE #Financials;

		CREATE TABLE #Financials (
		FinancialDate DATE,
		FinancialDate_new DATE,
		MONTHSNO INT,
		Denomination NVARCHAR(50),
		[YEAR] INT,
		[Type] NVARCHAR(50),
		[Audit] NVARCHAR(50),
		[Name] NVARCHAR(255),
		StatementType NVARCHAR(50),
		FinancialValue DECIMAL(18,3),
		FinancialCurrency VARCHAR(50),
		IdCurrency INT,
		IdField INT,
        IsConsolidated INT			--Added by Vivek on 24-10-2025
		);

		-- Insert JSON data into the table variable
		INSERT INTO #Financials (
			FinancialDate,
			MONTHSNO,
			Denomination,
			[YEAR],
			[Type],
			[Audit],
			[Name],
			StatementType,
			FinancialValue,
			FinancialCurrency
		)
		SELECT
			CAST(f.FinancialDateRaw AS DATE) AS FinancialDate,
			CAST(f.MONTHSNO AS INT) AS MONTHSNO,
			f.Denomination AS Denomination,
			CAST(f.[YEAR] AS INT) AS [YEAR],
			f.[Type] AS [Type],
			f.[Audit] AS [Audit],
			f.[Name] AS [Name],
			f.StatementType AS StatementType,
			CAST(f.FinancialValueRaw AS DECIMAL(18,3)) AS FinancialValue,
			f.FinancialCurrency AS FinancialCurrency
		FROM OPENJSON(@Json, '$.FINANCIALS.FINANCIAL')
		WITH (
			FinancialDateRaw NVARCHAR(20) '$.FINANCIALDATE',
			MONTHSNO NVARCHAR(20) '$.MONTHSNO',
			Denomination NVARCHAR(50) '$.Denomination',
			[YEAR] NVARCHAR(10) '$.YEAR',
			[Type] NVARCHAR(50) '$.TYPE',
			[Audit] NVARCHAR(50) '$.AUDIT',
			[Name] NVARCHAR(255) '$.NAME',
			StatementType NVARCHAR(50) '$.STATEMENTTYPE',
			FinancialValueRaw NVARCHAR(50) '$.FINANCIALVALUE',
			FinancialCurrency VARCHAR(50) '$.FINANCIALCURRENCY'
		) f;

		--ALTER TABLE #Financials ADD FinancialDate_new DATE

		UPDATE #Financials set FinancialDate_new = LEFT(FinancialDate,4)+'-'+LEFT(RIGHT(FinancialDate,5),2)+'-'+RIGHT(RIGHT(FinancialDate,5),2)

		UPDATE #Financials set IsConsolidated = CASE WHEN [Type]='Consolidated' THEN 1 WHEN [Type]='Standalone' THEN 0 END

		--------------------------------------------------#HistoricalManagements----------------------------------------------------

		IF OBJECT_ID ('tempdb..#HistoricalManagements', 'U') IS NOT NULL
		DROP TABLE #HistoricalManagements;

		CREATE TABLE #HistoricalManagements (
			ID INT IDENTITY(1,1) PRIMARY KEY,
			ManagerType NVARCHAR(50),
			ManagerRank INT,
			FullName NVARCHAR(255) NULL,
			FullNameArabic NVARCHAR(255) NULL,
			Position NVARCHAR(255) NULL,
			COUNTRY NVARCHAR(255) NULL,
			StartDate DATE NULL,
			EndDate DATE NULL,
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			ManagerIdPosition BIGINT NULL,
			PersonIDATOM INT
		);

		INSERT INTO #HistoricalManagements (
			ManagerType, ManagerRank, FullName, FullNameArabic, Position, COUNTRY,
			StartDate, EndDate, DateReported, DateUpdated, Source, 
			Intelligence, ManagerIdPosition
		)
		SELECT 
			JSON_VALUE(h.value, '$.MANAGERTYPE') AS ManagerType,
			CAST(JSON_VALUE(h.value, '$.MANAGERRANK') AS INT) AS ManagerRank,
			UPPER(JSON_VALUE(h.value, '$.FULLNAME')) AS FullName,
			JSON_VALUE(h.value, '$.FULLNAMEARABIC') AS FullNameArabic,
			JSON_VALUE(h.value, '$.POSITION') AS Position,
			JSON_VALUE(h.value, '$.COUNTRY') AS COUNTRY,
			TRY_CONVERT(DATE, JSON_VALUE(h.value, '$.STARTDATE'), 103) AS StartDate,
			TRY_CONVERT(DATE, JSON_VALUE(h.value, '$.ENDDATE'), 103) AS EndDate,
			TRY_CONVERT(DATE, JSON_VALUE(h.value, '$.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(h.value, '$.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(h.value, '$.SOURCE') AS Source,
			CAST(JSON_VALUE(h.value, '$.INTELLIGENCE') AS INT) AS Intelligence,
			CAST(JSON_VALUE(h.value, '$.MANAGERIDPOSITION') AS BIGINT) AS ManagerIdPosition
		FROM OPENJSON(@json, '$.HISTORICALMANAGEMENTS.HISTORICALMANAGEMENT') AS h;

		DELETE from #HistoricalManagements where ISNULL(FullName,'')='' and ISNULL(FullNameArabic,'')=''

		IF OBJECT_ID ('tempdb..#HistoricalManagements_Main', 'U') IS NOT NULL
		DROP TABLE #HistoricalManagements_Main;

		CREATE TABLE #HistoricalManagements_Main (
		ID INT,
		ManagerType NVARCHAR(50),
		ManagerRank INT,
		FullName NVARCHAR(255) NULL,
		FullName_New NVARCHAR(255) NULL,
		FullNameArabic NVARCHAR(255) NULL,
		Position NVARCHAR(255) NULL,
		COUNTRY NVARCHAR(255) NULL,
		PersonIDATOM INT,
		--TITLE NVARCHAR(100),
		--idtitle INT,
		idcountry INT,
		Companyidatom INT,
		[FirstNamePrefix] [nvarchar](250) NULL,
		[FirstName] [nvarchar](250) NULL,
		[MiddlePrefix1] [nvarchar](250) NULL,
		[MiddleName1] [nvarchar](250) NULL,
		[MiddlePrefix2] [nvarchar](250) NULL,
		[MiddleName2] [nvarchar](250) NULL,
		[MiddlePrefix3] [nvarchar](250) NULL,
		[MiddleName3] [nvarchar](250) NULL,
		[MiddlePrefix4] [nvarchar](250) NULL,
		[MiddleName4] [nvarchar](250) NULL,
		[MiddlePrefix5] [nvarchar](250) NULL,
		[MiddleName5] [nvarchar](250) NULL,
		[MiddlePrefix6] [nvarchar](250) NULL,
		[MiddleName6] [nvarchar](250) NULL,
		[LastNamePrefix] [nvarchar](250) NULL,
		[LastName] [nvarchar](250) NULL
		);

		INSERT INTO #HistoricalManagements_Main (ID, FullName, FullNameArabic, Position,ManagerType,COUNTRY
		)
		SELECT DISTINCT ID,FullName, FullNameArabic, 
			Position,ManagerType,COUNTRY
		from #HistoricalManagements
		
		
		--UPDATE #MANAGERSINDIVIDUALS_Main set MANAGERINDIVIDUALNAME_New = MANAGERINDIVIDUALNAME

		--JP AMENDED
		UPDATE #HistoricalManagements_Main set FullName_New = FullName
		--SUBSTRING(FullName,CHARINDEX(' ',FullName)+1,LEN(FullName))
		
		--------------------------------------------------#CompanyHistory----------------------------------------------------

		IF OBJECT_ID ('tempdb..#CompanyHistory', 'U') IS NOT NULL
		DROP TABLE #CompanyHistory;

		CREATE TABLE #CompanyHistory (
			ID INT IDENTITY(1,1) PRIMARY KEY,
			History NVARCHAR(MAX)
		);

		INSERT INTO #CompanyHistory (History)
		SELECT History
		FROM OPENJSON(@json)
		WITH (
			History NVARCHAR(MAX) '$.HISTORY'
		);

		--------------------------------------------------#Affiliates----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Affiliates', 'U') IS NOT NULL
		DROP TABLE #Affiliates;

		CREATE TABLE #Affiliates (
			CRiSNO NVARCHAR(50),
			[Name] NVARCHAR(255),
			Country NVARCHAR(100),
			AffiliatesStatus NVARCHAR(50) NULL,
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL
		);

		INSERT INTO #Affiliates (
			CRiSNO, [Name], Country, AffiliatesStatus, 
			DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(a.value, '$.CRiSNO') AS CRiSNO,
			JSON_VALUE(a.value, '$.NAME') AS [Name],
			JSON_VALUE(a.value, '$.COUNTRY') AS Country,
			JSON_VALUE(a.value, '$.AFFILIATESSTATUS') AS AffiliatesStatus,
			TRY_CONVERT(DATE, JSON_VALUE(a.value, '$.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(a.value, '$.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(a.value, '$.SOURCE') AS Source,
			CAST(JSON_VALUE(a.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@json, '$.AFFILIATES.AFFILIATE') AS a;

		--------------------------------------------------Brands----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Brands', 'U') IS NOT NULL
		DROP TABLE #Brands;

		CREATE TABLE #Brands (
			BrandName NVARCHAR(255),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL
		);

		INSERT INTO #Brands (
			BrandName, DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(@json, '$.BRANDS.BRANDNAME') AS BrandName,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.BRANDS.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.BRANDS.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(@json, '$.BRANDS.SOURCE') AS Source,
			CAST(JSON_VALUE(@json, '$.BRANDS.INTELLIGENCE') AS INT) AS Intelligence;

		--------------------------------------------------ProductionCapacity----------------------------------------------------

		
		IF OBJECT_ID ('tempdb..#ProductionCapacity', 'U') IS NOT NULL
		DROP TABLE #ProductionCapacity;

		CREATE TABLE #ProductionCapacity (
			ProductionYear INT,
			ProdCapacityInstalled NVARCHAR(255),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			IdUnitsType INT NULL,
			ProdCapacityInstalled_New DECIMAL(20,4)
		);

		INSERT INTO #ProductionCapacity (
			ProductionYear, ProdCapacityInstalled, DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			CAST(JSON_VALUE(@json, '$.PRODUCTIONCAPACITY.PRODCAPACITY.PRODUCTIONYYEAR') AS INT) AS ProductionYear,
			JSON_VALUE(@json, '$.PRODUCTIONCAPACITY.PRODCAPACITY.PRODCAPACITYINSTALLED') AS ProdCapacityInstalled,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.PRODUCTIONCAPACITY.PRODCAPACITY.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.PRODUCTIONCAPACITY.PRODCAPACITY.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(@json, '$.PRODUCTIONCAPACITY.PRODCAPACITY.SOURCE') AS Source,
			CAST(JSON_VALUE(@json, '$.PRODUCTIONCAPACITY.PRODCAPACITY.INTELLIGENCE') AS INT) AS Intelligence;

		UPDATE #ProductionCapacity set ProdCapacityInstalled_New = LEFT(ProdCapacityInstalled,CHARINDEX(' ',ProdCapacityInstalled))

		--------------------------------------------------AnnualImportsExports----------------------------------------------------
		
		IF OBJECT_ID ('tempdb..#AnnualImportsExports', 'U') IS NOT NULL
		DROP TABLE #AnnualImportsExports;

		CREATE TABLE #AnnualImportsExports (
			Year INT,
			ImportValue DECIMAL(18,4) NULL,
			ExportValue DECIMAL(18,4) NULL,
			Currency NVARCHAR(10),
			Comment NVARCHAR(500) NULL,
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			Idcurrency INT NULL
		);

		INSERT INTO #AnnualImportsExports (
			Year, ImportValue, ExportValue, Currency, Comment, 
			DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			CAST(JSON_VALUE(A.value, '$.YEAR') AS INT) AS Year,
			TRY_CAST(JSON_VALUE(A.value, '$.IMPORTVALUE') AS DECIMAL(18,4)) AS ImportValue,
			TRY_CAST(JSON_VALUE(A.value, '$.EXPORTVALUE') AS DECIMAL(18,4)) AS ExportValue,
			JSON_VALUE(A.value, '$.CURRENCY') AS Currency,
			JSON_VALUE(A.value, '$.Comment') AS Comment,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(A.value, '$.SOURCE') AS Source,
			CAST(JSON_VALUE(A.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@json, '$.ANNUALIMPORTSEXPORTS.ANNUALIMPORTEXPORT') AS A;
		
		--------------------------------------------------ImportFrom----------------------------------------------------

		IF OBJECT_ID ('tempdb..#ImportFrom', 'U') IS NOT NULL
		DROP TABLE #ImportFrom;

		CREATE TABLE #ImportFrom (
			Country NVARCHAR(255),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			IdCountry INT
		);

		INSERT INTO #ImportFrom (
			Country, DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(A.value, '$.COUNTRY') AS Country,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(A.value, '$.SOURCE') AS Source,
			CAST(JSON_VALUE(A.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@json, '$.IMPORTFROM.IMPORT') AS A;
		
		--------------------------------------------------ClientsInclude----------------------------------------------------
		
		IF OBJECT_ID ('tempdb..#ClientsInclude', 'U') IS NOT NULL
		DROP TABLE #ClientsInclude;

		CREATE TABLE #ClientsInclude (
			RelatedName NVARCHAR(255),
			Country NVARCHAR(100),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			idrelated INT NULL,
			IdCountry INT NULL
		);

		INSERT INTO #ClientsInclude (
			RelatedName, Country, DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(A.value, '$.RELATEDNAME') AS RelatedName,
			JSON_VALUE(A.value, '$.COUNTRY') AS Country,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(A.value, '$.SOURCE') AS Source,
			CAST(JSON_VALUE(A.value, '$.INTELLIGENCE') AS INT) AS Intelligence
		FROM OPENJSON(@json, '$.CLIENTSINCLUDE.CLIENT') AS A;
		
		--------------------------------------------------AgentsFor----------------------------------------------------

		IF OBJECT_ID ('tempdb..#AgentsFor', 'U') IS NOT NULL
		DROP TABLE #AgentsFor;

		CREATE TABLE #AgentsFor (
			Name NVARCHAR(255),
			Country NVARCHAR(100),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			idrelated INT NULL,
			IdCountry INT NULL
		);

		INSERT INTO #AgentsFor (
			Name, Country, DateReported, DateUpdated
		)
		SELECT 
			JSON_VALUE(@json, '$.AGENTSFOR.AGENT.NAME') AS Name,
			JSON_VALUE(@json, '$.AGENTSFOR.AGENT.COUNTRY') AS Country,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.AGENTSFOR.AGENT.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.AGENTSFOR.AGENT.DATEUPDATED'), 103) AS DateUpdated;
			
		--------------------------------------------------MethodOfPayment----------------------------------------------------

		IF OBJECT_ID ('tempdb..#MethodOfPayment', 'U') IS NOT NULL
		DROP TABLE #MethodOfPayment;

		CREATE TABLE #MethodOfPayment (
			PayMethod NVARCHAR(255),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			Comment NVARCHAR(MAX) NULL,
			IdPayMethod INT
		);

		INSERT INTO #MethodOfPayment (
			PayMethod, DateReported, DateUpdated, Source, Intelligence, Comment
		)
		SELECT 
			JSON_VALUE(A.value, '$.PAYMETHOD') AS PayMethod,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(A.value, '$.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(A.value, '$.SOURCE') AS Source,
			CAST(JSON_VALUE(A.value, '$.INTELLIGENCE') AS INT) AS Intelligence,
			JSON_VALUE(A.value, '$.COMMENT') AS Comment
		FROM OPENJSON(@json, '$.METHODOFPAYMENT.MOP') AS A;
		
		--------------------------------------------------Certifications----------------------------------------------------

		IF OBJECT_ID ('tempdb..#Certifications', 'U') IS NOT NULL
		DROP TABLE #Certifications;

		CREATE TABLE #Certifications (
			CertificationName NVARCHAR(255),
			Comment NVARCHAR(MAX) NULL,
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10) NULL,
			Intelligence INT NULL,
			IdCertificateType INT
		);

		INSERT INTO #Certifications (
			CertificationName, Comment, DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(@json, '$.CERTIFICATIONS.CERTIFICATION.CERTIFICATIONNAME') AS CertificationName,
			JSON_VALUE(@json, '$.CERTIFICATIONS.CERTIFICATION.Comment') AS Comment,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.CERTIFICATIONS.CERTIFICATION.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.CERTIFICATIONS.CERTIFICATION.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(@json, '$.CERTIFICATIONS.CERTIFICATION.SOURCE') AS Source,
			CAST(JSON_VALUE(@json, '$.CERTIFICATIONS.CERTIFICATION.INTELLIGENCE') AS INT) AS Intelligence;
			
		--------------------------------------------------ShareholdingAndInvestment----------------------------------------------------

		IF OBJECT_ID ('tempdb..#ShareholdingAndInvestment', 'U') IS NOT NULL
		DROP TABLE #ShareholdingAndInvestment;

		CREATE TABLE #ShareholdingAndInvestment (
			Name NVARCHAR(255),
			NameLocal NVARCHAR(255),
			CRiSNO NVARCHAR(50),
			IsFormer BIT,
			Address NVARCHAR(255),
			RegisterName NVARCHAR(255),
			RegisterNumber NVARCHAR(50),
			CompanyStatus NVARCHAR(50),
			DateReported DATE NULL,
			DateUpdated DATE NULL,
			Source NVARCHAR(10),
			Intelligence INT
		);

		INSERT INTO #ShareholdingAndInvestment (
			Name, NameLocal, CRiSNO, IsFormer, Address, RegisterName, RegisterNumber, 
			CompanyStatus, DateReported, DateUpdated, Source, Intelligence
		)
		SELECT 
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.Name') AS Name,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.NameLocal') AS NameLocal,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.CRiSNO') AS CRiSNO,
			CAST(JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.IsFormer') AS BIT) AS IsFormer,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.Address') AS Address,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.RegisterName') AS RegisterName,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.RegisterNumber') AS RegisterNumber,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.CompanyStatus') AS CompanyStatus,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.DATEREPORTED'), 103) AS DateReported,
			TRY_CONVERT(DATE, JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.DATEUPDATED'), 103) AS DateUpdated,
			JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.SOURCE') AS Source,
			CAST(JSON_VALUE(@json, '$.SHAREHOLDINGANDINVESTMENTINOTHERCOMPANIES.SHAREHOLDING.INTELLIGENCE') AS INT) AS Intelligence;
			
		--------------------------------------------------PHASE2 FinancialComparison----------------------------------------------------

		--IF OBJECT_ID ('tempdb..#FinancialComparison', 'U') IS NOT NULL
		--DROP TABLE #FinancialComparison;

		--CREATE TABLE #FinancialComparison (
		--	ID INT Identity(1,1),
		--	Year INT,
		--	FinancialMetric NVARCHAR(255),
		--	FinancialValue DECIMAL(18,2)
		--);

		--INSERT INTO #FinancialComparison (Year, FinancialMetric, FinancialValue)
		--SELECT 
		--	YEAR_DATA.[Year],
		--	FinancialData.FinancialMetric,
		--	FinancialData.FinancialValue
		--FROM OPENJSON(@json, '$.FINANCIALCOMPARISON.FINANCIALYEAR') 
		--WITH (
		--	[Year] INT '$.YEAR',
		--	FinancialValues NVARCHAR(MAX) '$.FINANCIALVALUES' AS JSON
		--) AS YEAR_DATA
		--CROSS APPLY OPENJSON(YEAR_DATA.FinancialValues, '$.FINANCIALVALUE')
		--WITH (
		--	FinancialMetric NVARCHAR(255) '$.NAME',
		--	FinancialValue DECIMAL(18,2) '$.FINANCIALVLAUE'
		--) AS FinancialData;

		----------------------------------------------------TradeReferences----------------------------------------------------
		
		IF OBJECT_ID ('tempdb..#TradeReferences', 'U') IS NOT NULL
		DROP TABLE #TradeReferences;

		CREATE TABLE #TradeReferences (
			ID INT IDENTITY(1,1),
			TradeSupplier NVARCHAR(255),
			Payments NVARCHAR(500),
			RelationshipDate NVARCHAR(50),
			TermsOfPayments NVARCHAR(255) NULL,
			MaxCreditLimit NVARCHAR(50) NULL,
			MaxCreditLimitCurrency NVARCHAR(10) NULL,
			AverageOrderAmount NVARCHAR(50) NULL,
			AverageOrderCurrency NVARCHAR(10) NULL,
			BusinessTrend NVARCHAR(50) NULL,
			Comment NVARCHAR(MAX) NULL,
			DateReported DATE,
			DateUpdated DATE,
			Source NVARCHAR(10),
			Intelligence INT,
			PaymentId INT,
			TermsOfPaymentsID INT,
			BusinessTrendId  INT,
			MaxCrLim INT,
			AvgCrLim INT,
			MaxCreditLimitCurrencyID INT,
			AverageOrderCurrencyID INT
		);

		INSERT INTO #TradeReferences (
			TradeSupplier, Payments, RelationshipDate, TermsOfPayments, 
			MaxCreditLimit, MaxCreditLimitCurrency, 
			AverageOrderAmount, AverageOrderCurrency, BusinessTrend, 
			Comment, DateReported, DateUpdated, Source, Intelligence
		)
		
		SELECT DISTINCT
		JSON_VALUE(trade.value, '$.TradeSupplier') AS [TradeSupplier],
		JSON_VALUE(trade.value, '$.Payments') AS [Payments],
		JSON_VALUE(trade.value, '$.RelationshipDate') AS [RelationshipDate],
		JSON_VALUE(trade.value, '$.TermsOfpayments') AS [TermsOfpayments],
		JSON_VALUE(trade.value, '$.MaxCreditLimit') AS [MaxCreditLimit],
		JSON_VALUE(trade.value, '$.MaxCreditLimitCurrency') AS [MaxCreditLimitCurrency],
		JSON_VALUE(trade.value, '$.AverageOrderAmount') AS [AverageOrderAmount],
		JSON_VALUE(trade.value, '$.AverageOrderCurrency') AS [AverageOrderCurrency],
		JSON_VALUE(trade.value, '$.BusinessTrend') AS [BusinessTrend],
		JSON_VALUE(trade.value, '$.Comment') AS [Comment],
		CONVERT(DATE,JSON_VALUE(trade.value, '$.DATEREPORTED'),103) AS [DATEREPORTED],
		CONVERT(DATE,JSON_VALUE(trade.value, '$.DATEUPDATED'),103) AS [DATEUPDATED],
		JSON_VALUE(trade.value, '$.SOURCE') AS [SOURCE],
		JSON_VALUE(trade.value, '$.INTELLIGENCE') AS [INTELLIGENCE]
		FROM OPENJSON(@Json, '$.TRADEREFERENCES.TRADEREFERENCE') AS trade
		
		
		----------------------------------------------------DEBTCOLLECTIONAGENCIESSEARCH----------------------------------------------------
		IF OBJECT_ID ('tempdb..#DEBTCOLLECTIONAGENCIESSEARCH', 'U') IS NOT NULL
		DROP TABLE #DEBTCOLLECTIONAGENCIESSEARCH;

		CREATE TABLE #DebtCollectionAgenciesSearch (
			DebtAgencies NVARCHAR(255),
			DebtCollection NVARCHAR(MAX),
			DateUpdated DATE,
			Source NVARCHAR(10),
			Intelligence INT,
			IdDebtAgencies INT
		)

		INSERT INTO #DEBTCOLLECTIONAGENCIESSEARCH (
			DebtAgencies, DebtCollection, DateUpdated, Source, Intelligence
		)
		SELECT 
			DebtAgencies, DebtCollection, DateUpdated, Source, Intelligence
		FROM OPENJSON(@json, '$.DEBTCOLLECTIONAGENCIESSEARCH')
		WITH (
			DebtAgencies NVARCHAR(255) '$.DEBTAGENCIES',
			DebtCollection NVARCHAR(MAX) '$.DEBTCOLLECTION',
			DateUpdated DATE '$.DATEUPDATED',
			Source NVARCHAR(10) '$.SOURCE',
			Intelligence INT '$.INTELLIGENCE'
		)

		
		--------------------------------------------------AdditionalFinancials----------------------------------------------------
		
		IF OBJECT_ID ('tempdb..#FinancialAnalyses', 'U') IS NOT NULL
		DROP TABLE #FinancialAnalyses;

		CREATE TABLE #FinancialAnalyses (
			FinancialDate DATE,
			FinancialDate_new DATE,
			MONTHSNO INT,
			Denomination NVARCHAR(50),
			[YEAR] INT,
			[Type] NVARCHAR(50),
			[Audit] NVARCHAR(50),
			StatementType NVARCHAR(50),
			Currency NVARCHAR(10),
			Code NVARCHAR(50),
			[Description] NVARCHAR(255),
			FinancialValue FLOAT,
			ParentCode NVARCHAR(50),
			Level INT,
			IdCurrency INT,
			IdField INT,
			StatementID INT,
            IsConsolidated INT		
            );

		-- Extract all root-level statements (no filtering on STATEMENTTYPE)
		--WITH Statement AS (
		--	SELECT *
		--	FROM OPENJSON(@json, '$.AdditionalFinancials.Statements')
		--	WITH (
		--		FINANCIALDATE DATE,
		--		[Type] NVARCHAR(50),
		--		[Audit] NVARCHAR(50),
		--		STATEMENTTYPE NVARCHAR(50),
		--		FINANCIALCURRENCY NVARCHAR(10),
		--		Analyses NVARCHAR(MAX) AS JSON
		--	)
		--),

		---- Recursive CTE to go through all Analysis trees from every statement
		--AnalysesRecursive AS (
		--	-- Anchor: root-level analyses
		--	SELECT 
		--		s.FINANCIALDATE as FINANCIALDATE,
		--		s.[Type] as [Type],
		--		s.[Audit] as [Audit],
		--		s.STATEMENTTYPE as STATEMENTTYPE,
		--		s.FINANCIALCURRENCY as FINANCIALCURRENCY,
		--		a.[Code] as [Code],
		--		a.[Description] as [Description],
		--		a.FinancialValue as FinancialValue,
		--		CAST(NULL AS NVARCHAR(50)) AS ParentCode,
		--		CAST(a.SubAnalyses AS NVARCHAR(MAX)) AS SubAnalyses,
		--		0 AS [Level]
		--	FROM Statement s
		--	CROSS APPLY OPENJSON(s.Analyses)
		--	WITH (
		--		[Code] NVARCHAR(50),
		--		[Description] NVARCHAR(255),
		--		FinancialValue FLOAT,
		--		SubAnalyses NVARCHAR(MAX) AS JSON
		--	) a

		--	UNION ALL

		--	-- Recursive: parse nested SubAnalyses
		--	SELECT 
		--		ar.FINANCIALDATE,
		--		ar.[Type],
		--		ar.[Audit],
		--		ar.STATEMENTTYPE,
		--		ar.FINANCIALCURRENCY,
		--		sa.[Code],
		--		sa.[Description],
		--		sa.FinancialValue,
		--		ar.Code AS ParentCode,
		--		CAST(sa.SubAnalyses AS NVARCHAR(MAX)) AS SubAnalyses,
		--		ar.[Level] + 1
		--	FROM AnalysesRecursive ar
		--	CROSS APPLY OPENJSON(ar.SubAnalyses)
		--	WITH (
		--		[Code] NVARCHAR(50),
		--		[Description] NVARCHAR(255),
		--		FinancialValue FLOAT,
		--		SubAnalyses NVARCHAR(MAX) AS JSON
		--	) sa
		--)

		---- Insert all results
		--INSERT INTO #FinancialAnalyses (
		--	FinancialDate, [Type], [Audit], StatementType, Currency,
		--	Code, [Description], FinancialValue, ParentCode, [Level]
		--)
		--SELECT
		--	FinancialDate, [Type], [Audit], StatementType, FinancialCurrency,
		--	Code, [Description], FinancialValue, ParentCode, [Level]
		--FROM AnalysesRecursive;

		-- Add index to track StatementID
		WITH Statement AS (
			SELECT 
				[key] AS StatementID,
				[value] AS StatementJson
			FROM OPENJSON(@json, '$.AdditionalFinancials.Statements')
		),

		ParsedStatements AS (
			SELECT 
				CAST(s.StatementID AS INT) AS StatementID,
				ps.FINANCIALDATE AS FINANCIALDATE,
				ps.MONTHSNO AS MONTHSNO,
				ps.Denomination AS Denomination,
				ps.[YEAR] AS [YEAR],
				ps.[Type] AS [Type],
				ps.[Audit] AS [Audit],
				ps.STATEMENTTYPE AS STATEMENTTYPE,
				ps.FINANCIALCURRENCY AS FINANCIALCURRENCY,
				ps.Analyses AS Analyses
			FROM Statement s
			CROSS APPLY OPENJSON(s.StatementJson)
			WITH (
				FINANCIALDATE NVARCHAR(20) '$.FINANCIALDATE',
				MONTHSNO NVARCHAR(20) '$.MONTHSNO',
				Denomination NVARCHAR(50) '$.Denomination',
				[YEAR] NVARCHAR(10) '$.YEAR',
				[Type] NVARCHAR(50) '$.TYPE',
				[Audit] NVARCHAR(50) '$.AUDIT',
				STATEMENTTYPE NVARCHAR(50) '$.STATEMENTTYPE',
				FINANCIALCURRENCY VARCHAR(50) '$.FINANCIALCURRENCY',
				Analyses NVARCHAR(MAX) '$.Analyses' AS JSON
			) ps
		),

		AnalysesRecursive AS (
			-- Anchor members: root-level analyses
			SELECT 
				ps.StatementID as StatementID,
				TRY_CAST(ps.FINANCIALDATE AS DATE) AS FinancialDate,
				ps.MONTHSNO as [MONTHSNO],
				ps.Denomination,
				ps.[YEAR] as [YEAR],
				ps.[Type] as [Type],
				ps.[Audit] as [Audit],
				ps.STATEMENTTYPE as STATEMENTTYPE,
				ps.FINANCIALCURRENCY as FINANCIALCURRENCY,
				a.[Code] as [Code],
				a.[Description] as [Description],
				a.FinancialValue as FinancialValue,
				CAST(NULL AS NVARCHAR(50)) AS ParentCode,
				CAST(a.SubAnalyses AS NVARCHAR(MAX)) AS SubAnalyses,
				0 AS [Level]
			FROM ParsedStatements ps
			CROSS APPLY OPENJSON(ps.Analyses)
			WITH (
				[Code] NVARCHAR(50),
				[Description] NVARCHAR(255),
				FinancialValue FLOAT,
				SubAnalyses NVARCHAR(MAX) AS JSON
			) a

			UNION ALL

			-- Recursive members
			SELECT 
				ar.StatementID,
				ar.FinancialDate,
				ar.MONTHSNO,
				ar.Denomination,
				ar.[YEAR],
				ar.[Type],
				ar.[Audit],
				ar.STATEMENTTYPE,
				ar.FINANCIALCURRENCY,
				sa.[Code],
				sa.[Description],
				sa.FinancialValue,
				ar.Code AS ParentCode,
				CAST(sa.SubAnalyses AS NVARCHAR(MAX)) AS SubAnalyses,
				ar.[Level] + 1
			FROM AnalysesRecursive ar
			CROSS APPLY OPENJSON(ar.SubAnalyses)
			WITH (
				[Code] NVARCHAR(50),
				[Description] NVARCHAR(255),
				FinancialValue FLOAT,
				SubAnalyses NVARCHAR(MAX) AS JSON
			) sa
		)

		-- Final insert
		INSERT INTO #FinancialAnalyses (
			StatementID, FinancialDate, MONTHSNO, Denomination, [YEAR], [Type], [Audit], StatementType, Currency,
			Code, [Description], FinancialValue, ParentCode, [Level]
		)
		SELECT
			StatementID, FinancialDate, MONTHSNO, Denomination, [YEAR], [Type], [Audit], StatementType, FINANCIALCURRENCY,
			Code, [Description], FinancialValue, ParentCode, [Level]
		FROM AnalysesRecursive;

		UPDATE #FinancialAnalyses set FinancialDate_new = LEFT(FinancialDate,4)+'-'+LEFT(RIGHT(FinancialDate,5),2)+'-'+RIGHT(RIGHT(FinancialDate,5),2)

		UPDATE #FinancialAnalyses set IsConsolidated = CASE WHEN [Type]='Consolidated' THEN 1 WHEN [Type]='Standalone' then 0 END

		--------------------------------------------------FinancialComparison----------------------------------------------------

		IF OBJECT_ID ('tempdb..#FinancialComparison', 'U') IS NOT NULL
		DROP TABLE #FinancialComparison;

		CREATE TABLE #FinancialComparison (
			ID INT Identity(1,1),
			Year INT,
			FinancialMetric NVARCHAR(255),
			FinancialValue DECIMAL(18,2)
		);

		INSERT INTO #FinancialComparison (Year, FinancialMetric, FinancialValue)
		SELECT 
			YEAR_DATA.[Year],
			FinancialData.FinancialMetric,
			FinancialData.FinancialValue
		FROM OPENJSON(@json, '$.FINANCIALCOMPARISON.FINANCIALYEAR') 
		WITH (
			[Year] INT '$.YEAR',
			FinancialValues NVARCHAR(MAX) '$.FINANCIALVALUES' AS JSON
		) AS YEAR_DATA
		CROSS APPLY OPENJSON(YEAR_DATA.FinancialValues, '$.FINANCIALVALUE')
		WITH (
			FinancialMetric NVARCHAR(255) '$.NAME',
			FinancialValue DECIMAL(18,2) '$.FINANCIALVLAUE'
		) AS FinancialData;
		
		
		--------------------------------------------------CUSTOMSDATA----------------------------------------------------

		----IF OBJECT_ID ('tempdb..#ImportShipments', 'U') IS NOT NULL
		----DROP TABLE #ImportShipments;

		------ Import Shipments Table
		----CREATE TABLE #ImportShipments (
		----    Year INT,
		----    QuarterValue INT,
		----    OriginCountry INT,
		----    ValueInUSD FLOAT,
		----    Weight FLOAT
		----);

		----INSERT INTO #ImportShipments
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.SHIPMENTS.IMPORTSHIPMENTS.QUARTERS')
		----WITH (
		----    Year INT '$.YEAR',
		----    QuarterValue INT '$.QUARTERVALUE',
		----    OriginCountry INT '$.ORIGINCOUNTRY',
		----    ValueInUSD FLOAT '$.VALUEINUSD',
		----    Weight FLOAT '$.WEIGHT'
		----);

		----IF OBJECT_ID ('tempdb..#ExportShipments', 'U') IS NOT NULL
		----DROP TABLE #ExportShipments;
		
		------ Export Shipments Table
		----CREATE TABLE #ExportShipments (
		----    Year INT,
		----    QuarterValue INT,
		----    OriginCountry INT,
		----    ValueInUSD FLOAT,
		----    Weight FLOAT
		----);

		----INSERT INTO #ExportShipments
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.SHIPMENTS.EXPORTSHIPMENTS.QUARTERS')
		----WITH (
		----	Year INT '$.YEAR',
		----	QuarterValue INT '$.QUARTERVALUE',
		----	OriginCountry INT '$.ORIGINCOUNTRY',
		----	ValueInUSD FLOAT '$.VALUEINUSD',
		----	Weight FLOAT '$.WEIGHT'
		----);

		----IF OBJECT_ID ('tempdb..#ImportProducts', 'U') IS NOT NULL
		----DROP TABLE #ImportProducts;
		
		------ Import Products Table
		----CREATE TABLE #ImportProducts (
		----    HSCode NVARCHAR(50),
		----    Description NVARCHAR(255)
		----);

		----INSERT INTO #ImportProducts
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.SHIPMENTPRODUCTS.IMPORTPRODUCTS.Products')
		----WITH (
		----	HSCode NVARCHAR(50) '$.HSCODE',
		----	Description NVARCHAR(255) '$.DESCRIPTION'
		----);

		----IF OBJECT_ID ('tempdb..#ExportProducts', 'U') IS NOT NULL
		----DROP TABLE #ExportProducts;
		
		------ Export Products Table
		----CREATE TABLE #ExportProducts (
		----    HSCode NVARCHAR(50),
		----    Description NVARCHAR(255)
		----);

		----INSERT INTO #ExportProducts
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.SHIPMENTPRODUCTS.EXPORTPRODUCTS.Products')
		----WITH (
		----	HSCode NVARCHAR(50) '$.HSCODE',
		----	Description NVARCHAR(255) '$.DESCRIPTION'
		----);

		----IF OBJECT_ID ('tempdb..#ImportCountries', 'U') IS NOT NULL
		----DROP TABLE #ImportCountries;
		
		------ Import Countries Table
		----CREATE TABLE #ImportCountries (
		----    Country NVARCHAR(255),
		----    CountryCode NVARCHAR(10)
		----);

		----INSERT INTO #ImportCountries
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.SHIPMENTCOUNTRIES.IMPORTCOUNTRIES.COUNTRYRECORDS')
		----WITH (
		----	Country NVARCHAR(255) '$.COUNTRY',
		----	CountryCode NVARCHAR(10) '$.COUNTRYCODE'
		----)
		----WHERE Country IS NOT NULL;

		----IF OBJECT_ID ('tempdb..#ExportCountries', 'U') IS NOT NULL
		----DROP TABLE #ExportCountries;
		
		------ Export Countries Table
		----CREATE TABLE #ExportCountries (
		----    Country NVARCHAR(255),
		----    CountryCode NVARCHAR(10)
		----);

		----INSERT INTO #ExportCountries
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.SHIPMENTCOUNTRIES.EXPORTCOUNTRIES.COUNTRYRECORDS')
		----WITH (
		----	Country NVARCHAR(255) '$.COUNTRY',
		----	CountryCode NVARCHAR(10) '$.COUNTRYCODE'
		----)
		----WHERE Country IS NOT NULL; 

		----IF OBJECT_ID ('tempdb..#TopSuppliers', 'U') IS NOT NULL
		----DROP TABLE #TopSuppliers;
		
		------ Top Suppliers Table
		----CREATE TABLE #TopSuppliers (
		----    UID NVARCHAR(50)
		----);

		----INSERT INTO #TopSuppliers
		----SELECT *
		----FROM OPENJSON(@json, '$.CUSTOMSDATA.TOPSUPPLIERS.Suppliers')
		----WITH (
		----	UID NVARCHAR(50) '$.UID'
		----);
		
	--------------------------------------------------------------
	
		DECLARE @CountryCode NVARCHAR(10),@CountryID INT,@CountryPhoneCode NVARCHAR(10)
		
		SELECT 
			@CountryCode=CountryCode,
			@CountryID=ID,
			@CountryPhoneCode = TelephoneCode 
		from tblDic_GeoCountries where Country=@Country

		IF OBJECT_ID ('tempdb..#GeoTowns', 'U') IS NOT NULL
		DROP TABLE #GeoTowns;

		CREATE TABLE #GeoTowns (
			ID INT NOT NULL,
			Town NVARCHAR(140) NOT NULL
		);

		IF OBJECT_ID ('tempdb..#GeoStreets', 'U') IS NOT NULL
		DROP TABLE #GeoStreets;

		CREATE TABLE #GeoStreets (
			ID INT NOT NULL,
			Street NVARCHAR(400) NOT NULL,
			IdTown INT NOT NULL
		);

		IF @CountryID IS NOT NULL
		BEGIN
			INSERT INTO #GeoTowns (ID, Town)
			SELECT t.ID, t.Town
			FROM tblDic_GeoTowns t
			JOIN tblDic_GeoDistricts d ON d.ID = t.IdDistrict
			WHERE d.IdCountry = @CountryID;

			INSERT INTO #GeoStreets (ID, Street, IdTown)
			SELECT b.ID, b.Street, b.IdTown
			FROM tblDic_GeoStreets b
			JOIN #GeoTowns t ON t.ID = b.IdTown;
		END

		CREATE INDEX IX_GeoTowns_Town ON #GeoTowns (Town);
		CREATE INDEX IX_GeoStreets_StreetTown ON #GeoStreets (Street, IdTown);
		
		--if((@UID is null or @UID ='') and @CountryID is not null and @Subject is not null and (select count(*) from #REGISTERS where REGISTERTYPEID = 4024813)>0) 
		--begin

		--	declare @RegisterNumber nvarchar(255);
		--	set @RegisterNumber = (select top 1 REGISTERNUMBER from #REGISTERS where REGISTERTYPEID = 4024813 and REGISTERMAINID = 4047632);
		
		--	if(@RegisterNumber is not null)
		--	begin

		--		set @uid = (
		--			select top 1 a.[UID] from tblatoms a (nolock)
		--			join tblcompanies c (nolock) on c.IDATOM = a.IDATOM
		--			join tblCompanyIDs i (nolock) on i.IDATOM = a.IDATOM and i.IdOrganisation = 4024813
		--			where 
		--			isnull(a.IsDeleted,0)=0 
		--			and IdRegisteredCountry = @CountryID
		--			and isnull(c.RegisteredName,c.[Name]) = @Subject
		--			and i.Number= @RegisterNumber
		--		)

		--	end

		--	if(@UID is null or @UID = '')
		--	begin
		--		select 0; ----No matching entity found
		--		return;
		--	end

		--end
		

---============================================================[MAPPINGS]============================================================---

		IF((SELECT COUNT(*) from #Address)>0)
		BEGIN
			
			UPDATE ad set AddressTypeID=t.ID from tblDic_BaseValues t
			join #Address ad on t.DummyName=REPLACE(ad.ADDRESSTYPE,'&amp;','&')
			where IdBaseDicName=164

			UPDATE ad set Idtown = t.ID,IdTownPostal=t.ID 
			from #GeoTowns t 
			join #Address ad on t.Town=ad.TOWN

			IF EXISTS (SELECT 1 FROM #Address WHERE Idtown IS NULL AND TOWN IS NOT NULL)
			BEGIN
				UPDATE ad SET Idtown = t.ID,IdTownPostal=t.ID 
				FROM #GeoTowns t 
				JOIN #Address ad
				ON REPLACE(LOWER(ad.TOWN), ' ', '') LIKE '%' + REPLACE(LOWER(t.Town), ' ', '') + '%'
				OR SOUNDEX(ad.TOWN) = SOUNDEX(t.Town)
				WHERE ad.Idtown IS NULL
			END

			UPDATE ad set IdArea = t.ID 
		    from tblDic_GeoAreas t 
		    join #Address ad on t.Area=ad.AREA and ad.idtown = t.IdTown

			IF EXISTS (SELECT 1 FROM #Address WHERE IdArea IS NULL AND AREA IS NOT NULL)
			BEGIN
				UPDATE ad set IdArea = t.ID 
			    from tblDic_GeoAreas t 
				JOIN #Address ad
				ON REPLACE(LOWER(ad.AREA), ' ', '') LIKE '%' + REPLACE(LOWER(t.Area), ' ', '') + '%'
				OR SOUNDEX(ad.AREA) = SOUNDEX(t.Area)
				WHERE ad.IdArea IS NULL and ad.idtown=t.IdTown
			END
			
			--UPDATE ad set IdBuilding=t.ID 
			--from 
			--tblDic_GeoBuildings b join tblDic_GeoTowns t on t.id = b.IdTown 
			--join tblDic_GeoDistricts d on d.ID = t.IdDistrict
			--join #Address ad on b.Building=ad.BUILDING and ad.idtown = t.id
			--and d.IdCountry = @CountryID

			--UPDATE ad set IdBuilding = t.ID 
		 --   from tblDic_GeoBuildings t 
			--JOIN #Address ad
			--ON REPLACE(LOWER(ad.BUILDING), ' ', '') LIKE '%' + REPLACE(LOWER(t.Building), ' ', '') + '%'
			--OR SOUNDEX(ad.BUILDING) = SOUNDEX(t.Building)
			--WHERE ad.IdBuilding IS NULL

			UPDATE ad set idstreet=b.ID 
			from #GeoStreets b 
			join #Address ad on b.Street=ad.STREET and ad.idtown = b.IdTown

			IF EXISTS (SELECT 1 FROM #Address WHERE idstreet IS NULL AND idtown IS NOT NULL AND Street IS NOT NULL)
			BEGIN
				UPDATE ad
				SET ad.idstreet = b.ID
				FROM #Address ad
				JOIN #GeoStreets b ON b.IdTown = ad.idtown
				AND 
				TRIM(LOWER(REPLACE(b.Street, '  ', ' '))) 
				COLLATE Latin1_General_CI_AI
				=
				TRIM(LOWER(REPLACE(ad.Street, '  ', ' '))) 
				COLLATE Latin1_General_CI_AI
				WHERE ad.idstreet is null and ad.idtown=b.IdTown
			END

      IF EXISTS (SELECT 1 FROM #Address WHERE idstreet IS NULL AND Street IS NOT NULL)
      BEGIN
	      UPDATE ad set idstreet = t.ID 
			  from #GeoStreets t 
				JOIN #Address ad
				ON REPLACE(LOWER(ad.Street), ' ', '') LIKE '%' + REPLACE(LOWER(t.Street), ' ', '') + '%'
				OR SOUNDEX(ad.Street) = SOUNDEX(t.Street)
				WHERE ad.idstreet IS NULL and ad.idtown=t.IdTown
	  END


			--UPDATE ad set idstreet = t.ID 
		 --   from tblDic_GeoStreets t 
			--JOIN #Address ad
			--ON REPLACE(LOWER(ad.Street), ' ', '') LIKE '%' + REPLACE(LOWER(t.Street), ' ', '') + '%'
			--OR SOUNDEX(ad.Street) = SOUNDEX(t.Street)
   --   JOIN tblDic_GeoTowns tow ON ad.idtown = tow.id
			--JOIN tblDic_GeoDistricts d ON d.ID = tow.IdDistrict
			--WHERE d.IdCountry = @CountryID and ad.idstreet IS NULL

		END
		
		IF((SELECT COUNT(*) from #Contacts)>0)
		BEGIN

			UPDATE c set IdAddress = ad.id
			from #Contacts c
			join #Address ad on c.ADDRESSTYPE= ad.ADDRESSTYPE and
			c.STREET = ad.STREET and c.AREA = ad.AREA and c.TOWN = ad.TOWN and c.COUNTRY = ad.COUNTRY 
						
		END

		
		IF((SELECT COUNT(*) from #STATUS)>0)
		BEGIN

			UPDATE ad set idStatus=t.ID from tblDic_BaseValues t
			join #STATUS ad on t.DummyName=ad.CompanyStatus
			where IdBaseDicName=190

		END

		IF((SELECT COUNT(*) from #REGISTERS)>0)
		BEGIN

			UPDATE ad set idStatus=t.ID from tblDic_BaseValues t
			join #REGISTERS ad on t.DummyName=ad.REGISTERSTATUS
			where IdBaseDicName=293
		
		END
		
		IF((SELECT COUNT(*) from #LEGALFORMINFO)>0)
		BEGIN
			
			UPDATE ad set IdType=t.ID from tblDic_BaseValues t
			join #LEGALFORMINFO ad on t.DummyName=ad.LEGALFORM
			where IdBaseDicName=189 and t.CountryID = @CountryID
		
		END
		
		IF((SELECT COUNT(*) from #CAPITAL)>0)
		BEGIN
			
			UPDATE ad set IdCurrency=t.ID from tblDic_Currencies t
			join #CAPITAL ad on t.Symbol=ad.CapitalCurrency

		END

		IF((SELECT COUNT(*) from #Premises)>0)
		BEGIN
			
			UPDATE ad set IdType=t.ID from tblDic_BaseValues t
			join #Premises ad on t.DummyName=ad.[Type]
			where IdBaseDicName=461
			
			UPDATE ad set [IdSizeMeasure]=t.ID from tblDic_BaseValues t
			join #Premises ad on t.DummyName=TRIM(SUBSTRING(ad.Size,CHARINDEX(' ',size),LEN(Size)))
			where IdBaseDicName=467

			UPDATE ad set idpremisetype=t.ID from tblDic_BaseValues t
			join #Premises ad on t.DummyName=ad.[ownership]
			where IdBaseDicName=463

		END

		IF((SELECT COUNT(*) from #Activities)>0)
		BEGIN
			
			UPDATE ad set IdDivisionUksic=g.DivisionID,IdGroupUksic=g.ID,IdClassUksic=s.ClassId,IdSubClassUksic=s.Id 
			from #Activities ad
			inner join [UKSIC2007_subclass] s on s.Code = ActivityCode
			inner join [UKSIC2007_class] c on c.id = s.ClassID
			inner join [UKSIC2007_group] g on g.id = c.GroupID
			
			UPDATE ad set IdDivisionUksic=g.DivisionID,IdGroupUksic=g.ID,IdClassUksic=c.id
			from #Activities ad
			inner join [UKSIC2007_class] c on c.Code = ActivityCode
			inner join [UKSIC2007_group] g on g.id = c.GroupID
			
			UPDATE ad set IdDivisionUksic=g.DivisionID,IdGroupUksic=g.ID
			from #Activities ad
			inner join [UKSIC2007_group] g on g.Code = ActivityCode

		END
	
		IF((SELECT COUNT(*) from #MANAGERSINDIVIDUALS_Main)>0)
		BEGIN
		

			UPDATE ad set Idgender=t.ID from tblDic_BaseValues t
			join #MANAGERSINDIVIDUALS_Main ad on t.DummyName=ad.MANAGERINDIVIDUALGENDER
			where IdBaseDicName=364

			UPDATE ad set IdNationality=t.ID from tblDic_BaseValues t
			join #MANAGERSINDIVIDUALS_Main ad on t.DummyName=MANAGERINDIVIDUALNATIONALITY
			where IdBaseDicName=366

			UPDATE ad set Idtitle=t.ID from tblDic_BaseValues t
			join #MANAGERSINDIVIDUALS_Main ad on t.DummyName=TITLE
			where IdBaseDicName=358

			UPDATE ad set IdLanguage=t.ID from tblDic_BaseValues t
			join #MANAGERSINDIVIDUALS_Main ad on t.DummyName=MANAGERINDIVIDUALLANGUAGE
			where IdBaseDicName=354
			
		END
		----select * from #MANAGERSINDIVIDUALS_Main   return;
		IF((SELECT COUNT(*) from #SHAREHOLDERSINDIVIDUALS_Distinct)>0)
		BEGIN

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #SHAREHOLDERSINDIVIDUALS_Distinct ad on t.Country=@Country
		
			UPDATE ad set IdNationality=t.ID from tblDic_BaseValues t
			join #SHAREHOLDERSINDIVIDUALS_Distinct ad on t.DummyName=SHAREHOLDERINDIVIDUALNATIONALITY
			where IdBaseDicName=366

		END

		IF((SELECT COUNT(*) from #MANAGERSCOMPANIES_Distinct)>0)
		BEGIN

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #MANAGERSCOMPANIES_Distinct ad on t.Country=ad.MANAGERCOMPANYCOUNTRY
		
		END
		
		IF((SELECT COUNT(*) from #SHAREHOLDERSCOMPANIES_Distinct)>0)
		BEGIN

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #SHAREHOLDERSCOMPANIES_Distinct ad on t.Country=ad.SHAREHOLDERCOMPANYCOUNTRY
		
		END

		IF((SELECT COUNT(*) from #HOLDINGS_Distinct)>0)
		BEGIN

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #HOLDINGS_Distinct ad on t.Country=ad.Address

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #HOLDINGS ad on t.Country=ad.Address
		
		END

		IF((SELECT COUNT(*) from #DIRECTORSHIPS_Distinct)>0)
		BEGIN

			--UPDATE ad set ID=t.id from #DIRECTORSHIPS t
			--join #DIRECTORSHIPS_Distinct ad on t.Name=ad.Name

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #DIRECTORSHIPS_Distinct ad on t.Country=ad.Address

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #DIRECTORSHIPS_Distinct ad on t.Country=TRIM(SUBSTRING(ad.Address,CHARINDEX(', ',ad.Address)+1,LEN(ad.Address)))
			where Address like '%,%'

			UPDATE ad set IdCountry=t.ID from #DIRECTORSHIPS_Distinct t
			join #DIRECTORSHIPS ad on t.Address=ad.Address

			UPDATE ad set IdPosition=t.ID from tblDic_BaseValues t
			join #DIRECTORSHIPS ad on t.DummyName=ad.Position
			where IdBaseDicName=272

			UPDATE ad set idOrganisation=t.ID from tblDic_BaseValues t
			join #DIRECTORSHIPS ad on t.DummyName=OrganisationName
			where IdBaseDicName=290

			UPDATE ad set Idregister=t.ID from tblDic_BaseValues t
			join #DIRECTORSHIPS ad on t.DummyName=RegisterName
			where IdBaseDicName=291 and Idcountry = @CountryID

			UPDATE ad set IDStatus=t.ID from tblDic_BaseValues t
			join #DIRECTORSHIPS ad on t.DummyName=CompanyStatus
			where IdBaseDicName=293
		
		END

		IF((SELECT COUNT(*) from #Financials)>0)
		BEGIN
			
			UPDATE ad set IdCurrency=t.ID from tblDic_Currencies t
			join #Financials ad on t.Symbol=ad.FinancialCurrency

			UPDATE ad set IdField=t.ID from tblFinancials_DicFields t
			join #Financials ad on t.DummyName=ad.Name

			UPDATE #Financials set IdField = 4429 where	Idfield is null and [Name]='Cash from financing activities'
			UPDATE #Financials set IdField = 4431 where	Idfield is null and [Name]='Cash and cash equivalents at beginning of period'
			UPDATE #Financials set IdField = 4432 where	Idfield is null and [Name]='Cash and cash equivalents at end of period'

		END

		--IF((SELECT COUNT(*) from #HistoricalManagements)>0)
		--BEGIN
			
		--	UPDATE ad set Idtitle=t.ID from tblDic_BaseValues t
		--	join #HistoricalManagements_Main ad on t.DummyName=LEFT(FullName,CHARINDEX(' ',FullName))
		--	where IdBaseDicName=358

		--END

		IF((SELECT COUNT(*) from #HistoricalManagements_Main)>0)
		BEGIN

			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #HistoricalManagements_Main ad on t.Country=ad.COUNTRY
		
		END

		CREATE INDEX IX_HistoricalManagements_Main_Company
		ON #HistoricalManagements_Main (ManagerType, FullName, IdCountry)
		INCLUDE (ID, Companyidatom);

		IF((SELECT COUNT(*) from #HistoricalActivities)>0)
		BEGIN
			
			UPDATE ad set IdDivisionUksic=g.DivisionID,IdGroupUksic=g.ID,IdClassUksic=s.ClassId,IdSubClassUksic=s.Id 
			from #HistoricalActivities ad
			inner join [UKSIC2007_subclass] s on s.[Description] = Activity
			inner join [UKSIC2007_class] c on c.id = s.ClassID
			inner join [UKSIC2007_group] g on g.id = c.GroupID
			
			UPDATE ad set IdDivisionUksic=g.DivisionID,IdGroupUksic=g.ID,IdClassUksic=c.id
			from #HistoricalActivities ad
			inner join [UKSIC2007_class] c on c.[Description] = Activity
			inner join [UKSIC2007_group] g on g.id = c.GroupID
			
			UPDATE ad set IdDivisionUksic=g.DivisionID,IdGroupUksic=g.ID
			from #HistoricalActivities ad
			inner join [UKSIC2007_group] g on g.[Description] = Activity


		END
	
		IF((SELECT COUNT(*) from #DEBTCOLLECTIONAGENCIESSEARCH)>0)
		BEGIN
			
			UPDATE ad set IdDebtAgencies=t.ID from tblDic_BaseValues t
			join #DEBTCOLLECTIONAGENCIESSEARCH ad on t.DummyName=ad.DebtAgencies
			where IdBaseDicName=8100

		END

		IF((SELECT COUNT(*) from #ProductionCapacity)>0)
		BEGIN
	
			UPDATE ad set IdUnitsType=t.ID from tblDic_BaseValues t
			join #ProductionCapacity ad on t.DummyName=TRIM(SUBSTRING(ProdCapacityInstalled,CHARINDEX(' ',ProdCapacityInstalled),LEN(ProdCapacityInstalled)))
			where IdBaseDicName=384

		END

		IF((SELECT COUNT(*) from #AnnualImportsExports)>0)
		BEGIN
	
			UPDATE ad set Idcurrency=t.ID from tblDic_Currencies t
			join #AnnualImportsExports ad on t.Symbol=Currency

		END

		IF((SELECT COUNT(*) from #ImportFrom)>0)
		BEGIN
			
			UPDATE ad set IdCountry=t.ID from tblDic_GeoCountries t
			join #ImportFrom ad on t.Country=ad.Country

		END

		IF((SELECT COUNT(*) from #MethodOfPayment)>0)
		BEGIN
			
			UPDATE ad set IdPayMethod=t.ID from tblDic_BaseValues t
			join #MethodOfPayment ad on t.DummyName=ad.PAYMETHOD
			where IdBaseDicName=382

		END
		
		IF((SELECT COUNT(*) from #Certifications)>0)
		BEGIN
			
			UPDATE ad set IdCertificateType=t.ID from tblDic_BaseValues t
			join #Certifications ad on t.DummyName=ad.CertificationName
			where IdBaseDicName=383

		END

		IF((SELECT COUNT(*) from #TradeReferences)>0)
		BEGIN
			
			UPDATE ad set PaymentId=t.ID from CS_TradeReference_Payments t
			join #TradeReferences ad on t.Name=ad.Payments

			UPDATE ad set TermsOfPaymentsID=t.ID from tblDic_BaseValues t
			join #TradeReferences ad on t.DummyName=ad.TermsOfPayments
			where IdBaseDicName=382 

			UPDATE ad set BusinessTrendId=t.ID from CS_TradeReference_Business t
			join #TradeReferences ad on t.[Name]=ad.BusinessTrend

			UPDATE ad set MaxCrLim=t.ID from CS_TradeReference_MaxCrLim t
			join #TradeReferences ad on t.[Value]=ad.MaxCreditLimit

			UPDATE ad set AvgCrLim=t.ID from [CS_TradeReference_AVGInvAmnt] t
			join #TradeReferences ad on t.[Value]=ad.AverageOrderAmount

			UPDATE ad set MaxCreditLimitCurrencyID=t.ID from tblDic_Currencies t
			join #TradeReferences ad on t.Symbol=ad.MaxCreditLimitCurrency

			UPDATE ad set AverageOrderCurrencyID=t.ID from tblDic_Currencies t
			join #TradeReferences ad on t.Symbol=ad.AverageOrderCurrency


		END
		
		IF((SELECT COUNT(*) from #FinancialAnalyses)>0)
		BEGIN
			
			UPDATE ad set IdCurrency=t.ID from tblDic_Currencies t
			join #FinancialAnalyses ad on t.Symbol=ad.Currency

			UPDATE ad set IdField=t.ID from tblFinancials_DicFieldsAdditional t
			join #FinancialAnalyses ad on t.BvDEPCode=ad.Code

		END		
		
---============================================================[FINISH MAPPINGS]============================================================---
---============================================================[UPDATE START]============================================================---

		--IF(@UID is not null and @UID <> '')
		--BEGIN

		--set @idatom = (SELECT top 1 idatom from tblatoms  where [UID] = @UID )
		
---------------------------------------------------------------
-- CONDITION 1: UID is already provided
---------------------------------------------------------------
IF (@UID IS NOT NULL AND @UID <> '')
BEGIN
    PRINT 'Condition 1: UID provided, trying to resolve idatom...';
    SET @idatom = ISNULL(@idatom, (SELECT TOP 1 idatom FROM tblatoms WHERE [UID] = @UID));
    PRINT 'idatom from UID = ' + ISNULL(CAST(@idatom AS NVARCHAR(50)), 'NULL');
END
ELSE
BEGIN
    PRINT 'Condition 1 failed → entering Condition 2 (derive UID from register info)...';

    ---------------------------------------------------------------
    -- CONDITION 2: Try to derive UID based on register info
    ---------------------------------------------------------------
    PRINT @CountryID;
    PRINT @Subject;

    IF (
        @CountryID IS NOT NULL 
        AND @Subject IS NOT NULL 
        AND (SELECT COUNT(*) FROM #REGISTERS WHERE REGISTERTYPEID = 4024813) > 0
    )
    BEGIN
        PRINT 'Condition 2 passed — checking all register numbers...';

        SELECT TOP 1
            @UID = a.[UID],
            @idatom = a.IDATOM
        FROM #REGISTERS r
        JOIN tblCompanyIDs i WITH (NOLOCK)
            ON i.Number = r.REGISTERNUMBER
           AND i.IdOrganisation = 4024813
        JOIN tblatoms a WITH (NOLOCK)
            ON a.IDATOM = i.IDATOM
        JOIN tblcompanies c WITH (NOLOCK)
            ON c.IDATOM = a.IDATOM
        WHERE r.REGISTERTYPEID = 4024813
          AND r.REGISTERMAINID = 4047632
          AND ISNULL(r.REGISTERNUMBER, '') <> ''
          AND ISNULL(a.IsDeleted, 0) = 0
          AND c.IdRegisteredCountry = @CountryID
          AND ISNULL(c.RegisteredName, c.[Name]) = @Subject
        ORDER BY r.ID;

        PRINT '  Derived @UID = ' + ISNULL(@UID, 'NULL');

        IF (@UID IS NOT NULL AND @UID <> '')
        BEGIN
            PRINT 'idatom resolved: ' + ISNULL(CAST(@idatom AS NVARCHAR(50)), 'NULL');
        END

        IF @idatom IS NULL
        BEGIN
            PRINT 'No matching idatom found for any register number.';
        END
    END
    ELSE
    BEGIN
        PRINT 'Condition 2 skipped — missing CountryID, Subject, or #REGISTERS entry.';
    END
END

PRINT '--- FINAL DEBUG RESULTS ---';
PRINT '  UID = ' + ISNULL(@UID, 'NULL');
PRINT '  idatom = ' + ISNULL(CAST(@idatom AS NVARCHAR(50)), 'NULL');
		
		--	DECLARE @HasRegisters BIT = CASE 
		--		WHEN EXISTS (SELECT 1 FROM #REGISTERS WHERE ISNULL(REGISTERNUMBER, '') <> '') 
		--		THEN 1 ELSE 0 END;

		--	DECLARE @HasMatchingRegister BIT = CASE 
		--		WHEN EXISTS (
		--			SELECT REGISTERNUMBER
		--			FROM #REGISTERS r
		--			JOIN tblCompanyIDs i ON i.Number = r.REGISTERNUMBER
		--			JOIN tblcompanies c WITH (NOLOCK)ON c.IDATOM = i.IDATOM
		--			JOIN tblAtoms a ON a.IDATOM=i.IDATOM
		--			WHERE REGISTERTYPEID = 4024813 
		--			AND REGISTERMAINID = 4047632
		--			AND ISNULL(REGISTERNUMBER, '') <> '' and IdRegisteredCountry=@CountryID and RegisteredName=@Subject
		--		)
		--		THEN 1 ELSE 0 
		--	END;

		--	---------------------------------------------------------------
		--	-- CONDITION : Registers exist but NO matching registration → DO NOTHING
		--	---------------------------------------------------------------
		--	IF (@HasRegisters = 1 AND @HasMatchingRegister = 0)
		--	BEGIN
		--		PRINT 'Condition 3: Register numbers exist but no match found in tblCompanyIDs — doing NOTHING.';
				
		--	END

		--ELSE
		IF (ISNULL(@UID,'')<>'' and ISNULL(@idatom,0)<>0 )-- AND (SELECT COUNT(*) from #REGISTERS)>0)
		BEGIN

		------RegisteredName
		IF((SELECT RegisteredName from tblcompanies where idatom = @idatom) is not null and @Subject IS NOT NULL)
		BEGIN
			
			declare @CrisRegisteredName nvarchar(250);
			set @CrisRegisteredName= (SELECT RegisteredName from tblcompanies where idatom = @idatom)
			set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompanyRegisteredNameSourceId=s.ID  where idatom = @idatom and RegisteredName is not null),12)
			set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompanyRegisteredNameIntelligenceId=s.ID where idatom = @idatom and RegisteredName is not null),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			--IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
			BEGIN

					UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

					UPDATE tblCompanies set DateUpdate = GETDATE() where IDATOM=@idatom

					if(replace(replace(replace(replace(replace(replace(replace(@CrisRegisteredName,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N'') != 
						replace(replace(replace(replace(replace(replace(replace(@Subject,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N''))
					begin

						INSERT INTO tblCompanies_Names(idatom, NameType,Name, IsHistory, DateUpdated, [IntelligenceID],[SourceID])
						SELECT DISTINCT @idatom, 1,@CrisRegisteredName, 1,GETDATE(),@IntelligenceID,@SourceID 
						where 
						@CrisRegisteredName not in (select [Name] from tblCompanies_Names where idatom = @idatom and NameType = 1)

						UPDATE [tblCompanies] set RegisteredName = @Subject, CompanyRegisteredNameIntelligenceId = @IntelligenceID,	CompanyRegisteredNameSourceId = @SourceID
						where idatom = @idatom
						

					end

				END


			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
		ELSE
		BEGIN
				
			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom	

			UPDATE tblcompanies set RegisteredName = @Subject, CompanyRegisteredNameSourceId = @SourceID, CompanyRegisteredNameIntelligenceId = @IntelligenceID, DateUpdate = GETDATE()
			where idatom = @idatom
				
		END
		
		-------------[Name]
		IF((SELECT [Name] from tblcompanies where idatom = @idatom) is not null and @Subject IS NOT NULL)
		BEGIN
			
			declare @CrisName nvarchar(250);
			set @CrisName= (SELECT [Name] from tblcompanies where idatom = @idatom)
			set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompaniesNameSourceId=s.ID  where idatom = @idatom and c.[Name] is not null),12)
			set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompaniesNameIntelligenceId=s.ID where idatom = @idatom and c.[Name] is not null),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN

					UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

					UPDATE tblCompanies set DateUpdate = GETDATE()	where IDATOM=@idatom

					if(replace(replace(replace(replace(replace(replace(replace(@CrisName,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N'') != 
						replace(replace(replace(replace(replace(replace(replace(@Subject,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N''))
					begin

						INSERT INTO tblCompanies_Names(idatom, NameType,Name, IsHistory, DateUpdated, [IntelligenceID],[SourceID])
						SELECT DISTINCT @idatom, 1,@CrisName, 1,GETDATE(),@IntelligenceID,@SourceID 
						where 
						@CrisName not in (select [Name] from tblCompanies_Names where idatom = @idatom and NameType = 1)

						UPDATE [tblCompanies] set [Name] = @Subject, CompaniesNameIntelligenceId = @IntelligenceID,	CompaniesNameSourceId = @SourceID
						where idatom = @idatom						

					end

				END


			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
		ELSE
		BEGIN
				
			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom	

			UPDATE tblcompanies set [Name] = @Subject, CompaniesNameSourceId = @SourceID, CompaniesNameIntelligenceId = @IntelligenceID, DateUpdate = GETDATE()
			where idatom = @idatom
				
		END

		-------------[RegisteredNameLocal]
		IF((SELECT RegisteredNameLocal from tblcompanies where idatom = @idatom) is not null and @SubjectNativeName IS NOT NULL)
		BEGIN
			
			declare @CrisRegisteredNameLocal nvarchar(250);
			set @CrisRegisteredNameLocal= (SELECT RegisteredNameLocal from tblcompanies where idatom = @idatom)
			set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompaniesNameSourceId=s.ID  where idatom = @idatom and c.RegisteredNameLocal is not null),12)
			set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompaniesNameIntelligenceId=s.ID where idatom = @idatom and c.RegisteredNameLocal is not null),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN

					UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

					UPDATE tblCompanies set DateUpdate = GETDATE()	where IDATOM=@idatom

					if(replace(replace(replace(replace(replace(replace(replace(@CrisRegisteredNameLocal,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N'') != 
						replace(replace(replace(replace(replace(replace(replace(@SubjectNativeName,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N''))
					begin

						INSERT INTO tblCompanies_Names(idatom, NameType,Name, IsHistory, DateUpdated, [IntelligenceID],[SourceID])
						SELECT DISTINCT @idatom, 1,@CrisRegisteredNameLocal, 1,GETDATE(),@IntelligenceID,@SourceID 
						where 
						@CrisRegisteredNameLocal not in (select [Name] from tblCompanies_Names where idatom = @idatom and NameType = 1)

						UPDATE [tblCompanies] set RegisteredNameLocal = @SubjectNativeName, CompanyRegisteredLocalNameIntelligenceId = @IntelligenceID,	
						CompanyRegisteredLocalNameSourceId = @SourceID
						where idatom = @idatom
						
					end

				END


			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
		ELSE
		BEGIN
				
			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom	

			UPDATE tblcompanies set RegisteredNameLocal = @SubjectNativeName, CompanyRegisteredLocalNameSourceId = @SourceID, CompanyRegisteredLocalNameIntelligenceId = @IntelligenceID, 
			DateUpdate = GETDATE()
			where idatom = @idatom
				
		END
		
		-------------[NameLocal]
		IF((SELECT [NameLocal] from tblcompanies where idatom = @idatom) is not null and @SubjectNativeName IS NOT NULL)
		BEGIN
			
			declare @CrisNameLocal nvarchar(250);
			set @CrisNameLocal= (SELECT [NameLocal] from tblcompanies where idatom = @idatom)
			set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompaniesNameSourceId=s.ID  where idatom = @idatom and c.[NameLocal] is not null),12)
			set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompaniesNameIntelligenceId=s.ID where idatom = @idatom and c.[NameLocal] is not null),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN

					UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

					UPDATE tblCompanies set DateUpdate = GETDATE()	where IDATOM=@idatom

					if(replace(replace(replace(replace(replace(replace(replace(@CrisNameLocal,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N'') != 
						replace(replace(replace(replace(replace(replace(replace(@SubjectNativeName,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N''))
					begin

						INSERT INTO tblCompanies_Names(idatom, NameType,Name, IsHistory, DateUpdated, [IntelligenceID],[SourceID])
						SELECT DISTINCT @idatom, 1,@CrisNameLocal, 1,GETDATE(),@IntelligenceID,@SourceID 
						where 
						@CrisNameLocal not in (select [Name] from tblCompanies_Names where idatom = @idatom and NameType = 1)

						UPDATE [tblCompanies] set [NameLocal] = @SubjectNativeName, CompaniesNameIntelligenceId = @IntelligenceID,	CompaniesNameSourceId = @SourceID
						where idatom = @idatom
						

					end

				END


			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
		ELSE
		BEGIN
				
			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom	

			UPDATE tblcompanies set [NameLocal] = @SubjectNativeName, CompaniesNameSourceId = @SourceID, CompaniesNameIntelligenceId = @IntelligenceID, DateUpdate = GETDATE()
			where idatom = @idatom
				
		END

		-------------[ShortName]
		--IF((SELECT ShortName from tblcompanies where idatom = @idatom) is not null and @COMPANYSHORTNAME IS NOT NULL)
		--BEGIN
			
		--	declare @CrisShortName nvarchar(250);
		--	set @CrisShortName= (SELECT ShortName from tblcompanies where idatom = @idatom)
		--	set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompaniesNameSourceId=s.ID  where idatom = @idatom and c.ShortName is not null),12)
		--	set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompaniesNameIntelligenceId=s.ID where idatom = @idatom and c.ShortName is not null),7)
		--	set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

		--	IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
		--	BEGIN

		--			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

		--			UPDATE tblCompanies set DateUpdate = GETDATE()	where IDATOM=@idatom

		--			if(replace(replace(replace(replace(replace(replace(replace(@CrisShortName,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N'') != 
		--				replace(replace(replace(replace(replace(replace(replace(@COMPANYSHORTNAME,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N''))
		--			begin

		--				INSERT INTO tblCompanies_Names(idatom, NameType,Name, IsHistory, DateUpdated, [IntelligenceID],[SourceID])
		--				SELECT DISTINCT @idatom, 1,@CrisShortName, 1,GETDATE(),@IntelligenceID,@SourceID 
		--				where 
		--				@CrisShortName not in (select [Name] from tblCompanies_Names where idatom = @idatom and NameType = 1)

		--				UPDATE [tblCompanies] set ShortName = @COMPANYSHORTNAME, CompaniesNameIntelligenceId = @IntelligenceID,	CompaniesNameSourceId = @SourceID
		--				where idatom = @idatom
						

		--			end

		--		END


		--	set @DTSourceID = NULL
		--	set @DTIntelligenceID = NULL
		--	set @DTRanking = NULL

		--END
		--ELSE
		--BEGIN
				
		--	UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom	

		--	UPDATE tblcompanies set ShortName = @COMPANYSHORTNAME, CompanyShortNameSourceId = @SourceID, CompanyShortNameIntelligenceId = @IntelligenceID, DateUpdate = GETDATE()
		--	where idatom = @idatom
				
		--END

		---------------[Name]
		--IF((SELECT ShortNameLocal from tblcompanies where idatom = @idatom) is not null and @COMPANYSHORTNAMELOCAL IS NOT NULL)
		--BEGIN
			
		--	declare @CrisShortNameLocal nvarchar(250);
		--	set @CrisShortNameLocal= (SELECT ShortNameLocal from tblcompanies where idatom = @idatom)
		--	set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompaniesNameSourceId=s.ID  where idatom = @idatom and c.ShortNameLocal is not null),12)
		--	set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompaniesNameIntelligenceId=s.ID where idatom = @idatom and c.ShortNameLocal is not null),7)
		--	set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

		--	IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
		--	BEGIN

		--			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

		--			UPDATE tblCompanies set DateUpdate = GETDATE()	where IDATOM=@idatom

		--			if(replace(replace(replace(replace(replace(replace(replace(@CrisShortNameLocal,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N'') != 
		--				replace(replace(replace(replace(replace(replace(replace(@COMPANYSHORTNAMELOCAL,N'-',N''),N'?',N''),N'.',N''),N'/',N''),N'&',N''),N'ه ',N'ة '),N' ',N''))
		--			begin

		--				INSERT INTO tblCompanies_Names(idatom, NameType,Name, IsHistory, DateUpdated, [IntelligenceID],[SourceID])
		--				SELECT DISTINCT @idatom, 1,@CrisShortNameLocal, 1,GETDATE(),@IntelligenceID,@SourceID 
		--				where 
		--				@CrisShortNameLocal not in (select [Name] from tblCompanies_Names where idatom = @idatom and NameType = 1)

		--				UPDATE [tblCompanies] set ShortNameLocal = @COMPANYSHORTNAMELOCAL, CompanyShortLocalNameIntelligenceId = @IntelligenceID,
		--				CompanyShortLocalNameSourceId = @SourceID
		--				where idatom = @idatom
						

		--			end

		--		END


		--	set @DTSourceID = NULL
		--	set @DTIntelligenceID = NULL
		--	set @DTRanking = NULL

		--END
		--ELSE
		--BEGIN
				
		--	UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom	

		--	UPDATE tblcompanies set ShortNameLocal = @COMPANYSHORTNAMELOCAL, CompanyShortLocalNameSourceId = @SourceID, CompanyShortLocalNameIntelligenceId = @IntelligenceID, DateUpdate = GETDATE()
		--	where idatom = @idatom
				
		--END
		
		-----------[DateIncorporation]
		IF((SELECT DateIncorporation from tblcompanies where idatom = @idatom) is not null and @DATEREGISTERED IS NOT NULL)
		BEGIN
			
			declare @CrisDateRegistered date;
			set @CrisDateRegistered= (SELECT DateIncorporation from tblcompanies where idatom = @idatom)
			set @DTSourceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsSources s on c.CompaniesDateSourceId=s.ID  where idatom = @idatom and c.DateIncorporation is not null),12)
			set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblcompanies c join tblRecordsIntelligence s on c.CompaniesDateIntelligenceId=s.ID where idatom = @idatom and c.DateIncorporation is not null),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			--print @DTRanking
			--print @RankingID

			--print @CrisDateRegistered 
			--print @DATEREGISTERED

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN

					UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM=@idatom				

					IF(@CrisDateRegistered != @DATEREGISTERED)
					begin
						UPDATE [tblCompanies] set DateUpdate = GETDATE(),
						DateIncorporation = @DATEREGISTERED, CompaniesDateIntelligenceId = @IntelligenceID,	
						CompaniesDateSourceId = @SourceID
						where idatom = @idatom				

					end

				END
			if(
				(select datestart from tblatoms where idatom = @idatom) is not null 
				and @DATESTARTED is not null
				and (select datestart from tblatoms where idatom = @idatom) <> @DATESTARTED
			)
			begin
					update tblatoms set datestart = @DATESTARTED where IDATOM = @idatom
			end

			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
		ELSE
		BEGIN
				
			UPDATE tblAtoms set DateUpdated = GETDATE() where IDATOM = @idatom	

			UPDATE tblcompanies set DateIncorporation = @CrisDateRegistered, CompaniesDateSourceId = @SourceID, CompaniesDateIntelligenceId = @IntelligenceID, DateUpdate = GETDATE()
			where idatom = @idatom
			
			if((select datestart from tblatoms where idatom = @idatom) is not null and @DATESTARTED is not null
			and (select datestart from tblatoms where idatom = @idatom) <> @DATESTARTED)
			begin
					update tblatoms set datestart = @DATESTARTED where IDATOM = @idatom
			end

		END
		
		
		----------------------------------------------------- TradingNames
		
		-----ADD A CURSOR TO LOOP OVER THE ADDRESSES TABLE

		IF(SELECT COUNT(*) from #TradingNames)>0
		BEGIN
			;WITH LatestTradingNames AS (
				SELECT
					tn.ID,
					tn.[Name],
					tn.IsNative,
					tn.IsHistory,
					tn.STARTDATE,
					tn.ENDDATE,
					ROW_NUMBER() OVER (PARTITION BY tn.[Name] ORDER BY tn.ID DESC) AS rn
				FROM #TradingNames tn WITH (NOLOCK)
			)
			UPDATE cn
				SET cn.DateUpdated = GETDATE(),
					cn.SourceId = @SourceID,
					cn.IntelligenceId = @IntelligenceID,
					cn.IsHistory = tn.IsHistory,
					cn.NameType = tn.IsNative,
					cn.StartDate = tn.STARTDATE,
					cn.EndDate = tn.STARTDATE
			FROM tblcompanies_names cn
			JOIN LatestTradingNames tn
				ON tn.rn = 1
			   AND cn.IDATOM = @idatom
			   AND cn.[Name] = tn.[Name];

			;WITH LatestTradingNames AS (
				SELECT
					tn.ID,
					tn.[Name],
					tn.IsNative,
					tn.IsHistory,
					tn.STARTDATE,
					tn.ENDDATE,
					ROW_NUMBER() OVER (PARTITION BY tn.[Name] ORDER BY tn.ID DESC) AS rn
				FROM #TradingNames tn WITH (NOLOCK)
			)
			INSERT INTO tblcompanies_names(idatom, NameType,Name, Intelligenceid, Sourceid, isHistory,DateUpdated, ReportedDate,startDate,EndDate)
			SELECT DISTINCT
				@idatom,
				tn.IsNative,
				tn.[Name],
				@IntelligenceID as IntelligenceID,
				@SourceID as SourceID,
				tn.IsHistory,
				GETDATE(),
				GETDATE(),
				tn.STARTDATE,
				tn.ENDDATE
			FROM LatestTradingNames tn
			WHERE tn.rn = 1					
			  AND NOT EXISTS (
				SELECT 1
				FROM tblcompanies_names cn
				WHERE cn.IDATOM = @idatom
				  AND cn.[Name] = tn.[Name]
			);
		END
		
		set @DTSourceID = NULL
		set @DTIntelligenceID = NULL
		set @DTRanking = NULL
		
	------------------------------------------------------- Legal Form Update -------------------------------------------------------

		IF((SELECT COUNT(*) from [tblCompanies2Types] where idatom = @idatom)>0 and (select count(*) from #LEGALFORMINFO where idtype is not null)>0)
		BEGIN
    print 'Legal Form START'
			set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from [tblCompanies2Types] c join tblRecordsSources s on c.SourceID=s.ID 
			where idatom = @idatom and IdType is not null and ISNULL(IsHistory,0)=0),12)
			set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from [tblCompanies2Types] c join tblRecordsIntelligence s on c.IntelligenceID=s.ID 
			where idatom = @idatom and IdType is not null and ISNULL(IsHistory,0)=0),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			--IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
			--BEGIN	
				
					--if(legalform is json different than database)
					IF(
						(select top 1 idtype from [tblCompanies2Types] where idatom = @idatom and isnull(IsHistory,0) = 0) <>
						(select idtype from #LEGALFORMINFO where idtype is not null and IsHistory = 0)
					)
					BEGIN

						UPDATE [tblCompanies2Types] set DateUpdated = getdate(),SourceID = @SourceID,IntelligenceID = @IntelligenceID, IsHistory = 1
						where idatom = @idatom and ISNULL(IsHistory,0)=0
            print 'legal form DIFF'
						INSERT INTO tblCompanies2Types(IDATOM, IdType, DateUpdated, DateReported, ShowInReport, IntelligenceID, SourceID, IsHistory)
						SELECT DISTINCT @idatom, ci.IdType,getdate() UpdatedDate,getdate(),1,@IntelligenceID,@SourceID,0
						from #LEGALFORMINFO ci 
						where ci.idtype is not null

					END
					ELSE
					BEGIN
            print 'legal form SAME - DATE UPDATED'
						UPDATE [tblCompanies2Types] set DateUpdated = getdate(),SourceID = @SourceID,IntelligenceID = @IntelligenceID	
						where idatom = @idatom and  ISNULL(IsHistory,0)=0

					END

				--END

		set @DTSourceID = NULL
		set @DTIntelligenceID = NULL
		set @DTRanking = NULL

		END
		ELSE
		BEGIN
			IF ((select count(*) from #LEGALFORMINFO where idtype is not null)>0) 
				INSERT INTO tblCompanies2Types(idatom, IdType , DateReported, DateUpdated, showinreport, SourceID, IntelligenceID)
				SELECT DISTINCT @idatom,ci.IdType ,getdate(), getdate(),1,@SourceID,@IntelligenceID
				from #LEGALFORMINFO ci 
				where IdType is not null

		END
		
		------------------- Registers -------------------	
	--   IF(SELECT COUNT(*) from #REGISTERS)>0
	--   BEGIN

	--	IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
	--	BEGIN
	--		DEALLOCATE cur_FormerData_Transfer
	--	END
	--	DECLARE @RegisterNo BIGINT
	--	DECLARE cur_FormerData_Transfer CURSOR FOR

	--	SELECT REGISTERNUMBER
	--	FROM #REGISTERS WITH(NOLOCK)
		
	--		OPEN cur_FormerData_Transfer
	--		FETCH NEXT FROM cur_FormerData_Transfer INTO @RegisterNo
	--		WHILE @@FETCH_STATUS = 0
	--		BEGIN


	--	IF((SELECT count(tblcompanyids.Id) from tblcompanyids where idatom = @idatom and Number=@RegisterNo)>0)
	--	BEGIN

	--		set @DTSourceID = ISNULL((SELECT TOP 1 s.[Rank] from tblcompanyids c join tblRecordsSources s on c.SourceID=s.ID  where idatom = @idatom and c.Number=@RegisterNo),12)
	--		set @DTIntelligenceID = ISNULL((SELECT TOP 1 s.[Rank] from tblcompanyids c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  where idatom = @idatom and c.Number=@RegisterNo ),7)
	--		set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

	--		IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
	--		BEGIN	

	--				update tblcompanyids set IdStatus = ci.idStatus,DateUpdated=GETDATE(),SourceID=@SourceID,IntelligenceID=@IntelligenceID,
	--				IssueDate=REGISTERISSUEDATE,ExpiryDate=REGISTEREXPIRYDATE,[Name]=ci.NAME,NativeTradingName=ci.NATIVETRADEINGNAME,IdType=REGISTERMAINID
	--				FROM #REGISTERS ci 
	--				where 
	--				@idatom is not null 
	--				and ci.idStatus is not null
	--				And tblcompanyids.idorganisation = ci.REGISTERTYPEID 
	--				and tblcompanyids.IdRegister = REGISTERNAMEID
	--				and @idatom = tblcompanyids.IDATOM
	--				and tblcompanyids.Number = @RegisterNo	

	--		END

	--	END

	--	ELSE
	--	BEGIN

	--				---Main IDs
	--				INSERT INTO tblcompanyids(idatom, idorganisation, idregister, Number, IdType, IdStatus, IdCountry, DateUpdated, DateReported,ShowInreport, IntelligenceId, SourceID,
	--				issueDate,ExpiryDate)
	--				SELECT DISTINCT @IDATOM, REGISTERTYPEID, REGISTERNAMEID,REGISTERNUMBER,REGISTERMAINID,idStatus,@CountryID, GETDATE(),GETDATE(),1,@IntelligenceID,@SourceID,
	--				cast(REGISTERISSUEDATE as date),cast(REGISTEREXPIRYDATE as date)
	--				from #REGISTERS r
	--				where @idatom is not null
	--				and REGISTERNUMBER NOT IN (SELECT Number from tblcompanyids c where c.IDATOM=@idatom and c.IdOrganisation=r.REGISTERTYPEID and c.IdRegister=r.REGISTERNAMEID)							
				
	--	END
	
	--		set @RegisterNo = null;
	--		set @DTSourceID = NULL
	--		set @DTIntelligenceID = NULL
	--		set @DTRanking = NULL

	--	FETCH NEXT FROM cur_FormerData_Transfer INTO @RegisterNo
	
	--END

	--END

	
		------------------- Status -------------------
		if((SELECT COUNT(id) from tblCompanies2Status where idatom = @idatom) =0 and (select count(*) from #STATUS where idStatus is not null)>0)
		begin
				INSERT INTO tblCompanies2Status(IDatom,IdStatus,DateUpdated,DateReported,ShowInReport,IntelligenceID,SourceID,DateStart)
				SELECT DISTINCT @idatom,m.IdStatus,getdate(),getdate(),1,@IntelligenceID,@SourceID,cast(@DATESTARTED as date)
				FROM #STATUS m
		end
		else
		IF((SELECT COUNT(id) from tblCompanies2Status where idatom = @idatom)>0 and (select count(*) from #STATUS where idStatus is not null)>0)
		BEGIN

			set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Status c join tblRecordsSources s on c.SourceID=s.ID 
			where idatom = @idatom and IdStatus is not null and isnull(IsHistory,0)=0),12)
			set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Status c join tblRecordsIntelligence s on c.IntelligenceID=s.ID 
			where idatom = @idatom and IdStatus is not null and isnull(IsHistory,0)=0),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN	

				if(SELECT IdStatus from tblCompanies2Status where idatom = @idatom and isnull(IsHistory,0)=0) <> (select idStatus from #STATUS where idStatus is not null)
					begin
						UPDATE tblCompanies2Status set DateUpdated = getdate(),SourceID = @SourceID,IntelligenceID = @IntelligenceID, IsHistory = 1
						--,DateStart=IIF(DateStart IS NULL, CAST(@DATESTARTED AS date), NULL)		--Added on 27/01/2026 by Vivek
						where idatom = @idatom and ISNULL(IsHistory,0)=0

						INSERT INTO tblCompanies2Status(IDATOM, idStatus, DateUpdated, DateReported, ShowInReport, IntelligenceID, SourceID, IsHistory,DateStart)
						SELECT DISTINCT @idatom, ci.idStatus,getdate() UpdatedDate,getdate(),1,@IntelligenceID,@SourceID,0,cast(@DATESTARTED as date)
						from #STATUS ci 
						where
						ci.idStatus IS NOT NULL 

					END
				end
				else
				begin
					UPDATE tblCompanies2Status set DateUpdated = getdate(),SourceID = @SourceID,IntelligenceID = @IntelligenceID,
					DateStart=IIF(DateStart IS NULL, CAST(@DATESTARTED AS date), NULL)		--Added on 27/01/2026 by Vivek
						where idatom = @idatom and ISNULL(IsHistory,0)=0
				end

			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
	
		------------------------------------------------------- Employees -------------------------------------------------------

		-----change to cursor and add a condition for the number 
		IF(SELECT COUNT(*) from #NUMBEROFEMPLOYEES)>0
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM tblCompanies_Employees e
				JOIN #NUMBEROFEMPLOYEES n
					ON n.[Year] = e.[Year]
				LEFT JOIN tblRecordsSources rs
					ON e.SourceID = rs.ID
				LEFT JOIN tblRecordsIntelligence ri
					ON e.IntelligenceID = ri.ID
				LEFT JOIN tblRecordsSIranking r
					ON r.[Source] = COALESCE(rs.[Rank], 12)
				   AND r.[Intelligence] = COALESCE(ri.[Rank], 7)
				WHERE e.IDATOM = @idatom
				  AND n.NumberFrom IS NOT NULL
				  AND r.Ranking >= @RankingID
				  AND ISNULL(e.TotalNumberFrom, -1) < n.NumberFrom
			)
			BEGIN
				UPDATE tblCompanies_Employees
					SET UpdatedDate = getdate(),
						SourceID = @SourceID,
						IntelligenceID = @IntelligenceID
				where idatom = @idatom;	
			END

			;WITH Existing AS (
				SELECT
					e.IDATOM,
					e.[Year],
					e.TotalNumberFrom,
					COALESCE(rs.[Rank], 12) AS SourceRank,
					COALESCE(ri.[Rank], 7) AS IntelligenceRank
				FROM tblCompanies_Employees e
				LEFT JOIN tblRecordsSources rs ON e.SourceID = rs.ID
				LEFT JOIN tblRecordsIntelligence ri ON e.IntelligenceID = ri.ID
				WHERE e.IDATOM = @idatom
			),
			Ranked AS (
				SELECT
					ex.*,
					r.Ranking
				FROM Existing ex
				LEFT JOIN tblRecordsSIranking r
					ON r.[Source] = ex.SourceRank
				   AND r.[Intelligence] = ex.IntelligenceRank
			)
			UPDATE e
				set TotalNumberFrom = NumberFrom
			from #NUMBEROFEMPLOYEES ci
			join tblCompanies_Employees e WITH(NOLOCK) on @idatom=e.IDATOM and e.Year=ci.Year
			join Ranked r on r.IDATOM = e.IDATOM and r.[Year] = e.[Year]
			where NumberFrom is not null
			  and r.Ranking >= @RankingID
			  and ISNULL(e.TotalNumberFrom, -1) < ci.NumberFrom;

			INSERT INTO tblCompanies_Employees(idatom,TotalNumberFrom,[Year],ReportedDate,UpdatedDate,ShowInReport, 
			SourceID, IntelligenceID)
			SELECT DISTINCT @idatom, REPLACE(NumberFrom,',',''), [YEAR], getdate(), getdate() UpdatedDate, 1,@SourceID,@IntelligenceID
			from #NUMBEROFEMPLOYEES ci
			where NumberFrom is not null
			and @idatom NOT IN (SELECT IdAtom from tblCompanies_Employees e where e.IDATOM=@idatom and e.[Year]=ci.[Year])
		END
		
		set @DTSourceID = NULL
		set @DTIntelligenceID = NULL
		set @DTRanking = NULL
	
		------------------- Capital -------------------	
		IF((SELECT COUNT(*) from tblCompanies_Capital where idatom = @idatom)>0 and (select count(*) from #CAPITAL)>0)
		BEGIN
			
			set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Capital c join tblRecordsSources s on c.SourceID=s.ID where idatom = @idatom and ISNULL(IsHistory,0)=0),12)
			set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Capital c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  where idatom = @idatom and ISNULL(IsHistory,0)=0),7)
			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					--if(Capital is json different than database)
					IF(
						((select Issued from [tblCompanies_Capital] where idatom = @idatom and isnull(IsHistory,0) = 0) <>
						(select CapitalIssued from #CAPITAL where CapitalIssued is not null)
						OR (select Authorised from [tblCompanies_Capital] where idatom = @idatom and isnull(IsHistory,0) = 0) <>
						(select CapitalAuthorised from #CAPITAL where CapitalAuthorised is not null)
						OR (select PaidUp from [tblCompanies_Capital] where idatom = @idatom and isnull(IsHistory,0) = 0) <>
						(select CapitalPaidUp from #CAPITAL where CapitalPaidUp is not null)
						OR (select Shares from [tblCompanies_Capital] where idatom = @idatom and isnull(IsHistory,0) = 0) <>
						(select NoOfShares from #CAPITAL where NoOfShares is not null)
						--OR (select nominalvalue from [tblCompanies_Capital] where idatom = @idatom and isnull(IsHistory,0) = 0) <>
						--(select ValueOfShare from #CAPITAL where ValueOfShare is not null))
					))
					BEGIN

						UPDATE a set DateUpdated = getdate() , IsHistory = 1 , SourceID = @SourceID,IntelligenceID = @IntelligenceID 
						from tblCompanies_Capital a where a.idatom = @idatom
					
						INSERT INTO tblCompanies_Capital(idatom,shares,Authorised, DateUpdated, ShowInReport,[IdCurrency], IntelligenceID,SourceID,DateReported--,nominalvalue
            )
						SELECT DISTINCT @idatom, CONVERT(DECIMAL(20,4),REPLACE(NoOfShares,',','')),--CONVERT(DECIMAL(20,4),REPLACE(ValueOfShare,',','')),
						CONVERT(DECIMAL(20,4),REPLACE(CapitalAuthorised,',','')),GETDATE() as DateUpdated,1,64,7,12,GETDATE()
						from  #CAPITAL b
					
					END
				

			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

		END
		ELSE
			BEGIN
					
					INSERT INTO tblCompanies_Capital(idatom,Issued,Authorised,PaidUp,Shares, DateUpdated, ShowInReport,[IdCurrency], IntelligenceID,SourceID,DateReported--NominalValue
          )
					SELECT DISTINCT @idatom,CONVERT(decimal(20,4),CapitalIssued) as Issued,CONVERT(decimal(20,4),CapitalAuthorised) as Authorised,CONVERT(decimal(20,4),CapitalPaidUp) as PaidUp,
					CONVERT(decimal(20,4),NoOfShares) as Shares,
          --CONVERT(decimal(20,4),ValueOfShare) as NominalValue,
          GETDATE() as DateUpdated,1,b.[IdCurrency],7,11,GETDATE()
					from #CAPITAL b
					where 
					(b.CapitalIssued is not null or b.CapitalAuthorised is not null or b.CapitalPaidUp is not null or b.NoOfShares is not null)-- or b.ValueOfShare is not null )
					


			END


		-----------------------------------------------------------------------Premises---------------------------------------------------------------------
		IF((SELECT COUNT(*) from tblPremises where idatom = @idatom)>0 and (select count(*) from #Premises)>0)
		BEGIN

			--set @DTSourceID = (SELECT TOP 1 s.[Rank] from tblPremises c join tblRecordsSources s on c.SourceID=s.ID where idatom = @idatom)
			--set @DTIntelligenceID = (SELECT TOP 1 s.[Rank] from tblPremises c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  where idatom = @idatom)
			--set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			--IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
				
			--	BEGIN	
		
			--		Update a set SourceID = @SourceID, IntelligenceID = @IntelligenceID, DateUpdated = getdate()
			--		from tblPremises a 
			--		join #Premises b on a.idatom = @idatom
			--		where b.idpremisetype = a.idtype and @idatom is not null

			--	END

			--set @DTSourceID = NULL
			--set @DTIntelligenceID = NULL
			--set @DTRanking = NULL

			INSERT INTO tblPremises (IDATOM,IdType,IdStatus,IdCountry,DateUpdated,DateReported,SourceID,IntelligenceID,ShowInReport, IdPremiseType,NumberOfUnits,IdSizeMeasure)
			SELECT DISTINCT @idatom,IdType, idpremisetype, @CountryID, getdate(), getdate(), @SourceID, @IntelligenceID, 1,2951835,Number,LEFT(Size,CHARINDEX(' ',Size))
			FROM #Premises b
			where 
			idtype is not null
			and b.idtype not in (select idtype from tblPremises where idatom = @idatom)
			and Number <> 0

		END
		
		----------------------------------------------------- Activities
		----take queries from ADIP
		IF((select count(*) from #Activities)>0)
		BEGIN
			
			INSERT INTO tblCompanies2Activities(idatom,idstandard, idactivity, DateUpdated, DateReported, IsPrimary,ishistory, showinreport,sourceid, intelligenceid, 
			idSubClassUKSIC, idClassUKSIC, idGroupUKSIC, iddivisionuksic)	
			SELECT DISTINCT @idatom as idatom, 4077413 as idstandard , ActivityID idactivity, getdate() UpdatedDate,GETDATE() as DateReported 
			,IsPrimary as IsPrimary,IsHistory as IsHistory,1 as ShowInReport,@SourceID as SourceId,@IntelligenceID as IntelligenceId, 
			IdSubClassUksic as idSubClassUKSIC, 
			IdClassUksic as idClassUKSIC, 
			IdGroupUksic as idGroupUKSIC, 
			IdDivisionUksic as iddivisionuksic
			FROM #Activities ba	
			where 
			ba.IdSubClassUksic is not null
			and @idatom not in(select idatom from tblCompanies2Activities where idatom = @idatom and idSubClassUKSIC =ba.idSubClassUKSIC)			

			INSERT INTO tblCompanies2Activities(idatom,idstandard, idactivity, DateUpdated, DateReported, IsPrimary,ishistory, showinreport,sourceid, intelligenceid, 
			idSubClassUKSIC, idClassUKSIC, idGroupUKSIC, iddivisionuksic)	
			SELECT DISTINCT @idatom as idatom, 4077413 as idstandard , ActivityID idactivity, getdate() UpdatedDate,GETDATE() as DateReported 
			,IsPrimary as IsPrimary,IsHistory as IsHistory,1 as ShowInReport,@SourceID as SourceId,@IntelligenceID as IntelligenceId, 
			IdSubClassUksic as idSubClassUKSIC, 
			IdClassUksic as idClassUKSIC, 
			IdGroupUksic as idGroupUKSIC, 
			IdDivisionUksic as iddivisionuksic
			FROM #Activities ba	
			where 
			ba.IdClassUksic is not null
			and @idatom not in(select idatom from tblCompanies2Activities where idatom = @idatom and IdClassUksic =ba.IdClassUksic)

			INSERT INTO tblCompanies2Activities(idatom,idstandard, idactivity, DateUpdated, DateReported, IsPrimary,ishistory, showinreport,sourceid, intelligenceid, 
			idSubClassUKSIC, idClassUKSIC, idGroupUKSIC, iddivisionuksic)	
			SELECT DISTINCT @idatom as idatom, 4077413 as idstandard , ActivityID idactivity, getdate() UpdatedDate,GETDATE() as DateReported 
			,IsPrimary as IsPrimary,IsHistory as IsHistory,1 as ShowInReport,@SourceID as SourceId,@IntelligenceID as IntelligenceId, 
			IdSubClassUksic as idSubClassUKSIC, 
			IdClassUksic as idClassUKSIC, 
			IdGroupUksic as idGroupUKSIC, 
			IdDivisionUksic as iddivisionuksic
			FROM #Activities ba	
			where 
			ba.IdGroupUksic is not null
			and @idatom not in(select idatom from tblCompanies2Activities where idatom = @idatom and IdGroupUksic =ba.IdGroupUksic)

			INSERT INTO tblCompanies2Activities(idatom,idstandard, idactivity, DateUpdated, DateReported, IsPrimary,ishistory, showinreport,sourceid, intelligenceid, 
			idSubClassUKSIC, idClassUKSIC, idGroupUKSIC, iddivisionuksic)	
			SELECT DISTINCT @idatom as idatom, 4077413 as idstandard , ActivityID idactivity, getdate() UpdatedDate,GETDATE() as DateReported 
			,IsPrimary as IsPrimary,IsHistory as IsHistory,1 as ShowInReport,@SourceID as SourceId,@IntelligenceID as IntelligenceId, 
			IdSubClassUksic as idSubClassUKSIC, 
			IdClassUksic as idClassUKSIC, 
			IdGroupUksic as idGroupUKSIC, 
			IdDivisionUksic as iddivisionuksic
			FROM #Activities ba	
			where 
			ba.iddivisionuksic is not null
			and @idatom not in(select idatom from tblCompanies2Activities where idatom = @idatom and IdDivisionUksic =ba.IdDivisionUksic)
		
		END
		
	------------------------------------------------------- Financials -------------------------------------------------------
		IF((SELECT COUNT(*) from tblCompanies_Financials where idatom = @idatom)>0 and (select count(*) from #Financials)>0)
		BEGIN

			INSERT INTO tblCompanies_Financials(
			idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo, ImportID)
			SELECT DISTINCT @idatom,IdCurrency,[YEAR],
			CASE WHEN Denomination = 'Standard' THEN 1 
				 WHEN Denomination = 'Thousands' THEN 1000
				 WHEN Denomination = 'Millions' THEN 1000000 ELSE 1 END as Denominator
			,1,1,15,FinancialDate_new,RIGHT(FinancialDate_new,5), getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,MONTHSNO,1696
			from #Financials ci
			where 
				[YEAR] not in(select FinancialYear from tblCompanies_Financials c where c.idatom = @idatom);

			--ATHOS: INSERT INTO tblCompanies_FinancialsAdditional to avoid DESYNC of IDs and violation of primary key.
			INSERT INTO tblCompanies_FinancialsAdditional(
			idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo, ImportID)
			SELECT DISTINCT @idatom,IdCurrency,[YEAR],
			CASE WHEN Denomination = 'Standard' THEN 1 
				 WHEN Denomination = 'Thousands' THEN 1000
				 WHEN Denomination = 'Millions' THEN 1000000 ELSE 1 END as Denominator
			,1,1,15,FinancialDate_new,RIGHT(FinancialDate_new,5), getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,MONTHSNO,1696
			from #Financials ci
			where 
				[YEAR] not in(select FinancialYear from tblCompanies_Financials c where c.idatom = @idatom);


			INSERT INTO tblCompanies_Financials_FieldValues(IdFinancial,IdField,FinancialValue, ImportID)
			SELECT DISTINCT cf.id,ci.IdField,ci.FinancialValue,1696
			from tblCompanies_Financials cf
			join #Financials ci on @idatom = cf.idatom  and FinancialYear=[YEAR] and cf.IsConsolidated=ci.IsConsolidated 
			where 
			ci.FinancialValue is not null and IdField is not null
			and cf.ID NOT IN (SELECT IdFinancial from tblCompanies_Financials_FieldValues f where f.IdFinancial=cf.ID and IdField = ci.IdField)

			INSERT INTO tblCompanies_Financials_FieldValuesAdditional(IdFinancial,IdField,FinancialValue, ImportID)
			SELECT DISTINCT cf.id,ci.IdField,ci.FinancialValue,1696
			from tblCompanies_FinancialsAdditional cf
			join #Financials ci on @idatom = cf.idatom  and FinancialYear=[YEAR] and cf.IsConsolidated=ci.IsConsolidated
			where 
			ci.FinancialValue is not null and IdField is not null
			and cf.ID NOT IN (SELECT IdFinancial from tblCompanies_Financials_FieldValues f where f.IdFinancial=cf.ID and IdField = ci.IdField)
		
		END
		
		----------------------------------------------------- MANAGERSINDIVIDUALS

		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - Managers',getdate(),getdate()) 
		--set @ManagerImportID = SCOPE_IDENTITY()
		--@ManagerUpdateID = 1700

		IF(SELECT COUNT(*) from #MANAGERSINDIVIDUALS)>0
		BEGIN
		
			DECLARE @ManagerImportID_Update INT = null,@PersonIDATOM_update INT,@Manager_IDAddress_Update INT
			
			IF((SELECT COUNT(*) from #MANAGERSINDIVIDUALS where id is not null)>0)
			BEGIN
		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @CRiSNOManager NVARCHAR(500)

		DECLARE cur_FormerData_Transfer CURSOR FOR

		--SELECT CRiSNO
		--FROM #MANAGERSINDIVIDUALS WITH(NOLOCK)
		--where crisNO is not null
		--and MANAGERINDIVIDUALNAME_New not in (SELECT 
		--LTRIM(RTRIM(REPLACE(REPLACE(isnull(FirstName, '')
		--+ ' ' + isnull(MiddleName, '')
		--+ ' ' +  isnull(LastName, ''), '   ', ' '), '  ', ' '))) AS [MANAGER Full Name]    
		--FROM TblPersons p
		--JOIN tblCompanies2Administrators cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  and isnull(IsFormer,0)=0
		--JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDRELATED
		--WHERE ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(isnull(FirstName, '') + ' ' + isnull(MiddleName, '') + ' ' +  isnull(LastName, ''), '   ', ' '), '  ', ' '))) , '') <> ''
		--and cs.IDATOM=@idatom)

		SELECT ID
		FROM #MANAGERSINDIVIDUALS_Main WITH (NOLOCK)
		WHERE EXISTS (
			SELECT 1
			FROM TblPersons p
			JOIN tblCompanies2Administrators cs WITH (NOLOCK)
				ON cs.IDRELATED = p.IDATOM --AND ISNULL(cs.IsFormer, 0) = 0
			WHERE cs.IDATOM = @idatom
			AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#MANAGERSINDIVIDUALS_Main.MANAGERINDIVIDUALNAME_New)))
		)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNOManager
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDRELATED where c.IDATOM=@idatom and aa.[UID] = @CRiSNOManager),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idrelated where c.IDATOM=@idatom and aa.[UID] = @CRiSNOManager),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN		
				
					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IdPosition = IdPosition
					from tblCompanies2Administrators s
					join tblAtoms att on att.IDATOM = s.IDRELATED
					join tblPersons p on p.IDATOM = s.IDRELATED
					join #MANAGERSINDIVIDUALS si on @idatom = att.IDATOM
					where s.idatom = @idatom
					and si.CRiSNO = @CRiSNOManager

				END

				set @CRiSNOManager = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNOManager

		END
		
		END

		IF((SELECT COUNT(*) from #MANAGERSINDIVIDUALS where id is not null)>0)
		BEGIN		

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ManagerID_Update INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #MANAGERSINDIVIDUALS_Main WITH(NOLOCK)
		where NOT EXISTS (
			SELECT 1
			FROM TblPersons p
			JOIN tblCompanies2Administrators cs WITH (NOLOCK)
				ON cs.IDRELATED = p.IDATOM --AND ISNULL(cs.IsFormer, 0) = 0
			WHERE cs.IDATOM = @idatom
			AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#MANAGERSINDIVIDUALS_Main.MANAGERINDIVIDUALNAME_New)))
		)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerID_Update
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),@CountryCode+'P' as CountryCode, GETDATE() as DateCreated, @CountryID as IdRegisteredCountry,1700 as ImportId,ID,1
				from #MANAGERSINDIVIDUALS_Main
				where ID=@ManagerID_Update
			
				SET @PersonIDATOM_update = SCOPE_IDENTITY()

				update #MANAGERSINDIVIDUALS_Main set PersonIDATOM = @PersonIDATOM_update where ID=@ManagerID_Update

				------ execute split SP to split person name 
				EXEC [sp_import_SplitPersonNames_Deep] '#MANAGERSINDIVIDUALS_Main','[MANAGERINDIVIDUALNAME_New]'

				insert into  tblPersons (IDATOM,LastNameLocal,IdLastNamePrefix,
				FirstNameLocal,IdFirstNamePrefix,
				MiddleNameLocal,IdMiddleNamePrefix,
				MiddleNameLocal2,IdMiddleNamePrefix2,
				MiddleNameLocal3,Idmiddlenameprefix3,
				MiddleNameLocal4,Idmiddlenameprefix4,
				MiddleNameLocal5,Idmiddlenameprefix5,
				MiddleNameLocal6,Idmiddlenameprefix6,
				LastName,FirstName,
				MiddleName,MiddleName2,
				MiddleName3,MiddleName4,
				MiddleName5,MiddleName6,
				UpdatedDate,
				[IdNationality],
				IdGender,
				Idtitle,
				IsBO)
				select distinct
				PersonIDATOM, 
				IIF(lastname not like '%[Aa-Zz]%',LastName,null),LastNamePrefix,
				IIF(FirstName not like '%[Aa-Zz]%',FirstName,null),FirstNamePrefix,
				IIF(MiddleName1 not like '%[Aa-Zz]%',MiddleName1,null), MiddlePrefix1,
				IIF(MiddleName2 not like '%[Aa-Zz]%',MiddleName2, NULL), MiddlePrefix2,
				IIF(MiddleName3 not like '%[Aa-Zz]%',MiddleName3, NULL), MiddlePrefix3,
				IIF(MiddleName4 not like '%[Aa-Zz]%',MiddleName4, NULL), MiddlePrefix4,
				IIF(MiddleName5 not like '%[Aa-Zz]%',MiddleName5, NULL), MiddlePrefix5,
				IIF(MiddleName6 not like '%[Aa-Zz]%',MiddleName6, NULL), MiddlePrefix6,
				IIF(lastname like '%[Aa-Zz]%',UPPER(LEFT(LastName,1))+LOWER(SUBSTRING(LastName,2,LEN(LastName))),null),
				IIF(FirstName like '%[Aa-Zz]%',UPPER(LEFT(FirstName,1))+LOWER(SUBSTRING(FirstName,2,LEN(FirstName))) ,null),
				IIF(MiddleName1 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName1,1))+LOWER(SUBSTRING(MiddleName1,2,LEN(MiddleName1))) , NULL),
				IIF(MiddleName2 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName2,1))+LOWER(SUBSTRING(MiddleName2,2,LEN(MiddleName2))) , NULL),
				IIF(MiddleName3 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName3,1))+LOWER(SUBSTRING(MiddleName3,2,LEN(MiddleName3))) , NULL),
				IIF(MiddleName4 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName4,1))+LOWER(SUBSTRING(MiddleName4,2,LEN(MiddleName4))) , NULL),
				IIF(MiddleName5 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName5,1))+LOWER(SUBSTRING(MiddleName5,2,LEN(MiddleName5))) , NULL),
				IIF(MiddleName6 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName6,1))+LOWER(SUBSTRING(MiddleName6,2,LEN(MiddleName6))) , NULL),
				GETDATE() UpdatedDate,
				IdNationality,
				Idgender,
				Idtitle,
				1 IsBO
				from #MANAGERSINDIVIDUALS_Main
				where ID=@ManagerID_Update

				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct @CountryID, 4075976 as [Primary Business Address], 1700, PersonIDATOM
				from #MANAGERSINDIVIDUALS_Main
				where id=@ManagerID_Update

				SET @Manager_IDAddress_Update = SCOPE_IDENTITY()

				print @ManagerID_Update
				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @PersonIDATOM_update, @Manager_IDAddress_Update, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@ManagerID_Update and ImportID=1700
				
				set @ManagerID_Update = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerID_Update
		
		END;

			update #MANAGERSINDIVIDUALS set PersonIDATOM = a.PersonIDATOM 
			from #MANAGERSINDIVIDUALS_Main a 
			where #MANAGERSINDIVIDUALS.MANAGERINDIVIDUALNAME = a.MANAGERINDIVIDUALNAME 

			INSERT INTO tblcompanies2administrators(idatom, idrelated, idposition,ShowInReport, IntelligenceID,SourceID, DateUpdated, DateReported)
			SELECT distinct @idatom, PersonIDATOM,MANAGERIDPOSITION,1,@IntelligenceID,@SourceID,GETDATE(),GETDATE() 
			FROM #MANAGERSINDIVIDUALS
			where @idatom is not null and PersonIdatom is not null and MANAGERIDPOSITION is not null

			UPDATE tblPersons2Languages set IdLanguage=m.IdLanguage
			from #MANAGERSINDIVIDUALS_Main m 
			join tblPersons2Languages on @idatom=tblPersons2Languages.IDATOM

			--select * from #MANAGERSINDIVIDUALS_Main
			--select * from tblcompanies2administrators where IDATOM=@idatom
			--return;

END
END

		--if(the company has shareholder)
			---if json shareholder name IS AVAILBALE in the the shareholders list of the company and S&I > --->update ---cursor should be on #SHAREHOLDERSINDIVIDUALS
			---else do not do anything
		--else ---the company doesnt have any shareholder
			---add the shareholders ---cursor should be on #SHAREHOLDERSINDIVIDUALS_distinct

		----------------------------------------------------- MANAGERCOMPANIES

--		DECLARE @ShareholderCompanyUpdateID INT,@ShareHolderCompanyIdatom_Update iNT
--		set @ShareholderCompanyUpdateID = null
--		--select * from imports order by id desc
--		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - ShareholderCompany',getdate(),getdate()) 
--		--set @ShareholderImportID = SCOPE_IDENTITY()
--		--@ShareholderCompanyUpdateID = 1718

		IF(SELECT COUNT(*) from #MANAGERSCOMPANIES)>0
		BEGIN
		
			DECLARE @ManagerCompanyIdatom INT, @ManagerCompany_IDAddress INT
			
			IF((SELECT COUNT(*) from #MANAGERSCOMPANIES where ID is not null)>0)
			begin

				------cursor start
				IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
				BEGIN
					DEALLOCATE cur_FormerData_Transfer
				END
				DECLARE @CRiSNO_ManagerCompany NVARCHAR(50);
				DECLARE cur_FormerData_Transfer CURSOR FOR

				SELECT ID
				FROM #MANAGERSCOMPANIES 
				where EXISTS (
			    SELECT 1    
				FROM tblCompanies p
				JOIN tblCompanies2Administrators cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  --and isnull(IsFormer,0)=0
				JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDATOM
				WHERE cs.IDATOM=@idatom
				and LOWER(LTRIM(RTRIM(REPLACE(ISNULL(p.RegisteredName, p.Name), '  ', ' ')))) 
				= LOWER(LTRIM(RTRIM(REPLACE(ManagerCompanyName, '  ', ' '))))
				) 
		
				OPEN cur_FormerData_Transfer
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_ManagerCompany
				WHILE @@FETCH_STATUS = 0
				BEGIN

				set @DTSourceID = isnull((SELECT s.[Rank] from tblCompanies2Administrators c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDRELATED where c.IDATOM=@idatom and aa.[UID] = @CRiSNO_ManagerCompany and ISNULL(IsFormer,0)=0),12)
				set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblCompanies2Administrators c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idrelated where c.IDATOM=@idatom and aa.[UID] = @CRiSNO_ManagerCompany and ISNULL(IsFormer,0)=0),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,datestart = si.STARTDATE
					from tblCompanies2Administrators s
					join tblAtoms att on att.IDATOM = s.IDRELATED
					join #MANAGERSCOMPANIES si on @idatom = att.IDATOM
					where s.idatom = @idatom
					and si.ID = @CRiSNO_ManagerCompany

				end

				set @CRiSNO_ManagerCompany = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null

				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_ManagerCompany
				------cursor end
				END
			END
			
			IF((SELECT COUNT(*) from #MANAGERSCOMPANIES where id is not null)>0)
		--	begin

		--	update tblCompanies_OriginalText set Shareholders_Owners = isnull(Shareholders_Owners,'')+char(10)+ 
		--	(isnull((Select STUFF((SELECT 
		--		IIF(ISNULL([SHAREHOLDERSCOMPANYNAME],'')<>'','SHAREHOLDERSCOMPANYNAME : ' + [SHAREHOLDERSCOMPANYNAME] +char(10) ,'')
		--		from #MANAGERSCOMPANIES fd
		--		where @idatom=@idatom
		--		FOR xml path('')),1,0,''))+CHAR(10),''))
		--	from #MANAGERSCOMPANIES a
		--	where @idatom is not null   and CRiSNO=''
		--	and SHAREHOLDERSCOMPANYNAME is not null
		--	and tblCompanies_OriginalText.IDATOM = @idatom
		--END
	
		BEGIN
		
		DECLARE @ManagerCompanyUpdateID INT
		set @ManagerCompanyUpdateID = null

		UPDATE i
		SET i.ManagerCompanyIdatom = x.idatom
		FROM #MANAGERSCOMPANIES_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				ISNULL(com.RegisteredName, com.[Name]) = i.MANAGERCOMPANYNAME
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.MANAGERCOMPANYNAME IS NOT NULL and Idcountry is not null;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END

		DECLARE @ManagerCompanyID INT
		
		-- Cursor to process only unmatched companies using LEFT JOIN
		DECLARE cur_FormerData_Transfer CURSOR FOR
		SELECT i.ID
		FROM #MANAGERSCOMPANIES_Distinct i WITH (NOLOCK)
		LEFT JOIN (
		    SELECT DISTINCT
		        LOWER(LTRIM(RTRIM(REPLACE(ISNULL(p.RegisteredName, p.Name), '  ', ' ')))) COLLATE Latin1_General_CI_AI AS CleanName,
				atoms.IdRegisteredCountry
		    FROM tblCompanies p
		    JOIN tblCompanies2Administrators cs ON cs.IDRELATED = p.IDATOM --AND ISNULL(cs.IsFormer, 0) = 0
			JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDATOM
		    WHERE cs.IDATOM = @idatom 
		) existing ON LOWER(LTRIM(RTRIM(REPLACE(i.MANAGERCOMPANYNAME, '  ', ' ')))) COLLATE Latin1_General_CI_AI = existing.CleanName
		AND existing.IdRegisteredCountry = i.IdCountry  
		WHERE i.ManagerCompanyIdatom IS NULL
		  AND existing.CleanName IS NULL and Idcountry is not null
		  and ManagerCompanyIdatom is null
		
		OPEN cur_FormerData_Transfer
		FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerCompanyID
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		    PRINT 'Inserting new company: ' + CAST(@ManagerCompanyID AS VARCHAR)
		
		    -- Insert into tblAtoms
		    INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
		    SELECT DISTINCT GETDATE(), GETDATE(),
			ca.CountryCode + 'C' AS CountryCode,	
			--@CountryCode + 'C', 
			GETDATE(),
		           ISNULL(IdCountry, @CountryID), 1718, ID, 1
		    FROM #MANAGERSCOMPANIES_Distinct d
			CROSS APPLY (
				    SELECT CountryCode 
				    FROM tblDic_GeoCountries 
				    WHERE Country = d.MANAGERCOMPANYCOUNTRY
				) ca
		    WHERE ID = @ManagerCompanyID
		
		    SET @ManagerCompanyIdatom = SCOPE_IDENTITY()
		
		    -- Update temp table
		    UPDATE #MANAGERSCOMPANIES_Distinct
		    SET ManagerCompanyIdatom = @ManagerCompanyIdatom
		    WHERE ID = @ManagerCompanyID
		
		    -- Insert into tblCompanies
		    INSERT INTO tblCompanies(IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
		                             DateUpdate, IsClient, IsCorrespondent, IsBO,
		                             CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
		                             CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
		                             CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
		                             CompaniesNameIntelligenceId, CompaniesNameSourceId)
		    SELECT DISTINCT @ManagerCompanyIdatom,
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', MANAGERCOMPANYNAME, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', MANAGERCOMPANYNAME, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', MANAGERCOMPANYNAME, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', MANAGERCOMPANYNAME, NULL),
		           GETDATE(), 0, 0, 1,
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @SourceID, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @SourceID, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @SourceID, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @SourceID, NULL)
		    FROM #MANAGERSCOMPANIES_Distinct
		    WHERE ID = @ManagerCompanyID
		
		    -- Insert address
		    INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
		    SELECT DISTINCT ISNULL(IdCountry, @CountryID), 4075976, 1718, @ManagerCompanyIdatom
		    FROM #MANAGERSCOMPANIES_Distinct
		    WHERE ID = @ManagerCompanyID and IdCountry is not null
		
		    SET @ManagerCompany_IDAddress = SCOPE_IDENTITY()
		
		    -- Link address to atom
		    INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
		    SELECT DISTINCT @ManagerCompanyIdatom, @ManagerCompany_IDAddress, 4075976,
		           GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
		    FROM tblAddresses
		    WHERE ID = @ManagerCompany_IDAddress AND ImportID = 1718

			update #MANAGERSCOMPANIES set ManagerCompanyIdatom = a.ManagerCompanyIdatom
			from #MANAGERSCOMPANIES_Distinct a 
			where #MANAGERSCOMPANIES.ManagerCompanyName = a.MANAGERCOMPANYNAME 
			and a.MANAGERCOMPANYCOUNTRY=#MANAGERSCOMPANIES.ManagerCompanyCountry

			insert into tblCompanies2Administrators(idatom, IDRELATED,IdPosition,ShowInReport, IsFormer,IntelligenceID, SourceID, DateReported, DateUpdated,DateStart)
			select distinct @idatom, ManagerCompanyIdatom,ManagerIDPosition,1, 0, @IntelligenceID, @SourceID,getdate(),getdate(),STARTDATE 
			from #MANAGERSCOMPANIES a
			where @idatom is not null and ManagerCompanyIdatom is not null 
			  AND NOT EXISTS (
								SELECT 1
								FROM tblCompanies2Administrators cs
								WHERE cs.IDATOM = @idatom
								AND cs.IDRELATED = a.ManagerCompanyIdatom
								AND ISNULL(cs.IsFormer, 0) = 0
								)
		
		    FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerCompanyID
		END
		
		CLOSE cur_FormerData_Transfer
		DEALLOCATE cur_FormerData_Transfer


			END
		END
--select * from #MANAGERSCOMPANIES
--select * from #MANAGERSCOMPANIES_Distinct

--			return;

			
		----------------------------------------------------- ShareholderIndividual
		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - ShareholderIndividuals',getdate(),getdate()) 
		--set @ShareholderIndividualImportID = SCOPE_IDENTITY()
		--@ShareholderIndividualImportID = 1716

    
		IF(SELECT COUNT(*) from #SHAREHOLDERSINDIVIDUALS)>0
		BEGIN
		
			DECLARE @Shareholderdatom_Update INT,@Shareholder_IDAddress_Update INT;
			
			
			if((SELECT COUNT(*) from #SHAREHOLDERSINDIVIDUALS where  id is not null)>0)
			begin

				------cursor start
				IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
				BEGIN
					DEALLOCATE cur_FormerData_Transfer
				END
				DECLARE @CRiSNO NVARCHAR(50);
				DECLARE cur_FormerData_Transfer CURSOR FOR

				SELECT ID
				FROM #SHAREHOLDERSINDIVIDUALS_Distinct 
				where EXISTS (
			    SELECT 1    
				FROM TblPersons p
				JOIN tblCompanies2Shareholders cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  --and isnull(IsFormer,0)=0
				WHERE cs.IDATOM = @idatom
				AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#SHAREHOLDERSINDIVIDUALS_Distinct.SHAREHOLDERINDIVIDUALNAME_new))))
		
				OPEN cur_FormerData_Transfer
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO
				WHILE @@FETCH_STATUS = 0
				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Shareholders c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDRELATED where c.IDATOM=@idatom and aa.[UID] = @crisNO),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Shareholders c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idrelated where c.IDATOM=@idatom and aa.[UID] = @crisNO),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IsFormer = IsHistory, SharesNumber= si.SharesNumber
										,SharesPercent= si.SHAREHOLDERPERCENTAGE 
										,datestart = si.STARTDATE
					from tblCompanies2Shareholders s
					join tblAtoms att on att.IDATOM = s.IDRELATED
					join #SHAREHOLDERSINDIVIDUALS si on @idatom = att.IDATOM
					where s.idatom = @idatom
					and si.CRiSNO = @CRiSNO

				end

				set @CRiSNO = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null

				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO
				------cursor end
				end
			end
			
			if((SELECT COUNT(*) from #SHAREHOLDERSINDIVIDUALS where id is not null)>0)
			begin


				update #SHAREHOLDERSINDIVIDUALS_Distinct set ShareholderIdatom = m.PersonIdatom
				from #MANAGERSINDIVIDUALS_Main m
				where 
				#SHAREHOLDERSINDIVIDUALS_Distinct.SHAREHOLDERINDIVIDUALNAME = m.MANAGERINDIVIDUALNAME_New
				and #SHAREHOLDERSINDIVIDUALS_Distinct.ShareholderIdatom IS NULL

				IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
				BEGIN
					DEALLOCATE cur_FormerData_Transfer
				END

				DECLARE @ShareholderIndividualID_Update INT;
				DECLARE cur_FormerData_Transfer CURSOR FOR

				SELECT id
				FROM #SHAREHOLDERSINDIVIDUALS_Distinct WITH(NOLOCK)
				where ShareholderIdatom is null
				AND NOT EXISTS (
			    SELECT 1    
				FROM TblPersons p
				JOIN tblCompanies2Shareholders cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  --and isnull(IsFormer,0)=0
				WHERE cs.IDATOM = @idatom
				AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#SHAREHOLDERSINDIVIDUALS_Distinct.SHAREHOLDERINDIVIDUALNAME_new))))
		
					OPEN cur_FormerData_Transfer
					FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderIndividualID_Update
					WHILE @@FETCH_STATUS = 0
					BEGIN

						INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
						SELECT distinct GETDATE(), GETDATE(),@CountryCode+'P' as CountryCode, GETDATE() as DateCreated, isnull(IdCountry, @CountryID) as IdRegisteredCountry,1716 as ImportId,ID,1
						from #SHAREHOLDERSINDIVIDUALS_Distinct
						where ID = @ShareholderIndividualID_Update 
			
						SET @Shareholderdatom_Update = SCOPE_IDENTITY()

						update #SHAREHOLDERSINDIVIDUALS_Distinct set ShareholderIdatom = @Shareholderdatom_Update where ID=@ShareholderIndividualID_Update

						------ execute split SP to split person name 
						EXEC [sp_import_SplitPersonNames_Deep] '#SHAREHOLDERSINDIVIDUALS_Distinct','[SHAREHOLDERINDIVIDUALNAME]'

						insert into  tblPersons (IDATOM,LastNameLocal,IdLastNamePrefix,
						FirstNameLocal,IdFirstNamePrefix,
						MiddleNameLocal,IdMiddleNamePrefix,
						MiddleNameLocal2,IdMiddleNamePrefix2,
						MiddleNameLocal3,Idmiddlenameprefix3,
						MiddleNameLocal4,Idmiddlenameprefix4,
						MiddleNameLocal5,Idmiddlenameprefix5,
						MiddleNameLocal6,Idmiddlenameprefix6,
						LastName,FirstName,
						MiddleName,MiddleName2,
						MiddleName3,MiddleName4,
						MiddleName5,MiddleName6,
						UpdatedDate,
						[IdNationality],
						IsBO)
						select distinct
						@Shareholderdatom_Update, 
						IIF(lastname not like '%[Aa-Zz]%',LastName,null),LastNamePrefix,
						IIF(FirstName not like '%[Aa-Zz]%',FirstName,null),FirstNamePrefix,
						IIF(MiddleName1 not like '%[Aa-Zz]%',MiddleName1,null), MiddlePrefix1,
						IIF(MiddleName2 not like '%[Aa-Zz]%',MiddleName2, NULL), MiddlePrefix2,
						IIF(MiddleName3 not like '%[Aa-Zz]%',MiddleName3, NULL), MiddlePrefix3,
						IIF(MiddleName4 not like '%[Aa-Zz]%',MiddleName4, NULL), MiddlePrefix4,
						IIF(MiddleName5 not like '%[Aa-Zz]%',MiddleName5, NULL), MiddlePrefix5,
						IIF(MiddleName6 not like '%[Aa-Zz]%',MiddleName6, NULL), MiddlePrefix6,
						IIF(lastname like '%[Aa-Zz]%',UPPER(LEFT(LastName,1))+LOWER(SUBSTRING(LastName,2,LEN(LastName))),null),
						IIF(FirstName like '%[Aa-Zz]%',UPPER(LEFT(FirstName,1))+LOWER(SUBSTRING(FirstName,2,LEN(FirstName))) ,null),
						IIF(MiddleName1 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName1,1))+LOWER(SUBSTRING(MiddleName1,2,LEN(MiddleName1))) , NULL),
						IIF(MiddleName2 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName2,1))+LOWER(SUBSTRING(MiddleName2,2,LEN(MiddleName2))) , NULL),
						IIF(MiddleName3 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName3,1))+LOWER(SUBSTRING(MiddleName3,2,LEN(MiddleName3))) , NULL),
						IIF(MiddleName4 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName4,1))+LOWER(SUBSTRING(MiddleName4,2,LEN(MiddleName4))) , NULL),
						IIF(MiddleName5 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName5,1))+LOWER(SUBSTRING(MiddleName5,2,LEN(MiddleName5))) , NULL),
						IIF(MiddleName6 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName6,1))+LOWER(SUBSTRING(MiddleName6,2,LEN(MiddleName6))) , NULL),
						GETDATE() UpdatedDate,
						IdNationality,
						1 IsBO
						from #SHAREHOLDERSINDIVIDUALS_Distinct
						where ID=@ShareholderIndividualID_Update

						INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
						SELECT distinct isnull(IdCountry, @CountryID), 4075976 as [Primary Business Address], 1716, @Shareholderdatom_Update
						from #SHAREHOLDERSINDIVIDUALS_Distinct
						where id=@ShareholderIndividualID_Update
		  
						SET @Shareholder_IDAddress_Update = SCOPE_IDENTITY()

						INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
						SELECT distinct @Shareholderdatom_Update, @Shareholder_IDAddress_Update, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
						FROM  tblAddresses where ID=@ShareholderIndividualID_Update and ImportID=1716
				
						set @ShareholderIndividualID_Update = null;
 
						FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderIndividualID_Update
		
					END;

					update #SHAREHOLDERSINDIVIDUALS set ShareholderIdatom = a.ShareholderIdatom 
					from #SHAREHOLDERSINDIVIDUALS_Distinct a 
					where #SHAREHOLDERSINDIVIDUALS.ShareholderIdatom is null
					and #SHAREHOLDERSINDIVIDUALS.SHAREHOLDERINDIVIDUALNAME = a.SHAREHOLDERINDIVIDUALNAME 
          
					INSERT INTO tblCompanies2Shareholders(idatom, idrelated, ShowInReport,SharesNumber,SharesPercent ,IntelligenceID,SourceID, DateUpdated, DateReported,DateStart,IsFormer)
					SELECT distinct @idatom, ShareholderIdatom,1,CONVERT(DECIMAL(19,4),SHARESNUMBER),CONVERT(DECIMAL(19,4),SHAREHOLDERPERCENTAGE),@IntelligenceID,@SourceID,GETDATE(),GETDATE() ,STARTDATE,IsHistory
					FROM #SHAREHOLDERSINDIVIDUALS
					where 
					ShareholderIdatom is not null and @idatom is not null

					--return;
			end
		end
	
		----------------------------------------------------- SHAREHOLDERSCOMPANIES

--		DECLARE @ShareholderCompanyUpdateID INT,@ShareHolderCompanyIdatom_Update iNT
--		set @ShareholderCompanyUpdateID = null
--		--select * from imports order by id desc
--		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - ShareholderCompany',getdate(),getdate()) 
--		--set @ShareholderImportID = SCOPE_IDENTITY()
--		--@ShareholderCompanyUpdateID = 1717

		IF(SELECT COUNT(*) from #SHAREHOLDERSCOMPANIES)>0
		BEGIN
		
			DECLARE @ShareHolderCompanyIdatom INT, @ShareholderCompany_IDAddress INT
			
			IF((SELECT COUNT(*) from #SHAREHOLDERSCOMPANIES where ID is not null)>0)
			begin

				------cursor start
				IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
				BEGIN
					DEALLOCATE cur_FormerData_Transfer
				END
				DECLARE @CRiSNO_ShareholderCompany NVARCHAR(50);
				DECLARE cur_FormerData_Transfer CURSOR FOR

				SELECT ID
				FROM #SHAREHOLDERSCOMPANIES 
				where EXISTS (
			    SELECT 1    
				FROM tblCompanies p
				JOIN tblCompanies2Shareholders cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  --and isnull(IsFormer,0)=0
				JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDATOM
				WHERE cs.IDATOM=@idatom
				and LOWER(LTRIM(RTRIM(REPLACE(ISNULL(p.RegisteredName, p.Name), '  ', ' ')))) 
				= LOWER(LTRIM(RTRIM(REPLACE(SHAREHOLDERSCOMPANYNAME, '  ', ' '))))
				) 
		
				OPEN cur_FormerData_Transfer
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_ShareholderCompany
				WHILE @@FETCH_STATUS = 0
				BEGIN

				set @DTSourceID = isnull((SELECT s.[Rank] from tblCompanies2Shareholders c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDRELATED where c.IDATOM=@idatom and aa.[UID] = @CRiSNO_ShareholderCompany and ISNULL(IsFormer,0)=0),12)
				set @DTIntelligenceID = isnull((SELECT s.[Rank] from tblCompanies2Shareholders c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idrelated where c.IDATOM=@idatom and aa.[UID] = @CRiSNO_ShareholderCompany and ISNULL(IsFormer,0)=0),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IsFormer = IsHistory, SharesNumber= si.SharesNumber
										,SharesPercent= si.SHAREHOLDERPERCENTAGE 
										,datestart = si.STARTDATE
					from tblCompanies2Shareholders s
					join tblAtoms att on att.IDATOM = s.IDRELATED
					join #SHAREHOLDERSCOMPANIES si on @idatom = att.IDATOM
					where s.idatom = @idatom
					and si.CRiSNO = @CRiSNO_ShareholderCompany

				end

				set @CRiSNO_ShareholderCompany = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null

				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_ShareholderCompany
				------cursor end
				END
			END
			
			IF((SELECT COUNT(*) from #SHAREHOLDERSCOMPANIES where id is not null)>0)
		--	begin

		--	update tblCompanies_OriginalText set Shareholders_Owners = isnull(Shareholders_Owners,'')+char(10)+ 
		--	(isnull((Select STUFF((SELECT 
		--		IIF(ISNULL([SHAREHOLDERSCOMPANYNAME],'')<>'','SHAREHOLDERSCOMPANYNAME : ' + [SHAREHOLDERSCOMPANYNAME] +char(10) ,'')
		--		from #SHAREHOLDERSCOMPANIES fd
		--		where @idatom=@idatom
		--		FOR xml path('')),1,0,''))+CHAR(10),''))
		--	from #SHAREHOLDERSCOMPANIES a
		--	where @idatom is not null   and CRiSNO=''
		--	and SHAREHOLDERSCOMPANYNAME is not null
		--	and tblCompanies_OriginalText.IDATOM = @idatom
		--END
	
		BEGIN
		
		DECLARE @ShareholderCompanyUpdateID INT
		set @ShareholderCompanyUpdateID = null

		--update i set i.ShareHolderCompanyIdatom = com.idatom
		--from tblatoms a (Nolock)
		--join tblCompanies com (Nolock) on com.idatom = a.idatom
		--join #SHAREHOLDERSCOMPANIES_Distinct i (Nolock) on isnull(com.RegisteredName,com.[Name]) = i.SHAREHOLDERSCOMPANYNAME
		--where 
		--a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		--and i.SHAREHOLDERSCOMPANYNAME is not null and Idcountry is not null

		IF OBJECT_ID ('tempdb..#ShareholderCompanyMatches_Update', 'U') IS NOT NULL
		DROP TABLE #ShareholderCompanyMatches_Update;

		CREATE TABLE #ShareholderCompanyMatches_Update (
			ID INT NOT NULL,
			idatom INT NOT NULL,
			DateUpdated DATETIME NOT NULL
		);

		INSERT INTO #ShareholderCompanyMatches_Update (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #SHAREHOLDERSCOMPANIES_Distinct i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName = i.SHAREHOLDERSCOMPANYNAME
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.SHAREHOLDERSCOMPANYNAME IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		INSERT INTO #ShareholderCompanyMatches_Update (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #SHAREHOLDERSCOMPANIES_Distinct i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName IS NULL
			AND com.[Name] = i.SHAREHOLDERSCOMPANYNAME
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.SHAREHOLDERSCOMPANYNAME IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		CREATE INDEX IX_ShareholderCompanyMatches_Update_ID_Date ON #ShareholderCompanyMatches_Update (ID, DateUpdated DESC) INCLUDE (idatom);

		;WITH Ranked AS (
			SELECT
				ID,
				idatom,
				ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DateUpdated DESC) AS rn
			FROM #ShareholderCompanyMatches_Update
		)
		UPDATE i
		SET i.ShareHolderCompanyIdatom = r.idatom
		FROM #SHAREHOLDERSCOMPANIES_Distinct i
		JOIN Ranked r ON r.ID = i.ID AND r.rn = 1;

		IF OBJECT_ID ('tempdb..#ShareholderCompanyMatches_Update', 'U') IS NOT NULL
		DROP TABLE #ShareholderCompanyMatches_Update;

		IF OBJECT_ID ('tempdb..#ShareholderCompanyMatches', 'U') IS NOT NULL
		DROP TABLE #ShareholderCompanyMatches;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END

		DECLARE @ShareholderCompanyID INT
		
		-- Cursor to process only unmatched companies using LEFT JOIN
		DECLARE cur_FormerData_Transfer CURSOR FOR
		SELECT i.ID
		FROM #SHAREHOLDERSCOMPANIES_Distinct i WITH (NOLOCK)
		LEFT JOIN (
		    SELECT DISTINCT
		        LOWER(LTRIM(RTRIM(REPLACE(ISNULL(p.RegisteredName, p.Name), '  ', ' ')))) COLLATE Latin1_General_CI_AI AS CleanName,
				atoms.IdRegisteredCountry
		    FROM tblCompanies p
		    JOIN tblCompanies2Shareholders cs ON cs.IDRELATED = p.IDATOM --AND ISNULL(cs.IsFormer, 0) = 0
			JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDATOM
		    WHERE cs.IDATOM = @idatom 
		) existing ON LOWER(LTRIM(RTRIM(REPLACE(i.SHAREHOLDERSCOMPANYNAME, '  ', ' ')))) COLLATE Latin1_General_CI_AI = existing.CleanName
		AND existing.IdRegisteredCountry = i.IdCountry  
		WHERE i.ShareHolderCompanyIdatom IS NULL
		  AND existing.CleanName IS NULL and Idcountry is not null

		
		OPEN cur_FormerData_Transfer
		FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderCompanyID
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		    PRINT 'Inserting new company: ' + CAST(@ShareholderCompanyID AS VARCHAR)
		
		    -- Insert into tblAtoms
		    INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
		    SELECT DISTINCT GETDATE(), GETDATE(),
			ca.CountryCode + 'C' AS CountryCode,	
			--@CountryCode + 'C', 
			GETDATE(),
		           ISNULL(IdCountry, @CountryID), 1717, ID, 1
		    FROM #SHAREHOLDERSCOMPANIES_Distinct d
			CROSS APPLY (
				    SELECT CountryCode 
				    FROM tblDic_GeoCountries 
				    WHERE Country = d.SHAREHOLDERCOMPANYCOUNTRY
				) ca
		    WHERE ID = @ShareholderCompanyID
		
		    SET @ShareHolderCompanyIdatom = SCOPE_IDENTITY()
		
		    -- Update temp table
		    UPDATE #SHAREHOLDERSCOMPANIES_Distinct
		    SET ShareHolderCompanyIdatom = @ShareHolderCompanyIdatom
		    WHERE ID = @ShareholderCompanyID
		
		    -- Insert into tblCompanies
		    INSERT INTO tblCompanies(IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
		                             DateUpdate, IsClient, IsCorrespondent, IsBO,
		                             CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
		                             CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
		                             CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
		                             CompaniesNameIntelligenceId, CompaniesNameSourceId)
		    SELECT DISTINCT @ShareHolderCompanyIdatom,
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[أ-ي]%', SHAREHOLDERSCOMPANYNAME, NULL),
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[أ-ي]%', SHAREHOLDERSCOMPANYNAME, NULL),
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[A-Za-Z]%', SHAREHOLDERSCOMPANYNAME, NULL),
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[A-Za-Z]%', SHAREHOLDERSCOMPANYNAME, NULL),
		           GETDATE(), 0, 0, 1,
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[أ-ي]%', @IntelligenceID, NULL), IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[أ-ي]%', @SourceID, NULL),
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[أ-ي]%', @IntelligenceID, NULL), IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[أ-ي]%', @SourceID, NULL),
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL), IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[A-Za-Z]%', @SourceID, NULL),
		           IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL), IIF(SHAREHOLDERSCOMPANYNAME LIKE N'%[A-Za-Z]%', @SourceID, NULL)
		    FROM #SHAREHOLDERSCOMPANIES_Distinct
		    WHERE ID = @ShareholderCompanyID
		
		    -- Insert address
		    INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
		    SELECT DISTINCT ISNULL(IdCountry, @CountryID), 4075976, 1717, @ShareHolderCompanyIdatom
		    FROM #SHAREHOLDERSCOMPANIES_Distinct
		    WHERE ID = @ShareholderCompanyID and IdCountry is not null
		
		    SET @ShareholderCompany_IDAddress = SCOPE_IDENTITY()
		
		    -- Link address to atom
		    INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
		    SELECT DISTINCT @ShareHolderCompanyIdatom, @ShareholderCompany_IDAddress, 4075976,
		           GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
		    FROM tblAddresses
		    WHERE ID = @ShareholderCompany_IDAddress AND ImportID = 1717
		
		    FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderCompanyID
		END
		
		CLOSE cur_FormerData_Transfer
		DEALLOCATE cur_FormerData_Transfer

			update #SHAREHOLDERSCOMPANIES set ShareHolderCompanyIdatom = a.ShareHolderCompanyIdatom
			from #SHAREHOLDERSCOMPANIES_Distinct a 
			where #SHAREHOLDERSCOMPANIES.SHAREHOLDERSCOMPANYNAME = a.SHAREHOLDERSCOMPANYNAME 
			and a.SHAREHOLDERCOMPANYCOUNTRY=#SHAREHOLDERSCOMPANIES.SHAREHOLDERCOMPANYCOUNTRY

			insert into tblCompanies2Shareholders(idatom, IDRELATED,SharesPercent,SharesNumber, ShowInReport, IsFormer,IntelligenceID, SourceID, DateReported, DateUpdated,DateStart)
			select distinct @idatom, ShareHolderCompanyIdatom,CONVERT(DECIMAL(19,4),replace(a.SHAREHOLDERPERCENTAGE,'%','')),CONVERT(DECIMAL(19,4),replace(a.SHARESNUMBER,'%','')),
			1, IsHistory, @IntelligenceID, @SourceID,getdate(),getdate(),STARTDATE 
			from #SHAREHOLDERSCOMPANIES a
			where @idatom is not null and ShareHolderCompanyIdatom is not null 
			  AND NOT EXISTS (
								SELECT 1
								FROM tblCompanies2Shareholders cs
								WHERE cs.IDATOM = @idatom
								AND cs.IDRELATED = a.ShareHolderCompanyIdatom
								AND ISNULL(cs.IsFormer, 0) = 0
								)

			--return;
			END
		END

----		----------------------------------------------------- HOLDINGS

----		DECLARE @HoldingCompanyUpdateID INT,@HoldingsIdatom_Update iNT
----		set @HoldingCompanyUpdateID = null
----		--select * from imports order by id desc
----		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - Update - HoldingCompany',getdate(),getdate()) 
----		--set @HoldingCompanyUpdateID = SCOPE_IDENTITY()
----		--@HoldingCompanyUpdateIDD = 1719

		IF(SELECT COUNT(*) from #HOLDINGS)>0
		BEGIN
		
			DECLARE @HoldingIDatom_Update INT,@Holding_IDAddress_Update INT;
			DECLARE @HoldingID_Update INT;
			
			IF((SELECT COUNT(*) from #HOLDINGS where CRiSNBR is not null)>0)
			begin

				------cursor start
				IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
				BEGIN
					DEALLOCATE cur_FormerData_Transfer
				END
				DECLARE @CRiSNO_Holding NVARCHAR(50);
				DECLARE cur_FormerData_Transfer CURSOR FOR

				SELECT CRiSNBR
				FROM #HOLDINGS 
				where [NAME] in (select ISNULL(c.RegisteredName,c.Name)
				from tblCompanies2Shareholders s
				JOIN tblAtoms at on at.IDATOM = s.IDRELATED and ISNULL(at.IsDeleted,0)=0
				JOIN tblCompanies c on c.IDATOM = s.IDRELATED
				where ISNULL(IsDeleted,0)=0 and ShowInReport = 1
				and IdRegisteredCountry = #HOLDINGS.idcountry and s.IDATOM=@idatom)
		
				OPEN cur_FormerData_Transfer
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_Holding
				WHILE @@FETCH_STATUS = 0
				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Shareholders c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDATOM where c.IDRELATED=@idatom and aa.[UID] = @CRiSNO_Holding),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Shareholders c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.IDATOM where c.IDRELATED=@idatom and aa.[UID] = @CRiSNO_Holding),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IsFormer = si.IsFormer, SharesPercent= si.[PERCENTAGE],SharesNumber=si.SHARES
					from tblCompanies2Shareholders s
					join tblAtoms att on att.IDATOM = s.IDATOM
					join #HOLDINGS si on @idatom = att.IDATOM
					where s.IDRELATED = @idatom
					and si.CRiSNBR = @CRiSNO_Holding

				end

				set @CRiSNO_Holding = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null

				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_Holding
				------cursor end
				END
			END

		END

		IF((SELECT COUNT(*) from #HOLDINGS where id is not null)>0)
		begin

		DECLARE @HoldingCompanyUpdateID INT,@HoldingsIdatom_update iNT
		set @HoldingCompanyUpdateID = null
		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - HoldingCompany',getdate(),getdate()) 
		--set @HoldingCompanyImportID = SCOPE_IDENTITY()
		--@HoldingCompanyImportID = 1719
			
		--update i set i.HoldingsIdatom = com.idatom
		--from tblatoms a (Nolock)
		--join tblCompanies com (Nolock) on com.idatom = a.idatom
		--join #HOLDINGS_Distinct i (Nolock) on isnull(com.RegisteredName,com.[Name]) = i.NAME
		--where 
		--a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		--and i.NAME is not null

		UPDATE i
		SET i.HoldingsIdatom = x.idatom
		FROM #HOLDINGS_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				ISNULL(com.RegisteredName, com.[Name]) = i.[Name]
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.[Name] IS NOT NULL;

		DECLARE @HoldingID INT,@HoldingCompany_IDAddress_update INT

		-- Cursor: only new shareholder rows (already excluded existing)
				IF CURSOR_STATUS('global','cur_NewShareholders2')>=-1
				BEGIN
					DEALLOCATE cur_NewShareholders2
				END

		DECLARE cur_NewShareholders2 CURSOR FOR
		SELECT h.ID
		FROM #HOLDINGS_Distinct h WITH (NOLOCK)
		LEFT JOIN (
			SELECT DISTINCT
				LOWER(LTRIM(RTRIM(REPLACE(REPLACE(COALESCE(c.RegisteredName, c.Name), '  ', ' '), CHAR(160), '')))) COLLATE Latin1_General_CI_AI AS CleanName,
				ISNULL(a.UID, '') AS ExistingCRISNO,
				a.IdRegisteredCountry
			FROM tblCompanies2Shareholders s
			JOIN tblCompanies c ON s.IDATOM = c.IDATOM
			JOIN tblAtoms a ON a.IDATOM = s.IDATOM
			WHERE s.IDRELATED = @idatom
			  AND ISNULL(a.IsDeleted, 0) = 0
		) existing ON LOWER(LTRIM(RTRIM(REPLACE(REPLACE(h.[Name], '  ', ' '), CHAR(160), '')))) COLLATE Latin1_General_CI_AI = existing.CleanName
		and existing.IdRegisteredCountry=idcountry
		WHERE 
		  existing.CleanName IS NULL and idcountry is not null

		OPEN cur_NewShareholders2;
		FETCH NEXT FROM cur_NewShareholders2 INTO @HoldingID;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'Processing HoldingID: ' + CAST(@HoldingID AS VARCHAR);

			-- Insert into tblAtoms for the shareholder
			INSERT INTO tblAtoms (DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
			SELECT DISTINCT GETDATE(), GETDATE(), @CountryCode+'C', GETDATE(), IdCountry, 1720, ID, 1
			FROM #HOLDINGS_Distinct
			WHERE ID = @HoldingID;

			SET @HoldingIdatom_Update = SCOPE_IDENTITY();

			-- Update temp table with new AtomID
			UPDATE #HOLDINGS_Distinct
			SET HoldingsIdatom = @HoldingIdatom_Update
			WHERE ID = @HoldingID;

			-- Insert into tblCompanies
			INSERT INTO [tblcompanies] (IDATOM,RegisteredNameLocal,NameLocal,RegisteredName,Name,
						DateUpdate,IsClient,IsCorrespondent,IsBO
						,CompanyRegisteredLocalNameIntelligenceId,CompanyRegisteredLocalNameSourceId
						,CompanyLocalNameIntelligenceId,CompanyLocalNameSourceId,
						CompanyRegisteredNameIntelligenceId,CompanyRegisteredNameSourceId,
						CompaniesNameIntelligenceId,CompaniesNameSourceId
						) 
						SELECT DISTINCT HoldingsIdatom,
						IIF ([NAME] like N'%[أ-ي]%',[NAME],null) as RegisteredNameLocal,
						IIF ([NAME] like N'%[أ-ي]%',[NAME],null) as NameLocal,
						IIF ([NAME] not like N'%[أ-ي]%',[NAME],null) as RegisteredName,
						IIF ([NAME] not like N'%[أ-ي]%',[NAME],null) as Name,
						getdate() UpdatedDate,	
						0,0,1 IsBO
						,IIF ([NAME] like N'%[أ-ي]%',@IntelligenceID, null),IIF ([NAME] like N'%[أ-ي]%',@SourceID, null)
						,IIF ([NAME] like N'%[أ-ي]%',@IntelligenceID, null),IIF ([NAME] like N'%[أ-ي]%',@SourceID, null)	
						,IIF ([NAME] like N'%[A-Za-Z]%',@IntelligenceID, null),IIF ([NAME] like N'%[A-Za-Z]%',@SourceID, null)
						,IIF ([NAME] like N'%[A-Za-Z]%',@IntelligenceID, null),IIF ([NAME] like N'%[A-Za-Z]%',@SourceID, null)
						FROM #HOLDINGS_Distinct
						WHERE ID = @HoldingID;

						INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
						SELECT distinct isnull(Idcountry,@CountryID) Idcountry, 4075976 as [Primary Business Address], 1719, @HoldingsIdatom_update		 
						from #HOLDINGS_Distinct
						where ID = @HoldingID 

						SET @HoldingCompany_IDAddress_update = SCOPE_IDENTITY()

						INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
						SELECT distinct @HoldingsIdatom_update, @HoldingCompany_IDAddress_update, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
						FROM  tblAddresses where ID=@HoldingCompany_IDAddress_update and ImportID=1719

					update #HOLDINGS set HoldingsIdatom = a.HoldingsIdatom
					from #HOLDINGS_Distinct a 
					where #HOLDINGS.HoldingsIdatom is null
					and #HOLDINGS.[NAME] = a.[NAME] 
					and a.[ADDRESS]=#HOLDINGS.[ADDRESS]

					insert into tblCompanies2Shareholders(idatom, IDRELATED,SharesPercent, ShowInReport, IsFormer,IntelligenceID, SourceID, DateReported, DateUpdated)
					select distinct  h.HoldingsIdatom,@idatom,CONVERT(DECIMAL(19,4),replace(h.PERCENTAGE,'%','')),
					1, IsFormer, @IntelligenceID, @SourceID,getdate(),getdate()
					from #HOLDINGS h
					where ID = @HoldingID
					AND @idatom is not null and h.HoldingsIdatom is not null 

					SET @HoldingID = NULL;
					FETCH NEXT FROM cur_NewShareholders2 INTO @HoldingID;
		END

		CLOSE cur_NewShareholders2;
		DEALLOCATE cur_NewShareholders2;
				--select * from #HOLDINGS_Distinct
				--select * from #HOLDINGS

			 -- return;


		END
	--END

----		----------------------------------------------------- DIRECTORSHIPS
		
			DECLARE @DirectorshipIDatom_Update INT,@DirectorshipIDAddress_Update INT;
			DECLARE @DirectorshipID_Update INT;
			
			IF((SELECT COUNT(*) from #DIRECTORSHIPS where id is not null)>0)
			begin

				------cursor start
				IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
				BEGIN
					DEALLOCATE cur_FormerData_Transfer
				END
				DECLARE @CRiSNO_Directorship NVARCHAR(50);
				DECLARE cur_FormerData_Transfer CURSOR FOR

				SELECT ID
				FROM #DIRECTORSHIPS 
				where
				[Name] IN (select COALESCE(c.RegisteredName, c.Name, c.RegisteredNameLocal, c.NameLocal)
				from tblCompanies2Administrators ca 
				join tblCompanies c on ca.IDRELATED = c.IDATOM
				join tblAtoms at on at.IDATOM = ca.IDRELATED
				where IdPosition in (4017659,4017662,4017663,4017664,4017671,4017674,4017679,4017683,4017688,4017691,4017699,4017704,4017738,4017746,4017749,4017775,4017788,4017802,4017803,4017804,4017810
				,4017851,4017856,4017875,4017876,4017877,4017881,4017935,4017937,4017945,4017949,4017964,4017998,4017999,4018012,4018019,4018024,4018028,4018065,4018093,4018095,4018117
				,4076160,4077406,4077952,4077956,4081186,4081748,4081850,4081853,4081856,4081858,4083367,4083418,4084854) and
				ISNULL(IsDeleted,0)=0 and ca.IDRELATED=@idatom
				)
		
				OPEN cur_FormerData_Transfer
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_Directorship
				WHILE @@FETCH_STATUS = 0
				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.idatom where c.IDRELATED=@idatom and aa.[UID] = @CRiSNO_Directorship),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idatom where c.IDRELATED=@idatom and aa.[UID] = @CRiSNO_Directorship),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IsFormer = si.IsFormer, IdPosition= si.IdPosition
					from tblCompanies2Administrators s
					join tblAtoms att on att.IDATOM = s.IDATOM
					join #DIRECTORSHIPS si on @idatom = att.IDATOM
					where s.IDRELATED = @idatom
					and si.CRiSNO = @CRiSNO_Directorship

				end

				set @CRiSNO_Directorship = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null

				FETCH NEXT FROM cur_FormerData_Transfer INTO @CRiSNO_Directorship
				------cursor end
				END
			END
			
			IF((SELECT COUNT(*) from #DIRECTORSHIPS where  id is not null)>0)
			--begin

			--update tblCompanies_OriginalText set Managers = isnull(Managers,'')+char(10)+ 
			--(isnull((Select STUFF((SELECT 
			--	IIF(ISNULL([name],'')<>'','Name : ' + [name] +char(10) ,'')+
			--	IIF(ISNULL([NameLocal],'')<>'','NameLocal : ' + [NameLocal] +char(10) ,'')
			--	from #DIRECTORSHIPS fd
			--	where @idatom=@idatom
			--	FOR xml path('')),1,0,''))+CHAR(10),''))
			--from #DIRECTORSHIPS a
			--where @idatom is not null  and CRiSNO=''  
			--and Name is not null
			--and tblCompanies_OriginalText.IDATOM = @idatom


			--END

--		ELSE
		BEGIN
			
		update i set i.DirectorIdatom = com.idatom
		from tblatoms a (Nolock)
		join tblCompanies com (Nolock) on com.idatom = a.idatom
		join #DIRECTORSHIPS_Distinct i (Nolock) on isnull(com.RegisteredName,com.[Name]) = i.NAME
		where 
		a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		and i.NAME is not null

		UPDATE i
		SET i.DirectorIdatom = x.idatom
		FROM #DIRECTORSHIPS_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				ISNULL(com.RegisteredName, com.[Name]) = i.[Name]
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.[Name] IS NOT NULL and DirectorIdatom is null

		update i set i.DirectorIdatom = com.idatom
		from tblatoms a (Nolock)
		join tblCompanies com (Nolock) on com.idatom = a.idatom
		join #DIRECTORSHIPS_Distinct i (Nolock) on isnull(com.RegisteredNameLocal,com.[NameLocal]) = i.NameLocal
		where 
		a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		and i.NameLocal is not null and DirectorIdatom is null

		UPDATE i
		SET i.DirectorIdatom = x.idatom
		FROM #DIRECTORSHIPS_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				isnull(com.RegisteredNameLocal,com.[NameLocal]) = i.NameLocal
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.[Name] IS NOT NULL and DirectorIdatom is null

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @DirectorIdatom_Update INT,@Directorship_IDAddress_Update INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #DIRECTORSHIPS_Distinct d
		LEFT JOIN (
			SELECT DISTINCT
				LOWER(LTRIM(RTRIM(REPLACE(REPLACE(
					COALESCE(c.RegisteredName, c.Name, c.RegisteredNameLocal, c.NameLocal),
					'  ', ' '), '.', '')))
				) COLLATE Latin1_General_CI_AI AS CleanName
			FROM tblCompanies2Administrators ca
			JOIN tblCompanies c ON ca.IDRELATED = c.IDATOM
			JOIN tblAtoms at ON at.IDATOM = ca.IDRELATED
			WHERE ca.IDATOM = @idatom
		) existing
			ON LOWER(LTRIM(RTRIM(REPLACE(REPLACE(d.[Name], '  ', ' '), '.', ''))))
				COLLATE Latin1_General_CI_AI = existing.CleanName
		WHERE existing.CleanName IS NULL;


OPEN cur_FormerData_Transfer
FETCH NEXT FROM cur_FormerData_Transfer INTO @DirectorshipID_Update

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing: ' + CAST(@DirectorshipID_Update AS VARCHAR)

    INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
    SELECT DISTINCT 
        GETDATE(), GETDATE(), @CountryCode + 'C', GETDATE(), IdCountry, 1720, ID, 1
    FROM #DIRECTORSHIPS_Distinct 
    WHERE ID = @DirectorshipID_Update and IdCountry is not null

    SET @DirectorIdatom_Update = SCOPE_IDENTITY()

    UPDATE #DIRECTORSHIPS_Distinct
    SET DirectorIdatom = @DirectorIdatom_Update
    WHERE ID = @DirectorshipID_Update

    INSERT INTO tblCompanies(
        IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
        DateUpdate, IsClient, IsCorrespondent, IsBO,
        CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
        CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
        CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
        CompaniesNameIntelligenceId, CompaniesNameSourceId
    ) 
    SELECT DISTINCT
        @DirectorIdatom_Update,
        IIF(NameLocal LIKE N'%[أ-ي]%', NameLocal, NULL),
        IIF(NameLocal LIKE N'%[أ-ي]%', NameLocal, NULL),
        IIF([Name] LIKE N'%[A-Za-Z]%', [Name], NULL),
        IIF([Name] LIKE N'%[A-Za-Z]%', [Name], NULL),
        GETDATE(), 0, 0, 1,
        IIF(NameLocal LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
        IIF(NameLocal LIKE N'%[أ-ي]%', @SourceID, NULL),
        IIF(NameLocal LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
        IIF(NameLocal LIKE N'%[أ-ي]%', @SourceID, NULL),
        IIF([Name] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
        IIF([Name] LIKE N'%[A-Za-Z]%', @SourceID, NULL),
        IIF([Name] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
        IIF([Name] LIKE N'%[A-Za-Z]%', @SourceID, NULL)
    FROM #DIRECTORSHIPS_Distinct
    WHERE ID = @DirectorshipID_Update
      AND @DirectorIdatom_Update IS NOT NULL

    INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
    SELECT DISTINCT IdCountry, 4075976, 1720, @DirectorIdatom_Update
    FROM #DIRECTORSHIPS_Distinct
    WHERE ID = @DirectorshipID_Update and IdCountry is not null

    SET @Directorship_IDAddress_Update = SCOPE_IDENTITY()

    INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
    SELECT @DirectorIdatom_Update, @Directorship_IDAddress_Update, 4075976, GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
    FROM tblAddresses 
    WHERE ID = @Directorship_IDAddress_Update AND ImportID = 1720

    -- FINAL FIX: Insert link only for this specific record
    PRINT 'Inserting link: DirectorIdatom = ' + CAST(@DirectorIdatom_Update AS NVARCHAR(20)) 
          + ' -> IDRELATED = ' + CAST(@idatom AS NVARCHAR(20));

    INSERT INTO tblCompanies2Administrators(idatom, idrelated, idposition, ShowInReport, IntelligenceID, SourceID, DateUpdated, DateReported, IsFormer)
    SELECT DISTINCT
        @DirectorIdatom_Update,
        @idatom,
        IdPosition,
        1,
        @IntelligenceID,
        @SourceID,
        GETDATE(),
        GETDATE(),
        IsFormer
    FROM #DIRECTORSHIPS
    WHERE ID = @DirectorshipID_Update       --  only current row
      AND @idatom IS NOT NULL
      AND @DirectorIdatom_Update IS NOT NULL
	  and IdPosition is not null;

    -- Move to next record
    FETCH NEXT FROM cur_FormerData_Transfer INTO @DirectorshipID_Update
END;

CLOSE cur_FormerData_Transfer;
DEALLOCATE cur_FormerData_Transfer;

			--select * from #DIRECTORSHIPS_Distinct
			--return;
--END
END

		----------------------------------------------------- #istoricalManagements

		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - Managers',getdate(),getdate()) 
		--set @ManagerImportID = SCOPE_IDENTITY()
		--@ManagerUpdateID = 1700

		IF(SELECT COUNT(*) from #HistoricalManagements)>0
		BEGIN
		
			DECLARE @HistoryManagerImportID_Update INT = null,@HistoryPersonIDATOM_update INT
			
			IF((SELECT COUNT(*) from #HistoricalManagements where ID is not null and ManagerType='Individual')>0)
			BEGIN
		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ManagerID NVARCHAR(500)

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT ID
		FROM #HistoricalManagements_Main WITH (NOLOCK)
		WHERE ManagerType='Individual' and EXISTS (
			SELECT 1
			FROM TblPersons p
			JOIN tblCompanies2Administrators cs WITH (NOLOCK)
				ON cs.IDRELATED = p.IDATOM AND ISNULL(cs.IsFormer, 0) = 1
			WHERE cs.IDATOM = @idatom
			AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#HistoricalManagements_Main.FullName_New)))
		)
	
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerID
			WHILE @@FETCH_STATUS = 0
			BEGIN
	
				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDRELATED where c.IDATOM=@idatom --and aa.[UID] = @ManagerID
											),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idrelated where c.IDATOM=@idatom --and aa.[UID] = @ManagerID
											),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN		
				
					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IdPosition = IdPosition
					from tblCompanies2Administrators s
					join tblAtoms att on att.IDATOM = s.IDRELATED
					join tblPersons p on p.IDATOM = s.IDRELATED
					--join #HistoricalManagements si on si.CRiSNO = att.[UID]
					where s.idatom = @idatom
					--and si.ID = @ManagerID

				END

				set @ManagerID = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerID

		END
		
		END

		IF((SELECT COUNT(*) from #HistoricalManagements where ID is not null and ManagerType='Individual')>0)
		BEGIN		
		
		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @HistoryManagerID_Update INT,@HistoryManager_IDAddress_Update INT

		--select * from  #HistoricalManagements_Main WITH(NOLOCK)
		--where ManagerType='Individual'

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #HistoricalManagements_Main WITH(NOLOCK)
		where ManagerType='Individual' and  
		NOT EXISTS (
			SELECT 1
			FROM TblPersons p
			JOIN tblCompanies2Administrators cs WITH (NOLOCK)
				ON cs.IDRELATED = p.IDATOM AND ISNULL(cs.IsFormer, 0) = 1
			WHERE cs.IDATOM = @idatom
			AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#HistoricalManagements_Main.FullName_New)))
		)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerID_Update
			WHILE @@FETCH_STATUS = 0
			BEGIN
		
				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),@CountryCode+'P' as CountryCode, GETDATE() as DateCreated, @CountryID as IdRegisteredCountry,1700 as ImportId,ID,1
				from #HistoricalManagements_Main
				where ID=@HistoryManagerID_Update
			
				SET @HistoryPersonIDATOM_update = SCOPE_IDENTITY()


				update #HistoricalManagements_Main set PersonIDATOM = @HistoryPersonIDATOM_update where ID=@HistoryManagerID_Update
				PRINT 'Inserting link: HistoryPersonIDATOM = ' + CAST(@HistoryPersonIDATOM_update AS NVARCHAR(20)) 

				------ execute split SP to split person name 
				EXEC [sp_import_SplitPersonNames_Deep] '#HistoricalManagements_Main','[FullName_New]'

				insert into  tblPersons (IDATOM,LastNameLocal,IdLastNamePrefix,
				FirstNameLocal,IdFirstNamePrefix,
				MiddleNameLocal,IdMiddleNamePrefix,
				MiddleNameLocal2,IdMiddleNamePrefix2,
				MiddleNameLocal3,Idmiddlenameprefix3,
				MiddleNameLocal4,Idmiddlenameprefix4,
				MiddleNameLocal5,Idmiddlenameprefix5,
				MiddleNameLocal6,Idmiddlenameprefix6,
				LastName,FirstName,
				MiddleName,MiddleName2,
				MiddleName3,MiddleName4,
				MiddleName5,MiddleName6,
				UpdatedDate,
				--IdTitle,
				IsBO)
				select distinct
				PersonIDATOM, 
				IIF(lastname not like '%[Aa-Zz]%',LastName,null),LastNamePrefix,
				IIF(FirstName not like '%[Aa-Zz]%',FirstName,null),FirstNamePrefix,
				IIF(MiddleName1 not like '%[Aa-Zz]%',MiddleName1,null), MiddlePrefix1,
				IIF(MiddleName2 not like '%[Aa-Zz]%',MiddleName2, NULL), MiddlePrefix2,
				IIF(MiddleName3 not like '%[Aa-Zz]%',MiddleName3, NULL), MiddlePrefix3,
				IIF(MiddleName4 not like '%[Aa-Zz]%',MiddleName4, NULL), MiddlePrefix4,
				IIF(MiddleName5 not like '%[Aa-Zz]%',MiddleName5, NULL), MiddlePrefix5,
				IIF(MiddleName6 not like '%[Aa-Zz]%',MiddleName6, NULL), MiddlePrefix6,
				IIF(lastname like '%[Aa-Zz]%',UPPER(LEFT(LastName,1))+LOWER(SUBSTRING(LastName,2,LEN(LastName))),null),
				IIF(FirstName like '%[Aa-Zz]%',UPPER(LEFT(FirstName,1))+LOWER(SUBSTRING(FirstName,2,LEN(FirstName))) ,null),
				IIF(MiddleName1 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName1,1))+LOWER(SUBSTRING(MiddleName1,2,LEN(MiddleName1))) , NULL),
				IIF(MiddleName2 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName2,1))+LOWER(SUBSTRING(MiddleName2,2,LEN(MiddleName2))) , NULL),
				IIF(MiddleName3 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName3,1))+LOWER(SUBSTRING(MiddleName3,2,LEN(MiddleName3))) , NULL),
				IIF(MiddleName4 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName4,1))+LOWER(SUBSTRING(MiddleName4,2,LEN(MiddleName4))) , NULL),
				IIF(MiddleName5 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName5,1))+LOWER(SUBSTRING(MiddleName5,2,LEN(MiddleName5))) , NULL),
				IIF(MiddleName6 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName6,1))+LOWER(SUBSTRING(MiddleName6,2,LEN(MiddleName6))) , NULL),
				GETDATE() UpdatedDate,
				--idtitle,
				1 IsBO
				from #HistoricalManagements_Main
				where ID=@HistoryManagerID_Update
			
				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct @CountryID, 4075976 as [Primary Business Address], 1700, PersonIDATOM
				from #HistoricalManagements_Main
				where id=@HistoryManagerID_Update
		  
				SET @HistoryManager_IDAddress_Update = SCOPE_IDENTITY()

				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @HistoryPersonIDATOM_update, @HistoryManager_IDAddress_Update, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@HistoryManagerID_Update and ImportID=1700
				
				set @HistoryManagerID_Update = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerID_Update
		
		END;

			update #HistoricalManagements set PersonIDATOM = a.PersonIDATOM 
			from #HistoricalManagements_Main a 
			where #HistoricalManagements.FullName = a.FullName 

			INSERT INTO tblcompanies2administrators(idatom, idrelated, idposition,ShowInReport, IntelligenceID,SourceID, DateUpdated, DateReported,DateStart,DateEnd,IsFormer)
			SELECT distinct @idatom, PersonIDATOM,MANAGERIDPOSITION,1,@IntelligenceID,@SourceID,GETDATE(),GETDATE(),StartDate,EndDate,1 
			FROM #HistoricalManagements
			where @idatom is not null and PersonIdatom is not null and ManagerIdPosition is not null


			--select * from #HistoricalManagements_Main
			--select * from tblcompanies2administrators where IDATOM=@idatom
			--return;

END
END
		----------------------------------------------------- #istoricalManagements

		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - Update - HistoryManagerCompany',getdate(),getdate()) 
		--set @ManagerImportID = SCOPE_IDENTITY()
		--@ManagerUpdateID = 1700

		IF(SELECT COUNT(*) from #HistoricalManagements)>0
		BEGIN
		
			DECLARE 
			@HistoryCompanyIDATOM_update INT,@Companyidatom_Update INT,@HistoryCompany_IDAddress_Update INT
			
			IF((SELECT COUNT(*) from #HistoricalManagements where ID is not null and ManagerType='Company')>0)
			BEGIN
		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @CompanyManagerID NVARCHAR(500)

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT ID
		FROM #HistoricalManagements_Main WITH (NOLOCK)
		WHERE ManagerType='Company' and EXISTS (
			SELECT 1
			FROM tblCompanies p
			JOIN tblCompanies2Administrators cs WITH (NOLOCK)
				ON cs.IDRELATED = p.IDATOM AND ISNULL(cs.IsFormer, 0) = 1
			WHERE cs.IDATOM = @idatom
			AND LOWER(LTRIM(RTRIM(ISNULL(p.RegisteredName, RegisteredNameLocal)))) 
				= LOWER(LTRIM(RTRIM(ISNULL(#HistoricalManagements_Main.FullName,#HistoricalManagements_Main.FullNameArabic))))
		)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @CompanyManagerID
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsSources s on c.SourceID=s.ID 
											join tblatoms aa on aa.idatom = c.IDRELATED where c.IDATOM=@idatom and aa.[UID] = @CompanyManagerID),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Administrators c join tblRecordsIntelligence s on c.IntelligenceID=s.ID  
											join tblatoms aa on aa.idatom = c.idrelated where c.IDATOM=@idatom and aa.[UID] = @CompanyManagerID),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

			IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
			BEGIN		
				
					update s set DateUpdated = getdate(),SourceId=@SourceID,IntelligenceId=@IntelligenceID
										,IdPosition = IdPosition
					from tblCompanies2Administrators s
					join tblAtoms att on att.IDATOM = s.IDRELATED
					join tblPersons p on p.IDATOM = s.IDRELATED
					--join #HistoricalManagements si on si.CRiSNO = att.[UID]
					where s.idatom = @idatom
					--and si.ID = @ManagerID

				END

				set @CompanyManagerID = null;
				set @DTSourceID = null
				set @DTIntelligenceID = null
				set @DTRanking = null
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @CompanyManagerID

		END
	END	

			IF((SELECT COUNT(*) from #HistoricalManagements_Main where id is not null and ManagerType='Company')>0)
	--		BEGIN

	--		update tblCompanies_OriginalText set Managers = isnull(Managers,'')+char(10)+ 
	--		(isnull((Select STUFF((SELECT 
	--			IIF(ISNULL([FULLNAME],'')<>'','FULLNAME : ' + [FULLNAME] +char(10) ,'')+
	--			IIF(ISNULL([FULLNAMEARABIC],'')<>'','FULLNAMEARABIC : ' + [FULLNAMEARABIC] +char(10) ,'')
	--			from #HistoricalManagements_Main fd
	--			where @idatom=@idatom and  ManagerType='Company'
	--			FOR xml path('')),1,0,''))+CHAR(10),''))
	--		from #HistoricalManagements_Main a
	--		where @idatom is not null and  ManagerType='Company'
	--		and ([FULLNAME] is not null or [FULLNAMEARABIC] is not null)
	--		and tblCompanies_OriginalText.IDATOM = @idatom

	--		END

		BEGIN
			
		IF OBJECT_ID ('tempdb..#HistoryCompanyMatches_Update', 'U') IS NOT NULL
		DROP TABLE #HistoryCompanyMatches_Update;

		CREATE TABLE #HistoryCompanyMatches_Update (
			ID INT NOT NULL,
			idatom INT NOT NULL,
			DateUpdated DATETIME NOT NULL
		);

		INSERT INTO #HistoryCompanyMatches_Update (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #HistoricalManagements_Main i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName = i.FullName
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.ManagerType = 'Company'
		  AND i.FullName IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		INSERT INTO #HistoryCompanyMatches_Update (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #HistoricalManagements_Main i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName IS NULL
			AND com.[Name] = i.FullName
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.ManagerType = 'Company'
		  AND i.FullName IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		CREATE INDEX IX_HistoryCompanyMatches_Update_ID_Date ON #HistoryCompanyMatches_Update (ID, DateUpdated DESC) INCLUDE (idatom);

		;WITH Ranked AS (
			SELECT
				ID,
				idatom,
				ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DateUpdated DESC) AS rn
			FROM #HistoryCompanyMatches_Update
		)
		UPDATE i
		SET i.Companyidatom = r.idatom
		FROM #HistoricalManagements_Main i
		JOIN Ranked r ON r.ID = i.ID AND r.rn = 1
		WHERE i.ManagerType = 'Company';

		IF OBJECT_ID ('tempdb..#HistoryCompanyMatches_Update', 'U') IS NOT NULL
		DROP TABLE #HistoryCompanyMatches_Update;

		----update i set i.Companyidatom = com.idatom
		----from tblatoms a (Nolock)
		----join tblCompanies com (Nolock) on com.idatom = a.idatom
		----join #DIRECTORSHIPS_Distinct i (Nolock) on isnull(com.RegisteredNameLocal,com.[NameLocal]) = i.NameLocal
		----where 
		----a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		----and i.NameLocal is not null and Companyidatom is null

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @HistoryManagerCompany_Update INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #HistoricalManagements_Main d
		LEFT JOIN (
			SELECT DISTINCT
				LOWER(LTRIM(RTRIM(REPLACE(REPLACE(
					COALESCE(c.RegisteredName, c.Name, c.RegisteredNameLocal, c.NameLocal),
					'  ', ' '), '.', '')))
				) COLLATE Latin1_General_CI_AI AS CleanName
			FROM tblCompanies2Administrators ca
			JOIN tblCompanies c ON ca.IDRELATED = c.IDATOM and isnull(IsFormer,0)=1
			JOIN tblAtoms at ON at.IDATOM = ca.IDATOM 
			WHERE ca.IDATOM = @idatom
		) existing
			ON LOWER(LTRIM(RTRIM(REPLACE(REPLACE(d.FullName, '  ', ' '), '.', ''))))
				COLLATE Latin1_General_CI_AI = existing.CleanName
		WHERE existing.CleanName IS NULL and d.ManagerType='Company';


OPEN cur_FormerData_Transfer
FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerCompany_Update

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing: ' + CAST(@HistoryManagerCompany_Update AS VARCHAR)

    INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
    SELECT DISTINCT 
        GETDATE(), GETDATE(), @CountryCode + 'C', GETDATE(), IdCountry, 2656, ID, 1
    FROM #HistoricalManagements_Main
    WHERE ID = @HistoryManagerCompany_Update and IdCountry is not null

    SET @Companyidatom_Update = SCOPE_IDENTITY()

    UPDATE #HistoricalManagements_Main
    SET Companyidatom = @Companyidatom_Update
    WHERE ID = @HistoryManagerCompany_Update

    INSERT INTO tblCompanies(
        IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
        DateUpdate, IsClient, IsCorrespondent, IsBO,
        CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
        CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
        CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
        CompaniesNameIntelligenceId, CompaniesNameSourceId
    ) 
    SELECT DISTINCT
        @Companyidatom_Update,
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', [FullNameArabic], NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', [FullNameArabic], NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', [FullName], NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', [FullName], NULL),
        GETDATE(), 0, 0, 1,
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @SourceID, NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @SourceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @SourceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @SourceID, NULL)
    FROM #HistoricalManagements_Main
    WHERE ID = @HistoryManagerCompany_Update
      AND @Companyidatom_Update IS NOT NULL

    INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
    SELECT DISTINCT IdCountry, 4075976, 2656, @Companyidatom_Update
    FROM #HistoricalManagements_Main
    WHERE ID = @HistoryManagerCompany_Update and IdCountry is not null

    SET @HistoryCompany_IDAddress_Update = SCOPE_IDENTITY()

    INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
    SELECT @Companyidatom_Update, @HistoryCompany_IDAddress_Update, 4075976, GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
    FROM tblAddresses 
    WHERE ID = @HistoryCompany_IDAddress_Update AND ImportID = 2656

    -- FINAL FIX: Insert link only for this specific record
    PRINT 'Inserting link: HistoryCompanyidatom = ' + CAST(@Companyidatom_Update AS NVARCHAR(20)) 
          + ' -> IDRELATED = ' + CAST(@idatom AS NVARCHAR(20));

    INSERT INTO tblCompanies2Administrators(idatom, idrelated, idposition, ShowInReport, IntelligenceID, SourceID, DateUpdated, DateReported, IsFormer)
    SELECT DISTINCT
		@idatom,
        @Companyidatom_Update,
        ManagerIdPosition,
        1,
        @IntelligenceID,
        @SourceID,
        GETDATE(),
        GETDATE(),
        1
    FROM #HistoricalManagements
    WHERE ID = @HistoryManagerCompany_Update       --  only current row
      AND @idatom IS NOT NULL
      AND @Companyidatom_Update IS NOT NULL
	  and ManagerIdPosition is not null;

    -- Move to next record
    FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerCompany_Update
END;

CLOSE cur_FormerData_Transfer;
DEALLOCATE cur_FormerData_Transfer;

			--select * from #HistoricalManagements_Main
			--return;
--END
END

END


		----------------------------------------------------- Addresses

			DECLARE @IdAddress_Update INT
			------------------------------------main address
			if((SELECT IdTown from #Address where IdTown is not null and MAIN=1) is not null)
			begin
				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblAtoms2Addresses c join tblRecordsSources s on c.SourceID=s.ID 
											 join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=1),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblAtoms2Addresses c join tblRecordsIntelligence s on c.GradingID=s.ID  
												join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=1),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	
				
						IF(
						--if both addresses have same town,
						(
						(SELECT IdTown from tblAtoms2Addresses c join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=1)
						=
						(SELECT IdTown from #Address where IdTown is not null and MAIN=1)
						) 
						---or if town is cris is null and towns in json is not null
						or 
						(SELECT IdTown from tblAtoms2Addresses c join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=1) is null)
				
						BEGIN

								update s set DateUpdated = getdate(),SourceId=@SourceID,GradingID=@IntelligenceID
								from tblAtoms2Addresses s
								where s.IDATOM = @idatom and s.IsMain=1

								UPDATE c set idtown = ci.idtown
								from #Address ci	
								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
								join tblAddresses c on a.idaddress = c.id	
								where c.IdTown is null and ci.idtown is not null 
								and ci.Main=1

								UPDATE c set IdArea = ci.IdArea
								from #Address ci	
								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
								join tblAddresses c on a.idaddress = c.id	
								where c.IdArea is null and ci.IdArea is not null 
								and ci.Main=1

								UPDATE c set idstreet = ci.idstreet
								from #Address ci	
								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
								join tblAddresses c on a.idaddress = c.id	
								where c.idstreet is null and ci.idstreet is not null 
								and ci.Main=1

								UPDATE c set idbuilding = ci.idbuilding
								from #Address ci	
								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
								join tblAddresses c on a.idaddress = c.id	
								where c.idbuilding is null and ci.idbuilding is not null 
								and ci.Main=1

								UPDATE c set pobox = ci.pobox
								from #Address ci	
								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
								join tblAddresses c on a.idaddress = c.id	
								where c.pobox is null and ci.pobox is not null 
								and ci.Main=1

								UPDATE c set PostalCode_Postal = ci.POSTALCODE
								from #Address ci	
								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
								join tblAddresses c on a.idaddress = c.id	
								where c.PostalCode_Postal is null and ci.POSTALCODE is not null 
								and ci.Main=1

							END

						
						--else
						IF(
						(SELECT IdTown from tblAtoms2Addresses c join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=1) is not null
						and(
							(SELECT IdTown from tblAtoms2Addresses c join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=1)!=
							(SELECT IdTown from #Address where IdTown is not null and MAIN=1))
						)
						begin
		
							update tblAtoms2Addresses set IsMain=0, IdType=2949878, DateUpdated = getdate() 
							where idatom = @idatom and IsMain = 1

							insert into tbladdresses(idcountry ,showinreport, AddressTypeid, idatom, ImportID ,IdTown,IdArea,IdStreet,IdBuilding,POBox,PostalCode_Postal, BuildingNo)
							SELECT DISTINCT @CountryID, 1, 2949338, @idatom, 1696 importid, IdTown, IdArea,IdStreet,IdBuilding,POBox,PostalCode, BUILDINGNO
							from #Address o
							where MAIN=1
					
							SET @IdAddress_Update = SCOPE_IDENTITY()

							insert into tblatoms2addresses(idatom, idaddress,idtype, DateUpdated, isMain, showinreport, SourceID, GradingID,DateReported)
							select distinct ad.idatom, @IdAddress_Update,2949338,getdate(), 1,1,11 ,7,getdate()
							from tbladdresses ad
							where ad.importid = 1696 and ID=@IdAddress_Update

							update #Contacts set IdAddress = @IdAddress_Update 

							--insert here the contact details from #contact

							UPDATE tblcontacts set atom2addressID = null where atom2addressID is not null

							INSERT INTO tblcontacts(atom2addressID)
							SELECT DISTINCT @idatom
							FROM #Contacts 
							where IdAddress = @IdAddress_Update and (PHONENUMBER is not null OR EMAIL is not null OR WEB is not null)
							and MAIN=1

							UPDATE #Contacts set Idcontact = a.id
							from tblcontacts a
							where 
							@idatom= a.atom2addressID
							and a.atom2addressID is not null
							and IdAddress = @IdAddress_Update and MAIN=1


							--select * from tblAtoms2Addresses where IDATOM = 246435179

							INSERT INTO tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
							SELECT DISTINCT [Idcontact], 2949458, C.PHONENUMBER , getdate() datereported, getdate() UPDATEdDate 
							from #Contacts  C
							where C.PHONENUMBER is not null and [Idcontact] is not null and @idatom is not null and phonetype='Phone' and MAIN=1
							and IdAddress = @IdAddress_Update
	
							insert into tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
							select distinct [IdContact], 2949459, PHONENUMBER, getdate() datereported, getdate() UpdatedDate 
							from #Contacts c
							where PHONENUMBER is not null and [IdContact] is not null and phonetype='Fax'  and MAIN=1
							and IdAddress = @IdAddress_Update

							insert into tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
							select distinct [IdContact], 2949460, PHONENUMBER, getdate() datereported, getdate() UpdatedDate 
							from #Contacts c
							where PHONENUMBER is not null and [IdContact] is not null and phonetype='Mobile'  and MAIN=1
							and IdAddress = @IdAddress_Update

							insert into [tblContacts_Emails](idcontact, [Email], DateReported, DateUpdated) 
							select distinct IdContact, ci.[Email] ,getdate(), getdate() 
							from #Contacts ci
							where ci.[Email] is not null
							and IdContact is not null and ci.[Email] like '%@%' and MAIN=1
							and IdAddress = @IdAddress_Update

							insert into tblContacts_Webs(idcontact, Web, DateReported, DateUpdated)
							select distinct idcontact, REPLACE(REPLACE(ci.WEB,'https://',''),'http://','') ,getdate(), getdate()
							from #Contacts ci
							where ci.WEB is not null
							and IdContact is not null and ci.WEB not like '%@%' and MAIN=1
							and IdAddress = @IdAddress_Update

				
							set @IdAddress_Update = null;
 

							UPDATE tblatoms2addresses set idcontact = q.Idcontact
							from #Contacts  q
							where 
							tblatoms2addresses.idatom = @idatom
							and q.Idcontact is not null 
							and tblatoms2addresses.IdAddress = q.IdAddress and MAIN=1 and IsMain=1

							END

--			IF((SELECT COUNT(*) from #Address where IdTown is not null and MAIN=0) is not null)
--			begin

--	---ADD A CURSOR TO LOOP OVER THE ADDRESSES TABLE
--		DECLARE @IdAddress1 INT;

--		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
--		BEGIN
--			DEALLOCATE cur_FormerData_Transfer
--		END
--		DECLARE @ID1 INT,@idtown INT;
--		DECLARE cur_FormerData_Transfer CURSOR FOR

--		SELECT id,idtown
--		FROM #Address WITH(NOLOCK)
--		where MAIN=0
		
--			OPEN cur_FormerData_Transfer
--			FETCH NEXT FROM cur_FormerData_Transfer INTO @ID1,@idtown
--			WHILE @@FETCH_STATUS = 0
--			BEGIN

--				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblAtoms2Addresses c join tblRecordsSources s on c.SourceID=s.ID 
--											 join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=0 and IdTown=@idtown),12)
--				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblAtoms2Addresses c join tblRecordsIntelligence s on c.GradingID=s.ID  
--												join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=0  and IdTown=@idtown),7)
--				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

--				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
--				BEGIN	
				
--						IF(
--						--if both addresses have same town,
--						(
--						(SELECT IdTown from tblAtoms2Addresses c join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=0 and IdTown=@idtown)
--						=
--						(SELECT IdTown from #Address where IdTown is not null and MAIN=0 and IdTown=@idtown)
--						) 
--						---or if town is cris is null and towns in json is not null
--						or 
--						(SELECT IdTown from tblAtoms2Addresses c join tblAddresses ad on c.IdAddress=ad.id where c.IDATOM=@idatom and ISNULL(ismain,0)=0) is null)
				
--						BEGIN
--							print 'V'
							
--							select *
--								--update s set DateUpdated = getdate(),SourceId=@SourceID,GradingID=@IntelligenceID
--								from tblAtoms2Addresses s
--								where s.IDATOM = @idatom and s.IsMain=0
--								and (SELECT IdTown from tblAddresses a where id=s.IdAddress and @idatom=s.IDATOM and IdTown=@idtown)=@idtown

--								select *
--								--UPDATE c set idtown = ci.idtown
--								from #Address ci	
--								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
--								join tblAddresses c on a.idaddress = c.id	
--								where c.IdTown is null and ci.idtown is not null 
--								and ci.MAIN=0
--								and ci.IdTown=@idtown

--								select *
--								--UPDATE c set IdArea = ci.IdArea
--								from #Address ci	
--								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
--								join tblAddresses c on a.idaddress = c.id	
--								where c.IdArea is null and ci.IdArea is not null 
--								and ci.MAIN=0
--								and ci.IdTown=@idtown

--								select *
--								--UPDATE c set idstreet = ci.idstreet
--								from #Address ci	
--								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
--								join tblAddresses c on a.idaddress = c.id	
--								where c.idstreet is null and ci.idstreet is not null 
--								and ci.MAIN=0
--								and ci.IdTown=@idtown

--								select *
--								--UPDATE c set idbuilding = ci.idbuilding
--								from #Address ci	
--								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
--								join tblAddresses c on a.idaddress = c.id	
--								where c.idbuilding is null and ci.idbuilding is not null 
--								and ci.MAIN=0
--								and ci.IdTown=@idtown

--								select *
--								--UPDATE c set pobox = ci.pobox
--								from #Address ci	
--								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
--								join tblAddresses c on a.idaddress = c.id	
--								where c.pobox is null and ci.pobox is not null 
--								and ci.MAIN=0
--								and ci.IdTown=@idtown

--								select *
--								--UPDATE c set PostalCode_Postal = ci.POSTALCODE
--								from #Address ci	
--								inner join tblAtoms2Addresses a on @idatom =a.idatom and a.IsMain=1
--								join tblAddresses c on a.idaddress = c.id	
--								where c.PostalCode_Postal is null and ci.POSTALCODE is not null 
--								and ci.MAIN=0
--								and ci.IdTown=@idtown

--				set @ID1 = null
--				set @IdAddress1 = null
--				set @idtown=null
 
--				FETCH NEXT FROM cur_FormerData_Transfer INTO @ID1,@idtown

--				END

END

		IF((SELECT COUNT(*) from #Address where IdTown is not null and MAIN=0) is not null)

	---ADD A CURSOR TO LOOP OVER THE ADDRESSES TABLE
		DECLARE @IdAddress2 INT;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ID2 INT;
		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #Address WITH(NOLOCK)
		where MAIN=0
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ID2
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
					INSERT INTO tblAddresses(IdCountry, IdTown, POBox, PostalCode, IdArea,BuildingNo,IdBuilding,ImportID,AddressTypeID,IdStreet)
					SELECT @CountryID,Idtown ,POBOX,POSTALCODE,IdArea,BUILDINGNO,IdBuilding,1696, AddressTypeID,idstreet
					from #Address 
					where id = @ID2

					SET @IdAddress2 = SCOPE_IDENTITY()

					INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
					SELECT @IDATOM, @IdAddress2, AddressTypeID, GETDATE(),GETDATE(),(select [Main] from #Address where id = @ID2),@IntelligenceID,@SourceID,1
					from tblAddresses
					where ImportID = 1696 and id = @IdAddress2

					--select * from tblDic_BaseValues where DummyName = 'Branch Address'
					update #Contacts set IdAddress = @IdAddress2 where IdAddress = @ID2

					--insert here the contact details from #contact

				UPDATE tblcontacts set atom2addressID = null where atom2addressID is not null

				INSERT INTO tblcontacts(atom2addressID)
				SELECT DISTINCT @idatom
				FROM #Contacts 
				where IdAddress = @IdAddress2 and (PHONENUMBER is not null OR EMAIL is not null OR WEB is not null)

				UPDATE #Contacts set Idcontact = a.id
				from tblcontacts a
				where 
				@idatom= a.atom2addressID
				and a.atom2addressID is not null
				and IdAddress = @IdAddress2


				--select * from tblAtoms2Addresses where IDATOM = 246435179

				INSERT INTO tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
				SELECT DISTINCT [Idcontact], 2949458, C.PHONENUMBER , getdate() datereported, getdate() UPDATEdDate 
				from #Contacts  C
				where C.PHONENUMBER is not null and [Idcontact] is not null and @idatom is not null and phonetype='Phone'
				and IdAddress = @IdAddress2
	
				insert into tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
				select distinct [IdContact], 2949459, PHONENUMBER, getdate() datereported, getdate() UpdatedDate 
				from #Contacts c
				where PHONENUMBER is not null and [IdContact] is not null and phonetype='Fax' 
				and IdAddress = @IdAddress2

				insert into tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
				select distinct [IdContact], 2949460, PHONENUMBER, getdate() datereported, getdate() UpdatedDate 
				from #Contacts c
				where PHONENUMBER is not null and [IdContact] is not null and phonetype='Mobile' 
				and IdAddress = @IdAddress2

				insert into [tblContacts_Emails](idcontact, [Email], DateReported, DateUpdated) 
				select distinct IdContact, ci.[Email] ,getdate(), getdate() 
				from #Contacts ci
				where ci.[Email] is not null
				and IdContact is not null and ci.[Email] like '%@%' 
				and IdAddress = @IdAddress2

				insert into tblContacts_Webs(idcontact, Web, DateReported, DateUpdated)
				select distinct idcontact, REPLACE(REPLACE(ci.WEB,'https://',''),'http://','') ,getdate(), getdate()
				from #Contacts ci
				where ci.WEB is not null
				and IdContact is not null and ci.WEB not like '%@%' 
				and IdAddress = @IdAddress2


				update #Address set Imported = 1 where id = @ID2
				update #Contacts set Imported = 1 where IdAddress = @IdAddress2
				
				set @ID2 = null
				set @IdAddress2 = null
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ID2
		END

		--select *
		UPDATE tblatoms2addresses set idcontact = q.Idcontact
		from #Contacts  q
		join tblatoms2addresses on
		tblatoms2addresses.idatom = @idatom
		where q.Idcontact is not null 
		and tblatoms2addresses.IdAddress = q.IdAddress and MAIN=1 and IsMain=0

						END

				--END

			
		--	end--ending main address



		--------------------------------------------------------------PHASE2-FinancialComparison-------------------------------------------------------------------------------
		IF((select count(*) from #FinancialAnalyses)>0)
		BEGIN
			
			INSERT INTO tblCompanies_Financials(
			idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo, ImportID)
			SELECT DISTINCT @idatom,IdCurrency,[YEAR],
			CASE WHEN Denomination = 'Standard' THEN 1 
				 WHEN Denomination = 'Thousands' THEN 1000
				 WHEN Denomination = 'Millions' THEN 1000000 ELSE 1 END as Denominator,
			CASE WHEN [TYPE] = 'Consolidated' THEN 1 ELSE 0 END as IsConsolidated,
			CASE WHEN [AUDIT] = 'Audited' THEN 1 
				 WHEN [AUDIT] = 'UnAudited' THEN 2
				 WHEN [AUDIT] = 'Estimated' THEN 3
				 WHEN [AUDIT] = 'Projected' THEN 4 END as isaudited,
			15,FinancialDate_new,LEFT(FORMAT(FinancialDate_new,'dd/MM/yyyy'),5), 
			getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,MONTHSNO,1696
			from #FinancialAnalyses ci
			where 
				[YEAR] not in(select FinancialYear from tblCompanies_Financials c where c.idatom = @idatom);
			
			SET IDENTITY_INSERT dbo.tblCompanies_FinancialsAdditional ON;

			delete from tblCompanies_Financials_FieldValuesAdditional where idFinancial in (select id from tblCompanies_FinancialsAdditional where idatom=@idatom 
			and FinancialYear in (select [YEAR] from #FinancialAnalyses)
			and IsConsolidated in (select IsConsolidated from #FinancialAnalyses))

			delete from tblCompanies_FinancialsAdditional where idatom=@idatom and FinancialYear in (select [YEAR] from #FinancialAnalyses) and IsConsolidated in (select IsConsolidated from #FinancialAnalyses)

			INSERT INTO tblCompanies_FinancialsAdditional(ID,
			idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo, ImportID)
			SELECT DISTINCT l.ID, @idatom,ci.IdCurrency,[YEAR],
			CASE WHEN Denomination = 'Standard' THEN 1 
				 WHEN Denomination = 'Thousands' THEN 1000
				 WHEN Denomination = 'Millions' THEN 1000000 ELSE 1  END as Denominator,
			CASE WHEN [TYPE] = 'Consolidated' THEN 1 ELSE 0 END as IsConsolidated,
			CASE WHEN [AUDIT] = 'Audited' THEN 1 
					WHEN [AUDIT] = 'UnAudited' THEN 2
					WHEN [AUDIT] = 'Estimated' THEN 3
					WHEN [AUDIT] = 'Projected' THEN 4 END as isaudited,
			15,FinancialDate_new,LEFT(FORMAT(FinancialDate_new,'dd/MM/yyyy'),5), 
			getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,ci.MONTHSNO,1696
			from 
			#FinancialAnalyses ci
			join tblCompanies_Financials l on l.IDATOM = @idatom and [YEAR] = l.FinancialYear  and ci.IsConsolidated=l.IsConsolidated
			where 
			l.id not in(select id from tblCompanies_FinancialsAdditional where IDATOM = @idatom)
			ORDER BY l.id DESC
			
			SET IDENTITY_INSERT dbo.tblCompanies_FinancialsAdditional OFF;

			--select * INTO JDP_TMP_FINANAL from #FinancialAnalyses
			
			INSERT INTO tblCompanies_Financials_FieldValuesAdditional(IdFinancial,IdField,FinancialValue, ImportID)
			SELECT DISTINCT cf.id,ci.IdField,ci.FinancialValue,1696
			from tblCompanies_FinancialsAdditional cf
			join #FinancialAnalyses ci on @idatom = cf.idatom and FinancialYear=[YEAR]  and ci.IsConsolidated=cf.IsConsolidated
			where 
			ci.FinancialValue is not null and IdField is not null

			-------------------JDP START
			DECLARE @FinID INT=0
			Declare @HiddenOut int
			DECLARE CCcursor CURSOR
				FOR Select distinct id from tblCompanies_FinancialsAdditional 
					where idatom=@idatom and FinancialYear in (select [YEAR] from #FinancialAnalyses)
			OPEN CCcursor
			FETCH NEXT FROM CCcursor INTO @FinID
			WHILE @@FETCH_STATUS = 0
			BEGIN
				exec @HiddenOut=spCR_FinancialsSave_Primary_FromExcel @FinID
			FETCH NEXT FROM CCcursor INTO @FinID
			END
			
			CLOSE CCcursor
			DEALLOCATE CCcursor

			DECLARE @tmpNewValue TABLE (newvalue int)
			INSERT INTO @tmpNewValue 
			EXEC @HiddenOut=ScoreCard_Get @idatom
			-------------------JDP END
		
		END

			IF((SELECT COUNT(Id) from tblCompanies_OriginalText	where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #FinancialComparison)>0)

				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_OriginalText c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_OriginalText c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					update [tblCompanies_OriginalText] set updateddate=GETDATE(),SourceID=@SourceID, IntelligenceID=@IntelligenceID, 
					Annual_Profit = Annual_Profit + char(10) + 
						replace((isnull((Select distinct STUFF((SELECT distinct
						IIF(ISNULL(CAST(ac.[Year] as NVARCHAR(10)),'')<>'','Year: ' + CAST(ac.[Year] as NVARCHAR(10)) +char(10) ,'')+	
						IIF(ISNULL(ac.FinancialMetric ,'')<>'','Name: '+ ac.FinancialMetric +char(10),'')+
						IIF(ISNULL(CAST(CAST(ac.FinancialValue as BIGINT) as NVARCHAR(100)),'')<>'','FinancialValue: '+CAST(CAST(ac.FinancialValue as BIGINT) as NVARCHAR(100)) +char(10)+char(10),'')
						from #FinancialComparison ac
						where @idatom = @idatom   and ac.FinancialValue <> '0.00'
					FOR xml path('')),1,0,''))+CHAR(10),'')) ,'&amp;','&')
					FROM #FinancialComparison m 
					join [tblCompanies_OriginalText] com with(nolock) on @idatom = com.idatom 
					where @idatom is not null 

				END

			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

			END
			ELSE

				BEGIN

				INSERT into tblCompanies_OriginalText(idatom, Annual_Profit, IntelligenceID, sourceID, updateddate)
				select distinct @idatom,'',@IntelligenceID,@SourceID,GETDATE()  
				from #FinancialComparison c
				where @idatom not in (SELECT IdAtom from tblCompanies_OriginalText c where c.IDATOM=@idatom)
	
				update [tblCompanies_OriginalText] set Annual_Profit = Annual_Profit + char(10) + 
					replace((isnull((Select distinct STUFF((SELECT distinct
					IIF(ISNULL(CAST(ac.[Year] as NVARCHAR(10)),'')<>'','Year: ' + CAST(ac.[Year] as NVARCHAR(10)) +char(10) ,'')+	
					IIF(ISNULL(ac.FinancialMetric ,'')<>'','Name: '+ ac.FinancialMetric +char(10),'')+
					IIF(ISNULL(CAST(CAST(ac.FinancialValue as BIGINT) as NVARCHAR(100)),'')<>'','FinancialValue: '+CAST(CAST(ac.FinancialValue as BIGINT) as NVARCHAR(100)) +char(10)+char(10),'')
					from #FinancialComparison ac
					where @idatom = @idatom   and ac.FinancialValue <> '0.00'
				FOR xml path('')),1,0,''))+CHAR(10),'')) ,'&amp;','&')
				FROM #FinancialComparison m 
				join [tblCompanies_OriginalText] com with(nolock) on @idatom = com.idatom --and FinancialYear = m.Year
				where @idatom is not null 

				END


		---------------------------------------------------------------CompanyHistory-------------------------------------------------------------------------------

			IF((SELECT COUNT(Id) from tblCompanies_OriginalText	where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #CompanyHistory)>0)
			BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies c join tblRecordsSources s on c.HistorySourceId=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies c join tblRecordsIntelligence s on c.HistoryIntelligenceId=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--select @DTSourceID
				--select @DTIntelligenceID
				--select @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	

					UPDATE tblCompanies set HistorySourceId = @SourceID,HistoryIntelligenceId = @IntelligenceID,DateUpdate=GETDATE()
					where 
					@idatom= tblCompanies.IDATOM 

					update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
						(isnull((Select STUFF((SELECT 
							isnull(IIF(ac.[History] <> '', N'Comment : ' + ac.[History] + CHAR(10), ''),'')	
						from #CompanyHistory ac
						where @idatom = @idatom  
					FOR xml path('')),1,0,''))+CHAR(10),'')) 
					FROM #CompanyHistory m 
					join tblCompanies com with(nolock) on @idatom = com.idatom
					join [tblDic_Comments] on [tblDic_Comments].id = com.IdHistoryComment
					where @idatom is not null and com.IdHistoryComment is not null

				END

			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

			END
			ELSE

				BEGIN

					INSERT into tblDic_Comments (DummyName,importId,IdStartDate,importIdRequestedNotes,ImportLinkField)
					select distinct '',1696,@idatom,5,@UID 
					from #CompanyHistory c
					join tblcompanies com on com.IDATOM=@idatom
					where @idatom is not null and com.IdHistoryComment is null
						
					update tblCompanies set IdHistoryComment = a.ID
					from tblDic_Comments a
					where tblCompanies.IDATOM = a.IdStartDate
					and a.importid = 1696 and importIdRequestedNotes = 5

					update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
						(isnull((Select STUFF((SELECT 
							isnull(IIF(ac.[History] <> '', N'Comment : ' + ac.[History] + CHAR(10), ''),'')	
						from #CompanyHistory ac
						where @idatom = @idatom  
					FOR xml path('')),1,0,''))+CHAR(10),'')) 
					FROM #CompanyHistory m 
					join tblCompanies com with(nolock) on @idatom = com.idatom
					join [tblDic_Comments] on [tblDic_Comments].id = com.IdHistoryComment
					where @idatom is not null and com.IdHistoryComment is not null

				END

	---------------------------------------------------------------Brands-------------------------------------------------------------------------------
			IF((SELECT COUNT(Id) from tblCompanies_OriginalText	where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #Brands)>0)

				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_OriginalText c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_OriginalText c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
				IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
				BEGIN	
						
					update [tblCompanies_OriginalText] set SourceID=@SourceID,IntelligenceID=@IntelligenceID,updateddate=GETDATE(),
						Brands_Comment = Brands_Comment + char(10) + 
						replace((isnull((Select distinct STUFF((SELECT distinct
						IIF(ISNULL(ac.BrandName ,'')<>'','BrandName: '+ ac.BrandName +char(10),'')
						from #Brands ac
						where @idatom = @idatom 
					FOR xml path('')),1,0,''))+CHAR(10),'')) ,'&amp;','&')
					FROM #Brands m 
					join [tblCompanies_OriginalText] com with(nolock) on @idatom = com.idatom 
					where @idatom is not null 

				END

			set @DTSourceID = NULL
			set @DTIntelligenceID = NULL
			set @DTRanking = NULL

			END
			ELSE

				BEGIN

					INSERT into tblCompanies_OriginalText(idatom, Brands_Comment, IntelligenceID, sourceID, updateddate)
					select distinct @idatom,'',@IntelligenceID,@SourceID,GETDATE()  
					from #Brands c
					where @idatom not in (SELECT IdAtom from tblCompanies_OriginalText c where c.IDATOM=@idatom)
	
					update [tblCompanies_OriginalText] set Brands_Comment = Brands_Comment + char(10) + 
						replace((isnull((Select distinct STUFF((SELECT distinct
						IIF(ISNULL(ac.BrandName ,'')<>'','BrandName: '+ ac.BrandName +char(10),'')
						from #Brands ac
						where @idatom = @idatom 
					FOR xml path('')),1,0,''))+CHAR(10),'')) ,'&amp;','&')
					FROM #Brands m 
					join [tblCompanies_OriginalText] com with(nolock) on @idatom = com.idatom 
					where @idatom is not null 

				END

			-------------------------------------------------------DebtCollectionRecords-------------------------------------------------------------------------------

			IF((SELECT COUNT(Id) from [tblCompanies2Searchers]	where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #DEBTCOLLECTIONAGENCIESSEARCH)>0)

				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from [tblCompanies2Searchers] c join tblRecordsSources s on c.DebtAgencieSourceId=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from [tblCompanies2Searchers] c join tblRecordsIntelligence s on c.DebtAgencieintelligenceId=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				--print @crisNO
				--print @DTRanking
				
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	

						update [tblCompanies2Searchers] set DebtAgencieSourceId=@SourceID, DebtAgencieintelligenceId=@IntelligenceID,  
							DebtAgencies_Notes = DebtAgencies_Notes + char(10) + 
							replace((isnull((Select distinct STUFF((SELECT distinct
							IIF(ISNULL(CAST(ac.[DEBTCOLLECTION] as NVARCHAR(MAX)),'')<>'','DEBTCOLLECTION: ' + CAST(ac.[DEBTCOLLECTION] as NVARCHAR(MAX)) +char(10) ,'')
							from #DEBTCOLLECTIONAGENCIESSEARCH ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) ,'&amp;','&')
						FROM #DEBTCOLLECTIONAGENCIESSEARCH m 
						join [tblCompanies2Searchers] com with(nolock) on @idatom = com.idatom 
						where @idatom is not null 	
						
					END

				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL		

				END
				ELSE

					BEGIN

						INSERT into [tblCompanies2Searchers](idatom,IdDebtAgencies, DebtAgencies_Notes, DebtAgencieintelligenceId, DebtAgencieSourceId, UpdateDate)
						select distinct @idatom,IdDebtAgencies,'DEBTCOLLECTION: ' + CAST(c.[DEBTCOLLECTION] as NVARCHAR(MAX)) +char(10),@IntelligenceID,@SourceID,GETDATE()  
						from #DEBTCOLLECTIONAGENCIESSEARCH c
						where @idatom not in (SELECT IdAtom from [tblCompanies2Searchers] c where c.IDATOM=@idatom)
	
						--update [tblCompanies2Searchers] set DebtAgencies_Notes = DebtAgencies_Notes + char(10) + 
						--	replace((isnull((Select distinct STUFF((SELECT distinct
						--	IIF(ISNULL(CAST(ac.[DEBTCOLLECTION] as NVARCHAR(MAX)),'')<>'','DEBTCOLLECTION: ' + CAST(ac.[DEBTCOLLECTION] as NVARCHAR(MAX)) +char(10) ,'')
						--	from #DEBTCOLLECTIONAGENCIESSEARCH ac
						--	where @idatom = @idatom  
						--FOR xml path('')),1,0,''))+CHAR(10),'')) ,'&amp;','&')
						--FROM #DEBTCOLLECTIONAGENCIESSEARCH m 
						--join [tblCompanies2Searchers] com with(nolock) on @idatom = com.idatom 
						--where @idatom is not null 

					END

		----------------------------------------------------ProductionCapacity-------------------------------------------------------------------------------

			IF((SELECT COUNT(Id) from [tblCompanies2Capacity] where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #ProductionCapacity)>0)

				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Capacity c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom and ProdCapacityInstalled is not null),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Capacity c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom and ProdCapacityInstalled is not null),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				print @DTSourceID  Print @DTIntelligenceID
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	
					
						UPDATE [tblCompanies2Capacity] set ProdCapacityInstalled = ProdCapacityInstalled_New,DateUpdated=GETDATE(),
						SourceID=@SourceID,IntelligenceID=@IntelligenceID
						from #ProductionCapacity a
						where 
						@idatom= [tblCompanies2Capacity].IDATOM and a.ProductionYear=[tblCompanies2Capacity].nYear
						and [tblCompanies2Capacity].ProdCapacityInstalled is null 
						
					END

				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL		

				END
				ELSE

					BEGIN

						INSERT into [tblCompanies2Capacity](idatom,nYear, ProdCapacityInstalled,IdUnitsType, SourceID, IntelligenceID, DateUpdated,ShowInReportImportExport,ShowInReportProductionCapacity)
						select distinct @idatom,ProductionYear,ProdCapacityInstalled_New,IdUnitsType,@IntelligenceID,@SourceID,GETDATE(),0,1  
						from #ProductionCapacity p
						where ProdCapacityInstalled_New is not null
						and ProductionYear not in (SELECT nYear from [tblCompanies2Capacity] c where c.IDATOM=@idatom and nYear=p.ProductionYear and ISNULL(ShowInReportProductionCapacity,0)=1)
	

					END


		------------------------------------------------------------AnnualImportsExports-------------------------------------------------------------------------------

		IF (SELECT COUNT(*) from #AnnualImportsExports)>0
		BEGIN

			IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
			BEGIN
				DEALLOCATE cur_FormerData_Transfer
			END
			DECLARE @Yearr INT

			DECLARE cur_FormerData_Transfer CURSOR FOR

			SELECT  Year
			FROM #AnnualImportsExports WITH(NOLOCK)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @Yearr
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
			IF(SELECT COUNT(Id) from [tblCompanies2Capacity] where IDATOM=@idatom and nYear=@Yearr)>0
				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Capacity c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Capacity c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	
					
						UPDATE [tblCompanies2Capacity] set ImportValue = a.ImportValue,ExportValue = a.ExportValue,IdCurrency=a.Idcurrency,
						DateUpdated=GETDATE(),
						SourceID=@SourceID,IntelligenceID=@IntelligenceID
						from #AnnualImportsExports a
						where 
						@idatom= [tblCompanies2Capacity].IDATOM and a.[Year]=[tblCompanies2Capacity].nYear
						and ([tblCompanies2Capacity].ImportValue is null or [tblCompanies2Capacity].ExportValue is null)

						update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
							(isnull((Select STUFF((SELECT 
								isnull(IIF(ac.[Comment] <> '', N'Comment : ' + ac.[Comment] + CHAR(10), ''),'')	
							from #AnnualImportsExports ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) 
						FROM #AnnualImportsExports m 
						join [tblCompanies2Capacity] com with(nolock) on @idatom = com.idatom and m.[Year]=com.nYear
						join [tblDic_Comments] on [tblDic_Comments].id = com.IdComment
						where com.IdComment is not null
						
					END	

				END
				ELSE

					BEGIN

						INSERT into [tblCompanies2Capacity](idatom,nYear,IdCurrency, ImportValue,ExportValue, SourceID, IntelligenceID, DateUpdated,ShowInReportImportExport)
						select distinct @idatom,[Year],IdCurrency,ImportValue,ExportValue,@IntelligenceID,@SourceID,GETDATE(),1  
						from #AnnualImportsExports s
						where [Year] not in (SELECT nYear from [tblCompanies2Capacity] c where c.IDATOM=@idatom and nYear=s.[Year] and ISNULL(ShowInReportImportExport,0)=1)

						INSERT into tblDic_Comments (DummyName,importId,IdStartDate,importIdRequestedNotes,ImportLinkField)
						select distinct '',1696,@idatom,6,[Year] 
						from #AnnualImportsExports c
						join [tblCompanies2Capacity] com with(nolock) on @idatom = com.idatom 
						where com.IdComment is null
							
						update [tblCompanies2Capacity] set IdComment = a.ID
						from tblDic_Comments a
						where [tblCompanies2Capacity].IDATOM = a.IdStartDate
						and a.importid = 1696 and importIdRequestedNotes = 6
						and ImportLinkField = [tblCompanies2Capacity].nYear

						update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
							(isnull((Select STUFF((SELECT 
								isnull(IIF(ac.[Comment] <> '', N'Comment : ' + ac.[Comment] + CHAR(10), ''),'')	
							from #AnnualImportsExports ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) 
						FROM #AnnualImportsExports m 
						join [tblCompanies2Capacity] com with(nolock) on @idatom = com.idatom and m.[Year]=com.nYear
						join [tblDic_Comments] on [tblDic_Comments].id = com.IdComment
						where com.IdComment is not null
		
					END


				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL	

				FETCH NEXT FROM cur_FormerData_Transfer INTO @Yearr

		END

	END


	-------------------------------------------------------------IMPORTFROM-------------------------------------------------------------------------------

		IF (SELECT COUNT(*) from #ImportFrom)>0
		BEGIN

			IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
			BEGIN
				DEALLOCATE cur_FormerData_Transfer
			END
			DECLARE @IdCountry INT

			DECLARE cur_FormerData_Transfer CURSOR FOR

			SELECT  IdCountry
			FROM #ImportFrom WITH(NOLOCK)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @IdCountry
			WHILE @@FETCH_STATUS = 0
			BEGIN
			

			IF((SELECT COUNT(Id) from tblCompanies2Commerce where IDATOM=@idatom and IdCountry=@IdCountry)>0)
				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Commerce c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom and IdCountry=@IdCountry),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies2Commerce c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom and IdCountry=@IdCountry),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	

						UPDATE tblCompanies2Commerce set IdCommerceType = 2949535,DateUpdated=GETDATE(),
						SourceID=@SourceID,IntelligenceID=@IntelligenceID
						from #ImportFrom a
						where 
						@idatom= tblCompanies2Commerce.IDATOM and tblCompanies2Commerce.IdCountry=@IdCountry
						
					END

				END
				ELSE

					BEGIN

						INSERT into tblCompanies2Commerce(idatom,IdCommerceType, IdCountry, SourceID, IntelligenceID, DateUpdated)
						select distinct @idatom,2949535,@IdCountry,@SourceID,@IntelligenceID,GETDATE()  
						from #ImportFrom cd
						where @idatom not in (SELECT IdAtom from tblCompanies2Commerce c where c.IDATOM=@idatom and c.IdCountry=@IdCountry)
	
					END

				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL
				
				FETCH NEXT FROM cur_FormerData_Transfer INTO @IdCountry

		END

	END

	---------------------------------------------------------------MethodOfPayment-------------------------------------------------------------------------------

		IF((SELECT COUNT(Id) from [tblCompanies2PayMethods] where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #MethodOfPayment)>0)

				BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from [tblCompanies2PayMethods] c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from [tblCompanies2PayMethods] c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	

						UPDATE [tblCompanies2PayMethods] set DateUpdated=GETDATE(),SourceID=@SourceID,IntelligenceID=@IntelligenceID
						from #MethodOfPayment a
						join [tblCompanies2PayMethods] on
						@idatom= [tblCompanies2PayMethods].IDATOM and a.IdPayMethod = [tblCompanies2PayMethods].IdPayMethod

						update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
							(isnull((Select STUFF((SELECT 
								isnull(IIF(ac.[Comment] <> '', N'Comment : ' + ac.[Comment] + CHAR(10), ''),'')	
							from #MethodOfPayment ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) 
						FROM #MethodOfPayment m 
						join [tblCompanies2PayMethods] com with(nolock) on @idatom = com.idatom and m.IdPayMethod = com.IdPayMethod
						join [tblDic_Comments] on [tblDic_Comments].id = com.IdComment
						where com.IdComment is not null
						
					END

				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL		

				END
				ELSE

					BEGIN

						INSERT into [tblCompanies2PayMethods](idatom,IdPayMethod,SourceID, IntelligenceID, DateUpdated)
						select distinct @idatom,IdPayMethod,@IntelligenceID,@SourceID,GETDATE()  
						from #MethodOfPayment c
						where @idatom not in (SELECT IdAtom from [tblCompanies2PayMethods] c where c.IDATOM=@idatom)
	
						INSERT into tblDic_Comments (DummyName,importId,IdStartDate,importIdRequestedNotes,ImportLinkField)
						select distinct '',1696,@idatom,7,@UID 
						from #MethodOfPayment c
						join [tblCompanies2PayMethods] com with(nolock) on @idatom = com.idatom 
						where com.IdComment is null
							
						update [tblCompanies2PayMethods] set IdComment = a.ID
						from tblDic_Comments a
						where [tblCompanies2PayMethods].IDATOM = a.IdStartDate
						and a.importid = 1696 and importIdRequestedNotes = 7

						update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
							(isnull((Select STUFF((SELECT 
								isnull(IIF(ac.[Comment] <> '', N'Comment : ' + ac.[Comment] + CHAR(10), ''),'')	
							from #MethodOfPayment ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) 
						FROM #MethodOfPayment m 
						join [tblCompanies2PayMethods] com with(nolock) on @idatom = com.idatom and m.IdPayMethod = com.IdPayMethod
						join [tblDic_Comments] on [tblDic_Comments].id = com.IdComment
						where com.IdComment is not null


					END

	----------------------------------------------------------Certifications-------------------------------------------------------------------------------

		IF((SELECT COUNT(Id) from tblCompanies_Certifications where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #Certifications where IdCertificateType is not null)>0)
			BEGIN

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Certifications c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Certifications c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	

						UPDATE tblCompanies_Certifications set DateUpdated=GETDATE(),SourceID=@SourceID,IntelligenceID=@IntelligenceID
						from #Certifications a
						where 
						@idatom= tblCompanies_Certifications.IDATOM

						update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
							(isnull((Select STUFF((SELECT 
								isnull(IIF(ac.[Comment] <> '', N'Comment : ' + ac.[Comment] + CHAR(10), ''),'')	
							from #Certifications ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) 
						FROM #Certifications m 
						join tblCompanies_Certifications com with(nolock) on @idatom = com.idatom
						join [tblDic_Comments] on [tblDic_Comments].id = com.IdComment
						where com.IdComment is not null
						
					END

				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL		

				END
				ELSE
					IF ((SELECT COUNT(*) from #Certifications where IdCertificateType is not null)>0 )
					BEGIN
						
						INSERT into tblCompanies_Certifications(idatom,IdCertificateType,SourceID, IntelligenceID, DateUpdated)
						select distinct @idatom,IdCertificateType,@IntelligenceID,@SourceID,GETDATE()  
						from #Certifications c
						where @idatom not in (SELECT IdAtom from tblCompanies_Certifications c where c.IDATOM=@idatom)
	
						INSERT into tblDic_Comments (DummyName,importId,IdStartDate,importIdRequestedNotes,ImportLinkField)
						select distinct '',1696,@idatom,8,@UID 
						from #Certifications c
						join tblCompanies_Certifications com with(nolock) on @idatom = com.idatom 
						where com.IdComment is null
							
						update tblCompanies_Certifications set IdComment = a.ID
						from tblDic_Comments a
						where tblCompanies_Certifications.IDATOM = a.IdStartDate
						and a.importid = 1696 and importIdRequestedNotes = 8

						update [tblDic_Comments] set DummyName = ISNULL(DummyName,'') + char(10) +
							(isnull((Select STUFF((SELECT 
								isnull(IIF(ac.[Comment] <> '', N'Comment : ' + ac.[Comment] + CHAR(10), ''),'')	
							from #Certifications ac
							where @idatom = @idatom  
						FOR xml path('')),1,0,''))+CHAR(10),'')) 
						FROM #Certifications m 
						join tblCompanies_Certifications com with(nolock) on @idatom = com.idatom
						join [tblDic_Comments] on [tblDic_Comments].id = com.IdComment
						where com.IdComment is not null

					END

	---------------------------------------------------------------TradeReferences-------------------------------------------------------------------------------

		IF (SELECT COUNT(*) from #TradeReferences)>0
		BEGIN

			IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
			BEGIN
				DEALLOCATE cur_FormerData_Transfer
			END
			DECLARE @RelationYear INT,@IDD INT

			DECLARE cur_FormerData_Transfer CURSOR FOR

			SELECT YEAR(RelationshipDate),ID
			FROM #TradeReferences WITH(NOLOCK)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @RelationYear,@IDD
			WHILE @@FETCH_STATUS = 0
			BEGIN
			

			IF((SELECT COUNT(Id) from cs_tradesuppliers where IDATOM=@idatom and RelationYear=@RelationYear)>0)

					BEGIN	

				set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from cs_tradesuppliers c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
				set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from cs_tradesuppliers c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
				set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
					IF((@DTSourceID is null or @DTIntelligenceID is null) ) or @DTRanking >= @RankingID
					BEGIN	

						UPDATE cs_tradesuppliers set 
						--PaymentId = a.PaymentId,TermsOfPaymentsID=a.TermsOfPaymentsID,BusinessTrendId = a.BusinessTrendId,
						--Comments = a.Comment,RelationMonth=MONTH(a.RelationshipDate),RelationYear=YEAR(a.RelationshipDate),
						UpdateDate=GETDATE(),
						SourceID=@SourceID,IntelligenceID=@IntelligenceID
						from #TradeReferences a
						where 
						@idatom= cs_tradesuppliers.IDATOM
						and RelationYear=@RelationYear and a.ID=@IDD
						
					END	

				END
				ELSE

					BEGIN

						INSERT into cs_tradesuppliers(idatom,TradeSupplierID,RelationMonth,RelationYear,TermsOfPaymentsID,MaxCreditLimit,MaxCreditLimitCurrencyID,
						AverageOrderAmount,AverageOrderCurrencyID,PaymentId,BusinessTrendId,Comments,SourceID, IntelligenceID, UpdateDate,ReportedDate)
						SELECT DISTINCT @idatom,'',MONTH(RelationshipDate),YEAR(RelationshipDate),TermsOfPaymentsID,MaxCreditLimit,MaxCreditLimitCurrencyID,
						AverageOrderAmount,AverageOrderCurrencyID,PaymentId,BusinessTrendId,Comment,@IntelligenceID,@SourceID,GETDATE(),GETDATE()  
						from #TradeReferences c
						where @idatom not in (SELECT IdAtom from cs_tradesuppliers c where c.IDATOM=@idatom)
						and  YEAR(RelationshipDate)=@RelationYear and c.ID=@IDD

					END

				set @RelationYear = null
				set @IDD = null
				set @DTSourceID = NULL
				set @DTIntelligenceID = NULL
				set @DTRanking = NULL
				FETCH NEXT FROM cur_FormerData_Transfer INTO @RelationYear,@IDD

		END

	END

	-------------------------------------------------------------AFFILIATES-------------------------------------------------------------------------------

	--	IF((SELECT COUNT(Id) from tblCompanies_Related where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #Affiliates)>0)

	--			BEGIN

	--			set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Related c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
	--			set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Related c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
	--			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
	--			IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
	--			BEGIN	

	--					UPDATE tblCompanies_Related set DateUpdated=GETDATE(),SourceID=@SourceID,IntelligenceID=@IntelligenceID
	--					from #Affiliates a
	--					where 
	--					@idatom= tblCompanies_Related.IDATOM

	--			END

	--			set @DTSourceID = NULL
	--			set @DTIntelligenceID = NULL
	--			set @DTRanking = NULL		

	--			END
	--			ELSE

	--				BEGIN

	--					INSERT INTO tblCompanies_Related(idatom,IdTypeRelated,IdCountry,DateUpdated,DateReported, ShowInReport,SourceID, IntelligenceID,IDRELATED)
	--					SELECT DISTINCT @idatom,2949528, IdCountry,GETDATE() UpdatedDate,GETDATE(), 1,@SourceID,@IntelligenceID,ci.idrelated
	--					from #Affiliates ci 
	--					where ci.idrelated is not null
	--					and ci.idrelated NOT IN (SELECT idrelated from tblCompanies_Related c where c.IDATOM = @idatom and IdTypeRelated = 2949528)
	
	--				END

	-----------------------------------------------------------------ClientsInclude-------------------------------------------------------------------------------

	--	IF((SELECT COUNT(Id) from tblCompanies_Related where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #ClientsInclude)>0)

	--			BEGIN

	--			set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Related c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
	--			set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Related c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
	--			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
	--				IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
	--				BEGIN	

	--					UPDATE tblCompanies_Related set DateUpdated=GETDATE(),SourceID=@SourceID,IntelligenceID=@IntelligenceID
	--					from #ClientsInclude a
	--					where 
	--					@idatom= tblCompanies_Related.IDATOM

						
	--				END

	--			set @DTSourceID = NULL
	--			set @DTIntelligenceID = NULL
	--			set @DTRanking = NULL		

	--			END
	--			ELSE

	--				BEGIN

	--					INSERT INTO tblCompanies_Related(idatom,IdTypeRelated,IdCountry,DateUpdated,DateReported, ShowInReport,SourceID, IntelligenceID,IDRELATED)
	--					SELECT DISTINCT @idatom,2949530, IdCountry,GETDATE() UpdatedDate,GETDATE(), 1,@SourceID,@IntelligenceID,ci.idrelated
	--					from #ClientsInclude ci 
	--					where ci.idrelated is not null
	--					and ci.idrelated NOT IN (SELECT idrelated from tblCompanies_Related c where c.IDATOM = @idatom and IdTypeRelated = 2949530)
	
	--				END

	-----------------------------------------------------------------AgentsFor-------------------------------------------------------------------------------

	--	IF((SELECT COUNT(Id) from tblCompanies_Related where IDATOM=@idatom)>0 and (SELECT COUNT(*) from #AgentsFor)>0)

	--			BEGIN

	--			set @DTSourceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Related c join tblRecordsSources s on c.SourceID=s.ID where c.IDATOM=@idatom),12)
	--			set @DTIntelligenceID = isnull((SELECT TOP 1 s.[Rank] from tblCompanies_Related c join tblRecordsIntelligence s on c.IntelligenceID=s.ID where c.IDATOM=@idatom),7)
	--			set @DTRanking = (SELECT Ranking from tblRecordsSIranking where [Source]=@DTSourceID and [Intelligence]=@DTIntelligenceID)

				
	--				IF((@DTSourceID is null or @DTIntelligenceID is null) ) --or @DTRanking >= @RankingID
	--				BEGIN	

	--					UPDATE tblCompanies_Related set DateUpdated=GETDATE(),SourceID=@SourceID,IntelligenceID=@IntelligenceID
	--					from #AgentsFor a
	--					where 
	--					@idatom= tblCompanies_Related.IDATOM

						
	--				END

	--			set @DTSourceID = NULL
	--			set @DTIntelligenceID = NULL
	--			set @DTRanking = NULL		

	--			END
	--			ELSE

	--				BEGIN

	--					INSERT INTO tblCompanies_Related(idatom,IdTypeRelated,IdCountry,DateUpdated,DateReported, ShowInReport,SourceID, IntelligenceID,IDRELATED)
	--					SELECT DISTINCT @idatom,2949529, IdCountry,GETDATE() UpdatedDate,GETDATE(), 1,@SourceID,@IntelligenceID,ci.idrelated
	--					from #AgentsFor ci 
	--					where ci.idrelated is not null
	--					and ci.idrelated NOT IN (SELECT idrelated from tblCompanies_Related c where c.IDATOM = @idatom and IdTypeRelated = 2949529)
	
	--				END

	

		print @idatom
		select 1;

	END ---ending update
---============================================================[UPDATE END]============================================================---

---============================================================[IMPORT START]============================================================---
	
	ELSE IF (ISNULL(@UID,'')='' and ISNULL(@idatom,0)=0  AND (SELECT COUNT(*) from #REGISTERS)>0)
	BEGIN
		-- Run IMPORT script if no UID found
		PRINT 'Running IMPORT script...';
			----------------------------------------------------- Atoms

			INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, [Source],IsImported)
			SELECT GETDATE(), GETDATE(),@CountryCode+'C' as CountryCode, GETDATE() as DateCreated, @CountryID as IdRegisteredCountry, 1696 as ImportId, 'Data Exchange Project',1

			SET @idatom = SCOPE_IDENTITY()
			print 'IDATOM=' + cast(@idatom as nvarchar)				
			----------------------------------------------------- Companies

			INSERT INTO tblCompanies(
				IDATOM, 
				NameLocal, RegisteredNameLocal, Name, RegisteredName, 
				--ShortName,ShortNameLocal,
				DateUpdate, DateIncorporation, IsBO,
				CompanyRegisteredLocalNameIntelligenceId, 
				CompanyRegisteredLocalNameSourceId,
				CompanyLocalNameIntelligenceId, 
				CompanyLocalNameSourceId,
				CompanyRegisteredNameIntelligenceId, 
				CompanyRegisteredNameSourceId,
				CompaniesNameIntelligenceId, 
				CompaniesNameSourceId,
				CompanyShortLocalNameIntelligenceId,CompanyShortLocalNameSourceId,
				CompanyShortNameIntelligenceId,CompanyShortNameSourceId,
				[CompaniesDateIntelligenceId],[CompaniesDateSourceId]
			)
			SELECT @idatom,@SubjectNativeName, @SubjectNativeName, @Subject, @Subject,--@COMPANYSHORTNAME,@COMPANYSHORTNAMELOCAL,
			GETDATE(),
			isnull(cast(@DATEREGISTERED as date),cast(@DATESTARTED as date)), 1 IsBO,
			@IntelligenceID,@SourceID,@IntelligenceID,@SourceID,@IntelligenceID,@SourceID,@IntelligenceID,@SourceID,@IntelligenceID,@SourceID,@IntelligenceID,@SourceID,@IntelligenceID,@SourceID

		--PRINT 'INSERT New Companies DONE'

		----------------------------------------------------- TradingNames

		insert into tblcompanies_names(idatom, NameType,Name, Intelligenceid, Sourceid,DateUpdated, ReportedDate, isHistory, StartDate, EndDate)
		SELECT @idatom,1,[Name],@IntelligenceID as IntelligenceID,@SourceID as SourceID,GETDATE(),GETDATE(), IsHistory, STARTDATE, EndDate
		from #TradingNames
		where (IsNative=0 or [Name] like '%[A-Za-z]%')
		UNION 
		SELECT @idatom,2,[Name],@IntelligenceID as IntelligenceID,@SourceID as SourceID,GETDATE(),GETDATE(), IsHistory, StartDate, EndDate
		from #TradingNames
		where IsNative=1 or [Name] not like '%[A-Za-z]%'

		----------------------------------------------------- FormerNames

		--insert into tblcompanies_names(idatom, NameType,Name, Intelligenceid, Sourceid, isHistory,DateUpdated, ReportedDate)
		--SELECT @idatom,1,[Name],@IntelligenceID as IntelligenceID,@SourceID as SourceID,1,GETDATE(),GETDATE()
		--from #FormerNames
		--where IsNative=0
		--UNION 
		--SELECT @idatom,2,[Name],@IntelligenceID as IntelligenceID,@SourceID as SourceID,1,GETDATE(),GETDATE()
		--from #FormerNames
		--where IsNative=1

		------------------------------------------------------- TRADINGNAMESHISTORICAL

		--insert into tblcompanies_names(idatom, NameType,Name, Intelligenceid, Sourceid, isHistory,DateUpdated, ReportedDate)
		--SELECT @idatom,1,[Name],@IntelligenceID as IntelligenceID,@SourceID as SourceID,1,GETDATE(),GETDATE()
		--from #TRADINGNAMESHISTORICAL
		--where [Name] like '%[A-Za-z]%'
		--and [Name] NOT IN (SELECT IDATOM from tblcompanies_names where IDATOM=@idatom and NameType=1)
		--UNION 
		--SELECT @idatom,2,Name,@IntelligenceID as IntelligenceID,@SourceID as SourceID,1,GETDATE(),GETDATE()
		--from #TRADINGNAMESHISTORICAL
		--where [Name] not like '%[A-Za-z]%'
		--and [Name] NOT IN (SELECT [Name] from tblcompanies_names where IDATOM=@idatom and NameType=2)

		------------------------------------------------------- REGISTEREDTRADINGNAMESHISTORICAL

		--insert into tblcompanies_names(idatom, NameType,Name, Intelligenceid, Sourceid, isHistory,DateUpdated, ReportedDate)
		--SELECT @idatom,1,[Name],@IntelligenceID as IntelligenceID,@SourceID as SourceID,1,GETDATE(),GETDATE()
		--from #REGISTEREDTRADINGNAMESHISTORICAL
		--where [Name] like '%[A-Za-z]%'
		--and [Name] NOT IN (SELECT [Name] from tblcompanies_names where IDATOM=@idatom and NameType=1)

		----------------------------------------------------- Addresses
	
	-----ADD A CURSOR TO LOOP OVER THE ADDRESSES TABLE
		DECLARE @IdAddress INT;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ID INT;
		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #Address WITH(NOLOCK)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ID
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
					INSERT INTO tblAddresses(IdCountry, IdTown, POBox, PostalCode, IdArea,BuildingNo,IdBuilding,ImportID,AddressTypeID)
					SELECT @CountryID,Idtown ,POBOX,POSTALCODE,IdArea,BUILDINGNO,IdBuilding,1696, AddressTypeID
					from #Address 
					where id = @id

					SET @IdAddress = SCOPE_IDENTITY()

					INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
					SELECT @IDATOM, @IdAddress, AddressTypeID, GETDATE(),GETDATE(),(select [Main] from #Address where id = @id),@IntelligenceID,@SourceID,1
					from tblAddresses
					where ImportID = 1696 and id = @IdAddress

					--select * from tblDic_BaseValues where DummyName = 'Branch Address'
					update #Contacts set IdAddress = @IdAddress where IdAddress = @ID

					--insert here the contact details from #contact

				UPDATE tblcontacts set atom2addressID = null where atom2addressID is not null

				INSERT INTO tblcontacts(atom2addressID)
				SELECT DISTINCT @idatom
				FROM #Contacts 
				where IdAddress = @IdAddress and (PHONENUMBER is not null OR EMAIL is not null OR WEB is not null)

				UPDATE #Contacts set Idcontact = a.id
				from tblcontacts a
				where 
				@idatom= a.atom2addressID
				and a.atom2addressID is not null
				and IdAddress = @IdAddress


				--select * from tblAtoms2Addresses where IDATOM = 246435179

				INSERT INTO tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
				SELECT DISTINCT [Idcontact], 2949458, C.PHONENUMBER , getdate() datereported, getdate() UPDATEdDate 
				from #Contacts  C
				where C.PHONENUMBER is not null and [Idcontact] is not null and @idatom is not null and phonetype='Phone'
				and IdAddress = @IdAddress
	
				insert into tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
				select distinct [IdContact], 2949459, PHONENUMBER, getdate() datereported, getdate() UpdatedDate 
				from #Contacts c
				where PHONENUMBER is not null and [IdContact] is not null and phonetype='Fax' 
				and IdAddress = @IdAddress

				insert into tblContacts_Phones(IdContact,IdPhoneType,Number,DateReported, DateUpdated) 
				select distinct [IdContact], 2949460, PHONENUMBER, getdate() datereported, getdate() UpdatedDate 
				from #Contacts c
				where PHONENUMBER is not null and [IdContact] is not null and phonetype='Mobile' 
				and IdAddress = @IdAddress

				insert into [tblContacts_Emails](idcontact, [Email], DateReported, DateUpdated) 
				select distinct IdContact, ci.[Email] ,getdate(), getdate() 
				from #Contacts ci
				where ci.[Email] is not null
				and IdContact is not null and ci.[Email] like '%@%' 
				and IdAddress = @IdAddress

				insert into tblContacts_Webs(idcontact, Web, DateReported, DateUpdated)
				select distinct idcontact, REPLACE(REPLACE(ci.WEB,'https://',''),'http://','') ,getdate(), getdate()
				from #Contacts ci
				where ci.WEB is not null
				and IdContact is not null and ci.WEB not like '%@%' 
				and IdAddress = @IdAddress


				update #Address set Imported = 1 where id = @ID
				update #Contacts set Imported = 1 where IdAddress = @IdAddress
				
				set @ID = null;
				set @IdAddress = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ID
		END;

		UPDATE tblatoms2addresses set idcontact = q.Idcontact
		from #Contacts  q
		where 
		tblatoms2addresses.idatom = @idatom
		and q.Idcontact is not null 
		and tblatoms2addresses.IdAddress = q.IdAddress

		
					
		
		----------------------------------------------------- OPERATIONAL STATUS
		--ALTER TABLE #STATUS ADD idStatus INT


		insert into tblCompanies2Status(idatom, idStatus, DateStart,DateUpdated, DateReported, DateEnd, ShowInReport, IntelligenceID,SourceID)
		SELECT @IDATOM, idStatus as idStatus, cast(@DATESTARTED as date), GETDATE(),GETDATE(),NULL,1,@IntelligenceID,@SourceID
		from #STATUS
		where idStatus is not null
		--select * from #STATUS

		----------------------------------------------------- REGISTERS

		--ALTER TABLE #REGISTERS add IdStatus INT


		insert into tblcompanyids(idatom, idorganisation, idregister, Number, IdType, IdStatus, IdCountry, DateUpdated, DateReported,ShowInreport, IntelligenceId, SourceID,
		issueDate,ExpiryDate)
		select @IDATOM, REGISTERTYPEID, REGISTERNAMEID,REGISTERNUMBER,REGISTERMAINID,idStatus,@CountryID, GETDATE(),GETDATE(),1,@IntelligenceID,@SourceID,
		cast(REGISTERISSUEDATE as date),cast(REGISTEREXPIRYDATE as date)
		from #REGISTERS
		where REGISTERNUMBER is not null 
		--select * from #REGISTERS

		----------------------------------------------------- CAPITAL
		insert into tblCompanies_Capital(IDATOM, PaidUp,Issued, IdCurrency, Shares
    --NominalValue
    ,DateReported, DateUpdated, SourceID, IntelligenceID, ShowInReport)
		SELECT @idatom,CapitalPaidUp,CapitalIssued,IdCurrency,NoOfShares,
    --ValueOfShare
    GETDATE(),GETDATE(),@IntelligenceID,@SourceID,1
		from #CAPITAL

		----------------------------------------------------- LEGALFORMINFO
		--ALTER TABLE #LEGALFORMINFO add IdType INT

		insert into [tblCompanies2Types]([IDATOM], [IdType], [DateUpdated],[DateReported],[ShowInReport],[IntelligenceID],[SourceID], IsHistory,DateStart,DateEnd)
		SELECT @idatom,IdType,GETDATE(),GETDATE(),1,@IntelligenceID,@SourceID,IsHistory,LEGALFORMSTARTDATE,LegalFormEndDate
		from #LEGALFORMINFO where IdType is not null 

		----------------------------------------------------- NUMBEROFEMPLOYEES

		insert into tblCompanies_Employees(IDATOM, TotalNumberFrom, [Year], ShowInReport, IntelligenceID,SourceID, UpdatedDate, ReportedDate)
		SELECT @idatom,NumberFrom,Year,1,@IntelligenceID,@SourceID,GETDATE(),GETDATE()
		from #NUMBEROFEMPLOYEES

		----------------------------------------------------- Premises
		--ALTER TABLE #Premises add idpremisetype INT,[IdStatus] INT,IdType INT,[IdCountry] INT,[IdSizeMeasure] INT

	    insert into tblPremises([IDATOM],IdStatus,IdType,idpremisetype,[IdCountry],[IdSizeMeasure],[DateUpdated],[DateReported],[Size],[IntelligenceID],[SourceID],
		[ShowInReport],[NumberOfUnits])
		SELECT @idatom,idpremisetype,IdType,2951835 ,@CountryID,[IdSizeMeasure],GETDATE(),GETDATE(),LEFT(Size,CHARINDEX(' ',Size)),@IntelligenceID,@SourceID,1,Number	
		from #Premises
		where idpremisetype is not null

		----------------------------------------------------- Activities

		insert into tblCompanies2Activities(idatom,idstandard, idactivity, DateUpdated, DateReported, IsPrimary,ishistory, showinreport,sourceid, intelligenceid, 
		idSubClassUKSIC, idClassUKSIC, idGroupUKSIC, iddivisionuksic)	
		SELECT distinct @idatom as idatom, 4077413 as idstandard , ActivityID idactivity, getdate() UpdatedDate,GETDATE() as DateReported 
		,IsPrimary as IsPrimary,IsHistory as IsHistory,1 as ShowInReport,@SourceID as SourceId,@IntelligenceID as IntelligenceId, 
		IdSubClassUksic as idSubClassUKSIC, 
		IdClassUksic as idClassUKSIC, 
		IdGroupUksic as idGroupUKSIC, 
		IdDivisionUksic as iddivisionuksic
		FROM #Activities ba	
		where (ba.IdSubClassUksic is not null or ba.IdClassUksic is not null or ba.IdGroupUksic is not null)
		and @idatom not in(select idatom from tblCompanies2Activities 
		where idatom = @idatom and idSubClassUKSIC =ba.idSubClassUKSIC)	
		and ActivityID is not null and IsPrimary is not null and IsHistory is not null

		----------------------------------------------------- MANAGERSINDIVIDUALS

	
		DECLARE @Manager_IDAddress INT ,@PersonIDATOM INT
		
		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ManagerImport_ID INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #MANAGERSINDIVIDUALS_Main WITH(NOLOCK)
		where LOWER(MANAGERINDIVIDUALNAME_New) not in (SELECT 
		LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
) AS [MANAGER Full Name]    
		FROM TblPersons p
		JOIN tblCompanies2Administrators cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM -- and isnull(IsFormer,0)=0
		JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDRELATED
		WHERE ISNULL(LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
) , '') <> ''
		and cs.IDATOM=@idatom)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerImport_ID
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),@CountryCode+'P' as CountryCode, GETDATE() as DateCreated, @CountryID as IdRegisteredCountry,1700 as ImportId,ID,1
				from #MANAGERSINDIVIDUALS_Main
				where ID=@ManagerImport_ID
			
				SET @PersonIDATOM = SCOPE_IDENTITY()

				update #MANAGERSINDIVIDUALS_Main set PersonIDATOM = @PersonIDATOM where ID=@ManagerImport_ID

				------ execute split SP to split person name 
				EXEC [sp_import_SplitPersonNames_Deep] '#MANAGERSINDIVIDUALS_Main','[MANAGERINDIVIDUALNAME_New]'

				insert into  tblPersons (IDATOM,LastNameLocal,IdLastNamePrefix,
				FirstNameLocal,IdFirstNamePrefix,
				MiddleNameLocal,IdMiddleNamePrefix,
				MiddleNameLocal2,IdMiddleNamePrefix2,
				MiddleNameLocal3,Idmiddlenameprefix3,
				MiddleNameLocal4,Idmiddlenameprefix4,
				MiddleNameLocal5,Idmiddlenameprefix5,
				MiddleNameLocal6,Idmiddlenameprefix6,
				LastName,FirstName,
				MiddleName,MiddleName2,
				MiddleName3,MiddleName4,
				MiddleName5,MiddleName6,
				UpdatedDate,
				[IdNationality],
				IdGender,
				Idtitle,
				IsBO)
				select distinct
				PersonIDATOM, 
				IIF(lastname not like '%[Aa-Zz]%',LastName,null),LastNamePrefix,
				IIF(FirstName not like '%[Aa-Zz]%',FirstName,null),FirstNamePrefix,
				IIF(MiddleName1 not like '%[Aa-Zz]%',MiddleName1,null), MiddlePrefix1,
				IIF(MiddleName2 not like '%[Aa-Zz]%',MiddleName2, NULL), MiddlePrefix2,
				IIF(MiddleName3 not like '%[Aa-Zz]%',MiddleName3, NULL), MiddlePrefix3,
				IIF(MiddleName4 not like '%[Aa-Zz]%',MiddleName4, NULL), MiddlePrefix4,
				IIF(MiddleName5 not like '%[Aa-Zz]%',MiddleName5, NULL), MiddlePrefix5,
				IIF(MiddleName6 not like '%[Aa-Zz]%',MiddleName6, NULL), MiddlePrefix6,
				IIF(lastname like '%[Aa-Zz]%',UPPER(LEFT(LastName,1))+LOWER(SUBSTRING(LastName,2,LEN(LastName))),null),
				IIF(FirstName like '%[Aa-Zz]%',UPPER(LEFT(FirstName,1))+LOWER(SUBSTRING(FirstName,2,LEN(FirstName))) ,null),
				IIF(MiddleName1 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName1,1))+LOWER(SUBSTRING(MiddleName1,2,LEN(MiddleName1))) , NULL),
				IIF(MiddleName2 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName2,1))+LOWER(SUBSTRING(MiddleName2,2,LEN(MiddleName2))) , NULL),
				IIF(MiddleName3 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName3,1))+LOWER(SUBSTRING(MiddleName3,2,LEN(MiddleName3))) , NULL),
				IIF(MiddleName4 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName4,1))+LOWER(SUBSTRING(MiddleName4,2,LEN(MiddleName4))) , NULL),
				IIF(MiddleName5 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName5,1))+LOWER(SUBSTRING(MiddleName5,2,LEN(MiddleName5))) , NULL),
				IIF(MiddleName6 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName6,1))+LOWER(SUBSTRING(MiddleName6,2,LEN(MiddleName6))) , NULL),
				GETDATE() UpdatedDate,
				IdNationality,
				Idgender,
				Idtitle,
				1 IsBO
				from #MANAGERSINDIVIDUALS_Main
				where ID=@ManagerImport_ID
			
				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct @CountryID, 4075976 as [Primary Business Address], 1700, PersonIDATOM
				from #MANAGERSINDIVIDUALS_Main
				where id=@ManagerImport_ID
		  
				SET @Manager_IDAddress = SCOPE_IDENTITY()

				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @PersonIDATOM, @Manager_IDAddress, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@ManagerImport_ID and ImportID=1700
				
				set @ManagerImport_ID = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerImport_ID
		
		END;

			update #MANAGERSINDIVIDUALS set PersonIDATOM = a.PersonIDATOM 
			from #MANAGERSINDIVIDUALS_Main a 
			where #MANAGERSINDIVIDUALS.MANAGERINDIVIDUALNAME = a.MANAGERINDIVIDUALNAME 

			INSERT INTO tblcompanies2administrators(idatom, idrelated, idposition,ShowInReport, IntelligenceID,SourceID, DateUpdated, DateReported)
			SELECT distinct @idatom, PersonIDATOM,MANAGERIDPOSITION,1,@IntelligenceID,@SourceID,GETDATE(),GETDATE() 
			FROM #MANAGERSINDIVIDUALS
			where @idatom is not null and PersonIdatom is not null and MANAGERIDPOSITION is not null

			UPDATE tblPersons2Languages set IdLanguage=m.IdLanguage
			from #MANAGERSINDIVIDUALS_Main m 
			join tblPersons2Languages on @idatom=tblPersons2Languages.IDATOM

			--select * from #MANAGERSINDIVIDUALS_Main
			--select * from tblcompanies2administrators where IDATOM=@idatom
			--return;

		----------------------------------------------------- MANAGERCOMPANIES

		IF(SELECT COUNT(*) from #MANAGERSCOMPANIES)>0
		BEGIN
		
			DECLARE @ManagerCompanyIdatom_Import INT, @ManagerCompany_IDAddress_Import INT,@ManagerCompanyID_Import INT
			
			IF((SELECT COUNT(*) from #MANAGERSCOMPANIES where ID is not null)>0)
	
		BEGIN
		
		DECLARE @ManagerCompanyImportID INT
		set @ManagerCompanyImportID = null

		UPDATE i
		SET i.ManagerCompanyIdatom = x.idatom
		FROM #MANAGERSCOMPANIES_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				ISNULL(com.RegisteredName, com.[Name]) = i.MANAGERCOMPANYNAME
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.MANAGERCOMPANYNAME IS NOT NULL and Idcountry is not null;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		
		-- Cursor to process only unmatched companies using LEFT JOIN
		DECLARE cur_FormerData_Transfer CURSOR FOR
		SELECT i.ID
		FROM #MANAGERSCOMPANIES_Distinct i WITH (NOLOCK)
		LEFT JOIN (
		    SELECT DISTINCT
		        LOWER(LTRIM(RTRIM(REPLACE(ISNULL(p.RegisteredName, p.Name), '  ', ' ')))) COLLATE Latin1_General_CI_AI AS CleanName,
				atoms.IdRegisteredCountry
		    FROM tblCompanies p
		    JOIN tblCompanies2Administrators cs ON cs.IDRELATED = p.IDATOM --AND ISNULL(cs.IsFormer, 0) = 0
			JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDATOM
		    WHERE cs.IDATOM = @idatom 
		) existing ON LOWER(LTRIM(RTRIM(REPLACE(i.MANAGERCOMPANYNAME, '  ', ' ')))) COLLATE Latin1_General_CI_AI = existing.CleanName
		AND existing.IdRegisteredCountry = i.IdCountry  
		WHERE ManagerCompanyIdatom IS NULL
		  AND existing.CleanName IS NULL and Idcountry is not null

		
		OPEN cur_FormerData_Transfer
		FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerCompanyID_Import
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		    PRINT 'Inserting new company: ' + CAST(@ManagerCompanyID_Import AS VARCHAR)
		
		    -- Insert into tblAtoms
		    INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
		    SELECT DISTINCT GETDATE(), GETDATE(),
			ca.CountryCode + 'C' AS CountryCode,	
			--@CountryCode + 'C', 
			GETDATE(),
		           ISNULL(IdCountry, @CountryID), 1721, ID, 1
		    FROM #MANAGERSCOMPANIES_Distinct d
			CROSS APPLY (
				    SELECT CountryCode 
				    FROM tblDic_GeoCountries 
				    WHERE Country = d.MANAGERCOMPANYCOUNTRY
				) ca
		    WHERE ID = @ManagerCompanyID_Import
		
		    SET @ManagerCompanyIdatom_Import = SCOPE_IDENTITY()
		
		    -- Update temp table
		    UPDATE #MANAGERSCOMPANIES_Distinct
		    SET ManagerCompanyIdatom = @ManagerCompanyIdatom_Import
		    WHERE ID = @ManagerCompanyID_Import
		
		    -- Insert into tblCompanies
		    INSERT INTO tblCompanies(IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
		                             DateUpdate, IsClient, IsCorrespondent, IsBO,
		                             CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
		                             CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
		                             CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
		                             CompaniesNameIntelligenceId, CompaniesNameSourceId)
		    SELECT DISTINCT @ManagerCompanyIdatom_Import,
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', MANAGERCOMPANYNAME, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', MANAGERCOMPANYNAME, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', MANAGERCOMPANYNAME, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', MANAGERCOMPANYNAME, NULL),
		           GETDATE(), 0, 0, 1,
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @SourceID, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[أ-ي]%', @SourceID, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @SourceID, NULL),
		           IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL), IIF(MANAGERCOMPANYNAME LIKE N'%[A-Za-Z]%', @SourceID, NULL)
		    FROM #MANAGERSCOMPANIES_Distinct
		    WHERE ID = @ManagerCompanyID_Import
		
		    -- Insert address
		    INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
		    SELECT DISTINCT ISNULL(IdCountry, @CountryID), 4075976, 1721, @ManagerCompanyIdatom_Import
		    FROM #MANAGERSCOMPANIES_Distinct
		    WHERE ID = @ManagerCompanyID_Import and IdCountry is not null
		
		    SET @ManagerCompany_IDAddress_Import = SCOPE_IDENTITY()
		
		    -- Link address to atom
		    INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
		    SELECT DISTINCT @ManagerCompanyIdatom_Import, @ManagerCompany_IDAddress_Import, 4075976,
		           GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
		    FROM tblAddresses
		    WHERE ID = @ManagerCompany_IDAddress_Import AND ImportID = 1721

			update #MANAGERSCOMPANIES set ManagerCompanyIdatom = a.ManagerCompanyIdatom
			from #MANAGERSCOMPANIES_Distinct a 
			where #MANAGERSCOMPANIES.ManagerCompanyName = a.MANAGERCOMPANYNAME 
			and a.MANAGERCOMPANYCOUNTRY=#MANAGERSCOMPANIES.ManagerCompanyCountry

			insert into tblCompanies2Administrators(idatom, IDRELATED,IdPosition,ShowInReport, IsFormer,IntelligenceID, SourceID, DateReported, DateUpdated,DateStart)
			select distinct @idatom, ManagerCompanyIdatom,ManagerIDPosition,1, 0, @IntelligenceID, @SourceID,getdate(),getdate(),STARTDATE 
			from #MANAGERSCOMPANIES a
			where @idatom is not null and ManagerCompanyIdatom is not null 
			  AND NOT EXISTS (
								SELECT 1
								FROM tblCompanies2Administrators cs
								WHERE cs.IDATOM = @idatom
								AND cs.IDRELATED = a.ManagerCompanyIdatom
								AND ISNULL(cs.IsFormer, 0) = 0
								)
		
		    FETCH NEXT FROM cur_FormerData_Transfer INTO @ManagerCompanyID_Import
		END
		
		CLOSE cur_FormerData_Transfer
		DEALLOCATE cur_FormerData_Transfer



			--return;
			END
		END

		------------------------------------------------------- ShareholderIndividual

		DECLARE @ShareholderIndividualImportID INT,@Shareholderdatom INT,@Shareholder_IDAddress INT
		set @ShareholderIndividualImportID = null
		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - ShareholderIndividuals',getdate(),getdate()) 
		--set @ShareholderIndividualImportID = SCOPE_IDENTITY()
		--@ShareholderIndividualImportID = 1716

			
		update #SHAREHOLDERSINDIVIDUALS_Distinct set ShareholderIdatom = m.PersonIdatom
		from #MANAGERSINDIVIDUALS_Main m
		where #SHAREHOLDERSINDIVIDUALS_Distinct.SHAREHOLDERINDIVIDUALNAME = m.MANAGERINDIVIDUALNAME_New
		and #SHAREHOLDERSINDIVIDUALS_Distinct.ShareholderIdatom IS NULL

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ShareholderIndividualID INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #SHAREHOLDERSINDIVIDUALS_Distinct WITH(NOLOCK)
		where LOWER([SHAREHOLDERINDIVIDUALNAME]) not in (SELECT 
				LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
) AS [MANAGER Full Name]    
				FROM TblPersons p
				JOIN tblCompanies2Shareholders cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  --and isnull(IsFormer,0)=0
				JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDRELATED
				WHERE ISNULL(LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
) , '') <> ''
				and cs.IDATOM=@idatom)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderIndividualID
			WHILE @@FETCH_STATUS = 0
			BEGIN

				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),@CountryCode+'P' as CountryCode, GETDATE() as DateCreated, isnull(IdCountry, @CountryID) as IdRegisteredCountry,1716 as ImportId,ID,1
				from #SHAREHOLDERSINDIVIDUALS_Distinct
				where ID=@ShareholderIndividualID 
			
				SET @Shareholderdatom = SCOPE_IDENTITY()

				update #SHAREHOLDERSINDIVIDUALS_Distinct set ShareholderIdatom = @Shareholderdatom where ID=@ShareholderIndividualID

				------ execute split SP to split person name 
				EXEC [sp_import_SplitPersonNames_Deep] '#SHAREHOLDERSINDIVIDUALS_Distinct','[SHAREHOLDERINDIVIDUALNAME]'

				insert into  tblPersons (IDATOM,LastNameLocal,IdLastNamePrefix,
				FirstNameLocal,IdFirstNamePrefix,
				MiddleNameLocal,IdMiddleNamePrefix,
				MiddleNameLocal2,IdMiddleNamePrefix2,
				MiddleNameLocal3,Idmiddlenameprefix3,
				MiddleNameLocal4,Idmiddlenameprefix4,
				MiddleNameLocal5,Idmiddlenameprefix5,
				MiddleNameLocal6,Idmiddlenameprefix6,
				LastName,FirstName,
				MiddleName,MiddleName2,
				MiddleName3,MiddleName4,
				MiddleName5,MiddleName6,
				UpdatedDate,
				[IdNationality],
				IsBO)
				select distinct
				@Shareholderdatom, 
				IIF(lastname not like '%[Aa-Zz]%',LastName,null),LastNamePrefix,
				IIF(FirstName not like '%[Aa-Zz]%',FirstName,null),FirstNamePrefix,
				IIF(MiddleName1 not like '%[Aa-Zz]%',MiddleName1,null), MiddlePrefix1,
				IIF(MiddleName2 not like '%[Aa-Zz]%',MiddleName2, NULL), MiddlePrefix2,
				IIF(MiddleName3 not like '%[Aa-Zz]%',MiddleName3, NULL), MiddlePrefix3,
				IIF(MiddleName4 not like '%[Aa-Zz]%',MiddleName4, NULL), MiddlePrefix4,
				IIF(MiddleName5 not like '%[Aa-Zz]%',MiddleName5, NULL), MiddlePrefix5,
				IIF(MiddleName6 not like '%[Aa-Zz]%',MiddleName6, NULL), MiddlePrefix6,
				IIF(lastname like '%[Aa-Zz]%',UPPER(LEFT(LastName,1))+LOWER(SUBSTRING(LastName,2,LEN(LastName))),null),
				IIF(FirstName like '%[Aa-Zz]%',UPPER(LEFT(FirstName,1))+LOWER(SUBSTRING(FirstName,2,LEN(FirstName))) ,null),
				IIF(MiddleName1 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName1,1))+LOWER(SUBSTRING(MiddleName1,2,LEN(MiddleName1))) , NULL),
				IIF(MiddleName2 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName2,1))+LOWER(SUBSTRING(MiddleName2,2,LEN(MiddleName2))) , NULL),
				IIF(MiddleName3 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName3,1))+LOWER(SUBSTRING(MiddleName3,2,LEN(MiddleName3))) , NULL),
				IIF(MiddleName4 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName4,1))+LOWER(SUBSTRING(MiddleName4,2,LEN(MiddleName4))) , NULL),
				IIF(MiddleName5 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName5,1))+LOWER(SUBSTRING(MiddleName5,2,LEN(MiddleName5))) , NULL),
				IIF(MiddleName6 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName6,1))+LOWER(SUBSTRING(MiddleName6,2,LEN(MiddleName6))) , NULL),
				GETDATE() UpdatedDate,
				IdNationality,
				1 IsBO
				from #SHAREHOLDERSINDIVIDUALS_Distinct
				where ID=@ShareholderIndividualID
			
				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct isnull(IdCountry, @CountryID), 4075976 as [Primary Business Address], 1716, @Shareholderdatom
				from #SHAREHOLDERSINDIVIDUALS_Distinct
				where id=@ShareholderIndividualID
		  
				SET @Shareholder_IDAddress = SCOPE_IDENTITY()

				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @Shareholderdatom, @Shareholder_IDAddress, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@ShareholderIndividualID and ImportID=1716
				
				set @ShareholderIndividualID = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderIndividualID
		
		END;

			update #SHAREHOLDERSINDIVIDUALS set ShareholderIdatom = a.ShareholderIdatom 
			from #SHAREHOLDERSINDIVIDUALS_Distinct a 
			where #SHAREHOLDERSINDIVIDUALS.ShareholderIdatom is null
			and #SHAREHOLDERSINDIVIDUALS.SHAREHOLDERINDIVIDUALNAME = a.SHAREHOLDERINDIVIDUALNAME 

			INSERT INTO tblCompanies2Shareholders(idatom, idrelated, ShowInReport,SharesNumber,SharesPercent ,IntelligenceID,SourceID, DateUpdated, DateReported,DateStart,IsFormer)
			SELECT distinct @idatom, ShareholderIdatom,1,CONVERT(DECIMAL(19,4),SHARESNUMBER),CONVERT(DECIMAL(19,4),SHAREHOLDERPERCENTAGE),@IntelligenceID,@SourceID,GETDATE(),GETDATE() ,STARTDATE,IsHistory
			FROM #SHAREHOLDERSINDIVIDUALS
			where @idatom is not null and ShareholderIdatom is not null
	
		------------------------------------------------------- SHAREHOLDERSCOMPANIES

		DECLARE @ShareholderCompanyImportID INT,@ShareHolderCompanyIdatom_Import iNT,@ShareholderCompany_IDAddress_Import INT
		set @ShareholderCompanyImportID = null
		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - ShareholderCompany',getdate(),getdate()) 
		--set @ShareholderImportID = SCOPE_IDENTITY()
		--@ShareholderCompanyImportID = 2659
			
		--update i set i.ShareHolderCompanyIdatom = com.idatom
		--from tblatoms a (Nolock)
		--join tblCompanies com (Nolock) on com.idatom = a.idatom
		--join #SHAREHOLDERSCOMPANIES_Distinct i (Nolock) on isnull(com.RegisteredName,com.[Name]) = i.SHAREHOLDERSCOMPANYNAME
		--where 
		--a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		--and i.SHAREHOLDERSCOMPANYNAME is not null

		IF OBJECT_ID ('tempdb..#ShareholderCompanyMatches_Import', 'U') IS NOT NULL
		DROP TABLE #ShareholderCompanyMatches_Import;

		CREATE TABLE #ShareholderCompanyMatches_Import (
			ID INT NOT NULL,
			idatom INT NOT NULL,
			DateUpdated DATETIME NOT NULL
		);

		INSERT INTO #ShareholderCompanyMatches_Import (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #SHAREHOLDERSCOMPANIES_Distinct i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName = i.SHAREHOLDERSCOMPANYNAME
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.SHAREHOLDERSCOMPANYNAME IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		INSERT INTO #ShareholderCompanyMatches_Import (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #SHAREHOLDERSCOMPANIES_Distinct i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName IS NULL
			AND com.[Name] = i.SHAREHOLDERSCOMPANYNAME
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.SHAREHOLDERSCOMPANYNAME IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		CREATE INDEX IX_ShareholderCompanyMatches_Import_ID_Date ON #ShareholderCompanyMatches_Import (ID, DateUpdated DESC) INCLUDE (idatom);

		;WITH Ranked AS (
			SELECT
				ID,
				idatom,
				ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DateUpdated DESC) AS rn
			FROM #ShareholderCompanyMatches_Import
		)
		UPDATE i
		SET i.ShareHolderCompanyIdatom = r.idatom
		FROM #SHAREHOLDERSCOMPANIES_Distinct i
		JOIN Ranked r ON r.ID = i.ID AND r.rn = 1;

		IF OBJECT_ID ('tempdb..#ShareholderCompanyMatches_Import', 'U') IS NOT NULL
		DROP TABLE #ShareholderCompanyMatches_Import;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @ShareholderCompanyID_Import INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		--JP INSERTED
		--select * from #SHAREHOLDERSCOMPANIES_Distinct

		SELECT id
		FROM #SHAREHOLDERSCOMPANIES_Distinct WITH(NOLOCK)
		where LOWER([SHAREHOLDERSCOMPANYNAME]) not in (SELECT 
				LOWER(LTRIM(RTRIM(ISNULL(RegisteredName,Name)))) AS [SHAREHOLDERSCOMPANYNAME]    
				FROM tblCompanies p
				JOIN tblCompanies2Shareholders cs WITH (NOLOCK) ON cs.IDRELATED = p.IDATOM  --and isnull(IsFormer,0)=0
				JOIN TblAtoms atoms WITH (NOLOCK) ON atoms.IDATOM = cs.IDATOM
				WHERE ISNULL(RegisteredName,Name) <> '' and atoms.IdRegisteredCountry=#SHAREHOLDERSCOMPANIES_Distinct.Idcountry
				and cs.IDATOM=@idatom) and Idcountry is not null
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderCompanyID_Import
			WHILE @@FETCH_STATUS = 0
			BEGIN

				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),
				 ca.CountryCode + 'C' AS CountryCode,	
				--@CountryCode+'C' as CountryCode, 
				GETDATE() as DateCreated, isnull(IdCountry, @CountryID) as IdRegisteredCountry,2659 as ImportId,ID,1
				from #SHAREHOLDERSCOMPANIES_Distinct d
				CROSS APPLY (
				    SELECT CountryCode 
				    FROM tblDic_GeoCountries 
				    WHERE Country = d.SHAREHOLDERCOMPANYCOUNTRY
				) ca
				where ID=@ShareholderCompanyID_Import
			
				SET @ShareHolderCompanyIdatom_Import = SCOPE_IDENTITY()

				update #SHAREHOLDERSCOMPANIES_Distinct set ShareHolderCompanyIdatom = @ShareHolderCompanyIdatom_Import where ID=@ShareholderCompanyID_Import

				INSERT INTO [tblcompanies] (IDATOM,RegisteredNameLocal,NameLocal,RegisteredName,Name,
				DateUpdate,IsClient,IsCorrespondent,IsBO
				,CompanyRegisteredLocalNameIntelligenceId,CompanyRegisteredLocalNameSourceId
				,CompanyLocalNameIntelligenceId,CompanyLocalNameSourceId,
				CompanyRegisteredNameIntelligenceId,CompanyRegisteredNameSourceId,
				CompaniesNameIntelligenceId,CompaniesNameSourceId
				) 
				SELECT DISTINCT @ShareHolderCompanyIdatom_Import,
				IIF (SHAREHOLDERSCOMPANYNAME like N'%[أ-ي]%',SHAREHOLDERSCOMPANYNAME,null) as RegisteredNameLocal,
				IIF (SHAREHOLDERSCOMPANYNAME like N'%[أ-ي]%',SHAREHOLDERSCOMPANYNAME,null) as NameLocal,
				IIF (SHAREHOLDERSCOMPANYNAME like N'%[A-Za-Z]%',SHAREHOLDERSCOMPANYNAME,null) as RegisteredName,
				IIF (SHAREHOLDERSCOMPANYNAME like N'%[A-Za-Z]%',SHAREHOLDERSCOMPANYNAME,null) as Name,

				getdate() UpdatedDate,	
				0,0,1 IsBO
				,IIF (SHAREHOLDERSCOMPANYNAME like N'%[أ-ي]%',@IntelligenceID, null),IIF (SHAREHOLDERSCOMPANYNAME like N'%[أ-ي]%',@SourceID, null)
				,IIF (SHAREHOLDERSCOMPANYNAME like N'%[أ-ي]%',@IntelligenceID, null),IIF (SHAREHOLDERSCOMPANYNAME like N'%[أ-ي]%',@SourceID, null)	
				,IIF (SHAREHOLDERSCOMPANYNAME like N'%[A-Za-Z]%',@IntelligenceID, null),IIF (SHAREHOLDERSCOMPANYNAME like N'%[A-Za-Z]%',@SourceID, null)
				,IIF (SHAREHOLDERSCOMPANYNAME like N'%[A-Za-Z]%',@IntelligenceID, null),IIF (SHAREHOLDERSCOMPANYNAME like N'%[A-Za-Z]%',@SourceID, null)		
				from #SHAREHOLDERSCOMPANIES_Distinct
				where @ShareHolderCompanyIdatom_Import is not null 
				and ID=@ShareholderCompanyID_Import
		 
				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct isnull(Idcountry,@CountryID) Idcountry, 4075976 as [Primary Business Address], 2659, @ShareHolderCompanyIdatom_Import		 
				from #SHAREHOLDERSCOMPANIES_Distinct
				where ID=@ShareholderCompanyID_Import

				SET @ShareholderCompany_IDAddress_Import = SCOPE_IDENTITY()

				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @ShareHolderCompanyIdatom_Import, @ShareholderCompany_IDAddress_Import, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@ShareholderCompany_IDAddress_Import and ImportID=2659
				
				set @ShareholderCompanyID_Import = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @ShareholderCompanyID_Import
		
			END;
		
			update #SHAREHOLDERSCOMPANIES set ShareHolderCompanyIdatom = a.ShareHolderCompanyIdatom
			from #SHAREHOLDERSCOMPANIES_Distinct a 
			where #SHAREHOLDERSCOMPANIES.SHAREHOLDERSCOMPANYNAME = a.SHAREHOLDERSCOMPANYNAME 
			and a.SHAREHOLDERCOMPANYCOUNTRY=#SHAREHOLDERSCOMPANIES.SHAREHOLDERCOMPANYCOUNTRY

			insert into tblCompanies2Shareholders(idatom, IDRELATED,SharesPercent,SharesNumber, ShowInReport, IsFormer,IntelligenceID, SourceID, DateReported, DateUpdated,DateStart)
			select distinct @idatom, ShareHolderCompanyIdatom,CONVERT(DECIMAL(19,4),replace(a.SHAREHOLDERPERCENTAGE,'%','')),CONVERT(DECIMAL(19,4),replace(a.SHARESNUMBER,'%','')),
			1, IsHistory, @IntelligenceID, @SourceID,getdate(),getdate(),STARTDATE 
			from #SHAREHOLDERSCOMPANIES a
			where @idatom is not null and ShareHolderCompanyIdatom is not null 


		------------------------------------------------------- HOLDINGS

		DECLARE @HoldingCompanyImportID INT,@HoldingsIdatom iNT,@HoldingCompany_IDAddress INT
		set @HoldingCompanyImportID = null
		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - HoldingCompany',getdate(),getdate()) 
		--set @HoldingCompanyImportID = SCOPE_IDENTITY()
		--@HoldingCompanyImportID = 1719
			
		----update i set i.HoldingsIdatom = com.idatom
		----from tblatoms a (Nolock)
		----join tblCompanies com (Nolock) on com.idatom = a.idatom
		----join #HOLDINGS_Distinct i (Nolock) on isnull(com.RegisteredName,com.[Name]) = i.NAME
		----where 
		----a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		----and i.NAME is not null

		UPDATE i
		SET i.HoldingsIdatom = x.idatom
		FROM #HOLDINGS_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				ISNULL(com.RegisteredName, com.[Name]) = i.[Name]
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.[Name] IS NOT NULL;

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @HoldingCompanyID INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #HOLDINGS_Distinct h WITH(NOLOCK) 
		LEFT JOIN (
			SELECT DISTINCT
				LOWER(LTRIM(RTRIM(REPLACE(REPLACE(COALESCE(c.RegisteredName, c.Name), '  ', ' '), CHAR(160), '')))) COLLATE Latin1_General_CI_AI AS CleanName,
				ISNULL(a.UID, '') AS ExistingCRISNO,
				a.IdRegisteredCountry
			FROM tblCompanies2Shareholders s
			JOIN tblCompanies c ON s.IDATOM = c.IDATOM
			JOIN tblAtoms a ON a.IDATOM = s.IDATOM
			WHERE s.IDRELATED = @idatom
			  AND ISNULL(a.IsDeleted, 0) = 0
		) existing ON LOWER(LTRIM(RTRIM(REPLACE(REPLACE(h.[Name], '  ', ' '), CHAR(160), '')))) COLLATE Latin1_General_CI_AI = existing.CleanName
		and existing.IdRegisteredCountry=idcountry
		WHERE 
		  existing.CleanName IS NULL and idcountry is not null
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @HoldingCompanyID
			WHILE @@FETCH_STATUS = 0
			BEGIN

				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),@CountryCode+'C' as CountryCode, GETDATE() as DateCreated, isnull(IdCountry, @CountryID) as IdRegisteredCountry,1719 as ImportId,ID,1
				from #HOLDINGS_Distinct
				where ID=@HoldingCompanyID
			
				SET @HoldingsIdatom = SCOPE_IDENTITY()

				update #HOLDINGS_Distinct set HoldingsIdatom = @HoldingsIdatom where ID=@HoldingCompanyID

				INSERT INTO [tblcompanies] (IDATOM,RegisteredNameLocal,NameLocal,RegisteredName,Name,
				DateUpdate,IsClient,IsCorrespondent,IsBO
				,CompanyRegisteredLocalNameIntelligenceId,CompanyRegisteredLocalNameSourceId
				,CompanyLocalNameIntelligenceId,CompanyLocalNameSourceId,
				CompanyRegisteredNameIntelligenceId,CompanyRegisteredNameSourceId,
				CompaniesNameIntelligenceId,CompaniesNameSourceId
				) 
				SELECT DISTINCT HoldingsIdatom,
				IIF ([NAME] like N'%[أ-ي]%',[NAME],null) as RegisteredNameLocal,
				IIF ([NAME] like N'%[أ-ي]%',[NAME],null) as NameLocal,
				IIF ([NAME] not like N'%[أ-ي]%',[NAME],null) as RegisteredName,
				IIF ([NAME] not like N'%[أ-ي]%',[NAME],null) as Name,
				getdate() UpdatedDate,	
				0,0,1 IsBO
				,IIF ([NAME] like N'%[أ-ي]%',@IntelligenceID, null),IIF ([NAME] like N'%[أ-ي]%',@SourceID, null)
				,IIF ([NAME] like N'%[أ-ي]%',@IntelligenceID, null),IIF ([NAME] like N'%[أ-ي]%',@SourceID, null)	
				,IIF ([NAME] like N'%[A-Za-Z]%',@IntelligenceID, null),IIF ([NAME] like N'%[A-Za-Z]%',@SourceID, null)
				,IIF ([NAME] like N'%[A-Za-Z]%',@IntelligenceID, null),IIF ([NAME] like N'%[A-Za-Z]%',@SourceID, null)		
				from #HOLDINGS_Distinct
				where @HoldingsIdatom is not null 
				and ID=@HoldingCompanyID
		 
				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct isnull(Idcountry,@CountryID) Idcountry, 4075976 as [Primary Business Address], 1719, @HoldingsIdatom		 
				from #HOLDINGS_Distinct

				SET @HoldingCompany_IDAddress = SCOPE_IDENTITY()

				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @HoldingsIdatom, @HoldingCompany_IDAddress, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@HoldingCompany_IDAddress and ImportID=1719
				
			
			update #HOLDINGS set HoldingsIdatom = a.HoldingsIdatom
			from #HOLDINGS_Distinct a 
			where #HOLDINGS.HoldingsIdatom is null
			and #HOLDINGS.[NAME] = a.[NAME] 
			and a.[ADDRESS]=#HOLDINGS.[ADDRESS]

			insert into tblCompanies2Shareholders(idatom, IDRELATED,SharesPercent, ShowInReport, IsFormer,IntelligenceID, SourceID, DateReported, DateUpdated)
			select distinct  HoldingsIdatom,@idatom,CONVERT(DECIMAL(19,4),replace(a.PERCENTAGE,'%','')),
			1, IsFormer, @IntelligenceID, @SourceID,getdate(),getdate()
			from #HOLDINGS a
			where ID=@HoldingCompanyID and @idatom is not null and HoldingsIdatom is not null 

				set @HoldingCompanyID = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @HoldingCompanyID
		
			END;


		------------------------------------------------------- Directorship

		DECLARE @DirectorshipImportID INT,@DirectorIdatom iNT,@Directorship_IDAddress INT
		set @DirectorshipImportID = null
		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - Directorship',getdate(),getdate()) 
		--set @DirectorshipImportID = SCOPE_IDENTITY()
		--@DirectorshipImportID = 1720
			
		update i set i.DirectorIdatom = com.idatom
		from tblatoms a (Nolock)
		join tblCompanies com (Nolock) on com.idatom = a.idatom
		join #DIRECTORSHIPS_Distinct i (Nolock) on isnull(com.RegisteredName,com.[Name]) = i.NAME
		where 
		a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		and i.NAME is not null

		UPDATE i
		SET i.DirectorIdatom = x.idatom
		FROM #DIRECTORSHIPS_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				isnull(com.RegisteredName,com.[Name]) = i.NAME
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.NAME IS NOT NULL and DirectorIdatom is null

		update i set i.DirectorIdatom = com.idatom
		from tblatoms a (Nolock)
		join tblCompanies com (Nolock) on com.idatom = a.idatom
		join #DIRECTORSHIPS_Distinct i (Nolock) on isnull(com.RegisteredNameLocal,com.[NameLocal]) = i.NameLocal
		where 
		a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		and i.NameLocal is not null and DirectorIdatom is null

		UPDATE i
		SET i.DirectorIdatom = x.idatom
		FROM #DIRECTORSHIPS_Distinct i WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 com.idatom
			FROM tblCompanies com WITH (NOLOCK)
			JOIN tblAtoms a WITH (NOLOCK) ON a.idatom = com.idatom
			WHERE 
				isnull(com.RegisteredNameLocal,com.[NameLocal]) = i.NameLocal
				AND a.IdRegisteredCountry = i.IdCountry
				AND ISNULL(a.IsDeleted, 0) = 0
			ORDER BY 
				a.DateUpdated DESC     -- then use DateUpdated
		) x
		WHERE i.NAME IS NOT NULL and DirectorIdatom is null

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @DirectorshipID INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
				FROM #DIRECTORSHIPS_Distinct d WITH (NOLOCK)
				LEFT JOIN (
			SELECT DISTINCT
				LOWER(LTRIM(RTRIM(REPLACE(REPLACE(
					COALESCE(c.RegisteredName, c.Name, c.RegisteredNameLocal, c.NameLocal),
					'  ', ' '), '.', '')))
				) COLLATE Latin1_General_CI_AI AS CleanName,
				at.IdRegisteredCountry
			FROM tblCompanies2Administrators ca
			JOIN tblCompanies c ON ca.IDRELATED = c.IDATOM
			JOIN tblAtoms at ON at.IDATOM = ca.IDRELATED
			WHERE ca.IDATOM = @idatom
		) existing
			ON LOWER(LTRIM(RTRIM(REPLACE(REPLACE(d.[Name], '  ', ' '), '.', ''))))
				COLLATE Latin1_General_CI_AI = existing.CleanName
				and existing.IdRegisteredCountry=idcountry
		WHERE existing.CleanName IS NULL and Idcountry is not null;


		OPEN cur_FormerData_Transfer
		FETCH NEXT FROM cur_FormerData_Transfer INTO @DirectorshipID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'Processing: ' + CAST(@DirectorshipID AS VARCHAR)

			INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
			SELECT DISTINCT 
				GETDATE(), GETDATE(), @CountryCode + 'C', GETDATE(), IdCountry, 1720, ID, 1
			FROM #DIRECTORSHIPS_Distinct
			WHERE ID = @DirectorshipID

			SET @DirectorIdatom_Update = SCOPE_IDENTITY()

			UPDATE #DIRECTORSHIPS_Distinct
			SET DirectorIdatom = @DirectorIdatom_Update
			WHERE ID = @DirectorshipID
			

			
			INSERT INTO tblCompanies(
				IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
				DateUpdate, IsClient, IsCorrespondent, IsBO,
				CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
				CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
				CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
				CompaniesNameIntelligenceId, CompaniesNameSourceId
			) 
			SELECT DISTINCT
				@DirectorIdatom_Update,
				IIF(NameLocal LIKE N'%[أ-ي]%', NameLocal, NULL),
				IIF(NameLocal LIKE N'%[أ-ي]%', NameLocal, NULL),
				IIF([Name] LIKE N'%[A-Za-Z]%', [Name], NULL),
				IIF([Name] LIKE N'%[A-Za-Z]%', [Name], NULL),
				GETDATE(), 0, 0, 1,
				IIF(NameLocal LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
				IIF(NameLocal LIKE N'%[أ-ي]%', @SourceID, NULL),
				IIF(NameLocal LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
				IIF(NameLocal LIKE N'%[أ-ي]%', @SourceID, NULL),
				IIF([Name] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
				IIF([Name] LIKE N'%[A-Za-Z]%', @SourceID, NULL),
				IIF([Name] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
				IIF([Name] LIKE N'%[A-Za-Z]%', @SourceID, NULL)
			FROM #DIRECTORSHIPS_Distinct
			WHERE ID = @DirectorshipID
			  AND @DirectorIdatom_Update IS NOT NULL

			INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
			SELECT DISTINCT IdCountry, 4075976, 1720, @DirectorIdatom_Update
			FROM #DIRECTORSHIPS_Distinct
			WHERE ID = @DirectorshipID

			SET @Directorship_IDAddress_Update = SCOPE_IDENTITY()

			INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
			SELECT @DirectorIdatom_Update, @Directorship_IDAddress_Update, 4075976, GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
			FROM tblAddresses 
			WHERE ID = @Directorship_IDAddress_Update AND ImportID = 1720

			-- FINAL FIX: Insert link only for this specific record
			PRINT 'Inserting link: DirectorIdatom = ' + CAST(@DirectorIdatom_Update AS NVARCHAR(20)) 
				  + ' -> IDRELATED = ' + CAST(@idatom AS NVARCHAR(20));

			INSERT INTO tblCompanies2Administrators(idatom, idrelated, idposition, ShowInReport, IntelligenceID, SourceID, DateUpdated, DateReported, IsFormer)
			SELECT DISTINCT
				@DirectorIdatom_Update,
				@idatom,
				IdPosition,
				1,
				@IntelligenceID,
				@SourceID,
				GETDATE(),
				GETDATE(),
				IsFormer
			FROM #DIRECTORSHIPS
			WHERE ID = @DirectorshipID       --  only current row
			  AND @idatom IS NOT NULL
			  AND @DirectorIdatom_Update IS NOT NULL
			  and IdPosition is not null;

			-- Move to next record
			FETCH NEXT FROM cur_FormerData_Transfer INTO @DirectorshipID
		END;

		CLOSE cur_FormerData_Transfer;
		DEALLOCATE cur_FormerData_Transfer;

		----------------------------------------------------- #istoricalManagements

		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - import - Managers',getdate(),getdate()) 
		--set @ManagerImportID = SCOPE_IDENTITY()
		--@ManagerUpdateID = 1700
		
			DECLARE @HistoryManagerImportID_Import INT = null,@HistoryPersonIDATOM_Import INT,@HistoryManager_IDAddress_Import INT
			
		IF((SELECT COUNT(*) from #HistoricalManagements where ManagerType='Individual')>0)
		BEGIN		

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @HistoryManagerID_Import INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT ID
		FROM #HistoricalManagements_Main WITH(NOLOCK)
		where ManagerType='Individual' and NOT EXISTS (
			SELECT 1
			FROM TblPersons p
			JOIN tblCompanies2Administrators cs WITH (NOLOCK)
				ON cs.IDRELATED = p.IDATOM AND ISNULL(cs.IsFormer, 0) = 1
			WHERE cs.IDATOM = @idatom
			AND LOWER(
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        ISNULL(p.FirstName, '') + ' ' +
                        ISNULL(p.MiddleName, '') + ' ' +
                        ISNULL(p.MiddleName2, '') + ' ' +
                        ISNULL(p.MiddleName3, '') + ' ' +
                        ISNULL(p.MiddleName4, '') + ' ' +
                        ISNULL(p.MiddleName5, '') + ' ' +
                        ISNULL(p.MiddleName6, '') + ' ' +
                        ISNULL(p.LastName, ''), 
                    '     ', ' '),
                '    ', ' '),
            '   ', ' '),
        '  ', ' ')
    )
)
				= LOWER(LTRIM(RTRIM(#HistoricalManagements_Main.FullName_New)))
		)
		
			OPEN cur_FormerData_Transfer
			FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerID_Import
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				INSERT INTO tblAtoms( DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId,ImportReference,SourceId)
				SELECT distinct GETDATE(), GETDATE(),@CountryCode+'P' as CountryCode, GETDATE() as DateCreated, @CountryID as IdRegisteredCountry,1700 as ImportId,ID,1
				from #HistoricalManagements_Main
				where ID=@HistoryManagerID_Import
			
				SET @HistoryPersonIDATOM_Import = SCOPE_IDENTITY() 
				PRINT 'HistoryPersonIDATOM_Import: ' + CAST(@HistoryPersonIDATOM_Import AS VARCHAR)
				update #HistoricalManagements_Main set PersonIDATOM = @HistoryPersonIDATOM_Import where ID=@HistoryManagerID_Import

				------ execute split SP to split person name 
				EXEC [sp_import_SplitPersonNames_Deep] '#HistoricalManagements_Main','[FullName_New]'

				insert into  tblPersons (IDATOM,LastNameLocal,IdLastNamePrefix,
				FirstNameLocal,IdFirstNamePrefix,
				MiddleNameLocal,IdMiddleNamePrefix,
				MiddleNameLocal2,IdMiddleNamePrefix2,
				MiddleNameLocal3,Idmiddlenameprefix3,
				MiddleNameLocal4,Idmiddlenameprefix4,
				MiddleNameLocal5,Idmiddlenameprefix5,
				MiddleNameLocal6,Idmiddlenameprefix6,
				LastName,FirstName,
				MiddleName,MiddleName2,
				MiddleName3,MiddleName4,
				MiddleName5,MiddleName6,
				UpdatedDate,
				--IdTitle,
				IsBO)
				select distinct
				PersonIDATOM, 
				IIF(lastname not like '%[Aa-Zz]%',LastName,null),LastNamePrefix,
				IIF(FirstName not like '%[Aa-Zz]%',FirstName,null),FirstNamePrefix,
				IIF(MiddleName1 not like '%[Aa-Zz]%',MiddleName1,null), MiddlePrefix1,
				IIF(MiddleName2 not like '%[Aa-Zz]%',MiddleName2, NULL), MiddlePrefix2,
				IIF(MiddleName3 not like '%[Aa-Zz]%',MiddleName3, NULL), MiddlePrefix3,
				IIF(MiddleName4 not like '%[Aa-Zz]%',MiddleName4, NULL), MiddlePrefix4,
				IIF(MiddleName5 not like '%[Aa-Zz]%',MiddleName5, NULL), MiddlePrefix5,
				IIF(MiddleName6 not like '%[Aa-Zz]%',MiddleName6, NULL), MiddlePrefix6,
				IIF(lastname like '%[Aa-Zz]%',UPPER(LEFT(LastName,1))+LOWER(SUBSTRING(LastName,2,LEN(LastName))),null),
				IIF(FirstName like '%[Aa-Zz]%',UPPER(LEFT(FirstName,1))+LOWER(SUBSTRING(FirstName,2,LEN(FirstName))) ,null),
				IIF(MiddleName1 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName1,1))+LOWER(SUBSTRING(MiddleName1,2,LEN(MiddleName1))) , NULL),
				IIF(MiddleName2 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName2,1))+LOWER(SUBSTRING(MiddleName2,2,LEN(MiddleName2))) , NULL),
				IIF(MiddleName3 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName3,1))+LOWER(SUBSTRING(MiddleName3,2,LEN(MiddleName3))) , NULL),
				IIF(MiddleName4 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName4,1))+LOWER(SUBSTRING(MiddleName4,2,LEN(MiddleName4))) , NULL),
				IIF(MiddleName5 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName5,1))+LOWER(SUBSTRING(MiddleName5,2,LEN(MiddleName5))) , NULL),
				IIF(MiddleName6 like '%[Aa-Zz]%',UPPER(LEFT(MiddleName6,1))+LOWER(SUBSTRING(MiddleName6,2,LEN(MiddleName6))) , NULL),
				GETDATE() UpdatedDate,
				--idtitle,
				1 IsBO
				from #HistoricalManagements_Main
				where ID=@HistoryManagerID_Import
			
				INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
				SELECT distinct @CountryID, 4075976 as [Primary Business Address], 1700, PersonIDATOM
				from #HistoricalManagements_Main
				where id=@HistoryManagerID_Import
		  
				SET @HistoryManager_IDAddress_Import = SCOPE_IDENTITY()

				INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
				SELECT distinct @HistoryPersonIDATOM_Import, @HistoryManager_IDAddress_Import, 4075976, GETDATE(),GETDATE(),1 as [IsMain],@IntelligenceID,@SourceID,1
				FROM  tblAddresses where ID=@HistoryManagerID_Import and ImportID=1700
				
				set @HistoryManagerID_Import = null;
 
				FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerID_Import
		
		END;

			update #HistoricalManagements set PersonIDATOM = a.PersonIDATOM 
			from #HistoricalManagements_Main a 
			where #HistoricalManagements.FullName = a.FullName 

			INSERT INTO tblcompanies2administrators(idatom, idrelated, idposition,ShowInReport, IntelligenceID,SourceID, DateUpdated, DateReported,DateStart,DateEnd,IsFormer)
			SELECT distinct @idatom, PersonIDATOM,MANAGERIDPOSITION,1,@IntelligenceID,@SourceID,GETDATE(),GETDATE(),StartDate,EndDate,1  
			FROM #HistoricalManagements
			where @idatom is not null and PersonIdatom is not null and ManagerIdPosition is not null


			--select * from #HistoricalManagements_Main
			--select * from tblcompanies2administrators where IDATOM=@idatom
			--return;

END

		----------------------------------------------------- #istoricalManagements

		--select * from imports order by id desc
		--insert into imports(Name,ImportDate, DateReported)values('DataExchangeProject - Update - HistoryManagerCompany',getdate(),getdate()) 
		--set @ManagerImportID = SCOPE_IDENTITY()
		--@ManagerUpdateID = 1700

		IF(SELECT COUNT(*) from #HistoricalManagements where ManagerType='Company')>0
		BEGIN
		
			DECLARE @HistoryCompanyIDATOM_Import INT,@HistoryCompany_IDAddress_Import INT,@Companyidatom_Import INT
		

			IF((SELECT COUNT(*) from #HistoricalManagements_Main where id is not null and ManagerType='Company')>0)
			--BEGIN

			--	INSERT INTO Crifis.dbo.tblCompanies_OriginalText(IDATOM, Managers, SourceID,IntelligenceID)
			--	SELECT DISTINCT @idatom,(isnull((Select STUFF((SELECT 
			--			IIF(ISNULL([FULLNAME],'')<>'','FULLNAME : ' + [FULLNAME] +char(10) ,'')+
			--			IIF(ISNULL([FULLNAMEARABIC],'')<>'','FULLNAMEARABIC : ' + [FULLNAMEARABIC] +char(10) ,'')
			--			from #HistoricalManagements_Main fd
			--			where @idatom=@idatom and  ManagerType='Company'
			--			FOR xml path('')),1,0,''))+CHAR(10),'')) as Managers,@SourceID,@IntelligenceID
			--	from #HistoricalManagements_Main q
			--	where @idatom is not null
			--	and  ManagerType='Company'

			--END

		BEGIN
			
		IF OBJECT_ID ('tempdb..#HistoryCompanyMatches_Import', 'U') IS NOT NULL
		DROP TABLE #HistoryCompanyMatches_Import;

		CREATE TABLE #HistoryCompanyMatches_Import (
			ID INT NOT NULL,
			idatom INT NOT NULL,
			DateUpdated DATETIME NOT NULL
		);

		INSERT INTO #HistoryCompanyMatches_Import (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #HistoricalManagements_Main i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName = i.FullName
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.FullName IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		INSERT INTO #HistoryCompanyMatches_Import (ID, idatom, DateUpdated)
		SELECT
			i.ID,
			a.IDATOM,
			a.DateUpdated
		FROM #HistoricalManagements_Main i WITH (NOLOCK)
		JOIN tblCompanies com WITH (NOLOCK)
			ON com.RegisteredName IS NULL
			AND com.[Name] = i.FullName
		JOIN tblAtoms a WITH (NOLOCK)
			ON a.IDATOM = com.IDATOM
			AND a.IdRegisteredCountry = i.IdCountry
			AND ISNULL(a.IsDeleted, 0) = 0
		WHERE i.FullName IS NOT NULL
		  AND i.IdCountry IS NOT NULL
		OPTION (RECOMPILE);

		CREATE INDEX IX_HistoryCompanyMatches_Import_ID_Date ON #HistoryCompanyMatches_Import (ID, DateUpdated DESC) INCLUDE (idatom);

		;WITH Ranked AS (
			SELECT
				ID,
				idatom,
				ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DateUpdated DESC) AS rn
			FROM #HistoryCompanyMatches_Import
		)
		UPDATE i
		SET i.Companyidatom = r.idatom
		FROM #HistoricalManagements_Main i
		JOIN Ranked r ON r.ID = i.ID AND r.rn = 1;

		IF OBJECT_ID ('tempdb..#HistoryCompanyMatches_Import', 'U') IS NOT NULL
		DROP TABLE #HistoryCompanyMatches_Import;

		----update i set i.Companyidatom = com.idatom
		----from tblatoms a (Nolock)
		----join tblCompanies com (Nolock) on com.idatom = a.idatom
		----join #DIRECTORSHIPS_Distinct i (Nolock) on isnull(com.RegisteredNameLocal,com.[NameLocal]) = i.NameLocal
		----where 
		----a.IdRegisteredCountry = i.Idcountry and ISNULL(a.IsDeleted,0) = 0 
		----and i.NameLocal is not null and Companyidatom is null

		IF CURSOR_STATUS('global','cur_FormerData_Transfer')>=-1
		BEGIN
			DEALLOCATE cur_FormerData_Transfer
		END
		DECLARE @HistoryManagerCompany_Import INT

		DECLARE cur_FormerData_Transfer CURSOR FOR

		SELECT id
		FROM #HistoricalManagements_Main d
		LEFT JOIN (
			SELECT DISTINCT
				LOWER(LTRIM(RTRIM(REPLACE(REPLACE(
					COALESCE(c.RegisteredName, c.Name, c.RegisteredNameLocal, c.NameLocal),
					'  ', ' '), '.', '')))
				) COLLATE Latin1_General_CI_AI AS CleanName,
				at.IdRegisteredCountry
			FROM tblCompanies2Administrators ca
			JOIN tblCompanies c ON ca.IDRELATED = c.IDATOM and isnull(IsFormer,0)=1
			JOIN tblAtoms at ON at.IDATOM = ca.IDATOM 
			WHERE ca.IDATOM = @idatom
		) existing
			ON LOWER(LTRIM(RTRIM(REPLACE(REPLACE(d.FullName, '  ', ' '), '.', ''))))
				COLLATE Latin1_General_CI_AI = existing.CleanName
				and existing.IdRegisteredCountry=idcountry
		WHERE existing.CleanName IS NULL and ManagerType='Company' and idcountry is not null;


OPEN cur_FormerData_Transfer
FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerCompany_Import

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing: ' + CAST(@HistoryManagerCompany_Import AS VARCHAR)

    INSERT INTO tblAtoms(DateReported, DateUpdated, CountryCode, DateCreated, IdRegisteredCountry, ImportId, ImportReference, SourceId)
    SELECT DISTINCT 
        GETDATE(), GETDATE(), @CountryCode + 'C', GETDATE(), IdCountry, 2655, ID, 1
    FROM #HistoricalManagements_Main
    WHERE ID = @HistoryManagerCompany_Import

    SET @Companyidatom_Import = SCOPE_IDENTITY()

    UPDATE #HistoricalManagements_Main
    SET Companyidatom = @Companyidatom_Import
    WHERE ID = @HistoryManagerCompany_Import

    INSERT INTO tblCompanies(
        IDATOM, RegisteredNameLocal, NameLocal, RegisteredName, Name,
        DateUpdate, IsClient, IsCorrespondent, IsBO,
        CompanyRegisteredLocalNameIntelligenceId, CompanyRegisteredLocalNameSourceId,
        CompanyLocalNameIntelligenceId, CompanyLocalNameSourceId,
        CompanyRegisteredNameIntelligenceId, CompanyRegisteredNameSourceId,
        CompaniesNameIntelligenceId, CompaniesNameSourceId
    ) 
    SELECT DISTINCT
        @Companyidatom_Import,
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', [FullNameArabic], NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', [FullNameArabic], NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', [FullName], NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', [FullName], NULL),
        GETDATE(), 0, 0, 1,
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @SourceID, NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @IntelligenceID, NULL),
        IIF([FullNameArabic] LIKE N'%[أ-ي]%', @SourceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @SourceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @IntelligenceID, NULL),
        IIF([FullName] LIKE N'%[A-Za-Z]%', @SourceID, NULL)
    FROM #HistoricalManagements_Main
    WHERE ID = @HistoryManagerCompany_Import
      AND @Companyidatom_Import IS NOT NULL

    INSERT INTO tblAddresses(IdCountry, AddressTypeID, ImportID, IDATOM)
    SELECT DISTINCT IdCountry, 4075976, 2655, @Companyidatom_Import
    FROM #HistoricalManagements_Main
    WHERE ID = @HistoryManagerCompany_Import and IdCountry is not null

    SET @HistoryCompany_IDAddress_Import = SCOPE_IDENTITY()

    INSERT INTO tblAtoms2Addresses(IDATOM, IdAddress, IdType, DateUpdated, DateReported, IsMain, GradingID, SourceID, ShowInReport)
    SELECT @Companyidatom_Import, @HistoryCompany_IDAddress_Import, 4075976, GETDATE(), GETDATE(), 1, @IntelligenceID, @SourceID, 1
    FROM tblAddresses 
    WHERE ID = @HistoryCompany_IDAddress_Import AND ImportID = 2655

    -- FINAL FIX: Insert link only for this specific record
    PRINT 'Inserting link: HistoryCompanyidatomImport = ' + CAST(@Companyidatom_Import AS NVARCHAR(20)) 
          + ' -> IDRELATED = ' + CAST(@idatom AS NVARCHAR(20));

    INSERT INTO tblCompanies2Administrators(idatom, idrelated, idposition, ShowInReport, IntelligenceID, SourceID, DateUpdated, DateReported, IsFormer)
    SELECT DISTINCT
		@idatom,
        @Companyidatom_Import,
        ManagerIdPosition,
        1,
        @IntelligenceID,
        @SourceID,
        GETDATE(),
        GETDATE(),
        1
    FROM #HistoricalManagements
    WHERE ID = @HistoryManagerCompany_Import       --  only current row
      AND @idatom IS NOT NULL
      AND @Companyidatom_Import IS NOT NULL
	  and ManagerIdPosition is not null;

    -- Move to next record
    FETCH NEXT FROM cur_FormerData_Transfer INTO @HistoryManagerCompany_Import
END;

CLOSE cur_FormerData_Transfer;
DEALLOCATE cur_FormerData_Transfer;

			--select * from #HistoricalManagements_Main
			--return;
--END
END

END

	------------------------------------------------------- Financials -------------------------------------------------------

		insert into tblCompanies_Financials(
		idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo)
		select distinct @idatom,IdCurrency,YEAR(FinancialDate_new),1,1,1,15,FinancialDate_new,RIGHT(FinancialDate_new,5), getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,MONTH(FinancialDate_new)
		from #Financials ci
		where @idatom is not null

		--[Financials]
		insert into tblCompanies_Financials_FieldValues(IdFinancial,IdField,FinancialValue)
		select distinct cf.id,ci.IdField,ci.FinancialValue
		from tblCompanies_Financials cf
		join #Financials ci on @idatom = cf.idatom  and FinancialYear=YEAR(FinancialDate_new) 
		where @idatom is not null and ci.FinancialValue is not null and IdField is not null

		--select * from #Financials

	-------------------------------------------------------------phase2--FinancialComparison-------------------------------------------------------------------------------

		IF((select count(*) from #FinancialAnalyses)>0)
		BEGIN
			
			INSERT INTO tblCompanies_Financials(
			idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo, ImportID)
			SELECT DISTINCT @idatom,IdCurrency,[YEAR],
			CASE WHEN Denomination = 'Standard' THEN 1 
				 WHEN Denomination = 'Thousands' THEN 1000
				 WHEN Denomination = 'Millions' THEN 1000000 ELSE 1 END as Denominator,
			CASE WHEN [TYPE] = 'Consolidated' THEN 1 ELSE 0 END as IsConsolidated,
			CASE WHEN [AUDIT] = 'Audited' THEN 1 
				 WHEN [AUDIT] = 'UnAudited' THEN 2
				 WHEN [AUDIT] = 'Estimated' THEN 3
				 WHEN [AUDIT] = 'Projected' THEN 4 END as isaudited,
			15,FinancialDate_new,LEFT(FORMAT(FinancialDate_new,'dd/MM/yyyy'),5), 
			getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,MONTHSNO,1696
			from #FinancialAnalyses ci
			where 
				[YEAR] not in(select FinancialYear from tblCompanies_Financials c where c.idatom = @idatom);
			
			SET IDENTITY_INSERT dbo.tblCompanies_FinancialsAdditional ON;

			delete from tblCompanies_Financials_FieldValuesAdditional where idFinancial in (select id from tblCompanies_FinancialsAdditional where idatom=@idatom 
			and FinancialYear in (select [YEAR] from #FinancialAnalyses)
			and IsConsolidated in (select IsConsolidated from #FinancialAnalyses))

			delete from tblCompanies_FinancialsAdditional where idatom=@idatom and FinancialYear in (select [YEAR] from #FinancialAnalyses) and IsConsolidated in (select IsConsolidated from #FinancialAnalyses)

			INSERT INTO tblCompanies_FinancialsAdditional(ID,
			idatom,IdCurrency,FinancialYear,Denominator,IsConsolidated,isaudited,IdStandard,PeriodEnding,FinancialYearEnds,DateReported,DateUpdated, SourceID, IntelligenceID, MonthsNo, ImportID)
			SELECT DISTINCT l.ID, @idatom,ci.IdCurrency,[YEAR],
			CASE WHEN Denomination = 'Standard' THEN 1 
				 WHEN Denomination = 'Thousands' THEN 1000
				 WHEN Denomination = 'Millions' THEN 1000000 ELSE 1  END as Denominator,
			CASE WHEN [TYPE] = 'Consolidated' THEN 1 ELSE 0 END as IsConsolidated,
			CASE WHEN [AUDIT] = 'Audited' THEN 1 
					WHEN [AUDIT] = 'UnAudited' THEN 2
					WHEN [AUDIT] = 'Estimated' THEN 3
					WHEN [AUDIT] = 'Projected' THEN 4 END as isaudited,
			15,FinancialDate_new,LEFT(FORMAT(FinancialDate_new,'dd/MM/yyyy'),5), 
			getdate(), getdate() UpdatedDate, @SourceID,@IntelligenceID,ci.MONTHSNO,1696
			from 
			#FinancialAnalyses ci
			join tblCompanies_Financials l on l.IDATOM = @idatom and [YEAR] = l.FinancialYear and l.IsConsolidated=ci.IsConsolidated 
			where 
			l.id not in(select id from tblCompanies_FinancialsAdditional where IDATOM = @idatom)
			
			SET IDENTITY_INSERT dbo.tblCompanies_FinancialsAdditional OFF;

			--select * INTO JDP_TMP_FINANAL from #FinancialAnalyses
			
			INSERT INTO tblCompanies_Financials_FieldValuesAdditional(IdFinancial,IdField,FinancialValue, ImportID)
			SELECT DISTINCT cf.id,ci.IdField,ci.FinancialValue,1696
			from tblCompanies_FinancialsAdditional cf
			join #FinancialAnalyses ci on @idatom = cf.idatom and FinancialYear=[YEAR] and cf.IsConsolidated=ci.IsConsolidated 
			where 
			ci.FinancialValue is not null and IdField is not null

			-------------------JDP START
			DECLARE @FinID2 INT=0
			Declare @HiddenOut2 int
			DECLARE CCcursor CURSOR
				FOR Select distinct id from tblCompanies_FinancialsAdditional 
					where idatom=@idatom and FinancialYear in (select [YEAR] from #FinancialAnalyses)
			OPEN CCcursor
			FETCH NEXT FROM CCcursor INTO @FinID2
			WHILE @@FETCH_STATUS = 0
			BEGIN
				exec @HiddenOut2=spCR_FinancialsSave_Primary_FromExcel @FinID2
			FETCH NEXT FROM CCcursor INTO @FinID2
			END
			
			CLOSE CCcursor
			DEALLOCATE CCcursor

			DECLARE @tmpNewValue2 TABLE (newvalue int)
			INSERT INTO @tmpNewValue 
			EXEC @HiddenOut2=ScoreCard_Get @idatom
			-------------------JDP END
		
		END	

		----JP ADDED TO UPDATE ORDER WITH NEW IDATOM
		if ISNULL(@orderid,0)<>0
		BEGIN
			Declare @OrderIDATOM int
			Select @OrderIDATOM = ISNULL(IDATOM,0) from cs_orders where id=@orderid
			IF (@OrderIDATOM<>@idatom)
				UPDATE cs_orders SET IDATOM=@idatom where id=@orderid
		END
			print '---IMPORT DONE---'
			select 1
END

	ELSE IF (ISNULL(@UID,'')='' and ISNULL(@idatom,0)=0 AND (SELECT COUNT(*) FROM #REGISTERS) = 0)
	BEGIN

		PRINT '---IMPORT/UPDATE FAILED - NO REGISTER INFO---'
		select 2

	END

---============================================================[IMPORT END]============================================================---

		COMMIT TRANSACTION;

END TRY

BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE 
        --@ErrorMessage NVARCHAR(MAX),
        --@ErrorSeverity INT,
        --@ErrorState INT,
        @ErrorLine INT,
        @ProcName NVARCHAR(200);

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorLine = ERROR_LINE(),
        @ProcName = ERROR_PROCEDURE();

    RAISERROR(
        'Error in procedure %s at line %d: %s',
        @ErrorSeverity, @ErrorState,
        @ProcName, @ErrorLine, @ErrorMessage
    );

    insert into [dbo].[tblErrors](Error,CreationDate,SP, InputParams)
		select  @ErrorMessage, getdate(),@ProcName,@orderid

END CATCH;
--select top 10 * from [dbo].[tblErrors] order by id desc

END
GO


