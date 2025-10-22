-- =============================================
-- Employee Management System - Views and Functions
-- Created: 2024
-- Description: Advanced views and functions demonstrating T-SQL analytics capabilities
--              Includes window functions, CTEs, and complex business logic
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Views for Complex Reporting
-- =============================================

-- Employee Summary View: Comprehensive employee information
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_EmployeeSummary')
    DROP VIEW [dbo].[vw_EmployeeSummary];
GO

CREATE VIEW [dbo].[vw_EmployeeSummary]
AS
SELECT 
    e.EmployeeID,
    e.FullName,
    e.FirstName,
    e.LastName,
    e.Email,
    e.Phone,
    e.DateOfBirth,
    e.Age,
    e.HireDate,
    e.YearsOfService,
    e.JobTitle,
    e.Salary,
    e.IsActive,
    e.CreatedDate,
    e.ModifiedDate,
    
    -- Department information
    d.DepartmentID,
    d.DepartmentName,
    d.Location AS DepartmentLocation,
    d.Budget AS DepartmentBudget,
    
    -- Manager information
    m.EmployeeID AS ManagerID,
    m.FullName AS ManagerName,
    m.Email AS ManagerEmail,
    m.JobTitle AS ManagerJobTitle,
    
    -- Department head information
    dh.EmployeeID AS DepartmentHeadID,
    dh.FullName AS DepartmentHeadName,
    dh.Email AS DepartmentHeadEmail,
    
    -- Project statistics
    ISNULL(projectStats.ActiveProjectCount, 0) AS ActiveProjectCount,
    ISNULL(projectStats.TotalAllocationPercentage, 0) AS TotalAllocationPercentage,
    ISNULL(projectStats.CurrentProjectRoles, '') AS CurrentProjectRoles,
    
    -- Performance statistics
    ISNULL(perfStats.LatestOverallRating, 0) AS LatestOverallRating,
    ISNULL(perfStats.AverageOverallRating, 0) AS AverageOverallRating,
    ISNULL(perfStats.TotalReviews, 0) AS TotalReviews,
    ISNULL(perfStats.LastReviewDate, NULL) AS LastReviewDate,
    
    -- Salary statistics
    ISNULL(salaryStats.SalaryIncreaseCount, 0) AS SalaryIncreaseCount,
    ISNULL(salaryStats.LastSalaryChangeDate, NULL) AS LastSalaryChangeDate,
    ISNULL(salaryStats.SalaryIncreasePercentage, 0) AS SalaryIncreasePercentage,
    
    -- Subordinate count
    ISNULL(subordinateStats.DirectReportsCount, 0) AS DirectReportsCount,
    ISNULL(subordinateStats.TotalTeamSize, 0) AS TotalTeamSize
    
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
LEFT JOIN Employees dh ON d.DepartmentHead = dh.EmployeeID

-- Project statistics subquery
LEFT JOIN (
    SELECT 
        ep.EmployeeID,
        COUNT(DISTINCT ep.ProjectID) AS ActiveProjectCount,
        SUM(ep.AllocationPercentage) AS TotalAllocationPercentage,
        STRING_AGG(ep.Role, ', ') AS CurrentProjectRoles
    FROM EmployeeProjects ep
    INNER JOIN Projects p ON ep.ProjectID = p.ProjectID
    WHERE ep.EndDate IS NULL OR ep.EndDate >= CAST(GETDATE() AS DATE)
    AND p.Status IN ('Planning', 'Active')
    GROUP BY ep.EmployeeID
) projectStats ON e.EmployeeID = projectStats.EmployeeID

-- Performance statistics subquery
LEFT JOIN (
    SELECT 
        pr.EmployeeID,
        pr.OverallRating AS LatestOverallRating,
        AVG(pr.OverallRating) AS AverageOverallRating,
        COUNT(*) AS TotalReviews,
        MAX(pr.ReviewDate) AS LastReviewDate
    FROM PerformanceReviews pr
    WHERE pr.ReviewDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY pr.EmployeeID, pr.OverallRating
    HAVING pr.ReviewDate = MAX(pr.ReviewDate)
) perfStats ON e.EmployeeID = perfStats.EmployeeID

