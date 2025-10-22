# Employee Management System

A comprehensive Employee Management System built with Angular 17+ and SQL Server, demonstrating advanced T-SQL features, modern Angular architecture, and best practices.

## 🚀 Features

### Core Features
- **Employee CRUD Operations** - Complete employee lifecycle management
- **Department Management** - Hierarchical department structure with budget tracking
- **Project Assignments** - Many-to-many relationships between employees and projects
- **Performance Review System** - Comprehensive performance tracking and analytics
- **Salary History Tracking** - Complete salary change audit trail
- **Audit Logging System** - Full data change tracking with triggers
- **Reporting Dashboard** - Real-time analytics with charts and visualizations

### T-SQL Advanced Features
- **Complex Stored Procedures** - Employee CRUD, salary calculations, performance aggregations
- **Advanced Triggers** - Comprehensive audit logging for all data changes
- **Reporting Views** - Optimized views for dashboard analytics
- **Window Functions** - Ranking, percentiles, and advanced analytics
- **CTEs (Common Table Expressions)** - Complex hierarchical queries
- **Indexed Views** - Performance optimization for reporting
- **Error Handling** - Comprehensive TRY-CATCH blocks
- **Transactions** - Data integrity and consistency

### Angular Features
- **Angular 17+** - Latest Angular with standalone components
- **Repository Pattern** - Clean separation of data access logic
- **Dependency Injection** - Proper service architecture
- **Reactive Forms** - Form validation and user experience
- **RxJS** - Advanced async operations and data streams
- **Component Architecture** - Modular, reusable components
- **Routing & Navigation** - Single-page application navigation
- **Role-based Access** - Admin/Manager/Employee permission levels

## 📋 Prerequisites

- **Node.js** (v18 or higher)
- **npm** (v9 or higher)
- **SQL Server** (2019 or higher)
- **SQL Server Management Studio** (SSMS)
- **Angular CLI** (v17+)

## 🛠️ Installation & Setup

### 1. Database Setup

1. **Open SQL Server Management Studio** and connect to your SQL Server instance

2. **Run the database scripts in order:**
   ```sql
   -- 1. Create database schema
   database/01_CreateDatabaseSchema.sql
   
   -- 2. Create stored procedures
   database/02_StoredProcedures_EmployeeCRUD.sql
   database/03_StoredProcedures_SalaryCalculations.sql
   database/04_StoredProcedures_PerformanceReviews.sql
   database/05_StoredProcedures_DepartmentSummaries.sql
   
   -- 3. Create triggers
   database/06_Triggers_AuditLogging.sql
   
   -- 4. Create views
   database/07_Views_ReportingDashboards.sql
   
   -- 5. Insert sample data
   database/08_SampleData_TestScripts.sql
   ```

3. **Verify the database setup:**
   ```sql
   USE EmployeeManagementDB;
   SELECT COUNT(*) FROM Employees;
   SELECT COUNT(*) FROM Departments;
   SELECT COUNT(*) FROM Projects;
   ```

### 2. Angular Frontend Setup

1. **Navigate to the frontend directory:**
   ```bash
   cd employee-management-frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Install additional packages:**
   ```bash
   npm install @angular/material@^17.0.0 @angular/cdk@^17.0.0 @angular/animations@^17.0.0 chart.js@^4.0.0 ng2-charts@^5.0.0 rxjs@^7.8.0
   ```

4. **Start the development server:**
   ```bash
   npm start
   ```

5. **Open your browser** and navigate to `http://localhost:4200`

## 🏗️ Project Structure

```
EmployeeManagementSystem/
├── database/                          # SQL Server database scripts
│   ├── 01_CreateDatabaseSchema.sql   # Database schema and tables
│   ├── 02_StoredProcedures_EmployeeCRUD.sql
│   ├── 03_StoredProcedures_SalaryCalculations.sql
│   ├── 04_StoredProcedures_PerformanceReviews.sql
│   ├── 05_StoredProcedures_DepartmentSummaries.sql
│   ├── 06_Triggers_AuditLogging.sql
│   ├── 07_Views_ReportingDashboards.sql
│   └── 08_SampleData_TestScripts.sql
│
└── employee-management-frontend/      # Angular application
    ├── src/
    │   ├── app/
    │   │   ├── core/                  # Core functionality
    │   │   │   ├── models/           # TypeScript interfaces
    │   │   │   ├── repositories/      # Repository pattern implementation
    │   │   │   └── services/         # Core services (HTTP, Auth, Dashboard)
    │   │   ├── shared/               # Shared components and modules
    │   │   │   └── components/      # Reusable UI components
    │   │   ├── features/            # Feature modules
    │   │   │   ├── dashboard/       # Dashboard component
    │   │   │   └── employee-list/   # Employee management
    │   │   ├── app.component.ts    # Main app component
    │   │   ├── app.routes.ts       # Routing configuration
    │   │   └── main.ts            # Application bootstrap
    │   ├── styles.scss            # Global styles
    │   └── index.html             # Main HTML template
    ├── package.json              # Dependencies and scripts
    └── angular.json             # Angular CLI configuration
```

## 🎯 Key Components

### Database Components

#### Tables
- **Employees** - Employee information with computed columns (FullName, YearsOfService, Age)
- **Departments** - Department structure with budget tracking
- **Projects** - Project management with status tracking
- **EmployeeProjects** - Many-to-many relationship with allocation percentages
- **PerformanceReviews** - Comprehensive performance evaluation system
- **SalaryHistory** - Complete salary change audit trail
- **AuditLog** - System-wide change tracking
- **Users** - Authentication and role management

