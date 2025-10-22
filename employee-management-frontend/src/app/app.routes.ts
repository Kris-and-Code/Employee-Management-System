import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { 
    path: 'dashboard', 
    loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent)
  },
  { 
    path: 'employees', 
    loadComponent: () => import('./features/employee-list/employee-list.component').then(m => m.EmployeeListComponent)
  },
  { 
    path: 'departments', 
    loadChildren: () => import('./features/features.module').then(m => m.FeaturesModule)
  },
  { 
    path: 'projects', 
    loadChildren: () => import('./features/features.module').then(m => m.FeaturesModule)
  },
  { 
    path: 'reports', 
    loadChildren: () => import('./features/features.module').then(m => m.FeaturesModule)
  },
  { path: '**', redirectTo: '/dashboard' }
];