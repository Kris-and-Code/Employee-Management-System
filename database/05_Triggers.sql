-- =============================================
-- Employee Management System - Triggers
-- Created: 2024
-- Description: Advanced triggers for audit logging, validation, and business rules
--              Demonstrates trigger best practices and complex business logic
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Audit Trail Triggers
-- =============================================

-- Trigger for Employees table audit logging
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_AuditEmployees')
    DROP TRIGGER [dbo].[trg_AuditEmployees];
GO

CREATE TRIGGER [dbo].[trg_AuditEmployees]
ON [dbo].[Employees]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(10);
    DECLARE @RecordID INT;
    DECLARE @OldValue NVARCHAR(MAX);
    DECLARE @NewValue NVARCHAR(MAX);
    DECLARE @ChangedBy NVARCHAR(100) = SYSTEM_USER;
    
    -- Determine action type
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Action = 'DELETE';
    
    -- Handle INSERT operations
    IF @Action = 'INSERT'
    BEGIN
        SELECT @RecordID = EmployeeID FROM inserted;
        SELECT @NewValue = CONCAT(
            'FirstName:', FirstName, ';',
            'LastName:', LastName, ';',
            'Email:', Email, ';',
            'JobTitle:', JobTitle, ';',
            'Salary:', CAST(Salary AS NVARCHAR(50)), ';',
            'DepartmentID:', CAST(DepartmentID AS NVARCHAR(10)), ';',
            'IsActive:', CAST(IsActive AS NVARCHAR(5))
        ) FROM inserted;
        
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @RecordID, @Action, NULL, @NewValue, @ChangedBy);
    END
    
    -- Handle UPDATE operations
    ELSE IF @Action = 'UPDATE'
    BEGIN
        -- Get the employee ID (assuming single row updates)
        SELECT @RecordID = EmployeeID FROM inserted;
        
        -- Check each field for changes and log them
        IF UPDATE(FirstName)
        BEGIN
            SELECT @OldValue = FirstName FROM deleted;
            SELECT @NewValue = FirstName FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(LastName)
        BEGIN
            SELECT @OldValue = LastName FROM deleted;
            SELECT @NewValue = LastName FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(Email)
        BEGIN
            SELECT @OldValue = Email FROM deleted;
            SELECT @NewValue = Email FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(Salary)
        BEGIN
            SELECT @OldValue = CAST(Salary AS NVARCHAR(50)) FROM deleted;
            SELECT @NewValue = CAST(Salary AS NVARCHAR(50)) FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(DepartmentID)
        BEGIN
            SELECT @OldValue = CAST(DepartmentID AS NVARCHAR(10)) FROM deleted;
            SELECT @NewValue = CAST(DepartmentID AS NVARCHAR(10)) FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(ManagerID)
        BEGIN
            SELECT @OldValue = CAST(ManagerID AS NVARCHAR(10)) FROM deleted;
            SELECT @NewValue = CAST(ManagerID AS NVARCHAR(10)) FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(IsActive)
        BEGIN
            SELECT @OldValue = CAST(IsActive AS NVARCHAR(5)) FROM deleted;
            SELECT @NewValue = CAST(IsActive AS NVARCHAR(5)) FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Employees', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
    END
    
    -- Handle DELETE operations
    ELSE IF @Action = 'DELETE'
    BEGIN
        SELECT @RecordID = EmployeeID FROM deleted;
        SELECT @OldValue = CONCAT(
            'FirstName:', FirstName, ';',
            'LastName:', LastName, ';',
            'Email:', Email, ';',
            'JobTitle:', JobTitle, ';',
            'Salary:', CAST(Salary AS NVARCHAR(50))
        ) FROM deleted;
        
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @RecordID, @Action, @OldValue, NULL, @ChangedBy);
    END
END
GO

-- Trigger for Departments table audit logging
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_AuditDepartments')
    DROP TRIGGER [dbo].[trg_AuditDepartments];
GO

CREATE TRIGGER [dbo].[trg_AuditDepartments]
ON [dbo].[Departments]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(10);
    DECLARE @RecordID INT;
    DECLARE @OldValue NVARCHAR(MAX);
    DECLARE @NewValue NVARCHAR(MAX);
    DECLARE @ChangedBy NVARCHAR(100) = SYSTEM_USER;
    
    -- Determine action type
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Action = 'DELETE';
    
    -- Handle INSERT operations
    IF @Action = 'INSERT'
    BEGIN
        SELECT @RecordID = DepartmentID FROM inserted;
        SELECT @NewValue = CONCAT(
            'DepartmentName:', DepartmentName, ';',
            'Budget:', CAST(Budget AS NVARCHAR(50)), ';',
            'Location:', ISNULL(Location, 'NULL')
        ) FROM inserted;
        
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Departments', @RecordID, @Action, NULL, @NewValue, @ChangedBy);
    END
    
    -- Handle UPDATE operations
    ELSE IF @Action = 'UPDATE'
    BEGIN
        SELECT @RecordID = DepartmentID FROM inserted;
        
        IF UPDATE(DepartmentName)
        BEGIN
            SELECT @OldValue = DepartmentName FROM deleted;
            SELECT @NewValue = DepartmentName FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Departments', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(Budget)
        BEGIN
            SELECT @OldValue = CAST(Budget AS NVARCHAR(50)) FROM deleted;
            SELECT @NewValue = CAST(Budget AS NVARCHAR(50)) FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Departments', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
        
        IF UPDATE(DepartmentHead)
        BEGIN
            SELECT @OldValue = CAST(DepartmentHead AS NVARCHAR(10)) FROM deleted;
            SELECT @NewValue = CAST(DepartmentHead AS NVARCHAR(10)) FROM inserted;
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
            VALUES ('Departments', @RecordID, @Action, @OldValue, @NewValue, @ChangedBy);
        END
    END
    
    -- Handle DELETE operations
    ELSE IF @Action = 'DELETE'
    BEGIN
        SELECT @RecordID = DepartmentID FROM deleted;
        SELECT @OldValue = CONCAT(
            'DepartmentName:', DepartmentName, ';',
            'Budget:', CAST(Budget AS NVARCHAR(50))
        ) FROM deleted;
        
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Departments', @RecordID, @Action, @OldValue, NULL, @ChangedBy);
    END