#### Stored Procedures
- **Employee CRUD** - `sp_CreateEmployee`, `sp_GetEmployee`, `sp_UpdateEmployee`, `sp_DeleteEmployee`
- **Salary Calculations** - `sp_CalculateEmployeeBonus`, `sp_CalculateDepartmentSalaryBudget`
- **Performance Analytics** - `sp_GetEmployeePerformanceSummary`, `sp_GetTopPerformersAnalysis`
- **Department Management** - `sp_GetDepartmentHierarchy`, `sp_GetDepartmentSummaryDashboard`

#### Views
- **vw_EmployeeDashboard** - Comprehensive employee analytics
- **vw_DepartmentDashboard** - Department performance metrics
- **vw_PerformanceAnalytics** - Performance review analytics
- **vw_SalaryAnalytics** - Salary analysis and recommendations
- **vw_ProjectAnalytics** - Project management insights

### Angular Components

#### Core Services
- **HttpService** - Centralized HTTP operations with error handling
- **AuthService** - Authentication and role-based access control
- **DashboardService** - Dashboard data aggregation
- **EmployeeRepository** - Employee data access layer
- **DepartmentRepository** - Department data access layer

#### UI Components
- **DashboardComponent** - Main dashboard with key metrics
- **EmployeeListComponent** - Employee management with filtering and sorting
- **LoadingSpinnerComponent** - Reusable loading indicator
- **ErrorMessageComponent** - Error display component
- **ConfirmationDialogComponent** - Confirmation dialogs

## 🔧 Configuration

### Database Connection
Update the connection string in your backend API to connect to your SQL Server instance:

```typescript
// In your backend API configuration
const connectionString = "Server=localhost;Database=EmployeeManagementDB;Trusted_Connection=true;";
```

### API Endpoints
The frontend expects the following API endpoints:

```
GET    /api/employees              # Get all employees with pagination
GET    /api/employees/{id}         # Get employee by ID
POST   /api/employees              # Create new employee
PUT    /api/employees/{id}         # Update employee
DELETE /api/employees/{id}         # Delete employee
GET    /api/departments            # Get all departments
GET    /api/dashboard/summary      # Get dashboard summary
```

## 🧪 Testing

### Database Testing
Run the test scripts included in `08_SampleData_TestScripts.sql`:

```sql
-- Test employee CRUD operations
EXEC sp_CreateEmployee @FirstName='Test', @LastName='Employee', ...

-- Test performance analytics
EXEC sp_GetEmployeePerformanceSummary @EmployeeID=1, @Year=2024

-- Test salary calculations
EXEC sp_CalculateEmployeeBonus @EmployeeID=1, @ReviewYear=2024
```

### Frontend Testing
```bash
# Run unit tests
npm test

# Run e2e tests
npm run e2e

# Run linting
npm run lint
```

## 📊 Sample Data

The system includes comprehensive sample data:
- **27 Employees** across 8 departments
- **8 Departments** with realistic budgets and hierarchies
- **10 Projects** in various stages
- **27 Performance Reviews** with detailed ratings
- **81 Salary History Records** showing progression
- **26 User Accounts** with different roles

## 🚀 Usage Examples

### Employee Management
```typescript
// Get employees with filtering
const employees = await this.employeeRepository.getAll({
  pageNumber: 1,
  pageSize: 10,
  departmentID: 2,
  searchTerm: 'developer'
});

// Create new employee
const newEmployee = await this.employeeRepository.create({
  firstName: 'John',
  lastName: 'Doe',
  email: 'john.doe@company.com',
  departmentID: 2,
  salary: 75000
});
```

### Performance Analytics
```sql
-- Get top performers
EXEC sp_GetTopPerformersAnalysis @TopCount=10, @Year=2024

-- Get department performance
EXEC sp_GetDepartmentPerformanceAnalytics @DepartmentID=2, @Year=2024
```

### Dashboard Analytics
```typescript
// Get dashboard summary
const summary = await this.dashboardService.getDashboardSummary();

// Get performance trends
const trends = await this.dashboardService.getPerformanceTrends(2023, 2024);
```

## 🔒 Security Features

- **Role-based Access Control** - Admin, Manager, Employee roles
- **Audit Logging** - Complete change tracking
- **Data Validation** - Comprehensive input validation
- **SQL Injection Prevention** - Parameterized queries
- **Authentication** - JWT-based authentication system

## 📈 Performance Optimizations

### Database
- **Indexed Views** - Pre-computed aggregations
- **Strategic Indexing** - Optimized query performance
- **Computed Columns** - PERSISTED columns for frequently accessed data
- **Window Functions** - Efficient ranking and analytics

### Frontend
- **Lazy Loading** - Route-based code splitting
- **OnPush Change Detection** - Optimized change detection
- **RxJS Operators** - Efficient data stream processing
- **Component Reusability** - Shared component library

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Verify SQL Server is running
   - Check connection string
   - Ensure database exists

2. **Angular Build Issues**
   - Clear node_modules: `rm -rf node_modules && npm install`
   - Update Angular CLI: `npm install -g @angular/cli@latest`

3. **Missing Dependencies**
   - Run `npm install` in the frontend directory
   - Check package.json for version conflicts

### Performance Issues

1. **Slow Database Queries**
   - Check index usage with execution plans
   - Optimize stored procedures
   - Consider adding more indexes

2. **Frontend Performance**
   - Use Angular DevTools for profiling
   - Implement OnPush change detection
   - Optimize RxJS operators

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Angular team for the excellent framework
- Microsoft for SQL Server and T-SQL
- The open-source community for various libraries and tools

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the sample data and test scripts

---

**Happy Coding! 🚀**
