-- =============================================
-- Employee Management System - Performance Reviews & Reporting Procedures
-- Created: 2024
-- Description: Advanced stored procedures for performance management and reporting
--              Demonstrates window functions, recursive CTEs, and complex analytics
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 4. Performance Review Stored Procedures
-- =============================================

-- sp_CreatePerformanceReview: Create new performance review with validation
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CreatePerformanceReview]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_CreatePerformanceReview];
GO

CREATE PROCEDURE [dbo].[sp_CreatePerformanceReview]
    @EmployeeID INT,
    @ReviewerID INT,
    @ReviewDate DATE,
    @ReviewPeriodStart DATE,
    @ReviewPeriodEnd DATE,
    @OverallRating INT,
    @TechnicalSkills INT,
    @Communication INT,
    @Teamwork INT,
    @Leadership INT,
    @Comments NVARCHAR(MAX) = NULL,
    @Goals NVARCHAR(MAX) = NULL,
    @CreatedBy NVARCHAR(100) = 'SYSTEM',
    @ReviewID INT OUTPUT,
    @ErrorMessage NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate employee exists and is active
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID AND IsActive = 1)
        BEGIN
            SET @ErrorMessage = 'Employee not found or inactive';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate reviewer exists and is active
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @ReviewerID AND IsActive = 1)
        BEGIN
            SET @ErrorMessage = 'Reviewer not found or inactive';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate reviewer is not the same as employee
        IF @ReviewerID = @EmployeeID
        BEGIN
            SET @ErrorMessage = 'Reviewer cannot be the same as employee being reviewed';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate ratings (1-5 scale)
        IF @OverallRating < 1 OR @OverallRating > 5 OR
           @TechnicalSkills < 1 OR @TechnicalSkills > 5 OR
           @Communication < 1 OR @Communication > 5 OR
           @Teamwork < 1 OR @Teamwork > 5 OR
           @Leadership < 1 OR @Leadership > 5
        BEGIN
            SET @ErrorMessage = 'All ratings must be between 1 and 5';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate review period
        IF @ReviewPeriodEnd < @ReviewPeriodStart
        BEGIN
            SET @ErrorMessage = 'Review period end date must be after start date';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate review date
        IF @ReviewDate < @ReviewPeriodEnd
        BEGIN
            SET @ErrorMessage = 'Review date must be after review period end date';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check for overlapping review periods
        IF EXISTS (
            SELECT 1 FROM PerformanceReviews 
            WHERE EmployeeID = @EmployeeID
            AND (
                (@ReviewPeriodStart BETWEEN ReviewPeriodStart AND ReviewPeriodEnd) OR
                (@ReviewPeriodEnd BETWEEN ReviewPeriodStart AND ReviewPeriodEnd) OR
                (@ReviewPeriodStart <= ReviewPeriodStart AND @ReviewPeriodEnd >= ReviewPeriodEnd)
            )
        )
        BEGIN
            SET @ErrorMessage = 'Review period overlaps with existing review';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Insert performance review
        INSERT INTO PerformanceReviews (
            EmployeeID, ReviewerID, ReviewDate, ReviewPeriodStart, ReviewPeriodEnd,
            OverallRating, TechnicalSkills, Communication, Teamwork, Leadership,
            Comments, Goals
        )
        VALUES (
            @EmployeeID, @ReviewerID, @ReviewDate, @ReviewPeriodStart, @ReviewPeriodEnd,
            @OverallRating, @TechnicalSkills, @Communication, @Teamwork, @Leadership,
            @Comments, @Goals
        );
        
        SET @ReviewID = SCOPE_IDENTITY();
        
        -- Log audit trail
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('PerformanceReviews', @ReviewID, 'INSERT', NULL, 
                CONCAT('EmployeeID:', @EmployeeID, ';OverallRating:', @OverallRating), 
                @CreatedBy);
        
        COMMIT TRANSACTION;
        
        SET @ErrorMessage = NULL;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END
GO

