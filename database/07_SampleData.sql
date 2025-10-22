-- =============================================
-- Employee Management System - Sample Data
-- Created: 2024
-- Description: Comprehensive sample data for testing and demonstration
--              Includes realistic data across all tables
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Insert Departments
-- =============================================

INSERT INTO Departments (DepartmentName, Location, Budget) VALUES
('Human Resources', 'New York', 500000.00),
('Information Technology', 'San Francisco', 2000000.00),
('Finance', 'Chicago', 800000.00),
('Marketing', 'Los Angeles', 1200000.00),
('Operations', 'Houston', 1500000.00),
('Sales', 'Boston', 1800000.00),
('Research & Development', 'Seattle', 3000000.00),
('Customer Service', 'Phoenix', 600000.00);

PRINT 'Departments inserted successfully';

-- =============================================
-- 2. Insert Employees
-- =============================================

-- First, insert employees without managers (top-level)
INSERT INTO Employees (FirstName, LastName, Email, Phone, DateOfBirth, HireDate, DepartmentID, JobTitle, Salary) VALUES
('John', 'Smith', 'john.smith@company.com', '555-0101', '1975-03-15', '2010-01-15', 1, 'VP of Human Resources', 150000.00),
('Sarah', 'Johnson', 'sarah.johnson@company.com', '555-0102', '1980-07-22', '2012-03-01', 2, 'VP of Information Technology', 180000.00),
('Michael', 'Brown', 'michael.brown@company.com', '555-0103', '1978-11-08', '2011-06-15', 3, 'VP of Finance', 170000.00),
('Emily', 'Davis', 'emily.davis@company.com', '555-0104', '1982-05-30', '2013-09-01', 4, 'VP of Marketing', 160000.00),
('David', 'Wilson', 'david.wilson@company.com', '555-0105', '1976-12-12', '2010-11-20', 5, 'VP of Operations', 175000.00),
('Lisa', 'Anderson', 'lisa.anderson@company.com', '555-0106', '1981-09-18', '2012-08-10', 6, 'VP of Sales', 190000.00),
('Robert', 'Taylor', 'robert.taylor@company.com', '555-0107', '1979-04-25', '2011-12-01', 7, 'VP of Research & Development', 200000.00),
('Jennifer', 'Thomas', 'jennifer.thomas@company.com', '555-0108', '1983-08-14', '2014-02-15', 8, 'VP of Customer Service', 140000.00);

-- Update department heads
UPDATE Departments SET DepartmentHead = 1 WHERE DepartmentID = 1;
UPDATE Departments SET DepartmentHead = 2 WHERE DepartmentID = 2;
UPDATE Departments SET DepartmentHead = 3 WHERE DepartmentID = 3;
UPDATE Departments SET DepartmentHead = 4 WHERE DepartmentID = 4;
UPDATE Departments SET DepartmentHead = 5 WHERE DepartmentID = 5;
UPDATE Departments SET DepartmentHead = 6 WHERE DepartmentID = 6;
UPDATE Departments SET DepartmentHead = 7 WHERE DepartmentID = 7;
UPDATE Departments SET DepartmentHead = 8 WHERE DepartmentID = 8;

-- Insert managers and senior employees
INSERT INTO Employees (FirstName, LastName, Email, Phone, DateOfBirth, HireDate, DepartmentID, ManagerID, JobTitle, Salary) VALUES
-- HR Department
('Mark', 'Williams', 'mark.williams@company.com', '555-0201', '1985-01-20', '2015-03-01', 1, 1, 'HR Manager', 95000.00),
('Jessica', 'Jones', 'jessica.jones@company.com', '555-0202', '1987-06-10', '2016-07-15', 1, 9, 'HR Specialist', 65000.00),
('Kevin', 'Garcia', 'kevin.garcia@company.com', '555-0203', '1984-12-05', '2014-11-20', 1, 9, 'Recruiter', 60000.00),