END
GO

-- =============================================
-- 2. Salary History Trigger
-- =============================================

-- Trigger to automatically log salary changes
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_SalaryHistory')
    DROP TRIGGER [dbo].[trg_SalaryHistory];
GO

CREATE TRIGGER [dbo].[trg_SalaryHistory]
ON [dbo].[Employees]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only process if salary was updated
    IF UPDATE(Salary)
    BEGIN
        -- Insert salary history for each updated employee
        INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
        SELECT 
            i.EmployeeID,
            d.Salary AS OldSalary,
            i.Salary AS NewSalary,
            CAST(GETDATE() AS DATE) AS ChangeDate,
            'Automatic salary update' AS ChangeReason,
            NULL AS ApprovedBy
        FROM inserted i
        INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
        WHERE i.Salary != d.Salary; -- Only insert if salary actually changed
    END
END
GO

-- =============================================
-- 3. Manager Validation Trigger
-- =============================================

-- Trigger to validate manager assignments
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_ValidateManager')
    DROP TRIGGER [dbo].[trg_ValidateManager];
GO

CREATE TRIGGER [dbo].[trg_ValidateManager]
ON [dbo].[Employees]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(500);
    
    -- Check for circular reporting (employee cannot be their own manager)
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE ManagerID = EmployeeID
    )
    BEGIN
        SET @ErrorMessage = 'Employee cannot be their own manager';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Check for circular reporting chains (A manages B, B manages A)
    IF EXISTS (
        SELECT 1 FROM inserted i1
        INNER JOIN inserted i2 ON i1.EmployeeID = i2.ManagerID AND i2.EmployeeID = i1.ManagerID
        WHERE i1.EmployeeID != i2.EmployeeID
    )
    BEGIN
        SET @ErrorMessage = 'Circular reporting relationship detected';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Check for deeper circular reporting (A manages B, B manages C, C manages A)
    WITH ManagerChain AS (
        -- Base case: direct manager relationships
        SELECT 
            i.EmployeeID,
            i.ManagerID,
            1 AS Level,
            CAST(i.EmployeeID AS NVARCHAR(MAX)) AS ChainPath
        FROM inserted i
        WHERE i.ManagerID IS NOT NULL
        
        UNION ALL
        
        -- Recursive case: follow the chain
        SELECT 
            mc.EmployeeID,
            e.ManagerID,
            mc.Level + 1,
            mc.ChainPath + ',' + CAST(e.ManagerID AS NVARCHAR(MAX))
        FROM ManagerChain mc
        INNER JOIN Employees e ON mc.ManagerID = e.EmployeeID
        WHERE e.ManagerID IS NOT NULL
        AND mc.Level < 10 -- Prevent infinite recursion
        AND mc.ChainPath NOT LIKE '%' + CAST(e.ManagerID AS NVARCHAR(MAX)) + '%' -- Prevent cycles
    )
    -- Check if any chain leads back to the original employee
    IF EXISTS (
        SELECT 1 FROM ManagerChain mc
        INNER JOIN inserted i ON mc.EmployeeID = i.EmployeeID
        WHERE mc.ManagerID = i.EmployeeID
        AND mc.Level > 1
    )
    BEGIN
        SET @ErrorMessage = 'Circular reporting chain detected';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate that manager is active
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN Employees m ON i.ManagerID = m.EmployeeID
        WHERE m.IsActive = 0
    )
    BEGIN
        SET @ErrorMessage = 'Cannot assign inactive employee as manager';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate that manager is in the same or parent department
    -- (This is a business rule - managers should be in the same department or a parent department)
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN Employees m ON i.ManagerID = m.EmployeeID
        INNER JOIN Departments empDept ON i.DepartmentID = empDept.DepartmentID
        INNER JOIN Departments mgrDept ON m.DepartmentID = mgrDept.DepartmentID
        WHERE empDept.DepartmentID != mgrDept.DepartmentID
        -- Note: In a real scenario, you might have a department hierarchy table
        -- For now, we'll allow cross-department management but log it
    )
    BEGIN
        -- Log cross-department management (not an error, just a warning)
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        SELECT 
            'Employees',
            i.EmployeeID,
            'WARNING',
            'Cross-department management',
            CONCAT('Employee in dept ', i.DepartmentID, ' managed by employee in dept ', m.DepartmentID),
            SYSTEM_USER
        FROM inserted i
        INNER JOIN Employees m ON i.ManagerID = m.EmployeeID
        WHERE i.DepartmentID != m.DepartmentID;
    END
