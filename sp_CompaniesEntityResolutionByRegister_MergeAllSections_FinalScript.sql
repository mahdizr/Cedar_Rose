USE [ADIP]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Jihene / Unified by Cursor Assistant
-- Description: Unified merge procedure for company entity resolution
-- Note: This procedure inlines logic from comments/profile/D&S/addresses/other scripts.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CompaniesEntityResolutionByRegister_MergeAllSections_FinalScript]
AS
BEGIN

	/* ==================== COMMENTS SECTION (START) ==================== */
	SET NOCOUNT ON;


	-------------------------------MAIN QUERY
--	WITH RankedData AS (
	--SELECT 
		--	    d.*,
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		--		FROM ADIP.dbo.DuplicateCompanies d
	--	)
	--select distinct 
	--		registernumber,
	--		b.dummyname As [Register Description],
	--		[HasOrders_1],
	--		[HasOrders_2],
	
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_1, DateUpdated_2),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_1, DateUpdated_2) 
	--	) [Update Date to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_2, DateUpdated_1),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_2, DateUpdated_1) 
	--	) [Update Date to Delete],
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
	--	) [idatom to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
	--	) [idatom to Delete]

	--FROM RankedData d
	--join TestCrifis2.dbo.tblDic_BaseValues b on b.id= d.IdRegister;


	--------------------------------------- Internal Notes-------------------------------------------------
	
		----- Idatom to delete have an internal note but Idatom To keep does not have internal notes
	
	;WITH RankedData AS (
			SELECT 
			   d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set IdComment_InternalNote = a.IdComment_InternalNote
	
	--Select [idatom to keep], [idatom to delete], a.IdComment_InternalNote, c.DummyName
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join TestCrifis2.dbo.tblcompanies a on a.idatom = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment_InternalNote

	left join TestCrifis2.dbo.tblcompanies a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment_InternalNote
	WHERE a.IdComment_InternalNote is not null
	and ISNULL(c.DummyName, '')!=''
	--and [idatom to keep] = 71933686


	------ IDatom to keep have Internal Note but  idatom to delete does not have Internal Note
	----- to test + test the count for all below conditions

	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + CHAR(10)+'The company was merged with the information from idatom '  + ISNULL(CAST([idatom to delete] AS NVARCHAR(20)), 0)
	--Select  [idatom to delete],[idatom to keep], c2.dummyname as dummynamedKept, ISNULL(c2.dummyname,'') +  CHAR(10)+'The company was merged with the information from idatom '  + ISNULL(CAST([idatom to delete] AS NVARCHAR(20)), 0) as dummynamedKeptUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	
	left join TestCrifis2.dbo.tblcompanies a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment_InternalNote
	WHERE a2.IdComment_InternalNote is not null
	and ISNULL(c2.DummyName, '')!=''
	--and [idatom to keep]=46949936


	------ IDatom to keep and idatom to delete both have Internal Notes

	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + char(10) +	c.dummyname + CHAR(10)+'The company was merged with the information from idatom '  + ISNULL(CAST([idatom to delete] AS NVARCHAR(20)), 0)
	--Select  [idatom to delete],c.dummyname as dummynamedDleted  ,[idatom to keep], c2.dummyname as dummynamedKept, ISNULL(c2.dummyname,'') + char(10) +	c.dummyname + CHAR(10)+'The company was merged with the information from idatom '  + ISNULL(CAST([idatom to delete] AS NVARCHAR(20)), 0) as dummynamedKeptUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join TestCrifis2.dbo.tblcompanies a on a.idatom = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment_InternalNote

	left join TestCrifis2.dbo.tblcompanies a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment_InternalNote
	WHERE a2.IdComment_InternalNote is not null
	and a.IdComment_InternalNote is not null
	--and ISNULL(c.DummyName, '')!=''
	and c.DummyName <> c2.DummyName
	--and [idatom to keep]=46983122




	------------ both Idatom to keep and Idatom to delete do not have an internal note

--DECLARE @ImportId 
--select * from [TestCrifis2].[dbo].imports order by id desc
INSERT INTO TestCrifis2.[dbo].imports([Name],ImportDate, DateReported)values('Entity Resolution Insert Internal Note - Jordan',GETDATE(),'2025-09-09')  


;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

INSERT into TestCrifis2.[dbo].[tblDic_Comments] (DummyName,importId,IdStartDate,importIdRequestedNotes)
select 'The company was merged with the information from idatom '  + ISNULL(CAST([idatom to delete] AS NVARCHAR(20)), 0)
,2428 as importId, a.idatom, 2 as importIdRequestedNotes

from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join TestCrifis2.dbo.tblcompanies a on a.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment_InternalNote
	left join TestCrifis2.dbo.tblcompanies a2 on a2.idatom = b.[idatom to Delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment_InternalNote
	where isnull(c.dummyname,'')= '' and isnull(c2.dummyname,'')= ''
	--and [idatom to keep]= 13739507


	update TestCrifis2.[dbo].[tblCompanies] set IdComment_InternalNote = a.ID
	from TestCrifis2.[dbo].[tblDic_Comments] a
	where TestCrifis2.[dbo].[tblCompanies].IDATOM = a.IdStartDate
	and a.importid = 2428 and importIdRequestedNotes = 2
	--and idatom = 13739507

	----------------------------------Historical comment
	--select * from TestCrifis2.dbo.tblDic_Comments 
	--where IdStartDate = 13454351 

	--------------------------------------Register Comment--------------------------------------------------------------------

	------ IDatom to keep have Register Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	--Select [idatom to keep], [idatom to delete],a2.Number, c2.DummyName, c.DummyName, ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanyIDs a on a.idatom = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanyIDs a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is not null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and c.DummyName <> c2.DummyName
	and a.Number = a2.Number
	--and [idatom to delete] = 70428680

	------- Idatom To keep does not have Register Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.IdComment= a.IdComment
	--Select [idatom to keep], [idatom to delete], a.IdComment, c.DummyName
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanyIDs a on a.idatom = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanyIDs a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and a.Number = a2.Number
	--and [idatom to keep] =13500278

	

	--------------------------------------Addresse Description1---------------------------------------------

	------ IDatom to keep have Description1
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE adrs set Description1 = ISNULL(adrs.Description1,'') + char(10) +	adr.Description1
	--Select [idatom to keep], [idatom to delete],adrs.Description1, adr.Description1, ISNULL(adrs.Description1,'') + char(10) +	adr.Description1
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to delete]
	left join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	left join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	WHERE  ISNULL(adr.Description1, '')!=''
	and adrs.Description1 <> adr.Description1
	and ad.IsMain = ad2.IsMain
	and ad.IdType = ad2.IdType
	and adr.IdTown = adrs.IdTown
	--and [idatom to delete] = 70398710


	----- Idatom To keep does not have Description
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update adrs set adrs.Description1 = adr.Description1
	--Select [idatom to keep], [idatom to delete], adrs.Description1, adr.Description1
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to delete]
	left join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	left join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	WHERE  ISNULL(adr.Description1, '')!=''
	and  ISNULL(adrs.Description1, '')=''
	and ad.IsMain = ad2.IsMain
	and ad.IdType = ad2.IdType
	and adr.IdTown = adrs.IdTown
	--and [idatom to delete] =46765867


	--------------------------------------Relations Comment------------------------------------------------------------------

	------------------ Using IDATOM
	------ IDatom to keep have Relations Comment

	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	--Select [idatom to keep], [idatom to delete],a2.IdTypeRelated, c2.DummyName, c.DummyName, ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_Related a on a.idatom = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Related a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is not null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and c.DummyName <> c2.DummyName
	and a.IdTypeRelated = a2.IdTypeRelated
	--and [idatom to delete] = 70428680

	
	----- Idatom To keep does not have Relations Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.IdComment= a.IdComment
	--Select [idatom to keep], [idatom to delete], a.IdComment, c.DummyName
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_Related a on a.idatom = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Related a2 on a2.idatom = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and a.IdTypeRelated = a2.IdTypeRelated

	-------------------- Using IDRELATED

	------ IDatom to keep have Relations Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	--Select [idatom to keep], [idatom to delete],a2.IdTypeRelated, c2.DummyName, c.DummyName, ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_Related a on a.IDRELATED = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Related a2 on a2.IDRELATED = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is not null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and c.DummyName <> c2.DummyName
	and a.IdTypeRelated = a2.IdTypeRelated
	--and [idatom to delete] = 70428680


	----- Idatom To keep does not have Relations Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.IdComment= a.IdComment
	--Select [idatom to keep], [idatom to delete], a.IdComment, c.DummyName
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_Related a on a.IDRELATED = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Related a2 on a2.IDRELATED = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and a.IdTypeRelated = a2.IdTypeRelated



	--------------------------------- Employees Comment --------------------------------------------------------------------

	---- IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)
	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	--Select [idatom to keep], [idatom to delete],a2.year, c2.DummyName, c.DummyName, ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_Employees a on a.IDATOM = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Employees a2 on a2.IDATOM = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is not null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and c.DummyName <> c2.DummyName
	and a.Year = a2.Year


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.IdComment= a.IdComment
	--Select [idatom to keep], [idatom to delete], a.IdComment, c.DummyName
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_Employees a on a.IDATOM = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Employees a2 on a2.IDATOM = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and a.year = a2.year


	--------------------------------- Financials Comment

	------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE c2 set DummyName = ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	--Select [idatom to keep], [idatom to delete],a2.FinancialYear, c2.DummyName, c.DummyName, ISNULL(c2.dummyname,'') + char(10) +	c.dummyname
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_Financials a on a.IDATOM = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Financials a2 on a2.IDATOM = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is not null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and c.DummyName <> c2.DummyName
	and a.FinancialYear = a2.FinancialYear
	and a.IsConsolidated = a2.IsConsolidated


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set IdComment= a.IdComment
	--Select [idatom to keep], [idatom to delete], a.IdComment, c.DummyName, a.FinancialYear
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_Financials a on a.IDATOM = b.[idatom to delete] 
	Left join TestCrifis2.dbo.tblDic_Comments c on c.ID = a.IdComment

	left join [TestCrifis2].[dbo].tblCompanies_Financials a2 on a2.IDATOM = b.[idatom to keep] 
	Left join TestCrifis2.dbo.tblDic_Comments c2 on c2.ID = a2.IdComment
	WHERE a2.IdComment is null
	and a.IdComment is not null
	and ISNULL(c.DummyName, '')!=''
	and a.FinancialYear = a2.FinancialYear
	and a.IsConsolidated = a2.IsConsolidated

	------------------------------------------Debt Collection --------------------------------


	--------add when empty
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)
	update  a set idatom = [idatom to keep]		 
	--Select [idatom to keep], [idatom to delete],  a.DebtAgencies_Notes,  a2.DebtAgencies_Notes
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies2Searchers a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies2Searchers a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE a.ID is not null
	and [idatom to keep]  not in (select idatom from [TestCrifis2].[dbo].tblCompanies2Searchers)
	--and [idatom to Delete]= 13640264
	
	
	------------Both companies have Debt collection --> copy the comment when both have the same type

	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set  DebtAgencies_Notes = ISNULL( a2.DebtAgencies_Notes,'') + char(10) +	 a.DebtAgencies_Notes
	--Select [idatom to keep], [idatom to delete], a2.IdDebtAgencies, a.IdDebtAgencies, a2.DebtAgencies_Notes, a.DebtAgencies_Notes, ISNULL(a2.DebtAgencies_Notes,'') + char(10) +	a.DebtAgencies_Notes
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies2Searchers a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies2Searchers a2 on a2.IDATOM = b.[idatom to keep] 
	
	WHERE ISNULL(a.DebtAgencies_Notes , '')!=''
	and a.IdDebtAgencies <> a2.IdDebtAgencies


	-----------------------------------------------------Shareholder Originals - Shareholders Owners------------------------------------------------
	------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Shareholders_Owners = ISNULL(a2.Shareholders_Owners,'') + char(10) +	a.Shareholders_Owners
	--Select [idatom to keep], [idatom to delete], a2.Shareholders_Owners, a.Shareholders_Owners, ISNULL(a2.Shareholders_Owners,'') + char(10) + a.Shareholders_Owners
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Shareholders_Owners, '')!=''
	and ISNULL(a2.Shareholders_Owners, '')!=''
	and a2.Shareholders_Owners <> a.Shareholders_Owners


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Shareholders_Owners= a.Shareholders_Owners
	--Select [idatom to keep], [idatom to delete], a.Shareholders_Owners, a2.Shareholders_Owners
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Shareholders_Owners, '')=''
	and ISNULL(a.Shareholders_Owners, '')!=''

	-----------------------------------------------------Shareholder Originals - Shareholders Owners Details------------------------------------------------
		------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Shareholders_Owners_Details_Profile = ISNULL(a2.Shareholders_Owners_Details_Profile,'') + char(10) +	a.Shareholders_Owners_Details_Profile
	--Select [idatom to keep], [idatom to delete], a2.Shareholders_Owners_Details_Profile, a.Shareholders_Owners_Details_Profile, ISNULL(a2.Shareholders_Owners_Details_Profile,'') + char(10) + a.Shareholders_Owners_Details_Profile
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Shareholders_Owners_Details_Profile, '')!=''
	and ISNULL(a2.Shareholders_Owners_Details_Profile, '')!=''
	and a2.Shareholders_Owners_Details_Profile <> a.Shareholders_Owners_Details_Profile


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Shareholders_Owners_Details_Profile= a.Shareholders_Owners_Details_Profile
	--Select [idatom to keep], [idatom to delete], a.Shareholders_Owners_Details_Profile, a2.Shareholders_Owners_Details_Profile
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Shareholders_Owners_Details_Profile, '')=''
	and ISNULL(a.Shareholders_Owners_Details_Profile, '')!=''
	
	-----------------------------------------------------Managers Originals------------------------------------------------
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Managers = ISNULL(a2.Managers,'') + char(10) +	a.Managers
	--Select [idatom to keep], [idatom to delete], a2.Managers, a.Managers, ISNULL(a2.Managers,'') + char(10) + a.Managers
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Managers, '')!=''
	and ISNULL(a2.Managers, '')!=''
	and a2.Managers <> a.Managers


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Managers= a.Managers
	--Select [idatom to keep], [idatom to delete], a.Managers, a2.Managers
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Managers, '')=''
	and ISNULL(a.Managers, '')!=''


		-----------------------------------------------------Relation Originals------------------------------------------------
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set MASRI_Auditors = ISNULL(a2.MASRI_Auditors,'') + char(10) +	a.MASRI_Auditors
	--Select [idatom to keep], [idatom to delete], a2.MASRI_Auditors, a.MASRI_Auditors, ISNULL(a2.MASRI_Auditors,'') + char(10) + a.MASRI_Auditors
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.MASRI_Auditors, '')!=''
	and ISNULL(a2.MASRI_Auditors, '')!=''
	and a2.MASRI_Auditors <> a.MASRI_Auditors

	--select top 1* from [TestCrifis2].[dbo].tblCompanies_OriginalText where idatom = 13454351

	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.MASRI_Auditors= a.MASRI_Auditors
	--Select [idatom to keep], [idatom to delete], a.MASRI_Auditors, a2.MASRI_Auditors
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.MASRI_Auditors, '')=''
	and ISNULL(a.MASRI_Auditors, '')!=''


	-----------------------------------------------------Activities comment------------------------------------------------
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Activities_Comment = ISNULL(a2.Activities_Comment,'') + char(10) +	a.Activities_Comment
	--Select [idatom to keep], [idatom to delete], a2.Activities_Comment, a.Activities_Comment, ISNULL(a2.Activities_Comment,'') + char(10) + a.Activities_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Activities_Comment, '')!=''
	and ISNULL(a2.Activities_Comment, '')!=''
	and a2.Activities_Comment <> a.Activities_Comment


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Activities_Comment= a.Activities_Comment,
	a2.IntelligenceID = a.IntelligenceID, 
	a2.SourceID = a.SourceID
	--Select [idatom to keep], [idatom to delete], a.Activities_Comment, a2.Activities_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Activities_Comment, '')=''
	and ISNULL(a.Activities_Comment, '')!=''

	-----------------------------------------------------Payment Method------------------------------------------------
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Pay_Method = ISNULL(a2.Pay_Method,'') + char(10) +	a.Pay_Method
	--Select [idatom to keep], [idatom to delete], a2.Pay_Method, a.Pay_Method, ISNULL(a2.Pay_Method,'') + char(10) + a.Pay_Method
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Pay_Method, '')!=''
	and ISNULL(a2.Pay_Method, '')!=''
	and a2.Pay_Method <> a.Pay_Method


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Pay_Method= a.Pay_Method
	--Select [idatom to keep], [idatom to delete], a.Pay_Method, a2.Pay_Method
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Pay_Method, '')=''
	and ISNULL(a.Pay_Method, '')!=''

	-----------------------------------------------------Premises Comment------------------------------------------------
				------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Premises_Comment = ISNULL(a2.Premises_Comment,'') + char(10) +	a.Premises_Comment
	--Select [idatom to keep], [idatom to delete], a2.Premises_Comment, a.Premises_Comment, ISNULL(a2.Premises_Comment,'') + char(10) + a.Premises_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Premises_Comment, '')!=''
	and ISNULL(a2.Premises_Comment, '')!=''
	and a2.Premises_Comment <> a.Premises_Comment


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Premises_Comment= a.Premises_Comment
	--Select [idatom to keep], [idatom to delete], a.Premises_Comment, a2.Premises_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Premises_Comment, '')=''
	and ISNULL(a.Premises_Comment, '')!=''

	-----------------------------------------------------History Comment--------------------------------------------------
		------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Company_History = ISNULL(a2.Company_History,'') + char(10) +	a.Company_History
	--Select [idatom to keep], [idatom to delete], a2.Company_History, a.Company_History, ISNULL(a2.Company_History,'') + char(10) + a.Company_History
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Company_History, '')!=''
	and ISNULL(a2.Company_History, '')!=''
	and a2.Company_History <> a.Company_History


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Company_History= a.Company_History
	--Select [idatom to keep], [idatom to delete], a.Company_History, a2.Company_History
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Company_History, '')=''
	and ISNULL(a.Company_History, '')!=''

	-----------------------------------------------------Financial Comment------------------------------------------------
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Financial_Comment = ISNULL(a2.Financial_Comment,'') + char(10) +	a.Financial_Comment
	--Select [idatom to keep], [idatom to delete], a2.Financial_Comment, a.Financial_Comment, ISNULL(a2.Financial_Comment,'') + char(10) + a.Financial_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Financial_Comment, '')!=''
	and ISNULL(a2.Financial_Comment, '')!=''
	and a2.Financial_Comment <> a.Financial_Comment


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Financial_Comment= a.Financial_Comment
	--Select [idatom to keep], [idatom to delete], a.Financial_Comment, a2.Financial_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Financial_Comment, '')=''
	and ISNULL(a.Financial_Comment, '')!=''

	-----------------------------------------------------Brands Comments------------------------------------------------
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Brands_Comment = ISNULL(a2.Brands_Comment,'') + char(10) +	a.Brands_Comment
	--Select [idatom to keep], [idatom to delete], a2.Brands_Comment, a.Brands_Comment, ISNULL(a2.Brands_Comment,'') + char(10) + a.Brands_Comment
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Brands_Comment, '')!=''
	and ISNULL(a2.Brands_Comment, '')!=''
	and a2.Brands_Comment <> a.Brands_Comment


	----- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Brands_Comment= a.Brands_Comment
	--Select [idatom to keep], [idatom to delete], a.Company_History, a2.Company_History
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Brands_Comment, '')=''
	and ISNULL(a.Brands_Comment, '')!=''

	-----------------------------------------------------Import Export Originals------------------------------------------------
	----## Import From
			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Import_From = ISNULL(a2.Import_From,'') + char(10) +	a.Import_From
	--Select [idatom to keep], [idatom to delete], a2.Import_From, a.Import_From, ISNULL(a2.Import_From,'') + char(10) + a.Import_From
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Import_From, '')!=''
	and ISNULL(a2.Import_From, '')!=''
	and a2.Import_From <> a.Import_From


	--- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Import_From= a.Import_From
	--Select [idatom to keep], [idatom to delete], a.Import_From, a2.Import_From
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Import_From, '')=''
	and ISNULL(a.Import_From, '')!=''

	--## Export to

			------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Export_To = ISNULL(a2.Export_To,'') + char(10) +	a.Export_To
	--Select [idatom to keep], [idatom to delete], a2.Export_To, a.Export_To, ISNULL(a2.Export_To,'') + char(10) + a.Export_To
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Export_To, '')!=''
	and ISNULL(a2.Export_To, '')!=''
	and a2.Export_To <> a.Export_To


	--- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Export_To= a.Export_To
	--Select [idatom to keep], [idatom to delete], a.Export_To, a2.Export_To
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Export_To, '')=''
	and ISNULL(a.Export_To, '')!=''

	
	--select Annual_Profit, Annual_Sales, Financial_Statement, Invested_Capital, Owners_Equity, Total_Assets, Import_Value, Export_Value 
	--from [TestCrifis2].[dbo].tblCompanies_OriginalText where isnull(Export_Value, '')!=''

	-----------------------------------------------------Certification------------------------------------------------

	--		------ IDatom to keep have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	UPDATE a2 set Certification = ISNULL(a2.Certification,'') + char(10) +	a.Certification
	--Select [idatom to keep], [idatom to delete], a2.Certification, a.Certification, ISNULL(a2.Certification,'') + char(10) + a.Certification
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a.Certification, '')!=''
	and ISNULL(a2.Certification, '')!=''
	and a2.Certification <> a.Certification


	------- Idatom To keep does not have  Comment
	
	;WITH RankedData AS (
			SELECT 
			    d.*,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
				iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
			)

	update a2 set a2.Certification= a.Certification
	--Select [idatom to keep], [idatom to delete], a.Certification, a2.Certification
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a on a.IDATOM = b.[idatom to delete] 
	left join [TestCrifis2].[dbo].tblCompanies_OriginalText a2 on a2.IDATOM = b.[idatom to keep] 
	WHERE ISNULL(a2.Certification, '')=''
	and ISNULL(a.Certification, '')!=''
	/* ==================== COMMENTS SECTION (END) ==================== */

	/* ==================== PROFILE SECTION (START) ==================== */
	SET NOCOUNT ON;


	-------------------------------MAIN QUERY
	--WITH RankedData AS (
	--	SELECT 
	--	   d.*,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
	--	FROM ADIP.dbo.DuplicateCompanies d
	--	)
	--select distinct 
	--		registernumber,
	--		b.dummyname As [Register Description],
	--		[HasOrders_1],
	--		[HasOrders_2],
	
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_1, DateUpdated_2),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_1, DateUpdated_2) 
	--	) [Update Date to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_2, DateUpdated_1),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_2, DateUpdated_1) 
	--	) [Update Date to Delete],
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
	--	) [idatom to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
	--	) [idatom to Delete]

	--FROM RankedData d
	--join TestCrifis2.dbo.tblDic_BaseValues b on b.id= d.IdRegister;
	
	
	

	------------------------------------------------------------Legal Forms
	------- deleted have a LF and Kept do not have a LF

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	Insert Into TestCrifis2.dbo.tblCompanies2Types (IDATOM, IdType, DateStart, DateEnd, IsHistory, DateUpdated, DateReported, IdComment, UserId, ShowInReport, IntelligenceID, HandlingConditionsID, SourceID, isLocked, MonitoringDate)
	select distinct [idatom to keep], P2.IdType, P2.DateStart, P2.DateEnd, P2.IsHistory, P2.DateUpdated, P2.DateReported, P2.IdComment, P2.UserId, P2.ShowInReport, P2.IntelligenceID, P2.HandlingConditionsID, P2.SourceID, P2.isLocked, P2.MonitoringDate
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	
	left join TestCrifis2.dbo.tblCompanies2Types p2 on p2.IDATOM  = b.[idatom to Delete] 
	where [idatom to keep] not in (select distinct idatom from TestCrifis2.dbo.tblCompanies2Types p)
	and IdType is not  null
	--and [idatom to keep] =50041395 

	------- Move the missing legal form 

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--update p2 set IDATOM =  b.[idatom to keep]--, IsHistory = 1
	Insert Into TestCrifis2.dbo.tblCompanies2Types (IDATOM, IdType, DateStart, DateEnd, IsHistory, DateUpdated, DateReported, IdComment, UserId, ShowInReport, IntelligenceID, HandlingConditionsID, SourceID, isLocked, MonitoringDate)
	select p.IDATOM, P2.IdType, P2.DateStart, P2.DateEnd, P2.IsHistory, P2.DateUpdated, P2.DateReported, P2.IdComment, P2.UserId, P2.ShowInReport, P2.IntelligenceID, P2.HandlingConditionsID, P2.SourceID, P2.isLocked, P2.MonitoringDate
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies2Types p on p.IDATOM  = b.[idatom to keep] and isnull(p.IsHistory,0) =0
	left join TestCrifis2.dbo.tblCompanies2Types p2 on p2.IDATOM  = b.[idatom to Delete] and isnull(p2.IsHistory,0) =0
	where p.idtype <> p2.IdType
	--and [idatom to keep] =50041395 

	------- Tick IsHistory the legal form with oldest updated date

	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		),
	Idatoms as (
			SELECT DISTINCT 
				registernumber,
				[HasOrders_1],
				[HasOrders_2],
				iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
							iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
							iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
				) [idatom to keep],

				iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
							iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
							iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
				) [idatom to Delete]

			FROM RankedData d
	),
	RankedLFs AS ( 
				SELECT [idatom to keep], IDtype, DateUpdated,
				ROW_NUMBER() OVER (PARTITION BY IDatom ORDER BY dateupdated ) as rn,
				COUNT( IdType) OVER (PARTITION BY IDATOM) as Type_Count
				FROM Idatoms b
				left join TestCrifis2.dbo.tblCompanies2Types p on p.IDATOM  = b.[idatom to keep] and isnull(p.IsHistory,0) =0
				)

	update y set IsHistory = 1
	from TestCrifis2.dbo.tblCompanies2Types y
	JOIN RankedLFs l on l.[idatom to keep] = y.idatom and l.IdType = y.IdType and l.DateUpdated = y.DateUpdated
	where l.rn = 1  and l.Type_Count >=2
	

	-------- Fill the missing info when 2 legal forms are the same
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update p set DateStart =  isnull(p.DateStart, p2.DateStart),
			 DateEnd = isnull(p.DateEnd, p2.DateEnd),
			 IntelligenceID = isnull(p.IntelligenceID, p2.IntelligenceID),
			 sourceID = isnull(p.sourceID, p2.sourceID),
			 DateReported  = isnull(p.DateReported, p2.DateReported)
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies2Types p on p.IDATOM  = b.[idatom to keep] 
	left join TestCrifis2.dbo.tblCompanies2Types p2 on p2.IDATOM  = b.[idatom to Delete] 
	where p.idtype = p2.IdType
	and (p2.DateStart IS NOT NULL OR p2.DateEnd IS NOT NULL OR p2.IntelligenceID IS NOT NULL OR p2.sourceID  IS NOT NULL OR p2.DateReported IS NOT NULL )
	--and [idatom to delete] =71925468 


	

	
	-------- Kept Companies with 1 LF as history --> change to  current
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update p set IsHistory =0
	--select p.idatom,p.IsHistory
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies2Types p on p.IDATOM  = b.[idatom to keep] 
	left join TestCrifis2.dbo.tblCompanies2Types p2 on p2.IDATOM  = b.[idatom to Delete] 
	where p.IsHistory = 1
	and p.idatom in ( Select idatom from TestCrifis2.dbo.tblCompanies2Types 
				group by idatom
				having count(*) = 1)

	--- checking if there are compnaies with all legal forms ticked ishistoy

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)
	 select distinct p.idatom,p.IsHistory
	from(
	SELECT DISTINCT 
		registernumber,
		[HasOrders_1],
		[HasOrders_2],
		iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
					iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
					iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
		) [idatom to keep],

		iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
					iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
					iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
		) [idatom to Delete]

	FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies2Types p on p.IDATOM  = b.[idatom to keep] 
	left join TestCrifis2.dbo.tblCompanies2Types p2 on p2.IDATOM  = b.[idatom to Delete] 
	where  p.IsHistory = 1
	and p.idatom in ( Select idatom from TestCrifis2.dbo.tblCompanies2Types where IsHistory=1-- and idatom = 13049660
				group by idatom
				having count(*) >1)


	---------------------------------------------------------------------DATES
	------------Registered Date 
	--select 
	--[idatom to keep], p.DateIncorporation
 --   ,[idatom to Delete], p2.DateIncorporation
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update p set DateIncorporation = p2.DateIncorporation
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies p on p.IDATOM  = b.[idatom to keep]
	join TestCrifis2.dbo.tblCompanies p2 on p2.IDATOM  = b.[idatom to Delete]
	where 
	p.DateIncorporation is null and p2.DateIncorporation is not null;

	------------Started Date   --Added by Jihene
	
	--select 
	--[idatom to keep], p.DateIncorporation
 --   ,[idatom to Delete], p2.DateIncorporation
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update p set DateStart = p2.DateStart
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblatoms p on p.IDATOM  = b.[idatom to keep]
	join TestCrifis2.dbo.tblatoms p2 on p2.IDATOM  = b.[idatom to Delete]
	where 
	p.DateStart is null and p2.DateStart is not null
	--and b.[idatom to Delete] = 13674210 
	;

	------------Started Year   --Added by Jihene
	
	--select 
	--[idatom to keep], p.DateIncorporation
 --   ,[idatom to Delete], p2.DateIncorporation
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update p set YearStart = p2.YearStart
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblatoms p on p.IDATOM  = b.[idatom to keep]
	join TestCrifis2.dbo.tblatoms p2 on p2.IDATOM  = b.[idatom to Delete]
	where 
	p.YearStart is null and p2.YearStart is not null
	--and b.[idatom to Delete] = 13674210 
	;

	------------Registered Year   --Added by Jihene

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update p set YearIncorporation = p2.YearIncorporation
	from(
		Select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies p on p.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.tblCompanies p2 on p2.IDATOM  = b.[idatom to Delete]
	where 
	p.YearIncorporation is null and p2.YearIncorporation is not null;


		----------------------registers
	
		------Different Register Name
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
	)

	update pm set IdRegister = p.IdRegister, DateUpdated= p.DateUpdated
	
	--select [idatom to keep], pm.number, pm.IdRegister IdRegisterToKeep,  pm.DateUpdated, [idatom to Delete], p.IdRegister IdRegistertoDelete, p.DateUpdated
	from(
		Select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)
	b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where pm.Number = p.Number
	and pm.IdRegister <> p.IdRegister
	and isnull( pm.DateUpdated,'2000-01-01') <isnull( p.DateUpdated,'2000-01-01')
	--and [idatom to keep]=13664321
	;

	--select *  FROM ADIP.dbo.DuplicateCompanies where IDATOM_1=16411429


		------Type
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set IdType = p.IdType
	
	--select *
	from(
		Select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)
	b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where pm.Number = p.Number
	and pm.IdType is null and p.IdType is not null
	
	;


		--------------IssueDate

	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	IssueDate = p.IssueDate
	
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where pm.Number = p.Number
	and pm.IssueDate is null and p.IssueDate is not null