-- IT Department
('Amanda', 'Miller', 'amanda.miller@company.com', '555-0301', '1986-03-18', '2015-05-01', 2, 2, 'IT Director', 120000.00),
('Christopher', 'Martinez', 'christopher.martinez@company.com', '555-0302', '1988-09-12', '2017-01-15', 2, 12, 'Senior Developer', 90000.00),
('Michelle', 'Rodriguez', 'michelle.rodriguez@company.com', '555-0303', '1989-11-28', '2017-08-20', 2, 12, 'Software Engineer', 75000.00),
('Daniel', 'Lee', 'daniel.lee@company.com', '555-0304', '1987-04-15', '2016-03-10', 2, 12, 'DevOps Engineer', 85000.00),
('Ashley', 'White', 'ashley.white@company.com', '555-0305', '1990-07-22', '2018-06-01', 2, 12, 'QA Engineer', 70000.00),

-- Finance Department
('James', 'Harris', 'james.harris@company.com', '555-0401', '1983-08-30', '2014-09-15', 3, 3, 'Finance Director', 110000.00),
('Stephanie', 'Clark', 'stephanie.clark@company.com', '555-0402', '1986-02-14', '2015-11-01', 3, 17, 'Senior Accountant', 75000.00),
('Ryan', 'Lewis', 'ryan.lewis@company.com', '555-0403', '1988-10-08', '2017-04-20', 3, 17, 'Financial Analyst', 65000.00),

-- Marketing Department
('Nicole', 'Robinson', 'nicole.robinson@company.com', '555-0501', '1985-05-25', '2015-07-01', 4, 4, 'Marketing Director', 100000.00),
('Brandon', 'Walker', 'brandon.walker@company.com', '555-0502', '1987-12-18', '2016-09-15', 4, 20, 'Marketing Manager', 80000.00),
('Rachel', 'Young', 'rachel.young@company.com', '555-0503', '1989-06-03', '2018-01-20', 4, 20, 'Digital Marketing Specialist', 60000.00),

-- Operations Department
('Tyler', 'Allen', 'tyler.allen@company.com', '555-0601', '1984-11-12', '2014-12-01', 5, 5, 'Operations Director', 115000.00),
('Samantha', 'King', 'samantha.king@company.com', '555-0602', '1986-08-07', '2015-10-15', 5, 23, 'Operations Manager', 85000.00),
('Justin', 'Wright', 'justin.wright@company.com', '555-0603', '1988-03-29', '2017-05-10', 5, 23, 'Process Analyst', 70000.00),

-- Sales Department
('Megan', 'Lopez', 'megan.lopez@company.com', '555-0701', '1983-09-16', '2014-08-01', 6, 6, 'Sales Director', 130000.00),
('Andrew', 'Hill', 'andrew.hill@company.com', '555-0702', '1985-01-24', '2015-12-15', 6, 26, 'Sales Manager', 90000.00),
('Lauren', 'Scott', 'lauren.scott@company.com', '555-0703', '1987-07-11', '2016-11-20', 6, 26, 'Account Executive', 75000.00),
('Jordan', 'Green', 'jordan.green@company.com', '555-0704', '1989-04-05', '2018-03-01', 6, 26, 'Sales Representative', 60000.00),

-- R&D Department
('Alexis', 'Adams', 'alexis.adams@company.com', '555-0801', '1982-12-20', '2013-06-01', 7, 7, 'R&D Director', 140000.00),
('Nathan', 'Baker', 'nathan.baker@company.com', '555-0802', '1984-05-13', '2014-10-15', 7, 30, 'Senior Research Scientist', 95000.00),
('Kayla', 'Gonzalez', 'kayla.gonzalez@company.com', '555-0803', '1986-10-27', '2016-02-20', 7, 30, 'Research Scientist', 80000.00),
('Zachary', 'Nelson', 'zachary.nelson@company.com', '555-0804', '1988-08-09', '2017-09-10', 7, 30, 'Product Manager', 85000.00),

