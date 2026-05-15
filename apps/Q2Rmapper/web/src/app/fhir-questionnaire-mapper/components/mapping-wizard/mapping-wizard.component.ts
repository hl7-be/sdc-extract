import { Component, Input, OnChanges, OnInit, SimpleChanges, ChangeDetectorRef, OnDestroy, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormControl } from '@angular/forms';
import { NgbTooltipModule } from '@ng-bootstrap/ng-bootstrap';

import { Subject, of, EMPTY } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  map,
  switchMap,
  tap,
  takeUntil,
  finalize,
} from 'rxjs/operators';

import { ToastrService } from '../../../shared/toastr/toastr.service';
import { I18nTranslatePipe } from '../../../shared/i18n/translate.pipe';
import { EnvironmentVariablesService, EnvironmentVariables } from '../../../shared/environment.token';

import { DatasetState } from '../questions-list/dataset.state';
import { SnomedItem, FhirQuestionnaireMapperService } from '../../service/fhirquestionnaire-mapper.service';

const SNOMED_SYSTEM = 'http://snomed.info/sct';
const FHIR_DEFINITION_BASE = 'http://hl7.org/fhir/StructureDefinition/';
const DEFINITION_EXTRACT_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract';
const DEFINITION_EXTRACT_VALUE_URL =
  'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue';

export type FixedValueType = 'valueCode' | 'valueString' | 'valueUri' | 'valueReference' | 'valueCodeableConcept';

export interface FixedValueEntry {
  elementPath: string;
  valueType: FixedValueType;
  valueSimple: string;
  valueSystem: string;
  valueCodingCode: string;
  valueDisplay: string;
  snomedQuery?: string;
  snomedResults?: SnomedItem[];
}

@Component({
  selector: 'app-mapping-wizard',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, I18nTranslatePipe, NgbTooltipModule],
  styleUrls: ['./mapping-wizard.component.scss'],
  templateUrl: './mapping-wizard.component.html',
})
export class MappingWizardComponent implements OnChanges, OnInit, OnDestroy {
  @Input() selectedId = '';
  @Input() label = '';
  @Input() itemType = '';
  @Input() questions: any[] = [];
  @Input() fullQuestionnaire: any;

  get isGroup(): boolean {
    return this.itemType === 'group';
  }

  get parentGroup(): any | null {
    if (!this.selectedId || this.isGroup) return null;
    const result = this.findParentGroup(this.selectedId, this.questions ?? [], null);
    return result?.parent ?? null;
  }

  get parentHasExtract(): boolean {
    const pg = this.parentGroup;
    if (!pg) return false;
    const pgId = pg.id || pg.linkId;
    if (pgId && this.mappings[pgId]?.resourceCategories) return true;
    return (pg.extension || []).some((e: any) => e.url === DEFINITION_EXTRACT_URL);
  }

  get parentGroupLabel(): string {
    const pg = this.parentGroup;
    return pg ? pg.text || pg.id || pg.linkId || '' : '';
  }

  get parentResourceType(): string {
    const pg = this.parentGroup;
    if (!pg) return '';
    const pgId = pg.id || pg.linkId;
    if (pgId && this.mappings[pgId]?.resourceCategories) {
      return this.mappings[pgId].resourceCategories;
    }
    const ext = (pg.extension || []).find((e: any) => e.url === DEFINITION_EXTRACT_URL);
    const canonical: string = ext?.valueCanonical ?? '';
    return canonical ? canonical.split('/').pop() ?? '' : '';
  }

  private findParentGroup(targetId: string, items: any[], lastGroup: any | null): { parent: any | null } | null {
    for (const item of items) {
      if (item.id === targetId || item.linkId === targetId) {
        return { parent: lastGroup };
      }
      if (item.item?.length) {
        const result = this.findParentGroup(targetId, item.item, item.type === 'group' ? item : lastGroup);
        if (result !== null) return result;
      }
    }
    return null;
  }

