-- =============================================
-- Performance Review Aggregations
-- Demonstrates advanced T-SQL features including:
-- - Complex aggregations with CTEs
-- - Window functions for ranking and percentiles
-- - Recursive CTEs for hierarchical analysis
-- - Statistical functions and calculations
-- - Performance optimization techniques
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Get Employee Performance Summary
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetEmployeePerformanceSummary]
    @EmployeeID INT = NULL,
    @DepartmentID INT = NULL,
    @Year INT = NULL,
    @IncludeHistory BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to calculate comprehensive performance metrics
        WITH PerformanceMetrics AS (
            SELECT 
                e.EmployeeID,
                e.FirstName,
                e.LastName,
                e.FullName,
                e.DepartmentID,
                d.DepartmentName,
                e.JobTitle,
                e.YearsOfService,
                pr.ReviewID,
                pr.ReviewDate,
                pr.ReviewPeriodStart,
                pr.ReviewPeriodEnd,
                pr.OverallRating,
                pr.TechnicalSkills,
                pr.Communication,
                pr.Teamwork,
                pr.Leadership,
                -- Calculate composite scores
                (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS AverageRating,
                -- Calculate weighted score (Overall rating has higher weight)
                (pr.OverallRating * 0.4 + pr.TechnicalSkills * 0.2 + pr.Communication * 0.2 + pr.Teamwork * 0.1 + pr.Leadership * 0.1) AS WeightedScore,
                -- Calculate performance category
                CASE 
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 4.5 THEN 'Exceeds Expectations'
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 4.0 THEN 'Above Expectations'
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 3.5 THEN 'Meets Expectations'
                    WHEN (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 >= 3.0 THEN 'Below Expectations'
                    ELSE 'Needs Improvement'
                END AS PerformanceCategory,
                pr.Comments,
                pr.Goals,
                pr.ReviewerID,
                r.FullName AS ReviewerName
            FROM Employees e
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            INNER JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            LEFT JOIN Employees r ON pr.ReviewerID = r.EmployeeID
            WHERE e.IsActive = 1
                AND (@EmployeeID IS NULL OR e.EmployeeID = @EmployeeID)
                AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
                AND (@IncludeHistory = 1 OR YEAR(pr.ReviewDate) = @Year)
        ),
        PerformanceTrends AS (
            SELECT 
                EmployeeID,
                FirstName,
                LastName,
                FullName,
                DepartmentName,
                JobTitle,
                YearsOfService,
                -- Current year performance
                MAX(CASE WHEN YEAR(ReviewDate) = @Year THEN AverageRating END) AS CurrentYearRating,
                MAX(CASE WHEN YEAR(ReviewDate) = @Year THEN WeightedScore END) AS CurrentYearWeightedScore,
                MAX(CASE WHEN YEAR(ReviewDate) = @Year THEN PerformanceCategory END) AS CurrentYearCategory,
                -- Previous year performance
                MAX(CASE WHEN YEAR(ReviewDate) = @Year - 1 THEN AverageRating END) AS PreviousYearRating,
                MAX(CASE WHEN YEAR(ReviewDate) = @Year - 1 THEN WeightedScore END) AS PreviousYearWeightedScore,
                MAX(CASE WHEN YEAR(ReviewDate) = @Year - 1 THEN PerformanceCategory END) AS PreviousYearCategory,
                -- Calculate improvement/decline
                MAX(CASE WHEN YEAR(ReviewDate) = @Year THEN AverageRating END) - 
                MAX(CASE WHEN YEAR(ReviewDate) = @Year - 1 THEN AverageRating END) AS RatingChange,
                -- Count of reviews
                COUNT(*) AS TotalReviews,
                COUNT(CASE WHEN YEAR(ReviewDate) = @Year THEN 1 END) AS ReviewsThisYear,
                COUNT(CASE WHEN YEAR(ReviewDate) = @Year - 1 THEN 1 END) AS ReviewsLastYear,
                -- Best and worst ratings
                MAX(AverageRating) AS BestRating,
                MIN(AverageRating) AS WorstRating,
                AVG(CAST(AverageRating AS FLOAT)) AS AverageRatingOverTime,
                STDEV(CAST(AverageRating AS FLOAT)) AS RatingStandardDeviation
            FROM PerformanceMetrics
            GROUP BY EmployeeID, FirstName, LastName, FullName, DepartmentName, JobTitle, YearsOfService
        ),
        DepartmentRankings AS (
            SELECT 
                pt.*,
                -- Department rankings using window functions
                ROW_NUMBER() OVER (PARTITION BY DepartmentName ORDER BY CurrentYearWeightedScore DESC) AS DepartmentRank,
                RANK() OVER (PARTITION BY DepartmentName ORDER BY CurrentYearWeightedScore DESC) AS DepartmentRankByRank,
                DENSE_RANK() OVER (PARTITION BY DepartmentName ORDER BY CurrentYearWeightedScore DESC) AS DepartmentRankByDenseRank,
                COUNT(*) OVER (PARTITION BY DepartmentName) AS DepartmentEmployeeCount,
                -- Percentile rankings
                PERCENT_RANK() OVER (PARTITION BY DepartmentName ORDER BY CurrentYearWeightedScore) AS DepartmentPercentile,
                CUME_DIST() OVER (PARTITION BY DepartmentName ORDER BY CurrentYearWeightedScore) AS DepartmentCumulativeDistribution,
                -- Overall rankings
                ROW_NUMBER() OVER (ORDER BY CurrentYearWeightedScore DESC) AS OverallRank,
                RANK() OVER (ORDER BY CurrentYearWeightedScore DESC) AS OverallRankByRank,
                PERCENT_RANK() OVER (ORDER BY CurrentYearWeightedScore) AS OverallPercentile,
                COUNT(*) OVER() AS TotalActiveEmployees
            FROM PerformanceTrends pt
        )
        SELECT 
            EmployeeID,
            FirstName,
            LastName,
            FullName,
            DepartmentName,
            JobTitle,
            YearsOfService,
            CurrentYearRating,
            CurrentYearWeightedScore,
            CurrentYearCategory,
            PreviousYearRating,
            PreviousYearWeightedScore,
            PreviousYearCategory,
            RatingChange,
            TotalReviews,
            ReviewsThisYear,
            ReviewsLastYear,
            BestRating,
            WorstRating,
            AverageRatingOverTime,
            RatingStandardDeviation,
            DepartmentRank,
            DepartmentRankByRank,
            DepartmentRankByDenseRank,
            DepartmentEmployeeCount,
            DepartmentPercentile,
            DepartmentCumulativeDistribution,
            OverallRank,
            OverallRankByRank,
            OverallPercentile,
            TotalActiveEmployees,
            -- Calculate performance trend
            CASE 
                WHEN RatingChange > 0.5 THEN 'Significantly Improved'
                WHEN RatingChange > 0.1 THEN 'Improved'
                WHEN RatingChange > -0.1 THEN 'Stable'
                WHEN RatingChange > -0.5 THEN 'Declined'
                ELSE 'Significantly Declined'
            END AS PerformanceTrend,
            -- Calculate consistency
            CASE 
                WHEN RatingStandardDeviation < 0.3 THEN 'Very Consistent'
                WHEN RatingStandardDeviation < 0.6 THEN 'Consistent'
                WHEN RatingStandardDeviation < 1.0 THEN 'Moderately Consistent'
                ELSE 'Inconsistent'
            END AS PerformanceConsistency
        FROM DepartmentRankings
        ORDER BY CurrentYearWeightedScore DESC;
        
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
-- 2. Get Department Performance Analytics
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetDepartmentPerformanceAnalytics]
    @DepartmentID INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to calculate department-level performance metrics
        WITH DepartmentPerformance AS (
            SELECT 
                d.DepartmentID,
                d.DepartmentName,
                COUNT(DISTINCT e.EmployeeID) AS TotalEmployees,
                COUNT(DISTINCT pr.EmployeeID) AS EmployeesWithReviews,
                COUNT(pr.ReviewID) AS TotalReviews,
                -- Average ratings
                AVG(CAST(pr.OverallRating AS FLOAT)) AS AvgOverallRating,
                AVG(CAST(pr.TechnicalSkills AS FLOAT)) AS AvgTechnicalSkills,
                AVG(CAST(pr.Communication AS FLOAT)) AS AvgCommunication,
                AVG(CAST(pr.Teamwork AS FLOAT)) AS AvgTeamwork,
                AVG(CAST(pr.Leadership AS FLOAT)) AS AvgLeadership,
                AVG(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS AvgCompositeRating,
                -- Rating distributions
                COUNT(CASE WHEN pr.OverallRating >= 4.5 THEN 1 END) AS ExceedsExpectations,
                COUNT(CASE WHEN pr.OverallRating >= 4.0 AND pr.OverallRating < 4.5 THEN 1 END) AS AboveExpectations,
                COUNT(CASE WHEN pr.OverallRating >= 3.5 AND pr.OverallRating < 4.0 THEN 1 END) AS MeetsExpectations,
                COUNT(CASE WHEN pr.OverallRating >= 3.0 AND pr.OverallRating < 3.5 THEN 1 END) AS BelowExpectations,
                COUNT(CASE WHEN pr.OverallRating < 3.0 THEN 1 END) AS NeedsImprovement,
                -- Statistical measures
                MIN(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS MinRating,
                MAX(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS MaxRating,
                STDEV(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS RatingStandardDeviation,
                -- Percentiles
                PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) OVER (PARTITION BY d.DepartmentID) AS Rating25thPercentile,
                PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) OVER (PARTITION BY d.DepartmentID) AS Rating50thPercentile,
                PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) OVER (PARTITION BY d.DepartmentID) AS Rating75thPercentile,
                PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) OVER (PARTITION BY d.DepartmentID) AS Rating90thPercentile
            FROM Departments d
            LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
            LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID AND YEAR(pr.ReviewDate) = @Year
            WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY d.DepartmentID, d.DepartmentName
        ),
        DepartmentTrends AS (
            SELECT 
                dp.DepartmentID,
                dp.DepartmentName,
                dp.TotalEmployees,
                dp.EmployeesWithReviews,
                dp.TotalReviews,
                dp.AvgOverallRating,
                dp.AvgTechnicalSkills,
                dp.AvgCommunication,
                dp.AvgTeamwork,
                dp.AvgLeadership,
                dp.AvgCompositeRating,
                dp.ExceedsExpectations,
                dp.AboveExpectations,
                dp.MeetsExpectations,
                dp.BelowExpectations,
                dp.NeedsImprovement,
                dp.MinRating,
                dp.MaxRating,
                dp.RatingStandardDeviation,
                dp.Rating25thPercentile,
                dp.Rating50thPercentile,
                dp.Rating75thPercentile,
                dp.Rating90thPercentile,
                -- Calculate review completion rate
                CASE 
                    WHEN dp.TotalEmployees > 0 THEN (CAST(dp.EmployeesWithReviews AS FLOAT) / dp.TotalEmployees) * 100.0
                    ELSE 0
                END AS ReviewCompletionRate,
                -- Calculate performance distribution percentages
                CASE 
                    WHEN dp.TotalReviews > 0 THEN (CAST(dp.ExceedsExpectations AS FLOAT) / dp.TotalReviews) * 100.0
                    ELSE 0
                END AS ExceedsExpectationsPercentage,
                CASE 
                    WHEN dp.TotalReviews > 0 THEN (CAST(dp.AboveExpectations AS FLOAT) / dp.TotalReviews) * 100.0
                    ELSE 0
                END AS AboveExpectationsPercentage,
                CASE 
                    WHEN dp.TotalReviews > 0 THEN (CAST(dp.MeetsExpectations AS FLOAT) / dp.TotalReviews) * 100.0
                    ELSE 0
                END AS MeetsExpectationsPercentage,
                CASE 
                    WHEN dp.TotalReviews > 0 THEN (CAST(dp.BelowExpectations AS FLOAT) / dp.TotalReviews) * 100.0
                    ELSE 0
                END AS BelowExpectationsPercentage,
                CASE 
                    WHEN dp.TotalReviews > 0 THEN (CAST(dp.NeedsImprovement AS FLOAT) / dp.TotalReviews) * 100.0
                    ELSE 0
                END AS NeedsImprovementPercentage,
                -- Calculate performance score
                CASE 
                    WHEN dp.TotalReviews > 0 THEN 
                        (dp.ExceedsExpectations * 5.0 + dp.AboveExpectations * 4.0 + dp.MeetsExpectations * 3.0 + dp.BelowExpectations * 2.0 + dp.NeedsImprovement * 1.0) / dp.TotalReviews
                    ELSE 0
                END AS PerformanceScore
            FROM DepartmentPerformance dp
        ),
        DepartmentRankings AS (
            SELECT 
                dt.*,
                -- Overall rankings
                ROW_NUMBER() OVER (ORDER BY dt.AvgCompositeRating DESC) AS OverallRank,
                RANK() OVER (ORDER BY dt.AvgCompositeRating DESC) AS OverallRankByRank,
                DENSE_RANK() OVER (ORDER BY dt.AvgCompositeRating DESC) AS OverallRankByDenseRank,
                PERCENT_RANK() OVER (ORDER BY dt.AvgCompositeRating) AS OverallPercentile,
                COUNT(*) OVER() AS TotalDepartments,
                -- Performance score rankings
                ROW_NUMBER() OVER (ORDER BY dt.PerformanceScore DESC) AS PerformanceScoreRank,
                RANK() OVER (ORDER BY dt.PerformanceScore DESC) AS PerformanceScoreRankByRank,
                -- Review completion rankings
                ROW_NUMBER() OVER (ORDER BY dt.ReviewCompletionRate DESC) AS ReviewCompletionRank,
                RANK() OVER (ORDER BY dt.ReviewCompletionRate DESC) AS ReviewCompletionRankByRank
            FROM DepartmentTrends dt
        )
        SELECT 
            DepartmentID,
            DepartmentName,
            TotalEmployees,
            EmployeesWithReviews,
            TotalReviews,
            AvgOverallRating,
            AvgTechnicalSkills,
            AvgCommunication,
            AvgTeamwork,
            AvgLeadership,
            AvgCompositeRating,
            ExceedsExpectations,
            AboveExpectations,
            MeetsExpectations,
            BelowExpectations,
            NeedsImprovement,
            MinRating,
            MaxRating,
            RatingStandardDeviation,
            Rating25thPercentile,
            Rating50thPercentile,
            Rating75thPercentile,
            Rating90thPercentile,
            ReviewCompletionRate,
            ExceedsExpectationsPercentage,
            AboveExpectationsPercentage,
            MeetsExpectationsPercentage,
            BelowExpectationsPercentage,
            NeedsImprovementPercentage,
            PerformanceScore,
            OverallRank,
            OverallRankByRank,
            OverallRankByDenseRank,
            OverallPercentile,
            TotalDepartments,
            PerformanceScoreRank,
            PerformanceScoreRankByRank,
            ReviewCompletionRank,
            ReviewCompletionRankByRank,
            -- Calculate performance grade
            CASE 
                WHEN AvgCompositeRating >= 4.5 THEN 'A+'
                WHEN AvgCompositeRating >= 4.0 THEN 'A'
                WHEN AvgCompositeRating >= 3.5 THEN 'B+'
                WHEN AvgCompositeRating >= 3.0 THEN 'B'
                WHEN AvgCompositeRating >= 2.5 THEN 'C+'
                WHEN AvgCompositeRating >= 2.0 THEN 'C'
                ELSE 'D'
            END AS PerformanceGrade,
            -- Calculate consistency rating
            CASE 
                WHEN RatingStandardDeviation < 0.3 THEN 'Very Consistent'
                WHEN RatingStandardDeviation < 0.6 THEN 'Consistent'
                WHEN RatingStandardDeviation < 1.0 THEN 'Moderately Consistent'
                ELSE 'Inconsistent'
            END AS ConsistencyRating,
            @Year AS AnalysisYear
        FROM DepartmentRankings
        ORDER BY AvgCompositeRating DESC;
        
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
-- 3. Get Performance Review Trends
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetPerformanceReviewTrends]
    @StartYear INT = NULL,
    @EndYear INT = NULL,
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to last 5 years if not specified
    IF @StartYear IS NULL
        SET @StartYear = YEAR(GETDATE()) - 4;
    IF @EndYear IS NULL
        SET @EndYear = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to calculate year-over-year trends
        WITH YearlyTrends AS (
            SELECT 
                YEAR(pr.ReviewDate) AS ReviewYear,
                d.DepartmentID,
                d.DepartmentName,
                COUNT(pr.ReviewID) AS TotalReviews,
                COUNT(DISTINCT pr.EmployeeID) AS EmployeesReviewed,
                -- Average ratings by year
                AVG(CAST(pr.OverallRating AS FLOAT)) AS AvgOverallRating,
                AVG(CAST(pr.TechnicalSkills AS FLOAT)) AS AvgTechnicalSkills,
                AVG(CAST(pr.Communication AS FLOAT)) AS AvgCommunication,
                AVG(CAST(pr.Teamwork AS FLOAT)) AS AvgTeamwork,
                AVG(CAST(pr.Leadership AS FLOAT)) AS AvgLeadership,
                AVG(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS AvgCompositeRating,
                -- Rating distributions
                COUNT(CASE WHEN pr.OverallRating >= 4.5 THEN 1 END) AS ExceedsExpectations,
                COUNT(CASE WHEN pr.OverallRating >= 4.0 AND pr.OverallRating < 4.5 THEN 1 END) AS AboveExpectations,
                COUNT(CASE WHEN pr.OverallRating >= 3.5 AND pr.OverallRating < 4.0 THEN 1 END) AS MeetsExpectations,
                COUNT(CASE WHEN pr.OverallRating >= 3.0 AND pr.OverallRating < 3.5 THEN 1 END) AS BelowExpectations,
                COUNT(CASE WHEN pr.OverallRating < 3.0 THEN 1 END) AS NeedsImprovement,
                -- Statistical measures
                MIN(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS MinRating,
                MAX(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS MaxRating,
                STDEV(CAST((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS FLOAT)) AS RatingStandardDeviation
            FROM PerformanceReviews pr
            INNER JOIN Employees e ON pr.EmployeeID = e.EmployeeID
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            WHERE YEAR(pr.ReviewDate) BETWEEN @StartYear AND @EndYear
                AND (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            GROUP BY YEAR(pr.ReviewDate), d.DepartmentID, d.DepartmentName
        ),
        TrendAnalysis AS (
            SELECT 
                *,
                -- Calculate year-over-year changes
                LAG(AvgCompositeRating) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear) AS PreviousYearRating,
                LAG(TotalReviews) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear) AS PreviousYearReviews,
                LAG(EmployeesReviewed) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear) AS PreviousYearEmployees,
                -- Calculate percentage changes
                CASE 
                    WHEN LAG(AvgCompositeRating) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear) > 0 
                    THEN ((AvgCompositeRating - LAG(AvgCompositeRating) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear)) / LAG(AvgCompositeRating) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear)) * 100.0
                    ELSE NULL
                END AS RatingChangePercentage,
                CASE 
                    WHEN LAG(TotalReviews) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear) > 0 
                    THEN ((TotalReviews - LAG(TotalReviews) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear)) / CAST(LAG(TotalReviews) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear) AS FLOAT)) * 100.0
                    ELSE NULL
                END AS ReviewCountChangePercentage,
                -- Calculate running averages
                AVG(AvgCompositeRating) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeYearMovingAverage,
                AVG(AvgCompositeRating) OVER (PARTITION BY DepartmentID ORDER BY ReviewYear ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS FiveYearMovingAverage
            FROM YearlyTrends
        )
        SELECT 
            ReviewYear,
            DepartmentID,
            DepartmentName,
            TotalReviews,
            EmployeesReviewed,
            AvgOverallRating,
            AvgTechnicalSkills,
            AvgCommunication,
            AvgTeamwork,
            AvgLeadership,
            AvgCompositeRating,
            ExceedsExpectations,
            AboveExpectations,
            MeetsExpectations,
            BelowExpectations,
            NeedsImprovement,
            MinRating,
            MaxRating,
            RatingStandardDeviation,
            PreviousYearRating,
            PreviousYearReviews,
            PreviousYearEmployees,
            RatingChangePercentage,
            ReviewCountChangePercentage,
            ThreeYearMovingAverage,
            FiveYearMovingAverage,
            -- Calculate trend direction
            CASE 
                WHEN RatingChangePercentage > 5 THEN 'Significantly Improving'
                WHEN RatingChangePercentage > 1 THEN 'Improving'
                WHEN RatingChangePercentage > -1 THEN 'Stable'
                WHEN RatingChangePercentage > -5 THEN 'Declining'
                ELSE 'Significantly Declining'
            END AS TrendDirection,
            -- Calculate performance grade
            CASE 
                WHEN AvgCompositeRating >= 4.5 THEN 'A+'
                WHEN AvgCompositeRating >= 4.0 THEN 'A'
                WHEN AvgCompositeRating >= 3.5 THEN 'B+'
                WHEN AvgCompositeRating >= 3.0 THEN 'B'
                WHEN AvgCompositeRating >= 2.5 THEN 'C+'
                WHEN AvgCompositeRating >= 2.0 THEN 'C'
                ELSE 'D'
            END AS PerformanceGrade
        FROM TrendAnalysis
        ORDER BY DepartmentName, ReviewYear;
        
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
-- 4. Get Top Performers Analysis
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetTopPerformersAnalysis]
    @TopCount INT = 10,
    @DepartmentID INT = NULL,
    @Year INT = NULL,
    @IncludeAllYears BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current year if not specified
    IF @Year IS NULL
        SET @Year = YEAR(GETDATE());
    
    BEGIN TRY
        -- Use CTE to identify top performers
        WITH PerformanceScores AS (
            SELECT 
                e.EmployeeID,
                e.FirstName,
                e.LastName,
                e.FullName,
                e.DepartmentID,
                d.DepartmentName,
                e.JobTitle,
                e.YearsOfService,
                e.Salary,
                pr.ReviewID,
                pr.ReviewDate,
                pr.OverallRating,
                pr.TechnicalSkills,
                pr.Communication,
                pr.Teamwork,
                pr.Leadership,
                -- Calculate various performance scores
                (pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0 AS AverageRating,
                (pr.OverallRating * 0.4 + pr.TechnicalSkills * 0.2 + pr.Communication * 0.2 + pr.Teamwork * 0.1 + pr.Leadership * 0.1) AS WeightedScore,
                -- Calculate performance index (rating relative to salary)
                CASE 
                    WHEN e.Salary > 0 THEN ((pr.OverallRating + pr.TechnicalSkills + pr.Communication + pr.Teamwork + pr.Leadership) / 5.0) / (e.Salary / 10000.0)
                    ELSE 0
                END AS PerformanceIndex,
                -- Calculate improvement score
                CASE 
                    WHEN pr.OverallRating >= 4.5 THEN 5.0
                    WHEN pr.OverallRating >= 4.0 THEN 4.0
                    WHEN pr.OverallRating >= 3.5 THEN 3.0
                    WHEN pr.OverallRating >= 3.0 THEN 2.0
                    ELSE 1.0
                END AS ImprovementScore,
                pr.Comments,
                pr.Goals,
                pr.ReviewerID,
                r.FullName AS ReviewerName
            FROM Employees e
            INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
            INNER JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
            LEFT JOIN Employees r ON pr.ReviewerID = r.EmployeeID
            WHERE e.IsActive = 1
                AND (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
                AND (@IncludeAllYears = 1 OR YEAR(pr.ReviewDate) = @Year)
        ),
        TopPerformers AS (
            SELECT 
                EmployeeID,
                FirstName,
                LastName,
                FullName,
                DepartmentID,
                DepartmentName,
                JobTitle,
                YearsOfService,
                Salary,
                -- Get latest review data
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN OverallRating END) AS LatestOverallRating,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN TechnicalSkills END) AS LatestTechnicalSkills,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN Communication END) AS LatestCommunication,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN Teamwork END) AS LatestTeamwork,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN Leadership END) AS LatestLeadership,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN AverageRating END) AS LatestAverageRating,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN WeightedScore END) AS LatestWeightedScore,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN PerformanceIndex END) AS LatestPerformanceIndex,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN ImprovementScore END) AS LatestImprovementScore,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN Comments END) AS LatestComments,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN Goals END) AS LatestGoals,
                MAX(CASE WHEN ReviewDate = (SELECT MAX(ReviewDate) FROM PerformanceScores ps2 WHERE ps2.EmployeeID = ps.EmployeeID) THEN ReviewerName END) AS LatestReviewerName,
                -- Calculate aggregate scores
                AVG(CAST(AverageRating AS FLOAT)) AS AverageRatingOverTime,
                AVG(CAST(WeightedScore AS FLOAT)) AS AverageWeightedScoreOverTime,
                AVG(CAST(PerformanceIndex AS FLOAT)) AS AveragePerformanceIndexOverTime,
                COUNT(*) AS TotalReviews,
                MIN(AverageRating) AS MinRating,
                MAX(AverageRating) AS MaxRating,
                STDEV(CAST(AverageRating AS FLOAT)) AS RatingStandardDeviation,
                -- Calculate consistency score
                CASE 
                    WHEN STDEV(CAST(AverageRating AS FLOAT)) < 0.3 THEN 5.0
                    WHEN STDEV(CAST(AverageRating AS FLOAT)) < 0.6 THEN 4.0
                    WHEN STDEV(CAST(AverageRating AS FLOAT)) < 1.0 THEN 3.0
                    ELSE 2.0
                END AS ConsistencyScore
            FROM PerformanceScores ps
            GROUP BY EmployeeID, FirstName, LastName, FullName, DepartmentID, DepartmentName, JobTitle, YearsOfService, Salary
        ),
        RankedPerformers AS (
            SELECT 
                *,
                -- Calculate composite score for ranking
                (LatestWeightedScore * 0.4 + AverageWeightedScoreOverTime * 0.3 + ConsistencyScore * 0.2 + LatestPerformanceIndex * 0.1) AS CompositeScore,
                -- Rankings
                ROW_NUMBER() OVER (ORDER BY LatestWeightedScore DESC) AS WeightedScoreRank,
                ROW_NUMBER() OVER (ORDER BY AverageWeightedScoreOverTime DESC) AS AverageScoreRank,
                ROW_NUMBER() OVER (ORDER BY ConsistencyScore DESC) AS ConsistencyRank,
                ROW_NUMBER() OVER (ORDER BY LatestPerformanceIndex DESC) AS PerformanceIndexRank,
                ROW_NUMBER() OVER (ORDER BY (LatestWeightedScore * 0.4 + AverageWeightedScoreOverTime * 0.3 + ConsistencyScore * 0.2 + LatestPerformanceIndex * 0.1) DESC) AS CompositeRank
            FROM TopPerformers
        )
        SELECT TOP (@TopCount)
            EmployeeID,
            FirstName,
            LastName,
            FullName,
            DepartmentName,
            JobTitle,
            YearsOfService,
            Salary,
            LatestOverallRating,
            LatestTechnicalSkills,
            LatestCommunication,
            LatestTeamwork,
            LatestLeadership,
            LatestAverageRating,
            LatestWeightedScore,
            LatestPerformanceIndex,
            LatestImprovementScore,
            LatestComments,
            LatestGoals,
            LatestReviewerName,
            AverageRatingOverTime,
            AverageWeightedScoreOverTime,
            AveragePerformanceIndexOverTime,
            TotalReviews,
            MinRating,
            MaxRating,
            RatingStandardDeviation,
            ConsistencyScore,
            CompositeScore,
            WeightedScoreRank,
            AverageScoreRank,
            ConsistencyRank,
            PerformanceIndexRank,
            CompositeRank,
            -- Calculate performance category
            CASE 
                WHEN LatestAverageRating >= 4.5 THEN 'Exceptional'
                WHEN LatestAverageRating >= 4.0 THEN 'Outstanding'
                WHEN LatestAverageRating >= 3.5 THEN 'Exceeds Expectations'
                WHEN LatestAverageRating >= 3.0 THEN 'Meets Expectations'
                ELSE 'Below Expectations'
            END AS PerformanceCategory,
            -- Calculate potential for promotion
            CASE 
                WHEN LatestAverageRating >= 4.5 AND YearsOfService >= 2 THEN 'Ready for Promotion'
                WHEN LatestAverageRating >= 4.0 AND YearsOfService >= 3 THEN 'Consider for Promotion'
                WHEN LatestAverageRating >= 3.5 AND YearsOfService >= 5 THEN 'Future Consideration'
                ELSE 'Continue Development'
            END AS PromotionPotential
        FROM RankedPerformers
        ORDER BY CompositeScore DESC;
        
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
-- 5. Create Performance Review
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CreatePerformanceReview]
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
    @CreatedBy NVARCHAR(100) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate inputs
        IF @OverallRating < 1 OR @OverallRating > 5
        BEGIN
            RAISERROR('Overall rating must be between 1 and 5', 16, 1);
            RETURN;
        END
        
        IF @TechnicalSkills < 1 OR @TechnicalSkills > 5
        BEGIN
            RAISERROR('Technical skills rating must be between 1 and 5', 16, 1);
            RETURN;
        END
        
        IF @Communication < 1 OR @Communication > 5
        BEGIN
            RAISERROR('Communication rating must be between 1 and 5', 16, 1);
            RETURN;
        END
        
        IF @Teamwork < 1 OR @Teamwork > 5
        BEGIN
            RAISERROR('Teamwork rating must be between 1 and 5', 16, 1);
            RETURN;
        END
        
        IF @Leadership < 1 OR @Leadership > 5
        BEGIN
            RAISERROR('Leadership rating must be between 1 and 5', 16, 1);
            RETURN;
        END
        
        -- Check if employee exists and is active
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID AND IsActive = 1)
        BEGIN
            RAISERROR('Employee does not exist or is inactive', 16, 1);
            RETURN;
        END
        
        -- Check if reviewer exists and is active
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @ReviewerID AND IsActive = 1)
        BEGIN
            RAISERROR('Reviewer does not exist or is inactive', 16, 1);
            RETURN;
        END
        
        -- Check if reviewer is not the same as employee
        IF @ReviewerID = @EmployeeID
        BEGIN
            RAISERROR('Reviewer cannot be the same as the employee being reviewed', 16, 1);
            RETURN;
        END
        
        -- Validate review period
        IF @ReviewPeriodEnd < @ReviewPeriodStart
        BEGIN
            RAISERROR('Review period end date must be after start date', 16, 1);
            RETURN;
        END
        
        -- Insert performance review
        DECLARE @ReviewID INT;
        
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
        
        -- Log audit
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('PerformanceReviews', @ReviewID, 'INSERT', NULL, 
                CONCAT('Performance Review for Employee ID: ', @EmployeeID, ' - Overall Rating: ', @OverallRating), @CreatedBy);
        
        COMMIT TRANSACTION;
        
        -- Return the created review with calculated metrics
        SELECT 
            pr.ReviewID,
            pr.EmployeeID,
            e.FullName AS EmployeeName,
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
            END AS PerformanceCategory
        FROM PerformanceReviews pr
        INNER JOIN Employees e ON pr.EmployeeID = e.EmployeeID
        INNER JOIN Employees r ON pr.ReviewerID = r.EmployeeID
        WHERE pr.ReviewID = @ReviewID;
        
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

PRINT 'Performance review aggregation stored procedures created successfully!';
PRINT 'Procedures created: sp_GetEmployeePerformanceSummary, sp_GetDepartmentPerformanceAnalytics, sp_GetPerformanceReviewTrends, sp_GetTopPerformersAnalysis, sp_CreatePerformanceReview';
PRINT 'Features demonstrated: Complex Aggregations, Window Functions, Statistical Calculations, Trend Analysis, Ranking Systems';