-- Customer Service Department
('Brittany', 'Carter', 'brittany.carter@company.com', '555-0901', '1985-06-14', '2015-04-01', 8, 8, 'Customer Service Director', 95000.00),
('Cody', 'Mitchell', 'cody.mitchell@company.com', '555-0902', '1987-11-02', '2016-08-15', 8, 34, 'Customer Service Manager', 70000.00),
('Taylor', 'Perez', 'taylor.perez@company.com', '555-0903', '1989-03-18', '2018-01-10', 8, 34, 'Customer Service Representative', 45000.00);

PRINT 'Employees inserted successfully';

-- =============================================
-- 3. Insert Projects
-- =============================================

INSERT INTO Projects (ProjectName, Description, StartDate, EndDate, Budget, Status, DepartmentID) VALUES
-- IT Projects
('Website Redesign', 'Complete redesign of company website with modern UI/UX', '2024-01-15', '2024-06-30', 150000.00, 'Active', 2),
('Mobile App Development', 'Development of mobile application for customer portal', '2024-02-01', '2024-08-31', 200000.00, 'Active', 2),
('Cloud Migration', 'Migration of on-premise systems to cloud infrastructure', '2024-03-01', '2024-12-31', 300000.00, 'Planning', 2),
('Security Enhancement', 'Implementation of enhanced security measures', '2023-10-01', '2024-03-31', 100000.00, 'Completed', 2),

-- Marketing Projects
('Brand Awareness Campaign', 'Q2 brand awareness campaign across digital channels', '2024-04-01', '2024-06-30', 80000.00, 'Active', 4),
('Social Media Strategy', 'Development and implementation of social media strategy', '2024-01-01', '2024-12-31', 120000.00, 'Active', 4),
('Product Launch Campaign', 'Marketing campaign for new product launch', '2023-08-01', '2023-12-31', 150000.00, 'Completed', 4),

-- R&D Projects
('AI Integration', 'Integration of AI capabilities into existing products', '2024-01-01', '2024-09-30', 500000.00, 'Active', 7),
('New Product Development', 'Development of next-generation product line', '2023-06-01', '2024-05-31', 800000.00, 'Active', 7),
('Research Study', 'Market research study for emerging technologies', '2024-02-15', '2024-07-31', 200000.00, 'Planning', 7),

-- Operations Projects
('Process Optimization', 'Optimization of operational processes', '2024-03-01', '2024-08-31', 100000.00, 'Active', 5),
('Supply Chain Improvement', 'Improvement of supply chain efficiency', '2023-11-01', '2024-04-30', 150000.00, 'Completed', 5),

-- HR Projects
('Employee Engagement Program', 'Implementation of employee engagement initiatives', '2024-01-01', '2024-12-31', 75000.00, 'Active', 1),
('Training Program Development', 'Development of comprehensive training programs', '2024-02-01', '2024-10-31', 100000.00, 'Planning', 1),

-- Sales Projects
('CRM Implementation', 'Implementation of new CRM system', '2024-01-15', '2024-07-31', 200000.00, 'Active', 6),
('Sales Process Improvement', 'Improvement of sales processes and methodologies', '2023-09-01', '2024-02-29', 80000.00, 'Completed', 6);

PRINT 'Projects inserted successfully';

-- =============================================
-- 4. Insert Employee Projects (Assignments)
-- =============================================

INSERT INTO EmployeeProjects (EmployeeID, ProjectID, Role, AllocationPercentage, StartDate, EndDate) VALUES
-- Website Redesign Project
(12, 1, 'Project Lead', 50, '2024-01-15', NULL),
(13, 1, 'Frontend Developer', 80, '2024-01-15', NULL),
(14, 1, 'Backend Developer', 70, '2024-01-15', NULL),
(15, 1, 'QA Tester', 60, '2024-02-01', NULL),

