-- =============================================
-- Employee Management System - Salary & Project Management Procedures
-- Created: 2024
-- Description: Advanced stored procedures for salary operations and project management
--              Demonstrates complex calculations, CTEs, and business logic
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 2. Salary Management Stored Procedures
-- =============================================

-- sp_UpdateSalary: Update salary with history tracking and validation
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpdateSalary]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_UpdateSalary];
GO

CREATE PROCEDURE [dbo].[sp_UpdateSalary]
    @EmployeeID INT,
    @NewSalary DECIMAL(18,2),
    @ChangeReason NVARCHAR(200),
    @ApprovedBy INT,
    @UpdatedBy NVARCHAR(100) = 'SYSTEM',
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
        
        -- Validate new salary
        IF @NewSalary <= 0
        BEGIN
            SET @ErrorMessage = 'Salary must be greater than 0';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate approver exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @ApprovedBy AND IsActive = 1)
        BEGIN
            SET @ErrorMessage = 'Invalid approver';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Get current salary
        DECLARE @CurrentSalary DECIMAL(18,2);
        SELECT @CurrentSalary = Salary FROM Employees WHERE EmployeeID = @EmployeeID;
        
        -- Check if salary is actually changing
        IF @NewSalary = @CurrentSalary
        BEGIN
            SET @ErrorMessage = 'New salary is the same as current salary';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Calculate percentage change
        DECLARE @PercentageChange DECIMAL(5,2);
        SET @PercentageChange = ((@NewSalary - @CurrentSalary) / @CurrentSalary) * 100;
        
        -- Validate percentage change (max 50% increase, max 25% decrease)
        IF @PercentageChange > 50
        BEGIN
            SET @ErrorMessage = 'Salary increase cannot exceed 50%';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        IF @PercentageChange < -25
        BEGIN
            SET @ErrorMessage = 'Salary decrease cannot exceed 25%';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Update employee salary
        UPDATE Employees 
        SET Salary = @NewSalary, ModifiedDate = GETDATE()
        WHERE EmployeeID = @EmployeeID;
        
        -- Insert salary history
        INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
        VALUES (@EmployeeID, @CurrentSalary, @NewSalary, CAST(GETDATE() AS DATE), @ChangeReason, @ApprovedBy);
        
        -- Log audit trail
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @EmployeeID, 'UPDATE', 
                CAST(@CurrentSalary AS NVARCHAR(50)), 
                CAST(@NewSalary AS NVARCHAR(50)), 
                @UpdatedBy);
        
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

-- sp_CalculateAverageSalary: Calculate average salary by department, job title, or overall
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalculateAverageSalary]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_CalculateAverageSalary];
GO

CREATE PROCEDURE [dbo].[sp_CalculateAverageSalary]
    @GroupBy NVARCHAR(20) = 'Department', -- 'Department', 'JobTitle', 'Overall'
    @DepartmentID INT = NULL,
    @JobTitle NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @GroupBy = 'Department'
    BEGIN
        SELECT 
            d.DepartmentID,
            d.DepartmentName,
            COUNT(e.EmployeeID) AS EmployeeCount,
            AVG(e.Salary) AS AverageSalary,
            MIN(e.Salary) AS MinSalary,
            MAX(e.Salary) AS MaxSalary,
            SUM(e.Salary) AS TotalSalaryCost,
            STDEV(e.Salary) AS SalaryStandardDeviation,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) AS MedianSalary,
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.Salary) AS Q1Salary,
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.Salary) AS Q3Salary
        FROM Departments d
        LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
        WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
        GROUP BY d.DepartmentID, d.DepartmentName
        ORDER BY AverageSalary DESC;
    END
    ELSE IF @GroupBy = 'JobTitle'
    BEGIN
        SELECT 
            e.JobTitle,
            COUNT(e.EmployeeID) AS EmployeeCount,
            AVG(e.Salary) AS AverageSalary,
            MIN(e.Salary) AS MinSalary,
            MAX(e.Salary) AS MaxSalary,
            SUM(e.Salary) AS TotalSalaryCost,
            STDEV(e.Salary) AS SalaryStandardDeviation,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) AS MedianSalary
        FROM Employees e
        WHERE e.IsActive = 1
        AND (@JobTitle IS NULL OR e.JobTitle = @JobTitle)
        GROUP BY e.JobTitle
        ORDER BY AverageSalary DESC;
    END
    ELSE IF @GroupBy = 'Overall'
    BEGIN
        SELECT 
            COUNT(e.EmployeeID) AS TotalEmployees,
            AVG(e.Salary) AS OverallAverageSalary,
            MIN(e.Salary) AS OverallMinSalary,
            MAX(e.Salary) AS OverallMaxSalary,
            SUM(e.Salary) AS TotalSalaryCost,
            STDEV(e.Salary) AS OverallSalaryStandardDeviation,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.Salary) AS OverallMedianSalary
        FROM Employees e
        WHERE e.IsActive = 1;
    END