--	For Register Issue date , please keep the one which is older.


	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
	)

	update pm set 
	IssueDate = p.IssueDate
	
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where pm.Number = p.Number
	and pm.IssueDate is not null and p.IssueDate is not null
	and pm.IssueDate > p.IssueDate


	
--  For renewal date and Expiry date , please keep the one which is newer

		--------------ExpiryDate

	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	ExpiryDate = p.ExpiryDate
	--select p.Number, [idatom to keep],pm.ExpiryDate ,[idatom to Delete], p.ExpiryDate
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.ExpiryDate is null and p.ExpiryDate is not null
	--and pm.ExpiryDate > p.ExpiryDate 
	--and [idatom to keep] =15975503 



	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	ExpiryDate = p.ExpiryDate
	--select p.Number, [idatom to keep],pm.ExpiryDate ,[idatom to Delete], p.ExpiryDate
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.ExpiryDate is not null and p.ExpiryDate is not null
	and pm.ExpiryDate < p.ExpiryDate 
	

		--------------Renewal Date

	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	RenewalDate = p.RenewalDate
	
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where pm.Number = p.Number
	and pm.RenewalDate is null and p.RenewalDate is not null
	--and [idatom to keep] =117945222 


	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	RenewalDate = p.RenewalDate
	
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where pm.Number = p.Number
	and pm.RenewalDate is not null and p.RenewalDate is not null
	and pm.RenewalDate < p.RenewalDate 

		--------------IdStatus (Register Status)

	---- is Status from kept is empty and for deleted is not empty
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set
	IdStatus = p.IdStatus
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.IdStatus is null and p.IdStatus is not null


	---- If status for deleted is more recent than of kept company --> update the status of kept company

