import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbPaginationModule } from '@ng-bootstrap/ng-bootstrap';
import { map, Observable, shareReplay, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { PagingService } from './paging.service';
import { I18nTranslatePipe } from '../i18n/translate.pipe';

@Component({
  selector: 'app-paging',
  standalone: true,
  imports: [CommonModule, NgbPaginationModule, I18nTranslatePipe],
  templateUrl: './paging.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PagingComponent<T> implements OnInit, OnDestroy {
  @Input() withPageNumbers = false;
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() pagingService!: PagingService<T>;

  page = 1;
  pageSize = 10;
  totalCollectionSize: number | undefined;
  currentPageSize = 0;

  prevDisabled$!: Observable<boolean>;
  nextDisabled$!: Observable<boolean>;

  private destroy$ = new Subject<void>();

  constructor(private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    const paginatorChanges$ = this.pagingService.paginatorChanges$.pipe(
      shareReplay(1),
      takeUntil(this.destroy$)
    );

    paginatorChanges$.subscribe((changes) => {
      this.page = changes.currentPage + 1;
      this.pageSize = changes.pageSize;
      this.totalCollectionSize = changes.totalSize;
      this.currentPageSize = changes.currentPageSize;
      this.cdr.markForCheck();
    });

    this.prevDisabled$ = paginatorChanges$.pipe(map(({ currentPage }) => currentPage === 0));
    this.nextDisabled$ = this.pagingService.hasNext$.pipe(map((hasNext) => !hasNext));
  }

  pageChange(page: number): void {
    if (!this.pagingService.isLoading()) this.pagingService.toPage(page - 1);
  }

  prev(): void {
    if (!this.pagingService.isLoading()) this.pagingService.prev();
  }

  next(): void {
    if (!this.pagingService.isLoading()) this.pagingService.next();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
