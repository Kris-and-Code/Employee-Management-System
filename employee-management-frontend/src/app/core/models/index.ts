export interface Employee {
  employeeID: number;
  firstName: string;
  lastName: string;
  fullName: string;
  email: string;
  phone?: string;
  dateOfBirth?: Date;
  age?: number;
  hireDate: Date;
  yearsOfService: number;
  departmentID: number;
  departmentName: string;
  managerID?: number;
  managerName?: string;
  jobTitle: string;
  salary: number;
  isActive: boolean;
  createdDate: Date;
  modifiedDate?: Date;
}

export interface Department {
  departmentID: number;
  departmentName: string;
  departmentHead?: number;
  departmentHeadName?: string;
  budget?: number;
  location?: string;
  createdDate: Date;
  modifiedDate?: Date;
}

export interface Project {
  projectID: number;
  projectName: string;
  description?: string;
  startDate: Date;
  endDate?: Date;
  budget?: number;
  status: ProjectStatus;
  departmentID: number;
  departmentName: string;
  createdDate: Date;
  modifiedDate?: Date;
}

export enum ProjectStatus {
  Planning = 'Planning',
  Active = 'Active',
  Completed = 'Completed',
  OnHold = 'On Hold',
  Cancelled = 'Cancelled'
}

export interface EmployeeProject {
  employeeProjectID: number;
  employeeID: number;
  projectID: number;
  role: string;
  allocationPercentage: number;
  startDate: Date;
  endDate?: Date;
  createdDate: Date;
}

export interface PerformanceReview {
  reviewID: number;
  employeeID: number;
  employeeName: string;
  reviewerID: number;
  reviewerName: string;
  reviewDate: Date;
  reviewPeriodStart: Date;
  reviewPeriodEnd: Date;
  overallRating: number;
  technicalSkills: number;
  communication: number;
  teamwork: number;
  leadership: number;
  comments?: string;
  goals?: string;
  createdDate: Date;
  modifiedDate?: Date;
  averageRating: number;
  weightedScore: number;
  performanceCategory: string;
}

export interface SalaryHistory {
  salaryHistoryID: number;
  employeeID: number;
  oldSalary?: number;
  newSalary: number;
  changeDate: Date;
  changeReason?: string;
  approvedBy?: number;
  createdDate: Date;
}

export interface User {
  userID: number;
  employeeID: number;
  username: string;
  passwordHash: string;
  role: UserRole;
  lastLogin?: Date;
  isActive: boolean;
  createdDate: Date;
  modifiedDate?: Date;
}

export enum UserRole {
  Admin = 'Admin',
  Manager = 'Manager',
  Employee = 'Employee'
}

export interface AuditLog {
  auditID: number;
  tableName: string;
  recordID: number;
  action: string;
  oldValue?: string;
  newValue?: string;
  changedBy: string;
  changedDate: Date;
}

export interface ApiResponse<T> {
  data: T;
  message: string;
  success: boolean;
  totalCount?: number;
  pageNumber?: number;
  pageSize?: number;
  totalPages?: number;
}

export interface PaginationParams {
  pageNumber: number;
  pageSize: number;
  sortColumn?: string;
  sortDirection?: 'ASC' | 'DESC';
  searchTerm?: string;
}

export interface EmployeeFilters extends PaginationParams {
  departmentID?: number;
  managerID?: number;
  isActive?: boolean;
}

export interface DashboardSummary {
  totalEmployees: number;
  activeEmployees: number;
  totalDepartments: number;
  totalProjects: number;
  activeProjects: number;
  totalPayroll: number;
  averageSalary: number;
  averagePerformanceRating: number;
  totalPerformanceReviews: number;
  salaryChangesThisYear: number;
  reviewsThisYear: number;
  activeEmployeePercentage: number;
  activeProjectPercentage: number;
  overallPerformanceStatus: string;
  lastUpdated: Date;
}
