-- =============================================
-- Reporting Dashboard Views
-- Demonstrates advanced T-SQL features including:
-- - Complex views with CTEs and window functions
-- - Indexed views for performance optimization
-- - Materialized views for reporting
-- - Cross-table aggregations and analytics
-- - Real-time dashboard data
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Employee Dashboard View
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_EmployeeDashboard]
AS
WITH EmployeeMetrics AS (
    SELECT 
        e.EmployeeID,
        e.FirstName,
        e.LastName,
        e.FullName,
        e.Email,
        e.Phone,
        e.DateOfBirth,
        e.Age,
        e.HireDate,
        e.YearsOfService,
        e.DepartmentID,
        d.DepartmentName,
        e.ManagerID,
        m.FullName AS ManagerName,
        e.JobTitle,
        e.Salary,
        e.IsActive,
        e.CreatedDate,
        e.ModifiedDate,
        -- Performance metrics
        pr.OverallRating AS LatestPerformanceRating,
        pr.ReviewDate AS LatestReviewDate,
        -- Project metrics
        COUNT(DISTINCT ep.ProjectID) AS ActiveProjects,
        SUM(ep.AllocationPercentage) AS TotalAllocation,
        -- Salary history
        COUNT(sh.SalaryHistoryID) AS SalaryChanges,
        MAX(sh.ChangeDate) AS LastSalaryChange,
        -- Calculate performance trend
        CASE 
            WHEN COUNT(pr.ReviewID) > 1 THEN
                AVG(CASE WHEN YEAR(pr.ReviewDate) = YEAR(GETDATE()) THEN pr.OverallRating END) -
                AVG(CASE WHEN YEAR(pr.ReviewDate) = YEAR(GETDATE()) - 1 THEN pr.OverallRating END)
            ELSE 0
        END AS PerformanceTrend,
        -- Calculate salary growth
        CASE 
            WHEN COUNT(sh.SalaryHistoryID) > 1 THEN
                AVG(CASE 
                    WHEN YEAR(sh.ChangeDate) = YEAR(GETDATE()) AND sh.OldSalary > 0 
                    THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
                END)
            ELSE 0
        END AS SalaryGrowthPercentage
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
    LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
    LEFT JOIN EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID AND ep.EndDate IS NULL
    LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
    WHERE e.IsActive = 1
    GROUP BY e.EmployeeID, e.FirstName, e.LastName, e.FullName, e.Email, e.Phone, e.DateOfBirth, e.Age, e.HireDate, e.YearsOfService, e.DepartmentID, d.DepartmentName, e.ManagerID, m.FullName, e.JobTitle, e.Salary, e.IsActive, e.CreatedDate, e.ModifiedDate, pr.OverallRating, pr.ReviewDate
),
EmployeeRankings AS (
    SELECT 
        *,
        -- Department rankings
        ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY LatestPerformanceRating DESC) AS DepartmentPerformanceRank,
        ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS DepartmentSalaryRank,
        -- Overall rankings
        ROW_NUMBER() OVER (ORDER BY LatestPerformanceRating DESC) AS OverallPerformanceRank,
        ROW_NUMBER() OVER (ORDER BY Salary DESC) AS OverallSalaryRank,
        -- Percentiles
        PERCENT_RANK() OVER (ORDER BY LatestPerformanceRating) AS PerformancePercentile,
        PERCENT_RANK() OVER (ORDER BY Salary) AS SalaryPercentile,
        -- Calculate performance category
        CASE 
            WHEN LatestPerformanceRating >= 4.5 THEN 'Exceptional'
            WHEN LatestPerformanceRating >= 4.0 THEN 'Outstanding'
            WHEN LatestPerformanceRating >= 3.5 THEN 'Exceeds Expectations'
            WHEN LatestPerformanceRating >= 3.0 THEN 'Meets Expectations'
            WHEN LatestPerformanceRating >= 2.5 THEN 'Below Expectations'
            ELSE 'Needs Improvement'
        END AS PerformanceCategory,
        -- Calculate salary category
        CASE 
            WHEN Salary >= 150000 THEN 'High'
            WHEN Salary >= 100000 THEN 'Above Average'
            WHEN Salary >= 75000 THEN 'Average'
            WHEN Salary >= 50000 THEN 'Below Average'
            ELSE 'Low'
        END AS SalaryCategory
    FROM EmployeeMetrics
)
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    FullName,
    Email,
    Phone,
    DateOfBirth,
    Age,
    HireDate,
    YearsOfService,
    DepartmentID,
    DepartmentName,
    ManagerID,
    ManagerName,
    JobTitle,
    Salary,
    IsActive,
    CreatedDate,
    ModifiedDate,
    LatestPerformanceRating,
    LatestReviewDate,
    ActiveProjects,
    TotalAllocation,
    SalaryChanges,
    LastSalaryChange,
    PerformanceTrend,
    SalaryGrowthPercentage,
    DepartmentPerformanceRank,
    DepartmentSalaryRank,
    OverallPerformanceRank,
    OverallSalaryRank,
    PerformancePercentile,
    SalaryPercentile,
    PerformanceCategory,
    SalaryCategory,
    -- Calculate employee status
    CASE 
        WHEN LatestPerformanceRating >= 4.0 AND SalaryGrowthPercentage > 5 THEN 'High Performer - Growing'
        WHEN LatestPerformanceRating >= 4.0 AND SalaryGrowthPercentage <= 5 THEN 'High Performer - Stable'
        WHEN LatestPerformanceRating >= 3.5 AND SalaryGrowthPercentage > 3 THEN 'Good Performer - Growing'
        WHEN LatestPerformanceRating >= 3.5 AND SalaryGrowthPercentage <= 3 THEN 'Good Performer - Stable'
        WHEN LatestPerformanceRating >= 3.0 THEN 'Average Performer'
        ELSE 'Needs Development'
    END AS EmployeeStatus,
    -- Calculate risk level
    CASE 
        WHEN LatestPerformanceRating < 3.0 AND SalaryGrowthPercentage < 0 THEN 'High Risk'
        WHEN LatestPerformanceRating < 3.5 AND SalaryGrowthPercentage < 2 THEN 'Medium Risk'
        WHEN LatestPerformanceRating < 4.0 AND SalaryGrowthPercentage < 3 THEN 'Low Risk'
        ELSE 'No Risk'
    END AS RiskLevel