-- Mobile App Development Project
(12, 2, 'Technical Lead', 40, '2024-02-01', NULL),
(13, 2, 'Mobile Developer', 90, '2024-02-01', NULL),
(14, 2, 'API Developer', 60, '2024-02-01', NULL),
(15, 2, 'QA Engineer', 50, '2024-02-15', NULL),

-- Brand Awareness Campaign
(20, 5, 'Campaign Manager', 70, '2024-04-01', NULL),
(21, 5, 'Digital Marketing Specialist', 80, '2024-04-01', NULL),
(22, 5, 'Content Creator', 60, '2024-04-01', NULL),

-- AI Integration Project
(30, 8, 'Project Manager', 60, '2024-01-01', NULL),
(31, 8, 'AI Engineer', 90, '2024-01-01', NULL),
(32, 8, 'Data Scientist', 80, '2024-01-01', NULL),
(33, 8, 'Product Manager', 50, '2024-01-01', NULL),

-- Process Optimization Project
(23, 11, 'Project Lead', 70, '2024-03-01', NULL),
(24, 11, 'Process Analyst', 80, '2024-03-01', NULL),
(25, 11, 'Operations Specialist', 60, '2024-03-01', NULL),

-- Employee Engagement Program
(9, 13, 'Program Manager', 60, '2024-01-01', NULL),
(10, 13, 'HR Specialist', 70, '2024-01-01', NULL),
(11, 13, 'Training Coordinator', 50, '2024-01-01', NULL),

-- CRM Implementation
(26, 15, 'Project Manager', 50, '2024-01-15', NULL),
(27, 15, 'Sales Manager', 40, '2024-01-15', NULL),
(28, 15, 'Sales Representative', 30, '2024-01-15', NULL);

PRINT 'Employee project assignments inserted successfully';

-- =============================================
-- 5. Insert Performance Reviews
-- =============================================

INSERT INTO PerformanceReviews (EmployeeID, ReviewerID, ReviewDate, ReviewPeriodStart, ReviewPeriodEnd, OverallRating, TechnicalSkills, Communication, Teamwork, Leadership, Comments, Goals) VALUES
-- 2023 Reviews
(1, 2, '2023-12-15', '2023-01-01', '2023-12-31', 4, 3, 5, 4, 5, 'Strong leadership in HR initiatives. Excellent communication skills.', 'Focus on technical skills development, continue building team culture'),
(2, 1, '2023-12-15', '2023-01-01', '2023-12-31', 5, 5, 4, 4, 5, 'Outstanding technical leadership. Successfully led multiple IT projects.', 'Continue mentoring junior developers, improve cross-department communication'),
(3, 1, '2023-12-15', '2023-01-01', '2023-12-31', 4, 4, 4, 5, 4, 'Solid performance in finance management. Great team player.', 'Develop stronger leadership presence, enhance technical skills'),
(4, 1, '2023-12-15', '2023-01-01', '2023-12-31', 4, 3, 5, 4, 4, 'Excellent marketing campaigns. Strong communication skills.', 'Improve technical understanding of digital tools, lead more strategic initiatives'),
(5, 1, '2023-12-15', '2023-01-01', '2023-12-31', 4, 4, 4, 4, 4, 'Consistent performance in operations. Good team collaboration.', 'Enhance leadership skills, take on more complex projects'),
(6, 1, '2023-12-15', '2023-01-01', '2023-12-31', 5, 4, 5, 4, 5, 'Exceptional sales results. Strong leadership and communication.', 'Continue driving sales growth, mentor sales team members'),
(7, 1, '2023-12-15', '2023-01-01', '2023-12-31', 5, 5, 4, 5, 5, 'Outstanding R&D leadership. Innovative thinking and team building.', 'Focus on commercializing research, strengthen business acumen'),
(8, 1, '2023-12-15', '2023-01-01', '2023-12-31', 4, 3, 5, 5, 4, 'Great customer service leadership. Excellent team management.', 'Develop technical skills, enhance strategic planning'),