END
GO

-- sp_GetSalaryBudgetAnalysis: Department budget vs actual salary costs
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetSalaryBudgetAnalysis]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetSalaryBudgetAnalysis];
GO

CREATE PROCEDURE [dbo].[sp_GetSalaryBudgetAnalysis]
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH DepartmentSalaryAnalysis AS (
        SELECT 
            d.DepartmentID,
            d.DepartmentName,
            d.Budget,
            COUNT(e.EmployeeID) AS EmployeeCount,
            SUM(e.Salary) AS TotalSalaryCost,
            AVG(e.Salary) AS AverageSalary,
            CASE 
                WHEN d.Budget > 0 THEN (SUM(e.Salary) / d.Budget) * 100
                ELSE 0 
            END AS BudgetUtilizationPercentage,
            CASE 
                WHEN d.Budget > 0 THEN d.Budget - SUM(e.Salary)
                ELSE 0 
            END AS RemainingBudget
        FROM Departments d
        LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
        WHERE (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
        GROUP BY d.DepartmentID, d.DepartmentName, d.Budget
    )
    SELECT 
        DepartmentID,
        DepartmentName,
        Budget,
        EmployeeCount,
        TotalSalaryCost,
        AverageSalary,
        BudgetUtilizationPercentage,
        RemainingBudget,
        CASE 
            WHEN BudgetUtilizationPercentage > 100 THEN 'Over Budget'
            WHEN BudgetUtilizationPercentage > 90 THEN 'Near Budget Limit'
            WHEN BudgetUtilizationPercentage > 75 THEN 'High Utilization'
            ELSE 'Normal'
        END AS BudgetStatus
    FROM DepartmentSalaryAnalysis
    ORDER BY BudgetUtilizationPercentage DESC;
END
GO

-- =============================================
-- 3. Project Management Stored Procedures
-- =============================================

-- sp_AssignEmployeeToProject: Assign employee to project with validation
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_AssignEmployeeToProject]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_AssignEmployeeToProject];
GO

CREATE PROCEDURE [dbo].[sp_AssignEmployeeToProject]
    @EmployeeID INT,
    @ProjectID INT,
    @Role NVARCHAR(100),
    @AllocationPercentage INT,
    @StartDate DATE,
    @EndDate DATE = NULL,
    @AssignedBy NVARCHAR(100) = 'SYSTEM',
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
        
        -- Validate project exists and is active
        IF NOT EXISTS (SELECT 1 FROM Projects WHERE ProjectID = @ProjectID AND Status IN ('Planning', 'Active'))
        BEGIN
            SET @ErrorMessage = 'Project not found or not active';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate allocation percentage
        IF @AllocationPercentage < 0 OR @AllocationPercentage > 100
        BEGIN
            SET @ErrorMessage = 'Allocation percentage must be between 0 and 100';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate dates
        IF @StartDate < CAST(GETDATE() AS DATE)
        BEGIN
            SET @ErrorMessage = 'Start date cannot be in the past';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        IF @EndDate IS NOT NULL AND @EndDate <= @StartDate
        BEGIN
            SET @ErrorMessage = 'End date must be after start date';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check if employee is already assigned to this project
        IF EXISTS (SELECT 1 FROM EmployeeProjects WHERE EmployeeID = @EmployeeID AND ProjectID = @ProjectID)
        BEGIN
            SET @ErrorMessage = 'Employee is already assigned to this project';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check for overlapping assignments
        IF EXISTS (
            SELECT 1 FROM EmployeeProjects ep
            WHERE ep.EmployeeID = @EmployeeID
            AND ep.EndDate IS NULL
            AND ep.StartDate <= ISNULL(@EndDate, '2099-12-31')
            AND (ep.EndDate IS NULL OR ep.EndDate >= @StartDate)
        )
        BEGIN
            SET @ErrorMessage = 'Employee has overlapping project assignments';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Calculate total allocation for employee
        DECLARE @TotalAllocation INT;
        SELECT @TotalAllocation = ISNULL(SUM(AllocationPercentage), 0)
        FROM EmployeeProjects
        WHERE EmployeeID = @EmployeeID
        AND EndDate IS NULL
        AND StartDate <= ISNULL(@EndDate, '2099-12-31')
        AND (EndDate IS NULL OR EndDate >= @StartDate);
        
        -- Check if total allocation would exceed 100%
        IF (@TotalAllocation + @AllocationPercentage) > 100
        BEGIN
            SET @ErrorMessage = 'Total allocation would exceed 100%';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Insert assignment
        INSERT INTO EmployeeProjects (EmployeeID, ProjectID, Role, AllocationPercentage, StartDate, EndDate)
        VALUES (@EmployeeID, @ProjectID, @Role, @AllocationPercentage, @StartDate, @EndDate);
        
        -- Log audit trail
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('EmployeeProjects', SCOPE_IDENTITY(), 'INSERT', NULL, 
                CONCAT('EmployeeID:', @EmployeeID, ';ProjectID:', @ProjectID, ';Role:', @Role), 
                @AssignedBy);
        
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

