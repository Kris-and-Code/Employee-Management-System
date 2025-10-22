import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { DashboardSummary, ApiResponse } from '../models';
import { HttpService } from './http.service';

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  constructor(private httpService: HttpService) {}

  getDashboardSummary(): Observable<ApiResponse<DashboardSummary>> {
    return this.httpService.get<DashboardSummary>('dashboard/summary');
  }

  getEmployeeStatistics(): Observable<ApiResponse<any>> {
    return this.httpService.get<any>('dashboard/employee-statistics');
  }

  getDepartmentAnalytics(departmentId?: number, year?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (departmentId) params.departmentId = departmentId;
    if (year) params.year = year;
    
    return this.httpService.get<any>('dashboard/department-analytics', params);
  }

  getPerformanceTrends(startYear?: number, endYear?: number, departmentId?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (startYear) params.startYear = startYear;
    if (endYear) params.endYear = endYear;
    if (departmentId) params.departmentId = departmentId;
    
    return this.httpService.get<any>('dashboard/performance-trends', params);
  }

  getSalaryAnalytics(departmentId?: number, year?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (departmentId) params.departmentId = departmentId;
    if (year) params.year = year;
    
    return this.httpService.get<any>('dashboard/salary-analytics', params);
  }

  getTopPerformers(topCount?: number, departmentId?: number, year?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (topCount) params.topCount = topCount;
    if (departmentId) params.departmentId = departmentId;
    if (year) params.year = year;
    
    return this.httpService.get<any>('dashboard/top-performers', params);
  }

  getCompensationAnalytics(year?: number): Observable<ApiResponse<any>> {
    const params = year ? { year } : undefined;
    return this.httpService.get<any>('dashboard/compensation-analytics', params);
  }

  getProjectAnalytics(departmentId?: number, year?: number): Observable<ApiResponse<any>> {
    const params: any = {};
    if (departmentId) params.departmentId = departmentId;
    if (year) params.year = year;
    
    return this.httpService.get<any>('dashboard/project-analytics', params);
  }

  getAuditReport(startDate?: Date, endDate?: Date, tableName?: string, action?: string, changedBy?: string): Observable<ApiResponse<any>> {
    const params: any = {};
    if (startDate) params.startDate = startDate.toISOString();
    if (endDate) params.endDate = endDate.toISOString();
    if (tableName) params.tableName = tableName;
    if (action) params.action = action;
    if (changedBy) params.changedBy = changedBy;
    
    return this.httpService.get<any>('dashboard/audit-report', params);
  }
}
