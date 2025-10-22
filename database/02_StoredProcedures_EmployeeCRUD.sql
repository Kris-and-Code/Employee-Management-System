-- =============================================
-- Employee CRUD Stored Procedures
-- Demonstrates advanced T-SQL features including:
-- - CTEs (Common Table Expressions)
-- - Window Functions
-- - Error Handling with TRY-CATCH
-- - Transactions
-- - Dynamic SQL where appropriate
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Create Employee Stored Procedure
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CreateEmployee]
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
    @CreatedBy NVARCHAR(100) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate inputs
        IF @Salary <= 0
        BEGIN
            RAISERROR('Salary must be greater than 0', 16, 1);
            RETURN;
        END
        
        IF @HireDate > CAST(GETDATE() AS DATE)
        BEGIN
            RAISERROR('Hire date cannot be in the future', 16, 1);
            RETURN;
        END
        
        -- Check if department exists
        IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Department does not exist', 16, 1);
            RETURN;
        END
        
        -- Check if manager exists (if provided)
        IF @ManagerID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @ManagerID AND IsActive = 1)
        BEGIN
            RAISERROR('Manager does not exist or is inactive', 16, 1);
            RETURN;
        END
        
        -- Insert employee
        DECLARE @EmployeeID INT;
        
        INSERT INTO Employees (
            FirstName, LastName, Email, Phone, DateOfBirth, 
            HireDate, DepartmentID, ManagerID, JobTitle, Salary
        )
        VALUES (
            @FirstName, @LastName, @Email, @Phone, @DateOfBirth,
            @HireDate, @DepartmentID, @ManagerID, @JobTitle, @Salary
        );
        
        SET @EmployeeID = SCOPE_IDENTITY();
        
        -- Insert salary history
        INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
        VALUES (@EmployeeID, NULL, @Salary, @HireDate, 'Initial salary', NULL);
        
        -- Log audit
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @EmployeeID, 'INSERT', NULL, 
                CONCAT('Employee: ', @FirstName, ' ', @LastName, ' - Salary: ', @Salary), @CreatedBy);
        
        COMMIT TRANSACTION;
        
        -- Return the created employee with computed columns
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
            e.CreatedDate
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
        WHERE e.EmployeeID = @EmployeeID;
        
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
-- 2. Get Employee by ID Stored Procedure
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetEmployee]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use CTE to get employee hierarchy
    WITH EmployeeHierarchy AS (
        -- Base case: the employee
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
            0 AS HierarchyLevel
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
        WHERE e.EmployeeID = @EmployeeID
        
        UNION ALL
        
        -- Recursive case: direct reports
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
            eh.HierarchyLevel + 1
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
        INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
        WHERE e.IsActive = 1
    )
    SELECT * FROM EmployeeHierarchy
    ORDER BY HierarchyLevel, LastName, FirstName;
END
GO