-- Salary statistics subquery
LEFT JOIN (
    SELECT 
        sh.EmployeeID,
        COUNT(*) AS SalaryIncreaseCount,
        MAX(sh.ChangeDate) AS LastSalaryChangeDate,
        CASE 
            WHEN COUNT(*) > 1 THEN 
                ((MAX(sh.NewSalary) - MIN(sh.NewSalary)) / MIN(sh.NewSalary)) * 100
            ELSE 0 
        END AS SalaryIncreasePercentage
    FROM SalaryHistory sh
    GROUP BY sh.EmployeeID
) salaryStats ON e.EmployeeID = salaryStats.EmployeeID

-- Subordinate statistics subquery
LEFT JOIN (
    SELECT 
        manager.EmployeeID,
        COUNT(subordinate.EmployeeID) AS DirectReportsCount,
        COUNT(subordinate.EmployeeID) AS TotalTeamSize -- Simplified for this view
    FROM Employees manager
    LEFT JOIN Employees subordinate ON manager.EmployeeID = subordinate.ManagerID
    WHERE subordinate.IsActive = 1
    GROUP BY manager.EmployeeID
) subordinateStats ON e.EmployeeID = subordinateStats.EmployeeID;
GO

-- Department Statistics View: Comprehensive department analytics
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_DepartmentStats')
    DROP VIEW [dbo].[vw_DepartmentStats];
GO

CREATE VIEW [dbo].[vw_DepartmentStats]
AS
SELECT 
    d.DepartmentID,
    d.DepartmentName,
    d.Location,
    d.Budget,
    d.CreatedDate,
    
    -- Employee statistics
    COUNT(e.EmployeeID) AS TotalEmployees,
    COUNT(CASE WHEN e.IsActive = 1 THEN 1 END) AS ActiveEmployees,
    COUNT(CASE WHEN e.IsActive = 0 THEN 1 END) AS InactiveEmployees,
    
    -- Salary statistics
    AVG(e.Salary) AS AverageSalary,
    MIN(e.Salary) AS MinSalary,
    MAX(e.Salary) AS MaxSalary,
    SUM(e.Salary) AS TotalSalaryCost,
    STDEV(e.Salary) AS SalaryStandardDeviation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) AS MedianSalary,
    
    -- Experience statistics
    AVG(e.YearsOfService) AS AverageYearsOfService,
    MIN(e.YearsOfService) AS MinYearsOfService,
    MAX(e.YearsOfService) AS MaxYearsOfService,
    
    -- Project statistics
    COUNT(DISTINCT p.ProjectID) AS TotalProjects,
    COUNT(DISTINCT CASE WHEN p.Status = 'Active' THEN p.ProjectID END) AS ActiveProjects,
    COUNT(DISTINCT CASE WHEN p.Status = 'Completed' THEN p.ProjectID END) AS CompletedProjects,
    COUNT(DISTINCT CASE WHEN p.Status = 'Planning' THEN p.ProjectID END) AS PlanningProjects,
    
    -- Performance statistics
    AVG(pr.OverallRating) AS AveragePerformanceRating,
    COUNT(DISTINCT pr.EmployeeID) AS EmployeesWithReviews,
    
    -- Calculated metrics
    CASE 
        WHEN d.Budget > 0 THEN (SUM(e.Salary) / d.Budget) * 100
        ELSE 0 
    END AS BudgetUtilizationPercentage,
    
    CASE 
        WHEN COUNT(e.EmployeeID) > 0 THEN (COUNT(CASE WHEN e.IsActive = 1 THEN 1 END) * 100.0 / COUNT(e.EmployeeID))
        ELSE 0 
    END AS EmployeeRetentionRate,
    
    CASE 
        WHEN COUNT(DISTINCT p.ProjectID) > 0 THEN 
            (COUNT(DISTINCT CASE WHEN p.Status = 'Completed' THEN p.ProjectID END) * 100.0 / COUNT(DISTINCT p.ProjectID))
        ELSE 0 
    END AS ProjectCompletionRate
    
FROM Departments d
LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID
LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
    AND pr.ReviewDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY d.DepartmentID, d.DepartmentName, d.Location, d.Budget, d.CreatedDate;
