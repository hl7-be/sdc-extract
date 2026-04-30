import { BehaviorSubject, Observable } from 'rxjs';
import { EnvironmentVariablesService, EnvironmentVariables } from '../../shared/environment.token';
import { Inject, Injectable } from '@angular/core';
import { ToastrService } from '../../shared/toastr/toastr.service';

export interface FhirSettings {
  baseUrl: string;
  apiKey?: string;
}

@Injectable({ providedIn: 'root' })
export class SettingsState {
  private settings$$: BehaviorSubject<FhirSettings>;

  constructor(
    private toastrService: ToastrService,
    @Inject(EnvironmentVariablesService) private env: EnvironmentVariables
  ) {
    this.settings$$ = new BehaviorSubject<FhirSettings>({
      baseUrl: this.env.fhir?.baseUrl ?? '',
    });

    const saved = sessionStorage.getItem('fhirSettings');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        if (parsed && typeof parsed === 'object' && typeof parsed.baseUrl === 'string') {
          this.settings$$.next(parsed as FhirSettings);
        }
      } catch (e) {
        this.toastrService.error('Error parsing saved fhir settings: ' + (e as any)?.message);
      }
    }
  }

  get settings$(): Observable<FhirSettings> {
    return this.settings$$.asObservable();
  }

  get settings(): FhirSettings {
    return this.settings$$.value;
  }

  updateSettings(settings: Partial<FhirSettings>): void {
    const newSettings = { ...this.settings$$.value, ...settings };
    this.settings$$.next(newSettings);
    sessionStorage.setItem('fhirSettings', JSON.stringify(newSettings));
  }
}