-- sp_GetProjectResourceAllocation: Show all employees assigned to projects
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetProjectResourceAllocation]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetProjectResourceAllocation];
GO

CREATE PROCEDURE [dbo].[sp_GetProjectResourceAllocation]
    @ProjectID INT = NULL,
    @EmployeeID INT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH ProjectResourceCTE AS (
        SELECT 
            p.ProjectID,
            p.ProjectName,
            p.Status AS ProjectStatus,
            p.StartDate AS ProjectStartDate,
            p.EndDate AS ProjectEndDate,
            p.Budget AS ProjectBudget,
            d.DepartmentName,
            
            e.EmployeeID,
            e.FullName AS EmployeeName,
            e.JobTitle,
            e.Salary,
            ep.Role AS ProjectRole,
            ep.AllocationPercentage,
            ep.StartDate AS AssignmentStartDate,
            ep.EndDate AS AssignmentEndDate,
            
            -- Calculate monthly cost for this employee on this project
            (e.Salary * ep.AllocationPercentage / 100) / 12 AS MonthlyProjectCost,
            
            -- Calculate total project cost for this employee
            CASE 
                WHEN ep.EndDate IS NULL THEN 
                    (e.Salary * ep.AllocationPercentage / 100) * 
                    DATEDIFF(MONTH, ep.StartDate, ISNULL(p.EndDate, GETDATE())) / 12
                ELSE 
                    (e.Salary * ep.AllocationPercentage / 100) * 
                    DATEDIFF(MONTH, ep.StartDate, ep.EndDate) / 12
            END AS TotalProjectCost
            
        FROM Projects p
        INNER JOIN Departments d ON p.DepartmentID = d.DepartmentID
        INNER JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
        INNER JOIN Employees e ON ep.EmployeeID = e.EmployeeID
        WHERE e.IsActive = 1
        AND (@ProjectID IS NULL OR p.ProjectID = @ProjectID)
        AND (@EmployeeID IS NULL OR e.EmployeeID = @EmployeeID)
        AND (@Status IS NULL OR p.Status = @Status)
    )
    SELECT 
        ProjectID,
        ProjectName,
        ProjectStatus,
        ProjectStartDate,
        ProjectEndDate,
        ProjectBudget,
        DepartmentName,
        EmployeeID,
        EmployeeName,
        JobTitle,
        Salary,
        ProjectRole,
        AllocationPercentage,
        AssignmentStartDate,
        AssignmentEndDate,
        MonthlyProjectCost,
        TotalProjectCost,
        
        -- Calculate team size and total allocation for each project
        COUNT(*) OVER (PARTITION BY ProjectID) AS TeamSize,
        SUM(AllocationPercentage) OVER (PARTITION BY ProjectID) AS TotalAllocationPercentage,
        SUM(MonthlyProjectCost) OVER (PARTITION BY ProjectID) AS TotalMonthlyProjectCost,
        SUM(TotalProjectCost) OVER (PARTITION BY ProjectID) AS TotalProjectCost
        
    FROM ProjectResourceCTE
    ORDER BY ProjectName, EmployeeName;
    
    -- Summary by project
    SELECT 
        p.ProjectID,
        p.ProjectName,
        p.Status,
        COUNT(ep.EmployeeID) AS TeamSize,
        SUM(ep.AllocationPercentage) AS TotalAllocationPercentage,
        SUM((e.Salary * ep.AllocationPercentage / 100) / 12) AS TotalMonthlyCost,
        AVG(ep.AllocationPercentage) AS AverageAllocationPerEmployee,
        p.Budget,
        CASE 
            WHEN p.Budget > 0 THEN 
                (SUM((e.Salary * ep.AllocationPercentage / 100) / 12) * 12) / p.Budget * 100
            ELSE 0 
        END AS BudgetUtilizationPercentage
    FROM Projects p
    LEFT JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
    LEFT JOIN Employees e ON ep.EmployeeID = e.EmployeeID AND e.IsActive = 1
    WHERE (@ProjectID IS NULL OR p.ProjectID = @ProjectID)
    AND (@Status IS NULL OR p.Status = @Status)
    GROUP BY p.ProjectID, p.ProjectName, p.Status, p.Budget
    ORDER BY TotalMonthlyCost DESC;
    