  _label = '';
  resourceCategories = '';
  snomedId = '';
  targetPath = '';
  snomedItems: SnomedItem[] = [];
  fhirElements: string[] = [];
  isFetchingElements = false;
  isSearchingSnomed = false;
  isInitializing = true;
  fixedValues: FixedValueEntry[] = [];

  resourceTypeOptions: string[] = [
    'Observation', 'Condition', 'Procedure', 'MedicationStatement', 'AllergyIntolerance',
    'DiagnosticReport', 'Encounter', 'Patient', 'Practitioner', 'FamilyMemberHistory', 'ClinicalImpression',
  ];

  savedResourceCategory = '';
  savedTargetPath = '';

  snomedControl = new FormControl('');
  mappings: { [id: string]: any } = {};
  hasSearched = false;

  private destroy$ = new Subject<void>();
  private fixedValueSnomedSearch$ = new Subject<{ index: number; query: string }>();
  private resourceTypeChange$ = new Subject<string>();

  constructor(
    private datasetState: DatasetState,
    private fhirQuestionnaireMapperService: FhirQuestionnaireMapperService,
    private cdr: ChangeDetectorRef,
    private toastrService: ToastrService,
    private i18n: I18nTranslatePipe,
    @Inject(EnvironmentVariablesService) private env: EnvironmentVariables
  ) {}

  getSnomedBrowserUrl(code: string): string {
    const base = this.env.snomedBrowserBaseUrl ?? 'https://browser.ihtsdotools.org/?perspective=full';
    return `${base}&conceptId1=${code}`;
  }

  ngOnInit(): void {
    this.fhirQuestionnaireMapperService
      .prefetchAllFhirElements(this.resourceTypeOptions)
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => {
          this.isInitializing = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe();

    this.snomedControl.valueChanges
      .pipe(
        takeUntil(this.destroy$),
        debounceTime(300),
        distinctUntilChanged(),
        tap(() => {
          this.hasSearched = false;
          this.isSearchingSnomed = true;
          this.cdr.detectChanges();
        }),
        switchMap((value) => {
          if (!value || value.length < 2) {
            this.snomedItems = [];
            this.isSearchingSnomed = false;
            return of([]);
          }
          return this.fhirQuestionnaireMapperService.getSnomedCode(value).pipe(
            catchError(() => {
              this.hasSearched = true;
              this.isSearchingSnomed = false;
              return of([]);
            })
          );
        })
      )
      .subscribe((results) => {
        this.snomedItems = results || [];
        this.hasSearched = true;
        this.isSearchingSnomed = false;
        this.cdr.detectChanges();
      });

    this.fixedValueSnomedSearch$
      .pipe(
        takeUntil(this.destroy$),
        debounceTime(300),
        distinctUntilChanged((a, b) => a.index === b.index && a.query === b.query),
        switchMap(({ index, query }) => {
          if (!query || query.length < 2) {
            return of({ index, results: [] as SnomedItem[] });
          }
          return this.fhirQuestionnaireMapperService.getSnomedCode(query).pipe(
            map((results) => ({ index, results: results || [] })),
            catchError(() => of({ index, results: [] as SnomedItem[] }))
          );
        })
      )
      .subscribe(({ index, results }) => {
        if (this.fixedValues[index]) {
          this.fixedValues[index].snomedResults = results;
          this.cdr.detectChanges();
        }
      });

    this.resourceTypeChange$
      .pipe(
        takeUntil(this.destroy$),
        tap((resourceType) => {
          if (!resourceType) {
            this.fhirElements = [];
          } else {
            this.isFetchingElements = true;
          }
          this.updateLiveJson();
          this.cdr.detectChanges();
        }),
        switchMap((resourceType) => {
          if (!resourceType) return EMPTY;
          return this.fhirQuestionnaireMapperService.getFhirElements(resourceType).pipe(
            catchError((err) => {
              this.isFetchingElements = false;
              this.toastrService.error('Fout bij ophalen FHIR elementen: ' + (err?.message || err));
              this.cdr.detectChanges();
              return EMPTY;
            })
          );
        })
      )
      .subscribe((elements) => {
        this.fhirElements = elements || [];
        this.isFetchingElements = false;
        this.cdr.detectChanges();
      });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['selectedId']) {
      const prevId = changes['selectedId'].previousValue;
      if (prevId) {
        const prevItemType = changes['itemType']?.previousValue ?? this.itemType;
        const snapshot = this.currentMappingSnapshot(prevId);
        snapshot.itemType = prevItemType;
        this.mappings[prevId] = snapshot;
      }

      const newId = changes['selectedId'].currentValue;
      if (newId) {
        const existing = this.mappings[newId];
        if (existing) {
          this._label = existing.label || this.label;
          this.resourceCategories = existing.resourceCategories || this.parentResourceType;
          this.snomedId = existing.snomedCode || '';
          this.snomedControl.setValue(existing.snomedDisplay || '', { emitEvent: false });
          this.targetPath = existing.targetPath || '';
          this.fixedValues = (existing.fixedValues || []).map((fv: FixedValueEntry) => ({
            ...fv,
            snomedResults: [],
          }));
          this.savedResourceCategory = this.resourceCategories;
          this.savedTargetPath = this.targetPath;
        } else {
          this._label = this.label;
          this.resourceCategories = this.parentResourceType;
          this.snomedId = '';
          this.snomedControl.setValue('', { emitEvent: false });
          this.targetPath = '';
          this.fixedValues = [];
          this.savedResourceCategory = '';
          this.savedTargetPath = '';
        }
        this.snomedItems = [];
        this.onResourceTypeChange();
        this.cdr.detectChanges();
      }
      this.updateLiveJson();
    }

    if (changes['questions'] && this.questions) {
      this.loadExistingMappings(this.questions);
      this.updateLiveJson();
    }
  }

