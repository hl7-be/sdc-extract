export type PagingParams = any;

export interface PageEvent {
  pageSize: number;
  pageNumber: number;
  pagingParams?: PagingParams;
}

export interface PagingState {
  pageSize: number;
  currentPage: number;
  currentPageSize: number;
  totalSize: number | undefined;
  pagingParams: PagingParams[];
  initialPagingParams: PagingParams;
}

export interface PagingResult<T> {
  data: T[];
  totalSize?: number;
  nextPagingParams: (data: T[]) => PagingParams;
}
