import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

// Services
import { HttpService } from './services/http.service';
import { AuthService } from './services/auth.service';
import { DashboardService } from './services/dashboard.service';

// Repositories
import { EmployeeRepository } from './repositories/employee.repository';
import { DepartmentRepository } from './repositories/department.repository';

@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    HttpClientModule,
    ReactiveFormsModule,
    FormsModule
  ],
  providers: [
    HttpService,
    AuthService,
    DashboardService,
    EmployeeRepository,
    DepartmentRepository
  ],
  exports: [
    CommonModule,
    HttpClientModule,
    ReactiveFormsModule,
    FormsModule
  ]
})
export class CoreModule { }