/*
Optimization patch for dbo.sp_DataExchange_DataLoading

This file contains drop-in replacements for the highest-cost blocks that are
triggered by the provided JSON (Financials, AdditionalFinancials, Register lookup,
Trading Names, and Number of Employees). Replace each original block in the
procedure with the corresponding optimized block below.
*/

/*================================================================================
1) Financials staging
Replace the existing INSERT into #Financials and the two UPDATEs that follow it
with the block below.
================================================================================*/

        INSERT INTO #Financials (
            FinancialDate,
            FinancialDate_new,
            MONTHSNO,
            Denomination,
            [YEAR],
            [Type],
            [Audit],
            [Name],
            StatementType,
            FinancialValue,
            FinancialCurrency,
            IsConsolidated
        )
        SELECT
            COALESCE(
                TRY_CONVERT(date, f.FinancialDateRaw, 103),
                TRY_CONVERT(date, f.FinancialDateRaw, 112)
            ) AS FinancialDate,
            COALESCE(
                TRY_CONVERT(date, f.FinancialDateRaw, 103),
                TRY_CONVERT(date, f.FinancialDateRaw, 112)
            ) AS FinancialDate_new,
            f.MONTHSNO,
            f.Denomination,
            f.[YEAR],
            f.[Type],
            f.[Audit],
            f.[Name],
            f.StatementType,
            f.FinancialValue,
            f.FinancialCurrency,
            CASE f.[Type]
                WHEN 'Consolidated' THEN 1
                WHEN 'Standalone' THEN 0
                ELSE NULL
            END AS IsConsolidated
        FROM OPENJSON(@Json, '$.FINANCIALS.FINANCIAL')
        WITH (
            FinancialDateRaw NVARCHAR(20) '$.FINANCIALDATE',
            MONTHSNO INT '$.MONTHSNO',
            Denomination NVARCHAR(50) '$.Denomination',
            [YEAR] INT '$.YEAR',
            [Type] NVARCHAR(50) '$.TYPE',
            [Audit] NVARCHAR(50) '$.AUDIT',
            [Name] NVARCHAR(255) '$.NAME',
            StatementType NVARCHAR(50) '$.STATEMENTTYPE',
            FinancialValue DECIMAL(18,3) '$.FINANCIALVALUE',
            FinancialCurrency NVARCHAR(10) '$.FINANCIALCURRENCY'
        ) f;

/*================================================================================
2) AdditionalFinancials recursive flatten
Replace the WITH Statement ... UPDATE #FinancialAnalyses block with the one below.
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
                ps.FinancialDateRaw,
                ps.MONTHSNO,
                ps.Denomination,
                ps.[YEAR],
                ps.[Type],
                ps.[Audit],
                ps.StatementType,
                ps.FinancialCurrency,
                ps.Analyses
            FROM Statement s
            CROSS APPLY OPENJSON(s.StatementJson)
            WITH (
                FinancialDateRaw NVARCHAR(20) '$.FINANCIALDATE',
                MONTHSNO INT '$.MONTHSNO',
                Denomination NVARCHAR(50) '$.Denomination',
                [YEAR] INT '$.YEAR',
                [Type] NVARCHAR(50) '$.TYPE',
                [Audit] NVARCHAR(50) '$.AUDIT',
                StatementType NVARCHAR(50) '$.STATEMENTTYPE',
                FinancialCurrency NVARCHAR(10) '$.FINANCIALCURRENCY',
                Analyses NVARCHAR(MAX) '$.Analyses' AS JSON
            ) ps
        ),
        AnalysesRecursive AS (
            -- Anchor members: root-level analyses
            SELECT
                ps.StatementID,
                COALESCE(
                    TRY_CONVERT(date, ps.FinancialDateRaw, 103),
                    TRY_CONVERT(date, ps.FinancialDateRaw, 112)
                ) AS FinancialDate,
                ps.MONTHSNO,
                ps.Denomination,
                ps.[YEAR],
                ps.[Type],
                ps.[Audit],
                ps.StatementType,
                ps.FinancialCurrency,
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
            FinancialDate_new,
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
            [Level],
            IsConsolidated
        )
        SELECT
            StatementID,
            FinancialDate,
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
            [Level],
            CASE [Type]
                WHEN 'Consolidated' THEN 1
                WHEN 'Standalone' THEN 0
                ELSE NULL
            END AS IsConsolidated
        FROM AnalysesRecursive;

/*================================================================================
3) Register lookup for UID/idatom (cursor removal)
Replace the reg_cursor loop with the block below.
================================================================================*/

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
        ORDER BY r.REGISTERNUMBER;

        PRINT '  Derived @UID = ' + ISNULL(@UID, 'NULL');

        IF (@UID IS NOT NULL AND @UID <> '')
        BEGIN
            PRINT 'idatom resolved: ' + ISNULL(CAST(@idatom AS NVARCHAR(50)), 'NULL');
        END
        ELSE
        BEGIN
            PRINT 'No match found for any register number.';
        END

/*================================================================================
4) Trading Names upsert (cursor removal)
Replace the TradingNames cursor block with the block below.
================================================================================*/

        IF EXISTS (SELECT 1 FROM #TradingNames)
        BEGIN
            UPDATE cn
                SET cn.DateUpdated = GETDATE(),
                    cn.SourceId = @SourceID,
                    cn.IntelligenceId = @IntelligenceID,
                    cn.IsHistory = tn.IsHistory,
                    cn.NameType = tn.IsNative,
                    cn.StartDate = tn.STARTDATE,
                    cn.EndDate = tn.ENDDATE
            FROM tblcompanies_names cn
            JOIN #TradingNames tn
                ON cn.IDATOM = @idatom
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
            FROM #TradingNames tn
            WHERE NOT EXISTS (
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
            ;WITH Existing AS (
                SELECT
                    e.IDATOM,
                    e.[Year],
                    e.TotalNumberFrom,
                    rs.[Rank] AS SourceRank,
                    ri.[Rank] AS IntelligenceRank
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
                SET e.UpdatedDate = GETDATE(),
                    e.SourceID = @SourceID,
                    e.IntelligenceID = @IntelligenceID,
                    e.TotalNumberFrom = n.NumberFrom
            FROM tblCompanies_Employees e
            JOIN #NUMBEROFEMPLOYEES n
                ON n.[Year] = e.[Year]
            JOIN Ranked r
                ON r.IDATOM = e.IDATOM
               AND r.[Year] = e.[Year]
            WHERE e.IDATOM = @idatom
              AND n.NumberFrom IS NOT NULL
              AND (r.SourceRank IS NULL OR r.IntelligenceRank IS NULL OR r.Ranking >= @RankingID)
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