FROM EmployeeRankings;
GO

-- =============================================
-- 2. Department Dashboard View
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_DepartmentDashboard]
AS
WITH DepartmentMetrics AS (
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
        -- Salary metrics
        SUM(e.Salary) AS TotalSalaryCost,
        AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
        MIN(e.Salary) AS MinSalary,
        MAX(e.Salary) AS MaxSalary,
        STDEV(CAST(e.Salary AS FLOAT)) AS SalaryStandardDeviation,
        -- Experience metrics
        AVG(CAST(e.YearsOfService AS FLOAT)) AS AverageYearsOfService,
        COUNT(CASE WHEN e.YearsOfService < 2 THEN 1 END) AS JuniorEmployees,
        COUNT(CASE WHEN e.YearsOfService BETWEEN 2 AND 5 THEN 1 END) AS MidLevelEmployees,
        COUNT(CASE WHEN e.YearsOfService > 5 THEN 1 END) AS SeniorEmployees,
        -- Project metrics
        COUNT(DISTINCT p.ProjectID) AS TotalProjects,
        COUNT(CASE WHEN p.Status = 'Active' THEN 1 END) AS ActiveProjects,
        COUNT(CASE WHEN p.Status = 'Completed' THEN 1 END) AS CompletedProjects,
        SUM(p.Budget) AS TotalProjectBudget,
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
    LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID
    LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
    LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
    LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
    GROUP BY d.DepartmentID, d.DepartmentName, d.DepartmentHead, dh.FullName, d.Budget, d.Location, d.CreatedDate, d.ModifiedDate
),
DepartmentCalculations AS (
    SELECT 
        *,
        -- Budget calculations
        CASE 
            WHEN Budget IS NOT NULL AND Budget > 0 
            THEN (TotalSalaryCost / Budget) * 100.0
            ELSE NULL
        END AS BudgetUtilizationPercentage,
        CASE 
            WHEN Budget IS NOT NULL 
            THEN Budget - TotalSalaryCost
            ELSE NULL
        END AS BudgetVariance,
        -- Performance calculations
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
        -- Employee distribution
        CASE 
            WHEN TotalEmployees > 0 
            THEN (CAST(JuniorEmployees AS FLOAT) / TotalEmployees) * 100.0
            ELSE 0
        END AS JuniorEmployeePercentage,
        CASE 
            WHEN TotalEmployees > 0 
            THEN (CAST(MidLevelEmployees AS FLOAT) / TotalEmployees) * 100.0
            ELSE 0
        END AS MidLevelEmployeePercentage,
        CASE 
            WHEN TotalEmployees > 0 
            THEN (CAST(SeniorEmployees AS FLOAT) / TotalEmployees) * 100.0
            ELSE 0
        END AS SeniorEmployeePercentage
    FROM DepartmentMetrics
),
DepartmentRankings AS (
    SELECT 
        *,
        -- Rankings
        ROW_NUMBER() OVER (ORDER BY AveragePerformanceRating DESC) AS PerformanceRank,
        ROW_NUMBER() OVER (ORDER BY AverageSalary DESC) AS SalaryRank,
        ROW_NUMBER() OVER (ORDER BY TotalSalaryCost DESC) AS BudgetRank,
        ROW_NUMBER() OVER (ORDER BY TotalEmployees DESC) AS SizeRank,
        RANK() OVER (ORDER BY AveragePerformanceRating DESC) AS PerformanceRankByRank,
        PERCENT_RANK() OVER (ORDER BY AveragePerformanceRating) AS PerformancePercentile,
        PERCENT_RANK() OVER (ORDER BY AverageSalary) AS SalaryPercentile,
        COUNT(*) OVER() AS TotalDepartments
    FROM DepartmentCalculations
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
    TotalSalaryCost,
    AverageSalary,
    MinSalary,
    MaxSalary,
    SalaryStandardDeviation,
    AverageYearsOfService,
    JuniorEmployees,
    MidLevelEmployees,
    SeniorEmployees,
    TotalProjects,
    ActiveProjects,
    CompletedProjects,
    TotalProjectBudget,
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
    JuniorEmployeePercentage,
    MidLevelEmployeePercentage,
    SeniorEmployeePercentage,
    PerformanceRank,
    SalaryRank,
    BudgetRank,
    SizeRank,
    PerformanceRankByRank,
    PerformancePercentile,
    SalaryPercentile,
    TotalDepartments,
    -- Calculate department grade
    CASE 
        WHEN AveragePerformanceRating >= 4.5 THEN 'A+'
        WHEN AveragePerformanceRating >= 4.0 THEN 'A'
        WHEN AveragePerformanceRating >= 3.5 THEN 'B+'
        WHEN AveragePerformanceRating >= 3.0 THEN 'B'
        WHEN AveragePerformanceRating >= 2.5 THEN 'C+'
        WHEN AveragePerformanceRating >= 2.0 THEN 'C'
        ELSE 'D'
    END AS DepartmentGrade,
    -- Calculate department status
    CASE 
        WHEN AveragePerformanceRating >= 4.0 AND BudgetUtilizationPercentage <= 100 AND ActiveEmployeePercentage >= 90 THEN 'Excellent'
        WHEN AveragePerformanceRating >= 3.5 AND BudgetUtilizationPercentage <= 110 AND ActiveEmployeePercentage >= 80 THEN 'Good'
        WHEN AveragePerformanceRating >= 3.0 AND BudgetUtilizationPercentage <= 120 AND ActiveEmployeePercentage >= 70 THEN 'Fair'
        WHEN AveragePerformanceRating >= 2.5 AND BudgetUtilizationPercentage <= 130 AND ActiveEmployeePercentage >= 60 THEN 'Poor'
        ELSE 'Critical'
    END AS DepartmentStatus,
    -- Calculate active employee percentage
    CASE 
        WHEN TotalEmployees > 0 
        THEN (CAST(ActiveEmployees AS FLOAT) / TotalEmployees) * 100.0
        ELSE 0
    END AS ActiveEmployeePercentage
FROM DepartmentRankings;
GO

-- =============================================
-- 3. Performance Analytics View
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_PerformanceAnalytics]
AS
WITH PerformanceMetrics AS (
    SELECT 
        pr.ReviewID,
        pr.EmployeeID,
        e.FullName AS EmployeeName,
        e.DepartmentID,
        d.DepartmentName,
        e.JobTitle,
        e.YearsOfService,
        pr.ReviewerID,
        r.FullName AS ReviewerName,
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
        pr.CreatedDate,
        pr.ModifiedDate,
        -- Calculate composite scores
        (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS AverageRating,
        (pr.OverallRating * 0.4 + pr.TechnicalSkills * 0.2 + pr.Communication * 0.2 + pr.Teamwork * 0.1 + pr.Leadership * 0.1) AS WeightedScore,
        -- Calculate performance category
        CASE 
            WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 4.5 THEN 'Exceeds Expectations'
            WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 4.0 THEN 'Above Expectations'
            WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 3.5 THEN 'Meets Expectations'
            WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 3.0 THEN 'Below Expectations'
            ELSE 'Needs Improvement'
        END AS PerformanceCategory,
        -- Calculate improvement score
        CASE 
            WHEN pr.OverallRating >= 4.5 THEN 5.0
            WHEN pr.OverallRating >= 4.0 THEN 4.0
            WHEN pr.OverallRating >= 3.5 THEN 3.0
            WHEN pr.OverallRating >= 3.0 THEN 2.0
            ELSE 1.0
        END AS ImprovementScore
    FROM PerformanceReviews pr
    INNER JOIN Employees e ON pr.EmployeeID = e.EmployeeID
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN Employees r ON pr.ReviewerID = r.EmployeeID
),
PerformanceTrends AS (
    SELECT 
        *,
        -- Calculate year-over-year trends
        LAG(AverageRating) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS PreviousYearRating,
        LAG(WeightedScore) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS PreviousYearWeightedScore,
        -- Calculate improvement
        AverageRating - LAG(AverageRating) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS RatingImprovement,
        WeightedScore - LAG(WeightedScore) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS WeightedScoreImprovement,
        -- Calculate review frequency
        COUNT(*) OVER (PARTITION BY EmployeeID) AS TotalReviews,
        DATEDIFF(DAY, LAG(ReviewDate) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate), ReviewDate) AS DaysSinceLastReview
    FROM PerformanceMetrics
),
PerformanceRankings AS (
    SELECT 
        *,
        -- Department rankings
        ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY WeightedScore DESC) AS DepartmentRank,
        RANK() OVER (PARTITION BY DepartmentID ORDER BY WeightedScore DESC) AS DepartmentRankByRank,
        DENSE_RANK() OVER (PARTITION BY DepartmentID ORDER BY WeightedScore DESC) AS DepartmentRankByDenseRank,
        PERCENT_RANK() OVER (PARTITION BY DepartmentID ORDER BY WeightedScore) AS DepartmentPercentile,
        -- Overall rankings
        ROW_NUMBER() OVER (ORDER BY WeightedScore DESC) AS OverallRank,
        RANK() OVER (ORDER BY WeightedScore DESC) AS OverallRankByRank,
        PERCENT_RANK() OVER (ORDER BY WeightedScore) AS OverallPercentile,
        -- Calculate performance trend
        CASE 
            WHEN RatingImprovement > 0.5 THEN 'Significantly Improved'
            WHEN RatingImprovement > 0.1 THEN 'Improved'
            WHEN RatingImprovement > -0.1 THEN 'Stable'
            WHEN RatingImprovement > -0.5 THEN 'Declined'
            ELSE 'Significantly Declined'
        END AS PerformanceTrend,
        -- Calculate review frequency category
        CASE 
            WHEN DaysSinceLastReview IS NULL THEN 'First Review'
            WHEN DaysSinceLastReview <= 365 THEN 'Annual'
            WHEN DaysSinceLastReview <= 730 THEN 'Biannual'
            ELSE 'Irregular'
        END AS ReviewFrequency
    FROM PerformanceTrends
)
SELECT 
    ReviewID,
    EmployeeID,
    EmployeeName,
    DepartmentID,
    DepartmentName,
    JobTitle,
    YearsOfService,
    ReviewerID,
    ReviewerName,
    ReviewDate,
    ReviewPeriodStart,
    ReviewPeriodEnd,
    OverallRating,
    TechnicalSkills,
    Communication,
    Teamwork,
    Leadership,
    Comments,
    Goals,
    CreatedDate,
    ModifiedDate,
    AverageRating,
    WeightedScore,
    PerformanceCategory,
    ImprovementScore,
    PreviousYearRating,
    PreviousYearWeightedScore,
    RatingImprovement,
    WeightedScoreImprovement,
    TotalReviews,
    DaysSinceLastReview,
    DepartmentRank,
    DepartmentRankByRank,
    DepartmentRankByDenseRank,
    DepartmentPercentile,
    OverallRank,
    OverallRankByRank,
    OverallPercentile,
    PerformanceTrend,
    ReviewFrequency,
    -- Calculate performance grade
    CASE 
        WHEN AverageRating >= 4.5 THEN 'A+'
        WHEN AverageRating >= 4.0 THEN 'A'
        WHEN AverageRating >= 3.5 THEN 'B+'
        WHEN AverageRating >= 3.0 THEN 'B'
        WHEN AverageRating >= 2.5 THEN 'C+'
        WHEN AverageRating >= 2.0 THEN 'C'
        ELSE 'D'
    END AS PerformanceGrade,
    -- Calculate bonus potential
    CASE 
        WHEN AverageRating >= 4.5 THEN 'High Bonus (15%)'
        WHEN AverageRating >= 4.0 THEN 'Above Average Bonus (12%)'
        WHEN AverageRating >= 3.5 THEN 'Standard Bonus (8%)'
        WHEN AverageRating >= 3.0 THEN 'Low Bonus (5%)'
        ELSE 'No Bonus'
    END AS BonusPotential,
    -- Calculate promotion potential
    CASE 
        WHEN AverageRating >= 4.5 AND YearsOfService >= 2 THEN 'Ready for Promotion'
        WHEN AverageRating >= 4.0 AND YearsOfService >= 3 THEN 'Consider for Promotion'
        WHEN AverageRating >= 3.5 AND YearsOfService >= 5 THEN 'Future Consideration'
        ELSE 'Continue Development'
    END AS PromotionPotential