-- sp_GetEmployeePerformanceHistory: Get performance history with trends
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetEmployeePerformanceHistory]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetEmployeePerformanceHistory];
GO

CREATE PROCEDURE [dbo].[sp_GetEmployeePerformanceHistory]
    @EmployeeID INT,
    @Years INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH PerformanceHistoryCTE AS (
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
            r.JobTitle AS ReviewerJobTitle,
            
            -- Calculate average of all ratings
            (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS AverageRating,
            
            -- Window functions for trend analysis
            LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) AS PreviousOverallRating,
            LAG(pr.TechnicalSkills) OVER (ORDER BY pr.ReviewDate) AS PreviousTechnicalSkills,
            LAG(pr.Communication) OVER (ORDER BY pr.ReviewDate) AS PreviousCommunication,
            LAG(pr.Teamwork) OVER (ORDER BY pr.ReviewDate) AS PreviousTeamwork,
            LAG(pr.Leadership) OVER (ORDER BY pr.ReviewDate) AS PreviousLeadership,
            
            -- Calculate improvement/decline
            pr.OverallRating - LAG(pr.OverallRating) OVER (ORDER BY pr.ReviewDate) AS OverallRatingChange,
            
            -- Ranking within employee's history
            ROW_NUMBER() OVER (ORDER BY pr.ReviewDate DESC) AS ReviewRank,
            
            -- Year-over-year comparison
            YEAR(pr.ReviewDate) AS ReviewYear
            
        FROM PerformanceReviews pr
        INNER JOIN Employees r ON pr.ReviewerID = r.EmployeeID
        WHERE pr.EmployeeID = @EmployeeID
        AND pr.ReviewDate >= DATEADD(YEAR, -@Years, GETDATE())
    )
    SELECT 
        ReviewID,
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
        ReviewerFirstName,
        ReviewerLastName,
        ReviewerJobTitle,
        AverageRating,
        PreviousOverallRating,
        PreviousTechnicalSkills,
        PreviousCommunication,
        PreviousTeamwork,
        PreviousLeadership,
        OverallRatingChange,
        ReviewRank,
        ReviewYear,
        
        -- Performance trend indicators
        CASE 
            WHEN OverallRatingChange > 0 THEN 'Improving'
            WHEN OverallRatingChange < 0 THEN 'Declining'
            ELSE 'Stable'
        END AS PerformanceTrend,
        
        -- Performance level classification
        CASE 
            WHEN OverallRating >= 4.5 THEN 'Excellent'
            WHEN OverallRating >= 3.5 THEN 'Good'
            WHEN OverallRating >= 2.5 THEN 'Satisfactory'
            WHEN OverallRating >= 1.5 THEN 'Needs Improvement'
            ELSE 'Unsatisfactory'
        END AS PerformanceLevel
        
    FROM PerformanceHistoryCTE
    ORDER BY ReviewDate DESC;
    
    -- Summary statistics
    SELECT 
        COUNT(*) AS TotalReviews,
        AVG(OverallRating) AS AverageOverallRating,
        AVG(TechnicalSkills) AS AverageTechnicalSkills,
        AVG(Communication) AS AverageCommunication,
        AVG(Teamwork) AS AverageTeamwork,
        AVG(Leadership) AS AverageLeadership,
        MIN(OverallRating) AS LowestOverallRating,
        MAX(OverallRating) AS HighestOverallRating,
        STDEV(OverallRating) AS OverallRatingStandardDeviation,
        
        -- Trend analysis
        AVG(CASE WHEN OverallRatingChange > 0 THEN OverallRatingChange ELSE 0 END) AS AverageImprovement,
        COUNT(CASE WHEN OverallRatingChange > 0 THEN 1 END) AS ImprovingReviews,
        COUNT(CASE WHEN OverallRatingChange < 0 THEN 1 END) AS DecliningReviews,
        COUNT(CASE WHEN OverallRatingChange = 0 THEN 1 END) AS StableReviews
        
    FROM PerformanceHistoryCTE;
    
END
GO

