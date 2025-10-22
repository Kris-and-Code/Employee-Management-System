-- =============================================
-- Employee Management System Database Schema
-- Created: 2024
-- Description: Comprehensive database schema for Employee Management System
--              Demonstrates advanced T-SQL features and best practices
-- =============================================

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EmployeeManagementDB')
BEGIN
    CREATE DATABASE EmployeeManagementDB
    COLLATE SQL_Latin1_General_CP1_CI_AS;
END
GO

USE EmployeeManagementDB;
GO

-- =============================================
-- Create Tables
-- =============================================

-- 1. Departments Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Departments]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Departments] (
        [DepartmentID] INT IDENTITY(1,1) NOT NULL,
        [DepartmentName] NVARCHAR(100) NOT NULL,
        [DepartmentHead] INT NULL,
        [Budget] DECIMAL(18,2) NULL,
        [Location] NVARCHAR(100) NULL,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME2(7) NULL,
        CONSTRAINT [PK_Departments] PRIMARY KEY CLUSTERED ([DepartmentID] ASC),
        CONSTRAINT [UK_Departments_DepartmentName] UNIQUE ([DepartmentName])
    );
END
GO

-- 2. Employees Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Employees]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Employees] (
        [EmployeeID] INT IDENTITY(1,1) NOT NULL,
        [FirstName] NVARCHAR(50) NOT NULL,
        [LastName] NVARCHAR(50) NOT NULL,
        [Email] NVARCHAR(100) NOT NULL,
        [Phone] NVARCHAR(20) NULL,
        [DateOfBirth] DATE NULL,
        [HireDate] DATE NOT NULL,
        [DepartmentID] INT NOT NULL,
        [ManagerID] INT NULL,
        [JobTitle] NVARCHAR(100) NOT NULL,
        [Salary] DECIMAL(18,2) NOT NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME2(7) NULL,
        CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED ([EmployeeID] ASC),
        CONSTRAINT [UK_Employees_Email] UNIQUE ([Email]),
        CONSTRAINT [FK_Employees_Departments] FOREIGN KEY ([DepartmentID]) 
            REFERENCES [dbo].[Departments] ([DepartmentID]),
        CONSTRAINT [FK_Employees_Manager] FOREIGN KEY ([ManagerID]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [CK_Employees_Salary] CHECK ([Salary] > 0),
        CONSTRAINT [CK_Employees_HireDate] CHECK ([HireDate] <= CAST(GETDATE() AS DATE)),
        CONSTRAINT [CK_Employees_DateOfBirth] CHECK ([DateOfBirth] IS NULL OR [DateOfBirth] < CAST(GETDATE() AS DATE))
    );
END
GO

-- 3. Projects Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Projects] (
        [ProjectID] INT IDENTITY(1,1) NOT NULL,
        [ProjectName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [StartDate] DATE NOT NULL,
        [EndDate] DATE NULL,
        [Budget] DECIMAL(18,2) NULL,
        [Status] NVARCHAR(20) NOT NULL DEFAULT 'Planning',
        [DepartmentID] INT NOT NULL,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME2(7) NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([ProjectID] ASC),
        CONSTRAINT [FK_Projects_Departments] FOREIGN KEY ([DepartmentID]) 
            REFERENCES [dbo].[Departments] ([DepartmentID]),
        CONSTRAINT [CK_Projects_Status] CHECK ([Status] IN ('Planning', 'Active', 'Completed', 'On Hold', 'Cancelled')),
        CONSTRAINT [CK_Projects_EndDate] CHECK ([EndDate] IS NULL OR [EndDate] >= [StartDate]),
        CONSTRAINT [CK_Projects_Budget] CHECK ([Budget] IS NULL OR [Budget] > 0)
    );
END
GO

-- 4. EmployeeProjects Table (Many-to-Many)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmployeeProjects]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EmployeeProjects] (
        [EmployeeProjectID] INT IDENTITY(1,1) NOT NULL,
        [EmployeeID] INT NOT NULL,
        [ProjectID] INT NOT NULL,
        [Role] NVARCHAR(100) NOT NULL,
        [AllocationPercentage] INT NOT NULL,
        [StartDate] DATE NOT NULL,
        [EndDate] DATE NULL,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_EmployeeProjects] PRIMARY KEY CLUSTERED ([EmployeeProjectID] ASC),
        CONSTRAINT [FK_EmployeeProjects_Employees] FOREIGN KEY ([EmployeeID]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [FK_EmployeeProjects_Projects] FOREIGN KEY ([ProjectID]) 
            REFERENCES [dbo].[Projects] ([ProjectID]),
        CONSTRAINT [UK_EmployeeProjects_Employee_Project] UNIQUE ([EmployeeID], [ProjectID]),
        CONSTRAINT [CK_EmployeeProjects_Allocation] CHECK ([AllocationPercentage] >= 0 AND [AllocationPercentage] <= 100),
        CONSTRAINT [CK_EmployeeProjects_EndDate] CHECK ([EndDate] IS NULL OR [EndDate] >= [StartDate])
    );
END
GO

