import { Component, OnDestroy, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, takeUntil } from 'rxjs';

import { I18nTranslatePipe } from '../../../shared/i18n/translate.pipe';
import { DatasetState } from '../questions-list/dataset.state';

declare let LForms: any;

@Component({
  selector: 'app-live-json',
  standalone: true,
  imports: [CommonModule, I18nTranslatePipe],
  templateUrl: './live-json.component.html',
})
export class LiveJsonComponent implements OnInit, OnDestroy {
  questionnaire: any = null;
  questionnaireResponse: any = null;
  isCollapsed = true;

  private destroy$ = new Subject<void>();

  constructor(private datasetState: DatasetState, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.datasetState.savedMapping.pipe(takeUntil(this.destroy$)).subscribe((mapping) => {
      this.questionnaire = mapping;
      if (!this.isCollapsed) this.readQrFromLForms();
      this.cdr.detectChanges();
    });
  }

  toggle(): void {
    this.isCollapsed = !this.isCollapsed;
    if (!this.isCollapsed) this.readQrFromLForms();
  }

  refreshQr(event?: MouseEvent): void {
    event?.stopPropagation();
    this.readQrFromLForms();
    this.cdr.detectChanges();
  }

  private readQrFromLForms(): void {
    try {
      if (typeof LForms === 'undefined') {
        this.questionnaireResponse = null;
        return;
      }
      const qr = LForms.Util.getFormFHIRData('QuestionnaireResponse', 'R4', 'lhcFormsContainer');
      if (qr && !qr.questionnaire) {
        const qId = this.datasetState.currentDatasetId;
        if (qId) qr.questionnaire = `Questionnaire/${qId}`;
      }
      this.questionnaireResponse = qr ?? null;
    } catch {
      this.questionnaireResponse = null;
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
