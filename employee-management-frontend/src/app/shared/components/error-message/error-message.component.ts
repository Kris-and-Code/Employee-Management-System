import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-error-message',
  template: `
    <div class="error-message" [class.dismissible]="dismissible">
      <div class="error-content">
        <i class="error-icon">⚠️</i>
        <div class="error-text">
          <h4 *ngIf="title">{{ title }}</h4>
          <p>{{ message }}</p>
        </div>
      </div>
      <button *ngIf="dismissible" class="dismiss-button" (click)="onDismiss()">×</button>
    </div>
  `,
  styles: [`
    .error-message {
      background-color: #fee;
      border: 1px solid #fcc;
      border-radius: 4px;
      padding: 1rem;
      margin: 1rem 0;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
    }

    .error-content {
      display: flex;
      align-items: flex-start;
      flex: 1;
    }

    .error-icon {
      font-size: 1.2rem;
      margin-right: 0.5rem;
      margin-top: 0.1rem;
    }

    .error-text h4 {
      margin: 0 0 0.5rem 0;
      color: #c33;
      font-size: 1rem;
    }

    .error-text p {
      margin: 0;
      color: #666;
      font-size: 0.9rem;
    }

    .dismiss-button {
      background: none;
      border: none;
      font-size: 1.5rem;
      color: #999;
      cursor: pointer;
      padding: 0;
      margin-left: 1rem;
      line-height: 1;
    }

    .dismiss-button:hover {
      color: #666;
    }
  `]
})
export class ErrorMessageComponent {
  @Input() message: string = 'An error occurred';
  @Input() title?: string;
  @Input() dismissible: boolean = false;

  onDismiss(): void {
    // This would typically emit an event to the parent component
    // For now, we'll just hide the error by setting message to empty
    this.message = '';
  }
}