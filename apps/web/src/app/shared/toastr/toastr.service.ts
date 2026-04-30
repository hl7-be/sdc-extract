import { Injectable } from '@angular/core';
import { ToastrService as NgxToastrService } from 'ngx-toastr';

@Injectable({ providedIn: 'root' })
export class ToastrService {
  constructor(private ngx: NgxToastrService) {}

  error(message?: string, _opts?: any): void {
    this.ngx.error(message || 'Er is een fout opgetreden', 'Fout', { timeOut: 6000, enableHtml: false });
  }

  errorErr(err: any, _opts?: any): void {
    const msg = err?.error?.message || err?.error || err?.message || String(err);
    this.error(msg);
  }

  success(message: string, _duration?: number): void {
    this.ngx.success(message, '', { timeOut: 5000 });
  }

  info(message: string, _duration?: number): void {
    this.ngx.info(message, '', { timeOut: 5000 });
  }

  warn(message: string, _duration?: number): void {
    this.ngx.warning(message, '', { timeOut: 5000 });
  }
}
