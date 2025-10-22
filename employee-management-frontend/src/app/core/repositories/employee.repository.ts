import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Employee, ApiResponse, EmployeeFilters } from '../models';
import { BaseRepository } from '../repositories/base.repository';
import { HttpService } from '../services/http.service';

@Injectable({
  providedIn: 'root'
})
export class EmployeeRepository extends BaseRepository<Employee> {
  constructor(private httpService: HttpService) {
    super('employees');
  }

  getAll(params?: EmployeeFilters): Observable<ApiResponse<Employee[]>> {
    return this.httpService.get<Employee[]>(this.baseUrl, params);
  }

  getById(id: number): Observable<ApiResponse<Employee>> {
    return this.httpService.get<Employee>(`${this.baseUrl}/${id}`);
  }

  create(employee: Partial<Employee>): Observable<ApiResponse<Employee>> {
    return this.httpService.post<Employee>(this.baseUrl, employee);
  }

  update(id: number, employee: Partial<Employee>): Observable<ApiResponse<Employee>> {
    return this.httpService.put<Employee>(`${this.baseUrl}/${id}`, employee);
  }

  delete(id: number): Observable<ApiResponse<void>> {
    return this.httpService.delete<void>(`${this.baseUrl}/${id}`);
  }

  getStatistics(): Observable<ApiResponse<any>> {
    return this.httpService.get<any>(`${this.baseUrl}/statistics`);
  }

  getPerformanceSummary(employeeId?: number, departmentId?: number, year?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (employeeId) params.employeeId = employeeId;
    if (departmentId) params.departmentId = departmentId;
    if (year) params.year = year;
    
    return this.httpService.get<any>(`${this.baseUrl}/performance-summary`, params);
  }

  calculateBonus(employeeId: number, reviewYear?: number, bonusPercentage?: number): Observable<ApiResponse<any>> {
    const params: any = { employeeId };
    if (reviewYear) params.reviewYear = reviewYear;
    if (bonusPercentage) params.bonusPercentage = bonusPercentage;
    
    return this.httpService.get<any>(`${this.baseUrl}/calculate-bonus`, params);
  }
}
