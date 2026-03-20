/*
Optimization patch for dbo.sp_DataExchange_DataLoading

This file contains drop-in replacements for the highest-cost blocks that are
triggered by the provided JSON (Financials, AdditionalFinancials, Register lookup,
Trading Names, and Number of Employees). Replace each original block in the
procedure with the corresponding optimized block below.
*/

/*================================================================================
1) Financials staging
Replace the existing INSERT into #Financials with the block below (keep the
two UPDATE statements that follow it unchanged).
================================================================================*/

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
            FinancialCurrency NVARCHAR(10) '$.FINANCIALCURRENCY'
        ) f;

/*================================================================================
2) AdditionalFinancials recursive flatten
Replace the WITH Statement ... INSERT INTO #FinancialAnalyses block with the one
below (keep the two UPDATE statements that follow it unchanged).
================================================================================*/

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
                FINANCIALCURRENCY NVARCHAR(10) '$.FINANCIALCURRENCY',
                Analyses NVARCHAR(MAX) '$.Analyses' AS JSON
            ) ps
        ),
        AnalysesRecursive AS (
            -- Anchor members: root-level analyses
            SELECT
                ps.StatementID,
                TRY_CAST(ps.FINANCIALDATE AS DATE) AS FinancialDate,
                ps.MONTHSNO,
                ps.Denomination,
                ps.[YEAR],
                ps.[Type],
                ps.[Audit],
                ps.STATEMENTTYPE,
                ps.FINANCIALCURRENCY,
                a.[Code],
                a.[Description],
                a.FinancialValue,
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
                ar.StatementType,
                ar.FinancialCurrency,
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
            StatementID,
            FinancialDate,
            MONTHSNO,
            Denomination,
            [YEAR],
            [Type],
            [Audit],
            StatementType,
            Currency,
            Code,
            [Description],
            FinancialValue,
            ParentCode,
            [Level]
        )
        SELECT
            StatementID,
            FinancialDate,
            MONTHSNO,
            Denomination,
            [YEAR],
            [Type],
            [Audit],
            StatementType,
            FinancialCurrency,
            Code,
            [Description],
            FinancialValue,
            ParentCode,
            [Level]
        FROM AnalysesRecursive;

/*================================================================================
3) Register lookup for UID/idatom (cursor removal)
Add an IDENTITY column to #REGISTERS for deterministic order, then replace the
reg_cursor loop with the block below.
================================================================================*/

        -- In the #REGISTERS temp table definition add:
        -- ID INT IDENTITY(1,1) PRIMARY KEY,

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

/*================================================================================
4) Trading Names upsert (cursor removal)
Replace the TradingNames cursor block with the block below.
================================================================================*/

        IF EXISTS (SELECT 1 FROM #TradingNames)
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

            INSERT INTO tblcompanies_names (
                idatom,
                NameType,
                Name,
                Intelligenceid,
                Sourceid,
                isHistory,
                DateUpdated,
                ReportedDate,
                startDate,
                EndDate
            )
            SELECT DISTINCT
                @idatom,
                tn.IsNative,
                tn.[Name],
                @IntelligenceID,
                @SourceID,
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

        SET @DTSourceID = NULL;
        SET @DTIntelligenceID = NULL;
        SET @DTRanking = NULL;

/*================================================================================
5) Number of Employees upsert (cursor removal)
Replace the Employees cursor block with the block below.
================================================================================*/

        IF EXISTS (SELECT 1 FROM #NUMBEROFEMPLOYEES)
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
                    SET UpdatedDate = GETDATE(),
                        SourceID = @SourceID,
                        IntelligenceID = @IntelligenceID
                WHERE IDATOM = @idatom;
            END;

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
                SET e.TotalNumberFrom = n.NumberFrom
            FROM tblCompanies_Employees e
            JOIN Ranked r
                ON r.IDATOM = e.IDATOM
               AND r.[Year] = e.[Year]
            JOIN #NUMBEROFEMPLOYEES n
                ON n.[Year] = e.[Year]
            WHERE e.IDATOM = @idatom
              AND n.NumberFrom IS NOT NULL
              AND r.Ranking >= @RankingID
              AND ISNULL(e.TotalNumberFrom, -1) < n.NumberFrom;

            INSERT INTO tblCompanies_Employees (
                idatom,
                TotalNumberFrom,
                [Year],
                ReportedDate,
                UpdatedDate,
                ShowInReport,
                SourceID,
                IntelligenceID
            )
            SELECT
                @idatom,
                n.NumberFrom,
                n.[Year],
                GETDATE(),
                GETDATE(),
                1,
                @SourceID,
                @IntelligenceID
            FROM #NUMBEROFEMPLOYEES n
            WHERE n.NumberFrom IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM tblCompanies_Employees e
                  WHERE e.IDATOM = @idatom
                    AND e.[Year] = n.[Year]
              );
        END

        SET @DTSourceID = NULL;
        SET @DTIntelligenceID = NULL;
        SET @DTRanking = NULL;
