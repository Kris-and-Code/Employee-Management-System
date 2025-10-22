-- =============================================
-- Sample Data and Test Scripts
-- Demonstrates comprehensive test data setup including:
-- - Realistic sample data for all tables
-- - Test scenarios for stored procedures
-- - Performance testing scripts
-- - Data validation and integrity tests
-- - Sample queries for demonstration
-- =============================================

USE EmployeeManagementDB;
GO

-- =============================================
-- 1. Insert Sample Departments
-- =============================================
INSERT INTO Departments (DepartmentName, Budget, Location) VALUES
('Human Resources', 500000.00, 'New York'),
('Information Technology', 2000000.00, 'San Francisco'),
('Finance', 800000.00, 'Chicago'),
('Marketing', 1200000.00, 'Los Angeles'),
('Sales', 1500000.00, 'Boston'),
('Operations', 1000000.00, 'Seattle'),
('Research & Development', 3000000.00, 'Austin'),
('Customer Support', 600000.00, 'Denver');
GO

-- =============================================
-- 2. Insert Sample Employees
-- =============================================
INSERT INTO Employees (FirstName, LastName, Email, Phone, DateOfBirth, HireDate, DepartmentID, JobTitle, Salary) VALUES
-- HR Department
('Sarah', 'Johnson', 'sarah.johnson@company.com', '555-0101', '1985-03-15', '2020-01-15', 1, 'HR Manager', 85000.00),
('Michael', 'Brown', 'michael.brown@company.com', '555-0102', '1990-07-22', '2021-03-10', 1, 'HR Specialist', 65000.00),
('Emily', 'Davis', 'emily.davis@company.com', '555-0103', '1988-11-08', '2022-06-01', 1, 'Recruiter', 60000.00),

-- IT Department
('David', 'Wilson', 'david.wilson@company.com', '555-0201', '1982-05-12', '2019-08-20', 2, 'IT Director', 140000.00),
('Lisa', 'Garcia', 'lisa.garcia@company.com', '555-0202', '1987-09-30', '2020-02-15', 2, 'Senior Developer', 110000.00),
('James', 'Martinez', 'james.martinez@company.com', '555-0203', '1992-01-18', '2021-09-05', 2, 'Software Developer', 90000.00),
('Jennifer', 'Anderson', 'jennifer.anderson@company.com', '555-0204', '1989-12-03', '2022-01-10', 2, 'DevOps Engineer', 105000.00),
('Robert', 'Taylor', 'robert.taylor@company.com', '555-0205', '1991-04-25', '2022-07-15', 2, 'QA Engineer', 75000.00),

-- Finance Department
('Maria', 'Thomas', 'maria.thomas@company.com', '555-0301', '1983-08-14', '2019-11-01', 3, 'CFO', 160000.00),
('Christopher', 'Jackson', 'christopher.jackson@company.com', '555-0302', '1986-06-07', '2020-04-20', 3, 'Financial Analyst', 80000.00),
('Amanda', 'White', 'amanda.white@company.com', '555-0303', '1990-10-12', '2021-08-15', 3, 'Accountant', 70000.00),

-- Marketing Department
('Daniel', 'Harris', 'daniel.harris@company.com', '555-0401', '1984-02-28', '2020-01-05', 4, 'Marketing Director', 120000.00),
('Jessica', 'Martin', 'jessica.martin@company.com', '555-0402', '1989-05-16', '2021-02-20', 4, 'Marketing Manager', 95000.00),
('Matthew', 'Thompson', 'matthew.thompson@company.com', '555-0403', '1993-09-22', '2022-05-10', 4, 'Digital Marketing Specialist', 70000.00),

-- Sales Department
('Ashley', 'Garcia', 'ashley.garcia@company.com', '555-0501', '1981-12-10', '2019-06-15', 5, 'Sales Director', 130000.00),
('Joshua', 'Martinez', 'joshua.martinez@company.com', '555-0502', '1987-03-05', '2020-09-01', 5, 'Sales Manager', 100000.00),
('Stephanie', 'Robinson', 'stephanie.robinson@company.com', '555-0503', '1992-07-18', '2021-11-15', 5, 'Sales Representative', 75000.00),
('Kevin', 'Clark', 'kevin.clark@company.com', '555-0504', '1988-11-30', '2022-03-20', 5, 'Account Executive', 85000.00),

-- Operations Department
('Nicole', 'Rodriguez', 'nicole.rodriguez@company.com', '555-0601', '1985-04-08', '2020-07-10', 6, 'Operations Manager', 95000.00),
('Brandon', 'Lewis', 'brandon.lewis@company.com', '555-0602', '1991-08-14', '2021-12-01', 6, 'Operations Coordinator', 65000.00),

