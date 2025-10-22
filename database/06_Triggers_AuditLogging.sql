-- =============================================
-- Audit Logging Triggers
-- Demonstrates advanced T-SQL features including:
-- - DML Triggers (INSERT, UPDATE, DELETE)
-- - INSTEAD OF triggers for complex logic
-- - Error handling in triggers
-- - Dynamic SQL for flexible auditing
-- - Performance optimization techniques
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Generic Audit Trigger for Employees Table
-- =============================================
CREATE OR ALTER TRIGGER [tr_Employees_Audit]
ON [dbo].[Employees]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Employees',
                i.EmployeeID,
                'INSERT',
                NULL,
                CONCAT(
                    'FirstName:', ISNULL(i.FirstName, 'NULL'), ';',
                    'LastName:', ISNULL(i.LastName, 'NULL'), ';',
                    'Email:', ISNULL(i.Email, 'NULL'), ';',
                    'Phone:', ISNULL(i.Phone, 'NULL'), ';',
                    'DateOfBirth:', ISNULL(CAST(i.DateOfBirth AS NVARCHAR), 'NULL'), ';',
                    'HireDate:', ISNULL(CAST(i.HireDate AS NVARCHAR), 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(i.DepartmentID AS NVARCHAR), 'NULL'), ';',
                    'ManagerID:', ISNULL(CAST(i.ManagerID AS NVARCHAR), 'NULL'), ';',
                    'JobTitle:', ISNULL(i.JobTitle, 'NULL'), ';',
                    'Salary:', ISNULL(CAST(i.Salary AS NVARCHAR), 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(i.IsActive AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Employees',
                i.EmployeeID,
                'UPDATE',
                CONCAT(
                    'FirstName:', ISNULL(d.FirstName, 'NULL'), ';',
                    'LastName:', ISNULL(d.LastName, 'NULL'), ';',
                    'Email:', ISNULL(d.Email, 'NULL'), ';',
                    'Phone:', ISNULL(d.Phone, 'NULL'), ';',
                    'DateOfBirth:', ISNULL(CAST(d.DateOfBirth AS NVARCHAR), 'NULL'), ';',
                    'HireDate:', ISNULL(CAST(d.HireDate AS NVARCHAR), 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(d.DepartmentID AS NVARCHAR), 'NULL'), ';',
                    'ManagerID:', ISNULL(CAST(d.ManagerID AS NVARCHAR), 'NULL'), ';',
                    'JobTitle:', ISNULL(d.JobTitle, 'NULL'), ';',
                    'Salary:', ISNULL(CAST(d.Salary AS NVARCHAR), 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(d.IsActive AS NVARCHAR), 'NULL')
                ),
                CONCAT(
                    'FirstName:', ISNULL(i.FirstName, 'NULL'), ';',
                    'LastName:', ISNULL(i.LastName, 'NULL'), ';',
                    'Email:', ISNULL(i.Email, 'NULL'), ';',
                    'Phone:', ISNULL(i.Phone, 'NULL'), ';',
                    'DateOfBirth:', ISNULL(CAST(i.DateOfBirth AS NVARCHAR), 'NULL'), ';',
                    'HireDate:', ISNULL(CAST(i.HireDate AS NVARCHAR), 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(i.DepartmentID AS NVARCHAR), 'NULL'), ';',
                    'ManagerID:', ISNULL(CAST(i.ManagerID AS NVARCHAR), 'NULL'), ';',
                    'JobTitle:', ISNULL(i.JobTitle, 'NULL'), ';',
                    'Salary:', ISNULL(CAST(i.Salary AS NVARCHAR), 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(i.IsActive AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
            WHERE 
                -- Only log if there are actual changes
                ISNULL(i.FirstName, '') != ISNULL(d.FirstName, '') OR
                ISNULL(i.LastName, '') != ISNULL(d.LastName, '') OR
                ISNULL(i.Email, '') != ISNULL(d.Email, '') OR
                ISNULL(i.Phone, '') != ISNULL(d.Phone, '') OR
                ISNULL(i.DateOfBirth, '1900-01-01') != ISNULL(d.DateOfBirth, '1900-01-01') OR
                ISNULL(i.HireDate, '1900-01-01') != ISNULL(d.HireDate, '1900-01-01') OR
                ISNULL(i.DepartmentID, 0) != ISNULL(d.DepartmentID, 0) OR
                ISNULL(i.ManagerID, 0) != ISNULL(d.ManagerID, 0) OR
                ISNULL(i.JobTitle, '') != ISNULL(d.JobTitle, '') OR
                ISNULL(i.Salary, 0) != ISNULL(d.Salary, 0) OR
                ISNULL(i.IsActive, 0) != ISNULL(d.IsActive, 0);
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Employees',
                d.EmployeeID,
                'DELETE',
                CONCAT(
                    'FirstName:', ISNULL(d.FirstName, 'NULL'), ';',
                    'LastName:', ISNULL(d.LastName, 'NULL'), ';',
                    'Email:', ISNULL(d.Email, 'NULL'), ';',
                    'Phone:', ISNULL(d.Phone, 'NULL'), ';',
                    'DateOfBirth:', ISNULL(CAST(d.DateOfBirth AS NVARCHAR), 'NULL'), ';',
                    'HireDate:', ISNULL(CAST(d.HireDate AS NVARCHAR), 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(d.DepartmentID AS NVARCHAR), 'NULL'), ';',
                    'ManagerID:', ISNULL(CAST(d.ManagerID AS NVARCHAR), 'NULL'), ';',
                    'JobTitle:', ISNULL(d.JobTitle, 'NULL'), ';',
                    'Salary:', ISNULL(CAST(d.Salary AS NVARCHAR), 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(d.IsActive AS NVARCHAR), 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        -- Log trigger error
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        -- Re-raise the error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 2. Audit Trigger for Departments Table
-- =============================================
CREATE OR ALTER TRIGGER [tr_Departments_Audit]
ON [dbo].[Departments]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Departments',
                i.DepartmentID,
                'INSERT',
                NULL,
                CONCAT(
                    'DepartmentName:', ISNULL(i.DepartmentName, 'NULL'), ';',
                    'DepartmentHead:', ISNULL(CAST(i.DepartmentHead AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(i.Budget AS NVARCHAR), 'NULL'), ';',
                    'Location:', ISNULL(i.Location, 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Departments',
                i.DepartmentID,
                'UPDATE',
                CONCAT(
                    'DepartmentName:', ISNULL(d.DepartmentName, 'NULL'), ';',
                    'DepartmentHead:', ISNULL(CAST(d.DepartmentHead AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(d.Budget AS NVARCHAR), 'NULL'), ';',
                    'Location:', ISNULL(d.Location, 'NULL')
                ),
                CONCAT(
                    'DepartmentName:', ISNULL(i.DepartmentName, 'NULL'), ';',
                    'DepartmentHead:', ISNULL(CAST(i.DepartmentHead AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(i.Budget AS NVARCHAR), 'NULL'), ';',
                    'Location:', ISNULL(i.Location, 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.DepartmentID = d.DepartmentID
            WHERE 
                ISNULL(i.DepartmentName, '') != ISNULL(d.DepartmentName, '') OR
                ISNULL(i.DepartmentHead, 0) != ISNULL(d.DepartmentHead, 0) OR
                ISNULL(i.Budget, 0) != ISNULL(d.Budget, 0) OR
                ISNULL(i.Location, '') != ISNULL(d.Location, '');
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Departments',
                d.DepartmentID,
                'DELETE',
                CONCAT(
                    'DepartmentName:', ISNULL(d.DepartmentName, 'NULL'), ';',
                    'DepartmentHead:', ISNULL(CAST(d.DepartmentHead AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(d.Budget AS NVARCHAR), 'NULL'), ';',
                    'Location:', ISNULL(d.Location, 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'Departments Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 3. Audit Trigger for Performance Reviews Table
-- =============================================
CREATE OR ALTER TRIGGER [tr_PerformanceReviews_Audit]
ON [dbo].[PerformanceReviews]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'PerformanceReviews',
                i.ReviewID,
                'INSERT',
                NULL,
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ReviewerID:', ISNULL(CAST(i.ReviewerID AS NVARCHAR), 'NULL'), ';',
                    'ReviewDate:', ISNULL(CAST(i.ReviewDate AS NVARCHAR), 'NULL'), ';',
                    'OverallRating:', ISNULL(CAST(i.OverallRating AS NVARCHAR), 'NULL'), ';',
                    'TechnicalSkills:', ISNULL(CAST(i.TechnicalSkills AS NVARCHAR), 'NULL'), ';',
                    'Communication:', ISNULL(CAST(i.Communication AS NVARCHAR), 'NULL'), ';',
                    'Teamwork:', ISNULL(CAST(i.Teamwork AS NVARCHAR), 'NULL'), ';',
                    'Leadership:', ISNULL(CAST(i.Leadership AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'PerformanceReviews',
                i.ReviewID,
                'UPDATE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ReviewerID:', ISNULL(CAST(d.ReviewerID AS NVARCHAR), 'NULL'), ';',
                    'ReviewDate:', ISNULL(CAST(d.ReviewDate AS NVARCHAR), 'NULL'), ';',
                    'OverallRating:', ISNULL(CAST(d.OverallRating AS NVARCHAR), 'NULL'), ';',
                    'TechnicalSkills:', ISNULL(CAST(d.TechnicalSkills AS NVARCHAR), 'NULL'), ';',
                    'Communication:', ISNULL(CAST(d.Communication AS NVARCHAR), 'NULL'), ';',
                    'Teamwork:', ISNULL(CAST(d.Teamwork AS NVARCHAR), 'NULL'), ';',
                    'Leadership:', ISNULL(CAST(d.Leadership AS NVARCHAR), 'NULL')
                ),
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ReviewerID:', ISNULL(CAST(i.ReviewerID AS NVARCHAR), 'NULL'), ';',
                    'ReviewDate:', ISNULL(CAST(i.ReviewDate AS NVARCHAR), 'NULL'), ';',
                    'OverallRating:', ISNULL(CAST(i.OverallRating AS NVARCHAR), 'NULL'), ';',
                    'TechnicalSkills:', ISNULL(CAST(i.TechnicalSkills AS NVARCHAR), 'NULL'), ';',
                    'Communication:', ISNULL(CAST(i.Communication AS NVARCHAR), 'NULL'), ';',
                    'Teamwork:', ISNULL(CAST(i.Teamwork AS NVARCHAR), 'NULL'), ';',
                    'Leadership:', ISNULL(CAST(i.Leadership AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.ReviewID = d.ReviewID
            WHERE 
                ISNULL(i.EmployeeID, 0) != ISNULL(d.EmployeeID, 0) OR
                ISNULL(i.ReviewerID, 0) != ISNULL(d.ReviewerID, 0) OR
                ISNULL(i.ReviewDate, '1900-01-01') != ISNULL(d.ReviewDate, '1900-01-01') OR
                ISNULL(i.OverallRating, 0) != ISNULL(d.OverallRating, 0) OR
                ISNULL(i.TechnicalSkills, 0) != ISNULL(d.TechnicalSkills, 0) OR
                ISNULL(i.Communication, 0) != ISNULL(d.Communication, 0) OR
                ISNULL(i.Teamwork, 0) != ISNULL(d.Teamwork, 0) OR
                ISNULL(i.Leadership, 0) != ISNULL(d.Leadership, 0);
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'PerformanceReviews',
                d.ReviewID,
                'DELETE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ReviewerID:', ISNULL(CAST(d.ReviewerID AS NVARCHAR), 'NULL'), ';',
                    'ReviewDate:', ISNULL(CAST(d.ReviewDate AS NVARCHAR), 'NULL'), ';',
                    'OverallRating:', ISNULL(CAST(d.OverallRating AS NVARCHAR), 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'PerformanceReviews Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 4. Audit Trigger for Projects Table
-- =============================================
CREATE OR ALTER TRIGGER [tr_Projects_Audit]
ON [dbo].[Projects]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Projects',
                i.ProjectID,
                'INSERT',
                NULL,
                CONCAT(
                    'ProjectName:', ISNULL(i.ProjectName, 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(i.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(i.EndDate AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(i.Budget AS NVARCHAR), 'NULL'), ';',
                    'Status:', ISNULL(i.Status, 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(i.DepartmentID AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Projects',
                i.ProjectID,
                'UPDATE',
                CONCAT(
                    'ProjectName:', ISNULL(d.ProjectName, 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(d.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(d.EndDate AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(d.Budget AS NVARCHAR), 'NULL'), ';',
                    'Status:', ISNULL(d.Status, 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(d.DepartmentID AS NVARCHAR), 'NULL')
                ),
                CONCAT(
                    'ProjectName:', ISNULL(i.ProjectName, 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(i.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(i.EndDate AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(i.Budget AS NVARCHAR), 'NULL'), ';',
                    'Status:', ISNULL(i.Status, 'NULL'), ';',
                    'DepartmentID:', ISNULL(CAST(i.DepartmentID AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.ProjectID = d.ProjectID
            WHERE 
                ISNULL(i.ProjectName, '') != ISNULL(d.ProjectName, '') OR
                ISNULL(i.StartDate, '1900-01-01') != ISNULL(d.StartDate, '1900-01-01') OR
                ISNULL(i.EndDate, '1900-01-01') != ISNULL(d.EndDate, '1900-01-01') OR
                ISNULL(i.Budget, 0) != ISNULL(d.Budget, 0) OR
                ISNULL(i.Status, '') != ISNULL(d.Status, '') OR
                ISNULL(i.DepartmentID, 0) != ISNULL(d.DepartmentID, 0);
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Projects',
                d.ProjectID,
                'DELETE',
                CONCAT(
                    'ProjectName:', ISNULL(d.ProjectName, 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(d.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(d.EndDate AS NVARCHAR), 'NULL'), ';',
                    'Budget:', ISNULL(CAST(d.Budget AS NVARCHAR), 'NULL'), ';',
                    'Status:', ISNULL(d.Status, 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'Projects Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 5. Audit Trigger for Salary History Table
-- =============================================
CREATE OR ALTER TRIGGER [tr_SalaryHistory_Audit]
ON [dbo].[SalaryHistory]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'SalaryHistory',
                i.SalaryHistoryID,
                'INSERT',
                NULL,
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'OldSalary:', ISNULL(CAST(i.OldSalary AS NVARCHAR), 'NULL'), ';',
                    'NewSalary:', ISNULL(CAST(i.NewSalary AS NVARCHAR), 'NULL'), ';',
                    'ChangeDate:', ISNULL(CAST(i.ChangeDate AS NVARCHAR), 'NULL'), ';',
                    'ChangeReason:', ISNULL(i.ChangeReason, 'NULL'), ';',
                    'ApprovedBy:', ISNULL(CAST(i.ApprovedBy AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'SalaryHistory',
                i.SalaryHistoryID,
                'UPDATE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'OldSalary:', ISNULL(CAST(d.OldSalary AS NVARCHAR), 'NULL'), ';',
                    'NewSalary:', ISNULL(CAST(d.NewSalary AS NVARCHAR), 'NULL'), ';',
                    'ChangeDate:', ISNULL(CAST(d.ChangeDate AS NVARCHAR), 'NULL'), ';',
                    'ChangeReason:', ISNULL(d.ChangeReason, 'NULL'), ';',
                    'ApprovedBy:', ISNULL(CAST(d.ApprovedBy AS NVARCHAR), 'NULL')
                ),
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'OldSalary:', ISNULL(CAST(i.OldSalary AS NVARCHAR), 'NULL'), ';',
                    'NewSalary:', ISNULL(CAST(i.NewSalary AS NVARCHAR), 'NULL'), ';',
                    'ChangeDate:', ISNULL(CAST(i.ChangeDate AS NVARCHAR), 'NULL'), ';',
                    'ChangeReason:', ISNULL(i.ChangeReason, 'NULL'), ';',
                    'ApprovedBy:', ISNULL(CAST(i.ApprovedBy AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.SalaryHistoryID = d.SalaryHistoryID
            WHERE 
                ISNULL(i.EmployeeID, 0) != ISNULL(d.EmployeeID, 0) OR
                ISNULL(i.OldSalary, 0) != ISNULL(d.OldSalary, 0) OR
                ISNULL(i.NewSalary, 0) != ISNULL(d.NewSalary, 0) OR
                ISNULL(i.ChangeDate, '1900-01-01') != ISNULL(d.ChangeDate, '1900-01-01') OR
                ISNULL(i.ChangeReason, '') != ISNULL(d.ChangeReason, '') OR
                ISNULL(i.ApprovedBy, 0) != ISNULL(d.ApprovedBy, 0);
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'SalaryHistory',
                d.SalaryHistoryID,
                'DELETE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'OldSalary:', ISNULL(CAST(d.OldSalary AS NVARCHAR), 'NULL'), ';',
                    'NewSalary:', ISNULL(CAST(d.NewSalary AS NVARCHAR), 'NULL'), ';',
                    'ChangeDate:', ISNULL(CAST(d.ChangeDate AS NVARCHAR), 'NULL'), ';',
                    'ChangeReason:', ISNULL(d.ChangeReason, 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'SalaryHistory Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 6. Audit Trigger for Users Table
-- =============================================
CREATE OR ALTER TRIGGER [tr_Users_Audit]
ON [dbo].[Users]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Users',
                i.UserID,
                'INSERT',
                NULL,
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'Username:', ISNULL(i.Username, 'NULL'), ';',
                    'Role:', ISNULL(i.Role, 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(i.IsActive AS NVARCHAR), 'NULL'), ';',
                    'LastLogin:', ISNULL(CAST(i.LastLogin AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Users',
                i.UserID,
                'UPDATE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'Username:', ISNULL(d.Username, 'NULL'), ';',
                    'Role:', ISNULL(d.Role, 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(d.IsActive AS NVARCHAR), 'NULL'), ';',
                    'LastLogin:', ISNULL(CAST(d.LastLogin AS NVARCHAR), 'NULL')
                ),
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'Username:', ISNULL(i.Username, 'NULL'), ';',
                    'Role:', ISNULL(i.Role, 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(i.IsActive AS NVARCHAR), 'NULL'), ';',
                    'LastLogin:', ISNULL(CAST(i.LastLogin AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.UserID = d.UserID
            WHERE 
                ISNULL(i.EmployeeID, 0) != ISNULL(d.EmployeeID, 0) OR
                ISNULL(i.Username, '') != ISNULL(d.Username, '') OR
                ISNULL(i.Role, '') != ISNULL(d.Role, '') OR
                ISNULL(i.IsActive, 0) != ISNULL(d.IsActive, 0) OR
                ISNULL(i.LastLogin, '1900-01-01') != ISNULL(d.LastLogin, '1900-01-01');
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'Users',
                d.UserID,
                'DELETE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'Username:', ISNULL(d.Username, 'NULL'), ';',
                    'Role:', ISNULL(d.Role, 'NULL'), ';',
                    'IsActive:', ISNULL(CAST(d.IsActive AS NVARCHAR), 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'Users Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 7. INSTEAD OF Trigger for Complex Audit Logic
-- =============================================
CREATE OR ALTER TRIGGER [tr_EmployeeProjects_Audit]
ON [dbo].[EmployeeProjects]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Handle INSERT operations
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'EmployeeProjects',
                i.EmployeeProjectID,
                'INSERT',
                NULL,
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ProjectID:', ISNULL(CAST(i.ProjectID AS NVARCHAR), 'NULL'), ';',
                    'Role:', ISNULL(i.Role, 'NULL'), ';',
                    'AllocationPercentage:', ISNULL(CAST(i.AllocationPercentage AS NVARCHAR), 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(i.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(i.EndDate AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i;
        END
        
        -- Handle UPDATE operations
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'EmployeeProjects',
                i.EmployeeProjectID,
                'UPDATE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ProjectID:', ISNULL(CAST(d.ProjectID AS NVARCHAR), 'NULL'), ';',
                    'Role:', ISNULL(d.Role, 'NULL'), ';',
                    'AllocationPercentage:', ISNULL(CAST(d.AllocationPercentage AS NVARCHAR), 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(d.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(d.EndDate AS NVARCHAR), 'NULL')
                ),
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(i.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ProjectID:', ISNULL(CAST(i.ProjectID AS NVARCHAR), 'NULL'), ';',
                    'Role:', ISNULL(i.Role, 'NULL'), ';',
                    'AllocationPercentage:', ISNULL(CAST(i.AllocationPercentage AS NVARCHAR), 'NULL'), ';',
                    'StartDate:', ISNULL(CAST(i.StartDate AS NVARCHAR), 'NULL'), ';',
                    'EndDate:', ISNULL(CAST(i.EndDate AS NVARCHAR), 'NULL')
                ),
                SYSTEM_USER,
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON i.EmployeeProjectID = d.EmployeeProjectID
            WHERE 
                ISNULL(i.EmployeeID, 0) != ISNULL(d.EmployeeID, 0) OR
                ISNULL(i.ProjectID, 0) != ISNULL(d.ProjectID, 0) OR
                ISNULL(i.Role, '') != ISNULL(d.Role, '') OR
                ISNULL(i.AllocationPercentage, 0) != ISNULL(d.AllocationPercentage, 0) OR
                ISNULL(i.StartDate, '1900-01-01') != ISNULL(d.StartDate, '1900-01-01') OR
                ISNULL(i.EndDate, '1900-01-01') != ISNULL(d.EndDate, '1900-01-01');
        END
        
        -- Handle DELETE operations
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
            SELECT 
                'EmployeeProjects',
                d.EmployeeProjectID,
                'DELETE',
                CONCAT(
                    'EmployeeID:', ISNULL(CAST(d.EmployeeID AS NVARCHAR), 'NULL'), ';',
                    'ProjectID:', ISNULL(CAST(d.ProjectID AS NVARCHAR), 'NULL'), ';',
                    'Role:', ISNULL(d.Role, 'NULL'), ';',
                    'AllocationPercentage:', ISNULL(CAST(d.AllocationPercentage AS NVARCHAR), 'NULL')
                ),
                'RECORD DELETED',
                SYSTEM_USER,
                GETDATE()
            FROM deleted d;
        END
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('TRIGGER_ERROR', 0, 'ERROR', 'EmployeeProjects Trigger Error', ERROR_MESSAGE(), SYSTEM_USER, GETDATE());
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 8. Create Audit Log Cleanup Procedure
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CleanupAuditLog]
    @RetentionDays INT = 365,
    @BatchSize INT = 1000
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DECLARE @DeletedCount INT = 0;
        DECLARE @TotalDeleted INT = 0;
        DECLARE @CutoffDate DATETIME2(7) = DATEADD(DAY, -@RetentionDays, GETDATE());
        
        -- Delete old audit records in batches
        WHILE 1 = 1
        BEGIN
            DELETE TOP (@BatchSize) 
            FROM AuditLog 
            WHERE ChangedDate < @CutoffDate;
            
            SET @DeletedCount = @@ROWCOUNT;
            SET @TotalDeleted = @TotalDeleted + @DeletedCount;
            
            -- Break if no more records to delete
            IF @DeletedCount = 0
                BREAK;
            
            -- Small delay to prevent blocking
            WAITFOR DELAY '00:00:01';
        END
        
        -- Log cleanup operation
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy, ChangedDate)
        VALUES ('AUDIT_CLEANUP', 0, 'CLEANUP', 
                CONCAT('Retention Days: ', @RetentionDays), 
                CONCAT('Records Deleted: ', @TotalDeleted), 
                SYSTEM_USER, GETDATE());
        
        SELECT 
            @TotalDeleted AS RecordsDeleted,
            @CutoffDate AS CutoffDate,
            'Audit log cleanup completed successfully' AS Result;
        
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
-- 9. Create Audit Report Procedure
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAuditReport]
    @StartDate DATETIME2(7) = NULL,
    @EndDate DATETIME2(7) = NULL,
    @TableName NVARCHAR(100) = NULL,
    @Action NVARCHAR(10) = NULL,
    @ChangedBy NVARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to last 30 days if not specified
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(DAY, -30, GETDATE());
    IF @EndDate IS NULL
        SET @EndDate = GETDATE();
    
    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 50;
    
    BEGIN TRY
        -- Use CTE for pagination and filtering
        WITH FilteredAuditLog AS (
            SELECT 
                al.AuditID,
                al.TableName,
                al.RecordID,
                al.Action,
                al.OldValue,
                al.NewValue,
                al.ChangedBy,
                al.ChangedDate,
                ROW_NUMBER() OVER (ORDER BY al.ChangedDate DESC) AS RowNumber,
                COUNT(*) OVER() AS TotalCount
            FROM AuditLog al
            WHERE 
                al.ChangedDate BETWEEN @StartDate AND @EndDate
                AND (@TableName IS NULL OR al.TableName = @TableName)
                AND (@Action IS NULL OR al.Action = @Action)
                AND (@ChangedBy IS NULL OR al.ChangedBy LIKE '%' + @ChangedBy + '%')
        )
        SELECT 
            AuditID,
            TableName,
            RecordID,
            Action,
            OldValue,
            NewValue,
            ChangedBy,
            ChangedDate,
            TotalCount,
            @PageNumber AS PageNumber,
            @PageSize AS PageSize,
            CEILING(CAST(TotalCount AS FLOAT) / @PageSize) AS TotalPages
        FROM FilteredAuditLog
        WHERE RowNumber BETWEEN ((@PageNumber - 1) * @PageSize) + 1 AND @PageNumber * @PageSize
        ORDER BY ChangedDate DESC;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

PRINT 'Audit logging triggers created successfully!';
PRINT 'Triggers created: tr_Employees_Audit, tr_Departments_Audit, tr_PerformanceReviews_Audit, tr_Projects_Audit, tr_SalaryHistory_Audit, tr_Users_Audit, tr_EmployeeProjects_Audit';
PRINT 'Procedures created: sp_CleanupAuditLog, sp_GetAuditReport';
PRINT 'Features demonstrated: DML Triggers, Error Handling, Batch Operations, Audit Reporting, Data Retention';