FROM PerformanceRankings;
GO

-- =============================================
-- 4. Salary Analytics View
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_SalaryAnalytics]
AS
WITH SalaryMetrics AS (
    SELECT 
        e.EmployeeID,
        e.FirstName,
        e.LastName,
        e.FullName,
        e.DepartmentID,
        d.DepartmentName,
        e.JobTitle,
        e.YearsOfService,
        e.Salary AS CurrentSalary,
        e.HireDate,
        -- Salary history metrics
        COUNT(sh.SalaryHistoryID) AS TotalSalaryChanges,
        MIN(sh.ChangeDate) AS FirstSalaryChange,
        MAX(sh.ChangeDate) AS LastSalaryChange,
        AVG(CASE 
            WHEN sh.OldSalary > 0 
            THEN ((sh.NewSalary - sh.OldSalary) / sh.OldSalary) * 100.0 
        END) AS AverageSalaryIncreasePercentage,
        SUM(CASE 
            WHEN YEAR(sh.ChangeDate) = YEAR(GETDATE()) 
            THEN sh.NewSalary - ISNULL(sh.OldSalary, 0)
        END) AS SalaryIncreaseThisYear,
        -- Performance metrics
        pr.OverallRating AS LatestPerformanceRating,
        pr.ReviewDate AS LatestReviewDate,
        -- Calculate salary growth
        CASE 
            WHEN COUNT(sh.SalaryHistoryID) > 0 THEN
                ((e.Salary - MIN(sh.OldSalary)) / MIN(sh.OldSalary)) * 100.0
            ELSE 0
        END AS TotalSalaryGrowthPercentage,
        -- Calculate years since last increase
        DATEDIFF(DAY, MAX(sh.ChangeDate), GETDATE()) AS DaysSinceLastIncrease
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
    LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID 
        AND pr.ReviewDate = (
            SELECT MAX(ReviewDate) 
            FROM PerformanceReviews pr2 
            WHERE pr2.EmployeeID = e.EmployeeID
        )
    WHERE e.IsActive = 1
    GROUP BY e.EmployeeID, e.FirstName, e.LastName, e.FullName, e.DepartmentID, d.DepartmentName, e.JobTitle, e.YearsOfService, e.Salary, e.HireDate, pr.OverallRating, pr.ReviewDate
),
SalaryComparisons AS (
    SELECT 
        *,
        -- Department comparisons
        AVG(CurrentSalary) OVER (PARTITION BY DepartmentID) AS DepartmentAverageSalary,
        MIN(CurrentSalary) OVER (PARTITION BY DepartmentID) AS DepartmentMinSalary,
        MAX(CurrentSalary) OVER (PARTITION BY DepartmentID) AS DepartmentMaxSalary,
        -- Experience comparisons
        AVG(CurrentSalary) OVER (PARTITION BY DepartmentID, 
            CASE 
                WHEN YearsOfService < 2 THEN 'Entry'
                WHEN YearsOfService < 5 THEN 'Mid'
                WHEN YearsOfService < 10 THEN 'Senior'
                ELSE 'Executive'
            END) AS ExperienceLevelAverageSalary,
        -- Performance comparisons
        AVG(CurrentSalary) OVER (PARTITION BY DepartmentID, 
            CASE 
                WHEN LatestPerformanceRating >= 4.5 THEN 'High'
                WHEN LatestPerformanceRating >= 4.0 THEN 'Above Average'
                WHEN LatestPerformanceRating >= 3.5 THEN 'Average'
                WHEN LatestPerformanceRating >= 3.0 THEN 'Below Average'
                ELSE 'Low'
            END) AS PerformanceLevelAverageSalary
    FROM SalaryMetrics
),
SalaryRankings AS (
    SELECT 
        *,
        -- Calculate salary position
        CurrentSalary - DepartmentAverageSalary AS SalaryVsDepartmentAverage,
        CurrentSalary - ExperienceLevelAverageSalary AS SalaryVsExperienceAverage,
        CurrentSalary - PerformanceLevelAverageSalary AS SalaryVsPerformanceAverage,
        -- Rankings
        ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY CurrentSalary DESC) AS DepartmentSalaryRank,
        ROW_NUMBER() OVER (ORDER BY CurrentSalary DESC) AS OverallSalaryRank,
        RANK() OVER (PARTITION BY DepartmentID ORDER BY CurrentSalary DESC) AS DepartmentSalaryRankByRank,
        PERCENT_RANK() OVER (PARTITION BY DepartmentID ORDER BY CurrentSalary) AS DepartmentSalaryPercentile,
        PERCENT_RANK() OVER (ORDER BY CurrentSalary) AS OverallSalaryPercentile,
        -- Calculate salary category
        CASE 
            WHEN CurrentSalary >= 150000 THEN 'High'
            WHEN CurrentSalary >= 100000 THEN 'Above Average'
            WHEN CurrentSalary >= 75000 THEN 'Average'
            WHEN CurrentSalary >= 50000 THEN 'Below Average'
            ELSE 'Low'
        END AS SalaryCategory,
        -- Calculate market position
        CASE 
            WHEN CurrentSalary > DepartmentMaxSalary * 0.9 THEN 'Top 10%'
            WHEN CurrentSalary > DepartmentMaxSalary * 0.75 THEN 'Top 25%'
            WHEN CurrentSalary > DepartmentMaxSalary * 0.5 THEN 'Above Median'
            WHEN CurrentSalary > DepartmentMaxSalary * 0.25 THEN 'Below Median'
            ELSE 'Bottom 25%'
        END AS MarketPosition
    FROM SalaryComparisons
)
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    FullName,
    DepartmentID,
    DepartmentName,
    JobTitle,
    YearsOfService,
    CurrentSalary,
    HireDate,
    TotalSalaryChanges,
    FirstSalaryChange,
    LastSalaryChange,
    AverageSalaryIncreasePercentage,
    SalaryIncreaseThisYear,
    LatestPerformanceRating,
    LatestReviewDate,
    TotalSalaryGrowthPercentage,
    DaysSinceLastIncrease,
    DepartmentAverageSalary,
    DepartmentMinSalary,
    DepartmentMaxSalary,
    ExperienceLevelAverageSalary,
    PerformanceLevelAverageSalary,
    SalaryVsDepartmentAverage,
    SalaryVsExperienceAverage,
    SalaryVsPerformanceAverage,
    DepartmentSalaryRank,
    OverallSalaryRank,
    DepartmentSalaryRankByRank,
    DepartmentSalaryPercentile,
    OverallSalaryPercentile,
    SalaryCategory,
    MarketPosition,
    -- Calculate salary adjustment recommendation
    CASE 
        WHEN SalaryVsDepartmentAverage < -10000 AND LatestPerformanceRating >= 4.0 THEN 'High Priority Increase'
        WHEN SalaryVsDepartmentAverage < -5000 AND LatestPerformanceRating >= 3.5 THEN 'Medium Priority Increase'
        WHEN SalaryVsDepartmentAverage < 0 AND LatestPerformanceRating >= 4.0 THEN 'Consider Increase'
        WHEN SalaryVsDepartmentAverage > 10000 AND LatestPerformanceRating < 3.0 THEN 'Consider Decrease'
        ELSE 'Maintain Current Level'
    END AS SalaryAdjustmentRecommendation,
    -- Calculate salary risk
    CASE 
        WHEN SalaryVsDepartmentAverage < -15000 AND LatestPerformanceRating >= 4.0 THEN 'High Risk of Departure'
        WHEN SalaryVsDepartmentAverage < -10000 AND LatestPerformanceRating >= 3.5 THEN 'Medium Risk of Departure'
        WHEN SalaryVsDepartmentAverage < -5000 AND LatestPerformanceRating >= 3.0 THEN 'Low Risk of Departure'
        ELSE 'No Risk'
    END AS SalaryRisk,
    -- Calculate next review recommendation
    CASE 
        WHEN DaysSinceLastIncrease > 730 THEN 'Overdue for Review'
        WHEN DaysSinceLastIncrease > 365 THEN 'Due for Review'
        WHEN DaysSinceLastIncrease > 180 THEN 'Consider Review'
        ELSE 'Recently Reviewed'
    END AS ReviewRecommendation