END
GO

-- sp_CalculateProjectCost: Calculate total project cost based on employee allocations
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalculateProjectCost]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_CalculateProjectCost];
GO

CREATE PROCEDURE [dbo].[sp_CalculateProjectCost]
    @ProjectID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH ProjectCostCalculation AS (
        SELECT 
            p.ProjectID,
            p.ProjectName,
            p.Status,
            p.StartDate,
            p.EndDate,
            p.Budget AS PlannedBudget,
            
            -- Calculate actual costs
            SUM(
                CASE 
                    WHEN ep.EndDate IS NULL THEN 
                        (e.Salary * ep.AllocationPercentage / 100) * 
                        DATEDIFF(MONTH, ep.StartDate, ISNULL(p.EndDate, GETDATE())) / 12
                    ELSE 
                        (e.Salary * ep.AllocationPercentage / 100) * 
                        DATEDIFF(MONTH, ep.StartDate, ep.EndDate) / 12
                END
            ) AS ActualCost,
            
            -- Calculate monthly burn rate
            SUM((e.Salary * ep.AllocationPercentage / 100) / 12) AS MonthlyBurnRate,
            
            -- Team statistics
            COUNT(DISTINCT ep.EmployeeID) AS TeamSize,
            AVG(ep.AllocationPercentage) AS AverageAllocation,
            SUM(ep.AllocationPercentage) AS TotalAllocation
            
        FROM Projects p
        LEFT JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
        LEFT JOIN Employees e ON ep.EmployeeID = e.EmployeeID AND e.IsActive = 1
        WHERE (@ProjectID IS NULL OR p.ProjectID = @ProjectID)
        GROUP BY p.ProjectID, p.ProjectName, p.Status, p.StartDate, p.EndDate, p.Budget
    )
    SELECT 
        ProjectID,
        ProjectName,
        Status,
        StartDate,
        EndDate,
        PlannedBudget,
        ActualCost,
        MonthlyBurnRate,
        TeamSize,
        AverageAllocation,
        TotalAllocation,
        
        -- Cost analysis
        CASE 
            WHEN PlannedBudget > 0 THEN (ActualCost / PlannedBudget) * 100
            ELSE 0 
        END AS BudgetUtilizationPercentage,
        
        CASE 
            WHEN PlannedBudget > 0 THEN PlannedBudget - ActualCost
            ELSE 0 
        END AS RemainingBudget,
        
        -- Projected total cost if project continues at current burn rate
        CASE 
            WHEN EndDate IS NULL AND MonthlyBurnRate > 0 THEN 
                ActualCost + (MonthlyBurnRate * DATEDIFF(MONTH, GETDATE(), DATEADD(YEAR, 1, GETDATE())))
            ELSE ActualCost
        END AS ProjectedTotalCost
        
    FROM ProjectCostCalculation
    ORDER BY ActualCost DESC;
    
END
GO

PRINT 'Salary and Project management stored procedures created successfully!';
PRINT 'Procedures created: sp_UpdateSalary, sp_CalculateAverageSalary, sp_GetSalaryBudgetAnalysis';
PRINT 'Procedures created: sp_AssignEmployeeToProject, sp_GetProjectResourceAllocation, sp_CalculateProjectCost';