;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set
	IdStatus = p.IdStatus, 
	DateUpdated = p.DateUpdated
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and  p.IdStatus is not null
	and p.DateUpdated > pm.DateUpdated
	--and [idatom to Delete] =47639315

		--------------DateReported

	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	pm.DateReported = p.DateReported
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.DateReported is null and p.DateReported is not null

		--------------DateUpdated
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set
	pm.DateUpdated = p.DateUpdated
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.DateUpdated is null and p.DateUpdated is not null
	
		--------------IntelligenceID 
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	pm.IntelligenceID = p.IntelligenceID
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.IntelligenceID is null and p.IntelligenceID is not null

		--------------SourceID
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)
 
	update pm set 
	pm.SourceID = p.SourceID
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.SourceID is null and p.SourceID is not null

		--------------Name
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	pm.[Name] = p.[Name]
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.Name is null and p.Name is not null


	-----------NativeTradingName
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set 
	pm.NativeTradingName = p.NativeTradingName
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]
	join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = [idatom to Delete]

	where 
	pm.Number = p.Number
	and pm.NativeTradingName is null and p.NativeTradingName is not null



	----------------------------------------

	----------ADD missing IDS
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into TestCrifis2.dbo.tblCompanyIDs(
	IDATOM, IdOrganisation, IdRegister, IdStatus, IdType,Number, IssueDate, DateReported, DateUpdated, IntelligenceID, SourceID,
	UserID, ShowInReport, ExpiryDate, RenewalDate, name, NativeTradingName, IsHistory, IdComment)
	
	select 
	[idatom to keep], l.IdOrganisation, l.IdRegister, l.IdStatus, l.IdType, l.Number, l.IssueDate, l.DateReported, l.DateUpdated, l.IntelligenceID, 
	l.SourceID,	l.UserID, l.ShowInReport, l.ExpiryDate, l.RenewalDate, l.[name], l.NativeTradingName, l.IsHistory, l.IdComment
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs l on l.IDATOM = [idatom to Delete]
	where 
	--number not in (select l2.number from TestCrifis2.dbo.tblCompanyIDs l2 where l2.IDATOM = [idatom to keep])
	NOT EXISTS
	(select 1 from TestCrifis2.dbo.tblCompanyIDs l2 where l2.IDATOM = [idatom to keep] and l2.number = l.number)
	--and [idatom to Delete] = 47685413
	;

	---------- for kuwait only (The oldest chamber number to be set as Type = Main, and All other chamber numbers to be set as Type = Branch.)
			-----------NativeTradingName
	-- set everything to branch
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update pm set Idtype = 4047633
	--select *
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanyIDs pm on pm.IDATOM  = [idatom to keep]

	where 
	IdOrganisation = 4024812 
	--and  [idatom to keep] = 13104700 

	--select * from TestCrifis2.dbo.tblCompanyIDs where idatom =13104700

