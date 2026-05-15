import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-page',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="container-fluid py-3">
      <h4 *ngIf="title" class="mb-3">{{ title }}</h4>
      <ng-content></ng-content>
    </div>
  `,
})
export class PageComponent {
  @Input() title = '';
}
