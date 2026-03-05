;WITH EligibleAtoms AS (
    /* Your eligibility set (the 2nd query) */
    SELECT DISTINCT com.IDATOM
    FROM tblCompanies com WITH(NOLOCK)
    JOIN tblatoms a WITH(NOLOCK) ON com.IDATOM = a.IDATOM
    JOIN tblCompanyIDs cid WITH(NOLOCK)
        ON com.IDATOM = cid.IDATOM
       AND ISNULL(cid.Number,'') != ''
       AND cid.IdStatus = 2949507
    JOIN tblCompanies2Types ct WITH(NOLOCK)
        ON com.IDATOM = ct.IDATOM
       AND ct.IdType IS NOT NULL
    JOIN tblAtoms2Addresses aa WITH(NOLOCK)
        ON com.IDATOM = aa.IDATOM
       AND aa.IsMain = 1
    JOIN tblAddresses ad WITH(NOLOCK)
        ON ad.ID = aa.IdAddress
       AND ISNULL(ad.IdTown,0) != 0
    JOIN tblCompanies2Activities ca WITH(NOLOCK)
        ON com.IDATOM = ca.IDATOM
       AND ca.[IsPrimary] = 1
    WHERE ISNULL(a.IsDeleted,0)=0
      AND a.IdRegisteredCountry IN (9,16,48,49,90,119,128)
),
EligibleCountries AS (
    SELECT DISTINCT a.IdRegisteredCountry
    FROM tblAtoms a WITH (NOLOCK)
    JOIN EligibleAtoms ea ON ea.IDATOM = a.IDATOM
    WHERE ISNULL(a.IsDeleted,0)=0
)
SELECT c.Country as [Country]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
        and a.IdRegisteredCountry = c.id 
        and isnull(a.isdeleted,0) = 0 and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
        and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Total Number of Companies]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '')
        and a.IdRegisteredCountry = c.id 
        and (isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
        and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
        and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Names in English AND Native Name]
 
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.RegisteredName,'') <> '' or  isnull(com.RegisteredNameLocal,'') <> '' or isnull(com.Name,'') <> '' or isnull(com.NameLocal,'') <> '')
        and a.IdRegisteredCountry = c.id 
        and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
        and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Names in English or Native Name]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where isnull(com.Name,'') = '' 
          and isnull(com.RegisteredName,'') = '' 
          and a.IdRegisteredCountry = c.id 
          and (isnull(com.NameLocal,'') <> '' Or isnull(com.RegisteredNameLocal,'') <> '') 
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Names in Native ONLY]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where isnull(com.NameLocal,'') = '' 
          and isnull(com.RegisteredNameLocal,'') = '' 
          and a.IdRegisteredCountry = c.id 
          and (isnull(com.Name,'') <> '' Or isnull(com.RegisteredName,'') <> '') 
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Names in English ONLY]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        where a.IdRegisteredCountry = c.id and isnull(ad.ismain,0) = 1
        and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
        and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Main Address]

    ,(select count(aa.id) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a on a.IDATOM = com.IDATOM  
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
        and a.IdRegisteredCountry = c.id and aa.IsMain = 0 
        and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
        and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Branches]

    ,(select count(distinct com.IDATOM) 
        from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tblAddresses adr WITH (NOLOCK) on adr.ID = ad.IdAddress 
        where isnull(a.isdeleted,0) = 0 
          and (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and adr.IdTown is not NULL  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address_Town]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and adr.idArea is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Area]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(adr.PlotNo,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address PlotNo]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and adr.idStreet is not null 
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Street]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(adr.StreetNumber,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address StreetNo]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(adr.BlockNo,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address BlockNo]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and adr.idBuilding is not null 
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Building]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(adr.BuildingNo,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address BuildingNo]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(adr.OfficeUnit,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Office Unit]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(adr.[Floor],'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Floor]
   
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tbladdresses adr WITH (NOLOCK) on adr.ID = ad.IDAddress 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and (isnull(adr.Description1,'') <> '' or isnull(adr.Description2,'') <> '')
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Description]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblPremises ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(ad.[Premise],'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address Premise]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies_OriginalText] ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ad.[Premises_Comment] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Address PremisesComments Comment]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 	
        inner join tblCompanies2Status cs WITH (NOLOCK)  on cs.IDatom = com.IDATOM
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Status]  
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 	
        inner join tblCompanies2Status cs WITH (NOLOCK)  on cs.IDatom = com.IDATOM
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and cs.IdStatus is not null and IdStatus = 3680101
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Status Active]   

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 	
        inner join tblCompanies2Status cs WITH (NOLOCK)  on cs.IDatom = com.IDATOM
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and cs.IdStatus is not null and IdStatus = 3686193
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Status Not Active]   

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on  a.IDATOM = com.IDATOM 
        inner join tblCompanies_Names cn WITH (NOLOCK) on cn.IDATOM = com.IDATOM	
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and cn.NameType is not null  and cn.NameType = 1
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Trading name - English Names] 

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on  a.IDATOM = com.IDATOM 
        inner join tblCompanies_Names cn WITH (NOLOCK) on cn.IDATOM = com.IDATOM	
        where cn.NameType is not null  and cn.NameType = 2
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Trading name - Local Names] 

    ,(select count(distinct com.idatom) from tblatoms a WITH (NOLOCK)
        join tblcompanies com WITH (NOLOCK) on a.idatom = com.idatom
        join CS_CompanyHistory ch WITH (NOLOCK) on com.idatom = ch.idatom
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(a.isdeleted,0) =0 and a.idregisteredcountry= c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Historical Changes]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 	
        inner join tblDic_Comments cm WITH (NOLOCK)  on cm.ID = com.IdHistoryComment
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(cm.DummyName,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [History Comment]	   

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 	
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(com.IsListed,0)=1
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Company is Listed] 

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Types aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM  
        inner join tblDic_BaseValues bv WITH (NOLOCK) on aa.idtype = bv.Id
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Legal Form]

    ,(select count(distinct com.IDATOM) from tblCompanyids com 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM  
        inner join tblCompanies aa WITH (NOLOCK) on aa.IDATOM = com.IDATOM 
        where (isnull(aa.Name,'') <> '' or isnull(aa.RegisteredName,'') <> '' or isnull(aa.NameLocal,'') <> '' or isnull(aa.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id 
          and (com.IdOrganisation is not null or com.IdRegister is not null) 
          and isnull(com.Number,'') <> '' 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Unique_Identification_Number]
	
    ,(select count(distinct com.IDATOM) from tblCompanyids com 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM  
        inner join tblCompanies aa WITH (NOLOCK) on aa.IDATOM = com.IDATOM 
        where (isnull(aa.Name,'') <> '' or isnull(aa.RegisteredName,'') <> '' or isnull(aa.NameLocal,'') <> '' or isnull(aa.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id 
          and (com.IdOrganisation is not null and com.IdRegister is null) 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Register NULL]

    ,(select count(distinct com.IDATOM) from tblCompanyids com  WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
        where a.IdRegisteredCountry = c.id 
          and isnull(com.Number,'') <> '' 
          and isnull(a.isdeleted,0) = 0  
          and com.idStatus is not null
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Legal-Status]

    ,(select count(distinct com.IDATOM) from tblCompanyids com  WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339) 
        where a.IdRegisteredCountry = c.id 
          and isnull(com.Number,'') <> '' 
          and isnull(com.idStatus,'') = 2949507
          and isnull(a.isdeleted,0) = 0 
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Legal Status_Active]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and (com.DateIncorporation is not NULL or com.YearIncorporation is not NULL or a.DateStart is not NULL or a.YearStart is not NULL)
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Registration_Date]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Employees e WITH (NOLOCK) on e.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and isnull(a.isdeleted,0)=0
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Employees]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblatoms a WITH (NOLOCK) on com.IDATOM = a.IDATOM and isnull(a.isdeleted,0) = 0
        inner join tblCompanies_Capital ca WITH (NOLOCK) on ca.IDATOM = com.IDATOM	
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
          and (ca.paidUp is not null or ca.Issued is not null or ca.Authorised is not null or ca.Unspecified is not null) 
          and a.IdRegisteredCountry = c.id and isnull(a.isdeleted,0)=0
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Capital]
	
    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and exists (select idatom from tblCompanies2Shareholders c where c.IDATOM = com.IDATOM )
          and isnull(a.isdeleted,0)=0
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Shareholders]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblcompanies2shareholders cp WITH (NOLOCK) on cp.IDATOM = com.IDATOM 
        inner join tblCompanies cpc WITH (NOLOCK) on cpc.IDATOM = cp.idrelated
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Shareholders Companies]
    
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblcompanies2shareholders cp WITH (NOLOCK) on cp.IDATOM = com.IDATOM 
        inner join tblpersons cpc WITH (NOLOCK) on cpc.IDATOM = cp.idrelated
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Shareholders Person]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblcompanies2shareholders cp WITH (NOLOCK) on cp.IDATOM = com.IDATOM 
        inner join [tblLists] cpc on cpc.IDATOM = cp.idrelated
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Shareholders Others]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_OriginalText ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and (isnull(ac.shareholders_Owners,'') <> '' or isnull(ac.shareholders_Owners_details_profile,'') <> '')
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Shareholders Comment]

    ,(select count(distinct cf1.IDATOM) from vwFinancials_Fields ff WITH (NOLOCK)
        inner join tblFinancials_StatementType st WITH (NOLOCK) on  st.Id = ff.IdStatementType
        inner join tblCompanies_Financials_FieldValues fv WITH (NOLOCK) on fv.IdField = ff.ID and ff.id in(4375 ,4337)
        inner join tblCompanies_Financials cf1 WITH (NOLOCK) on cf1.ID = fv.IdFinancial
        INNER JOIN tblAtoms atoms WITH (NOLOCK) on atoms.IDATOM = cf1.IDATOM
        inner join tblCompanies com WITH (NOLOCK) on com.IDATOM = atoms.idatom
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and atoms.IdRegisteredCountry = c.id 
          and ff.idculture = 3 
          and FinancialValue is not null
          and isnull(atoms.isdeleted,0)=0  and isnull(atoms.ImportId,0) not in (343,342,341,340,339,353,352,351,350,349,348)
          and atoms.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Turnover]

    ,(select count(distinct cf1.IDATOM) from vwFinancials_Fields ff WITH (NOLOCK)
        inner join tblFinancials_StatementType st WITH (NOLOCK) on st.Id = ff.IdStatementType
        inner join tblCompanies_Financials_FieldValues fv WITH (NOLOCK) on fv.IdField = ff.ID and ff.id in(4411,4334,4413)
        inner join tblCompanies_Financials cf1 WITH (NOLOCK) on cf1.ID = fv.IdFinancial
        INNER JOIN tblAtoms atoms WITH (NOLOCK) on atoms.IDATOM = cf1.IDATOM
        inner join tblCompanies com WITH (NOLOCK) on com.IDATOM = atoms.idatom
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and atoms.IdRegisteredCountry = c.id 
          and ff.idculture = 3 
          and FinancialValue is not null
          and isnull(atoms.isdeleted,0)=0  and isnull(atoms.ImportId,0) not in (343,342,341,340,339,353,352,351,350,349,348)
          and atoms.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Profit]

    ,(select count(distinct cf1.IDATOM) from vwFinancials_Fields ff WITH (NOLOCK)
        inner join tblFinancials_StatementType st WITH (NOLOCK) on st.Id = ff.IdStatementType
        inner join tblCompanies_Financials_FieldValues fv WITH (NOLOCK) on fv.IdField = ff.ID and ff.id = 4362 
        inner join tblCompanies_Financials cf1 WITH (NOLOCK) on cf1.ID = fv.IdFinancial
        INNER JOIN tblAtoms atoms WITH (NOLOCK) on atoms.IDATOM = cf1.IDATOM
        inner join tblCompanies com WITH (NOLOCK) on com.IDATOM = atoms.idatom
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and atoms.IdRegisteredCountry = c.id and ff.idculture = 3 and FinancialValue is not null
          and isnull(atoms.isdeleted,0) = 0  and isnull(atoms.ImportId,0) not in (343,342,341,340,339,353,352,351,350,349,348)
          and atoms.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Total Assets]

    ,(select count(distinct cf1.IDATOM) from vwFinancials_Fields ff WITH (NOLOCK)
        inner join tblFinancials_StatementType st WITH (NOLOCK) on  st.Id = ff.IdStatementType
        inner join tblCompanies_Financials_FieldValues fv WITH (NOLOCK) on fv.IdField = ff.ID and ff.id = 4397
        inner join tblCompanies_Financials cf1 WITH (NOLOCK) on cf1.ID = fv.IdFinancial
        INNER JOIN tblAtoms atoms WITH (NOLOCK) on atoms.IDATOM = cf1.IDATOM
        inner join tblCompanies com WITH (NOLOCK) on com.IDATOM = atoms.idatom
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and atoms.IdRegisteredCountry = c.id 
          and ff.idculture = 3 
          and FinancialValue is not null
          and isnull(atoms.isdeleted,0)=0  and isnull(atoms.ImportId,0) not in (343,342,341,340,339,353,352,351,350,349,348)
          and atoms.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Total Shareholders Funds and Liabilities]

    ,(select count(distinct cf1.IDATOM) from vwFinancials_Fields ff WITH (NOLOCK)
        inner join tblFinancials_StatementType st WITH (NOLOCK) on  st.Id = ff.IdStatementType
        inner join tblCompanies_Financials_FieldValues fv WITH (NOLOCK) on fv.IdField = ff.ID and ff.id = 4276
        inner join tblCompanies_Financials cf1 WITH (NOLOCK) on cf1.ID = fv.IdFinancial
        INNER JOIN tblAtoms atoms WITH (NOLOCK) on atoms.IDATOM = cf1.IDATOM
        inner join tblCompanies com WITH (NOLOCK) on com.IDATOM = atoms.idatom
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and atoms.IdRegisteredCountry = c.id 
          and ff.idculture = 3 
          and FinancialValue is not null
          and isnull(atoms.isdeleted,0)=0  and isnull(atoms.ImportId,0) not in (343,342,341,340,339,353,352,351,350,349,348)
          and atoms.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Shareholders Funds]

    ,(select count(distinct cf1.IDATOM) from tblCompanies ff WITH (NOLOCK)
        inner join tblCompanies_Financials cf1 WITH (NOLOCK) on cf1.IDatom = ff.idatom
        INNER JOIN tblAtoms atoms WITH (NOLOCK) on atoms.IDATOM = cf1.IDATOM
        where atoms.IdRegisteredCountry = c.id 
          and isnull(atoms.isdeleted,0)=0  and isnull(atoms.ImportId,0) not in (343,342,341,340,339,353,352,351,350,349,348)
          and atoms.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [any Finanical Field]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_OriginalText ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(ac.Financial_Comment,'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Financial Comment]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and exists (select IDRELATED from tblCompanies2Shareholders c WITH (NOLOCK) where c.IDRELATED = com.IDATOM )
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Subsidiaries]
 
    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and exists (select idatom from tblCompanies2Administrators c where c.IDATOM = com.IDATOM )
          and isnull(a.isdeleted,0)=0
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Directors/Managers]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Administrators ca WITH (NOLOCK) on ca.IDATOM = com.IDATOM		
        inner join tblpersons ab WITH (NOLOCK) on ab.IDATOM = ca.IDRELATED			  
        where a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0 and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Directors/Managers - Individuals] 
		
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Administrators ca WITH (NOLOCK) on ca.IDATOM = com.IDATOM		
        inner join tblCompanies ab WITH (NOLOCK) on ab.IDATOM = ca.IDRELATED			  
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0 and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Directors/Managers - Companies] 
	
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 	
        inner join tblCompanies_OriginalText ta WITH (NOLOCK) on ta.IDATOM = com.IDATOM
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ISNULL(Managers,'') <> ''
          and a.IdRegisteredCountry = c.id 	  
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Directors/Managers - Managers Originals]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id  
          and (
              exists(select * from tblContacts_Phones p where p.IdContact = aa.IdContact and p.IdPhoneType in (2949458, 2949460) and p.Number is not NULL) 
              or 
              exists(select * from tblContacts_Phones p where p.IdContact = aa.IdContact and p.IdPhoneType in (2949459) and p.Number is not NULL)
          )
          and ad.IdTown is not NULL 
          and ad.IdArea is not NULL 
          and ad.IdStreet is not NULL 
          and ad.IdBuilding is not NULL 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [full Contact details]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id
          and (
              exists(select * from tblContacts_Phones p where p.IdContact = aa.IdContact and isnull(p.Number,'')<>'' )
              or exists(select * from tblContacts_Emails e where e.IdContact = aa.IdContact and isnull(e.Email,'')<>'' )
              or exists(select * from tblContacts_Webs w where w.IdContact = aa.IdContact and isnull(w.Web,'')<>'' )
          )
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [any Contact detail]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tblContacts_Phones p WITH (NOLOCK) on p.IDcontact = ad.IDcontact 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(p.[Number],'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Phone]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id
          and exists(select * from tblContacts_Phones p where p.IdContact = aa.IdContact and isnull(p.Number,'')<>'' and idphoneType in(2949460,2949458))
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Mobile or phone number]
  
    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id
          and exists(select * from tblContacts_Phones p where p.IdContact = aa.IdContact and isnull(p.Number,'')<>'' and idphoneType = 2949460)
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Mobile Number]
  
    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id
          and exists(select * from tblContacts_Phones p where p.IdContact = aa.IdContact and isnull(p.Number,'')<>'' and idphoneType = 2949459)
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Fax Number]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblatoms2addresses ad WITH (NOLOCK) on ad.IDATOM = com.IDATOM 
        inner join tblContacts_webs p WITH (NOLOCK) on p.IDcontact = ad.IDcontact 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(p.[Web],'') <> ''
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Website]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id
          and exists(select * from tblContacts_Emails p where p.IdContact = aa.IdContact and isnull(p.Email,'')<>'' )
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Email Address]
 
    ,(select count(distinct com.IDATOM) 
        from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and isnull(pobox,'')<>''
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [POBOX]

    ,(select count(distinct com.IDATOM) 
        from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and ( isnull(PostalCode,'')<>'' or isnull(PostalCode_Postal,'')<>'')
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [postal Code]

    ,(select count(distinct com.IDATOM) 
        from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblAtoms2Addresses aa WITH (NOLOCK) on a.IDATOM = aa.IDATOM 
        inner join tblAddresses ad WITH (NOLOCK) on ad.id = aa.IdAddress
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and (isnull(PostalCode,'') <> '' or isnull(PostalCode_Postal,'') <> '' or isnull(pobox,'') <> '')
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [postal address]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')
          and a.IdRegisteredCountry = c.id 
          and exists(select * from tblCompanies2Activities ca WITH (NOLOCK) 
                     where ca.IDATOM = com.IDATOM  
                       and (ca.IdClassUksic is not null or ca.IdDivisionUksic is not null or ca.IdGroupUksic is not null or ca.IdSubClassUksic is not null))
          and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Activity Codes]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_OriginalText co WITH (NOLOCK) on co.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and co.Activities_Comment is not null 
          and co.Activities_Comment <> '' and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Activity description/Overview]

    ,(select count(distinct com.IDATOM) from tblCompanies com WITH (NOLOCK)
        inner join tblatoms a WITH (NOLOCK) on com.IDATOM = a.IDATOM and isnull(a.isdeleted,0) = 0
        inner join tblCompanies_CreditRating ca WITH (NOLOCK) on ca.IDATOM = com.IDATOM  and MaximumCredit > 0
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' 
               or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '') 
          and a.IdRegisteredCountry = c.id  and isnull(a.isdeleted,0)=0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Credit Rating]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_CreditHistory ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Credit History]
  
    ,(
        SELECT count(distinct a.IDATOM)
        FROM tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM
        inner join tblCompanies2Shareholders cs WITH (NOLOCK) on cs.IDATOM = com.IDATOM	
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(a.isdeleted,0) = 0 and a.IdRegisteredCountry =c.id  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and ((select count(1) from tblCompanies2Shareholders c WITH (NOLOCK) join tblcompanies cc on cc.idatom = c.idrelated where c.IDATOM = com.IDATOM) > 0
            or (select count(1) from tblCompanies2Shareholders c where c.IdRelated = com.IDATOM) > 0
            or (select count(1) from tblCompanies2Shareholders c WITH (NOLOCK) join tblpersons cc on cc.idatom = c.idrelated 
                where c.IDATOM = com.IDATOM and c.SharesPercent >= 25) > 0)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [UBO]
	
    ,(
        SELECT count(distinct a.IDATOM)
        FROM tblCompanies com WITH (NOLOCK)
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM
        inner join tblCompanies2Shareholders cs WITH (NOLOCK) on cs.IDATOM = com.IDATOM	
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and isnull(a.isdeleted,0) = 0 and a.IdRegisteredCountry =c.id  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and (
              (select count(1) from tblCompanies2Shareholders c WITH (NOLOCK) join tblcompanies cc on cc.idatom = c.idrelated where c.IDATOM = com.IDATOM) > 0
              or (select count(1) from tblCompanies2Shareholders c where c.IdRelated = com.IDATOM) > 0
              or (select count(1) from tblCompanies2Shareholders c WITH (NOLOCK) join tblpersons cc on cc.idatom = c.idrelated 
                  where c.IDATOM = com.IDATOM and c.SharesPercent >= 25) > 0)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Group Structure]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2950250
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Banker]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2949528
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Affiliate]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2950252
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Auditors]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2949529
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Agent For]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2949530
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Client]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2949531
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Trade Supplier]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 2950281
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Solicitor]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 4092268
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Audit Firm]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Related ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.idTypeRelated is not null and ac.idTypeRelated = 4092269
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Relation - Law Firm]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_Profiles ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Brands and Trade Marks]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_OriginalText ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.[Brands_Comment] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Brands Comments]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies2Searchers] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.[IdDebtAgencies] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Debt Collection Agencies Search]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies_CreditRating] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.[IdBusinessTrend] is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Business Trend]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies_CreditRating] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.[IdSize] is not null 
          and com.idatom in(select ca.idatom from tblCompanies2Activities ca WITH (NOLOCK) where ca.IDATOM = com.IDATOM)
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Size]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies2Capacity] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.[ImportValue] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Commerce - Import]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies2Capacity] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.[ExportValue] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Commerce - Export]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies_OriginalText ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and (isnull(ac.[Import_Value],'') <> '' or isnull(ac.[Export_Value],'') <> '')
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Import Export Originals]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies2PayMethods] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.[IdPayMethod] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Method of Payment]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies_Certifications] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and ac.[IdCertificateType] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Certifications]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies2Capacity] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Production Capacity]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [CS_TradeSuppliers] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where ac.[TradeSupplierID] is not null
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Trade Reference]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK)  on a.IDATOM = com.IDATOM 
        inner join [tblCompanies_Files] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.[FileId] is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Files]

    ,(select count(*) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies2InternetPortals] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and isnull(ac.link,'')<> ''
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Internet Portals]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdCriminalRecords is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Criminal Record]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdPublicationsMedia is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Publications Media]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdBankruptcies is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Bankruptcies]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdLocalGazette is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Published Legal Announcement and Local Gazette Searches]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdInternationlaCrimeWatch is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Global & Local Compliance & Sanction List Checks]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdAdverseMedia is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Adverse Media]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdDefaultCases is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Default Cases]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdLegalProcedures is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Legal Procedures]
  
    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdLocalReputation is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Local Reputation]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.IdPoliticallyExposedPersons is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Politically Exposed Persons]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join tblCompanies2Searchers ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id and ac.idcomment is not null
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [BUSINESS INTELLIGENCE & COMMENTS]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        inner join [tblCompanies_ChargesMortgages] ac WITH (NOLOCK) on ac.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [Charges and Mortgages]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0
          and isnull(com.finalratio,0) <> 0  and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [CR Score - Zeros not included]

    ,(select count(distinct com.idatom) from tblCompanies com WITH (NOLOCK) 
        inner join tblAtoms a WITH (NOLOCK) on a.IDATOM = com.IDATOM 
        where (isnull(com.Name,'') <> '' or isnull(com.RegisteredName,'') <> '' or isnull(com.NameLocal,'') <> '' or isnull(com.RegisteredNameLocal,'') <> '')  
          and a.IdRegisteredCountry = c.id 
          and isnull(a.isdeleted,0) = 0
          and com.finalratio is not null and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and com.IDATOM in (select IDATOM from EligibleAtoms)
    ) as [CR Score - With Zeros]

    ,(select count(distinct com.idatom) from dbo.tblatoms a with(nolock)
        join dbo.tblcompanies com with(nolock) on com.idatom = a.idatom 
        where isnull(a.isdeleted,0) = 0 and a.IdRegisteredCountry = c.id 
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and not exists (select 1 from dbo.tblCompanies2Status where idatom = com.IDATOM)
          and a.IDATOM in (select IDATOM from EligibleAtoms)
    ) [Unknown operational status]

    ,(select count(distinct a.idatom) from dbo.tblatoms a with(nolock)
        join dbo.tblcompanyids cid with(nolock) on cid.idatom = a.idatom
        where isnull(a.isdeleted,0) = 0 and a.IdRegisteredCountry = c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and (cid.idstatus = 3755950 or cid.idstatus is null)
          and cid.IdType = 4047632
          and a.IDATOM in (select IDATOM from EligibleAtoms)
    ) [Unknow legal status]

    ,(select count(distinct a.idatom) from dbo.tblatoms a with(nolock)
        join dbo.tblcompanyids cid with(nolock) on cid.idatom = a.idatom
        where isnull(a.isdeleted,0) = 0 and a.IdRegisteredCountry = c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and cid.idstatus is not null and cid.idstatus in (2949508,3755956,3755958,3755960,3755961,4083437)
          and cid.IdType = 4047632
          and a.IDATOM in (select IDATOM from EligibleAtoms)
    ) [Inactive legal status]

    ,(select count(distinct a.idatom) from dbo.tblatoms a with(nolock)
        join dbo.tblcompanyids cid with(nolock) on cid.idatom = a.idatom
        where isnull(a.isdeleted,0) = 0 and a.IdRegisteredCountry = c.id
          and isnull(a.ImportId,0) not in (353,352,351,350,349,348,343,342,341,340,339)
          and cid.idstatus is not null and cid.idstatus in (3755955,2949509,3755959,4087348,4087349,4092475,4092935,4093349,4076055)
          and cid.IdType = 4047632
          and a.IDATOM in (select IDATOM from EligibleAtoms)
    ) [Other legal status]

FROM tblDic_GeoCountries c
WHERE c.ID IN (SELECT IdRegisteredCountry FROM EligibleCountries)
ORDER BY Country asc;