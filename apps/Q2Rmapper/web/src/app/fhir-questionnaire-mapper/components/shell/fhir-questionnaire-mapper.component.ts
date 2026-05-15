import { Component, OnInit, OnDestroy, ChangeDetectorRef, ViewChild, TemplateRef, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { NgbModal, NgbTypeaheadModule } from '@ng-bootstrap/ng-bootstrap';
import { Observable, Subject, merge, of, takeUntil } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';

import { PageComponent } from '../../../shared/page/page.component';
import { IconsModule } from '../../../shared/icons/icons.module';
import { PagingComponent } from '../../../shared/paging/paging.component';
import { PagingService } from '../../../shared/paging/paging.service';
import { PagingResult } from '../../../shared/paging/paging.models';
import { I18nTranslatePipe } from '../../../shared/i18n/translate.pipe';
import { ToastrService } from '../../../shared/toastr/toastr.service';

import { DatasetItem, FhirQuestionnaireMapperService } from '../../service/fhirquestionnaire-mapper.service';
import { SettingsState } from '../../service/settings.state';
import { DatasetState } from '../questions-list/dataset.state';
import { EnvironmentVariablesService, EnvironmentVariables, FhirServerPreset } from '../../../shared/environment.token';

@Component({
  selector: 'app-fhir-questionnaire-mapper',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    NgbTypeaheadModule,
    IconsModule,
    PagingComponent,
    I18nTranslatePipe,
    PageComponent,
  ],
  templateUrl: './fhir-questionnaire-mapper.component.html',
  styleUrl: './fhir-questionnaire-mapper.component.scss',
  providers: [PagingService],
})
export class FhirQuestionnaireMapperComponent implements OnInit, OnDestroy {
  @ViewChild('settingsModal') settingsModal!: TemplateRef<any>;

  searchTerm = '';
  displayDatasets: DatasetItem[] = [];
  appliedFilter: string | DatasetItem | null = null;
  loading = true;
  showNoResultsTimeout = false;
  apiKey = '';

  focus$ = new Subject<string>();
  click$ = new Subject<string>();