GO

-- Active Projects View: Current project information with team details
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ActiveProjects')
    DROP VIEW [dbo].[vw_ActiveProjects];
GO

CREATE VIEW [dbo].[vw_ActiveProjects]
AS
SELECT 
    p.ProjectID,
    p.ProjectName,
    p.Description,
    p.StartDate,
    p.EndDate,
    p.Budget,
    p.Status,
    p.CreatedDate,
    
    -- Department information
    d.DepartmentID,
    d.DepartmentName,
    d.Location AS DepartmentLocation,
    
    -- Team statistics
    COUNT(DISTINCT ep.EmployeeID) AS TeamSize,
    SUM(ep.AllocationPercentage) AS TotalAllocationPercentage,
    AVG(ep.AllocationPercentage) AS AverageAllocationPerEmployee,
    
    -- Cost analysis
    SUM((e.Salary * ep.AllocationPercentage / 100) / 12) AS MonthlyProjectCost,
    SUM((e.Salary * ep.AllocationPercentage / 100)) AS AnnualProjectCost,
    
    -- Project timeline
    CASE 
        WHEN p.EndDate IS NULL THEN 'Ongoing'
        WHEN p.EndDate < CAST(GETDATE() AS DATE) THEN 'Overdue'
        WHEN p.EndDate <= DATEADD(MONTH, 1, CAST(GETDATE() AS DATE)) THEN 'Ending Soon'
        ELSE 'On Track'
    END AS ProjectTimelineStatus,
    
    -- Budget analysis
    CASE 
        WHEN p.Budget > 0 THEN 
            (SUM((e.Salary * ep.AllocationPercentage / 100) / 12) * 12) / p.Budget * 100
        ELSE 0 
    END AS BudgetUtilizationPercentage,
    
    -- Team roles
    STRING_AGG(DISTINCT ep.Role, ', ') AS TeamRoles,
    
    -- Team members
    STRING_AGG(e.FullName, ', ') AS TeamMembers
    
FROM Projects p
INNER JOIN Departments d ON p.DepartmentID = d.DepartmentID
LEFT JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
    AND (ep.EndDate IS NULL OR ep.EndDate >= CAST(GETDATE() AS DATE))
LEFT JOIN Employees e ON ep.EmployeeID = e.EmployeeID AND e.IsActive = 1
WHERE p.Status IN ('Planning', 'Active')
GROUP BY 
    p.ProjectID, p.ProjectName, p.Description, p.StartDate, p.EndDate, 
    p.Budget, p.Status, p.CreatedDate, d.DepartmentID, d.DepartmentName, d.Location;
GO

-- Performance Overview View: Latest performance ratings and trends
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_PerformanceOverview')
    DROP VIEW [dbo].[vw_PerformanceOverview];
GO

