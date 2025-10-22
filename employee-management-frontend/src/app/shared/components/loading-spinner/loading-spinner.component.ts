import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-loading-spinner',
  template: `
    <div class="loading-spinner" [class.small]="size === 'small'" [class.large]="size === 'large'">
      <div class="spinner"></div>
      <p *ngIf="message" class="loading-message">{{ message }}</p>
    </div>
  `,
  styles: [`
    .loading-spinner {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 2rem;
    }

    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #f3f3f3;
      border-top: 4px solid #3498db;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    .loading-spinner.small .spinner {
      width: 20px;
      height: 20px;
      border-width: 2px;
    }

    .loading-spinner.large .spinner {
      width: 60px;
      height: 60px;
      border-width: 6px;
    }

    .loading-message {
      margin-top: 1rem;
      color: #666;
      font-size: 0.9rem;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  `]
})
export class LoadingSpinnerComponent {
  @Input() message: string = '';
  @Input() size: 'small' | 'medium' | 'large' = 'medium';
}