-- 2024 Reviews (Mid-year)
(9, 1, '2024-06-15', '2024-01-01', '2024-06-30', 4, 3, 4, 4, 4, 'Good HR management skills. Effective team leadership.', 'Improve technical HR systems knowledge, enhance employee engagement programs'),
(12, 2, '2024-06-15', '2024-01-01', '2024-06-30', 5, 5, 4, 4, 4, 'Excellent technical leadership. Successfully managing multiple projects.', 'Continue technical growth, improve project management skills'),
(13, 12, '2024-06-15', '2024-01-01', '2024-06-30', 4, 5, 3, 4, 3, 'Strong development skills. Needs improvement in communication.', 'Focus on communication skills, take on more leadership responsibilities'),
(14, 12, '2024-06-15', '2024-01-01', '2024-06-30', 4, 4, 4, 4, 3, 'Solid technical performance. Good team collaboration.', 'Develop leadership skills, enhance system architecture knowledge'),
(15, 12, '2024-06-15', '2024-01-01', '2024-06-30', 4, 4, 4, 5, 3, 'Excellent QA work. Great attention to detail and teamwork.', 'Improve automation skills, take on test strategy responsibilities'),
(20, 4, '2024-06-15', '2024-01-01', '2024-06-30', 4, 3, 5, 4, 4, 'Strong marketing leadership. Excellent campaign management.', 'Enhance digital marketing technical skills, develop team members'),
(26, 6, '2024-06-15', '2024-01-01', '2024-06-30', 4, 3, 4, 4, 4, 'Good sales management. Effective team leadership.', 'Improve CRM technical skills, enhance sales process optimization'),
(30, 7, '2024-06-15', '2024-01-01', '2024-06-30', 5, 5, 4, 5, 4, 'Outstanding research leadership. Strong technical and team skills.', 'Focus on commercial applications, strengthen business partnerships');

PRINT 'Performance reviews inserted successfully';

-- =============================================
-- 6. Insert Salary History (Some historical changes)
-- =============================================

-- Insert some salary changes for demonstration
INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy) VALUES
(9, 85000.00, 95000.00, '2024-01-01', 'Promotion to HR Manager', 1),
(12, 100000.00, 120000.00, '2024-01-01', 'Promotion to IT Director', 2),
(13, 70000.00, 75000.00, '2024-01-01', 'Annual salary increase', 12),
(14, 80000.00, 85000.00, '2024-01-01', 'Annual salary increase', 12),
(20, 90000.00, 100000.00, '2024-01-01', 'Promotion to Marketing Director', 4),
(26, 85000.00, 90000.00, '2024-01-01', 'Annual salary increase', 6),
(30, 120000.00, 140000.00, '2024-01-01', 'Promotion to R&D Director', 7);

PRINT 'Salary history inserted successfully';

-- =============================================
-- 7. Insert Users (for authentication)
-- =============================================

-- Insert users for key employees (using simple password hash for demo)
INSERT INTO Users (EmployeeID, Username, PasswordHash, Role, IsActive) VALUES
(1, 'john.smith', 'hashed_password_1', 'Admin', 1),
(2, 'sarah.johnson', 'hashed_password_2', 'Admin', 1),
(3, 'michael.brown', 'hashed_password_3', 'Manager', 1),
(4, 'emily.davis', 'hashed_password_4', 'Manager', 1),
(5, 'david.wilson', 'hashed_password_5', 'Manager', 1),
(6, 'lisa.anderson', 'hashed_password_6', 'Manager', 1),
(7, 'robert.taylor', 'hashed_password_7', 'Manager', 1),
(8, 'jennifer.thomas', 'hashed_password_8', 'Manager', 1),
(9, 'mark.williams', 'hashed_password_9', 'Manager', 1),
(12, 'amanda.miller', 'hashed_password_12', 'Manager', 1),
(20, 'nicole.robinson', 'hashed_password_20', 'Manager', 1),
(26, 'megan.lopez', 'hashed_password_26', 'Manager', 1),
(30, 'alexis.adams', 'hashed_password_30', 'Manager', 1),
(13, 'christopher.martinez', 'hashed_password_13', 'Employee', 1),
(14, 'michelle.rodriguez', 'hashed_password_14', 'Employee', 1),
(15, 'daniel.lee', 'hashed_password_15', 'Employee', 1);

