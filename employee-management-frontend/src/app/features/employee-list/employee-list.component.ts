import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { map, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { FormControl } from '@angular/forms';
import { Employee, EmployeeFilters, ApiResponse } from '../../core/models';
import { EmployeeRepository } from '../../core/repositories/employee.repository';

@Component({
  selector: 'app-employee-list',
  template: `
    <div class="employee-list">
      <div class="header">
        <h2>Employees</h2>
        <button class="btn btn-primary" (click)="onAddEmployee()">Add Employee</button>
      </div>

      <div class="filters">
        <div class="search-box">
          <input 
            type="text" 
            placeholder="Search employees..." 
            [formControl]="searchControl"
            class="search-input">
        </div>
        
        <div class="filter-controls">
          <select [(ngModel)]="selectedDepartment" (change)="onFilterChange()" class="filter-select">
            <option value="">All Departments</option>
            <option *ngFor="let dept of departments" [value]="dept.departmentID">
              {{ dept.departmentName }}
            </option>
          </select>
          
          <select [(ngModel)]="selectedStatus" (change)="onFilterChange()" class="filter-select">
            <option value="">All Status</option>
            <option value="true">Active</option>
            <option value="false">Inactive</option>
          </select>
        </div>
      </div>

      <div class="table-container" *ngIf="employees$ | async as employees">
        <table class="employee-table">
          <thead>
            <tr>
              <th (click)="onSort('fullName')" class="sortable">
                Name 
                <span *ngIf="sortColumn === 'fullName'">{{ sortDirection === 'ASC' ? '↑' : '↓' }}</span>
              </th>
              <th (click)="onSort('departmentName')" class="sortable">
                Department
                <span *ngIf="sortColumn === 'departmentName'">{{ sortDirection === 'ASC' ? '↑' : '↓' }}</span>
              </th>
              <th (click)="onSort('jobTitle')" class="sortable">
                Job Title
                <span *ngIf="sortColumn === 'jobTitle'">{{ sortDirection === 'ASC' ? '↑' : '↓' }}</span>
              </th>
              <th (click)="onSort('salary')" class="sortable">
                Salary
                <span *ngIf="sortColumn === 'salary'">{{ sortDirection === 'ASC' ? '↑' : '↓' }}</span>
              </th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let employee of employees">
              <td>
                <div class="employee-info">
                  <div class="name">{{ employee.fullName }}</div>
                  <div class="email">{{ employee.email }}</div>
                </div>
              </td>
              <td>{{ employee.departmentName }}</td>
              <td>{{ employee.jobTitle }}</td>
              <td>{{ employee.salary | currency }}</td>
              <td>
                <span class="status-badge" [class.active]="employee.isActive" [class.inactive]="!employee.isActive">
                  {{ employee.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>
              <td>
                <div class="actions">
                  <button class="btn btn-sm btn-secondary" (click)="onViewEmployee(employee)">View</button>
                  <button class="btn btn-sm btn-primary" (click)="onEditEmployee(employee)">Edit</button>
                  <button class="btn btn-sm btn-danger" (click)="onDeleteEmployee(employee)">Delete</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <div class="pagination" *ngIf="paginationInfo">
          <button 
            class="btn btn-secondary" 
            [disabled]="currentPage === 1"
            (click)="onPageChange(currentPage - 1)">
            Previous
          </button>
          
          <span class="page-info">
            Page {{ currentPage }} of {{ paginationInfo.totalPages }}
            ({{ paginationInfo.totalCount }} total employees)
          </span>
          
          <button 
            class="btn btn-secondary" 
            [disabled]="currentPage === paginationInfo.totalPages"
            (click)="onPageChange(currentPage + 1)">
            Next
          </button>
        </div>
      </div>

      <app-loading-spinner *ngIf="!(employees$ | async)" message="Loading employees..."></app-loading-spinner>
      
      <app-confirmation-dialog
        [visible]="showDeleteDialog"
        title="Delete Employee"
        [message]="'Are you sure you want to delete ' + (selectedEmployee?.fullName || 'this employee') + '?'"
        (confirm)="confirmDelete()"
        (cancel)="cancelDelete()">
      </app-confirmation-dialog>
    </div>
  `,
  styles: [`
    .employee-list {
      padding: 2rem;
      max-width: 1200px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2rem;
    }

    .header h2 {
      margin: 0;
      color: #333;
    }

    .filters {
      display: flex;
      gap: 1rem;
      margin-bottom: 2rem;
      flex-wrap: wrap;
    }

    .search-box {
      flex: 1;
      min-width: 250px;
    }

    .search-input {
      width: 100%;
      padding: 0.75rem;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 1rem;
    }

    .filter-controls {
      display: flex;
      gap: 1rem;
    }

    .filter-select {
      padding: 0.75rem;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 1rem;
      min-width: 150px;
    }

    .table-container {
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      overflow: hidden;
    }

    .employee-table {
      width: 100%;
      border-collapse: collapse;
    }

    .employee-table th {
      background: #f8f9fa;
      padding: 1rem;
      text-align: left;
      font-weight: 600;
      color: #333;
      border-bottom: 2px solid #dee2e6;
    }

    .employee-table th.sortable {
      cursor: pointer;
      user-select: none;
    }

    .employee-table th.sortable:hover {
      background: #e9ecef;
    }

    .employee-table td {
      padding: 1rem;
      border-bottom: 1px solid #dee2e6;
    }

    .employee-table tr:hover {
      background: #f8f9fa;
    }

    .employee-info .name {
      font-weight: 600;
      color: #333;
    }

    .employee-info .email {
      font-size: 0.9rem;
      color: #666;
    }

    .status-badge {
      padding: 0.25rem 0.75rem;
      border-radius: 12px;
      font-size: 0.8rem;
      font-weight: 500;
    }

    .status-badge.active {
      background: #d4edda;
      color: #155724;
    }

    .status-badge.inactive {
      background: #f8d7da;
      color: #721c24;
    }

    .actions {
      display: flex;
      gap: 0.5rem;
    }

    .btn {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.9rem;
      transition: background-color 0.2s;
    }

    .btn-sm {
      padding: 0.25rem 0.5rem;
      font-size: 0.8rem;
    }

    .btn-primary {
      background: #007bff;
      color: white;
    }

    .btn-primary:hover {
      background: #0056b3;
    }

    .btn-secondary {
      background: #6c757d;
      color: white;
    }

    .btn-secondary:hover {
      background: #545b62;
    }

    .btn-danger {
      background: #dc3545;
      color: white;
    }

    .btn-danger:hover {
      background: #c82333;
    }

    .btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .pagination {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem;
      background: #f8f9fa;
    }

    .page-info {
      color: #666;
      font-size: 0.9rem;
    }

    @media (max-width: 768px) {
      .employee-list {
        padding: 1rem;
      }
      
      .header {
        flex-direction: column;
        gap: 1rem;
        align-items: stretch;
      }
      
      .filters {
        flex-direction: column;
      }
      
      .filter-controls {
        flex-direction: column;
      }
      
      .employee-table {
        font-size: 0.9rem;
      }
      
      .actions {
        flex-direction: column;
      }
    }
  `]
})
export class EmployeeListComponent implements OnInit {
  employees$!: Observable<Employee[]>;
  departments: any[] = [];
  
  searchControl = new FormControl('');
  selectedDepartment = '';
  selectedStatus = '';
  
  sortColumn = 'fullName';
  sortDirection: 'ASC' | 'DESC' = 'ASC';
  currentPage = 1;
  pageSize = 10;
  
  paginationInfo: any;
  showDeleteDialog = false;
  selectedEmployee: Employee | null = null;

  constructor(private employeeRepository: EmployeeRepository) {}

  ngOnInit(): void {
    this.loadEmployees();
    this.loadDepartments();
    
    // Setup search with debounce
    this.searchControl.valueChanges.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(() => {
      this.currentPage = 1;
      this.loadEmployees();
    });
  }

  loadEmployees(): void {
    const filters: EmployeeFilters = {
      pageNumber: this.currentPage,
      pageSize: this.pageSize,
      sortColumn: this.sortColumn,
      sortDirection: this.sortDirection,
      searchTerm: this.searchControl.value || undefined,
      departmentID: this.selectedDepartment ? +this.selectedDepartment : undefined,
      isActive: this.selectedStatus ? this.selectedStatus === 'true' : undefined
    };

    this.employees$ = this.employeeRepository.getAll(filters).pipe(
      map(response => {
        this.paginationInfo = {
          totalCount: response.totalCount,
          totalPages: response.totalPages,
          pageNumber: response.pageNumber,
          pageSize: response.pageSize
        };
        return response.data;
      })
    );
  }

  loadDepartments(): void {
    // This would typically come from a department service
    this.departments = [
      { departmentID: 1, departmentName: 'Human Resources' },
      { departmentID: 2, departmentName: 'Information Technology' },
      { departmentID: 3, departmentName: 'Finance' },
      { departmentID: 4, departmentName: 'Marketing' },
      { departmentID: 5, departmentName: 'Sales' },
      { departmentID: 6, departmentName: 'Operations' },
      { departmentID: 7, departmentName: 'Research & Development' },
      { departmentID: 8, departmentName: 'Customer Support' }
    ];
  }

  onSort(column: string): void {
    if (this.sortColumn === column) {
      this.sortDirection = this.sortDirection === 'ASC' ? 'DESC' : 'ASC';
    } else {
      this.sortColumn = column;
      this.sortDirection = 'ASC';
    }
    this.loadEmployees();
  }

  onFilterChange(): void {
    this.currentPage = 1;
    this.loadEmployees();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadEmployees();
  }

  onAddEmployee(): void {
    // Navigate to add employee form
    console.log('Add employee clicked');
  }

  onViewEmployee(employee: Employee): void {
    // Navigate to employee details
    console.log('View employee:', employee);
  }

  onEditEmployee(employee: Employee): void {
    // Navigate to edit employee form
    console.log('Edit employee:', employee);
  }

  onDeleteEmployee(employee: Employee): void {
    this.selectedEmployee = employee;
    this.showDeleteDialog = true;
  }

  confirmDelete(): void {
    if (this.selectedEmployee) {
      this.employeeRepository.delete(this.selectedEmployee.employeeID).subscribe({
        next: () => {
          this.loadEmployees();
          this.showDeleteDialog = false;
          this.selectedEmployee = null;
        },
        error: (error) => {
          console.error('Error deleting employee:', error);
          this.showDeleteDialog = false;
          this.selectedEmployee = null;
        }
      });
    }
  }

  cancelDelete(): void {
    this.showDeleteDialog = false;
    this.selectedEmployee = null;
  }
}