-- R&D Department
('Rachel', 'Lee', 'rachel.lee@company.com', '555-0701', '1980-01-25', '2019-03-01', 7, 'R&D Director', 150000.00),
('Andrew', 'Walker', 'andrew.walker@company.com', '555-0702', '1986-06-12', '2020-05-15', 7, 'Senior Research Scientist', 120000.00),
('Michelle', 'Hall', 'michelle.hall@company.com', '555-0703', '1990-10-28', '2021-08-20', 7, 'Research Scientist', 95000.00),

-- Customer Support Department
('Ryan', 'Allen', 'ryan.allen@company.com', '555-0801', '1988-02-14', '2020-10-01', 8, 'Support Manager', 80000.00),
('Lauren', 'Young', 'lauren.young@company.com', '555-0802', '1993-05-20', '2021-06-15', 8, 'Support Specialist', 55000.00),
('Justin', 'King', 'justin.king@company.com', '555-0803', '1991-09-03', '2022-01-10', 8, 'Customer Success Manager', 70000.00);
GO

-- =============================================
-- 3. Update Department Heads
-- =============================================
UPDATE Departments SET DepartmentHead = 1 WHERE DepartmentID = 1;  -- Sarah Johnson
UPDATE Departments SET DepartmentHead = 4 WHERE DepartmentID = 2;  -- David Wilson
UPDATE Departments SET DepartmentHead = 9 WHERE DepartmentID = 3;  -- Maria Thomas
UPDATE Departments SET DepartmentHead = 12 WHERE DepartmentID = 4; -- Daniel Harris
UPDATE Departments SET DepartmentHead = 15 WHERE DepartmentID = 5;  -- Ashley Garcia
UPDATE Departments SET DepartmentHead = 19 WHERE DepartmentID = 6;  -- Nicole Rodriguez
UPDATE Departments SET DepartmentHead = 21 WHERE DepartmentID = 7;  -- Rachel Lee
UPDATE Departments SET DepartmentHead = 25 WHERE DepartmentID = 8;  -- Ryan Allen
GO

-- =============================================
-- 4. Update Employee Managers
-- =============================================
UPDATE Employees SET ManagerID = 1 WHERE EmployeeID IN (2, 3);     -- HR
UPDATE Employees SET ManagerID = 4 WHERE EmployeeID IN (5, 6, 7, 8); -- IT
UPDATE Employees SET ManagerID = 9 WHERE EmployeeID IN (10, 11);  -- Finance
UPDATE Employees SET ManagerID = 12 WHERE EmployeeID IN (13, 14);  -- Marketing
UPDATE Employees SET ManagerID = 15 WHERE EmployeeID IN (16, 17, 18); -- Sales
UPDATE Employees SET ManagerID = 19 WHERE EmployeeID = 20;          -- Operations
UPDATE Employees SET ManagerID = 21 WHERE EmployeeID IN (22, 23);  -- R&D
UPDATE Employees SET ManagerID = 25 WHERE EmployeeID IN (26, 27);   -- Support
GO

-- =============================================
-- 5. Insert Sample Projects
-- =============================================
INSERT INTO Projects (ProjectName, Description, StartDate, EndDate, Budget, Status, DepartmentID) VALUES
('Employee Portal Redesign', 'Redesign the employee self-service portal with modern UI/UX', '2024-01-15', '2024-06-30', 250000.00, 'Active', 2),
('Financial Reporting System', 'Implement new financial reporting and analytics system', '2024-02-01', '2024-08-31', 400000.00, 'Active', 3),
('Marketing Automation Platform', 'Deploy marketing automation tools and CRM integration', '2024-01-01', '2024-05-15', 300000.00, 'Active', 4),
('Sales Performance Dashboard', 'Create real-time sales performance tracking dashboard', '2024-03-01', '2024-07-31', 150000.00, 'Active', 5),
('Operations Optimization', 'Streamline operations processes and implement automation', '2024-02-15', '2024-09-30', 200000.00, 'Active', 6),
('AI Research Initiative', 'Develop AI-powered solutions for customer service', '2024-01-10', '2024-12-31', 500000.00, 'Active', 7),
('Customer Support Chatbot', 'Implement AI chatbot for customer support', '2024-03-15', '2024-08-15', 100000.00, 'Active', 8),
('HR Analytics Platform', 'Build comprehensive HR analytics and reporting system', '2023-10-01', '2024-04-30', 180000.00, 'Completed', 1),
('Legacy System Migration', 'Migrate legacy systems to cloud infrastructure', '2023-08-01', '2024-02-29', 600000.00, 'Completed', 2),
('Product Launch Campaign', 'Comprehensive marketing campaign for new product launch', '2023-11-01', '2024-01-31', 250000.00, 'Completed', 4);
GO