PRINT 'Users inserted successfully';

-- =============================================
-- 8. Update some employees to have managers (create hierarchy)
-- =============================================

-- Update some employees to report to department heads
UPDATE Employees SET ManagerID = 1 WHERE EmployeeID IN (9, 10, 11);
UPDATE Employees SET ManagerID = 2 WHERE EmployeeID IN (12, 13, 14, 15);
UPDATE Employees SET ManagerID = 3 WHERE EmployeeID IN (17, 18, 19);
UPDATE Employees SET ManagerID = 4 WHERE EmployeeID IN (20, 21, 22);
UPDATE Employees SET ManagerID = 5 WHERE EmployeeID IN (23, 24, 25);
UPDATE Employees SET ManagerID = 6 WHERE EmployeeID IN (26, 27, 28, 29);
UPDATE Employees SET ManagerID = 7 WHERE EmployeeID IN (30, 31, 32, 33);
UPDATE Employees SET ManagerID = 8 WHERE EmployeeID IN (34, 35, 36);

-- Create some additional management levels
UPDATE Employees SET ManagerID = 9 WHERE EmployeeID IN (10, 11);
UPDATE Employees SET ManagerID = 12 WHERE EmployeeID IN (13, 14, 15);
UPDATE Employees SET ManagerID = 17 WHERE EmployeeID IN (18, 19);
UPDATE Employees SET ManagerID = 20 WHERE EmployeeID IN (21, 22);
UPDATE Employees SET ManagerID = 23 WHERE EmployeeID IN (24, 25);
UPDATE Employees SET ManagerID = 26 WHERE EmployeeID IN (27, 28, 29);
UPDATE Employees SET ManagerID = 30 WHERE EmployeeID IN (31, 32, 33);
UPDATE Employees SET ManagerID = 34 WHERE EmployeeID IN (35, 36);

PRINT 'Employee hierarchy updated successfully';

-- =============================================
-- 9. Display Summary Statistics
-- =============================================

PRINT '=== SAMPLE DATA SUMMARY ===';
PRINT 'Departments: ' + CAST((SELECT COUNT(*) FROM Departments) AS NVARCHAR(10));
PRINT 'Employees: ' + CAST((SELECT COUNT(*) FROM Employees) AS NVARCHAR(10));
PRINT 'Projects: ' + CAST((SELECT COUNT(*) FROM Projects) AS NVARCHAR(10));
PRINT 'Employee Project Assignments: ' + CAST((SELECT COUNT(*) FROM EmployeeProjects) AS NVARCHAR(10));
PRINT 'Performance Reviews: ' + CAST((SELECT COUNT(*) FROM PerformanceReviews) AS NVARCHAR(10));
PRINT 'Salary History Records: ' + CAST((SELECT COUNT(*) FROM SalaryHistory) AS NVARCHAR(10));
PRINT 'Users: ' + CAST((SELECT COUNT(*) FROM Users) AS NVARCHAR(10));

-- Display department statistics
PRINT '';
PRINT '=== DEPARTMENT STATISTICS ===';
SELECT 
    d.DepartmentName,
    COUNT(e.EmployeeID) AS EmployeeCount,
    AVG(e.Salary) AS AverageSalary,
    COUNT(p.ProjectID) AS ProjectCount
FROM Departments d
LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY EmployeeCount DESC;

PRINT '';
PRINT 'Sample data insertion completed successfully!';
PRINT 'The database now contains realistic test data for all features.';
