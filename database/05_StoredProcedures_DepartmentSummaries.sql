-- =============================================
-- Department Summaries and Management
-- Demonstrates advanced T-SQL features including:
-- - Hierarchical queries with recursive CTEs
-- - Complex aggregations and window functions
-- - Department hierarchy management
-- - Budget and resource allocation analysis
-- - Department performance metrics
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Get Department Hierarchy
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetDepartmentHierarchy]
    @RootDepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Use recursive CTE to build department hierarchy
        WITH DepartmentHierarchy AS (
            -- Base case: root departments or specified department
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                d.DepartmentHead,
                dh.FullName AS DepartmentHeadName,
                d.Budget,
                d.Location,
                d.CreatedDate,
                d.ModifiedDate,
                0 AS HierarchyLevel,
                CAST(d.DepartmentName AS NVARCHAR(MAX)) AS HierarchyPath,
                CAST(d.DepartmentID AS NVARCHAR(MAX)) AS HierarchyPathIDs,
                -- Count direct employees
                COUNT(e.EmployeeID) AS DirectEmployeeCount,
                -- Calculate department metrics
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                SUM(e.Salary) AS TotalSalaryBudget,
                COUNT(CASE WHEN e.IsActive = 1 THEN 1 END) AS ActiveEmployeeCount,
                COUNT(CASE WHEN e.IsActive = 0 THEN 1 END) AS InactiveEmployeeCount
            FROM Departments d
            LEFT JOIN Employees dh ON d.DepartmentHead = dh.EmployeeID
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID
            WHERE (@RootDepartmentID IS NULL OR d.DepartmentID = @RootDepartmentID)
            GROUP BY d.DepartmentID, d.DepartmentName, d.DepartmentHead, dh.FullName, d.Budget, d.Location, d.CreatedDate, d.ModifiedDate
            
            UNION ALL
            
            -- Recursive case: sub-departments (if we had a parent-child relationship)
            -- For now, we'll show all departments as flat structure
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                d.DepartmentHead,
                dh.FullName AS DepartmentHeadName,
                d.Budget,
                d.Location,
                d.CreatedDate,
                d.ModifiedDate,
                dh.HierarchyLevel + 1,
                CAST(dh.HierarchyPath + ' > ' + d.DepartmentName AS NVARCHAR(MAX)),
                CAST(dh.HierarchyPathIDs + ',' + CAST(d.DepartmentID AS NVARCHAR) AS NVARCHAR(MAX)),
                COUNT(e.EmployeeID) AS DirectEmployeeCount,
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                SUM(e.Salary) AS TotalSalaryBudget,
                COUNT(CASE WHEN e.IsActive = 1 THEN 1 END) AS ActiveEmployeeCount,
                COUNT(CASE WHEN e.IsActive = 0 THEN 1 END) AS InactiveEmployeeCount
            FROM Departments d
            LEFT JOIN Employees dh ON d.DepartmentHead = dh.EmployeeID
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID
            INNER JOIN DepartmentHierarchy dh ON d.DepartmentID != dh.DepartmentID  -- Prevent infinite recursion
            GROUP BY d.DepartmentID, d.DepartmentName, d.DepartmentHead, dh.FullName, d.Budget, d.Location, d.CreatedDate, d.ModifiedDate, dh.HierarchyLevel, dh.HierarchyPath, dh.HierarchyPathIDs
        ),
        DepartmentMetrics AS (
            SELECT 
                dh.*,
                -- Calculate budget utilization
                CASE 
                    WHEN dh.Budget IS NOT NULL AND dh.Budget > 0 
                    THEN (dh.TotalSalaryBudget / dh.Budget) * 100.0
                    ELSE NULL
                END AS BudgetUtilizationPercentage,
                -- Calculate budget variance
                CASE 
                    WHEN dh.Budget IS NOT NULL 
                    THEN dh.Budget - dh.TotalSalaryBudget
                    ELSE NULL
                END AS BudgetVariance,
                -- Calculate employee metrics
                CASE 
                    WHEN dh.DirectEmployeeCount > 0 
                    THEN (CAST(dh.ActiveEmployeeCount AS FLOAT) / dh.DirectEmployeeCount) * 100.0
                    ELSE 0
                END AS ActiveEmployeePercentage,
                -- Calculate salary metrics
                CASE 
                    WHEN dh.DirectEmployeeCount > 0 
                    THEN dh.TotalSalaryBudget / dh.DirectEmployeeCount
                    ELSE 0
                END AS SalaryPerEmployee,
                -- Get department performance metrics
                AVG(CAST(pr.OverallRating AS FLOAT)) AS AveragePerformanceRating,
                COUNT(pr.ReviewID) AS TotalPerformanceReviews,
                COUNT(CASE WHEN pr.OverallRating >= 4.0 THEN 1 END) AS HighPerformanceReviews,
                COUNT(CASE WHEN pr.OverallRating < 3.0 THEN 1 END) AS LowPerformanceReviews
            FROM DepartmentHierarchy dh
            LEFT JOIN Employees e ON dh.DepartmentID = e.DepartmentID
            LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            GROUP BY dh.DepartmentID, dh.DepartmentName, dh.DepartmentHead, dh.DepartmentHeadName, dh.Budget, dh.Location, dh.CreatedDate, dh.ModifiedDate, dh.HierarchyLevel, dh.HierarchyPath, dh.HierarchyPathIDs, dh.DirectEmployeeCount, dh.AverageSalary, dh.TotalSalaryBudget, dh.ActiveEmployeeCount, dh.InactiveEmployeeCount
        )
        SELECT 
            DepartmentID,
            DepartmentName,
            DepartmentHead,
            DepartmentHeadName,
            Budget,
            Location,
            CreatedDate,
            ModifiedDate,
            HierarchyLevel,
            HierarchyPath,
            HierarchyPathIDs,
            DirectEmployeeCount,
            AverageSalary,
            TotalSalaryBudget,
            ActiveEmployeeCount,
            InactiveEmployeeCount,
            BudgetUtilizationPercentage,
            BudgetVariance,
            ActiveEmployeePercentage,
            SalaryPerEmployee,
            AveragePerformanceRating,
            TotalPerformanceReviews,
            HighPerformanceReviews,
            LowPerformanceReviews,
            -- Calculate performance percentage
            CASE 
                WHEN TotalPerformanceReviews > 0 
                THEN (CAST(HighPerformanceReviews AS FLOAT) / TotalPerformanceReviews) * 100.0
                ELSE 0
            END AS HighPerformancePercentage,
            CASE 
                WHEN TotalPerformanceReviews > 0 
                THEN (CAST(LowPerformanceReviews AS FLOAT) / TotalPerformanceReviews) * 100.0
                ELSE 0
            END AS LowPerformancePercentage,
            -- Calculate department health score
            CASE 
                WHEN BudgetUtilizationPercentage IS NOT NULL AND BudgetUtilizationPercentage <= 100 
                THEN 
                    CASE 
                        WHEN AveragePerformanceRating >= 4.0 AND ActiveEmployeePercentage >= 90 THEN 'Excellent'
                        WHEN AveragePerformanceRating >= 3.5 AND ActiveEmployeePercentage >= 80 THEN 'Good'
                        WHEN AveragePerformanceRating >= 3.0 AND ActiveEmployeePercentage >= 70 THEN 'Fair'
                        ELSE 'Needs Attention'
                    END
                ELSE 'Budget Overrun'
            END AS DepartmentHealthStatus
        FROM DepartmentMetrics
        ORDER BY HierarchyLevel, DepartmentName;
        
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
-- 2. Get Department Summary Dashboard
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetDepartmentSummaryDashboard]
    @DepartmentID INT = NULL,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Use CTE to calculate comprehensive department summaries
        WITH DepartmentSummary AS (
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                d.DepartmentHead,
                dh.FullName AS DepartmentHeadName,
                d.Budget,
                d.Location,
                d.CreatedDate,
                d.ModifiedDate,
                -- Employee counts
                COUNT(e.EmployeeID) AS TotalEmployees,
                COUNT(CASE WHEN e.IsActive = 1 THEN 1 END) AS ActiveEmployees,
                COUNT(CASE WHEN e.IsActive = 0 THEN 1 END) AS InactiveEmployees,
                COUNT(CASE WHEN e.ManagerID IS NULL THEN 1 END) AS TopLevelEmployees,
                COUNT(CASE WHEN e.ManagerID IS NOT NULL THEN 1 END) AS ManagedEmployees,
                -- Salary metrics
                SUM(e.Salary) AS TotalSalaryBudget,
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                MIN(e.Salary) AS MinSalary,
                MAX(e.Salary) AS MaxSalary,
                STDEV(CAST(e.Salary AS FLOAT)) AS SalaryStandardDeviation,
                -- Experience metrics
                AVG(CAST(e.YearsOfService AS FLOAT)) AS AverageYearsOfService,
                MIN(e.YearsOfService) AS MinYearsOfService,
                MAX(e.YearsOfService) AS MaxYearsOfService,
                COUNT(CASE WHEN e.YearsOfService < 2 THEN 1 END) AS JuniorEmployees,
                COUNT(CASE WHEN e.YearsOfService BETWEEN 2 AND 5 THEN 1 END) AS MidLevelEmployees,
                COUNT(CASE WHEN e.YearsOfService > 5 THEN 1 END) AS SeniorEmployees,
                -- Project metrics
                COUNT(DISTINCT p.ProjectID) AS TotalProjects,
                COUNT(CASE WHEN p.Status = 'Active' THEN 1 END) AS ActiveProjects,
                COUNT(CASE WHEN p.Status = 'Completed' THEN 1 END) AS CompletedProjects,
                COUNT(CASE WHEN p.Status = 'Planning' THEN 1 END) AS PlanningProjects,
                -- Performance metrics
                COUNT(DISTINCT pr.ReviewID) AS TotalPerformanceReviews,
                AVG(CAST(pr.OverallRating AS FLOAT)) AS AveragePerformanceRating,
                COUNT(CASE WHEN pr.OverallRating >= 4.0 THEN 1 END) AS HighPerformanceReviews,
                COUNT(CASE WHEN pr.OverallRating < 3.0 THEN 1 END) AS LowPerformanceReviews,
                -- Salary history metrics
                COUNT(DISTINCT sh.SalaryHistoryID) AS TotalSalaryChanges,
                AVG(CASE 
                    WHEN YEAR(sh.ChangeDate) = YEAR(GETDATE()) AND sh.OldSalary > 0 
                    THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
                END) AS AverageSalaryIncreasePercentage
            FROM Departments d
            LEFT JOIN Employees dh ON d.DepartmentHead = dh.EmployeeID
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND (@IncludeInactive = 1 OR e.IsActive = 1)
            LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
            LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
            WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY d.DepartmentID, d.DepartmentName, d.DepartmentHead, dh.FullName, d.Budget, d.Location, d.CreatedDate, d.ModifiedDate
        ),
        DepartmentRankings AS (
            SELECT 
                *,
                -- Budget utilization
                CASE 
                    WHEN Budget IS NOT NULL AND Budget > 0 
                    THEN (TotalSalaryBudget / Budget) * 100.0
                    ELSE NULL
                END AS BudgetUtilizationPercentage,
                -- Budget variance
                CASE 
                    WHEN Budget IS NOT NULL 
                    THEN Budget - TotalSalaryBudget
                    ELSE NULL
                END AS BudgetVariance,
                -- Performance percentage
                CASE 
                    WHEN TotalPerformanceReviews > 0 
                    THEN (CAST(HighPerformanceReviews AS FLOAT) / TotalPerformanceReviews) * 100.0
                    ELSE 0
                END AS HighPerformancePercentage,
                CASE 
                    WHEN TotalPerformanceReviews > 0 
                    THEN (CAST(LowPerformanceReviews AS FLOAT) / TotalPerformanceReviews) * 100.0
                    ELSE 0
                END AS LowPerformancePercentage,
                -- Rankings using window functions
                ROW_NUMBER() OVER (ORDER BY AverageSalary DESC) AS SalaryRank,
                ROW_NUMBER() OVER (ORDER BY AveragePerformanceRating DESC) AS PerformanceRank,
                ROW_NUMBER() OVER (ORDER BY TotalSalaryBudget DESC) AS BudgetRank,
                ROW_NUMBER() OVER (ORDER BY TotalEmployees DESC) AS SizeRank,
                RANK() OVER (ORDER BY AverageSalary DESC) AS SalaryRankByRank,
                RANK() OVER (ORDER BY AveragePerformanceRating DESC) AS PerformanceRankByRank,
                PERCENT_RANK() OVER (ORDER BY AverageSalary) AS SalaryPercentile,
                PERCENT_RANK() OVER (ORDER BY AveragePerformanceRating) AS PerformancePercentile,
                COUNT(*) OVER() AS TotalDepartments
            FROM DepartmentSummary
        )
        SELECT 
            DepartmentID,
            DepartmentName,
            DepartmentHead,
            DepartmentHeadName,
            Budget,
            Location,
            CreatedDate,
            ModifiedDate,
            TotalEmployees,
            ActiveEmployees,
            InactiveEmployees,
            TopLevelEmployees,
            ManagedEmployees,
            TotalSalaryBudget,
            AverageSalary,
            MinSalary,
            MaxSalary,
            SalaryStandardDeviation,
            AverageYearsOfService,
            MinYearsOfService,
            MaxYearsOfService,
            JuniorEmployees,
            MidLevelEmployees,
            SeniorEmployees,
            TotalProjects,
            ActiveProjects,
            CompletedProjects,
            PlanningProjects,
            TotalPerformanceReviews,
            AveragePerformanceRating,
            HighPerformanceReviews,
            LowPerformanceReviews,
            TotalSalaryChanges,
            AverageSalaryIncreasePercentage,
            BudgetUtilizationPercentage,
            BudgetVariance,
            HighPerformancePercentage,
            LowPerformancePercentage,
            SalaryRank,
            PerformanceRank,
            BudgetRank,
            SizeRank,
            SalaryRankByRank,
            PerformanceRankByRank,
            SalaryPercentile,
            PerformancePercentile,
            TotalDepartments,
            -- Calculate department efficiency score
            CASE 
                WHEN AveragePerformanceRating >= 4.0 AND BudgetUtilizationPercentage <= 100 AND ActiveEmployeePercentage >= 90 THEN 5.0
                WHEN AveragePerformanceRating >= 3.5 AND BudgetUtilizationPercentage <= 110 AND ActiveEmployeePercentage >= 80 THEN 4.0
                WHEN AveragePerformanceRating >= 3.0 AND BudgetUtilizationPercentage <= 120 AND ActiveEmployeePercentage >= 70 THEN 3.0
                WHEN AveragePerformanceRating >= 2.5 AND BudgetUtilizationPercentage <= 130 AND ActiveEmployeePercentage >= 60 THEN 2.0
                ELSE 1.0
            END AS EfficiencyScore,
            -- Calculate department health status
            CASE 
                WHEN AveragePerformanceRating >= 4.0 AND BudgetUtilizationPercentage <= 100 AND ActiveEmployeePercentage >= 90 THEN 'Excellent'
                WHEN AveragePerformanceRating >= 3.5 AND BudgetUtilizationPercentage <= 110 AND ActiveEmployeePercentage >= 80 THEN 'Good'
                WHEN AveragePerformanceRating >= 3.0 AND BudgetUtilizationPercentage <= 120 AND ActiveEmployeePercentage >= 70 THEN 'Fair'
                WHEN AveragePerformanceRating >= 2.5 AND BudgetUtilizationPercentage <= 130 AND ActiveEmployeePercentage >= 60 THEN 'Poor'
                ELSE 'Critical'
            END AS HealthStatus,
            -- Calculate active employee percentage
            CASE 
                WHEN TotalEmployees > 0 
                THEN (CAST(ActiveEmployees AS FLOAT) / TotalEmployees) * 100.0
                ELSE 0
            END AS ActiveEmployeePercentage
        FROM DepartmentRankings
        ORDER BY AveragePerformanceRating DESC, AverageSalary DESC;
        
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
-- 3. Get Department Budget Analysis
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetDepartmentBudgetAnalysis]
    @Year INT = NULL,
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to calculate comprehensive budget analysis
        WITH BudgetAnalysis AS (
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                d.Budget,
                d.Location,
                -- Current year salary costs
                SUM(e.Salary) AS CurrentYearSalaryCost,
                COUNT(e.EmployeeID) AS CurrentEmployeeCount,
                AVG(CAST(e.Salary AS FLOAT)) AS CurrentAverageSalary,
                -- Project costs
                SUM(p.Budget) AS ProjectBudget,
                COUNT(p.ProjectID) AS ProjectCount,
                -- Salary history analysis
                COUNT(sh.SalaryHistoryID) AS SalaryChangesThisYear,
                AVG(CASE 
                    WHEN YEAR(sh.ChangeDate) = @Year AND sh.OldSalary > 0 
                    THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
                END) AS AverageSalaryIncreasePercentage,
                SUM(CASE 
                    WHEN YEAR(sh.ChangeDate) = @Year 
                    THEN sh.NewSalary - ISNULL(sh.OldSalary, 0)
                END) AS TotalSalaryIncreaseAmount,
                -- Performance-based salary adjustments
                AVG(CASE 
                    WHEN YEAR(pr.ReviewDate) = @Year AND pr.OverallRating >= 4.0 
                    THEN e.Salary * 0.12  -- 12% bonus for high performers
                    WHEN YEAR(pr.ReviewDate) = @Year AND pr.OverallRating >= 3.5 
                    THEN e.Salary * 0.08   -- 8% bonus for good performers
                    ELSE 0
                END) AS AveragePerformanceBonus,
                -- Calculate total compensation cost
                SUM(e.Salary) + AVG(CASE 
                    WHEN YEAR(pr.ReviewDate) = @Year AND pr.OverallRating >= 4.0 
                    THEN e.Salary * 0.12
                    WHEN YEAR(pr.ReviewDate) = @Year AND pr.OverallRating >= 3.5 
                    THEN e.Salary * 0.08
                    ELSE 0
                END) AS TotalCompensationCost
            FROM Departments d
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
            LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
            LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
            LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY d.DepartmentID, d.DepartmentName, d.Budget, d.Location
        ),
        BudgetProjections AS (
            SELECT 
                *,
                -- Calculate budget utilization
                CASE 
                    WHEN Budget IS NOT NULL AND Budget > 0 
                    THEN (CurrentYearSalaryCost / Budget) * 100.0
                    ELSE NULL
                END AS BudgetUtilizationPercentage,
                -- Calculate budget variance
                CASE 
                    WHEN Budget IS NOT NULL 
                    THEN Budget - CurrentYearSalaryCost
                    ELSE NULL
                END AS BudgetVariance,
                -- Calculate projected next year costs
                CurrentYearSalaryCost * (1 + ISNULL(AverageSalaryIncreasePercentage, 3.0) / 100.0) AS ProjectedNextYearSalaryCost,
                -- Calculate budget recommendations
                CASE 
                    WHEN Budget IS NULL THEN CurrentYearSalaryCost * 1.1  -- 10% increase if no budget set
                    WHEN BudgetUtilizationPercentage > 120 THEN Budget * 1.15  -- 15% increase if over budget
                    WHEN BudgetUtilizationPercentage > 100 THEN Budget * 1.10  -- 10% increase if at budget
                    WHEN BudgetUtilizationPercentage > 80 THEN Budget * 1.05  -- 5% increase if under budget
                    ELSE Budget  -- Keep same if well under budget
                END AS RecommendedBudget,
                -- Calculate cost per employee
                CASE 
                    WHEN CurrentEmployeeCount > 0 
                    THEN CurrentYearSalaryCost / CurrentEmployeeCount
                    ELSE 0
                END AS CostPerEmployee,
                -- Calculate cost per project
                CASE 
                    WHEN ProjectCount > 0 
                    THEN ProjectBudget / ProjectCount
                    ELSE 0
                END AS CostPerProject
            FROM BudgetAnalysis
        ),
        BudgetRankings AS (
            SELECT 
                *,
                -- Rankings
                ROW_NUMBER() OVER (ORDER BY BudgetUtilizationPercentage DESC) AS BudgetUtilizationRank,
                ROW_NUMBER() OVER (ORDER BY CurrentYearSalaryCost DESC) AS SalaryCostRank,
                ROW_NUMBER() OVER (ORDER BY AverageSalary DESC) AS AverageSalaryRank,
                ROW_NUMBER() OVER (ORDER BY TotalCompensationCost DESC) AS TotalCostRank,
                RANK() OVER (ORDER BY BudgetUtilizationPercentage DESC) AS BudgetUtilizationRankByRank,
                PERCENT_RANK() OVER (ORDER BY BudgetUtilizationPercentage) AS BudgetUtilizationPercentile,
                COUNT(*) OVER() AS TotalDepartments
            FROM BudgetProjections
        )
        SELECT 
            DepartmentID,
            DepartmentName,
            Budget,
            Location,
            CurrentYearSalaryCost,
            CurrentEmployeeCount,
            CurrentAverageSalary,
            ProjectBudget,
            ProjectCount,
            SalaryChangesThisYear,
            AverageSalaryIncreasePercentage,
            TotalSalaryIncreaseAmount,
            AveragePerformanceBonus,
            TotalCompensationCost,
            BudgetUtilizationPercentage,
            BudgetVariance,
            ProjectedNextYearSalaryCost,
            RecommendedBudget,
            CostPerEmployee,
            CostPerProject,
            BudgetUtilizationRank,
            SalaryCostRank,
            AverageSalaryRank,
            TotalCostRank,
            BudgetUtilizationRankByRank,
            BudgetUtilizationPercentile,
            TotalDepartments,
            -- Calculate budget status
            CASE 
                WHEN BudgetUtilizationPercentage > 120 THEN 'Over Budget (Critical)'
                WHEN BudgetUtilizationPercentage > 100 THEN 'Over Budget'
                WHEN BudgetUtilizationPercentage > 80 THEN 'Near Budget'
                WHEN BudgetUtilizationPercentage > 60 THEN 'Under Budget'
                ELSE 'Well Under Budget'
            END AS BudgetStatus,
            -- Calculate budget efficiency
            CASE 
                WHEN BudgetUtilizationPercentage <= 100 AND AveragePerformanceRating >= 4.0 THEN 'Highly Efficient'
                WHEN BudgetUtilizationPercentage <= 110 AND AveragePerformanceRating >= 3.5 THEN 'Efficient'
                WHEN BudgetUtilizationPercentage <= 120 AND AveragePerformanceRating >= 3.0 THEN 'Moderately Efficient'
                WHEN BudgetUtilizationPercentage <= 130 AND AveragePerformanceRating >= 2.5 THEN 'Inefficient'
                ELSE 'Highly Inefficient'
            END AS BudgetEfficiency,
            -- Calculate recommended actions
            CASE 
                WHEN BudgetUtilizationPercentage > 120 THEN 'Reduce costs or increase budget'
                WHEN BudgetUtilizationPercentage > 100 THEN 'Monitor spending closely'
                WHEN BudgetUtilizationPercentage > 80 THEN 'Consider strategic investments'
                WHEN BudgetUtilizationPercentage > 60 THEN 'Opportunity for growth'
                ELSE 'Consider budget reduction'
            END AS RecommendedAction,
            @Year AS AnalysisYear
        FROM BudgetRankings
        ORDER BY BudgetUtilizationPercentage DESC;
        
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
-- 4. Create Department
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CreateDepartment]
    @DepartmentName NVARCHAR(100),
    @DepartmentHead INT = NULL,
    @Budget DECIMAL(18,2) = NULL,
    @Location NVARCHAR(100) = NULL,
    @CreatedBy NVARCHAR(100) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate inputs
        IF @DepartmentName IS NULL OR LEN(TRIM(@DepartmentName)) = 0
        BEGIN
            RAISERROR('Department name is required', 16, 1);
            RETURN;
        END
        
        -- Check if department name already exists
        IF EXISTS (SELECT 1 FROM Departments WHERE DepartmentName = @DepartmentName)
        BEGIN
            RAISERROR('Department name already exists', 16, 1);
            RETURN;
        END
        
        -- Check if department head exists and is active (if provided)
        IF @DepartmentHead IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @DepartmentHead AND IsActive = 1)
        BEGIN
            RAISERROR('Department head does not exist or is inactive', 16, 1);
            RETURN;
        END
        
        -- Validate budget
        IF @Budget IS NOT NULL AND @Budget <= 0
        BEGIN
            RAISERROR('Budget must be greater than 0', 16, 1);
            RETURN;
        END
        
        -- Insert department
        DECLARE @DepartmentID INT;
        
        INSERT INTO Departments (DepartmentName, DepartmentHead, Budget, Location)
        VALUES (@DepartmentName, @DepartmentHead, @Budget, @Location);
        
        SET @DepartmentID = SCOPE_IDENTITY();
        
        -- Log audit
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Departments', @DepartmentID, 'INSERT', NULL, 
                CONCAT('Department: ', @DepartmentName, ' - Budget: ', ISNULL(CAST(@Budget AS NVARCHAR), 'Not Set')), @CreatedBy);
        
        COMMIT TRANSACTION;
        
        -- Return the created department
        SELECT 
            d.DepartmentID,
            d.DepartmentName,
            d.DepartmentHead,
            e.FullName AS DepartmentHeadName,
            d.Budget,
            d.Location,
            d.CreatedDate,
            d.ModifiedDate
        FROM Departments d
        LEFT JOIN Employees e ON d.DepartmentHead = e.EmployeeID
        WHERE d.DepartmentID = @DepartmentID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 5. Update Department
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_UpdateDepartment]
    @DepartmentID INT,
    @DepartmentName NVARCHAR(100) = NULL,
    @DepartmentHead INT = NULL,
    @Budget DECIMAL(18,2) = NULL,
    @Location NVARCHAR(100) = NULL,
    @UpdatedBy NVARCHAR(100) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if department exists
        IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Department does not exist', 16, 1);
            RETURN;
        END
        
        -- Check if new department name already exists (if changing)
        IF @DepartmentName IS NOT NULL AND EXISTS (SELECT 1 FROM Departments WHERE DepartmentName = @DepartmentName AND DepartmentID != @DepartmentID)
        BEGIN
            RAISERROR('Department name already exists', 16, 1);
            RETURN;
        END
        
        -- Check if department head exists and is active (if provided)
        IF @DepartmentHead IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @DepartmentHead AND IsActive = 1)
        BEGIN
            RAISERROR('Department head does not exist or is inactive', 16, 1);
            RETURN;
        END
        
        -- Validate budget
        IF @Budget IS NOT NULL AND @Budget <= 0
        BEGIN
            RAISERROR('Budget must be greater than 0', 16, 1);
            RETURN;
        END
        
        -- Get current values for audit
        DECLARE @OldValues NVARCHAR(MAX);
        SELECT @OldValues = CONCAT(
            'DepartmentName:', ISNULL(DepartmentName, 'NULL'), ';',
            'DepartmentHead:', ISNULL(CAST(DepartmentHead AS NVARCHAR), 'NULL'), ';',
            'Budget:', ISNULL(CAST(Budget AS NVARCHAR), 'NULL'), ';',
            'Location:', ISNULL(Location, 'NULL')
        )
        FROM Departments WHERE DepartmentID = @DepartmentID;
        
        -- Update department
        UPDATE Departments 
        SET 
            DepartmentName = ISNULL(@DepartmentName, DepartmentName),
            DepartmentHead = ISNULL(@DepartmentHead, DepartmentHead),
            Budget = ISNULL(@Budget, Budget),
            Location = ISNULL(@Location, Location),
            ModifiedDate = GETDATE()
        WHERE DepartmentID = @DepartmentID;
        
        -- Log audit
        DECLARE @NewValues NVARCHAR(MAX);
        SELECT @NewValues = CONCAT(
            'DepartmentName:', ISNULL(DepartmentName, 'NULL'), ';',
            'DepartmentHead:', ISNULL(CAST(DepartmentHead AS NVARCHAR), 'NULL'), ';',
            'Budget:', ISNULL(CAST(Budget AS NVARCHAR), 'NULL'), ';',
            'Location:', ISNULL(Location, 'NULL')
        )
        FROM Departments WHERE DepartmentID = @DepartmentID;
        
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Departments', @DepartmentID, 'UPDATE', @OldValues, @NewValues, @UpdatedBy);
        
        COMMIT TRANSACTION;
        
        -- Return updated department
        SELECT 
            d.DepartmentID,
            d.DepartmentName,
            d.DepartmentHead,
            e.FullName AS DepartmentHeadName,
            d.Budget,
            d.Location,
            d.CreatedDate,
            d.ModifiedDate
        FROM Departments d
        LEFT JOIN Employees e ON d.DepartmentHead = e.EmployeeID
        WHERE d.DepartmentID = @DepartmentID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 6. Get Department Resource Allocation
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetDepartmentResourceAllocation]
    @DepartmentID INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to calculate resource allocation
        WITH ResourceAllocation AS (
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                d.Budget,
                d.Location,
                -- Employee resources
                COUNT(e.EmployeeID) AS TotalEmployees,
                SUM(e.Salary) AS TotalSalaryCost,
                AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
                -- Project resources
                COUNT(p.ProjectID) AS TotalProjects,
                SUM(p.Budget) AS TotalProjectBudget,
                AVG(CAST(p.Budget AS FLOAT)) AS AverageProjectBudget,
                -- Resource allocation percentages
                COUNT(CASE WHEN ep.AllocationPercentage >= 100 THEN 1 END) AS FullTimeEmployees,
                COUNT(CASE WHEN ep.AllocationPercentage BETWEEN 50 AND 99 THEN 1 END) AS PartTimeEmployees,
                COUNT(CASE WHEN ep.AllocationPercentage < 50 THEN 1 END) AS LowAllocationEmployees,
                -- Calculate total allocation
                SUM(ep.AllocationPercentage) AS TotalAllocationPercentage,
                -- Calculate resource utilization
                CASE 
                    WHEN COUNT(e.EmployeeID) > 0 
                    THEN SUM(ep.AllocationPercentage) / COUNT(e.EmployeeID)
                    ELSE 0
                END AS AverageAllocationPercentage
            FROM Departments d
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
            LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
            LEFT JOIN EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID
            WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY d.DepartmentID, d.DepartmentName, d.Budget, d.Location
        ),
        ResourceMetrics AS (
            SELECT 
                *,
                -- Calculate budget allocation
                CASE 
                    WHEN Budget IS NOT NULL AND Budget > 0 
                    THEN (TotalSalaryCost / Budget) * 100.0
                    ELSE NULL
                END AS BudgetAllocationPercentage,
                -- Calculate resource efficiency
                CASE 
                    WHEN TotalEmployees > 0 
                    THEN (CAST(FullTimeEmployees AS FLOAT) / TotalEmployees) * 100.0
                    ELSE 0
                END AS FullTimeEmployeePercentage,
                -- Calculate project resource allocation
                CASE 
                    WHEN TotalProjectBudget > 0 
                    THEN (TotalSalaryCost / TotalProjectBudget) * 100.0
                    ELSE NULL
                END AS ProjectResourceAllocationPercentage,
                -- Calculate resource utilization score
                CASE 
                    WHEN AverageAllocationPercentage >= 80 THEN 5.0
                    WHEN AverageAllocationPercentage >= 60 THEN 4.0
                    WHEN AverageAllocationPercentage >= 40 THEN 3.0
                    WHEN AverageAllocationPercentage >= 20 THEN 2.0
                    ELSE 1.0
                END AS ResourceUtilizationScore
            FROM ResourceAllocation
        )
        SELECT 
            DepartmentID,
            DepartmentName,
            Budget,
            Location,
            TotalEmployees,
            TotalSalaryCost,
            AverageSalary,
            TotalProjects,
            TotalProjectBudget,
            AverageProjectBudget,
            FullTimeEmployees,
            PartTimeEmployees,
            LowAllocationEmployees,
            TotalAllocationPercentage,
            AverageAllocationPercentage,
            BudgetAllocationPercentage,
            FullTimeEmployeePercentage,
            ProjectResourceAllocationPercentage,
            ResourceUtilizationScore,
            -- Calculate resource status
            CASE 
                WHEN ResourceUtilizationScore >= 4.0 AND BudgetAllocationPercentage <= 100 THEN 'Optimal'
                WHEN ResourceUtilizationScore >= 3.0 AND BudgetAllocationPercentage <= 110 THEN 'Good'
                WHEN ResourceUtilizationScore >= 2.0 AND BudgetAllocationPercentage <= 120 THEN 'Fair'
                WHEN ResourceUtilizationScore >= 1.0 AND BudgetAllocationPercentage <= 130 THEN 'Poor'
                ELSE 'Critical'
            END AS ResourceStatus,
            -- Calculate recommendations
            CASE 
                WHEN ResourceUtilizationScore < 2.0 THEN 'Increase resource allocation'
                WHEN BudgetAllocationPercentage > 120 THEN 'Reduce budget allocation'
                WHEN FullTimeEmployeePercentage < 50 THEN 'Consider full-time positions'
                WHEN AverageAllocationPercentage > 120 THEN 'Reduce employee workload'
                ELSE 'Maintain current allocation'
            END AS Recommendation,
            @Year AS AnalysisYear
        FROM ResourceMetrics
        ORDER BY ResourceUtilizationScore DESC, BudgetAllocationPercentage ASC;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

PRINT 'Department summary stored procedures created successfully!';
PRINT 'Procedures created: sp_GetDepartmentHierarchy, sp_GetDepartmentSummaryDashboard, sp_GetDepartmentBudgetAnalysis, sp_CreateDepartment, sp_UpdateDepartment, sp_GetDepartmentResourceAllocation';
PRINT 'Features demonstrated: Hierarchical Queries, Complex Aggregations, Budget Analysis, Resource Allocation, Department Management';