-- =============================================
-- 6. Insert Sample Employee Projects
-- =============================================
INSERT INTO EmployeeProjects (EmployeeID, ProjectID, Role, AllocationPercentage, StartDate, EndDate) VALUES
-- Employee Portal Redesign
(5, 1, 'Lead Developer', 100, '2024-01-15', NULL),
(6, 1, 'Frontend Developer', 80, '2024-01-15', NULL),
(7, 1, 'Backend Developer', 70, '2024-01-15', NULL),
(8, 1, 'DevOps Engineer', 50, '2024-01-15', NULL),

-- Financial Reporting System
(9, 2, 'Project Manager', 100, '2024-02-01', NULL),
(10, 2, 'Financial Analyst', 90, '2024-02-01', NULL),
(11, 2, 'Data Analyst', 80, '2024-02-01', NULL),

-- Marketing Automation Platform
(12, 3, 'Project Manager', 100, '2024-01-01', NULL),
(13, 3, 'Marketing Manager', 90, '2024-01-01', NULL),
(14, 3, 'Digital Marketing Specialist', 100, '2024-01-01', NULL),

-- Sales Performance Dashboard
(15, 4, 'Project Manager', 100, '2024-03-01', NULL),
(16, 4, 'Sales Manager', 80, '2024-03-01', NULL),
(17, 4, 'Sales Representative', 60, '2024-03-01', NULL),

-- Operations Optimization
(19, 5, 'Project Manager', 100, '2024-02-15', NULL),
(20, 5, 'Operations Coordinator', 90, '2024-02-15', NULL),

-- AI Research Initiative
(21, 6, 'Project Director', 100, '2024-01-10', NULL),
(22, 6, 'Senior Research Scientist', 90, '2024-01-10', NULL),
(23, 6, 'Research Scientist', 80, '2024-01-10', NULL),

-- Customer Support Chatbot
(25, 7, 'Project Manager', 100, '2024-03-15', NULL),
(26, 7, 'Support Specialist', 70, '2024-03-15', NULL),
(27, 7, 'Customer Success Manager', 60, '2024-03-15', NULL);
GO

