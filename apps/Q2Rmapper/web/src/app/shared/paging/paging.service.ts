import { Injectable, OnDestroy } from '@angular/core';
import { BehaviorSubject, catchError, Observable, of, tap } from 'rxjs';
import { distinctUntilChanged, filter, map } from 'rxjs/operators';
import { PageEvent, PagingParams, PagingResult, PagingState } from './paging.models';

@Injectable({ providedIn: 'any' })
export class PagingService<T> implements OnDestroy {
  private readonly initialState: PagingState = Object.freeze({
    pagingParams: [null],
    initialPagingParams: null,
    pageSize: 10,
    currentPage: 0,
    currentPageSize: 0,
    totalSize: undefined,
  });
  private _stateSubj$: BehaviorSubject<Readonly<PagingState>> = new BehaviorSubject(this.initialState);
  private _loadingSubj$ = new BehaviorSubject(false);
  private _triggerLoadSubj$ = new BehaviorSubject(true);

  pageChanges$: Observable<PageEvent> = this._triggerLoadSubj$.pipe(
    filter((emit) => emit),
    map(() => {
      const state = this._stateSubj$.getValue();
      return {
        pagingParams: state.pagingParams.length > 0 ? state.pagingParams[state.currentPage] : null,
        pageSize: state.pageSize,
        pageNumber: state.currentPage,
      };
    })
  );

  paginatorChanges$ = this._stateSubj$.asObservable().pipe(
    map(({ pageSize, currentPage, currentPageSize, totalSize }) => ({
      pageSize,
      currentPage,
      currentPageSize,
      totalSize,
    })),
    distinctUntilChanged(
      (curr, prev) =>
        curr.pageSize === prev.pageSize &&
        curr.currentPage === prev.currentPage &&
        curr.currentPageSize === prev.currentPageSize &&
        curr.totalSize === prev.totalSize
    )
  );

  hasNext$ = this._stateSubj$.asObservable().pipe(map((state) => this.hasNextFromState(state)));

  loading$ = this._loadingSubj$.asObservable();

  init(pageSize: number, initPagingParams: PagingParams): void {
    this._stateSubj$.next({
      currentPage: 0,
      pagingParams: [initPagingParams],
      initialPagingParams: initPagingParams,
      pageSize,
      currentPageSize: 0,
      totalSize: undefined,
    });
  }

  toPage(page: number): void {
    const state = this._stateSubj$.getValue();
    this._stateSubj$.next({ ...state, currentPageSize: state.pageSize, currentPage: page });
    this._triggerLoadSubj$.next(true);
  }

  getCurrentPage(): number {
    return this._stateSubj$.getValue().currentPage;
  }

  getPage(request: (pagingParams: PagingParams) => Observable<PagingResult<T>>): Observable<T[]> {
    let state = this._stateSubj$.getValue();
    const pagingParam = state.pagingParams[state.currentPage];
    this._loadingSubj$.next(true);
    return request(pagingParam).pipe(
      tap((res) => {
        state = this._stateSubj$.getValue();
        if (res.totalSize && !state.totalSize) {
          state = { ...state, totalSize: res.totalSize };
        }
        if (res.data.length === 0 || res.data.length < state.pageSize) {
          this._loadingSubj$.next(false);
          return;
        }
        const pagingParams = [...state.pagingParams];
        pagingParams.splice(
          state.currentPage + 1,
          state.pagingParams.length - (state.currentPage + 1),
          res.nextPagingParams(res.data)
        );
        this._loadingSubj$.next(false);
        this._stateSubj$.next({ ...state, pagingParams, currentPageSize: res.data ? res.data.length : 0 });
      }),
      map((response) => response.data),
      catchError(() => {
        this._loadingSubj$.next(false);
        return of([]);
      })
    );
  }

  isLoading(): boolean {
    return this._loadingSubj$.getValue();
  }

  clear(reload: boolean, opts?: { newInitPagingParams?: PagingParams }): void {
    const state = this._stateSubj$.getValue();
    let newState = {
      ...state,
      currentPage: 0,
      currentPageSize: 0,
      totalSize: undefined,
      pagingParams: [state.initialPagingParams],
    };
    if (opts?.newInitPagingParams) {
      newState = { ...newState, pagingParams: [opts.newInitPagingParams] };
    }
    this._stateSubj$.next(newState);
    if (reload) this.reload();
  }

  reload(): void {
    this._triggerLoadSubj$.next(true);
  }

  prev(): void {
    if (!this.isLoading()) this.toPage(this.getCurrentPage() - 1);
  }

  next(): void {
    if (!this.isLoading()) this.toPage(this.getCurrentPage() + 1);
  }

  hasNext(): boolean {
    return this.hasNextFromState(this._stateSubj$.getValue());
  }

  private hasNextFromState(state: PagingState): boolean {
    return state.pagingParams.length > state.currentPage + 1 && state.pagingParams[state.currentPage + 1];
  }

  ngOnDestroy(): void {
    this._stateSubj$.complete();
    this._loadingSubj$.complete();
    this._triggerLoadSubj$.complete();
  }
}