-- 5. PerformanceReviews Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerformanceReviews]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PerformanceReviews] (
        [ReviewID] INT IDENTITY(1,1) NOT NULL,
        [EmployeeID] INT NOT NULL,
        [ReviewerID] INT NOT NULL,
        [ReviewDate] DATE NOT NULL,
        [ReviewPeriodStart] DATE NOT NULL,
        [ReviewPeriodEnd] DATE NOT NULL,
        [OverallRating] INT NOT NULL,
        [TechnicalSkills] INT NOT NULL,
        [Communication] INT NOT NULL,
        [Teamwork] INT NOT NULL,
        [Leadership] INT NOT NULL,
        [Comments] NVARCHAR(MAX) NULL,
        [Goals] NVARCHAR(MAX) NULL,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME2(7) NULL,
        CONSTRAINT [PK_PerformanceReviews] PRIMARY KEY CLUSTERED ([ReviewID] ASC),
        CONSTRAINT [FK_PerformanceReviews_Employee] FOREIGN KEY ([EmployeeID]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [FK_PerformanceReviews_Reviewer] FOREIGN KEY ([ReviewerID]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [CK_PerformanceReviews_Ratings] CHECK (
            [OverallRating] >= 1 AND [OverallRating] <= 5 AND
            [TechnicalSkills] >= 1 AND [TechnicalSkills] <= 5 AND
            [Communication] >= 1 AND [Communication] <= 5 AND
            [Teamwork] >= 1 AND [Teamwork] <= 5 AND
            [Leadership] >= 1 AND [Leadership] <= 5
        ),
        CONSTRAINT [CK_PerformanceReviews_Period] CHECK ([ReviewPeriodEnd] >= [ReviewPeriodStart])
    );
END
GO

-- 6. SalaryHistory Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SalaryHistory]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SalaryHistory] (
        [SalaryHistoryID] INT IDENTITY(1,1) NOT NULL,
        [EmployeeID] INT NOT NULL,
        [OldSalary] DECIMAL(18,2) NULL,
        [NewSalary] DECIMAL(18,2) NOT NULL,
        [ChangeDate] DATE NOT NULL,
        [ChangeReason] NVARCHAR(200) NULL,
        [ApprovedBy] INT NULL,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_SalaryHistory] PRIMARY KEY CLUSTERED ([SalaryHistoryID] ASC),
        CONSTRAINT [FK_SalaryHistory_Employees] FOREIGN KEY ([EmployeeID]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [FK_SalaryHistory_ApprovedBy] FOREIGN KEY ([ApprovedBy]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [CK_SalaryHistory_NewSalary] CHECK ([NewSalary] > 0),
        CONSTRAINT [CK_SalaryHistory_OldSalary] CHECK ([OldSalary] IS NULL OR [OldSalary] > 0)
    );
END
GO

-- 7. AuditLog Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AuditLog] (
        [AuditID] INT IDENTITY(1,1) NOT NULL,
        [TableName] NVARCHAR(100) NOT NULL,
        [RecordID] INT NOT NULL,
        [Action] NVARCHAR(10) NOT NULL,
        [OldValue] NVARCHAR(MAX) NULL,
        [NewValue] NVARCHAR(MAX) NULL,
        [ChangedBy] NVARCHAR(100) NOT NULL,
        [ChangedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_AuditLog] PRIMARY KEY CLUSTERED ([AuditID] ASC),
        CONSTRAINT [CK_AuditLog_Action] CHECK ([Action] IN ('INSERT', 'UPDATE', 'DELETE'))
    );
END
GO

-- 8. Users Table (for authentication)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Users] (
        [UserID] INT IDENTITY(1,1) NOT NULL,
        [EmployeeID] INT NOT NULL,
        [Username] NVARCHAR(50) NOT NULL,
        [PasswordHash] NVARCHAR(256) NOT NULL,
        [Role] NVARCHAR(20) NOT NULL,
        [LastLogin] DATETIME2(7) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedDate] DATETIME2(7) NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME2(7) NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([UserID] ASC),
        CONSTRAINT [FK_Users_Employees] FOREIGN KEY ([EmployeeID]) 
            REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [UK_Users_Username] UNIQUE ([Username]),
        CONSTRAINT [UK_Users_EmployeeID] UNIQUE ([EmployeeID]),
        CONSTRAINT [CK_Users_Role] CHECK ([Role] IN ('Admin', 'Manager', 'Employee'))
    );
END
GO

-- =============================================
-- Add Foreign Key Constraints (Self-references)
-- =============================================

-- Add foreign key constraint for Department Head
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Departments_DepartmentHead')
BEGIN
    ALTER TABLE [dbo].[Departments]
    ADD CONSTRAINT [FK_Departments_DepartmentHead] 
    FOREIGN KEY ([DepartmentHead]) REFERENCES [dbo].[Employees] ([EmployeeID]);
END
GO

-- =============================================
-- Create Indexes for Performance Optimization
-- =============================================