FROM SalaryRankings;
GO

-- =============================================
-- 5. Project Analytics View
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_ProjectAnalytics]
AS
WITH ProjectMetrics AS (
    SELECT 
        p.ProjectID,
        p.ProjectName,
        p.Description,
        p.StartDate,
        p.EndDate,
        p.Budget,
        p.Status,
        p.DepartmentID,
        d.DepartmentName,
        p.CreatedDate,
        p.ModifiedDate,
        -- Employee metrics
        COUNT(DISTINCT ep.EmployeeID) AS TotalEmployees,
        COUNT(CASE WHEN ep.EndDate IS NULL THEN 1 END) AS ActiveEmployees,
        SUM(ep.AllocationPercentage) AS TotalAllocation,
        AVG(CAST(ep.AllocationPercentage AS FLOAT)) AS AverageAllocation,
        -- Calculate project duration
        CASE 
            WHEN p.EndDate IS NOT NULL THEN DATEDIFF(DAY, p.StartDate, p.EndDate)
            ELSE DATEDIFF(DAY, p.StartDate, GETDATE())
        END AS ProjectDurationDays,
        -- Calculate project progress
        CASE 
            WHEN p.EndDate IS NOT NULL THEN 100.0
            WHEN p.StartDate > GETDATE() THEN 0.0
            ELSE 
                CASE 
                    WHEN DATEDIFF(DAY, p.StartDate, GETDATE()) > 0 
                    THEN (CAST(DATEDIFF(DAY, p.StartDate, GETDATE()) AS FLOAT) / DATEDIFF(DAY, p.StartDate, DATEADD(YEAR, 1, p.StartDate))) * 100.0
                    ELSE 0.0
                END
        END AS ProjectProgressPercentage,
        -- Calculate budget utilization
        CASE 
            WHEN p.Budget IS NOT NULL AND p.Budget > 0 
            THEN (SUM(e.Salary * ep.AllocationPercentage / 100.0) / p.Budget) * 100.0
            ELSE NULL
        END AS BudgetUtilizationPercentage
    FROM Projects p
    INNER JOIN Departments d ON p.DepartmentID = d.DepartmentID
    LEFT JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
    LEFT JOIN Employees e ON ep.EmployeeID = e.EmployeeID
    GROUP BY p.ProjectID, p.ProjectName, p.Description, p.StartDate, p.EndDate, p.Budget, p.Status, p.DepartmentID, d.DepartmentName, p.CreatedDate, p.ModifiedDate
),
ProjectRankings AS (
    SELECT 
        *,
        -- Rankings
        ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY Budget DESC) AS DepartmentBudgetRank,
        ROW_NUMBER() OVER (ORDER BY Budget DESC) AS OverallBudgetRank,
        ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY TotalEmployees DESC) AS DepartmentEmployeeRank,
        ROW_NUMBER() OVER (ORDER BY TotalEmployees DESC) AS OverallEmployeeRank,
        RANK() OVER (PARTITION BY DepartmentID ORDER BY Budget DESC) AS DepartmentBudgetRankByRank,
        PERCENT_RANK() OVER (ORDER BY Budget) AS BudgetPercentile,
        PERCENT_RANK() OVER (ORDER BY TotalEmployees) AS EmployeeCountPercentile,
        -- Calculate project category
        CASE 
            WHEN Budget >= 1000000 THEN 'Large'
            WHEN Budget >= 500000 THEN 'Medium'
            WHEN Budget >= 100000 THEN 'Small'
            ELSE 'Micro'
        END AS ProjectSizeCategory,
        -- Calculate project status
        CASE 
            WHEN Status = 'Completed' THEN 'Completed'
            WHEN Status = 'Active' AND ProjectProgressPercentage >= 80 THEN 'Near Completion'
            WHEN Status = 'Active' AND ProjectProgressPercentage >= 50 THEN 'In Progress'
            WHEN Status = 'Active' AND ProjectProgressPercentage < 50 THEN 'Early Stage'
            WHEN Status = 'Planning' THEN 'Planning'
            WHEN Status = 'On Hold' THEN 'On Hold'
            ELSE 'Other'
        END AS ProjectStatusCategory
    FROM ProjectMetrics
)
SELECT 
    ProjectID,
    ProjectName,
    Description,
    StartDate,
    EndDate,
    Budget,
    Status,
    DepartmentID,
    DepartmentName,
    CreatedDate,
    ModifiedDate,
    TotalEmployees,
    ActiveEmployees,
    TotalAllocation,
    AverageAllocation,
    ProjectDurationDays,
    ProjectProgressPercentage,
    BudgetUtilizationPercentage,
    DepartmentBudgetRank,
    OverallBudgetRank,
    DepartmentEmployeeRank,
    OverallEmployeeRank,
    DepartmentBudgetRankByRank,
    BudgetPercentile,
    EmployeeCountPercentile,
    ProjectSizeCategory,
    ProjectStatusCategory,
    -- Calculate project health
    CASE 
        WHEN Status = 'Completed' AND BudgetUtilizationPercentage <= 100 THEN 'Successful'
        WHEN Status = 'Active' AND BudgetUtilizationPercentage <= 80 AND ProjectProgressPercentage >= 50 THEN 'Healthy'
        WHEN Status = 'Active' AND BudgetUtilizationPercentage <= 100 AND ProjectProgressPercentage >= 30 THEN 'On Track'
        WHEN Status = 'Active' AND BudgetUtilizationPercentage > 100 THEN 'Over Budget'
        WHEN Status = 'Active' AND ProjectProgressPercentage < 30 THEN 'Delayed'
        WHEN Status = 'On Hold' THEN 'Paused'
        ELSE 'Needs Attention'
    END AS ProjectHealth,
    -- Calculate resource efficiency
    CASE 
        WHEN TotalEmployees > 0 AND Budget IS NOT NULL AND Budget > 0 
        THEN Budget / TotalEmployees
        ELSE NULL
    END AS BudgetPerEmployee,
    -- Calculate timeline efficiency
    CASE 
        WHEN ProjectDurationDays > 0 AND Budget IS NOT NULL AND Budget > 0 
        THEN Budget / ProjectDurationDays
        ELSE NULL
    END AS BudgetPerDay,
    -- Calculate completion prediction
    CASE 
        WHEN Status = 'Active' AND ProjectProgressPercentage > 0 
        THEN DATEADD(DAY, (100.0 - ProjectProgressPercentage) * ProjectDurationDays / ProjectProgressPercentage, GETDATE())
        ELSE NULL
    END AS PredictedCompletionDate
