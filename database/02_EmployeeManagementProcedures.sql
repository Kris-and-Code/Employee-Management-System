-- =============================================
-- Employee Management System - Stored Procedures
-- Created: 2024
-- Description: Advanced stored procedures demonstrating T-SQL best practices
--              Includes error handling, transactions, and complex business logic
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Employee Management Stored Procedures
-- =============================================

-- sp_CreateEmployee: Insert new employee with validation and audit logging
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CreateEmployee]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_CreateEmployee];
GO

CREATE PROCEDURE [dbo].[sp_CreateEmployee]
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20) = NULL,
    @DateOfBirth DATE = NULL,
    @HireDate DATE,
    @DepartmentID INT,
    @ManagerID INT = NULL,
    @JobTitle NVARCHAR(100),
    @Salary DECIMAL(18,2),
    @CreatedBy NVARCHAR(100) = 'SYSTEM',
    @EmployeeID INT OUTPUT,
    @ErrorMessage NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate input parameters
        IF @FirstName IS NULL OR LEN(TRIM(@FirstName)) = 0
        BEGIN
            SET @ErrorMessage = 'First name is required';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        IF @LastName IS NULL OR LEN(TRIM(@LastName)) = 0
        BEGIN
            SET @ErrorMessage = 'Last name is required';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        IF @Email IS NULL OR LEN(TRIM(@Email)) = 0
        BEGIN
            SET @ErrorMessage = 'Email is required';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check email format
        IF @Email NOT LIKE '%_@_%.__%'
        BEGIN
            SET @ErrorMessage = 'Invalid email format';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check if email already exists
        IF EXISTS (SELECT 1 FROM Employees WHERE Email = @Email)
        BEGIN
            SET @ErrorMessage = 'Email already exists';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate department exists
        IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID = @DepartmentID)
        BEGIN
            SET @ErrorMessage = 'Invalid department ID';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate manager exists and is active
        IF @ManagerID IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @ManagerID AND IsActive = 1)
            BEGIN
                SET @ErrorMessage = 'Invalid manager ID or manager is inactive';
                ROLLBACK TRANSACTION;
                RETURN -1;
            END
        END
        
        -- Validate salary
        IF @Salary <= 0
        BEGIN
            SET @ErrorMessage = 'Salary must be greater than 0';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validate hire date
        IF @HireDate > CAST(GETDATE() AS DATE)
        BEGIN
            SET @ErrorMessage = 'Hire date cannot be in the future';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Insert employee
        INSERT INTO Employees (
            FirstName, LastName, Email, Phone, DateOfBirth, 
            HireDate, DepartmentID, ManagerID, JobTitle, Salary
        )
        VALUES (
            @FirstName, @LastName, @Email, @Phone, @DateOfBirth,
            @HireDate, @DepartmentID, @ManagerID, @JobTitle, @Salary
        );
        
        SET @EmployeeID = SCOPE_IDENTITY();
        
        -- Insert into salary history
        INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
        VALUES (@EmployeeID, NULL, @Salary, @HireDate, 'Initial salary', NULL);
        
        -- Log audit trail
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @EmployeeID, 'INSERT', NULL, 
                CONCAT('FirstName:', @FirstName, ';LastName:', @LastName, ';Email:', @Email), 
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

-- sp_UpdateEmployee: Update employee with validation and audit logging
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpdateEmployee]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_UpdateEmployee];
GO

