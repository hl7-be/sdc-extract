import { Component, ChangeDetectorRef, OnInit, Renderer2, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { Subject, filter, switchMap, takeUntil, skip, of, catchError, forkJoin } from 'rxjs';

import { IconsModule } from '../../../shared/icons/icons.module';
import { I18nTranslatePipe } from '../../../shared/i18n/translate.pipe';
import { ToastrService } from '../../../shared/toastr/toastr.service';

import { MappingWizardComponent } from '../mapping-wizard/mapping-wizard.component';
import { FhirQuestionnaireMapperService } from '../../service/fhirquestionnaire-mapper.service';
import { DatasetState } from './dataset.state';

declare let LForms: any;

const DEFINITION_EXTRACT_EXT = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract';
const SNOMED_SYSTEM = 'http://snomed.info/sct';

@Component({
  selector: 'app-question-list',
  standalone: true,
  imports: [CommonModule, RouterModule, IconsModule, I18nTranslatePipe, MappingWizardComponent],
  styleUrls: ['./questions-list.component.scss'],
  templateUrl: './questions-list.component.html',
})
export class QuestionsListComponent implements OnInit, OnDestroy {
  data: any;

  selectedId = '';
  selectedLabel = '';
  selectedItemType = '';

  previewEnabled = false;
  fetchedResponse = null;
  isCheckingResponse = true;
  showHelp = false;

  private destroy$ = new Subject<void>();
  private unlisten: (() => void) | null = null;
  private initLFormsTimeoutId: ReturnType<typeof setTimeout> | null = null;
  private clickListenerTimeoutId: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private dataState: DatasetState,
    private cdr: ChangeDetectorRef,
    private i18n: I18nTranslatePipe,
    private renderer: Renderer2,
    private fhirQuestionnaireMapperService: FhirQuestionnaireMapperService,
    private toastrService: ToastrService
  ) {}

  latestQuestionnaire: any = null;

  ngOnInit(): void {
    this.dataState.savedMapping
      .pipe(
        takeUntil(this.destroy$),
        filter(Boolean),
        skip(1)
      )
      .subscribe((latestQuestionnaire) => {
        this.latestQuestionnaire = latestQuestionnaire;
        const container = document.getElementById('lhcFormsContainer');
        if (container) {
          this.updateLFormsLabels(container, latestQuestionnaire);
          this.tagLFormsRows(container, latestQuestionnaire);
        }
      });

    this.dataState.dataset
      .pipe(
        takeUntil(this.destroy$),
        filter(Boolean),
        switchMap((q_id) => {
          this.isCheckingResponse = true;
          return forkJoin({
            questions: this.fhirQuestionnaireMapperService.getQuestionnaire(q_id!),
            responseCheck: this.fhirQuestionnaireMapperService
              .getQuestionnaireResponse(q_id!)
              .pipe(catchError(() => of(null))),
          });
        })
      )
      .subscribe(({ questions, responseCheck }) => {
        this.fetchedResponse = responseCheck;
        this.isCheckingResponse = false;

        const mapIncomingItems = (items: any[]): any[] => {
          return items.map((item) => {
            const newItem = { ...item };
            if (newItem.linkId) {
              newItem.id = newItem.linkId;
            }
            if (newItem.item?.length) {
              newItem.item = mapIncomingItems(newItem.item);
            }
            return newItem;
          });
        };

        if (questions?.item) {
          questions.item = mapIncomingItems(questions.item);
        }

        this.data = questions;
        this.latestQuestionnaire = this.data;
        this.dataState.setSavedMapping(this.data);
        this.refreshLForms();
        this.cdr.detectChanges();
      });
  }

  private refreshLForms(): void {
    if (!this.latestQuestionnaire) return;

    this.loadLFormsAssets().then(() => {
      const lformsData = JSON.parse(JSON.stringify(this.latestQuestionnaire));

      const addLinkId = (items: any[]): void => {
        items.forEach((item: any) => {
          if (item.id) {
            item.linkId = item.id;
            if (!item.text) item.text = item.id;
          }
          if (item.item) addLinkId(item.item);
        });
      };

      if (lformsData.item) addLinkId(lformsData.item);

      const questionnaireResponse = this.previewEnabled ? this.fetchedResponse : null;
      this.initLForms(lformsData, questionnaireResponse);
    });
  }

  private loadLFormsAssets(): Promise<void> {
    if (typeof LForms !== 'undefined') return Promise.resolve();

    if (!document.querySelector('link[href*="lforms/styles.css"]')) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'assets/lib/lforms/styles.css';
      document.head.appendChild(link);
    }

    return this.loadScript('assets/lib/lforms/jquery.min.js')
      .then(() => this.loadScript('assets/lib/lforms/moment.min.js'))
      .then(() => this.loadScript('assets/lib/lforms/lhc-forms.js'))
      .then(() => this.loadScript('assets/lib/lforms/lformsFHIRAll.min.js'))
      .catch((e) => {
        console.error('LForms script loading error', e);
        throw e;
      });
  }

  private loadScript(src: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (document.querySelector(`script[src="${src}"]`)) {
        resolve();
        return;
      }
      const script = document.createElement('script');
      script.src = src;
      script.onload = () => resolve();
      script.onerror = (e) => reject(e);
      document.body.appendChild(script);
    });
  }

  private setupLFormsClickListener(lformsData: any): void {
    const container = document.getElementById('lhcFormsContainer');
    if (!container) return;
    this.tagLFormsRows(container, lformsData);

    this.unlisten?.();
    this.unlisten = this.renderer.listen(container, 'click', (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      const row = target.closest('[data-linkid]') as HTMLElement;
      if (row) {
        const linkId = row.getAttribute('data-linkid');
        if (linkId) this.handleRowSelection(linkId, row);
      }
    });
  }

  private updateLFormsLabels(container: HTMLElement, questionnaire: any): void {
    if (!questionnaire?.item) return;

    const applyLabels = (items: any[]): void => {
      items.forEach((item: any) => {
        const linkId = item.linkId || item.id;
        const newText: string | undefined = item.text;
        if (linkId && newText) {
          const labelEl = container.querySelector(`label[id^="label-${CSS.escape(linkId)}"]`);
          if (labelEl) {
            labelEl.textContent = newText;
          }
          if (this.data?.item) {
            const inMemItem = this.findItemById(linkId, this.data.item);
            if (inMemItem) inMemItem.text = newText;
          }
        }
        if (item.item?.length) applyLabels(item.item);
      });
    };

    applyLabels(questionnaire.item);
  }

  private tagLFormsRows(container: HTMLElement, lformsData: any): void {
    const lhcItems = Array.from(container.querySelectorAll('lhc-item')) as HTMLElement[];

    interface ItemMeta {
      type: string;
      annotationStatus: 'full' | 'partial' | 'none';
    }

    const itemMetaMap: { [linkId: string]: ItemMeta } = {};

    const buildMap = (items: any[]): void => {
      items.forEach((item: any) => {
        const linkId = item.linkId || item.id;
        if (!linkId) return;

        const type = item.type || '';
        let status: 'full' | 'partial' | 'none' = 'none';

        if (type === 'group') {
          const hasExtract = (item.extension || []).some((e: any) => e.url === DEFINITION_EXTRACT_EXT);
          status = hasExtract ? 'full' : 'none';
        } else if (type !== 'display') {
          const hasDefinition = typeof item.definition === 'string' && item.definition.includes('#');
          const hasSnomedCode = (item.code || []).some((c: any) => c.system === SNOMED_SYSTEM);
          if (hasDefinition && hasSnomedCode) {
            status = 'full';
          } else if (hasDefinition || hasSnomedCode) {
            status = 'partial';
          }
        }

        itemMetaMap[linkId] = { type, annotationStatus: status };
        if (item.item) buildMap(item.item);
      });
    };
    if (lformsData?.item) buildMap(lformsData.item);

    lhcItems.forEach((el) => {
      const label = el.querySelector('label[id^="label-"]');
      if (!label) return;

      const linkId = label.id.replace(/^label-/, '').split('/')[0];
      if (!linkId) return;

      const meta = itemMetaMap[linkId];
      const itemType = meta?.type || '';
      el.setAttribute('data-linkid', linkId);
      el.setAttribute('data-type', itemType);
      el.style.cursor = itemType === 'display' ? 'default' : 'pointer';

      el.querySelector('.annotation-badge')?.remove();

      if (itemType && itemType !== 'display') {
        const status = meta?.annotationStatus ?? 'none';
        const badge = document.createElement('span');
        badge.className = 'annotation-badge';
        badge.title =
          status === 'full'
            ? 'Configured'
            : status === 'partial'
            ? 'Partially configured — element path or SNOMED code missing'
            : 'Not configured — click to annotate';
        Object.assign(badge.style, {
          display: 'inline-block',
          width: '8px',
          height: '8px',
          borderRadius: '50%',
          marginLeft: '6px',
          verticalAlign: 'middle',
          flexShrink: '0',
          backgroundColor: status === 'full' ? '#198754' : status === 'partial' ? '#ffc107' : '#ced4da',
        });
        label.appendChild(badge);
      }
    });
  }

  private handleRowSelection(linkId: string, element: HTMLElement): void {
    if (!this.data) return;
    const item = this.findItemById(linkId, this.data.item);
    if (!item) return;

    this.selectedId = item.id;
    this.selectedLabel = item.text || item.id;
    this.selectedItemType = item.type || '';

    const container = document.getElementById('lhcFormsContainer');
    container?.querySelectorAll('.lforms-row-selected').forEach((el) => el.classList.remove('lforms-row-selected'));
    element.classList.add('lforms-row-selected');

    this.cdr.detectChanges();
  }

  private initLForms(lformsData: any, questionnaireResponse: any = null, attempts = 0): void {
    const container = document.getElementById('lhcFormsContainer');

    if (!container && attempts < 20) {
      this.cdr.detectChanges();
      this.initLFormsTimeoutId = setTimeout(
        () => this.initLForms(lformsData, questionnaireResponse, attempts + 1),
        100
      );
      return;
    }

    if (container) {
      try {
        const options: any = {
          fhirVersion: 'R4',
          templateOptions: { showQuestionUnits: true },
        };
        if (questionnaireResponse) {
          options.questionnaireResponse = questionnaireResponse;
        }
        LForms.Util.addFormToPage(lformsData, container, options);
        this.clickListenerTimeoutId = setTimeout(() => {
          this.setupLFormsClickListener(lformsData);
          if (this.latestQuestionnaire) {
            this.updateLFormsLabels(container, this.latestQuestionnaire);
            this.tagLFormsRows(container, this.latestQuestionnaire);
          }
        }, 500);
      } catch (e) {
        this.toastrService.error('LForms error during addFormToPage: ' + (e as any)?.message);
      }
    } else {
      this.toastrService.error('lhcFormsContainer not found after 20 attempts');
    }
  }

  private findItemById(id: string, items: any[]): any | null {
    if (!items || !Array.isArray(items)) return null;
    for (const item of items) {
      if (item.id === id) return item;
      if (item.item?.length) {
        const found = this.findItemById(id, item.item);
        if (found) return found;
      }
    }
    return null;
  }

  togglePreview(event: Event): void {
    this.previewEnabled = (event.target as HTMLInputElement).checked;
    this.refreshLForms();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.unlisten?.();
    if (this.initLFormsTimeoutId !== null) clearTimeout(this.initLFormsTimeoutId);
    if (this.clickListenerTimeoutId !== null) clearTimeout(this.clickListenerTimeoutId);
  }
}