CREATE VIEW [dbo].[vw_PerformanceOverview]
AS
WITH LatestReviews AS (
    SELECT 
        pr.EmployeeID,
        pr.ReviewID,
        pr.ReviewDate,
        pr.OverallRating,
        pr.TechnicalSkills,
        pr.Communication,
        pr.Teamwork,
        pr.Leadership,
        pr.Comments,
        pr.Goals,
        ROW_NUMBER() OVER (PARTITION BY pr.EmployeeID ORDER BY pr.ReviewDate DESC) AS ReviewRank
    FROM PerformanceReviews pr
),
PreviousReviews AS (
    SELECT 
        pr.EmployeeID,
        pr.OverallRating,
        ROW_NUMBER() OVER (PARTITION BY pr.EmployeeID ORDER BY pr.ReviewDate DESC) AS ReviewRank
    FROM PerformanceReviews pr
)
SELECT 
    e.EmployeeID,
    e.FullName,
    e.JobTitle,
    d.DepartmentName,
    
    -- Latest review information
    lr.ReviewID,
    lr.ReviewDate,
    lr.OverallRating,
    lr.TechnicalSkills,
    lr.Communication,
    lr.Teamwork,
    lr.Leadership,
    lr.Comments,
    lr.Goals,
    
    -- Performance trend
    CASE 
        WHEN pr.OverallRating IS NOT NULL THEN lr.OverallRating - pr.OverallRating
        ELSE 0 
    END AS PerformanceChange,
    
    -- Performance level classification
    CASE 
        WHEN lr.OverallRating >= 4.5 THEN 'Excellent'
        WHEN lr.OverallRating >= 3.5 THEN 'Good'
        WHEN lr.OverallRating >= 2.5 THEN 'Satisfactory'
        WHEN lr.OverallRating >= 1.5 THEN 'Needs Improvement'
        ELSE 'Unsatisfactory'
    END AS PerformanceLevel,
    
    -- Performance trend indicator
    CASE 
        WHEN pr.OverallRating IS NOT NULL AND lr.OverallRating > pr.OverallRating THEN 'Improving'
        WHEN pr.OverallRating IS NOT NULL AND lr.OverallRating < pr.OverallRating THEN 'Declining'
        WHEN pr.OverallRating IS NOT NULL AND lr.OverallRating = pr.OverallRating THEN 'Stable'
        ELSE 'New Employee'
    END AS PerformanceTrend,
    
    -- Reviewer information
    r.FullName AS ReviewerName,
    r.JobTitle AS ReviewerJobTitle
    
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
INNER JOIN LatestReviews lr ON e.EmployeeID = lr.EmployeeID AND lr.ReviewRank = 1
LEFT JOIN PreviousReviews pr ON e.EmployeeID = pr.EmployeeID AND pr.ReviewRank = 2
LEFT JOIN Employees r ON lr.ReviewID IN (
    SELECT ReviewID FROM PerformanceReviews WHERE ReviewerID = r.EmployeeID
)
WHERE e.IsActive = 1;
GO

-- Salary Analysis View: Comprehensive salary analytics
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_SalaryAnalysis')
    DROP VIEW [dbo].[vw_SalaryAnalysis];
GO

CREATE VIEW [dbo].[vw_SalaryAnalysis]
AS
SELECT 
    e.EmployeeID,
    e.FullName,
    e.JobTitle,
    d.DepartmentName,
    e.Salary,
    e.YearsOfService,
    e.HireDate,
    
    -- Salary percentiles within department
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS DepartmentQ1Salary,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS DepartmentMedianSalary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) AS DepartmentQ3Salary,
    
    -- Salary percentiles within job title
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY e.JobTitle) AS JobTitleQ1Salary,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY e.JobTitle) AS JobTitleMedianSalary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY e.JobTitle) AS JobTitleQ3Salary,
    
    -- Salary percentiles within experience level
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY 
        CASE 
            WHEN e.YearsOfService < 2 THEN 'Junior'
            WHEN e.YearsOfService < 5 THEN 'Mid-Level'
            WHEN e.YearsOfService < 10 THEN 'Senior'
            ELSE 'Executive'
        END
    ) AS ExperienceLevelQ1Salary,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY 
        CASE 
            WHEN e.YearsOfService < 2 THEN 'Junior'
            WHEN e.YearsOfService < 5 THEN 'Mid-Level'
            WHEN e.YearsOfService < 10 THEN 'Senior'
            ELSE 'Executive'
        END
    ) AS ExperienceLevelMedianSalary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY 
        CASE 
            WHEN e.YearsOfService < 2 THEN 'Junior'
            WHEN e.YearsOfService < 5 THEN 'Mid-Level'
            WHEN e.YearsOfService < 10 THEN 'Senior'
            ELSE 'Executive'
        END
    ) AS ExperienceLevelQ3Salary,
    
    -- Salary ranking
    ROW_NUMBER() OVER (ORDER BY e.Salary DESC) AS OverallSalaryRank,
    ROW_NUMBER() OVER (PARTITION BY d.DepartmentID ORDER BY e.Salary DESC) AS DepartmentSalaryRank,
    ROW_NUMBER() OVER (PARTITION BY e.JobTitle ORDER BY e.Salary DESC) AS JobTitleSalaryRank,
    
    -- Salary analysis
    CASE 
        WHEN e.Salary >= PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) THEN 'Top 10%'
        WHEN e.Salary >= PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) THEN 'Top 25%'
        WHEN e.Salary >= PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) THEN 'Above Median'
        WHEN e.Salary >= PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.Salary) OVER (PARTITION BY d.DepartmentID) THEN 'Below Median'
        ELSE 'Bottom 25%'
    END AS DepartmentSalaryPercentile,
    
    -- Experience level
    CASE 
        WHEN e.YearsOfService < 2 THEN 'Junior'
        WHEN e.YearsOfService < 5 THEN 'Mid-Level'
        WHEN e.YearsOfService < 10 THEN 'Senior'
        ELSE 'Executive'
    END AS ExperienceLevel
    
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.IsActive = 1;
GO

