import { Component, OnDestroy, TemplateRef, ViewChild, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

import { Subject, takeUntil } from 'rxjs';

import { I18nTranslatePipe } from '../../../shared/i18n/translate.pipe';
import { ToastrService } from '../../../shared/toastr/toastr.service';

import { FhirQuestionnaireMapperService } from '../../service/fhirquestionnaire-mapper.service';
import { DatasetState } from '../questions-list/dataset.state';

declare let LForms: any;

const DEFINITION_EXTRACT_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract';

export interface PreflightIssue {
  severity: 'error' | 'warning';
  message: string;
}

function runPreflightChecks(questionnaire: any, i18n: I18nTranslatePipe): PreflightIssue[] {
  const issues: PreflightIssue[] = [];
  const extractionGroups: string[] = [];
  const leavesWithDefinition: Array<{ linkId: string; ancestorGroupLinkId: string | null }> = [];

  function walk(items: any[], nearestExtractGroupId: string | null): void {
    for (const item of items || []) {
      const linkId: string = item.linkId || item.id || '(unknown)';
      const isGroup = item.type === 'group';
      const hasExtract = (item.extension || []).some((e: any) => e.url === DEFINITION_EXTRACT_URL);
      const hasDefinition = typeof item.definition === 'string' && item.definition.includes('#');

      if (isGroup) {
        const myExtractId = hasExtract ? linkId : null;
        if (hasExtract) extractionGroups.push(linkId);
        walk(item.item || [], myExtractId ?? nearestExtractGroupId);
      } else {
        if (hasDefinition) {
          leavesWithDefinition.push({ linkId, ancestorGroupLinkId: nearestExtractGroupId });
        }
      }
    }
  }

  walk(questionnaire?.item || [], null);

  if (extractionGroups.length === 0) {
    if (leavesWithDefinition.length === 0) {
      issues.push({
        severity: 'error',
        message: i18n.transform('no-extraction-groups.error'),
      });
    }
    return issues;
  }

  const orphanLeaves = leavesWithDefinition.filter((l) => l.ancestorGroupLinkId === null);
  for (const leaf of orphanLeaves) {
    issues.push({
      severity: 'warning',
      message: i18n.transform('no-ancestor-groups.warning', { leafId: leaf.linkId }),
    });
  }

  return issues;
}

@Component({
  selector: 'app-extraction-panel',
  standalone: true,
  imports: [CommonModule, I18nTranslatePipe],
  templateUrl: './extraction-panel.component.html',
})
export class ExtractionPanelComponent implements OnDestroy {
  @ViewChild('confirmModal') confirmModal!: TemplateRef<any>;

  bundle: any = null;
  errors: string[] = [];
  preflightIssues: PreflightIssue[] = [];
  isPreviewing = false;
  isSaving = false;
  isCollapsed = true;

  private lastQr: any = null;
  private destroy$ = new Subject<void>();

  get resourceCount(): number {
    return this.bundle?.entry?.length ?? 0;
  }

  constructor(
    private fhirQuestionnaireMapperService: FhirQuestionnaireMapperService,
    private datasetState: DatasetState,
    private modalService: NgbModal,
    private cdr: ChangeDetectorRef,
    private toastrService: ToastrService,
    private i18n: I18nTranslatePipe
  ) {}

  preview(): void {
    const qr = this.exportLFormsAsQr();
    const questionnaire = this.getQuestionnaireForExtraction();
    if (!qr || !questionnaire) return;

    this.preflightIssues = runPreflightChecks(questionnaire, this.i18n);
    const hasErrors = this.preflightIssues.some((i) => i.severity === 'error');
    if (hasErrors) {
      this.cdr.detectChanges();
      return;
    }

    this.lastQr = qr;
    this.isPreviewing = true;
    this.bundle = null;
    this.errors = [];
    this.isCollapsed = false;

    this.fhirQuestionnaireMapperService
      .extractQuestionnaireResponseFromBody(questionnaire, qr, false)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (result) => {
          this.bundle = result.bundle;
          this.errors = result.errors || [];
          this.isPreviewing = false;
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.isPreviewing = false;
          this.toastrService.error(
            this.i18n.transform('extraction.preview-error') +
              (err?.error?.detail || err?.message || err)
          );
          this.cdr.detectChanges();
        },
      });
  }

  openSaveConfirmation(): void {
    this.modalService.open(this.confirmModal, { ariaLabelledBy: 'extraction-confirm-title' }).result.then(
      (result) => { if (result === 'save') this.saveExtracted(); },
      () => {}
    );
  }

  private saveExtracted(): void {
    const qr = this.lastQr;
    const questionnaire = this.getQuestionnaireForExtraction();
    if (!qr || !questionnaire) return;

    this.isSaving = true;

    this.fhirQuestionnaireMapperService
      .extractQuestionnaireResponseFromBody(questionnaire, qr, true)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (result) => {
          this.bundle = result.bundle;
          this.errors = result.errors || [];
          this.isSaving = false;
          const persistFailed = this.errors.some((e) => e.startsWith('FHIR store rejected'));
          if (persistFailed) {
            this.toastrService.error(this.i18n.transform('extraction.save-error'));
          } else {
            this.toastrService.success(this.i18n.transform('extraction.save-success'));
          }
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.isSaving = false;
          this.toastrService.error(
            this.i18n.transform('extraction.save-error') +
              (err?.error?.detail || err?.message || err)
          );
          this.cdr.detectChanges();
        },
      });
  }

  private exportLFormsAsQr(): any | null {
    try {
      const qr = LForms.Util.getFormFHIRData('QuestionnaireResponse', 'R4', 'lhcFormsContainer');
      if (!qr) {
        this.toastrService.error(this.i18n.transform('extraction.no-lforms-data'));
        return null;
      }
      if (!qr.questionnaire) {
        const qId = this.datasetState.currentDatasetId;
        if (qId) qr.questionnaire = `Questionnaire/${qId}`;
      }
      return qr;
    } catch (e) {
      this.toastrService.error(this.i18n.transform('extraction.no-lforms-data'));
      return null;
    }
  }

  private getQuestionnaireForExtraction(): any | null {
    const q = this.datasetState.currentSavedMapping;
    if (!q) {
      this.toastrService.error(this.i18n.transform('extraction.no-lforms-data'));
      return null;
    }

    const clone = JSON.parse(JSON.stringify(q));

    const restoreLinkId = (items: any[]): void => {
      items.forEach((item: any) => {
        if (item.id && !item.linkId) item.linkId = item.id;
        if (item.item) restoreLinkId(item.item);
      });
    };

    if (clone.item) restoreLinkId(clone.item);
    return clone;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
