# Employee Management System - Database Documentation

## Overview

This comprehensive Employee Management System database demonstrates advanced T-SQL skills and enterprise-level database design. The system includes complex stored procedures, triggers, views, functions, and comprehensive audit logging.

## Database Features

### 🏗️ **Database Schema**
- **8 Core Tables**: Departments, Employees, Projects, EmployeeProjects, PerformanceReviews, SalaryHistory, AuditLog, Users
- **Advanced Constraints**: Check constraints, foreign keys, unique constraints
- **Computed Columns**: FullName, YearsOfService, Age
- **Optimized Indexes**: Performance-tuned indexes on frequently queried columns

### 📊 **Advanced T-SQL Features**

#### **Stored Procedures (16+)**
- **Employee Management**: `sp_CreateEmployee`, `sp_UpdateEmployee`, `sp_DeleteEmployee`, `sp_GetEmployeeDetails`
- **Salary Operations**: `sp_UpdateSalary`, `sp_CalculateAverageSalary`, `sp_GetSalaryBudgetAnalysis`
- **Project Management**: `sp_AssignEmployeeToProject`, `sp_GetProjectResourceAllocation`, `sp_CalculateProjectCost`
- **Performance Reviews**: `sp_CreatePerformanceReview`, `sp_GetEmployeePerformanceHistory`, `sp_CalculateAverageRating`
- **Reporting**: `sp_GetDepartmentStatistics`, `sp_GetEmployeeHierarchy`, `sp_GetTopPerformers`

#### **Triggers (6)**
- **Audit Logging**: `trg_AuditEmployees`, `trg_AuditDepartments`
- **Business Logic**: `trg_SalaryHistory`, `trg_ValidateManager`, `trg_ValidateProjectAssignment`, `trg_ValidatePerformanceReview`

#### **Views (5)**
- **Analytics Views**: `vw_EmployeeSummary`, `vw_DepartmentStats`, `vw_ActiveProjects`, `vw_PerformanceOverview`, `vw_SalaryAnalysis`

#### **Functions (4)**
- **Scalar Functions**: `fn_GetYearsOfService`, `fn_CalculateBonus`
- **Table-Valued Functions**: `fn_GetEmployeeSubordinates`, `fn_GetEmployeePerformanceHistory`

### 🔧 **Advanced T-SQL Techniques Demonstrated**

1. **Common Table Expressions (CTEs)**
   - Recursive CTEs for organizational hierarchy
   - Complex analytical queries with multiple CTEs

2. **Window Functions**
   - `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`
   - `LAG()`, `LEAD()` for trend analysis
   - `PERCENTILE_CONT()` for statistical analysis
   - `SUM() OVER()`, `AVG() OVER()` for running totals

3. **Complex Business Logic**
   - Salary validation with percentage limits
   - Project allocation validation (100% max)
   - Circular reporting prevention
   - Performance rating validation

4. **Error Handling**
   - Comprehensive `TRY...CATCH` blocks
   - Transaction management with rollback
   - Detailed error messages

5. **Performance Optimization**
   - Strategic indexing strategy
   - Query optimization with execution plans
   - Computed columns for frequently calculated values

## Installation Instructions

### Prerequisites
- SQL Server 2019+ or Azure SQL Database
- SQL Server Management Studio (SSMS)
- Appropriate permissions to create databases and objects

### Setup Steps

1. **Create Database**
   ```sql
   -- Run the database creation script
   EXEC sp_executesql @sql = '01_CreateDatabaseSchema.sql'
   ```

2. **Create Stored Procedures**
   ```sql
   -- Run in order:
   EXEC sp_executesql @sql = '02_EmployeeManagementProcedures.sql'
   EXEC sp_executesql @sql = '03_SalaryProjectProcedures.sql'
   EXEC sp_executesql @sql = '04_PerformanceReportingProcedures.sql'
   ```

3. **Create Triggers**
   ```sql
   EXEC sp_executesql @sql = '05_Triggers.sql'
   ```

4. **Create Views and Functions**
   ```sql
   EXEC sp_executesql @sql = '06_ViewsAndFunctions.sql'
   ```

5. **Insert Sample Data**
   ```sql
   EXEC sp_executesql @sql = '07_SampleData.sql'
   ```

### Quick Setup (All at Once)
```sql
-- Run all scripts in sequence
:r 01_CreateDatabaseSchema.sql
:r 02_EmployeeManagementProcedures.sql
:r 03_SalaryProjectProcedures.sql
:r 04_PerformanceReportingProcedures.sql
:r 05_Triggers.sql
:r 06_ViewsAndFunctions.sql
:r 07_SampleData.sql
```

## Sample Data Overview

The database includes realistic sample data:

- **8 Departments**: HR, IT, Finance, Marketing, Operations, Sales, R&D, Customer Service
- **36 Employees**: Complete organizational hierarchy with VPs, Directors, Managers, and Staff
- **16 Projects**: Active, completed, and planning projects across departments
- **25+ Project Assignments**: Realistic resource allocations
- **24 Performance Reviews**: Historical and current reviews with ratings
- **7 Salary Changes**: Historical salary adjustments
- **16 User Accounts**: Authentication setup for different roles

## Key Stored Procedure Examples

### Employee Management
```sql
-- Create new employee with validation
DECLARE @EmployeeID INT, @ErrorMessage NVARCHAR(500);
EXEC sp_CreateEmployee 
    @FirstName = 'John',
    @LastName = 'Doe',
    @Email = 'john.doe@company.com',
    @HireDate = '2024-01-01',
    @DepartmentID = 2,
    @JobTitle = 'Software Engineer',
    @Salary = 75000.00,
    @EmployeeID = @EmployeeID OUTPUT,
    @ErrorMessage = @ErrorMessage OUTPUT;
```

