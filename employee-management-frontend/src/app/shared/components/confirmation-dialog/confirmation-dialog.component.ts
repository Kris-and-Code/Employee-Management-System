import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-confirmation-dialog',
  template: `
    <div class="dialog-overlay" *ngIf="visible" (click)="onOverlayClick()">
      <div class="dialog" (click)="$event.stopPropagation()">
        <div class="dialog-header">
          <h3>{{ title }}</h3>
          <button class="close-button" (click)="onCancel()">×</button>
        </div>
        <div class="dialog-body">
          <p>{{ message }}</p>
        </div>
        <div class="dialog-footer">
          <button class="btn btn-secondary" (click)="onCancel()">{{ cancelText }}</button>
          <button class="btn btn-primary" (click)="onConfirm()">{{ confirmText }}</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dialog-overlay {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-color: rgba(0, 0, 0, 0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
    }

    .dialog {
      background: white;
      border-radius: 8px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
      min-width: 400px;
      max-width: 500px;
    }

    .dialog-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem 1.5rem;
      border-bottom: 1px solid #eee;
    }

    .dialog-header h3 {
      margin: 0;
      color: #333;
    }

    .close-button {
      background: none;
      border: none;
      font-size: 1.5rem;
      color: #999;
      cursor: pointer;
      padding: 0;
      line-height: 1;
    }

    .close-button:hover {
      color: #666;
    }

    .dialog-body {
      padding: 1.5rem;
    }

    .dialog-body p {
      margin: 0;
      color: #666;
      line-height: 1.5;
    }

    .dialog-footer {
      display: flex;
      justify-content: flex-end;
      gap: 0.5rem;
      padding: 1rem 1.5rem;
      border-top: 1px solid #eee;
    }

    .btn {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.9rem;
      transition: background-color 0.2s;
    }

    .btn-secondary {
      background-color: #f8f9fa;
      color: #6c757d;
    }

    .btn-secondary:hover {
      background-color: #e9ecef;
    }

    .btn-primary {
      background-color: #007bff;
      color: white;
    }

    .btn-primary:hover {
      background-color: #0056b3;
    }
  `]
})
export class ConfirmationDialogComponent {
  @Input() visible: boolean = false;
  @Input() title: string = 'Confirm Action';
  @Input() message: string = 'Are you sure you want to proceed?';
  @Input() confirmText: string = 'Confirm';
  @Input() cancelText: string = 'Cancel';
  @Input() closeOnOverlayClick: boolean = true;

  @Output() confirm = new EventEmitter<void>();
  @Output() cancel = new EventEmitter<void>();

  onConfirm(): void {
    this.confirm.emit();
    this.visible = false;
  }

  onCancel(): void {
    this.cancel.emit();
    this.visible = false;
  }

  onOverlayClick(): void {
    if (this.closeOnOverlayClick) {
      this.onCancel();
    }
  }
}