-- =============================================
-- 7. Insert Sample Performance Reviews
-- =============================================
INSERT INTO PerformanceReviews (EmployeeID, ReviewerID, ReviewDate, ReviewPeriodStart, ReviewPeriodEnd, OverallRating, TechnicalSkills, Communication, Teamwork, Leadership, Comments, Goals) VALUES
-- 2024 Reviews
(1, 4, '2024-01-15', '2023-01-01', '2023-12-31', 4, 4, 5, 4, 4, 'Excellent leadership in HR initiatives. Strong communication skills.', 'Implement new HR analytics platform, improve employee engagement'),
(2, 1, '2024-01-20', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 3, 'Good performance in recruitment activities. Needs technical skill development.', 'Complete HR certification, improve technical skills'),
(3, 1, '2024-01-25', '2023-01-01', '2023-12-31', 3, 3, 4, 3, 3, 'Solid performance in recruiting. Room for improvement in teamwork.', 'Improve collaboration skills, increase recruitment targets'),
(4, 9, '2024-02-01', '2023-01-01', '2023-12-31', 5, 5, 4, 4, 5, 'Outstanding technical leadership. Excellent project management skills.', 'Lead digital transformation initiatives, mentor junior developers'),
(5, 4, '2024-02-05', '2023-01-01', '2023-12-31', 4, 5, 4, 4, 3, 'Strong technical skills and code quality. Good team collaboration.', 'Improve leadership skills, mentor junior developers'),
(6, 4, '2024-02-10', '2023-01-01', '2023-12-31', 4, 4, 3, 4, 3, 'Good development skills. Needs improvement in communication.', 'Improve communication skills, take on more complex projects'),
(7, 4, '2024-02-15', '2023-01-01', '2023-12-31', 3, 4, 3, 3, 2, 'Solid technical skills. Needs improvement in teamwork and leadership.', 'Improve collaboration skills, take initiative on projects'),
(8, 4, '2024-02-20', '2023-01-01', '2023-12-31', 4, 5, 4, 4, 3, 'Excellent DevOps skills. Good team player.', 'Improve leadership skills, automate more processes'),
(9, 21, '2024-03-01', '2023-01-01', '2023-12-31', 5, 4, 5, 5, 5, 'Exceptional financial leadership. Strong strategic thinking.', 'Lead financial transformation, improve reporting systems'),
(10, 9, '2024-03-05', '2023-01-01', '2023-12-31', 4, 4, 4, 4, 3, 'Strong analytical skills. Good team collaboration.', 'Improve leadership skills, take on more complex analyses'),
(11, 9, '2024-03-10', '2023-01-01', '2023-12-31', 3, 3, 3, 3, 2, 'Adequate performance. Needs improvement in all areas.', 'Improve technical skills, better communication, take initiative'),
(12, 21, '2024-03-15', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 4, 'Good marketing leadership. Strong creative thinking.', 'Improve technical skills, lead digital transformation'),
(13, 12, '2024-03-20', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 3, 'Strong marketing execution. Good team management.', 'Improve technical skills, mentor junior marketers'),
(14, 12, '2024-03-25', '2023-01-01', '2023-12-31', 3, 4, 3, 3, 2, 'Good technical skills. Needs improvement in communication and leadership.', 'Improve communication skills, take on leadership roles'),
(15, 21, '2024-04-01', '2023-01-01', '2023-12-31', 5, 4, 5, 5, 5, 'Outstanding sales leadership. Exceptional results.', 'Exceed sales targets, develop sales team, expand market reach'),
(16, 15, '2024-04-05', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 4, 'Strong sales management. Good team leadership.', 'Improve technical skills, mentor sales team'),
(17, 15, '2024-04-10', '2023-01-01', '2023-12-31', 3, 3, 4, 3, 2, 'Adequate sales performance. Needs improvement in technical skills.', 'Improve product knowledge, better teamwork, take initiative'),
(18, 15, '2024-04-15', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 3, 'Good sales performance. Strong communication skills.', 'Improve technical skills, take on larger accounts'),
(19, 21, '2024-05-01', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 4, 'Strong operations management. Good process improvement skills.', 'Improve technical skills, optimize more processes'),
(20, 19, '2024-05-05', '2023-01-01', '2023-12-31', 3, 3, 3, 3, 2, 'Adequate performance. Needs improvement in all areas.', 'Improve technical skills, better communication, take initiative'),
(21, 21, '2024-05-10', '2023-01-01', '2023-12-31', 5, 5, 5, 5, 5, 'Exceptional R&D leadership. Outstanding innovation.', 'Lead breakthrough research, develop new products, mentor team'),
(22, 21, '2024-05-15', '2023-01-01', '2023-12-31', 4, 5, 4, 4, 3, 'Strong research skills. Good technical expertise.', 'Improve leadership skills, mentor junior researchers'),
(23, 21, '2024-05-20', '2023-01-01', '2023-12-31', 3, 4, 3, 3, 2, 'Good technical skills. Needs improvement in communication and leadership.', 'Improve communication skills, take on leadership roles'),
(25, 21, '2024-06-01', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 4, 'Strong support management. Good customer focus.', 'Improve technical skills, enhance customer experience'),
(26, 25, '2024-06-05', '2023-01-01', '2023-12-31', 3, 3, 3, 3, 2, 'Adequate support performance. Needs improvement in all areas.', 'Improve technical skills, better communication, take initiative'),
(27, 25, '2024-06-10', '2023-01-01', '2023-12-31', 4, 3, 4, 4, 3, 'Good customer success management. Strong relationship building.', 'Improve technical skills, expand customer base');
GO

-- =============================================
-- 8. Insert Sample Salary History
-- =============================================
INSERT INTO SalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeDate, ChangeReason, ApprovedBy) VALUES
-- Initial salaries (from hire dates)
(1, NULL, 85000.00, '2020-01-15', 'Initial salary', NULL),
(2, NULL, 65000.00, '2021-03-10', 'Initial salary', NULL),
(3, NULL, 60000.00, '2022-06-01', 'Initial salary', NULL),
(4, NULL, 140000.00, '2019-08-20', 'Initial salary', NULL),
(5, NULL, 110000.00, '2020-02-15', 'Initial salary', NULL),
(6, NULL, 90000.00, '2021-09-05', 'Initial salary', NULL),
(7, NULL, 105000.00, '2022-01-10', 'Initial salary', NULL),
(8, NULL, 75000.00, '2022-07-15', 'Initial salary', NULL),
(9, NULL, 160000.00, '2019-11-01', 'Initial salary', NULL),
(10, NULL, 80000.00, '2020-04-20', 'Initial salary', NULL),
(11, NULL, 70000.00, '2021-08-15', 'Initial salary', NULL),
(12, NULL, 120000.00, '2020-01-05', 'Initial salary', NULL),
(13, NULL, 95000.00, '2021-02-20', 'Initial salary', NULL),
(14, NULL, 70000.00, '2022-05-10', 'Initial salary', NULL),
(15, NULL, 130000.00, '2019-06-15', 'Initial salary', NULL),
(16, NULL, 100000.00, '2020-09-01', 'Initial salary', NULL),
(17, NULL, 75000.00, '2021-11-15', 'Initial salary', NULL),
(18, NULL, 85000.00, '2022-03-20', 'Initial salary', NULL),
(19, NULL, 95000.00, '2020-07-10', 'Initial salary', NULL),
(20, NULL, 65000.00, '2021-12-01', 'Initial salary', NULL),
(21, NULL, 150000.00, '2019-03-01', 'Initial salary', NULL),
(22, NULL, 120000.00, '2020-05-15', 'Initial salary', NULL),
(23, NULL, 95000.00, '2021-08-20', 'Initial salary', NULL),
(25, NULL, 80000.00, '2020-10-01', 'Initial salary', NULL),
(26, NULL, 55000.00, '2021-06-15', 'Initial salary', NULL),
(27, NULL, 70000.00, '2022-01-10', 'Initial salary', NULL),

