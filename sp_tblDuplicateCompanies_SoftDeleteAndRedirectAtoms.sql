USE [ADIP]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Cursor Assistant
-- Description: Soft-delete and redirect atoms using dbo.tblDuplicateCompanies
-- Input table: dbo.tblDuplicateCompanies(idatomtodelete, mergedidatom)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_tblDuplicateCompanies_SoftDeleteAndRedirectAtoms]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID(N'dbo.tblDuplicateCompanies', N'U') IS NULL
    BEGIN
        RAISERROR('Table dbo.tblDuplicateCompanies does not exist.', 16, 1);
        RETURN;
    END;

    IF COL_LENGTH(N'dbo.tblDuplicateCompanies', N'idatomtodelete') IS NULL
       OR COL_LENGTH(N'dbo.tblDuplicateCompanies', N'mergedidatom') IS NULL
    BEGIN
        RAISERROR('dbo.tblDuplicateCompanies must contain columns idatomtodelete and mergedidatom.', 16, 1);
        RETURN;
    END;

    IF OBJECT_ID(N'TestCrifis2.dbo.tblAtoms', N'U') IS NULL
    BEGIN
        RAISERROR('Table TestCrifis2.dbo.tblAtoms does not exist.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#InputMap') IS NOT NULL
            DROP TABLE #InputMap;

        ;WITH RawMap AS (
            SELECT
                TRY_CONVERT(INT, idatomtodelete) AS IdatomToDelete,
                TRY_CONVERT(INT, mergedidatom) AS IdatomToKeep
            FROM dbo.tblDuplicateCompanies
        ),
        CleanMap AS (
            SELECT
                IdatomToDelete,
                IdatomToKeep
            FROM RawMap
            WHERE ISNULL(IdatomToDelete, 0) > 0
              AND ISNULL(IdatomToKeep, 0) > 0
              AND IdatomToDelete <> IdatomToKeep
        ),
        DedupedMap AS (
            SELECT
                IdatomToDelete,
                IdatomToKeep,
                ROW_NUMBER() OVER (PARTITION BY IdatomToDelete ORDER BY IdatomToKeep) AS rn
            FROM CleanMap
        )
        SELECT
            IdatomToDelete,
            IdatomToKeep
        INTO #InputMap
        FROM DedupedMap
        WHERE rn = 1;

        IF NOT EXISTS (SELECT 1 FROM #InputMap)
        BEGIN
            RAISERROR('No valid rows found in dbo.tblDuplicateCompanies.', 10, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        CREATE UNIQUE CLUSTERED INDEX IX_InputMap_Delete ON #InputMap (IdatomToDelete);

        IF OBJECT_ID('tempdb..#FinalMap') IS NOT NULL
            DROP TABLE #FinalMap;

        SELECT
            IdatomToDelete,
            IdatomToKeep
        INTO #FinalMap
        FROM #InputMap;

        CREATE UNIQUE CLUSTERED INDEX IX_FinalMap_Delete ON #FinalMap (IdatomToDelete);

        -- Collapse chains so each delete points to the terminal kept atom.
        DECLARE @MapRowsUpdated INT = 1;
        DECLARE @MapPass INT = 0;

        WHILE @MapRowsUpdated > 0 AND @MapPass < 100
        BEGIN
            UPDATE fm
            SET fm.IdatomToKeep = nextFm.IdatomToKeep
            FROM #FinalMap fm
            JOIN #FinalMap nextFm ON nextFm.IdatomToDelete = fm.IdatomToKeep
            WHERE fm.IdatomToKeep <> nextFm.IdatomToKeep;

            SET @MapRowsUpdated = @@ROWCOUNT;
            SET @MapPass += 1;
        END;

        DELETE FROM #FinalMap
        WHERE IdatomToKeep = IdatomToDelete;

        -- EasyNumber normalization:
        -- 1) If kept easy is NULL and deleted easy exists, copy deleted -> kept.
        -- 2) Then deleted easy always follows kept easy.
        ;WITH KeepEasyCandidate AS (
            SELECT
                fm.IdatomToKeep,
                deletedAtom.EasyNumber AS CandidateEasyNumber,
                ROW_NUMBER() OVER (
                    PARTITION BY fm.IdatomToKeep
                    ORDER BY ISNULL(deletedAtom.DateUpdated, '19000101') DESC, fm.IdatomToDelete DESC
                ) AS rn
            FROM #FinalMap fm
            JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = fm.IdatomToKeep
            JOIN TestCrifis2.dbo.tblAtoms deletedAtom ON deletedAtom.IDATOM = fm.IdatomToDelete
            WHERE keptAtom.EasyNumber IS NULL
              AND deletedAtom.EasyNumber IS NOT NULL
        )
        UPDATE keptAtom
        SET keptAtom.EasyNumber = c.CandidateEasyNumber
        FROM TestCrifis2.dbo.tblAtoms keptAtom
        JOIN KeepEasyCandidate c ON c.IdatomToKeep = keptAtom.IDATOM
                               AND c.rn = 1
        WHERE keptAtom.EasyNumber IS NULL;

        DECLARE @DirectDeletedRows INT = 0;
        DECLARE @CascadeRows INT = 0;
        DECLARE @EasyRedirectRows INT = 0;

        -- Direct merged-away atoms.
        UPDATE deletedAtom
        SET
            deletedAtom.IsDeleted = 1,
            deletedAtom.replacedByIdatom = fm.IdatomToKeep,
            deletedAtom.EasyNumber = keptAtom.EasyNumber
        FROM TestCrifis2.dbo.tblAtoms deletedAtom
        JOIN #FinalMap fm ON fm.IdatomToDelete = deletedAtom.IDATOM
        LEFT JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = fm.IdatomToKeep;

        SET @DirectDeletedRows = @@ROWCOUNT;

        -- Cascade previous replacement chains: A->B and now B->C becomes A->C.
        DECLARE @RowsUpdated INT = 1;
        DECLARE @Pass INT = 0;

        WHILE @RowsUpdated > 0 AND @Pass < 100
        BEGIN
            UPDATE previousAtom
            SET
                previousAtom.IsDeleted = 1,
                previousAtom.replacedByIdatom = fm.IdatomToKeep,
                previousAtom.EasyNumber = keptAtom.EasyNumber
            FROM TestCrifis2.dbo.tblAtoms previousAtom
            JOIN #FinalMap fm ON fm.IdatomToDelete = previousAtom.replacedByIdatom
            LEFT JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = fm.IdatomToKeep
            WHERE previousAtom.IDATOM <> fm.IdatomToKeep
              AND (
                    ISNULL(previousAtom.IsDeleted, 0) = 0
                    OR previousAtom.replacedByIdatom <> fm.IdatomToKeep
                    OR (previousAtom.EasyNumber IS NULL AND keptAtom.EasyNumber IS NOT NULL)
                    OR (previousAtom.EasyNumber IS NOT NULL AND keptAtom.EasyNumber IS NULL)
                    OR previousAtom.EasyNumber <> keptAtom.EasyNumber
              );

            SET @RowsUpdated = @@ROWCOUNT;
            SET @CascadeRows += @RowsUpdated;
            SET @Pass += 1;
        END;

        -- Redirect rows whose EasyNumber still points to a deleted atom.
        UPDATE atom
        SET atom.EasyNumber = keptAtom.EasyNumber
        FROM TestCrifis2.dbo.tblAtoms atom
        JOIN #FinalMap fm ON atom.EasyNumber = fm.IdatomToDelete
        LEFT JOIN TestCrifis2.dbo.tblAtoms keptAtom ON keptAtom.IDATOM = fm.IdatomToKeep
        WHERE atom.IDATOM <> fm.IdatomToKeep
          AND (
                (atom.EasyNumber IS NULL AND keptAtom.EasyNumber IS NOT NULL)
                OR (atom.EasyNumber IS NOT NULL AND keptAtom.EasyNumber IS NULL)
                OR atom.EasyNumber <> keptAtom.EasyNumber
          );

        SET @EasyRedirectRows = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            (SELECT COUNT(1) FROM #FinalMap) AS MergePairs,
            @DirectDeletedRows AS DirectDeletedRows,
            @CascadeRows AS CascadeRedirectRows,
            @EasyRedirectRows AS EasyNumberRedirectRows;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Example:
-- EXEC [dbo].[sp_tblDuplicateCompanies_SoftDeleteAndRedirectAtoms];