CREATE PROCEDURE [dbo].[sp_UpdateEmployee]
    @EmployeeID INT,
    @FirstName NVARCHAR(50) = NULL,
    @LastName NVARCHAR(50) = NULL,
    @Email NVARCHAR(100) = NULL,
    @Phone NVARCHAR(20) = NULL,
    @DateOfBirth DATE = NULL,
    @DepartmentID INT = NULL,
    @ManagerID INT = NULL,
    @JobTitle NVARCHAR(100) = NULL,
    @Salary DECIMAL(18,2) = NULL,
    @IsActive BIT = NULL,
    @UpdatedBy NVARCHAR(100) = 'SYSTEM',
    @ErrorMessage NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if employee exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @ErrorMessage = 'Employee not found';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Get current values for audit trail
        DECLARE @OldFirstName NVARCHAR(50), @OldLastName NVARCHAR(50), @OldEmail NVARCHAR(100),
                @OldPhone NVARCHAR(20), @OldDateOfBirth DATE, @OldDepartmentID INT,
                @OldManagerID INT, @OldJobTitle NVARCHAR(100), @OldSalary DECIMAL(18,2),
                @OldIsActive BIT;
                
        SELECT @OldFirstName = FirstName, @OldLastName = LastName, @OldEmail = Email,
               @OldPhone = Phone, @OldDateOfBirth = DateOfBirth, @OldDepartmentID = DepartmentID,
               @OldManagerID = ManagerID, @OldJobTitle = JobTitle, @OldSalary = Salary,
               @OldIsActive = IsActive
        FROM Employees WHERE EmployeeID = @EmployeeID;
        
        -- Validate email uniqueness if changing email
        IF @Email IS NOT NULL AND @Email != @OldEmail
        BEGIN
            IF EXISTS (SELECT 1 FROM Employees WHERE Email = @Email AND EmployeeID != @EmployeeID)
            BEGIN
                SET @ErrorMessage = 'Email already exists';
                ROLLBACK TRANSACTION;
                RETURN -1;
            END
        END
        
        -- Validate department if changing
        IF @DepartmentID IS NOT NULL AND @DepartmentID != @OldDepartmentID
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID = @DepartmentID)
            BEGIN
                SET @ErrorMessage = 'Invalid department ID';
                ROLLBACK TRANSACTION;
                RETURN -1;
            END
        END
        
        -- Validate manager if changing
        IF @ManagerID IS NOT NULL AND @ManagerID != @OldManagerID
        BEGIN
            IF @ManagerID = @EmployeeID
            BEGIN
                SET @ErrorMessage = 'Employee cannot be their own manager';
                ROLLBACK TRANSACTION;
                RETURN -1;
            END
            
            IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @ManagerID AND IsActive = 1)
            BEGIN
                SET @ErrorMessage = 'Invalid manager ID or manager is inactive';
                ROLLBACK TRANSACTION;
                RETURN -1;
            END
        END
        
        -- Update employee
        UPDATE Employees SET
            FirstName = ISNULL(@FirstName, FirstName),
            LastName = ISNULL(@LastName, LastName),
            Email = ISNULL(@Email, Email),
            Phone = ISNULL(@Phone, Phone),
            DateOfBirth = ISNULL(@DateOfBirth, DateOfBirth),
            DepartmentID = ISNULL(@DepartmentID, DepartmentID),
            ManagerID = ISNULL(@ManagerID, ManagerID),
            JobTitle = ISNULL(@JobTitle, JobTitle),
            Salary = ISNULL(@Salary, Salary),
            IsActive = ISNULL(@IsActive, IsActive),
            ModifiedDate = GETDATE()
        WHERE EmployeeID = @EmployeeID;
        
        -- Handle salary change
        IF @Salary IS NOT NULL AND @Salary != @OldSalary
        BEGIN
            INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
            VALUES (@EmployeeID, @OldSalary, @Salary, CAST(GETDATE() AS DATE), 'Salary update', NULL);
        END
        
        -- Log audit trail for each changed field
        IF @FirstName IS NOT NULL AND @FirstName != @OldFirstName
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @EmployeeID, 'UPDATE', @OldFirstName, @FirstName, @UpdatedBy);
        END
        
        IF @LastName IS NOT NULL AND @LastName != @OldLastName
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @EmployeeID, 'UPDATE', @OldLastName, @LastName, @UpdatedBy);
        END
        
        IF @Email IS NOT NULL AND @Email != @OldEmail
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @EmployeeID, 'UPDATE', @OldEmail, @Email, @UpdatedBy);
        END
        
        IF @Salary IS NOT NULL AND @Salary != @OldSalary
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @EmployeeID, 'UPDATE', CAST(@OldSalary AS NVARCHAR(50)), CAST(@Salary AS NVARCHAR(50)), @UpdatedBy);
        END
        
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

-- sp_DeleteEmployee: Soft delete employee (set IsActive = 0)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DeleteEmployee]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_DeleteEmployee];
GO