-- =============================================
-- 2. Scalar Functions
-- =============================================

-- Function to calculate years of service
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetYearsOfService]') AND type in (N'FN', N'IF', N'TF'))
    DROP FUNCTION [dbo].[fn_GetYearsOfService];
GO

CREATE FUNCTION [dbo].[fn_GetYearsOfService](@EmployeeID INT)
RETURNS INT
AS
BEGIN
    DECLARE @YearsOfService INT;
    
    SELECT @YearsOfService = DATEDIFF(YEAR, HireDate, GETDATE())
    FROM Employees
    WHERE EmployeeID = @EmployeeID;
    
    RETURN ISNULL(@YearsOfService, 0);
END
GO

-- Function to calculate bonus eligibility
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_CalculateBonus]') AND type in (N'FN', N'IF', N'TF'))
    DROP FUNCTION [dbo].[fn_CalculateBonus];
GO

CREATE FUNCTION [dbo].[fn_CalculateBonus](@EmployeeID INT, @Year INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Bonus DECIMAL(18,2) = 0;
    DECLARE @Salary DECIMAL(18,2);
    DECLARE @AverageRating DECIMAL(5,2);
    DECLARE @YearsOfService INT;
    
    -- Get employee salary
    SELECT @Salary = Salary
    FROM Employees
    WHERE EmployeeID = @EmployeeID AND IsActive = 1;
    
    IF @Salary IS NULL
        RETURN 0;
    
    -- Get average performance rating for the year
    SELECT @AverageRating = AVG((OverallRating + TechnicalSkills + Communication + Teamwork + Leadership) / 5.0)
    FROM PerformanceReviews
    WHERE EmployeeID = @EmployeeID
    AND YEAR(ReviewDate) = @Year;
    
    -- Get years of service
    SELECT @YearsOfService = DATEDIFF(YEAR, HireDate, GETDATE())
    FROM Employees
    WHERE EmployeeID = @EmployeeID;
    
    -- Calculate bonus based on performance and years of service
    IF @AverageRating >= 4.5
        SET @Bonus = @Salary * 0.15; -- 15% for excellent performance
    ELSE IF @AverageRating >= 3.5
        SET @Bonus = @Salary * 0.10; -- 10% for good performance
    ELSE IF @AverageRating >= 2.5
        SET @Bonus = @Salary * 0.05; -- 5% for satisfactory performance
    ELSE
        SET @Bonus = 0; -- No bonus for poor performance
    
    -- Add loyalty bonus for years of service
    IF @YearsOfService >= 10
        SET @Bonus = @Bonus + (@Salary * 0.05); -- Additional 5% for 10+ years
    ELSE IF @YearsOfService >= 5
        SET @Bonus = @Bonus + (@Salary * 0.03); -- Additional 3% for 5+ years
    
    RETURN ISNULL(@Bonus, 0);
END
GO

-- =============================================
-- 3. Table-Valued Functions
-- =============================================

-- Function to get employee hierarchy (subordinates)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetEmployeeSubordinates]') AND type in (N'FN', N'IF', N'TF'))
    DROP FUNCTION [dbo].[fn_GetEmployeeSubordinates];
GO