-- sp_CalculateAverageRating: Calculate average ratings by various criteria
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalculateAverageRating]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_CalculateAverageRating];
GO

CREATE PROCEDURE [dbo].[sp_CalculateAverageRating]
    @GroupBy NVARCHAR(20) = 'Employee', -- 'Employee', 'Department', 'JobTitle', 'Overall'
    @EmployeeID INT = NULL,
    @DepartmentID INT = NULL,
    @JobTitle NVARCHAR(100) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DateFilterStart DATE = ISNULL(@StartDate, DATEADD(YEAR, -1, GETDATE()));
    DECLARE @DateFilterEnd DATE = ISNULL(@EndDate, GETDATE());
    
    IF @GroupBy = 'Employee'
    BEGIN
        SELECT 
            e.EmployeeID,
            e.FullName,
            e.JobTitle,
            d.DepartmentName,
            COUNT(pr.ReviewID) AS ReviewCount,
            AVG(pr.OverallRating) AS AverageOverallRating,
            AVG(pr.TechnicalSkills) AS AverageTechnicalSkills,
            AVG(pr.Communication) AS AverageCommunication,
            AVG(pr.Teamwork) AS AverageTeamwork,
            AVG(pr.Leadership) AS AverageLeadership,
            AVG((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) AS AverageCompositeRating,
            MIN(pr.ReviewDate) AS FirstReviewDate,
            MAX(pr.ReviewDate) AS LastReviewDate
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            AND pr.ReviewDate BETWEEN @DateFilterStart AND @DateFilterEnd
        WHERE e.IsActive = 1
        AND (@EmployeeID IS NULL OR e.EmployeeID = @EmployeeID)
        GROUP BY e.EmployeeID, e.FullName, e.JobTitle, d.DepartmentName
        HAVING COUNT(pr.ReviewID) > 0
        ORDER BY AverageCompositeRating DESC;
    END
    ELSE IF @GroupBy = 'Department'
    BEGIN
        SELECT 
            d.DepartmentID,
            d.DepartmentName,
            COUNT(DISTINCT pr.EmployeeID) AS EmployeesReviewed,
            COUNT(pr.ReviewID) AS TotalReviews,
            AVG(pr.OverallRating) AS AverageOverallRating,
            AVG(pr.TechnicalSkills) AS AverageTechnicalSkills,
            AVG(pr.Communication) AS AverageCommunication,
            AVG(pr.Teamwork) AS AverageTeamwork,
            AVG(pr.Leadership) AS AverageLeadership,
            AVG((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) AS AverageCompositeRating,
            STDEV(pr.OverallRating) AS OverallRatingStandardDeviation
        FROM Departments d
        INNER JOIN Employees e ON d.DepartmentID = e.DepartmentID
        INNER JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            AND pr.ReviewDate BETWEEN @DateFilterStart AND @DateFilterEnd
        WHERE e.IsActive = 1
        AND (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
        GROUP BY d.DepartmentID, d.DepartmentName
        ORDER BY AverageCompositeRating DESC;
    END
    ELSE IF @GroupBy = 'JobTitle'
    BEGIN
        SELECT 
            e.JobTitle,
            COUNT(DISTINCT pr.EmployeeID) AS EmployeesReviewed,
            COUNT(pr.ReviewID) AS TotalReviews,
            AVG(pr.OverallRating) AS AverageOverallRating,
            AVG(pr.TechnicalSkills) AS AverageTechnicalSkills,
            AVG(pr.Communication) AS AverageCommunication,
            AVG(pr.Teamwork) AS AverageTeamwork,
            AVG(pr.Leadership) AS AverageLeadership,
            AVG((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) AS AverageCompositeRating
        FROM Employees e
        INNER JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            AND pr.ReviewDate BETWEEN @DateFilterStart AND @DateFilterEnd
        WHERE e.IsActive = 1
        AND (@JobTitle IS NULL OR e.JobTitle = @JobTitle)
        GROUP BY e.JobTitle
        ORDER BY AverageCompositeRating DESC;
    END
    ELSE IF @GroupBy = 'Overall'
    BEGIN
        SELECT 
            COUNT(DISTINCT pr.EmployeeID) AS TotalEmployeesReviewed,
            COUNT(pr.ReviewID) AS TotalReviews,
            AVG(pr.OverallRating) AS OverallAverageRating,
            AVG(pr.TechnicalSkills) AS OverallAverageTechnicalSkills,
            AVG(pr.Communication) AS OverallAverageCommunication,
            AVG(pr.Teamwork) AS OverallAverageTeamwork,
            AVG(pr.Leadership) AS OverallAverageLeadership,
            AVG((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) AS OverallAverageCompositeRating,
            STDEV(pr.OverallRating) AS OverallRatingStandardDeviation,
            MIN(pr.ReviewDate) AS EarliestReviewDate,
            MAX(pr.ReviewDate) AS LatestReviewDate
        FROM PerformanceReviews pr
        WHERE pr.ReviewDate BETWEEN @DateFilterStart AND @DateFilterEnd;
    END
END
GO

-- =============================================
-- 5. Reporting Stored Procedures
-- =============================================

-- sp_GetDepartmentStatistics: Comprehensive department statistics
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetDepartmentStatistics]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetDepartmentStatistics];
GO

CREATE PROCEDURE [dbo].[sp_GetDepartmentStatistics]
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH DepartmentStatsCTE AS (
        SELECT 
            d.DepartmentID,
            d.DepartmentName,
            d.Budget,
            d.Location,
            
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
            
            -- Experience statistics
            AVG(e.YearsOfService) AS AverageYearsOfService,
            MIN(e.YearsOfService) AS MinYearsOfService,
            MAX(e.YearsOfService) AS MaxYearsOfService,
            
            -- Project statistics
            COUNT(DISTINCT p.ProjectID) AS TotalProjects,
            COUNT(DISTINCT CASE WHEN p.Status = 'Active' THEN p.ProjectID END) AS ActiveProjects,
            COUNT(DISTINCT CASE WHEN p.Status = 'Completed' THEN p.ProjectID END) AS CompletedProjects,
            
            -- Performance statistics
            AVG(pr.OverallRating) AS AveragePerformanceRating,
            COUNT(DISTINCT pr.EmployeeID) AS EmployeesWithReviews
            
        FROM Departments d
        LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID
        LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
        LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            AND pr.ReviewDate >= DATEADD(YEAR, -1, GETDATE())
        WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
        GROUP BY d.DepartmentID, d.DepartmentName, d.Budget, d.Location
    )
    SELECT 
        DepartmentID,
        DepartmentName,
        Budget,
        Location,
        TotalEmployees,
        ActiveEmployees,
        InactiveEmployees,
        AverageSalary,
        MinSalary,
        MaxSalary,
        TotalSalaryCost,
        SalaryStandardDeviation,
        AverageYearsOfService,
        MinYearsOfService,
        MaxYearsOfService,
        TotalProjects,
        ActiveProjects,
        CompletedProjects,
        AveragePerformanceRating,
        EmployeesWithReviews,
        
        -- Calculated metrics
        CASE 
            WHEN Budget > 0 THEN (TotalSalaryCost / Budget) * 100
            ELSE 0 
        END AS BudgetUtilizationPercentage,
        
        CASE 
            WHEN TotalEmployees > 0 THEN (ActiveEmployees * 100.0 / TotalEmployees)
            ELSE 0 
        END AS EmployeeRetentionRate,
        
        CASE 
            WHEN TotalProjects > 0 THEN (CompletedProjects * 100.0 / TotalProjects)
            ELSE 0 
        END AS ProjectCompletionRate,
        
        -- Performance distribution
        CASE 
            WHEN AveragePerformanceRating >= 4.5 THEN 'Excellent'
            WHEN AveragePerformanceRating >= 3.5 THEN 'Good'
            WHEN AveragePerformanceRating >= 2.5 THEN 'Satisfactory'
            WHEN AveragePerformanceRating >= 1.5 THEN 'Needs Improvement'
            ELSE 'Unsatisfactory'
        END AS PerformanceLevel
        
    FROM DepartmentStatsCTE
    ORDER BY AveragePerformanceRating DESC, TotalSalaryCost DESC;
    
END
GO

-- sp_GetEmployeeHierarchy: Get organizational hierarchy using recursive CTE
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetEmployeeHierarchy]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetEmployeeHierarchy];
GO

CREATE PROCEDURE [dbo].[sp_GetEmployeeHierarchy]
    @RootEmployeeID INT = NULL,
    @DepartmentID INT = NULL,
    @MaxLevels INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH EmployeeHierarchyCTE AS (
        -- Base case: Top-level employees (no manager or specified root)
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
            NULL AS ManagerName,
            0 AS HierarchyLevel,
            CAST(e.FullName AS NVARCHAR(MAX)) AS HierarchyPath,
            CAST(e.EmployeeID AS NVARCHAR(MAX)) AS EmployeePath
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        WHERE e.IsActive = 1
        AND (
            (@RootEmployeeID IS NULL AND e.ManagerID IS NULL) OR
            (@RootEmployeeID IS NOT NULL AND e.EmployeeID = @RootEmployeeID)
        )
        AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
        
        UNION ALL
        
        -- Recursive case: Subordinates
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
            eh.FullName AS ManagerName,
            eh.HierarchyLevel + 1 AS HierarchyLevel,
            eh.HierarchyPath + ' > ' + e.FullName AS HierarchyPath,
            eh.EmployeePath + ',' + CAST(e.EmployeeID AS NVARCHAR(MAX)) AS EmployeePath
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        INNER JOIN EmployeeHierarchyCTE eh ON e.ManagerID = eh.EmployeeID
        WHERE e.IsActive = 1
        AND eh.HierarchyLevel < @MaxLevels
        AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
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
        ManagerName,
        DepartmentID,
        DepartmentName,
        HierarchyLevel,
        HierarchyPath,
        EmployeePath,
        
        -- Indentation for display
        REPLICATE('  ', HierarchyLevel) + FullName AS IndentedName,
        
        -- Subordinate count
        (SELECT COUNT(*) FROM Employees WHERE ManagerID = EmployeeHierarchyCTE.EmployeeID AND IsActive = 1) AS DirectReportsCount,
        
        -- Total team size (including all subordinates)
        (SELECT COUNT(*) FROM EmployeeHierarchyCTE eh2 
         WHERE eh2.EmployeePath LIKE '%' + CAST(EmployeeHierarchyCTE.EmployeeID AS NVARCHAR(MAX)) + '%'
         AND eh2.HierarchyLevel > EmployeeHierarchyCTE.HierarchyLevel) AS TotalTeamSize
        
    FROM EmployeeHierarchyCTE
    ORDER BY HierarchyLevel, DepartmentName, FullName;
    
END
GO

-- sp_GetTopPerformers: Get top performing employees based on various criteria
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetTopPerformers]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetTopPerformers];
GO

