/*
Run once to speed up sp_DataExchange_DataLoading_mahdi_optimized.
These indexes target the heaviest name-lookup joins.
*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_tblCompanies_RegisteredName'
      AND object_id = OBJECT_ID('dbo.tblCompanies')
)
BEGIN
    CREATE INDEX IX_tblCompanies_RegisteredName
    ON dbo.tblCompanies (RegisteredName)
    INCLUDE (IDATOM, [Name]);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_tblCompanies_Name'
      AND object_id = OBJECT_ID('dbo.tblCompanies')
)
BEGIN
    CREATE INDEX IX_tblCompanies_Name
    ON dbo.tblCompanies ([Name])
    INCLUDE (IDATOM, RegisteredName);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_tblAtoms_Country_Active'
      AND object_id = OBJECT_ID('dbo.tblAtoms')
)
BEGIN
    CREATE INDEX IX_tblAtoms_Country_Active
    ON dbo.tblAtoms (IdRegisteredCountry, IsDeleted)
    INCLUDE (IDATOM, DateUpdated);
END;