-- Employee indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_DepartmentID')
    CREATE NONCLUSTERED INDEX [IX_Employees_DepartmentID] ON [dbo].[Employees] ([DepartmentID]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_ManagerID')
    CREATE NONCLUSTERED INDEX [IX_Employees_ManagerID] ON [dbo].[Employees] ([ManagerID]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_HireDate')
    CREATE NONCLUSTERED INDEX [IX_Employees_HireDate] ON [dbo].[Employees] ([HireDate]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_IsActive')
    CREATE NONCLUSTERED INDEX [IX_Employees_IsActive] ON [dbo].[Employees] ([IsActive]);
GO

-- Project indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Projects_DepartmentID')
    CREATE NONCLUSTERED INDEX [IX_Projects_DepartmentID] ON [dbo].[Projects] ([DepartmentID]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Projects_Status')
    CREATE NONCLUSTERED INDEX [IX_Projects_Status] ON [dbo].[Projects] ([Status]);
GO

-- EmployeeProjects indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EmployeeProjects_EmployeeID')
    CREATE NONCLUSTERED INDEX [IX_EmployeeProjects_EmployeeID] ON [dbo].[EmployeeProjects] ([EmployeeID]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EmployeeProjects_ProjectID')
    CREATE NONCLUSTERED INDEX [IX_EmployeeProjects_ProjectID] ON [dbo].[EmployeeProjects] ([ProjectID]);
GO

-- PerformanceReviews indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PerformanceReviews_EmployeeID')
    CREATE NONCLUSTERED INDEX [IX_PerformanceReviews_EmployeeID] ON [dbo].[PerformanceReviews] ([EmployeeID]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PerformanceReviews_ReviewDate')
    CREATE NONCLUSTERED INDEX [IX_PerformanceReviews_ReviewDate] ON [dbo].[PerformanceReviews] ([ReviewDate]);
GO

-- SalaryHistory indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalaryHistory_EmployeeID')
    CREATE NONCLUSTERED INDEX [IX_SalaryHistory_EmployeeID] ON [dbo].[SalaryHistory] ([EmployeeID]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalaryHistory_ChangeDate')
    CREATE NONCLUSTERED INDEX [IX_SalaryHistory_ChangeDate] ON [dbo].[SalaryHistory] ([ChangeDate]);
GO

-- AuditLog indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLog_TableName')
    CREATE NONCLUSTERED INDEX [IX_AuditLog_TableName] ON [dbo].[AuditLog] ([TableName]);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLog_ChangedDate')
    CREATE NONCLUSTERED INDEX [IX_AuditLog_ChangedDate] ON [dbo].[AuditLog] ([ChangedDate]);
GO

-- =============================================
-- Create Computed Columns for Better Performance
-- =============================================

-- Add computed column for full name
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Employees') AND name = 'FullName')
BEGIN
    ALTER TABLE [dbo].[Employees]
    ADD [FullName] AS ([FirstName] + ' ' + [LastName]) PERSISTED;
END
GO

-- Add computed column for years of service
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Employees') AND name = 'YearsOfService')
BEGIN
    ALTER TABLE [dbo].[Employees]
    ADD [YearsOfService] AS (DATEDIFF(YEAR, [HireDate], GETDATE())) PERSISTED;
END
GO

-- Add computed column for age
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Employees') AND name = 'Age')
BEGIN
    ALTER TABLE [dbo].[Employees]
    ADD [Age] AS (CASE 
        WHEN [DateOfBirth] IS NOT NULL 
        THEN DATEDIFF(YEAR, [DateOfBirth], GETDATE()) 
        ELSE NULL 
    END) PERSISTED;
END
GO

-- =============================================
-- Create Check Constraints for Data Integrity
-- =============================================

-- Ensure manager is not the same as employee
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Employees_ManagerNotSelf')
BEGIN
    ALTER TABLE [dbo].[Employees]
    ADD CONSTRAINT [CK_Employees_ManagerNotSelf] 
    CHECK ([ManagerID] IS NULL OR [ManagerID] != [EmployeeID]);
END
GO

-- Ensure reviewer is not the same as employee being reviewed
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_PerformanceReviews_ReviewerNotEmployee')
BEGIN
    ALTER TABLE [dbo].[PerformanceReviews]
    ADD CONSTRAINT [CK_PerformanceReviews_ReviewerNotEmployee] 
    CHECK ([ReviewerID] != [EmployeeID]);
END
GO

-- =============================================
-- Create Default Constraints
-- =============================================

-- Set default values for common fields
IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Employees_IsActive')
BEGIN
    ALTER TABLE [dbo].[Employees]
    ADD CONSTRAINT [DF_Employees_IsActive] DEFAULT (1) FOR [IsActive];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Projects_Status')
BEGIN
    ALTER TABLE [dbo].[Projects]
    ADD CONSTRAINT [DF_Projects_Status] DEFAULT ('Planning') FOR [Status];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Users_IsActive')
BEGIN
    ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_IsActive] DEFAULT (1) FOR [IsActive];
END
GO

PRINT 'Database schema created successfully!';
PRINT 'Tables created: Departments, Employees, Projects, EmployeeProjects, PerformanceReviews, SalaryHistory, AuditLog, Users';
PRINT 'Indexes created for performance optimization';
PRINT 'Computed columns added for FullName, YearsOfService, and Age';
PRINT 'Check constraints added for data integrity';
