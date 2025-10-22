import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Department, ApiResponse, PaginationParams } from '../models';
import { BaseRepository } from '../repositories/base.repository';
import { HttpService } from '../services/http.service';

@Injectable({
  providedIn: 'root'
})
export class DepartmentRepository extends BaseRepository<Department> {
  constructor(private httpService: HttpService) {
    super('departments');
  }

  getAll(params?: PaginationParams): Observable<ApiResponse<Department[]>> {
    return this.httpService.get<Department[]>(this.baseUrl, params);
  }

  getById(id: number): Observable<ApiResponse<Department>> {
    return this.httpService.get<Department>(`${this.baseUrl}/${id}`);
  }

  create(department: Partial<Department>): Observable<ApiResponse<Department>> {
    return this.httpService.post<Department>(this.baseUrl, department);
  }

  update(id: number, department: Partial<Department>): Observable<ApiResponse<Department>> {
    return this.httpService.put<Department>(`${this.baseUrl}/${id}`, department);
  }

  delete(id: number): Observable<ApiResponse<void>> {
    return this.httpService.delete<void>(`${this.baseUrl}/${id}`);
  }

  getHierarchy(rootDepartmentId?: number): Observable<ApiResponse<any>> {
    const params = rootDepartmentId ? { rootDepartmentId } : undefined;
    return this.httpService.get<any>(`${this.baseUrl}/hierarchy`, params);
  }

  getSummaryDashboard(departmentId?: number, includeInactive?: boolean): Observable<ApiResponse<any>> {
    const params: any = {};
    if (departmentId) params.departmentId = departmentId;
    if (includeInactive) params.includeInactive = includeInactive;
    
    return this.httpService.get<any>(`${this.baseUrl}/summary-dashboard`, params);
  }

  getBudgetAnalysis(year?: number, departmentId?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (year) params.year = year;
    if (departmentId) params.departmentId = departmentId;
    
    return this.httpService.get<any>(`${this.baseUrl}/budget-analysis`, params);
  }

  getResourceAllocation(departmentId?: number, year?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (departmentId) params.departmentId = departmentId;
    if (year) params.year = year;
    
    return this.httpService.get<any>(`${this.baseUrl}/resource-allocation`, params);
  }
}