### Advanced Analytics
```sql
-- Get comprehensive department statistics
EXEC sp_GetDepartmentStatistics;

-- Get employee hierarchy
EXEC sp_GetEmployeeHierarchy @RootEmployeeID = 1;

-- Get top performers
EXEC sp_GetTopPerformers @Criteria = 'Performance', @TopCount = 10;
```

### Salary Analysis
```sql
-- Calculate average salary by department
EXEC sp_CalculateAverageSalary @GroupBy = 'Department';

-- Get salary budget analysis
EXEC sp_GetSalaryBudgetAnalysis;
```

## Advanced Query Examples

### Using Views for Analytics
```sql
-- Employee summary with all related data
SELECT * FROM vw_EmployeeSummary WHERE IsActive = 1;

-- Department statistics
SELECT * FROM vw_DepartmentStats ORDER BY AverageSalary DESC;

-- Active projects with team details
SELECT * FROM vw_ActiveProjects WHERE Status = 'Active';

-- Performance overview with trends
SELECT * FROM vw_PerformanceOverview ORDER BY PerformanceLevel DESC;
```

### Using Functions
```sql
-- Get employee subordinates (recursive)
SELECT * FROM fn_GetEmployeeSubordinates(1);

-- Get performance history with trends
SELECT * FROM fn_GetEmployeePerformanceHistory(1, 3);

-- Calculate bonus eligibility
SELECT dbo.fn_CalculateBonus(1, 2024) AS BonusAmount;
```

## Performance Features

### Indexing Strategy
- **Clustered Indexes**: Primary keys on all tables
- **Non-clustered Indexes**: Foreign keys, frequently queried columns
- **Covering Indexes**: Composite indexes for common query patterns

### Query Optimization
- **Execution Plans**: All procedures optimized with execution plan analysis
- **Statistics**: Updated statistics for optimal query performance
- **Computed Columns**: Pre-calculated values for frequently accessed data

## Security Features

### Audit Logging
- **Comprehensive Audit Trail**: All changes logged to AuditLog table
- **Field-Level Tracking**: Individual field changes tracked
- **User Attribution**: Changes attributed to specific users

### Data Validation
- **Business Rule Enforcement**: Triggers enforce complex business rules
- **Referential Integrity**: Foreign key constraints maintain data integrity
- **Check Constraints**: Data validation at the database level

## Testing the System

### Test Stored Procedures
```sql
-- Test employee creation
EXEC sp_CreateEmployee @FirstName = 'Test', @LastName = 'User', 
    @Email = 'test@company.com', @HireDate = '2024-01-01', 
    @DepartmentID = 1, @JobTitle = 'Test Role', @Salary = 50000.00;

-- Test salary update
EXEC sp_UpdateSalary @EmployeeID = 1, @NewSalary = 160000.00, 
    @ChangeReason = 'Annual increase', @ApprovedBy = 2;

-- Test project assignment
EXEC sp_AssignEmployeeToProject @EmployeeID = 1, @ProjectID = 1, 
    @Role = 'Project Manager', @AllocationPercentage = 50, 
    @StartDate = '2024-01-01';
```

### Test Triggers
```sql
-- Test audit logging
UPDATE Employees SET Salary = Salary + 1000 WHERE EmployeeID = 1;
SELECT * FROM AuditLog WHERE TableName = 'Employees' AND RecordID = 1;

-- Test manager validation
UPDATE Employees SET ManagerID = EmployeeID WHERE EmployeeID = 1; -- Should fail
```

## Database Statistics

After running the sample data script, you'll have:

- **8 Departments** with realistic budgets and locations
- **36 Employees** across all departments with complete hierarchy
- **16 Projects** in various stages (Planning, Active, Completed)
- **25+ Project Assignments** with realistic resource allocations
- **24 Performance Reviews** with detailed ratings and comments
- **7 Salary History Records** showing promotions and increases
- **16 User Accounts** for authentication testing
- **Comprehensive Audit Log** with all changes tracked

## Advanced Features Demonstrated

### 1. **Recursive Queries**
- Organizational hierarchy traversal
- Manager-subordinate relationships
- Project team hierarchies

### 2. **Window Functions**
- Running totals and averages
- Ranking and percentiles
- Trend analysis with LAG/LEAD

### 3. **Complex Business Logic**
- Salary increase validation (max 50%)
- Project allocation validation (max 100%)
- Circular reporting prevention
- Performance rating validation

### 4. **Error Handling**
- Comprehensive validation
- Transaction rollback on errors
- Detailed error messages
- Audit trail maintenance

### 5. **Performance Optimization**
- Strategic indexing
- Query optimization
- Computed columns
- Efficient joins and subqueries

## Next Steps

This database provides the foundation for:

1. **Web API Development**: Use Entity Framework Core to create REST APIs
2. **Angular Frontend**: Build modern web applications
3. **Reporting**: Create comprehensive business intelligence reports
4. **Integration**: Connect with other enterprise systems
5. **Analytics**: Implement advanced data analytics and machine learning

## Support and Maintenance

### Regular Maintenance Tasks
- Update statistics: `UPDATE STATISTICS`
- Rebuild indexes: `ALTER INDEX ALL ON TableName REBUILD`
- Clean audit log: Archive old audit records
- Monitor performance: Use SQL Server Profiler

### Backup Strategy
- Full database backups: Daily
- Transaction log backups: Every 15 minutes
- Differential backups: Every 6 hours

---

**This database demonstrates enterprise-level T-SQL skills and serves as a comprehensive foundation for building modern employee management applications.**