-- =============================================
-- 3. Update Employee Stored Procedure
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_UpdateEmployee]
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
    @UpdatedBy NVARCHAR(100) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if employee exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID)
        BEGIN
            RAISERROR('Employee does not exist', 16, 1);
            RETURN;
        END
        
        -- Get current values for audit
        DECLARE @OldValues NVARCHAR(MAX);
        SELECT @OldValues = CONCAT(
            'FirstName:', ISNULL(FirstName, 'NULL'), ';',
            'LastName:', ISNULL(LastName, 'NULL'), ';',
            'Email:', ISNULL(Email, 'NULL'), ';',
            'Phone:', ISNULL(Phone, 'NULL'), ';',
            'Salary:', ISNULL(CAST(Salary AS NVARCHAR), 'NULL'), ';',
            'DepartmentID:', ISNULL(CAST(DepartmentID AS NVARCHAR), 'NULL'), ';',
            'ManagerID:', ISNULL(CAST(ManagerID AS NVARCHAR), 'NULL'), ';',
            'JobTitle:', ISNULL(JobTitle, 'NULL'), ';',
            'IsActive:', ISNULL(CAST(IsActive AS NVARCHAR), 'NULL')
        )
        FROM Employees WHERE EmployeeID = @EmployeeID;
        
        -- Update employee
        UPDATE Employees 
        SET 
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
        IF @Salary IS NOT NULL
        BEGIN
            DECLARE @OldSalary DECIMAL(18,2);
            SELECT @OldSalary = Salary FROM Employees WHERE EmployeeID = @EmployeeID;
            
            IF @OldSalary != @Salary
            BEGIN
                INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy)
                VALUES (@EmployeeID, @OldSalary, @Salary, CAST(GETDATE() AS DATE), 'Salary update', NULL);
            END
        END
        
        -- Log audit
        DECLARE @NewValues NVARCHAR(MAX);
        SELECT @NewValues = CONCAT(
            'FirstName:', ISNULL(FirstName, 'NULL'), ';',
            'LastName:', ISNULL(LastName, 'NULL'), ';',
            'Email:', ISNULL(Email, 'NULL'), ';',
            'Phone:', ISNULL(Phone, 'NULL'), ';',
            'Salary:', ISNULL(CAST(Salary AS NVARCHAR), 'NULL'), ';',
            'DepartmentID:', ISNULL(CAST(DepartmentID AS NVARCHAR), 'NULL'), ';',
            'ManagerID:', ISNULL(CAST(ManagerID AS NVARCHAR), 'NULL'), ';',
            'JobTitle:', ISNULL(JobTitle, 'NULL'), ';',
            'IsActive:', ISNULL(CAST(IsActive AS NVARCHAR), 'NULL')
        )
        FROM Employees WHERE EmployeeID = @EmployeeID;
        
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @EmployeeID, 'UPDATE', @OldValues, @NewValues, @UpdatedBy);
        
        COMMIT TRANSACTION;
        
        -- Return updated employee
        EXEC sp_GetEmployee @EmployeeID;
        
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
-- 4. Delete Employee Stored Procedure (Soft Delete)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteEmployee]
    @EmployeeID INT,
    @DeletedBy NVARCHAR(100) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if employee exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID)
        BEGIN
            RAISERROR('Employee does not exist', 16, 1);
            RETURN;
        END
        
        -- Check if employee has direct reports
        IF EXISTS (SELECT 1 FROM Employees WHERE ManagerID = @EmployeeID AND IsActive = 1)
        BEGIN
            RAISERROR('Cannot delete employee with active direct reports. Please reassign reports first.', 16, 1);
            RETURN;
        END
        
        -- Get current values for audit
        DECLARE @OldValues NVARCHAR(MAX);
        SELECT @OldValues = CONCAT(
            'FirstName:', ISNULL(FirstName, 'NULL'), ';',
            'LastName:', ISNULL(LastName, 'NULL'), ';',
            'Email:', ISNULL(Email, 'NULL'), ';',
            'Salary:', ISNULL(CAST(Salary AS NVARCHAR), 'NULL')
        )
        FROM Employees WHERE EmployeeID = @EmployeeID;
        
        -- Soft delete (set IsActive = 0)
        UPDATE Employees 
        SET 
            IsActive = 0,
            ModifiedDate = GETDATE()
        WHERE EmployeeID = @EmployeeID;
        
        -- Log audit
        INSERT INTO AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedBy)
        VALUES ('Employees', @EmployeeID, 'DELETE', @OldValues, 'Employee deactivated', @DeletedBy);
        
        COMMIT TRANSACTION;
        
        SELECT 'Employee successfully deactivated' AS Result;
        
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
-- 5. Get All Employees with Pagination and Filtering
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetEmployees]
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @DepartmentID INT = NULL,
    @ManagerID INT = NULL,
    @IsActive BIT = NULL,
    @SearchTerm NVARCHAR(100) = NULL,
    @SortColumn NVARCHAR(50) = 'LastName',
    @SortDirection NVARCHAR(4) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 10;
    
    -- Validate sort column
    IF @SortColumn NOT IN ('FirstName', 'LastName', 'FullName', 'Email', 'HireDate', 'Salary', 'DepartmentName', 'JobTitle')
        SET @SortColumn = 'LastName';
    
    -- Validate sort direction
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'ASC';
    
    -- Use CTE for pagination and window functions for ranking
    WITH FilteredEmployees AS (
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
            -- Window functions for analytics
            ROW_NUMBER() OVER (
                ORDER BY 
                    CASE WHEN @SortColumn = 'FirstName' AND @SortDirection = 'ASC' THEN FirstName END ASC,
                    CASE WHEN @SortColumn = 'FirstName' AND @SortDirection = 'DESC' THEN FirstName END DESC,
                    CASE WHEN @SortColumn = 'LastName' AND @SortDirection = 'ASC' THEN LastName END ASC,
                    CASE WHEN @SortColumn = 'LastName' AND @SortDirection = 'DESC' THEN LastName END DESC,
                    CASE WHEN @SortColumn = 'FullName' AND @SortDirection = 'ASC' THEN FullName END ASC,
                    CASE WHEN @SortColumn = 'FullName' AND @SortDirection = 'DESC' THEN FullName END DESC,
                    CASE WHEN @SortColumn = 'Email' AND @SortDirection = 'ASC' THEN Email END ASC,
                    CASE WHEN @SortColumn = 'Email' AND @SortDirection = 'DESC' THEN Email END DESC,
                    CASE WHEN @SortColumn = 'HireDate' AND @SortDirection = 'ASC' THEN HireDate END ASC,
                    CASE WHEN @SortColumn = 'HireDate' AND @SortDirection = 'DESC' THEN HireDate END DESC,
                    CASE WHEN @SortColumn = 'Salary' AND @SortDirection = 'ASC' THEN Salary END ASC,
                    CASE WHEN @SortColumn = 'Salary' AND @SortDirection = 'DESC' THEN Salary END DESC,
                    CASE WHEN @SortColumn = 'DepartmentName' AND @SortDirection = 'ASC' THEN DepartmentName END ASC,
                    CASE WHEN @SortColumn = 'DepartmentName' AND @SortDirection = 'DESC' THEN DepartmentName END DESC,
                    CASE WHEN @SortColumn = 'JobTitle' AND @SortDirection = 'ASC' THEN JobTitle END ASC,
                    CASE WHEN @SortColumn = 'JobTitle' AND @SortDirection = 'DESC' THEN JobTitle END DESC
            ) AS RowNumber,
            COUNT(*) OVER() AS TotalCount
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
        WHERE 
            (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
            AND (@ManagerID IS NULL OR e.ManagerID = @ManagerID)
            AND (@IsActive IS NULL OR e.IsActive = @IsActive)
            AND (@SearchTerm IS NULL OR 
                 e.FirstName LIKE '%' + @SearchTerm + '%' OR
                 e.LastName LIKE '%' + @SearchTerm + '%' OR
                 e.FullName LIKE '%' + @SearchTerm + '%' OR
                 e.Email LIKE '%' + @SearchTerm + '%' OR
                 e.JobTitle LIKE '%' + @SearchTerm + '%' OR
                 d.DepartmentName LIKE '%' + @SearchTerm + '%')
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
        TotalCount,
        @PageNumber AS PageNumber,
        @PageSize AS PageSize,
        CEILING(CAST(TotalCount AS FLOAT) / @PageSize) AS TotalPages
    FROM FilteredEmployees
    WHERE RowNumber BETWEEN ((@PageNumber - 1) * @PageSize) + 1 AND @PageNumber * @PageSize
    ORDER BY RowNumber;
END
GO

-- =============================================
-- 6. Get Employee Statistics
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GetEmployeeStatistics]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use window functions and CTEs for comprehensive statistics
    WITH EmployeeStats AS (
        SELECT 
            COUNT(*) AS TotalEmployees,
            COUNT(CASE WHEN IsActive = 1 THEN 1 END) AS ActiveEmployees,
            COUNT(CASE WHEN IsActive = 0 THEN 1 END) AS InactiveEmployees,
            AVG(CAST(Salary AS FLOAT)) AS AverageSalary,
            MIN(Salary) AS MinSalary,
            MAX(Salary) AS MaxSalary,
            AVG(CAST(YearsOfService AS FLOAT)) AS AverageYearsOfService,
            COUNT(CASE WHEN ManagerID IS NULL THEN 1 END) AS TopLevelManagers
        FROM Employees
    ),
    DepartmentStats AS (
        SELECT 
            d.DepartmentName,
            COUNT(e.EmployeeID) AS EmployeeCount,
            AVG(CAST(e.Salary AS FLOAT)) AS AvgSalary,
            SUM(e.Salary) AS TotalSalaryBudget
        FROM Departments d
        LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
        GROUP BY d.DepartmentID, d.DepartmentName
    ),
    SalaryDistribution AS (
        SELECT 
            CASE 
                WHEN Salary < 50000 THEN 'Under 50K'
                WHEN Salary BETWEEN 50000 AND 75000 THEN '50K-75K'
                WHEN Salary BETWEEN 75000 AND 100000 THEN '75K-100K'
                WHEN Salary BETWEEN 100000 AND 150000 THEN '100K-150K'
                ELSE 'Over 150K'
            END AS SalaryRange,
            COUNT(*) AS EmployeeCount
        FROM Employees
        WHERE IsActive = 1
        GROUP BY 
            CASE 
                WHEN Salary < 50000 THEN 'Under 50K'
                WHEN Salary BETWEEN 50000 AND 75000 THEN '50K-75K'
                WHEN Salary BETWEEN 75000 AND 100000 THEN '75K-100K'
                WHEN Salary BETWEEN 100000 AND 150000 THEN '100K-150K'
                ELSE 'Over 150K'
            END
    )
    SELECT 
        'Overall Statistics' AS Category,
        TotalEmployees,
        ActiveEmployees,
        InactiveEmployees,
        AverageSalary,
        MinSalary,
        MaxSalary,
        AverageYearsOfService,
        TopLevelManagers,
        NULL AS DepartmentName,
        NULL AS EmployeeCount,
        NULL AS AvgSalary,
        NULL AS TotalSalaryBudget,
        NULL AS SalaryRange,
        NULL AS SalaryRangeCount
    FROM EmployeeStats
    
    UNION ALL
    
    SELECT 
        'Department Statistics' AS Category,
        NULL AS TotalEmployees,
        NULL AS ActiveEmployees,
        NULL AS InactiveEmployees,
        NULL AS AverageSalary,
        NULL AS MinSalary,
        NULL AS MaxSalary,
        NULL AS AverageYearsOfService,
        NULL AS TopLevelManagers,
        DepartmentName,
        EmployeeCount,
        AvgSalary,
        TotalSalaryBudget,
        NULL AS SalaryRange,
        NULL AS SalaryRangeCount
    FROM DepartmentStats
    
    UNION ALL
    
    SELECT 
        'Salary Distribution' AS Category,
        NULL AS TotalEmployees,
        NULL AS ActiveEmployees,
        NULL AS InactiveEmployees,
        NULL AS AverageSalary,
        NULL AS MinSalary,
        NULL AS MaxSalary,
        NULL AS AverageYearsOfService,
        NULL AS TopLevelManagers,
        NULL AS DepartmentName,
        NULL AS EmployeeCount,
        NULL AS AvgSalary,
        NULL AS TotalSalaryBudget,
        SalaryRange,
        EmployeeCount AS SalaryRangeCount
    FROM SalaryDistribution;
END
GO

PRINT 'Employee CRUD stored procedures created successfully!';
PRINT 'Procedures created: sp_CreateEmployee, sp_GetEmployee, sp_UpdateEmployee, sp_DeleteEmployee, sp_GetEmployees, sp_GetEmployeeStatistics';
PRINT 'Features demonstrated: CTEs, Window Functions, Error Handling, Transactions, Dynamic Sorting, Pagination';