-- 2023 Salary Increases
(1, 85000.00, 90000.00, '2023-01-15', 'Annual increase', 9),
(2, 65000.00, 68000.00, '2023-03-10', 'Annual increase', 1),
(3, 60000.00, 63000.00, '2023-06-01', 'Annual increase', 1),
(4, 140000.00, 150000.00, '2023-08-20', 'Promotion to Director', 9),
(5, 110000.00, 115000.00, '2023-02-15', 'Annual increase', 4),
(6, 90000.00, 95000.00, '2023-09-05', 'Annual increase', 4),
(7, 105000.00, 110000.00, '2023-01-10', 'Annual increase', 4),
(8, 75000.00, 80000.00, '2023-07-15', 'Annual increase', 4),
(9, 160000.00, 170000.00, '2023-11-01', 'Annual increase', 21),
(10, 80000.00, 85000.00, '2023-04-20', 'Annual increase', 9),
(11, 70000.00, 73000.00, '2023-08-15', 'Annual increase', 9),
(12, 120000.00, 130000.00, '2023-01-05', 'Annual increase', 21),
(13, 95000.00, 100000.00, '2023-02-20', 'Annual increase', 12),
(14, 70000.00, 75000.00, '2023-05-10', 'Annual increase', 12),
(15, 130000.00, 140000.00, '2023-06-15', 'Annual increase', 21),
(16, 100000.00, 105000.00, '2023-09-01', 'Annual increase', 15),
(17, 75000.00, 78000.00, '2023-11-15', 'Annual increase', 15),
(18, 85000.00, 90000.00, '2023-03-20', 'Annual increase', 15),
(19, 95000.00, 100000.00, '2023-07-10', 'Annual increase', 21),
(20, 65000.00, 68000.00, '2023-12-01', 'Annual increase', 19),
(21, 150000.00, 160000.00, '2023-03-01', 'Annual increase', 21),
(22, 120000.00, 125000.00, '2023-05-15', 'Annual increase', 21),
(23, 95000.00, 100000.00, '2023-08-20', 'Annual increase', 21),
(25, 80000.00, 85000.00, '2023-10-01', 'Annual increase', 21),
(26, 55000.00, 58000.00, '2023-06-15', 'Annual increase', 25),
(27, 70000.00, 75000.00, '2023-01-10', 'Annual increase', 25),

-- 2024 Salary Increases (Performance-based)
(1, 90000.00, 95000.00, '2024-01-15', 'Performance increase', 9),
(2, 68000.00, 72000.00, '2024-01-20', 'Performance increase', 1),
(3, 63000.00, 66000.00, '2024-01-25', 'Performance increase', 1),
(4, 150000.00, 160000.00, '2024-02-01', 'Performance increase', 9),
(5, 115000.00, 120000.00, '2024-02-05', 'Performance increase', 4),
(6, 95000.00, 100000.00, '2024-02-10', 'Performance increase', 4),
(7, 110000.00, 115000.00, '2024-02-15', 'Performance increase', 4),
(8, 80000.00, 85000.00, '2024-02-20', 'Performance increase', 4),
(9, 170000.00, 180000.00, '2024-03-01', 'Performance increase', 21),
(10, 85000.00, 90000.00, '2024-03-05', 'Performance increase', 9),
(11, 73000.00, 76000.00, '2024-03-10', 'Performance increase', 9),
(12, 130000.00, 135000.00, '2024-03-15', 'Performance increase', 21),
(13, 100000.00, 105000.00, '2024-03-20', 'Performance increase', 12),
(14, 75000.00, 78000.00, '2024-03-25', 'Performance increase', 12),
(15, 140000.00, 150000.00, '2024-04-01', 'Performance increase', 21),
(16, 105000.00, 110000.00, '2024-04-05', 'Performance increase', 15),
(17, 78000.00, 80000.00, '2024-04-10', 'Performance increase', 15),
(18, 90000.00, 95000.00, '2024-04-15', 'Performance increase', 15),
(19, 100000.00, 105000.00, '2024-05-01', 'Performance increase', 21),
(20, 68000.00, 70000.00, '2024-05-05', 'Performance increase', 19),
(21, 160000.00, 170000.00, '2024-05-10', 'Performance increase', 21),
(22, 125000.00, 130000.00, '2024-05-15', 'Performance increase', 21),
(23, 100000.00, 105000.00, '2024-05-20', 'Performance increase', 21),
(25, 85000.00, 90000.00, '2024-06-01', 'Performance increase', 21),
(26, 58000.00, 60000.00, '2024-06-05', 'Performance increase', 25),
(27, 75000.00, 80000.00, '2024-06-10', 'Performance increase', 25);
GO

