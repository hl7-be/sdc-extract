import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { ToastrService } from '../../../shared/toastr/toastr.service';

@Injectable({ providedIn: 'root' })
export class DatasetState {
  private dataset$$ = new BehaviorSubject<string | null>(null);
  private savedMapping$$ = new BehaviorSubject<any | null>(null);

  constructor(private toastrService: ToastrService) {
    const saved = sessionStorage.getItem('selectedDataset');
    if (saved) {
      try {
        const item = JSON.parse(saved);
        if (item?.id) this.setDataset(item.id);
      } catch (e) {
        this.toastrService.error('Error parsing saved dataset: ' + (e as any)?.message);
      }
    }
  }

  get dataset(): Observable<string | null> {
    return this.dataset$$.asObservable();
  }

  get currentDatasetId(): string | null {
    return this.dataset$$.value;
  }

  get savedMapping(): Observable<any | null> {
    return this.savedMapping$$.asObservable();
  }

  get currentSavedMapping(): any | null {
    return this.savedMapping$$.value;
  }

  setDataset(dataset: string): void {
    this.dataset$$.next(dataset);
    this.savedMapping$$.next(null);
  }

  setSavedMapping(mapping: any): void {
    this.savedMapping$$.next(mapping);
  }
}