  private destroy$ = new Subject<void>();
  private noResultsTimeoutId: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private datasetState: DatasetState,
    public pagingService: PagingService<any>,
    private cdr: ChangeDetectorRef,
    private i18n: I18nTranslatePipe,
    private fhirQuestionnaireMapperService: FhirQuestionnaireMapperService,
    private settingsState: SettingsState,
    private modalService: NgbModal,
    private toastrService: ToastrService,
    @Inject(EnvironmentVariablesService) private env: EnvironmentVariables
  ) {}

  ngOnInit(): void {
    this.pagingService.init(10, null);

    this.fhirQuestionnaireMapperService.datasets$.pipe(takeUntil(this.destroy$)).subscribe(() => this.applyPaging());
    this.pagingService.pageChanges$.pipe(takeUntil(this.destroy$)).subscribe(() => this.applyPaging());

    this.fetchAndDisplayQuestionnaires();

    this.noResultsTimeoutId = setTimeout(() => {
      if (this.loading) {
        this.showNoResultsTimeout = true;
        this.cdr.detectChanges();
      }
    }, 5000);
  }

  private fetchAndDisplayQuestionnaires(): void {
    this.fhirQuestionnaireMapperService
      .loadQuestionnaires()
      .pipe(
        takeUntil(this.destroy$),
        map((data) => this.normalizeDatasets(data))
      )
      .subscribe({
        next: (mappedData) => {
          this.fhirQuestionnaireMapperService.setDatasets(mappedData);
          this.loading = false;
          this.applyPaging();
          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.loading = false;
          this.toastrService.error('Fout bij laden API: ' + (err?.message || err));
          this.cdr.detectChanges();
        },
      });
  }

  private normalizeDatasets(data: DatasetItem[]): DatasetItem[] {
    const nullTitleLabel = this.i18n.transform(
      'fhir-questionnaire.null-title'
    );
    const mapped = data.map((d) => ({
      ...d,
      id: d.id ?? '?',
      title: d.title ?? nullTitleLabel,
      mappingtag: d.mappingtag ?? 'NOT-STARTED',
    }));
    return mapped.sort((a, b) => {
      const aNull = a.title === nullTitleLabel;
      const bNull = b.title === nullTitleLabel;
      if (aNull && !bNull) return 1;
      if (!aNull && bNull) return -1;
      return a.title.localeCompare(b.title);
    });
  }

  applyPaging(): void {
    const datasetLoader = (): Observable<PagingResult<any>> => {
      const page = this.pagingService.getCurrentPage();
      const pageSize = 10;
      const start = page * pageSize;

      return of({
        data: this.filteredDatasets.slice(start, start + pageSize),
        totalSize: this.filteredDatasets.length,
        nextPagingParams: () => null,
      } as PagingResult<any>);
    };

    this.pagingService
      .getPage(datasetLoader)
      .pipe(takeUntil(this.destroy$))
      .subscribe((data) => {
        this.displayDatasets = data;
        this.cdr.detectChanges();
      });
  }

  get filteredDatasets(): DatasetItem[] {
    if (!this.fhirQuestionnaireMapperService.datasets) return [];

    const filterValue =
      typeof this.appliedFilter === 'string' ? this.appliedFilter : this.appliedFilter?.title || '';

    if (!filterValue) return this.fhirQuestionnaireMapperService.datasets;

    const term = filterValue.trim().toLowerCase();
    return this.fhirQuestionnaireMapperService.datasets.filter(
      (d: DatasetItem) =>
        d.id.toLowerCase().includes(term) ||
        d.title.toLowerCase().includes(term) ||
        d.mappingtag.toLowerCase().includes(term)
    );
  }

  onSearchSubmit(): void {
    this.appliedFilter = this.searchTerm;
    this.pagingService.clear(false);
    this.applyPaging();
  }

  onSuggestionClick(item: DatasetItem): void {
    this.searchTerm = item.title;
    this.appliedFilter = item;
    this.pagingService.clear(false);
    this.applyPaging();
  }

  suggest: (text$: Observable<string>) => Observable<any> = (text$: Observable<string>) => {
    const debouncedText$ = text$.pipe(debounceTime(200), distinctUntilChanged());
    return merge(debouncedText$, this.focus$, this.click$).pipe(
      map((term) => {
        if (term === '') return this.fhirQuestionnaireMapperService.datasets.slice(0, 10);

        const filtered = this.fhirQuestionnaireMapperService.datasets.filter(
          (v: DatasetItem) =>
            v.title.toLowerCase().includes(term.toLowerCase()) ||
            v.id.toLowerCase().includes(term.toLowerCase())
        );

        if (filtered.length === 0) {
          return [
            {
              id: 'NO_RESULT',
              title: this.i18n.transform('wizard.no-items-found'),
            },
          ];
        }

        return filtered.slice(0, 10);
      })
    );
  };

  formatter: (x: { title: string }) => string = (x: { title: string }) => x.title;

  setDataset(item: string | DatasetItem): void {
    const selectedItem =
      typeof item === 'string'
        ? this.fhirQuestionnaireMapperService.datasets.find((d: DatasetItem) => d.id === item)
        : item;

    if (selectedItem) {
      this.datasetState.setDataset(selectedItem.id);
      sessionStorage.setItem('selectedDataset', JSON.stringify(selectedItem));
    }
  }

  openSettings(content: any): void {
    const previousSettings = { ...this.settingsState.settings };
    this.apiKey = this.settingsState.settings.apiKey ?? '';

    this.modalService.open(content, { ariaLabelledBy: 'modal-basic-title' }).result.then(
      (result) => {
        if (result === 'save') {
          this.settingsState.updateSettings({ apiKey: this.apiKey });
          this.loading = true;
          this.showNoResultsTimeout = false;
          this.pagingService.clear(false);
          this.fetchAndDisplayQuestionnaires();
        } else {
          this.settingsState.updateSettings(previousSettings);
          this.apiKey = previousSettings.apiKey ?? '';
        }
      },
      () => {
        this.settingsState.updateSettings(previousSettings);
        this.apiKey = previousSettings.apiKey ?? '';
      }
    );
  }

  updateSettings(settings: any): void {
    this.settingsState.updateSettings(settings);
  }

  get settings() {
    return this.settingsState.settings;
  }

  isPresetSelected(presetUrl: string): boolean {
    if (presetUrl === this.settings.baseUrl) return true;
    // eHealth: match by domain so tenantId changes don't break selection
    if (presetUrl.includes('hapi.fhir-testserver.be') && this.isEHealthServer) return true;
    // Google: match any healthcare.googleapis.com URL against the google sentinel preset
    if (presetUrl === 'https://healthcare.googleapis.com' && this.isGoogleServer) return true;
    return false;
  }

  get isEHealthServer(): boolean {
    return this.settings.baseUrl?.includes('hapi.fhir-testserver.be') ?? false;
  }

  get isGoogleServer(): boolean {
    return this.settings.baseUrl?.startsWith('https://healthcare.googleapis.com') ?? false;
  }

  get tenantId(): string {
    const match = this.settings.baseUrl?.match(/hapi\.fhir-testserver\.be\/fhir\/([^/?]+)/);
    return match ? match[1] : '';
  }

  updateTenantId(tenantId: string): void {
    this.updateSettings({ baseUrl: `https://hapi.fhir-testserver.be/fhir/${tenantId}` });
  }

  get availableServers(): FhirServerPreset[] {
    return this.env.fhir?.servers ?? [];
  }

  selectPreset(event: Event): void {
    const url = (event.target as HTMLSelectElement).value;
    if (url) this.updateSettings({ baseUrl: url });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.focus$.complete();
    this.click$.complete();
    if (this.noResultsTimeoutId !== null) clearTimeout(this.noResultsTimeoutId);
  }
}