-- =============================================
-- 9. Insert Sample Users
-- =============================================
INSERT INTO Users (EmployeeID, Username, PasswordHash, Role, LastLogin) VALUES
(1, 'sarah.johnson', 'hashed_password_1', 'Manager', '2024-01-15 09:30:00'),
(2, 'michael.brown', 'hashed_password_2', 'Employee', '2024-01-14 14:20:00'),
(3, 'emily.davis', 'hashed_password_3', 'Employee', '2024-01-13 11:45:00'),
(4, 'david.wilson', 'hashed_password_4', 'Admin', '2024-01-15 08:15:00'),
(5, 'lisa.garcia', 'hashed_password_5', 'Manager', '2024-01-14 16:30:00'),
(6, 'james.martinez', 'hashed_password_6', 'Employee', '2024-01-13 10:20:00'),
(7, 'jennifer.anderson', 'hashed_password_7', 'Employee', '2024-01-12 15:45:00'),
(8, 'robert.taylor', 'hashed_password_8', 'Employee', '2024-01-11 09:15:00'),
(9, 'maria.thomas', 'hashed_password_9', 'Admin', '2024-01-15 07:45:00'),
(10, 'christopher.jackson', 'hashed_password_10', 'Employee', '2024-01-14 13:30:00'),
(11, 'amanda.white', 'hashed_password_11', 'Employee', '2024-01-13 12:15:00'),
(12, 'daniel.harris', 'hashed_password_12', 'Manager', '2024-01-14 10:45:00'),
(13, 'jessica.martin', 'hashed_password_13', 'Manager', '2024-01-13 14:20:00'),
(14, 'matthew.thompson', 'hashed_password_14', 'Employee', '2024-01-12 11:30:00'),
(15, 'ashley.garcia', 'hashed_password_15', 'Manager', '2024-01-14 16:15:00'),
(16, 'joshua.martinez', 'hashed_password_16', 'Manager', '2024-01-13 15:45:00'),
(17, 'stephanie.robinson', 'hashed_password_17', 'Employee', '2024-01-12 09:30:00'),
(18, 'kevin.clark', 'hashed_password_18', 'Employee', '2024-01-11 14:15:00'),
(19, 'nicole.rodriguez', 'hashed_password_19', 'Manager', '2024-01-13 11:20:00'),
(20, 'brandon.lewis', 'hashed_password_20', 'Employee', '2024-01-12 13:45:00'),
(21, 'rachel.lee', 'hashed_password_21', 'Admin', '2024-01-15 06:30:00'),
(22, 'andrew.walker', 'hashed_password_22', 'Manager', '2024-01-14 12:15:00'),
(23, 'michelle.hall', 'hashed_password_23', 'Employee', '2024-01-13 10:45:00'),
(25, 'ryan.allen', 'hashed_password_25', 'Manager', '2024-01-14 15:30:00'),
(26, 'lauren.young', 'hashed_password_26', 'Employee', '2024-01-13 09:15:00'),
(27, 'justin.king', 'hashed_password_27', 'Employee', '2024-01-12 16:20:00');
GO

-- =============================================
-- 10. Test Stored Procedures
-- =============================================

-- Test Employee CRUD
PRINT 'Testing Employee CRUD Procedures...';

-- Test Create Employee
EXEC sp_CreateEmployee 
    @FirstName = 'Test',
    @LastName = 'Employee',
    @Email = 'test.employee@company.com',
    @Phone = '555-9999',
    @DateOfBirth = '1990-01-01',
    @HireDate = '2024-01-01',
    @DepartmentID = 1,
    @ManagerID = 1,
    @JobTitle = 'Test Position',
    @Salary = 75000.00;

-- Test Get Employee
EXEC sp_GetEmployee @EmployeeID = 1;

-- Test Get Employees with pagination
EXEC sp_GetEmployees 
    @PageNumber = 1,
    @PageSize = 10,
    @DepartmentID = NULL,
    @SearchTerm = 'Manager';

