import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { SharedModule } from '../shared/shared.module';
import { CoreModule } from '../core/core.module';

// Components
import { DashboardComponent } from './dashboard/dashboard.component';
import { EmployeeListComponent } from './employee-list/employee-list.component';

@NgModule({
  declarations: [
    DashboardComponent,
    EmployeeListComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    CoreModule
  ],
  exports: [
    DashboardComponent,
    EmployeeListComponent
  ]
})
export class FeaturesModule { }