--- set main chamber
		;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		),
		Idatoms as (
				SELECT DISTINCT 
					registernumber,
					[HasOrders_1],
					[HasOrders_2],
					iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
								iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
								iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
					) [idatom to keep],

					iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
								iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
								iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
					) [idatom to Delete]

				FROM RankedData d
		),
		RankedLFs AS ( 
					SELECT [idatom to keep], Number, IdType,
					ROW_NUMBER() OVER (PARTITION BY IDatom ORDER BY  cast( Number as int) ) as rn,
					COUNT( IDATOM) OVER (PARTITION BY IDATOM) as Type_Count
					FROM Idatoms b
					left join TestCrifis2.dbo.tblCompanyIDs p on p.IDATOM  = b.[idatom to keep] and isnull(p.IsHistory,0) =0
					where  IdOrganisation = 4024812
					)

		update y set Idtype = 4047632 -- Main
		--select [idatom to keep], y.Number
		from TestCrifis2.dbo.tblCompanyIDs y
		JOIN RankedLFs l on l.[idatom to keep] = y.idatom and l.Number = y.Number
		where
		l.rn = 1  and l.Type_Count >=2
		and 
		IdOrganisation = 4024812 
		--and  [idatom to keep] = 13104700 
	;
	

	----------Merge employees
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into TestCrifis2.dbo.tblCompanies_Employees(
	IDATOM, [Year], TotalNumberFrom, TotalNumberTo, ReportedDate, UpdatedDate, IntelligenceID, 
	SourceID,UserID, ShowInReport)
	
	select 
	[idatom to keep],[Year], TotalNumberFrom, TotalNumberTo, ReportedDate, UpdatedDate, IntelligenceID, 
	SourceID,UserID, ShowInReport
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Employees l on l.IDATOM = [idatom to Delete]
	where 
	l.[Year] not in
	(select [Year] from TestCrifis2.dbo.tblCompanies_Employees l2 where l2.IDATOM = [idatom to keep]);


	--------------------------------------------

	--insert into TestCrifis2.dbo.tblCompanies_Employees(
	--IDATOM, [Year], TotalNumberFrom, TotalNumberTo, ReportedDate, UpdatedDate, IntelligenceID, 
	--SourceID,UserID, ShowInReport)
	
	--select 
	--[idatom to keep],[idatom to Delete]
	--from(
	--	SELECT 
	--		registernumber,
	--		IdRegister,
	--		CASE 
	--			WHEN [DateUpdated_1] >= [DateUpdated_2] THEN IDATOM_1
	--			ELSE IDATOM_2
	--		END AS [idatom to keep],
	--		CASE 
	--			WHEN [DateUpdated_1] < [DateUpdated_2] THEN IDATOM_1
	--			ELSE IDATOM_2
	--		END AS [idatom to delete]
	--	FROM ADIP.dbo.DuplicateCompanies
	--)b
	--join TestCrifis2.dbo.tblCompanies_Employees l on l.IDATOM = [idatom to keep]
	--join TestCrifis2.dbo.tblCompanies_Employees l2 on l2.IDATOM = [idatom to Delete]
	--where 
	--l.[Year] = l2.[Year] 
	--and l.TotalNumberFrom <> l2.TotalNumberFrom;




	----------------------------------------------------------------------------------------------

	----------Merge Operatinal Status

	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into TestCrifis2.dbo.tblCompanies2Status(IDATOM, IdStatus, DateReported, DateUpdated, IntelligenceID, 
	SourceID,UserID, ShowInReport)
	
	select 
	[idatom to keep],IdStatus, DateReported, DateUpdated, IntelligenceID, 
	SourceID,UserID, ShowInReport
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies2Status l on l.IDATOM = [idatom to Delete]
	where 
	[idatom to keep] not in
	(select l2.IDATOM from TestCrifis2.dbo.tblCompanies2Status l2 where l2.IDATOM = [idatom to keep]);


	--------------------------------------------

	--insert into TestCrifis2.dbo.tblCompanies_Employees(
	--IDATOM, [Year], TotalNumberFrom, TotalNumberTo, ReportedDate, UpdatedDate, IntelligenceID, 
	--SourceID,UserID, ShowInReport)
	
	--select 
	--[idatom to keep],[idatom to Delete]

	--from(
	--	SELECT 
	--		registernumber,
	--		IdRegister,
	--		CASE 
	--			WHEN [DateUpdated_1] >= [DateUpdated_2] THEN IDATOM_1
	--			ELSE IDATOM_2
	--		END AS [idatom to keep],
	--		CASE 
	--			WHEN [DateUpdated_1] < [DateUpdated_2] THEN IDATOM_1
	--			ELSE IDATOM_2
	--		END AS [idatom to delete]
	--	FROM ADIP.dbo.DuplicateCompanies
	--)b
	--join TestCrifis2.dbo.tblCompanies2Status l on l.IDATOM = [idatom to keep]
	--join TestCrifis2.dbo.tblCompanies2Status l2 on l2.IDATOM = [idatom to Delete]
	--where 
	--l.IdStatus <> l2.IdStatus ;

	
	----------------------------------------------------------------------------------------------

	----------Merge Trading Names
	
	;WITH RankedData AS (
		SELECT 
		    d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into TestCrifis2.dbo.tblCompanies_Names(IDATOM, NameType, ReportedDate, DateUpdated, IntelligenceID, 
	SourceID,updatedby, isHistory, [Name])
	
	select 
	[idatom to keep],NameType, ReportedDate, DateUpdated, IntelligenceID, 
	SourceID,updatedby, isHistory, [Name]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	where 
	[Name] not in
	(select l2.[Name] from TestCrifis2.dbo.tblCompanies_Names l2 where l2.IDATOM = [idatom to keep]);
	/* ==================== PROFILE SECTION (END) ==================== */

	/* ==================== D&S SECTION (START) ==================== */
	SET NOCOUNT ON;


	-------------------------------MAIN QUERY
	
	--WITH RankedData AS (
	--		SELECT 
		--	    d.*,
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
		--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
	--		FROM ADIP.dbo.DuplicateCompanies d
	--	)
	--select distinct 
	--		registernumber,
	--		b.dummyname As [Register Description],
	--		[HasOrders_1],
	--		[HasOrders_2],
	
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_1, DateUpdated_2),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_1, DateUpdated_2) 
	--	) [Update Date to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_2, DateUpdated_1),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_2, DateUpdated_1) 
	--	) [Update Date to Delete],
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
	--	) [idatom to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
	--	) [idatom to Delete]

	--FROM RankedData d
	--join TestCrifis2.dbo.tblDic_BaseValues b on b.id= d.IdRegister
	
	----------------------------------------------------------------------
	------------------DIRECTORSHIPs

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set IDATOM = [idatom to keep]
	--select distinct l2.*
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Administrators l on l.IDATOM = [idatom to keep]
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Administrators l2 on l2.IDATOM = [idatom to Delete]
	--join TestCrifis2.dbo.tblatoms ap (NOLOCK) on ap.idatom = [idatom to Delete] and ap.IdRegisteredCountry = 90 and  isnull(ap.IsDeleted,0) = 0
	where 
	l2.IDRELATED not in(select l3.idrelated from TestCrifis2.dbo.tblCompanies2Administrators l3 where l3.IDATOM = [idatom to keep]
	 AND l3.IdPosition = l.IdPosition)
	--and registernumber = '272787'
	--and [idatom to Delete] = 13042228 
	;


	----------------------------------------------------------------------
	------------------SHAREHOLDERS

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set IDATOM = [idatom to keep]
	--select distinct [idatom to Delete],[idatom to keep], l2.*
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Shareholders l2 on l2.IDATOM = [idatom to Delete]
	where 
	l2.IDRELATED not in(select l3.idrelated from TestCrifis2.dbo.tblCompanies2Shareholders l3 where l3.IDATOM = [idatom to keep])
	--and [idatom to keep] = 105538060
	;

	-------------------------------------------------------------
	----------Capital

	-----add as history if it's previous          (Added by Jihene)

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l set idatom = [idatom to keep], l.IsHistory = 1
	--select [idatom to Delete], [idatom to keep], l.Authorised, l2.Authorised, l.IsHistory 
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Capital l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Capital l2 on l2.IDATOM = [idatom to keep]
	where ISNULL(l.DateUpdated, '1900-01-01') <= l2.DateUpdated
	--and [idatom to Delete] = 226131074    
	;

	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0) [HasOrders_1],
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0) [HasOrders_2]
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select *
	update l set idatom = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Capital l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Capital l2 on l2.IDATOM = [idatom to keep]
	--where 
	--[idatom to keep] not in
	--(select l2.IDATOM from TestCrifis2.dbo.tblCompanies_Capital l2 where l2.IDATOM = [idatom to keep])
	--and [idatom to Delete] = 226131074   
	;

	
	---------------- Relations

	------- Using IDATOM
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)
	
	--select *
	update l set idatom = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Related l on l.IDATOM = [idatom to Delete]
	--where 
	--[idatom to keep] not in
	--(select l2.IDATOM from TestCrifis2.dbo.tblCompanies_Related l2 where l2.IDATOM = [idatom to keep]);
	;

	------- Using IDRELATED
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select *
	update l set IDRELATED = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d 
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Related l on l.IDRELATED = b.[idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Related l2 on l2.IDRELATED = b.[idatom to keep];
	;


	-----------------	Holdings      (Added by Jihene)

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select [idatom to keep], [idatom to Delete], l.IDATOM as [holdong to Delete]
	update l set IDRELATED = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Shareholders l on l.IDRELATED = b.[idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Shareholders l2 on l2.IDRELATED = b.[idatom to keep]
	
	where  l.IDATOM not in
	(select l2.IDATOM from TestCrifis2.dbo.tblCompanies2Shareholders l2 where l2.IDATOM = [idatom to keep]);
	/* ==================== D&S SECTION (END) ==================== */

	/* ==================== ADDRESSES SECTION (START) ==================== */
	SET NOCOUNT ON;

	--select * from DuplicateCompanies

	----STEP 1:
	 --drop table DuplicateCompanies

	----STEP 2:
	--create Table DuplicateCompanies (
	--[IDATOM_1] int null,
	--[IDATOM_2] int null,
	--[DateUpdated_1] date null,
	--[DateUpdated_2] date null, 
	--[registernumber] nvarchar(250) null,
	--[IdRegister] int null	
	--)

	----STEP 3: Insert data
	----- could be like this 

	----Insert Into ADIP.dbo.DuplicateCompanies ([IDATOM_1], [IDATOM_2])
	----Select idatom_1, IDATOM_2
	----From ADIP.dbo.DuplicateCompanies


	----- or could be like this 
	--truncate table DuplicateCompanies


	--INSERT INTO [dbo].[DuplicateCompanies]  ([IDATOM_1], [IDATOM_2], [registernumber],[DateUpdated_1] ,[DateUpdated_2]  )
	----	 -----Same Register Number 
	-- SELECT distinct
	--	a.IDATOM AS IDATOM_1,
	--	b.IDATOM AS IDATOM_2,
	--	a.[Company ID]
	--	--d.id as IdRegister
	--	--IdRegister
	--	,cast (a.[Date Updated] as date )  DateUpdated_1,
	--	cast (b.[Date Updated]as date )  DateUpdated_2
	--	--,a.[Register Name], a.Town, a.[Company Name English], a.[Company Name Local]
	--FROM [ADIP].[dbo].Duplicates_kuwait a
	--JOIN [ADIP].[dbo].Duplicates_kuwait b 
	-- ON a.IDATOM < b.IDATOM
	-- AND a.[Company ID] = b.[Company ID]
	-- --left join TestCrifis2.dbo.tblCompanyIDs d on d.Number = a.[Company ID]
	----left join TestCrifis2.dbo.tblDic_BaseValues d on d.DummyName = a.[Register Name]


	----- or could be like this 

	--INSERT INTO [dbo].[DuplicateCompanies]  ([IDATOM_1] ,[IDATOM_2]  ,[DateUpdated_1] ,[DateUpdated_2]  ,[registernumber])
	--   VALUES
--           (13110442, 235850846, '2017-05-18'  , '2024-06-11' , 100056)
	--INSERT INTO ADIP.dbo.DuplicateCompanies   ([IDATOM_1] ,[IDATOM_2], idregister, registernumber)


	----STEP 4: Get the latest updated dates

	--UPDATE e set [DateUpdated_1]= DateUpdated from TestCrifis2.dbo.tblatoms t
	--										  join ADIP.dbo.DuplicateCompanies e on IDATOM_1 =t.idatom
	--UPDATE e set [DateUpdated_2]= DateUpdated from TestCrifis2.dbo.tblatoms t
	--										  join ADIP.dbo.DuplicateCompanies e on IDATOM_2 =t.idatom

	
	
	------STEP 5:	Add the idregister when not available
	
	--UPDATE e set  idRegister = t.idRegister 
	----select e.*, t.idRegister
	--from TestCrifis2.dbo.tblCompanyIDs t
	--join ADIP.dbo.DuplicateCompanies e on IDATOM_1 = t.idatom and registernumber = t.number
	--where e.IdRegister is null
	
	
	--select * from ADIP.dbo.DuplicateCompanies
	--select distinct * FROM [ADIP].[dbo].Duplicates_kuwait

	-------delete duplicates

	--;With CTE AS (
	--SELECt* ,
	--row_number() OVER(PARTITION BY [IDATOM_1] ,[IDATOM_2] ,[registernumber] ORDER BY [IDATOM_1]) AS [rn]
	--from ADIP.dbo.DuplicateCompanies
	--)
	--delete from CTE where RN >1

	-----------------------------------MAIN QUERY
	
	--;WITH RankedData AS (
	--	SELECT 
	--	   d.*,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
	--		FROM ADIP.dbo.DuplicateCompanies d
	--	)
	--select distinct 
	--		registernumber,
	--		b.dummyname As [Register Description],
	--		[HasOrders_1],
	--		[HasOrders_2],
	
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_1, DateUpdated_2),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_1, DateUpdated_2) 
	--	) [Update Date to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_2, DateUpdated_1),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_2, DateUpdated_1) 
	--	) [Update Date to Delete],
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
	--	) [idatom to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
	--	) [idatom to Delete]

	--FROM RankedData d
	--join TestCrifis2.dbo.tblDic_BaseValues b on b.id= d.IdRegister
	----;
	---------------------------------------------------------------START MERGing PROCESS

	------------------------------------------CONTACTs----------------------------------------------- (added by Jihene)

	-------------Emails
	--select 
	--[idatom to keep],[idatom to Delete], e.email, e2.email as EmailToMerge
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update e2 set IdContact =  e.IdContact
	--select [idatom to Delete],  e.email
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b

	left join TestCrifis2.dbo.tblatoms2addresses a on a.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.[tblContacts_Emails] e on e.IdContact = a.IdContact

	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Emails] e2 on e2.IdContact = a2.IdContact
	where e2.email not in ( select email from TestCrifis2.dbo.[tblContacts_Emails] e
							join TestCrifis2.dbo.tblatoms2addresses a on e.IdContact = a.IdContact
							 where a.IDATOM  = b.[idatom to keep])
	and e2.email is not null
	and e.email is not null
	--and [idatom to keep] =13683847
	;

	--- Add missing

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	INSERT INTO TestCrifis2.dbo.tblcontacts(atom2addressID)
	SELECT DISTINCT [idatom to keep]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Emails] e2 on e2.IdContact = a2.IdContact
	--left join TestCrifis2.dbo.tblcontacts c2 on c2.ID = a2.IdContact 
		 
	where [idatom to keep] not in (select atom2addressID from TestCrifis2.dbo.tblcontacts c)
	and e2.email is not null
	--and [idatom to keep] = 13683847