CREATE FUNCTION [dbo].[fn_GetEmployeeSubordinates](@ManagerID INT)
RETURNS TABLE
AS
RETURN
(
    WITH EmployeeHierarchy AS (
        -- Base case: Direct reports
        SELECT 
            e.EmployeeID,
            e.FirstName,
            e.LastName,
            e.FullName,
            e.JobTitle,
            e.Email,
            e.Salary,
            e.YearsOfService,
            e.ManagerID,
            e.DepartmentID,
            d.DepartmentName,
            @ManagerID AS RootManagerID,
            1 AS HierarchyLevel,
            CAST(e.FullName AS NVARCHAR(MAX)) AS HierarchyPath
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        WHERE e.ManagerID = @ManagerID AND e.IsActive = 1
        
        UNION ALL
        
        -- Recursive case: Subordinates of subordinates
        SELECT 
            e.EmployeeID,
            e.FirstName,
            e.LastName,
            e.FullName,
            e.JobTitle,
            e.Email,
            e.Salary,
            e.YearsOfService,
            e.ManagerID,
            e.DepartmentID,
            d.DepartmentName,
            eh.RootManagerID,
            eh.HierarchyLevel + 1,
            eh.HierarchyPath + ' > ' + e.FullName
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
        WHERE e.IsActive = 1
        AND eh.HierarchyLevel < 10 -- Prevent infinite recursion
    )
    SELECT 
        EmployeeID,
        FirstName,
        LastName,
        FullName,
        JobTitle,
        Email,
        Salary,
        YearsOfService,
        ManagerID,
        DepartmentID,
        DepartmentName,
        RootManagerID,
        HierarchyLevel,
        HierarchyPath,
        REPLICATE('  ', HierarchyLevel - 1) + FullName AS IndentedName
    FROM EmployeeHierarchy
);
GO

-- Function to get employee performance history
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetEmployeePerformanceHistory]') AND type in (N'FN', N'IF', N'TF'))
    DROP FUNCTION [dbo].[fn_GetEmployeePerformanceHistory];
GO

CREATE FUNCTION [dbo].[fn_GetEmployeePerformanceHistory](@EmployeeID INT, @Years INT = 3)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        pr.ReviewID,
        pr.ReviewDate,
        pr.ReviewPeriodStart,
        pr.ReviewPeriodEnd,
        pr.OverallRating,
        pr.TechnicalSkills,
        pr.Communication,
        pr.Teamwork,
        pr.Leadership,
        pr.Comments,
        pr.Goals,
        
        -- Reviewer information
        r.FirstName AS ReviewerFirstName,
        r.LastName AS ReviewerLastName,
        r.FullName AS ReviewerFullName,
        r.JobTitle AS ReviewerJobTitle,
        
        -- Calculated metrics
        (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS AverageRating,
        
        -- Performance trend
        LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) AS PreviousOverallRating,
        pr.OverallRating - LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) AS OverallRatingChange,
        
        -- Performance level
        CASE 
            WHEN pr.OverallRating >= 4.5 THEN 'Excellent'
            WHEN pr.OverallRating >= 3.5 THEN 'Good'
            WHEN pr.OverallRating >= 2.5 THEN 'Satisfactory'
            WHEN pr.OverallRating >= 1.5 THEN 'Needs Improvement'
            ELSE 'Unsatisfactory'
        END AS PerformanceLevel,
        
        -- Performance trend indicator
        CASE 
            WHEN pr.OverallRating - LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) > 0 THEN 'Improving'
            WHEN pr.OverallRating - LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) < 0 THEN 'Declining'
            WHEN pr.OverallRating - LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) = 0 THEN 'Stable'
            ELSE 'First Review'
        END AS PerformanceTrend
        
    FROM PerformanceReviews pr
    INNER JOIN Employees r ON pr.ReviewerID = r.EmployeeID
    WHERE pr.EmployeeID = @EmployeeID
    AND pr.ReviewDate >= DATEADD(YEAR, -@Years, GETDATE())
);
GO

PRINT 'Views and functions created successfully!';
PRINT 'Views created: vw_EmployeeSummary, vw_DepartmentStats, vw_ActiveProjects, vw_PerformanceOverview, vw_SalaryAnalysis';
PRINT 'Functions created: fn_GetYearsOfService, fn_CalculateBonus, fn_GetEmployeeSubordinates, fn_GetEmployeePerformanceHistory';
PRINT 'All views and functions demonstrate advanced T-SQL features including window functions, CTEs, and complex analytics';
