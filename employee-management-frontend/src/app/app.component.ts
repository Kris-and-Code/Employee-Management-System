import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: `
    <div class="app-container">
      <header class="app-header">
        <h1>Employee Management System</h1>
        <nav class="nav-menu">
          <a routerLink="/dashboard" routerLinkActive="active">Dashboard</a>
          <a routerLink="/employees" routerLinkActive="active">Employees</a>
          <a routerLink="/departments" routerLinkActive="active">Departments</a>
          <a routerLink="/projects" routerLinkActive="active">Projects</a>
          <a routerLink="/reports" routerLinkActive="active">Reports</a>
        </nav>
      </header>
      
      <main class="app-main">
        <router-outlet></router-outlet>
      </main>
      
      <footer class="app-footer">
        <p>&copy; 2024 Employee Management System. All rights reserved.</p>
      </footer>
    </div>
  `,
  styles: [`
    .app-container {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    .app-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 1rem 2rem;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }

    .app-header h1 {
      margin: 0 0 1rem 0;
      font-size: 1.8rem;
      text-align: center;
    }

    .nav-menu {
      display: flex;
      justify-content: center;
      gap: 2rem;
      flex-wrap: wrap;
    }

    .nav-menu a {
      color: white;
      text-decoration: none;
      padding: 0.5rem 1rem;
      border-radius: 4px;
      transition: background-color 0.2s;
    }

    .nav-menu a:hover,
    .nav-menu a.active {
      background-color: rgba(255, 255, 255, 0.2);
    }

    .app-main {
      flex: 1;
      background: #f8f9fa;
    }

    .app-footer {
      background: #333;
      color: white;
      text-align: center;
      padding: 1rem;
    }

    .app-footer p {
      margin: 0;
    }

    @media (max-width: 768px) {
      .app-header {
        padding: 1rem;
      }
      
      .app-header h1 {
        font-size: 1.5rem;
      }
      
      .nav-menu {
        gap: 1rem;
      }
      
      .nav-menu a {
        padding: 0.4rem 0.8rem;
        font-size: 0.9rem;
      }
    }
  `]
})
export class AppComponent {
  title = 'employee-management-frontend';
}