FROM ProjectRankings;
GO

-- =============================================
-- 6. Create Indexed View for Performance
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_EmployeePerformanceIndexed]
WITH SCHEMABINDING
AS
SELECT 
    e.EmployeeID,
    e.DepartmentID,
    pr.OverallRating,
    pr.ReviewDate,
    COUNT_BIG(*) AS RecordCount
FROM dbo.Employees e
INNER JOIN dbo.PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
WHERE e.IsActive = 1
GROUP BY e.EmployeeID, e.DepartmentID, pr.OverallRating, pr.ReviewDate;
GO

-- Create unique clustered index for the indexed view
CREATE UNIQUE CLUSTERED INDEX [IX_vw_EmployeePerformanceIndexed] 
ON [dbo].[vw_EmployeePerformanceIndexed] (EmployeeID, ReviewDate, OverallRating);
GO

-- =============================================
-- 7. Create Materialized View for Dashboard
-- =============================================
CREATE OR ALTER VIEW [dbo].[vw_DashboardSummary]
AS
WITH DashboardData AS (
    SELECT 
        -- Overall metrics
        COUNT(DISTINCT e.EmployeeID) AS TotalEmployees,
        COUNT(DISTINCT CASE WHEN e.IsActive = 1 THEN e.EmployeeID END) AS ActiveEmployees,
        COUNT(DISTINCT d.DepartmentID) AS TotalDepartments,
        COUNT(DISTINCT p.ProjectID) AS TotalProjects,
        COUNT(DISTINCT CASE WHEN p.Status = 'Active' THEN p.ProjectID END) AS ActiveProjects,
        -- Salary metrics
        SUM(e.Salary) AS TotalPayroll,
        AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
        -- Performance metrics
        AVG(CAST(pr.OverallRating AS FLOAT)) AS AveragePerformanceRating,
        COUNT(DISTINCT pr.ReviewID) AS TotalPerformanceReviews,
        -- Recent activity
        COUNT(DISTINCT CASE WHEN YEAR(sh.ChangeDate) = YEAR(GETDATE()) THEN sh.SalaryHistoryID END) AS SalaryChangesThisYear,
        COUNT(DISTINCT CASE WHEN YEAR(pr.ReviewDate) = YEAR(GETDATE()) THEN pr.ReviewID END) AS ReviewsThisYear
    FROM Employees e
    LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
    LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
    LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
)
SELECT 
    TotalEmployees,
    ActiveEmployees,
    TotalDepartments,
    TotalProjects,
    ActiveProjects,
    TotalPayroll,
    AverageSalary,
    AveragePerformanceRating,
    TotalPerformanceReviews,
    SalaryChangesThisYear,
    ReviewsThisYear,
    -- Calculate percentages
    CASE 
        WHEN TotalEmployees > 0 
        THEN (CAST(ActiveEmployees AS FLOAT) / TotalEmployees) * 100.0
        ELSE 0
    END AS ActiveEmployeePercentage,
    CASE 
        WHEN TotalProjects > 0 
        THEN (CAST(ActiveProjects AS FLOAT) / TotalProjects) * 100.0
        ELSE 0
    END AS ActiveProjectPercentage,
    -- Calculate trends
    CASE 
        WHEN AveragePerformanceRating >= 4.0 THEN 'High Performance'
        WHEN AveragePerformanceRating >= 3.5 THEN 'Good Performance'
        WHEN AveragePerformanceRating >= 3.0 THEN 'Average Performance'
        ELSE 'Needs Improvement'
    END AS OverallPerformanceStatus,
    GETDATE() AS LastUpdated
FROM DashboardData;
GO

PRINT 'Reporting dashboard views created successfully!';
PRINT 'Views created: vw_EmployeeDashboard, vw_DepartmentDashboard, vw_PerformanceAnalytics, vw_SalaryAnalytics, vw_ProjectAnalytics, vw_EmployeePerformanceIndexed, vw_DashboardSummary';
PRINT 'Features demonstrated: Complex Views, CTEs, Window Functions, Indexed Views, Materialized Views, Cross-table Analytics';