;

	update TestCrifis2.dbo.tblatoms2addresses set idcontact = a.id
	from TestCrifis2.dbo.tblcontacts a where Atom2AddressID = idatom
	and IdContact is null


	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into  TestCrifis2.dbo.[tblContacts_Emails] (idcontact, email,  DateReported, DateUpdated)
	select distinct c.id , e2.email,  e2.DateReported, e2.DateUpdated
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d	
	)b

	left join TestCrifis2.dbo.tblatoms2addresses a on a.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.[tblContacts_Emails] e on e.IdContact = a.IdContact
	left join TestCrifis2.dbo.tblcontacts c on c.ID = a.IdContact 
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Emails] e2 on e2.IdContact = a2.IdContact
	left join TestCrifis2.dbo.tblcontacts c2 on c2.ID = a2.IdContact 
	where e2.email not in ( select email from TestCrifis2.dbo.[tblContacts_Emails] e
						join TestCrifis2.dbo.tblatoms2addresses a on e.IdContact = a.IdContact
						where a.IDATOM  = b.[idatom to keep])
	and e2.email is not null
	and e.email is null
	and c.id  is not null
	and e.IdContact is not null
	----and [idatom to keep]=235856662
	;


	-------------Phones/Fax
	--select 
	--[idatom to keep]
 --   ,[idatom to Delete], e.Number, e2.Number as numberToMerge

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update e2 set IdContact =  e.IdContact
	from( 
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d	
	)b

	left join TestCrifis2.dbo.tblatoms2addresses a on a.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.[tblContacts_Phones] e on e.IdContact = a.IdContact
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Phones] e2 on e2.IdContact = a2.IdContact
	where e2.Number not in ( select Number from TestCrifis2.dbo.[tblContacts_Phones] e
							join TestCrifis2.dbo.tblatoms2addresses a on e.IdContact = a.IdContact
							where a.IDATOM  = b.[idatom to keep])
	and e2.Number is not null
	and e.Number is not null;
	;
	
	--- Add missing

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	INSERT INTO TestCrifis2.dbo.tblcontacts(atom2addressID)
	SELECT DISTINCT [idatom to keep]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d	
	)b
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_phones] e2 on e2.IdContact = a2.IdContact
	left join TestCrifis2.dbo.tblcontacts c2 on c2.ID = a2.IdContact 
		 
	where [idatom to keep] not in (select atom2addressID from TestCrifis2.dbo.tblcontacts c
									where c.atom2addressID  = [idatom to keep] )
	and e2.Number is not null
	;

	update TestCrifis2.dbo.tblatoms2addresses set idcontact = a.id
	from TestCrifis2.dbo.tblcontacts a where Atom2AddressID = idatom
	and IdContact is null


	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into  TestCrifis2.dbo.[tblContacts_Phones] (idcontact, Number, IdPhoneType,  DateReported, DateUpdated)
	select distinct c.id, e2.number, e2.IdPhoneType,  e2.DateReported, e2.DateUpdated
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b

	left join TestCrifis2.dbo.tblatoms2addresses a on a.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.[tblContacts_phones] e on e.IdContact = a.IdContact
	left join TestCrifis2.dbo.tblcontacts c on c.ID = a.IdContact 
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_phones] e2 on e2.IdContact = a2.IdContact
	left join TestCrifis2.dbo.tblcontacts c2 on c2.ID = a2.IdContact 
	where e2.number not in ( select number from TestCrifis2.dbo.[tblContacts_Phones] e
						join TestCrifis2.dbo.tblatoms2addresses a on e.IdContact = a.IdContact
						where a.IDATOM  = b.[idatom to keep])
	and e2.number is not null
	and e.number is null
	and c.id is not null
	--and [idatom to keep]=117660032
	;


	-------------WEBSITES
	--select 
	--[idatom to keep] ,[idatom to Delete], e.Web, e2.Web as webToMerge
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update e2 set IdContact =  e.IdContact
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b

	left join TestCrifis2.dbo.tblatoms2addresses a on a.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.[tblContacts_Webs] e on e.IdContact = a.IdContact
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Webs] e2 on e2.IdContact = a2.IdContact
	where e2.Web not in ( select web from TestCrifis2.dbo.[tblContacts_Webs] e
						join TestCrifis2.dbo.tblatoms2addresses a on e.IdContact = a.IdContact
						where a.IDATOM  = b.[idatom to keep])
	and e2.Web is not null
	and e.IdContact is not null
	and e.Web  is not null
	and e2.web != 'www.dutyfree.egyptair.com'
	;

	--- Add missing

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	INSERT INTO TestCrifis2.dbo.tblcontacts(atom2addressID)
	SELECT DISTINCT [idatom to keep]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Webs] e2 on e2.IdContact = a2.IdContact
	left join TestCrifis2.dbo.tblcontacts c2 on c2.ID = a2.IdContact 
		 
	where [idatom to keep] not in (select atom2addressID from TestCrifis2.dbo.tblcontacts c
									where c.atom2addressID  = [idatom to keep] )
	and e2.Web is not null
	;

	update TestCrifis2.dbo.tblatoms2addresses set idcontact = a.id
	from TestCrifis2.dbo.tblcontacts a where Atom2AddressID = idatom
	and IdContact is null



	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into  TestCrifis2.dbo.[tblContacts_Webs] (idcontact, web,  DateReported, DateUpdated)
	select distinct c.id, e2.web,  e2.DateReported, e2.DateUpdated
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b

	left join TestCrifis2.dbo.tblatoms2addresses a on a.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.[tblContacts_Webs] e on e.IdContact = a.IdContact
	left join TestCrifis2.dbo.tblcontacts c on c.ID = a.IdContact 
	left join TestCrifis2.dbo.tblatoms2addresses a2 on a2.IDATOM  = b.[idatom to Delete]
	left join TestCrifis2.dbo.[tblContacts_Webs] e2 on e2.IdContact = a2.IdContact
	left join TestCrifis2.dbo.tblcontacts c2 on c2.ID = a2.IdContact 
	where e2.Web not in ( select web from TestCrifis2.dbo.[tblContacts_Webs] e
						join TestCrifis2.dbo.tblatoms2addresses a on e.IdContact = a.IdContact
						where a.IDATOM  = b.[idatom to keep])
	and e2.Web is not null
	and e.web is null
	and c.id is not null
	and e2.Web != 'www.aiho-group.com'
	;

	------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------ADDRESS--------------------------------------------------------------------------
	------------ AREA
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)
		
	update adr set 
		IdArea = adrs.IdArea
