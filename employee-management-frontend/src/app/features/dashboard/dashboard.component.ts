import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DashboardSummary } from '../../core/models';
import { DashboardService } from '../../core/services/dashboard.service';

@Component({
  selector: 'app-dashboard',
  template: `
    <div class="dashboard">
      <h1>Employee Management Dashboard</h1>
      
      <div class="dashboard-summary" *ngIf="dashboardSummary$ | async as summary">
        <div class="summary-cards">
          <div class="summary-card">
            <h3>Total Employees</h3>
            <p class="number">{{ summary.totalEmployees }}</p>
            <p class="subtitle">{{ summary.activeEmployees }} active</p>
          </div>
          
          <div class="summary-card">
            <h3>Departments</h3>
            <p class="number">{{ summary.totalDepartments }}</p>
            <p class="subtitle">Active departments</p>
          </div>
          
          <div class="summary-card">
            <h3>Projects</h3>
            <p class="number">{{ summary.totalProjects }}</p>
            <p class="subtitle">{{ summary.activeProjects }} active</p>
          </div>
          
          <div class="summary-card">
            <h3>Total Payroll</h3>
            <p class="number">{{ summary.totalPayroll | currency }}</p>
            <p class="subtitle">Annual budget</p>
          </div>
        </div>
        
        <div class="metrics-grid">
          <div class="metric-card">
            <h4>Average Salary</h4>
            <p class="metric-value">{{ summary.averageSalary | currency }}</p>
          </div>
          
          <div class="metric-card">
            <h4>Average Performance</h4>
            <p class="metric-value">{{ summary.averagePerformanceRating | number:'1.1-1' }}/5.0</p>
          </div>
          
          <div class="metric-card">
            <h4>Performance Reviews</h4>
            <p class="metric-value">{{ summary.totalPerformanceReviews }}</p>
          </div>
          
          <div class="metric-card">
            <h4>Salary Changes (2024)</h4>
            <p class="metric-value">{{ summary.salaryChangesThisYear }}</p>
          </div>
        </div>
        
        <div class="status-section">
          <h3>System Status</h3>
          <div class="status-indicators">
            <div class="status-item">
              <span class="status-label">Active Employees:</span>
              <span class="status-value">{{ summary.activeEmployeePercentage | number:'1.1-1' }}%</span>
            </div>
            <div class="status-item">
              <span class="status-label">Active Projects:</span>
              <span class="status-value">{{ summary.activeProjectPercentage | number:'1.1-1' }}%</span>
            </div>
            <div class="status-item">
              <span class="status-label">Overall Performance:</span>
              <span class="status-value">{{ summary.overallPerformanceStatus }}</span>
            </div>
          </div>
        </div>
      </div>
      
      <app-loading-spinner *ngIf="!(dashboardSummary$ | async)" message="Loading dashboard data..."></app-loading-spinner>
    </div>
  `,
  styles: [`
    .dashboard {
      padding: 2rem;
      max-width: 1200px;
      margin: 0 auto;
    }

    h1 {
      color: #333;
      margin-bottom: 2rem;
      text-align: center;
    }

    .summary-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }

    .summary-card {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 2rem;
      border-radius: 12px;
      text-align: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
    }

    .summary-card h3 {
      margin: 0 0 1rem 0;
      font-size: 1.1rem;
      opacity: 0.9;
    }

    .summary-card .number {
      font-size: 2.5rem;
      font-weight: bold;
      margin: 0 0 0.5rem 0;
    }

    .summary-card .subtitle {
      margin: 0;
      opacity: 0.8;
      font-size: 0.9rem;
    }

    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
      margin-bottom: 2rem;
    }

    .metric-card {
      background: white;
      padding: 1.5rem;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      text-align: center;
    }

    .metric-card h4 {
      margin: 0 0 1rem 0;
      color: #666;
      font-size: 0.9rem;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .metric-value {
      font-size: 1.8rem;
      font-weight: bold;
      color: #333;
      margin: 0;
    }

    .status-section {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }

    .status-section h3 {
      margin: 0 0 1.5rem 0;
      color: #333;
    }

    .status-indicators {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1rem;
    }

    .status-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem;
      background: #f8f9fa;
      border-radius: 6px;
    }

    .status-label {
      color: #666;
      font-weight: 500;
    }

    .status-value {
      color: #333;
      font-weight: bold;
    }

    @media (max-width: 768px) {
      .dashboard {
        padding: 1rem;
      }
      
      .summary-cards {
        grid-template-columns: 1fr;
      }
      
      .metrics-grid {
        grid-template-columns: repeat(2, 1fr);
      }
    }
  `]
})
export class DashboardComponent implements OnInit {
  dashboardSummary$!: Observable<DashboardSummary>;

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.dashboardSummary$ = this.dashboardService.getDashboardSummary().pipe(
      map(response => response.data)
    );
  }
}