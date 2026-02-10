USE [ADIP]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Cursor Assistant
-- Description: Master orchestrator for entity-resolution merge sections
-- Notes:
--   1) Runs section procedures in a deterministic order.
--   2) "Other" runs last because it updates broad references (including cs_orders).
--   3) Returns step-level execution log at the end.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CompaniesEntityResolutionByRegister_MergeAllSections_MasterScript]
    @RunComments  BIT = 1,
    @RunProfile   BIT = 1,
    @RunDAndS     BIT = 1,
    @RunAddresses BIT = 1,
    @RunOther     BIT = 1,
    @UseTransaction BIT = 1,
    @StopOnError    BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ExecutionLog TABLE
    (
        StepOrder INT NOT NULL,
        StepName NVARCHAR(200) NOT NULL,
        StartedAt DATETIME2(0) NOT NULL,
        EndedAt DATETIME2(0) NULL,
        [Status] NVARCHAR(20) NOT NULL,
        ErrorMessage NVARCHAR(MAX) NULL
    );

    IF @UseTransaction = 1 AND @StopOnError = 0
    BEGIN
        RAISERROR('Invalid parameters: @StopOnError must be 1 when @UseTransaction = 1.', 16, 1);
        RETURN;
    END;

    IF OBJECT_ID(N'dbo.DuplicateCompanies', N'U') IS NULL
    BEGIN
        RAISERROR('Required table dbo.DuplicateCompanies was not found.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.DuplicateCompanies)
    BEGIN
        RAISERROR('No rows found in dbo.DuplicateCompanies. Nothing to process.', 10, 1);
        RETURN;
    END;

    IF @RunComments = 1
       AND OBJECT_ID(N'dbo.sp_CompaniesEntityResolutionByRegister_MergeComments_FinalScript', N'P') IS NULL
    BEGIN
        RAISERROR('Missing procedure: dbo.sp_CompaniesEntityResolutionByRegister_MergeComments_FinalScript', 16, 1);
        RETURN;
    END;

    IF @RunProfile = 1
       AND OBJECT_ID(N'dbo.sp_CompaniesEntityResolutionByRegister_MergeProfileSection_FinalScript', N'P') IS NULL
    BEGIN
        RAISERROR('Missing procedure: dbo.sp_CompaniesEntityResolutionByRegister_MergeProfileSection_FinalScript', 16, 1);
        RETURN;
    END;

    IF @RunDAndS = 1
       AND OBJECT_ID(N'dbo.sp_CompaniesEntityResolutionByRegister_MergeD&SSection_FinalScript', N'P') IS NULL
    BEGIN
        RAISERROR('Missing procedure: dbo.sp_CompaniesEntityResolutionByRegister_MergeD&SSection_FinalScript', 16, 1);
        RETURN;
    END;

    IF @RunAddresses = 1
       AND OBJECT_ID(N'dbo.sp_CompaniesEntityResolutionByRegister_MergeAddresses_FinalScript', N'P') IS NULL
    BEGIN
        RAISERROR('Missing procedure: dbo.sp_CompaniesEntityResolutionByRegister_MergeAddresses_FinalScript', 16, 1);
        RETURN;
    END;

    IF @RunOther = 1
       AND OBJECT_ID(N'dbo.sp_CompaniesEntityResolutionByRegister_MergeOtherSections_FinalScript', N'P') IS NULL
    BEGIN
        RAISERROR('Missing procedure: dbo.sp_CompaniesEntityResolutionByRegister_MergeOtherSections_FinalScript', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        IF @UseTransaction = 1
            BEGIN TRANSACTION;

        IF @RunComments = 1
        BEGIN
            INSERT INTO @ExecutionLog (StepOrder, StepName, StartedAt, [Status])
            VALUES (10, N'Merge Comments', SYSDATETIME(), N'Started');

            BEGIN TRY
                EXEC [dbo].[sp_CompaniesEntityResolutionByRegister_MergeComments_FinalScript];

                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Completed'
                WHERE StepOrder = 10
                  AND EndedAt IS NULL;
            END TRY
            BEGIN CATCH
                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Failed',
                    ErrorMessage = ERROR_MESSAGE()
                WHERE StepOrder = 10
                  AND EndedAt IS NULL;

                IF @UseTransaction = 1 AND XACT_STATE() <> 0
                    ROLLBACK TRANSACTION;

                IF @StopOnError = 1
                    THROW;
            END CATCH;
        END;

        IF @RunProfile = 1
        BEGIN
            INSERT INTO @ExecutionLog (StepOrder, StepName, StartedAt, [Status])
            VALUES (20, N'Merge Profile', SYSDATETIME(), N'Started');

            BEGIN TRY
                EXEC [dbo].[sp_CompaniesEntityResolutionByRegister_MergeProfileSection_FinalScript];

                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Completed'
                WHERE StepOrder = 20
                  AND EndedAt IS NULL;
            END TRY
            BEGIN CATCH
                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Failed',
                    ErrorMessage = ERROR_MESSAGE()
                WHERE StepOrder = 20
                  AND EndedAt IS NULL;

                IF @UseTransaction = 1 AND XACT_STATE() <> 0
                    ROLLBACK TRANSACTION;

                IF @StopOnError = 1
                    THROW;
            END CATCH;
        END;

        IF @RunDAndS = 1
        BEGIN
            INSERT INTO @ExecutionLog (StepOrder, StepName, StartedAt, [Status])
            VALUES (30, N'Merge D&S', SYSDATETIME(), N'Started');

            BEGIN TRY
                EXEC [dbo].[sp_CompaniesEntityResolutionByRegister_MergeD&SSection_FinalScript];

                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Completed'
                WHERE StepOrder = 30
                  AND EndedAt IS NULL;
            END TRY
            BEGIN CATCH
                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Failed',
                    ErrorMessage = ERROR_MESSAGE()
                WHERE StepOrder = 30
                  AND EndedAt IS NULL;

                IF @UseTransaction = 1 AND XACT_STATE() <> 0
                    ROLLBACK TRANSACTION;

                IF @StopOnError = 1
                    THROW;
            END CATCH;
        END;

        IF @RunAddresses = 1
        BEGIN
            INSERT INTO @ExecutionLog (StepOrder, StepName, StartedAt, [Status])
            VALUES (40, N'Merge Addresses', SYSDATETIME(), N'Started');

            BEGIN TRY
                EXEC [dbo].[sp_CompaniesEntityResolutionByRegister_MergeAddresses_FinalScript];

                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Completed'
                WHERE StepOrder = 40
                  AND EndedAt IS NULL;
            END TRY
            BEGIN CATCH
                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Failed',
                    ErrorMessage = ERROR_MESSAGE()
                WHERE StepOrder = 40
                  AND EndedAt IS NULL;

                IF @UseTransaction = 1 AND XACT_STATE() <> 0
                    ROLLBACK TRANSACTION;

                IF @StopOnError = 1
                    THROW;
            END CATCH;
        END;

        IF @RunOther = 1
        BEGIN
            INSERT INTO @ExecutionLog (StepOrder, StepName, StartedAt, [Status])
            VALUES (50, N'Merge Other Sections', SYSDATETIME(), N'Started');

            BEGIN TRY
                EXEC [dbo].[sp_CompaniesEntityResolutionByRegister_MergeOtherSections_FinalScript];

                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Completed'
                WHERE StepOrder = 50
                  AND EndedAt IS NULL;
            END TRY
            BEGIN CATCH
                UPDATE @ExecutionLog
                SET EndedAt = SYSDATETIME(),
                    [Status] = N'Failed',
                    ErrorMessage = ERROR_MESSAGE()
                WHERE StepOrder = 50
                  AND EndedAt IS NULL;

                IF @UseTransaction = 1 AND XACT_STATE() <> 0
                    ROLLBACK TRANSACTION;

                IF @StopOnError = 1
                    THROW;
            END CATCH;
        END;

        IF @UseTransaction = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @UseTransaction = 1 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT
        StepOrder,
        StepName,
        StartedAt,
        EndedAt,
        DATEDIFF(SECOND, StartedAt, EndedAt) AS DurationSeconds,
        [Status],
        ErrorMessage
    FROM @ExecutionLog
    ORDER BY StepOrder;
END
GO