--select ad.*
	from(
			select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	left join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	left join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	left join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.IdArea is null and adrs.IdArea is not null
	--and [idatom to Delete] = 74501795 
	;
	 ------------STREET

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		IdStreet = adrs.IdStreet
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.IdStreet is null and adrs.IdStreet is not null
	;
	------------ BUILDING

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		adr.IdBuilding = adrs.IdBuilding
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.IdBuilding is null and adrs.IdBuilding is not null
	;
	------------- FLOOR

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		IdFloor = adrs.IdFloor, Floor = adrs.Floor
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	--and
	--adr.IdFloor is null and adrs.IdFloor is not null
	and isnull(adr.floor,'')='' and  isnull(adrs.floor,'')!='' 
;
	--------------- OFFICE UNIT

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		IdOfficeUnit = adrs.IdOfficeUnit, OfficeUnit = adrs.OfficeUnit
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	--and
	--adr.IdOfficeUnit is null and adrs.IdOfficeUnit is not null
	and isnull(adr.OfficeUnit,'')='' and  isnull(adrs.OfficeUnit,'')!='' 
	;
	---------------- POSTAL CODE

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		PostalCode = adrs.PostalCode
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.PostalCode is null and adrs.PostalCode is not null
	;

	---------------- POSTAL CODE Postal

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		PostalCode_Postal = adrs.PostalCode_Postal
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.PostalCode_Postal is null and adrs.PostalCode_Postal is not null
	;

	---------------- PLOT NO

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		PlotNo = adrs.PlotNo
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.PlotNo is null and adrs.PlotNo is not null
	;
	---------------- STREET NO

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set
		StreetNumber = adrs.StreetNumber
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	isnull(adr.StreetNumber,'')=''  and isnull(adrs.StreetNumber,'')!='' 
	;
	---------------- BLOCK NO

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set
		BlockNo = adrs.BlockNo
		
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.BlockNo is null and adrs.BlockNo is not null
	;
	-------------- PO BOX

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set
		POBox = adrs.POBox
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.POBox is null and adrs.POBox is not null
	;
	------------- BUILDING NO

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set
		BuildingNo = adrs.BuildingNo
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.BuildingNo is null and adrs.BuildingNo is not null
	;
	-------------- OFFICE UNIT

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
		OfficeUnit = adrs.OfficeUnit
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	adr.OfficeUnit is null and adrs.OfficeUnit is not null
	;
	-------------- USER

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set
		UserID = adrs.UserID
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	 adr.UserID is null and adrs.UserID is not null  and adrs.UserID != 486
	 ;
	---------------- USER

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set
		UserID = adrs.UserID
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	 adr.UserID is not null and adr.UserID = 486 and adrs.UserID is not null and adrs.UserID != 486
	 ;
	------------- DATE REPORTED

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad set
		DateReported = ad2.DateReported
		
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	ad.DateReported is null and ad2.DateReported is not null
	;
	-------------- Source ID

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad set
		SourceID = ad2.SourceID
		
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	ad.SourceID is null and ad2.SourceID is not null
	;
	-------------- GRADING ID

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad set 
		GradingID = ad2.GradingID
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and
	ad.GradingID is null and ad2.GradingID is not null
	;
	-------------- DATE UPDATED

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad set 
		DateUpdated = ad2.DateUpdated

	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown = adrs.IdTown
	and  ad.DateUpdated < ad2.DateUpdated
	;
	---------------------------------------------------------------------------------------------------

	------------------- town
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update adr set 
	idtown = adrs.idtown
--select ad.*
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is null and adrs.IdTown is not null
	;

	


	-------if different town, add the address of the record to be deleted as former
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad2 set IDATOM = b.[idatom to keep], IsMain = 0,IdType = 2949878
	--select  [idatom to keep],[idatom to Delete]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adrs.IdArea is not null
	and adr.IdArea <> adrs.IdArea
	--and [idatom to Delete] = 46674665
	;

	--------------------------------------merge branches ----> NO RECORDS

	--select  [idatom to keep],ad.IsMain, ad.IdType, adr.ID,  adr.IdTown   ,[idatom to Delete], ad2.IsMain, ad2.IdType, adrs.ID as [ID address to update to former],  adrs.IdTown 
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad2 set IDATOM =  b.[idatom to keep], IsMain = 0 ,IdType = 2949878
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 0 and ad.IdType = 2949871
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 0 and ad2.IdType = 2949871
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown <> adrs.IdTown 
	--and b.[idatom to keep]= 50252011
	;
	--select * from TestCrifis2.dbo.tblDic_BaseValues where id = 2949871

-----------move and keep address type as it is, if it's not available in the company to be kept (anything except is Main) . (added by jihene)
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad2 set IDATOM =  b.[idatom to keep]
	--select adr.IdTown,adrs.IdTown
		from(
			select distinct 
				registernumber,
				[HasOrders_1],
				[HasOrders_2],
				iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
							iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
							iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
				) [idatom to keep],

				iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
							iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
							iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
				) [idatom to Delete]

			FROM RankedData d
		)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 0 
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 0 
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress

	where 
	adr.IdTown is not null and adrs.IdTown is not null
	and adr.IdTown <> adrs.IdTown
	--and [idatom to Delete] = 120017103
	;

	-------- Move main address of deleted company to kept company and change type to former address   (added by jihene)
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad2 set IDATOM =  b.[idatom to keep], IsMain = 0, ad2.IdType = 2949878 
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 1
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress
	where 
	adr.IdTown is not null and adrs.IdTown is not null 
	and adr.IdTown <> adrs.IdTown
	--and [idatom to keep] =13154796
	;

	--------------- Move everything  that is left in deleted to kept company

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update ad2 set IDATOM =  b.[idatom to keep]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
		)b
	join TestCrifis2.dbo.tblAtoms2Addresses ad on ad.IDATOM  = b.[idatom to keep] and ad.IsMain = 0
	join TestCrifis2.dbo.tblAddresses adr on adr.ID  = ad.IdAddress

	join TestCrifis2.dbo.tblAtoms2Addresses ad2 on ad2.IDATOM  = b.[idatom to Delete] and ad2.IsMain = 0
	join TestCrifis2.dbo.tblAddresses adrs on adrs.ID  = ad2.IdAddress
	where 
	adr.IdTown is not null and adrs.IdTown is not null 
	--and [idatom to keep] =13154796;


	--------------------------------------merge PREMISES ----> NO RECORDS
	
	--select 
	--[idatom to keep]
 --   ,[idatom to Delete]
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
			FROM ADIP.dbo.DuplicateCompanies d
		)

	update p2 set IDATOM =  b.[idatom to keep]
	from(
		select distinct 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblPremises p on p.IDATOM  = b.[idatom to keep]
	left join TestCrifis2.dbo.tblPremises p2 on p2.IDATOM  = b.[idatom to Delete]
	--where [idatom to keep]=70317468  
	;
	/* ==================== ADDRESSES SECTION (END) ==================== */

	/* ==================== OTHER SECTION (START) ==================== */
	SET NOCOUNT ON;


	-------------------------------MAIN QUERY
	--WITH RankedData AS (
	--	SELECT 
	--	   d.*,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
	--		iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
	--	FROM ADIP.dbo.DuplicateCompanies d
	--	)
	--select distinct 
	--		registernumber,
	--		b.dummyname As [Register Description],
	--		[HasOrders_1],
	--		[HasOrders_2],
	
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_1, DateUpdated_2),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_1, DateUpdated_2) 
	--	) [Update Date to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, DateUpdated_2, DateUpdated_1),
	--				iif(DateUpdated_1 >= DateUpdated_2, DateUpdated_2, DateUpdated_1) 
	--	) [Update Date to Delete],
	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
	--	) [idatom to keep],

	--	iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
	--				iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
	--				iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
	--	) [idatom to Delete]

	--FROM RankedData d
	--join TestCrifis2.dbo.tblDic_BaseValues b on b.id= d.IdRegister;
	

	----------Company Updated Date

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select [idatom to keep], l.DateUpdate,  [idatom to Delete], l2.DateUpdate
	update l set DateUpdate = l2.DateUpdate
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblcompanies l on l.IDATOM = [idatom to keep]
	LEFT JOIN TestCrifis2.dbo.tblcompanies l2 on l2.IDATOM = [idatom to Delete]
	where  l2.DateUpdate >  l.DateUpdate
	--and [idatom to keep] = 47151552

	----------Company Reported Date 

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select [idatom to keep], l.DateUpdate,  [idatom to Delete], l2.DateUpdate
	update l set DateReported = l2.DateReported
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblAtoms l on l.IDATOM = [idatom to keep]
	LEFT JOIN TestCrifis2.dbo.tblAtoms l2 on l2.IDATOM = [idatom to Delete]
	where   l.DateReported is null 
	--and [idatom to keep] = 13605278


	----------IsListed

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select [idatom to keep], l.DateUpdate,  [idatom to Delete], l2.DateUpdate
	update l set IsListed = 1
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblcompanies l on l.IDATOM = [idatom to keep]
	LEFT JOIN TestCrifis2.dbo.tblcompanies l2 on l2.IDATOM = [idatom to Delete]
	where   isnull(l2.IsListed,0) = 1


	----------Historical Changes

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select [idatom to keep], l.DateUpdate,  [idatom to Delete], l2.DateUpdate
	update l2 set IDATOM = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.CS_CompanyHistory l on l.IDATOM = [idatom to keep]
	LEFT JOIN TestCrifis2.dbo.CS_CompanyHistory l2 on l2.IDATOM = [idatom to Delete]
	--where [idatom to keep] =13734507

	--select * from TestCrifis2.dbo.CS_CompanyHistory

	----------Financials

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select *
	update l set idatom = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies_Financials l on l.IDATOM = [idatom to Delete]
	--where
	------[idatom to keep] not in
	------(select l2.IDATOM from TestCrifis2.dbo.tblCompanies_Financials l2 where l2.IDATOM = [idatom to keep])
	------[idatom to keep] = 13683847
	------and 
	--[idatom to keep] =13683847

	----------Credit Rating

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select distinct [idatom to keep] , l2.MaximumCredit , [idatom to Delete], l.MaximumCredit
	update l set idatom = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b

	LEFT JOIN TestCrifis2.dbo.tblCompanies_CreditRating l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies_CreditRating l2 on l2.IDATOM = [idatom to keep]
	--where 
	--[idatom to keep] not in
	--(select l2.IDATOM from TestCrifis2.dbo.tblCompanies_CreditRating l2 where l2.IDATOM = [idatom to keep])
	--and [idatom to keep] =70317468 
	;

	----------------- Credig History
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l set idatom = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b

	LEFT JOIN TestCrifis2.dbo.tblCompanies_CreditHistory l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies_CreditHistory l2 on l2.IDATOM = [idatom to keep]
	--where [idatom to Delete] =13327722
	;

	--------------- Credit Rating - cs_orders

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l set idatom = [idatom to keep]
	--select distinct [idatom to delete], l.ID
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.cs_orders l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.cs_orders l2 on l2.IDATOM = [idatom to keep]
	--where 
	--[idatom to keep] not in
	--(select l2.IDATOM from TestCrifis2.dbo.cs_orders l2 where l2.IDATOM = [idatom to keep]);
	--[idatom to keep]= 74511180  


	--select * from TestCrifis2.dbo.cs_orders where id =1267455
	----------Activities

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l set idatom = [idatom to keep]
	--select *
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Activities l on l.IDATOM = [idatom to Delete]
    LEFT JOIN TestCrifis2.dbo.tblCompanies2Activities l2 on l2.IDATOM = [idatom to keep]
	--where 
	--[idatom to keep] not in
	----(select l2.IDATOM from TestCrifis2.dbo.tblCompanies2Activities l2 where l2.IDATOM = [idatom to keep]);
	--l.[IdActivity] <>  l2.[IdActivity] :



	

	----------Commerce

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	--select l.*
	update l set idatom = [idatom to keep]
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies2Commerce l on l.IDATOM = [idatom to Delete]
    LEFT JOIN TestCrifis2.dbo.tblCompanies2Commerce l2 on l2.IDATOM = [idatom to keep]
	and l.IdCommerceType is not null
	--where [idatom to Delete] =14665533
	;

	-------------------------Company Names of deleted company to Trading names of kept
	-- Reg English Name/ English Name to Trading Name

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into TestCrifis2.dbo.tblCompanies_Names(IDATOM, NameType, isHistory, [Name], SourceId, IntelligenceId, DateUpdated, ReportedDate)
	
	select [idatom to keep],1,1 isHistory, isnull(registeredname,name), isnull(CompanyRegisteredNameSourceId, CompaniesNameSourceId), 
	isnull(CompanyRegisteredNameIntelligenceId, CompaniesNameIntelligenceId), DateUpdate, t.DateReported
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblatoms t on t.IDATOM = [idatom to Delete]
	where 
	--isnull(registeredname,name) not in
	--(select l2.[Name] from TestCrifis2.dbo.tblCompanies_Names l2 where l2.IDATOM = [idatom to keep] and NameType = 1)
	--and
	 isnull(registeredname,name) <> (select isnull(registeredname,name) from TestCrifis2.dbo.tblCompanies l where l.IDATOM = [idatom to keep])
	--and [idatom to delete]=226131074  


	---Reg Local Name/ Local Name to Trading Local Name  -- Added by Jihene

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	insert into TestCrifis2.dbo.tblCompanies_Names(IDATOM, NameType, isHistory, [Name], SourceId, IntelligenceId, DateUpdated, ReportedDate)
	
	select [idatom to keep],2,1 isHistory, isnull(RegisteredNameLocal,NameLocal), isnull(CompanyRegisteredLocalNameSourceId, CompanyLocalNameSourceId),
	isnull(CompanyRegisteredLocalNameIntelligenceId, CompanyLocalNameIntelligenceId), DateUpdate, t.DateReported
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblatoms t on t.IDATOM = [idatom to Delete]
	where 
	isnull(l.RegisteredNameLocal, l.NameLocal) not in 
		(select RegisteredNameLocal from TestCrifis2.dbo.tblCompanies l3 where l3.IDATOM = [idatom to keep])
	--or
	-- isnull(l.RegisteredNameLocal, l.NameLocal) not in
	--	(select l2.name from TestCrifis2.dbo.tblCompanies_Names l2 where l2.IDATOM = [idatom to keep] and NameType = 2)
	--and [idatom to keep] = 47383055 
	



	--------------Add Name when missing------------------------------------------------------------ added by jihene
	--Registered Engish Name

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET
	registeredname = l.registeredname, 
	CompanyRegisteredNameSourceId = l.CompanyRegisteredNameSourceId,
	CompanyRegisteredNameIntelligenceId =  l.CompanyRegisteredNameIntelligenceId
	--select l2.*
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where isnull(l2.registeredname,'')='' 
	--and [idatom to delete]=226131074  


	-- Registered Local Name

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET
	RegisteredNameLocal = l.RegisteredNameLocal, 
	CompanyRegisteredLocalNameSourceId = l.CompanyRegisteredLocalNameSourceId,
	CompanyRegisteredLocalNameIntelligenceId =  l.CompanyRegisteredLocalNameIntelligenceId
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where isnull(l2.RegisteredNameLocal,'')='' 
	--and [idatom to delete]=14665925 


	-- Engish Name

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET
	name = l.name, 
	CompaniesNameSourceId = l.CompaniesNameSourceId,
	CompaniesNameIntelligenceId =  l.CompaniesNameIntelligenceId
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where isnull(l2.Name,'')='' 
	--and [idatom to delete]=14665925 


	-- Local Name

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET
	NameLocal = l.NameLocal,
	CompanyLocalNameSourceId = l.CompanyLocalNameSourceId,
	CompanyLocalNameIntelligenceId =  l.CompanyLocalNameIntelligenceId
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where isnull(l2.NameLocal,'')='' 
	--and [idatom to delete]=14665925


	--------------Add Missing Source grading in the names when they are the same
	-- Local Name
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET 
	CompanyLocalNameSourceId = l.CompanyLocalNameSourceId,
	CompanyLocalNameIntelligenceId =  l.CompanyLocalNameIntelligenceId

	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where l2.NameLocal = l.NameLocal
	and l.CompanyLocalNameSourceId is not null and  l2.CompanyLocalNameSourceId is null
	and l.CompanyLocalNameIntelligenceId is not null and l2.CompanyLocalNameIntelligenceId is null
	--and [idatom to delete]=226131074 

	 ------Name
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET 
	CompaniesNameSourceId = l.CompaniesNameSourceId,
	CompaniesNameIntelligenceId =  l.CompaniesNameIntelligenceId
	
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where l2.Name = l.Name
	and l.CompaniesNameSourceId is not null and  l2.CompaniesNameSourceId is null
	and l.CompaniesNameIntelligenceId is not null and l2.CompaniesNameIntelligenceId is null
	--and [idatom to keep]=117945222 


	 ------Registered Name
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET 
	CompanyRegisteredNameSourceId = l.CompanyRegisteredNameSourceId,
	CompanyRegisteredNameIntelligenceId =  l.CompanyRegisteredNameIntelligenceId

	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where l2.RegisteredName = l.RegisteredName
	and l.CompanyRegisteredNameSourceId is not null and  l2.CompanyRegisteredNameSourceId is null
	and l.CompanyRegisteredNameIntelligenceId is not null and l2.CompanyRegisteredNameIntelligenceId is null
	--and [idatom to keep]=117945222 

		 ------Registered Local Name
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	UPDATE  l2 SET 
	CompanyRegisteredLocalNameSourceId = l.CompanyRegisteredLocalNameSourceId,
	CompanyRegisteredLocalNameIntelligenceId =  l.CompanyRegisteredLocalNameIntelligenceId

	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	LEFT JOIN TestCrifis2.dbo.tblCompanies l on l.IDATOM = [idatom to Delete]
	LEFT JOIN TestCrifis2.dbo.tblCompanies l2 on l2.IDATOM = [idatom to keep]
	where l2.RegisteredNameLocal = l.RegisteredNameLocal
	and l.CompanyRegisteredLocalNameSourceId is not null and  l2.CompanyRegisteredLocalNameSourceId is null
	and l.CompanyRegisteredLocalNameIntelligenceId is not null and l2.CompanyRegisteredLocalNameIntelligenceId is null
	--and [idatom to keep]=117945222 


	-----------------------------  Trading names        -- Added by Jihene

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update  l set idatom = [idatom to keep]
	--select distinct l.name, [idatom to Delete], [idatom to keep], l.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	join TestCrifis2.dbo.tblCompanies_Names l2 on l2.IDATOM = [idatom to keep]
	where 
	L.[Name] not in (select l2.[Name] from TestCrifis2.dbo.tblCompanies_Names l2 where l2.IDATOM = [idatom to keep])
	and l.[Name] not in (select isnull(isnull(registeredname,name),'') from TestCrifis2.dbo.tblCompanies l where l.IDATOM = [idatom to keep])
	and l.[Name] not in (select isnull(isnull(RegisteredNameLocal,NameLocal),'') from TestCrifis2.dbo.tblCompanies l where l.IDATOM = [idatom to keep])
	--and [idatom to keep] =13154796 
	;