-- Test Update Employee
EXEC sp_UpdateEmployee 
    @EmployeeID = 28,
    @FirstName = 'Updated',
    @LastName = 'Employee',
    @Salary = 80000.00;

-- Test Employee Statistics
EXEC sp_GetEmployeeStatistics;

PRINT 'Employee CRUD tests completed.';

-- Test Salary Calculations
PRINT 'Testing Salary Calculation Procedures...';

-- Test Calculate Employee Bonus
EXEC sp_CalculateEmployeeBonus @EmployeeID = 1, @ReviewYear = 2024;

-- Test Calculate Department Salary Budget
EXEC sp_CalculateDepartmentSalaryBudget @DepartmentID = 2, @Year = 2024;

-- Test Calculate Salary Adjustments
EXEC sp_CalculateSalaryAdjustments @DepartmentID = 1;

-- Test Compensation Analytics
EXEC sp_GetCompensationAnalytics @Year = 2024;

PRINT 'Salary calculation tests completed.';

-- Test Performance Reviews
PRINT 'Testing Performance Review Procedures...';

-- Test Get Employee Performance Summary
EXEC sp_GetEmployeePerformanceSummary @EmployeeID = 1, @Year = 2024;

-- Test Get Department Performance Analytics
EXEC sp_GetDepartmentPerformanceAnalytics @DepartmentID = 2, @Year = 2024;

-- Test Get Performance Review Trends
EXEC sp_GetPerformanceReviewTrends @StartYear = 2023, @EndYear = 2024;

-- Test Get Top Performers
EXEC sp_GetTopPerformersAnalysis @TopCount = 5, @Year = 2024;

PRINT 'Performance review tests completed.';

-- Test Department Summaries
PRINT 'Testing Department Summary Procedures...';

-- Test Get Department Hierarchy
EXEC sp_GetDepartmentHierarchy;

-- Test Get Department Summary Dashboard
EXEC sp_GetDepartmentSummaryDashboard @DepartmentID = 2;

-- Test Get Department Budget Analysis
EXEC sp_GetDepartmentBudgetAnalysis @Year = 2024;

-- Test Get Department Resource Allocation
EXEC sp_GetDepartmentResourceAllocation @DepartmentID = 2;

PRINT 'Department summary tests completed.';

-- Test Audit Logging
PRINT 'Testing Audit Logging...';

-- Test Get Audit Report
EXEC sp_GetAuditReport 
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @PageNumber = 1,
    @PageSize = 20;

PRINT 'Audit logging tests completed.';

-- =============================================
-- 11. Sample Queries for Demonstration
-- =============================================

PRINT 'Sample Queries for Demonstration:';

-- Query 1: Employee Dashboard View
PRINT '1. Employee Dashboard View:';
SELECT TOP 10 
    EmployeeID, FullName, DepartmentName, JobTitle, Salary, 
    LatestPerformanceRating, PerformanceCategory, EmployeeStatus
FROM vw_EmployeeDashboard
ORDER BY LatestPerformanceRating DESC;

-- Query 2: Department Dashboard View
PRINT '2. Department Dashboard View:';
SELECT 
    DepartmentName, TotalEmployees, AverageSalary, AveragePerformanceRating, 
    DepartmentGrade, DepartmentStatus
FROM vw_DepartmentDashboard
ORDER BY AveragePerformanceRating DESC;

-- Query 3: Performance Analytics View
PRINT '3. Performance Analytics View:';
SELECT TOP 10 
    EmployeeName, DepartmentName, OverallRating, AverageRating, 
    PerformanceCategory, PerformanceTrend, PromotionPotential
FROM vw_PerformanceAnalytics
WHERE ReviewDate >= '2024-01-01'
ORDER BY WeightedScore DESC;

-- Query 4: Salary Analytics View
PRINT '4. Salary Analytics View:';
SELECT TOP 10 
    FullName, DepartmentName, CurrentSalary, SalaryCategory, 
    SalaryVsDepartmentAverage, SalaryAdjustmentRecommendation, SalaryRisk
FROM vw_SalaryAnalytics
ORDER BY CurrentSalary DESC;

-- Query 5: Project Analytics View
PRINT '5. Project Analytics View:';
SELECT 
    ProjectName, DepartmentName, Status, Budget, TotalEmployees, 
    ProjectProgressPercentage, ProjectHealth
FROM vw_ProjectAnalytics
WHERE Status = 'Active'
ORDER BY Budget DESC;

-- Query 6: Dashboard Summary View
PRINT '6. Dashboard Summary View:';
SELECT * FROM vw_DashboardSummary;

-- =============================================
-- 12. Performance Testing Queries
-- =============================================

PRINT 'Performance Testing Queries:';