END
GO

-- =============================================
-- 4. Project Assignment Validation Trigger
-- =============================================

-- Trigger to validate project assignments
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_ValidateProjectAssignment')
    DROP TRIGGER [dbo].[trg_ValidateProjectAssignment];
GO

CREATE TRIGGER [dbo].[trg_ValidateProjectAssignment]
ON [dbo].[EmployeeProjects]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(500);
    
    -- Validate allocation percentage
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE AllocationPercentage < 0 OR AllocationPercentage > 100
    )
    BEGIN
        SET @ErrorMessage = 'Allocation percentage must be between 0 and 100';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Check for overlapping assignments for the same employee
    IF EXISTS (
        SELECT 1 FROM inserted i1
        INNER JOIN inserted i2 ON i1.EmployeeID = i2.EmployeeID AND i1.EmployeeProjectID != i2.EmployeeProjectID
        WHERE (
            (i1.StartDate BETWEEN i2.StartDate AND ISNULL(i2.EndDate, '2099-12-31')) OR
            (ISNULL(i1.EndDate, '2099-12-31') BETWEEN i2.StartDate AND ISNULL(i2.EndDate, '2099-12-31')) OR
            (i1.StartDate <= i2.StartDate AND ISNULL(i1.EndDate, '2099-12-31') >= ISNULL(i2.EndDate, '2099-12-31'))
        )
    )
    BEGIN
        SET @ErrorMessage = 'Employee has overlapping project assignments';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Check total allocation doesn't exceed 100% for any employee
    WITH EmployeeAllocation AS (
        SELECT 
            i.EmployeeID,
            SUM(i.AllocationPercentage) AS TotalAllocation
        FROM inserted i
        GROUP BY i.EmployeeID
    )
    IF EXISTS (
        SELECT 1 FROM EmployeeAllocation ea
        WHERE ea.TotalAllocation > 100
    )
    BEGIN
        SET @ErrorMessage = 'Total allocation exceeds 100% for one or more employees';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate that employee is active
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN Employees e ON i.EmployeeID = e.EmployeeID
        WHERE e.IsActive = 0
    )
    BEGIN
        SET @ErrorMessage = 'Cannot assign inactive employee to project';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate that project is active
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN Projects p ON i.ProjectID = p.ProjectID
        WHERE p.Status NOT IN ('Planning', 'Active')
    )
    BEGIN
        SET @ErrorMessage = 'Cannot assign employee to inactive or completed project';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
END
GO

-- =============================================
-- 5. Performance Review Validation Trigger
-- =============================================

-- Trigger to validate performance reviews
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_ValidatePerformanceReview')
    DROP TRIGGER [dbo].[trg_ValidatePerformanceReview];
GO

CREATE TRIGGER [dbo].[trg_ValidatePerformanceReview]
ON [dbo].[PerformanceReviews]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(500);
    
    -- Validate ratings are within range
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE OverallRating < 1 OR OverallRating > 5 OR
              TechnicalSkills < 1 OR TechnicalSkills > 5 OR
              Communication < 1 OR Communication > 5 OR
              Teamwork < 1 OR Teamwork > 5 OR
              Leadership < 1 OR Leadership > 5
    )
    BEGIN
        SET @ErrorMessage = 'All ratings must be between 1 and 5';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate reviewer is not the same as employee
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE EmployeeID = ReviewerID
    )
    BEGIN
        SET @ErrorMessage = 'Reviewer cannot be the same as employee being reviewed';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate review period dates
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE ReviewPeriodEnd < ReviewPeriodStart
    )
    BEGIN
        SET @ErrorMessage = 'Review period end date must be after start date';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate review date is after review period
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE ReviewDate < ReviewPeriodEnd
    )
    BEGIN
        SET @ErrorMessage = 'Review date must be after review period end date';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- Validate that employee and reviewer are active
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN Employees e ON i.EmployeeID = e.EmployeeID
        WHERE e.IsActive = 0
    )
    BEGIN
        SET @ErrorMessage = 'Cannot create review for inactive employee';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN Employees r ON i.ReviewerID = r.EmployeeID
        WHERE r.IsActive = 0
    )
    BEGIN
        SET @ErrorMessage = 'Cannot create review with inactive reviewer';
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
END
GO

PRINT 'Triggers created successfully!';
PRINT 'Triggers created: trg_AuditEmployees, trg_AuditDepartments, trg_SalaryHistory';
PRINT 'Triggers created: trg_ValidateManager, trg_ValidateProjectAssignment, trg_ValidatePerformanceReview';
PRINT 'All triggers include comprehensive validation and audit logging';