CREATE PROCEDURE [dbo].[sp_DeleteEmployee]
    @EmployeeID INT,
    @DeletedBy NVARCHAR(100) = 'SYSTEM',
    @ErrorMessage NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if employee exists and is active
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID AND IsActive = 1)
        BEGIN
            SET @ErrorMessage = 'Employee not found or already inactive';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check if employee is a manager of other employees
        IF EXISTS (SELECT 1 FROM Employees WHERE ManagerID = @EmployeeID AND IsActive = 1)
        BEGIN
            SET @ErrorMessage = 'Cannot delete employee who manages other employees';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check if employee is department head
        IF EXISTS (SELECT 1 FROM Departments WHERE DepartmentHead = @EmployeeID)
        BEGIN
            SET @ErrorMessage = 'Cannot delete employee who is a department head';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Soft delete employee
        UPDATE Employees 
        SET IsActive = 0, ModifiedDate = GETDATE()
        WHERE EmployeeID = @EmployeeID;
        
        -- Log audit trail
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @EmployeeID, 'UPDATE', '1', '0', @DeletedBy);
        
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

-- sp_GetEmployeeDetails: Get comprehensive employee information with all related data
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetEmployeeDetails]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetEmployeeDetails];
GO

CREATE PROCEDURE [dbo].[sp_GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Main employee information
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
        e.JobTitle,
        e.Salary,
        e.IsActive,
        e.CreatedDate,
        e.ModifiedDate,
        
        -- Department information
        d.DepartmentName,
        d.Location AS DepartmentLocation,
        d.Budget AS DepartmentBudget,
        
        -- Manager information
        m.FirstName AS ManagerFirstName,
        m.LastName AS ManagerLastName,
        m.Email AS ManagerEmail,
        m.JobTitle AS ManagerJobTitle,
        
        -- Department head information
        dh.FirstName AS DepartmentHeadFirstName,
        dh.LastName AS DepartmentHeadLastName,
        dh.Email AS DepartmentHeadEmail
        
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
    LEFT JOIN Employees dh ON d.DepartmentHead = dh.EmployeeID
    WHERE e.EmployeeID = @EmployeeID;
    
    -- Current projects
    SELECT 
        p.ProjectID,
        p.ProjectName,
        p.Description,
        p.StartDate,
        p.EndDate,
        p.Status,
        p.Budget,
        ep.Role,
        ep.AllocationPercentage,
        ep.StartDate AS AssignmentStartDate,
        ep.EndDate AS AssignmentEndDate
    FROM EmployeeProjects ep
    INNER JOIN Projects p ON ep.ProjectID = p.ProjectID
    WHERE ep.EmployeeID = @EmployeeID
    AND (ep.EndDate IS NULL OR ep.EndDate >= CAST(GETDATE() AS DATE))
    ORDER BY p.StartDate DESC;
    
    -- Performance reviews
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
        r.FirstName AS ReviewerFirstName,
        r.LastName AS ReviewerLastName,
        r.JobTitle AS ReviewerJobTitle
    FROM PerformanceReviews pr
    INNER JOIN Employees r ON pr.ReviewerID = r.EmployeeID
    WHERE pr.EmployeeID = @EmployeeID
    ORDER BY pr.ReviewDate DESC;
    
    -- Salary history
    SELECT 
        sh.SalaryHistoryID,
        sh.OldSalary,
        sh.NewSalary,
        sh.ChangeDate,
        sh.ChangeReason,
        sh.CreatedDate,
        a.FirstName AS ApprovedByFirstName,
        a.LastName AS ApprovedByLastName
    FROM SalaryHistory sh
    LEFT JOIN Employees a ON sh.ApprovedBy = a.EmployeeID
    WHERE sh.EmployeeID = @EmployeeID
    ORDER BY sh.ChangeDate DESC;
    
    -- Direct reports (subordinates)
    SELECT 
        s.EmployeeID,
        s.FirstName,
        s.LastName,
        s.FullName,
        s.Email,
        s.JobTitle,
        s.HireDate,
        s.YearsOfService,
        s.Salary,
        s.IsActive
    FROM Employees s
    WHERE s.ManagerID = @EmployeeID AND s.IsActive = 1
    ORDER BY s.HireDate DESC;
    
END
GO

PRINT 'Employee management stored procedures created successfully!';
PRINT 'Procedures created: sp_CreateEmployee, sp_UpdateEmployee, sp_DeleteEmployee, sp_GetEmployeeDetails';