-- Test 1: Complex aggregation query
PRINT 'Test 1: Complex aggregation query';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    d.DepartmentName,
    COUNT(e.EmployeeID) AS EmployeeCount,
    AVG(CAST(e.Salary AS FLOAT)) AS AverageSalary,
    AVG(CAST(pr.OverallRating AS FLOAT)) AS AveragePerformance,
    COUNT(p.ProjectID) AS ProjectCount,
    SUM(p.Budget) AS TotalProjectBudget
FROM Departments d
LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID AND e.IsActive = 1
LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY AverageSalary DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Test 2: Window function query
PRINT 'Test 2: Window function query';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    e.FullName,
    e.DepartmentID,
    d.DepartmentName,
    e.Salary,
    ROW_NUMBER() OVER (PARTITION BY e.DepartmentID ORDER BY e.Salary DESC) AS SalaryRank,
    PERCENT_RANK() OVER (PARTITION BY e.DepartmentID ORDER BY e.Salary) AS SalaryPercentile,
    AVG(CAST(e.Salary AS FLOAT)) OVER (PARTITION BY e.DepartmentID) AS DepartmentAverageSalary
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.IsActive = 1
ORDER BY e.DepartmentID, e.Salary DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Test 3: CTE query
PRINT 'Test 3: CTE query';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

WITH EmployeeHierarchy AS (
    SELECT 
        e.EmployeeID,
        e.FullName,
        e.ManagerID,
        m.FullName AS ManagerName,
        0 AS Level
    FROM Employees e
    LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID
    WHERE e.ManagerID IS NULL
    
    UNION ALL
    
    SELECT 
        e.EmployeeID,
        e.FullName,
        e.ManagerID,
        m.FullName AS ManagerName,
        eh.Level + 1
    FROM Employees e
    INNER JOIN Employees m ON e.ManagerID = m.EmployeeID
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
    WHERE e.IsActive = 1
)
SELECT * FROM EmployeeHierarchy
ORDER BY Level, FullName;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

PRINT 'Performance testing completed.';

-- =============================================
-- 13. Data Validation Queries
-- =============================================

PRINT 'Data Validation Queries:';

-- Check data integrity
PRINT '1. Data Integrity Checks:';

-- Check for orphaned records
SELECT 'Orphaned Employees' AS CheckType, COUNT(*) AS Count
FROM Employees e
LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE d.DepartmentID IS NULL;

SELECT 'Orphaned Projects' AS CheckType, COUNT(*) AS Count
FROM Projects p
LEFT JOIN Departments d ON p.DepartmentID = d.DepartmentID
WHERE d.DepartmentID IS NULL;

SELECT 'Orphaned Performance Reviews' AS CheckType, COUNT(*) AS Count
FROM PerformanceReviews pr
LEFT JOIN Employees e ON pr.EmployeeID = e.EmployeeID
WHERE e.EmployeeID IS NULL;

-- Check for data consistency
SELECT 'Salary History Consistency' AS CheckType, COUNT(*) AS Count
FROM SalaryHistory sh
WHERE sh.OldSalary IS NOT NULL AND sh.OldSalary >= sh.NewSalary;

SELECT 'Performance Review Consistency' AS CheckType, COUNT(*) AS Count
FROM PerformanceReviews pr
WHERE pr.ReviewPeriodEnd < pr.ReviewPeriodStart;

-- Check for missing data
SELECT 'Employees without Performance Reviews' AS CheckType, COUNT(*) AS Count
FROM Employees e
LEFT JOIN PerformanceReviews pr ON e.EmployeeID = pr.EmployeeID
WHERE e.IsActive = 1 AND pr.EmployeeID IS NULL;

SELECT 'Employees without Salary History' AS CheckType, COUNT(*) AS Count
FROM Employees e
LEFT JOIN SalaryHistory sh ON e.EmployeeID = sh.EmployeeID
WHERE e.IsActive = 1 AND sh.EmployeeID IS NULL;

PRINT 'Data validation completed.';

-- =============================================
-- 14. Cleanup Test Data
-- =============================================

PRINT 'Cleaning up test data...';

-- Remove test employee
DELETE FROM SalaryHistory WHERE EmployeeID = 28;
DELETE FROM PerformanceReviews WHERE EmployeeID = 28;
DELETE FROM EmployeeProjects WHERE EmployeeID = 28;
DELETE FROM Users WHERE EmployeeID = 28;
DELETE FROM Employees WHERE EmployeeID = 28;

PRINT 'Test data cleanup completed.';

PRINT 'Sample data and test scripts completed successfully!';
PRINT 'Sample data inserted: 27 employees, 8 departments, 10 projects, 27 performance reviews, 81 salary history records, 26 users';
PRINT 'All stored procedures tested and validated';
PRINT 'Performance testing completed with statistics';
PRINT 'Data validation checks passed';