-------------------------Trading Names updated dates    
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set DateUpdated = l.DateUpdated
	--select [idatom to Delete], [idatom to keep], l.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	join TestCrifis2.dbo.tblCompanies_Names l2 on l2.IDATOM = [idatom to keep]
	where 
	l.[Name] = l2.[Name] 
	and l.DateUpdated > l2.DateUpdated
	;

	------------------------- Same Trading Names --> update End date, start year, start date, end year 
	----EndDate

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set Enddate = l.Enddate
	--select l.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	join TestCrifis2.dbo.tblCompanies_Names l2 on l2.IDATOM = [idatom to keep]
	where 
	l.[Name] = l2.[Name] 
	and l2.enddate is null
	and l.enddate is not null
	--and [idatom to Delete] =118016010 
	;

	-----StartDate

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set startdate = l.startdate
	--select l.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	join TestCrifis2.dbo.tblCompanies_Names l2 on l2.IDATOM = [idatom to keep]
	where 
	l.[Name] = l2.[Name] 
	and l2.startdate is null
	and l.startdate is not null
	--and [idatom to Delete] =118016010 
	;

	----StartYear

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set startyear = l.startyear
	--select l.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	join TestCrifis2.dbo.tblCompanies_Names l2 on l2.IDATOM = [idatom to keep]
	where 
	l.[Name] = l2.[Name] 
	and l2.startyear is null
	and l.startyear is not null
	--and [idatom to Delete] =118016010 
	;


	---EndYear

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update l2 set endyear = l.endyear 
	--select l.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	join TestCrifis2.dbo.tblCompanies_Names l on l.IDATOM = [idatom to Delete]
	join TestCrifis2.dbo.tblCompanies_Names l2 on l2.IDATOM = [idatom to keep]
	where 
	l.[Name] = l2.[Name] 
	and l2.endyear is null
	and l.endyear is not null
	--and [idatom to Delete] =118016010 
	;
	--select * from TestCrifis2.dbo.tblCompanies_Names where idatom =13653199 

	------------------------Files--------------------------  
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update  l set idatom = [idatom to keep]
	--select l.idatom, [idatom to keep], f.name, f2.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies_Files l on l.IDATOM = [idatom to Delete] 
	left join TestCrifis2.dbo.Files f on  f.id = l.FileId

	left join TestCrifis2.dbo.tblCompanies_Files l2 on l2.IDATOM = [idatom to keep]
	left join TestCrifis2.dbo.Files f2 on  f2.id = l2.FileId
	--where [idatom to Delete] = 13454351

	

	------------------------Financial Files--------------------------  
	
	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
		)

	update  l set CompanyIdAtom = [idatom to keep]
	--select l.CompanyIdAtom, [idatom to keep], f.name, f2.name, l.DateUpdated, l2.DateUpdated
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.CompaniesFinancials_Files l on l.CompanyIdAtom = [idatom to Delete] 
	left join TestCrifis2.dbo.Files f on  f.id = l.FileId

	left join TestCrifis2.dbo.CompaniesFinancials_Files l2 on l2.CompanyIdAtom = [idatom to keep]
	left join TestCrifis2.dbo.Files f2 on  f2.id = l2.FileId
	--where [idatom to Delete] = 13454351


	------------------------------ Main Products & Services

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
	)

	update  l set idatom = [idatom to keep]
	--select l.*, l2.*
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies2ProductsServices l on l.IDATOM = [idatom to Delete] 
	left join TestCrifis2.dbo.tblCompanies2ProductsServices l2 on l2.IDATOM = [idatom to keep]
	where l.ID is not null
	and l.IdProductService not in (select idatom from TestCrifis2.dbo.tblCompanies2ProductsServices
									where idatom =  [idatom to keep])


	------------------------------ Import & Export

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
	)

	update  l set idatom = [idatom to keep]
	--select l.*, l2.*
	from(
		SELECT DISTINCT 
			registernumber,
			[HasOrders_1],
			[HasOrders_2],
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2) 
			) [idatom to keep],

			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2, idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1) 
			) [idatom to Delete]

		FROM RankedData d
	)b
	left join TestCrifis2.dbo.tblCompanies2Capacity l on l.IDATOM = [idatom to Delete] 
	left join TestCrifis2.dbo.tblCompanies2Capacity l2 on l2.IDATOM = [idatom to keep]
	where l.ID is not null
	--and [idatom to Delete] =13640264 



	--select *
	--from [TestCrifis2].[dbo].tblCompanies2Capacity p
	--where idatom =13640264

	/* ==================== FINAL TBLATOMS REDIRECTION / SOFT DELETE (START) ==================== */

	IF OBJECT_ID('tempdb..#MergeMap') IS NOT NULL
		DROP TABLE #MergeMap;

	;WITH RankedData AS (
		SELECT 
		   d.*,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_1 = o.IDATOM)>0,1,0)) [HasOrders_1],		
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM and o.SpeedID IN (1,3,4,10) and ISNULL(o.StatusID,'')<>16)>0,1,
			iif((select count(id) from TestCrifis2.dbo.cs_orders o where o.IDATOM is not null and idatom_2 = o.IDATOM)>0,1,0)) [HasOrders_2]	
		FROM ADIP.dbo.DuplicateCompanies d
	),
	MapCandidates AS (
		SELECT DISTINCT
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_1,idatom_2),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_1, idatom_2)
			) AS IdatomToKeep,
			iif((HasOrders_1 = 1 and HasOrders_2 = 0) OR (HasOrders_1 = 0 and HasOrders_2 = 1),
						iif(HasOrders_1 = 1 and HasOrders_2 = 0, idatom_2,idatom_1),
						iif(DateUpdated_1 >= DateUpdated_2,  idatom_2, idatom_1)
			) AS IdatomToDelete
		FROM RankedData
		WHERE ISNULL(idatom_1, 0) > 0
		  AND ISNULL(idatom_2, 0) > 0
	),
	DedupedMap AS (
		SELECT
			IdatomToKeep,
			IdatomToDelete,
			ROW_NUMBER() OVER (PARTITION BY IdatomToDelete ORDER BY IdatomToKeep) AS rn
		FROM MapCandidates
		WHERE IdatomToKeep IS NOT NULL
		  AND IdatomToDelete IS NOT NULL
		  AND IdatomToKeep <> IdatomToDelete
	)
	SELECT IdatomToKeep, IdatomToDelete
	INTO #MergeMap
	FROM DedupedMap
	WHERE rn = 1;

	CREATE UNIQUE CLUSTERED INDEX IX_MergeMap_Delete ON #MergeMap (IdatomToDelete);

	-- Collapse map chains to a terminal kept ID:
	-- if B -> C and C -> D in this run, map B directly to D.
	IF OBJECT_ID('tempdb..#FinalMergeMap') IS NOT NULL
		DROP TABLE #FinalMergeMap;

	SELECT IdatomToKeep, IdatomToDelete
	INTO #FinalMergeMap
	FROM #MergeMap;

	CREATE UNIQUE CLUSTERED INDEX IX_FinalMergeMap_Delete ON #FinalMergeMap (IdatomToDelete);

	DECLARE @MapRowsUpdated INT = 1;
	DECLARE @MapPass INT = 0;

	WHILE @MapRowsUpdated > 0 AND @MapPass < 100
	BEGIN
		UPDATE fm
		SET fm.IdatomToKeep = fmNext.IdatomToKeep
		FROM #FinalMergeMap fm
		JOIN #FinalMergeMap fmNext ON fmNext.IdatomToDelete = fm.IdatomToKeep
		WHERE fm.IdatomToKeep <> fmNext.IdatomToKeep;

		SET @MapRowsUpdated = @@ROWCOUNT;
		SET @MapPass += 1;
	END;

	-- Defensive cleanup in case of circular pairs.
	DELETE FROM #FinalMergeMap
	WHERE IdatomToKeep = IdatomToDelete;

	-- Mark deleted atoms and point them to the final kept atom.
	UPDATE deletedAtom
	SET
		deletedAtom.IsDeleted = 1,
		deletedAtom.replacedByIdatom = m.IdatomToKeep,
		deletedAtom.EasyNumber = COALESCE(keptAtom.EasyNumber, m.IdatomToKeep, deletedAtom.EasyNumber)
	FROM TestCrifis2.dbo.tblAtoms deletedAtom
	JOIN #FinalMergeMap m ON m.IdatomToDelete = deletedAtom.IDATOM
	LEFT JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = m.IdatomToKeep;

	-- Cascade previous replacements:
	-- if A -> B and now B -> C, then A becomes A -> C (same for EasyNumber).
	DECLARE @RowsUpdated INT = 1;
	DECLARE @Pass INT = 0;

	WHILE @RowsUpdated > 0 AND @Pass < 100
	BEGIN
		UPDATE previousAtom
		SET
			previousAtom.IsDeleted = 1,
			previousAtom.replacedByIdatom = m.IdatomToKeep,
			previousAtom.EasyNumber = COALESCE(keptAtom.EasyNumber, m.IdatomToKeep, previousAtom.EasyNumber)
		FROM TestCrifis2.dbo.tblAtoms previousAtom
		JOIN #FinalMergeMap m ON m.IdatomToDelete = previousAtom.replacedByIdatom
		LEFT JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = m.IdatomToKeep
		WHERE previousAtom.IDATOM <> m.IdatomToKeep
		  AND (
				previousAtom.replacedByIdatom <> m.IdatomToKeep
				OR (
					previousAtom.EasyNumber IS NULL
					AND COALESCE(keptAtom.EasyNumber, m.IdatomToKeep) IS NOT NULL
				)
				OR (
					previousAtom.EasyNumber IS NOT NULL
					AND COALESCE(keptAtom.EasyNumber, m.IdatomToKeep) IS NULL
				)
				OR previousAtom.EasyNumber <> COALESCE(keptAtom.EasyNumber, m.IdatomToKeep)
		  );

		SET @RowsUpdated = @@ROWCOUNT;
		SET @Pass += 1;
	END;

	-- Apply the same redirection rule when EasyNumber itself still points to a deleted atom.
	UPDATE atom
	SET atom.EasyNumber = COALESCE(keptAtom.EasyNumber, m.IdatomToKeep, atom.EasyNumber)
	FROM TestCrifis2.dbo.tblAtoms atom
	JOIN #FinalMergeMap m ON atom.EasyNumber = m.IdatomToDelete
	LEFT JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = m.IdatomToKeep
	WHERE atom.IDATOM <> m.IdatomToKeep
	  AND (
			atom.EasyNumber IS NULL
			OR atom.EasyNumber <> COALESCE(keptAtom.EasyNumber, m.IdatomToKeep)
	  );

	DROP TABLE #FinalMergeMap;
	DROP TABLE #MergeMap;

	/* ==================== FINAL TBLATOMS REDIRECTION / SOFT DELETE (END) ==================== */
	/* ==================== OTHER SECTION (END) ==================== */

END
GO