CREATE PROCEDURE [dbo].[sp_GetTopPerformers]
    @Criteria NVARCHAR(20) = 'Performance', -- 'Performance', 'Salary', 'Experience', 'Projects'
    @TopCount INT = 10,
    @DepartmentID INT = NULL,
    @JobTitle NVARCHAR(100) = NULL,
    @Years INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATE = DATEADD(YEAR, -@Years, GETDATE());
    
    IF @Criteria = 'Performance'
    BEGIN
        WITH PerformanceRankingCTE AS (
            SELECT 
                e.EmployeeID,
                e.FullName,
                e.JobTitle,
                d.DepartmentName,
                e.Salary,
                e.YearsOfService,
                AVG(pr.OverallRating) AS AverageOverallRating,
                AVG(pr.TechnicalSkills) AS AverageTechnicalSkills,
                AVG(pr.Communication) AS AverageCommunication,
                AVG(pr.Teamwork) AS AverageTeamwork,
                AVG(pr.Leadership) AS AverageLeadership,
                AVG((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) AS AverageCompositeRating,
                COUNT(pr.ReviewID) AS ReviewCount,
                ROW_NUMBER() OVER (ORDER BY AVG((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) DESC) AS PerformanceRank
            FROM Employees e
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            INNER JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            WHERE e.IsActive = 1
            AND pr.ReviewDate >= @StartDate
            AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
            AND (@JobTitle IS NULL OR e.JobTitle = @JobTitle)
            GROUP BY e.EmployeeID, e.FullName, e.JobTitle, d.DepartmentName, e.Salary, e.YearsOfService
            HAVING COUNT(pr.ReviewID) >= 1
        )
        SELECT TOP (@TopCount)
            EmployeeID,
            FullName,
            JobTitle,
            DepartmentName,
            Salary,
            YearsOfService,
            AverageOverallRating,
            AverageTechnicalSkills,
            AverageCommunication,
            AverageTeamwork,
            AverageLeadership,
            AverageCompositeRating,
            ReviewCount,
            PerformanceRank,
            'Top Performer' AS Category
        FROM PerformanceRankingCTE
        ORDER BY AverageCompositeRating DESC;
    END
    ELSE IF @Criteria = 'Salary'
    BEGIN
        SELECT TOP (@TopCount)
            e.EmployeeID,
            e.FullName,
            e.JobTitle,
            d.DepartmentName,
            e.Salary,
            e.YearsOfService,
            ROW_NUMBER() OVER (ORDER BY e.Salary DESC) AS SalaryRank,
            'Top Earner' AS Category
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        WHERE e.IsActive = 1
        AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
        AND (@JobTitle IS NULL OR e.JobTitle = @JobTitle)
        ORDER BY e.Salary DESC;
    END
    ELSE IF @Criteria = 'Experience'
    BEGIN
        SELECT TOP (@TopCount)
            e.EmployeeID,
            e.FullName,
            e.JobTitle,
            d.DepartmentName,
            e.Salary,
            e.YearsOfService,
            ROW_NUMBER() OVER (ORDER BY e.YearsOfService DESC) AS ExperienceRank,
            'Most Experienced' AS Category
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        WHERE e.IsActive = 1
        AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
        AND (@JobTitle IS NULL OR e.JobTitle = @JobTitle)
        ORDER BY e.YearsOfService DESC;
    END
    ELSE IF @Criteria = 'Projects'
    BEGIN
        WITH ProjectCountCTE AS (
            SELECT 
                e.EmployeeID,
                e.FullName,
                e.JobTitle,
                d.DepartmentName,
                e.Salary,
                e.YearsOfService,
                COUNT(DISTINCT ep.ProjectID) AS ProjectCount,
                SUM(ep.AllocationPercentage) AS TotalAllocation,
                ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ep.ProjectID) DESC) AS ProjectRank
            FROM Employees e
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            LEFT JOIN EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID
                AND (ep.EndDate IS NULL OR ep.EndDate >= @StartDate)
            WHERE e.IsActive = 1
            AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
            AND (@JobTitle IS NULL OR e.JobTitle = @JobTitle)
            GROUP BY e.EmployeeID, e.FullName, e.JobTitle, d.DepartmentName, e.Salary, e.YearsOfService
        )
        SELECT TOP (@TopCount)
            EmployeeID,
            FullName,
            JobTitle,
            DepartmentName,
            Salary,
            YearsOfService,
            ProjectCount,
            TotalAllocation,
            ProjectRank,
            'Most Active' AS Category
        FROM ProjectCountCTE
        ORDER BY ProjectCount DESC, TotalAllocation DESC;
    END
END
GO

PRINT 'Performance review and reporting stored procedures created successfully!';
PRINT 'Procedures created: sp_CreatePerformanceReview, sp_GetEmployeePerformanceHistory, sp_CalculateAverageRating';
PRINT 'Procedures created: sp_GetDepartmentStatistics, sp_GetEmployeeHierarchy, sp_GetTopPerformers';