  onResourceTypeUserChange(): void {
    this.targetPath = '';
    this.onResourceTypeChange();
  }

  onResourceTypeChange(): void {
    this.resourceTypeChange$.next(this.resourceCategories);
  }

  selectSnomedItem(item: SnomedItem): void {
    this.snomedId = item.id;
    this.snomedControl.setValue(item.display, { emitEvent: false });
    this.snomedItems = [];
    this.hasSearched = false;
    this.updateLiveJson();
  }

  addFixedValue(): void {
    this.fixedValues.push({
      elementPath: this.fhirElements[0] || '',
      valueType: 'valueCodeableConcept',
      valueSimple: '',
      valueSystem: SNOMED_SYSTEM,
      valueCodingCode: '',
      valueDisplay: '',
      snomedQuery: '',
      snomedResults: [],
    });
    this.updateLiveJson();
  }

  removeFixedValue(index: number): void {
    this.fixedValues.splice(index, 1);
    this.updateLiveJson();
  }

  getValuePlaceholder(valueType: FixedValueType): string {
    switch (valueType) {
      case 'valueCode': return 'e.g. final';
      case 'valueString': return 'text value';
      case 'valueUri': return 'e.g. http://unitsofmeasure.org';
      case 'valueReference': return 'e.g. Patient/123';
      default: return 'value';
    }
  }

  onFixedValueSnomedInput(index: number, query: string): void {
    if (!this.fixedValues[index]) return;
    this.fixedValues[index].snomedQuery = query;
    if (!query || query.length < 2) {
      this.fixedValues[index].snomedResults = [];
    }
    this.fixedValueSnomedSearch$.next({ index, query });
  }

  selectFixedValueSnomedItem(index: number, item: SnomedItem): void {
    const fv = this.fixedValues[index];
    if (!fv) return;
    fv.valueSystem = item.system || SNOMED_SYSTEM;
    fv.valueCodingCode = item.id;
    fv.valueDisplay = item.display;
    fv.snomedQuery = item.display;
    fv.snomedResults = [];
    this.updateLiveJson();
    this.cdr.detectChanges();
  }

