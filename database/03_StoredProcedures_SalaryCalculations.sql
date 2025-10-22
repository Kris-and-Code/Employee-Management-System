-- =============================================
-- Salary Calculations and Bonus Computations
-- Demonstrates advanced T-SQL features including:
-- - Complex calculations with CTEs
-- - Window functions for ranking and aggregations
-- - Recursive CTEs for hierarchical calculations
-- - Mathematical functions and business logic
-- - Performance optimization with indexed views
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Calculate Employee Bonus Based on Performance
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CalculateEmployeeBonus]
    @EmployeeID INT,
    @ReviewYear INT = NULL,
    @BonusPercentage DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @ReviewYear IS NULL
        SET @ReviewYear = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to get employee performance data
        WITH EmployeePerformance AS (
            SELECT 
                e.EmployeeID,
                e.FirstName,
                e.LastName,
                e.FullName,
                e.Salary,
                e.YearsOfService,
                e.DepartmentID,
                d.DepartmentName,
                -- Get latest performance review for the year
                pr.OverallRating,
                pr.TechnicalSkills,
                pr.Communication,
                pr.Teamwork,
                pr.Leadership,
                pr.ReviewDate,
                -- Calculate average rating
                (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS AverageRating,
                -- Calculate bonus percentage based on performance
                CASE 
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 4.5 THEN 15.0
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 4.0 THEN 12.0
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 3.5 THEN 8.0
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 3.0 THEN 5.0
                    ELSE 0.0
                END AS CalculatedBonusPercentage,
                -- Years of service bonus
                CASE 
                    WHEN e.YearsOfService >= 10 THEN 2.0
                    WHEN e.YearsOfService >= 5 THEN 1.5
                    WHEN e.YearsOfService >= 2 THEN 1.0
                    ELSE 0.0
                END AS ServiceBonusPercentage
            FROM Employees e
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID 
                AND YEAR(pr.ReviewDate) = @ReviewYear
            WHERE e.EmployeeID = @EmployeeID AND e.IsActive = 1
        ),
        BonusCalculation AS (
            SELECT 
                *,
                -- Use provided percentage or calculated percentage
                ISNULL(@BonusPercentage, CalculatedBonusPercentage) AS FinalBonusPercentage,
                -- Calculate total bonus percentage including service bonus
                ISNULL(@BonusPercentage, CalculatedBonusPercentage) + ServiceBonusPercentage AS TotalBonusPercentage,
                -- Calculate bonus amount
                e.Salary * (ISNULL(@BonusPercentage, CalculatedBonusPercentage) + ServiceBonusPercentage) / 100.0 AS BonusAmount,
                -- Calculate total compensation
                e.Salary + (e.Salary * (ISNULL(@BonusPercentage, CalculatedBonusPercentage) + ServiceBonusPercentage) / 100.0) AS TotalCompensation
            FROM EmployeePerformance e
        )
        SELECT 
            EmployeeID,
            FirstName,
            LastName,
            FullName,
            Salary,
            YearsOfService,
            DepartmentName,
            OverallRating,
            TechnicalSkills,
            Communication,
            Teamwork,
            Leadership,
            AverageRating,
            CalculatedBonusPercentage,
            ServiceBonusPercentage,
            FinalBonusPercentage,
            TotalBonusPercentage,
            BonusAmount,
            TotalCompensation,
            ReviewDate,
            @ReviewYear AS ReviewYear
        FROM BonusCalculation;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 2. Calculate Department Salary Budget and Variance
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CalculateDepartmentSalaryBudget]
    @DepartmentID INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to calculate comprehensive salary metrics
        WITH DepartmentSalaryMetrics AS (
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                d.Budget,
                COUNT(e.EmployeeID) AS EmployeeCount,
                SUM(e.Salary) AS TotalSalary,
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                MIN(e.Salary) AS MinSalary,
                MAX(e.Salary) AS MaxSalary,
                STDEV(CAST(e.Salary AS FLOAT)) AS SalaryStandardDeviation,
                -- Calculate salary variance from budget
                CASE 
                    WHEN d.Budget IS NOT NULL THEN d.Budget - SUM(e.Salary)
                    ELSE NULL
                END AS BudgetVariance,
                -- Calculate budget utilization percentage
                CASE 
                    WHEN d.Budget IS NOT NULL AND d.Budget > 0 THEN (SUM(e.Salary) / d.Budget) * 100.0
                    ELSE NULL
                END AS BudgetUtilizationPercentage,
                -- Calculate salary distribution percentiles
                PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS Salary25thPercentile,
                PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS Salary50thPercentile,
                PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS Salary75thPercentile,
                PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS Salary90thPercentile
            FROM Departments d
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
            WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY d.DepartmentID, d.DepartmentName, d.Budget
        ),
        SalaryTrends AS (
            SELECT 
                d.DepartmentID,
                -- Calculate year-over-year salary growth
                AVG(CASE WHEN YEAR(sh.ChangeDate) = @Year THEN sh.NewSalary - ISNULL(sh.OldSalary, 0) END) AS AvgSalaryIncrease,
                COUNT(CASE WHEN YEAR(sh.ChangeDate) = @Year THEN 1 END) AS SalaryChangesThisYear,
                -- Calculate average salary increase percentage
                AVG(CASE 
                    WHEN YEAR(sh.ChangeDate) = @Year AND sh.OldSalary > 0 
                    THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
                END) AS AvgSalaryIncreasePercentage
            FROM Departments d
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
            LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
            WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY d.DepartmentID
        )
        SELECT 
            dsm.DepartmentID,
            dsm.DepartmentName,
            dsm.Budget,
            dsm.EmployeeCount,
            dsm.TotalSalary,
            dsm.AverageSalary,
            dsm.MinSalary,
            dsm.MaxSalary,
            dsm.SalaryStandardDeviation,
            dsm.BudgetVariance,
            dsm.BudgetUtilizationPercentage,
            dsm.Salary25thPercentile,
            dsm.Salary50thPercentile,
            dsm.Salary75thPercentile,
            dsm.Salary90thPercentile,
            st.AvgSalaryIncrease,
            st.SalaryChangesThisYear,
            st.AvgSalaryIncreasePercentage,
            @Year AS AnalysisYear,
            -- Calculate budget status
            CASE 
                WHEN dsm.BudgetVariance > 0 THEN 'Under Budget'
                WHEN dsm.BudgetVariance < 0 THEN 'Over Budget'
                WHEN dsm.BudgetVariance = 0 THEN 'On Budget'
                ELSE 'No Budget Set'
            END AS BudgetStatus,
            -- Calculate salary competitiveness
            CASE 
                WHEN dsm.AverageSalary > dsm.Salary75thPercentile THEN 'Above Market'
                WHEN dsm.AverageSalary < dsm.Salary25thPercentile THEN 'Below Market'
                ELSE 'Market Rate'
            END AS SalaryCompetitiveness
        FROM DepartmentSalaryMetrics dsm
        LEFT JOIN SalaryTrends st ON dsm.DepartmentID = st.DepartmentID
        ORDER BY dsm.TotalSalary DESC;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 3. Calculate Salary Adjustments Based on Market Data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CalculateSalaryAdjustments]
    @DepartmentID INT = NULL,
    @AdjustmentPercentage DECIMAL(5,2) = NULL,
    @MinAdjustmentAmount DECIMAL(18,2) = 1000.00,
    @MaxAdjustmentAmount DECIMAL(18,2) = 10000.00
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Use CTE to calculate market-based salary adjustments
        WITH MarketAnalysis AS (
            SELECT 
                e.EmployeeID,
                e.FirstName,
                e.LastName,
                e.FullName,
                e.Salary,
                e.YearsOfService,
                e.DepartmentID,
                d.DepartmentName,
                e.JobTitle,
                -- Calculate market position based on department average
                e.Salary - AVG(e.Salary) OVER (PARTITION BY e.DepartmentID) AS SalaryVsDepartmentAvg,
                -- Calculate market position based on years of service
                e.Salary - AVG(e.Salary) OVER (PARTITION BY e.DepartmentID, 
                    CASE 
                        WHEN e.YearsOfService < 2 THEN 'Entry'
                        WHEN e.YearsOfService < 5 THEN 'Mid'
                        WHEN e.YearsOfService < 10 THEN 'Senior'
                        ELSE 'Executive'
                    END) AS SalaryVsExperienceAvg,
                -- Get latest performance rating
                pr.OverallRating,
                -- Calculate adjustment factors
                CASE 
                    WHEN pr.OverallRating >= 4.5 THEN 1.2  -- High performer
                    WHEN pr.OverallRating >= 4.0 THEN 1.1  -- Above average
                    WHEN pr.OverallRating >= 3.5 THEN 1.0  -- Average
                    WHEN pr.OverallRating >= 3.0 THEN 0.9  -- Below average
                    ELSE 0.8  -- Poor performer
                END AS PerformanceFactor,
                -- Calculate market adjustment percentage
                CASE 
                    WHEN e.Salary < AVG(e.Salary) OVER (PARTITION BY e.DepartmentID) * 0.8 THEN 8.0  -- Significantly underpaid
                    WHEN e.Salary < AVG(e.Salary) OVER (PARTITION BY e.DepartmentID) * 0.9 THEN 5.0  -- Underpaid
                    WHEN e.Salary > AVG(e.Salary) OVER (PARTITION BY e.DepartmentID) * 1.2 THEN -2.0  -- Overpaid
                    ELSE 3.0  -- Market rate adjustment
                END AS MarketAdjustmentPercentage
            FROM Employees e
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID 
                AND pr.ReviewDate = (
                    SELECT MAX(ReviewDate) 
                    FROM PerformanceReviews pr2 
                    WHERE pr2.EmployeeID = e.EmployeeID
                )
            WHERE e.IsActive = 1 
                AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
        ),
        AdjustmentCalculation AS (
            SELECT 
                *,
                -- Calculate final adjustment percentage
                CASE 
                    WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                    ELSE MarketAdjustmentPercentage * PerformanceFactor
                END AS FinalAdjustmentPercentage,
                -- Calculate adjustment amount
                Salary * (
                    CASE 
                        WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                        ELSE MarketAdjustmentPercentage * PerformanceFactor
                    END
                ) / 100.0 AS AdjustmentAmount,
                -- Apply min/max constraints
                CASE 
                    WHEN Salary * (
                        CASE 
                            WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                            ELSE MarketAdjustmentPercentage * PerformanceFactor
                        END
                    ) / 100.0 < @MinAdjustmentAmount THEN @MinAdjustmentAmount
                    WHEN Salary * (
                        CASE 
                            WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                            ELSE MarketAdjustmentPercentage * PerformanceFactor
                        END
                    ) / 100.0 > @MaxAdjustmentAmount THEN @MaxAdjustmentAmount
                    ELSE Salary * (
                        CASE 
                            WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                            ELSE MarketAdjustmentPercentage * PerformanceFactor
                        END
                    ) / 100.0
                END AS ConstrainedAdjustmentAmount,
                -- Calculate new salary
                Salary + CASE 
                    WHEN Salary * (
                        CASE 
                            WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                            ELSE MarketAdjustmentPercentage * PerformanceFactor
                        END
                    ) / 100.0 < @MinAdjustmentAmount THEN @MinAdjustmentAmount
                    WHEN Salary * (
                        CASE 
                            WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                            ELSE MarketAdjustmentPercentage * PerformanceFactor
                        END
                    ) / 100.0 > @MaxAdjustmentAmount THEN @MaxAdjustmentAmount
                    ELSE Salary * (
                        CASE 
                            WHEN @AdjustmentPercentage IS NOT NULL THEN @AdjustmentPercentage
                            ELSE MarketAdjustmentPercentage * PerformanceFactor
                        END
                    ) / 100.0
                END AS NewSalary
            FROM MarketAnalysis
        )
        SELECT 
            EmployeeID,
            FirstName,
            LastName,
            FullName,
            Salary AS CurrentSalary,
            YearsOfService,
            DepartmentName,
            JobTitle,
            OverallRating,
            SalaryVsDepartmentAvg,
            SalaryVsExperienceAvg,
            PerformanceFactor,
            MarketAdjustmentPercentage,
            FinalAdjustmentPercentage,
            AdjustmentAmount,
            ConstrainedAdjustmentAmount AS FinalAdjustmentAmount,
            NewSalary,
            -- Calculate percentage increase
            (ConstrainedAdjustmentAmount / Salary) * 100.0 AS ActualAdjustmentPercentage,
            -- Priority for adjustments (higher priority = more urgent)
            CASE 
                WHEN SalaryVsDepartmentAvg < -10000 AND OverallRating >= 4.0 THEN 'High'
                WHEN SalaryVsDepartmentAvg < -5000 AND OverallRating >= 3.5 THEN 'Medium'
                WHEN SalaryVsDepartmentAvg < 0 AND OverallRating >= 4.0 THEN 'Medium'
                ELSE 'Low'
            END AS AdjustmentPriority
        FROM AdjustmentCalculation
        WHERE ConstrainedAdjustmentAmount > 0  -- Only show positive adjustments
        ORDER BY AdjustmentPriority DESC, ConstrainedAdjustmentAmount DESC;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 4. Calculate Compensation Analytics Dashboard
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetCompensationAnalytics]
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use multiple CTEs for comprehensive analytics
        WITH CompensationSummary AS (
            SELECT 
                COUNT(*) AS TotalEmployees,
                SUM(Salary) AS TotalPayroll,
                AVG(CAST(Salary AS FLOAT)) AS AverageSalary,
                MIN(Salary) AS MinSalary,
                MAX(Salary) AS MaxSalary,
                STDEV(CAST(Salary AS FLOAT)) AS SalaryStandardDeviation,
                -- Calculate salary ranges
                COUNT(CASE WHEN Salary < 50000 THEN 1 END) AS Under50K,
                COUNT(CASE WHEN Salary BETWEEN 50000 AND 75000 THEN 1 END) AS Salary50KTo75K,
                COUNT(CASE WHEN Salary BETWEEN 75000 AND 100000 THEN 1 END) AS Salary75KTo100K,
                COUNT(CASE WHEN Salary BETWEEN 100000 AND 150000 THEN 1 END) AS Salary100KTo150K,
                COUNT(CASE WHEN Salary > 150000 THEN 1 END) AS Over150K
            FROM Employees
            WHERE IsActive = 1
        ),
        DepartmentCompensation AS (
            SELECT 
                d.DepartmentName,
                COUNT(e.EmployeeID) AS EmployeeCount,
                SUM(e.Salary) AS TotalSalary,
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                MIN(e.Salary) AS MinSalary,
                MAX(e.Salary) AS MaxSalary,
                -- Calculate salary growth
                AVG(CASE 
                    WHEN YEAR(sh.ChangeDate) = @Year AND sh.OldSalary > 0 
                    THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
                END) AS AvgSalaryGrowthPercentage
            FROM Departments d
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
            LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
            GROUP BY d.DepartmentID, d.DepartmentName
        ),
        PerformanceCompensation AS (
            SELECT 
                pr.OverallRating,
                COUNT(e.EmployeeID) AS EmployeeCount,
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                AVG(CAST(e.YearsOfService AS FLOAT)) AS AverageYearsOfService,
                -- Calculate bonus potential
                AVG(CASE 
                    WHEN pr.OverallRating >= 4.5 THEN e.Salary * 0.15
                    WHEN pr.OverallRating >= 4.0 THEN e.Salary * 0.12
                    WHEN pr.OverallRating >= 3.5 THEN e.Salary * 0.08
                    WHEN pr.OverallRating >= 3.0 THEN e.Salary * 0.05
                    ELSE 0
                END) AS AveragePotentialBonus
            FROM Employees e
            INNER JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            WHERE e.IsActive = 1 
                AND YEAR(pr.ReviewDate) = @Year
            GROUP BY pr.OverallRating
        ),
        SalaryTrends AS (
            SELECT 
                YEAR(sh.ChangeDate) AS ChangeYear,
                COUNT(*) AS SalaryChanges,
                AVG(CAST(sh.NewSalary - ISNULL(sh.OldSalary, 0) AS FLOAT)) AS AvgSalaryIncrease,
                AVG(CASE 
                    WHEN sh.OldSalary > 0 
                    THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
                END) AS AvgSalaryIncreasePercentage
            FROM SalaryHistory sh
            WHERE YEAR(sh.ChangeDate) >= @Year - 2
            GROUP BY YEAR(sh.ChangeDate)
        )
        -- Return comprehensive analytics
        SELECT 
            'Summary' AS Category,
            TotalEmployees,
            TotalPayroll,
            AverageSalary,
            MinSalary,
            MaxSalary,
            SalaryStandardDeviation,
            Under50K,
            Salary50KTo75K,
            Salary75KTo100K,
            Salary100KTo150K,
            Over150K,
            NULL AS DepartmentName,
            NULL AS EmployeeCount,
            NULL AS TotalSalary,
            NULL AS AvgSalaryGrowthPercentage,
            NULL AS OverallRating,
            NULL AS AverageYearsOfService,
            NULL AS AveragePotentialBonus,
            NULL AS ChangeYear,
            NULL AS SalaryChanges,
            NULL AS AvgSalaryIncrease,
            NULL AS AvgSalaryIncreasePercentage
        FROM CompensationSummary
        
        UNION ALL
        
        SELECT 
            'Department' AS Category,
            NULL AS TotalEmployees,
            NULL AS TotalPayroll,
            NULL AS AverageSalary,
            NULL AS MinSalary,
            NULL AS MaxSalary,
            NULL AS SalaryStandardDeviation,
            NULL AS Under50K,
            NULL AS Salary50KTo75K,
            NULL AS Salary75KTo100K,
            NULL AS Salary100KTo150K,
            NULL AS Over150K,
            DepartmentName,
            EmployeeCount,
            TotalSalary,
            AvgSalaryGrowthPercentage,
            NULL AS OverallRating,
            NULL AS AverageYearsOfService,
            NULL AS AveragePotentialBonus,
            NULL AS ChangeYear,
            NULL AS SalaryChanges,
            NULL AS AvgSalaryIncrease,
            NULL AS AvgSalaryIncreasePercentage
        FROM DepartmentCompensation
        
        UNION ALL
        
        SELECT 
            'Performance' AS Category,
            NULL AS TotalEmployees,
            NULL AS TotalPayroll,
            NULL AS AverageSalary,
            NULL AS MinSalary,
            NULL AS MaxSalary,
            NULL AS SalaryStandardDeviation,
            NULL AS Under50K,
            NULL AS Salary50KTo75K,
            NULL AS Salary75KTo100K,
            NULL AS Salary100KTo150K,
            NULL AS Over150K,
            NULL AS DepartmentName,
            EmployeeCount,
            NULL AS TotalSalary,
            NULL AS AvgSalaryGrowthPercentage,
            OverallRating,
            AverageYearsOfService,
            AveragePotentialBonus,
            NULL AS ChangeYear,
            NULL AS SalaryChanges,
            NULL AS AvgSalaryIncrease,
            NULL AS AvgSalaryIncreasePercentage
        FROM PerformanceCompensation
        
        UNION ALL
        
        SELECT 
            'Trends' AS Category,
            NULL AS TotalEmployees,
            NULL AS TotalPayroll,
            NULL AS AverageSalary,
            NULL AS MinSalary,
            NULL AS MaxSalary,
            NULL AS SalaryStandardDeviation,
            NULL AS Under50K,
            NULL AS Salary50KTo75K,
            NULL AS Salary75KTo100K,
            NULL AS Salary100KTo150K,
            NULL AS Over150K,
            NULL AS DepartmentName,
            NULL AS EmployeeCount,
            NULL AS TotalSalary,
            NULL AS AvgSalaryGrowthPercentage,
            NULL AS OverallRating,
            NULL AS AverageYearsOfService,
            NULL AS AveragePotentialBonus,
            ChangeYear,
            SalaryChanges,
            AvgSalaryIncrease,
            AvgSalaryIncreasePercentage
        FROM SalaryTrends
        ORDER BY Category, DepartmentName, OverallRating, ChangeYear;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 5. Apply Salary Adjustments (Batch Update)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_ApplySalaryAdjustments]
    @AdjustmentData NVARCHAR(MAX), -- JSON format: [{"EmployeeID": 1, "NewSalary": 75000, "Reason": "Performance"}, ...]
    @ApprovedBy NVARCHAR(100) = 'System',
    @EffectiveDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current date if not specified
    IF @EffectiveDate IS NULL
        SET @EffectiveDate = CAST(GETDATE() AS DATE);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Create temporary table to hold adjustment data
        CREATE TABLE #SalaryAdjustments (
            EmployeeID INT,
            NewSalary DECIMAL(18,2),
            Reason NVARCHAR(200)
        );
        
        -- Parse JSON data (SQL Server 2016+)
        INSERT INTO #SalaryAdjustments (EmployeeID, NewSalary, Reason)
        SELECT 
            JSON_VALUE(value, '$.EmployeeID') AS EmployeeID,
            CAST(JSON_VALUE(value, '$.NewSalary') AS DECIMAL(18,2)) AS NewSalary,
            JSON_VALUE(value, '$.Reason') AS Reason
        FROM OPENJSON(@AdjustmentData);
        
        -- Validate all employees exist and are active
        IF EXISTS (
            SELECT 1 FROM #SalaryAdjustments sa
            LEFT JOIN Employees e ON sa.EmployeeID = e.EmployeeID
            WHERE e.EmployeeID IS NULL OR e.IsActive = 0
        )
        BEGIN
            RAISERROR('One or more employees do not exist or are inactive', 16, 1);
            RETURN;
        END
        
        -- Apply salary adjustments
        DECLARE @ProcessedCount INT = 0;
        
        DECLARE adjustment_cursor CURSOR FOR
        SELECT EmployeeID, NewSalary, Reason FROM #SalaryAdjustments;
        
        DECLARE @EmployeeID INT, @NewSalary DECIMAL(18,2), @Reason NVARCHAR(200);
        
        OPEN adjustment_cursor;
        FETCH NEXT FROM adjustment_cursor INTO @EmployeeID, @NewSalary, @Reason;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Get current salary
            DECLARE @OldSalary DECIMAL(18,2);
            SELECT @OldSalary = Salary FROM Employees WHERE EmployeeID = @EmployeeID;
            
            -- Update employee salary
            UPDATE Employees 
            SET Salary = @NewSalary, ModifiedDate = GETDATE()
            WHERE EmployeeID = @EmployeeID;
            
            -- Insert salary history
            INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
            VALUES (@EmployeeID, @OldSalary, @NewSalary, @EffectiveDate, @Reason, @ApprovedBy);
            
            -- Log audit
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @EmployeeID, 'UPDATE', 
                    CONCAT('Salary: ', @OldSalary), 
                    CONCAT('Salary: ', @NewSalary, ' - Reason: ', @Reason), 
                    @ApprovedBy);
            
            SET @ProcessedCount = @ProcessedCount + 1;
            
            FETCH NEXT FROM adjustment_cursor INTO @EmployeeID, @NewSalary, @Reason;
        END
        
        CLOSE adjustment_cursor;
        DEALLOCATE adjustment_cursor;
        
        DROP TABLE #SalaryAdjustments;
        
        COMMIT TRANSACTION;
        
        SELECT 
            @ProcessedCount AS ProcessedAdjustments,
            @EffectiveDate AS EffectiveDate,
            'Salary adjustments applied successfully' AS Result;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        IF OBJECT_ID('tempdb..#SalaryAdjustments') IS NOT NULL
            DROP TABLE #SalaryAdjustments;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

PRINT 'Salary calculation and bonus computation stored procedures created successfully!';
PRINT 'Procedures created: sp_CalculateEmployeeBonus, sp_CalculateDepartmentSalaryBudget, sp_CalculateSalaryAdjustments, sp_GetCompensationAnalytics, sp_ApplySalaryAdjustments';
PRINT 'Features demonstrated: Complex CTEs, Window Functions, Mathematical Calculations, JSON Processing, Cursors, Batch Operations';
