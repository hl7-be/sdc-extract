import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';

import { BehaviorSubject, Observable, of, forkJoin } from 'rxjs';
import { tap, map } from 'rxjs/operators';

import { ToastrService } from '../../shared/toastr/toastr.service';
import { SettingsState } from './settings.state';

export interface DatasetItem {
  id: string;
  title: string;
  mappingtag: string;
}

export interface SnomedItem {
  system: string;
  id: string;
  display: string;
}

export const BASE_URL = 'http://localhost:8000/api/v1';

@Injectable({ providedIn: 'root' })
export class FhirQuestionnaireMapperService {
  private datasetsSubject = new BehaviorSubject<DatasetItem[]>([]);
  datasets$ = this.datasetsSubject.asObservable();

  private fhirElementsCache = new Map<string, string[]>();

  get datasets(): DatasetItem[] {
    return this.datasetsSubject.value;
  }

  constructor(
    private http: HttpClient,
    private settingsState: SettingsState,
    private toastrService: ToastrService
  ) {}

  private get headers(): HttpHeaders {
    const settings = this.settingsState.settings;
    return new HttpHeaders({
      'X-FHIR-Base-URL': settings.baseUrl,
      'X-FHIR-API-Key': settings.apiKey ?? '',
    });
  }

  loadQuestionnaires(): Observable<DatasetItem[]> {
    return this.http.get<DatasetItem[]>(`${BASE_URL}/list_questionnaires`, { headers: this.headers });
  }

  setDatasets(datasets: DatasetItem[]): void {
    this.datasetsSubject.next(datasets);
  }

  getSnomedCode(value: string): Observable<SnomedItem[]> {
    return this.http.get<SnomedItem[]>(
      `${BASE_URL}/search_snomed_concept?query=${encodeURIComponent(value)}`,
      { headers: this.headers }
    );
  }

  updateQuestionnaireAndStatus(questionnaire: any, status: string): Observable<any> {
    return this.http.put(`${BASE_URL}/questionnaire/status/${encodeURIComponent(status)}`, questionnaire, {
      headers: this.headers,
    });
  }

  getFhirElements(resourceType: string): Observable<string[]> {
    const cached = this.fhirElementsCache.get(resourceType);
    if (cached) return of(cached);
    return this.http
      .get<string[]>(`${BASE_URL}/fhir-elements?resourceType=${encodeURIComponent(resourceType)}`, {
        headers: this.headers,
      })
      .pipe(tap((elements) => this.fhirElementsCache.set(resourceType, elements)));
  }

  prefetchAllFhirElements(resourceTypes: string[]): Observable<string[][]> {
    const uncached = resourceTypes.filter((t) => !this.fhirElementsCache.has(t));
    if (uncached.length === 0) {
      return of(resourceTypes.map((t) => this.fhirElementsCache.get(t) ?? []));
    }
    return forkJoin(uncached.map((t) => this.getFhirElements(t))).pipe(
      map(() => resourceTypes.map((t) => this.fhirElementsCache.get(t) ?? []))
    );
  }

  getQuestionnaire(q_id: string): Observable<any> {
    return this.http.get(`${BASE_URL}/questionnaire/${encodeURIComponent(q_id)}`, { headers: this.headers });
  }

  getQuestionnaireResponse(q_id: string): Observable<any> {
    return this.http.get(`${BASE_URL}/questionnaire/${encodeURIComponent(q_id)}/response`, {
      headers: this.headers,
    });
  }

  extractQuestionnaireResponseFromBody(
    questionnaire: any,
    qr: any,
    persist: boolean
  ): Observable<{ bundle: any; errors: string[] }> {
    return this.http.post<{ bundle: any; errors: string[] }>(
      `${BASE_URL}/questionnaire-response/extract?persist=${persist}`,
      { questionnaire, questionnaireResponse: qr },
      { headers: this.headers }
    );
  }

  getExampleResponse(qId: string): Observable<any> {
    return this.http.get<any>(`${BASE_URL}/questionnaire/${encodeURIComponent(qId)}/example-response`, {
      headers: this.headers,
    });
  }
}