  updateLiveJson(): void {
    const questionnaire = this.generateMappedQuestionnaire();
    this.datasetState.setSavedMapping(questionnaire);
  }

  save(): void {
    const questionnaire = this.generateMappedQuestionnaire();
    this.datasetState.setSavedMapping(questionnaire);
    this.fhirQuestionnaireMapperService
      .updateQuestionnaireAndStatus(questionnaire, 'PARTIAL')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () =>
          this.toastrService.success(this.i18n.transform('wizard.save-success')),
        error: (err) =>
          this.toastrService.error(
            this.i18n.transform('wizard.save-error') + (err?.message || err)
          ),
      });
  }

  private currentMappingSnapshot(id: string): any {
    return {
      id,
      itemType: this.itemType,
      label: this._label,
      resourceCategories: this.resourceCategories,
      snomedCode: this.snomedId,
      snomedDisplay: this.snomedControl.value,
      targetPath: this.targetPath,
      fixedValues: this.fixedValues.map(({ snomedResults: _r, ...fv }) => ({ ...fv })),
    };
  }

  private generateMappedQuestionnaire(): any {
    if (this.selectedId) {
      this.mappings[this.selectedId] = this.currentMappingSnapshot(this.selectedId);
    }

    const mapItem = (item: any): any => {
      const mapping = this.mappings[item.id];
      const newItem = { ...item, linkId: item.id };

      if (mapping) {
        const isGroupItem = mapping.itemType === 'group' || item.type === 'group';

        if (mapping.snomedCode) {
          newItem.code = [{ system: SNOMED_SYSTEM, code: mapping.snomedCode, display: mapping.snomedDisplay || mapping.label || item.text || item.id }];
        }

        if (isGroupItem) {
          if (mapping.resourceCategories) {
            const canonical = `${FHIR_DEFINITION_BASE}${mapping.resourceCategories}`;
            const extensions: any[] = (newItem.extension || []).filter(
              (e: any) => e.url !== DEFINITION_EXTRACT_URL && e.url !== DEFINITION_EXTRACT_VALUE_URL
            );
            extensions.push({ url: DEFINITION_EXTRACT_URL, valueCanonical: canonical });

            const userFixedValues: FixedValueEntry[] = mapping.fixedValues || [];
            for (const fv of userFixedValues) {
              if (!fv.elementPath) continue;
              const ext = this.buildFixedValueExtension(`${canonical}#${fv.elementPath}`, fv);
              if (ext) extensions.push(ext);
            }

            if (mapping.resourceCategories === 'Observation' && mapping.snomedCode) {
              const userHasCode = userFixedValues.some((fv) => fv.elementPath === 'Observation.code');
              if (!userHasCode) {
                extensions.push({
                  url: DEFINITION_EXTRACT_VALUE_URL,
                  extension: [
                    { url: 'definition', valueUri: `${canonical}#Observation.code` },
                    { url: 'fixed-value', valueCodeableConcept: { coding: [{ system: SNOMED_SYSTEM, code: mapping.snomedCode, display: mapping.snomedDisplay || '' }] } },
                  ],
                });
              }
            }

            newItem.extension = extensions;
          } else {
            if (newItem.extension) {
              const cleaned = (newItem.extension as any[]).filter(
                (e: any) => e.url !== DEFINITION_EXTRACT_URL && e.url !== DEFINITION_EXTRACT_VALUE_URL
              );
              newItem.extension = cleaned.length > 0 ? cleaned : undefined;
            }
          }
        } else {
          if (mapping.resourceCategories && mapping.targetPath) {
            newItem.definition = `${FHIR_DEFINITION_BASE}${mapping.resourceCategories}#${mapping.targetPath}`;
          }
          const canonical = mapping.resourceCategories ? `${FHIR_DEFINITION_BASE}${mapping.resourceCategories}` : null;
          const userFixedValues: FixedValueEntry[] = mapping.fixedValues || [];
          const extensions: any[] = (newItem.extension || []).filter(
            (e: any) => e.url !== DEFINITION_EXTRACT_URL && e.url !== DEFINITION_EXTRACT_VALUE_URL
          );
          if (canonical) {
            for (const fv of userFixedValues) {
              if (!fv.elementPath) continue;
              const ext = this.buildFixedValueExtension(`${canonical}#${fv.elementPath}`, fv);
              if (ext) extensions.push(ext);
            }
          }
          if (extensions.length > 0) {
            newItem.extension = extensions;
          } else {
            delete newItem.extension;
          }
        }

        if (mapping.label) newItem.text = mapping.label;
      } else {
        if (item.type !== 'group' && newItem.extension) {
          const cleaned = (newItem.extension as any[]).filter((e: any) => e.url !== DEFINITION_EXTRACT_URL);
          if (cleaned.length !== newItem.extension.length) {
            newItem.extension = cleaned.length > 0 ? cleaned : undefined;
          }
        }
      }

      if (item.item?.length) newItem.item = item.item.map(mapItem);
      return newItem;
    };

    return { ...this.fullQuestionnaire, item: this.questions.map(mapItem) };
  }

  private buildFixedValueExtension(definitionUri: string, fv: FixedValueEntry): any | null {
    let fixedValueKey: string;
    let fixedValue: any;

    switch (fv.valueType) {
      case 'valueCode':
      case 'valueString':
      case 'valueUri':
        if (!fv.valueSimple) return null;
        fixedValueKey = fv.valueType;
        fixedValue = fv.valueSimple;
        break;
      case 'valueReference':
        if (!fv.valueSimple) return null;
        fixedValueKey = 'valueReference';
        fixedValue = { reference: fv.valueSimple };
        break;
      case 'valueCodeableConcept':
        if (!fv.valueCodingCode) return null;
        fixedValueKey = 'valueCodeableConcept';
        fixedValue = { coding: [{ system: fv.valueSystem || SNOMED_SYSTEM, code: fv.valueCodingCode, display: fv.valueDisplay || '' }] };
        break;
      default:
        return null;
    }

    return {
      url: DEFINITION_EXTRACT_VALUE_URL,
      extension: [
        { url: 'definition', valueUri: definitionUri },
        { url: 'fixed-value', [fixedValueKey]: fixedValue },
      ],
    };
  }

  private loadExistingMappings(items: any[]): void {
    const processItem = (item: any): void => {
      const mapping: any = { id: item.id, itemType: item.type || '' };
      let hasMapping = false;

      if (item.type === 'group') {
        const extractExt = (item.extension || []).find((e: any) => e.url === DEFINITION_EXTRACT_URL);
        if (extractExt?.valueCanonical) {
          const canonical: string = extractExt.valueCanonical;
          const resourceType = canonical.startsWith(FHIR_DEFINITION_BASE)
            ? canonical.substring(FHIR_DEFINITION_BASE.length)
            : canonical.split('/').pop() || canonical;
          const matched = this.resourceTypeOptions.find((o) => o.toLowerCase() === resourceType.toLowerCase());
          mapping.resourceCategories = matched || resourceType;
          hasMapping = true;
        }
      } else {
        if (item.definition && item.definition.startsWith(FHIR_DEFINITION_BASE)) {
          const afterBase = item.definition.substring(FHIR_DEFINITION_BASE.length);
          const parts = afterBase.split('#');
          if (parts.length === 2) {
            const matched = this.resourceTypeOptions.find((o) => o.toLowerCase() === parts[0].toLowerCase());
            mapping.resourceCategories = matched || parts[0];
            mapping.targetPath = parts[1];
            hasMapping = true;
          }
        }

        if (!mapping.resourceCategories) {
          const extractExt = (item.extension || []).find((e: any) => e.url === DEFINITION_EXTRACT_URL);
          if (extractExt?.valueCanonical) {
            const canonical: string = extractExt.valueCanonical;
            const resourceType = canonical.startsWith(FHIR_DEFINITION_BASE)
              ? canonical.substring(FHIR_DEFINITION_BASE.length)
              : canonical.split('/').pop() || canonical;
            const matched = this.resourceTypeOptions.find((o) => o.toLowerCase() === resourceType.toLowerCase());
            mapping.resourceCategories = matched || resourceType;
            hasMapping = true;
          }
        }

      }

      if (item.code) {
        const snomedCode = item.code.find((c: any) => c.system === SNOMED_SYSTEM);
        if (snomedCode) {
          mapping.snomedCode = snomedCode.code;
          mapping.snomedDisplay = snomedCode.display;
          hasMapping = true;
        }
      }

      const fixedValues = this.readFixedValues(item.extension || []);
      if (fixedValues.length > 0) { mapping.fixedValues = fixedValues; hasMapping = true; }

      mapping.label = item.text;
      if (hasMapping || item.text) this.mappings[item.id] = mapping;
      if (item.item && item.item.length > 0) item.item.forEach(processItem);
    };

    items.forEach(processItem);

    if (this.selectedId) {
      const existing = this.mappings[this.selectedId];
      if (existing) {
        this._label = existing.label || this.label;
        this.resourceCategories = existing.resourceCategories || '';
        this.snomedId = existing.snomedCode || '';
        this.snomedControl.setValue(existing.snomedDisplay || '', { emitEvent: false });
        this.targetPath = existing.targetPath || '';
        this.fixedValues = (existing.fixedValues || []).map((fv: FixedValueEntry) => ({ ...fv, snomedResults: [] }));
        this.onResourceTypeChange();
      }
    }
  }

  private readFixedValues(extensions: any[]): FixedValueEntry[] {
    const result: FixedValueEntry[] = [];
    for (const ext of extensions) {
      if (ext.url !== DEFINITION_EXTRACT_VALUE_URL) continue;
      const subs: any[] = ext.extension || [];
      const defSub = subs.find((s: any) => s.url === 'definition');
      const fvSub = subs.find((s: any) => s.url === 'fixed-value');
      if (!defSub || !fvSub) continue;

      const definitionUri: string = defSub.valueUri ?? defSub.valueUrl ?? defSub.valueString ?? '';
      const hashIdx = definitionUri.indexOf('#');
      if (hashIdx === -1) continue;

      const elementPath = definitionUri.substring(hashIdx + 1);
      let valueType: FixedValueType = 'valueCode';
      let valueSimple = '', valueSystem = SNOMED_SYSTEM, valueCodingCode = '', valueDisplay = '';

      if (fvSub.valueCode !== undefined) { valueType = 'valueCode'; valueSimple = String(fvSub.valueCode); }
      else if (fvSub.valueString !== undefined) { valueType = 'valueString'; valueSimple = String(fvSub.valueString); }
      else if (fvSub.valueUri !== undefined) { valueType = 'valueUri'; valueSimple = String(fvSub.valueUri); }
      else if (fvSub.valueReference !== undefined) {
        valueType = 'valueReference';
        valueSimple = typeof fvSub.valueReference === 'string' ? fvSub.valueReference : fvSub.valueReference?.reference ?? JSON.stringify(fvSub.valueReference);
      } else if (fvSub.valueCodeableConcept !== undefined) {
        valueType = 'valueCodeableConcept';
        const coding = fvSub.valueCodeableConcept?.coding?.[0];
        if (coding) { valueSystem = coding.system ?? SNOMED_SYSTEM; valueCodingCode = coding.code ?? ''; valueDisplay = coding.display ?? ''; }
      }

      result.push({ elementPath, valueType, valueSimple, valueSystem, valueCodingCode, valueDisplay, snomedQuery: valueType === 'valueCodeableConcept' ? valueDisplay : '', snomedResults: [] });
    }
    return result;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.resourceTypeChange$.complete();
  }
}
