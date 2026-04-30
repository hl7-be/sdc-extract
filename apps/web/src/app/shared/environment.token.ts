import { InjectionToken } from '@angular/core';

export interface FhirServerPreset {
  name: string;
  url: string;
}

export interface EnvironmentVariables {
  production: boolean;
  snomedBrowserBaseUrl?: string;
  fhir?: {
    apiKey?: string;
    baseUrl?: string;
    servers?: FhirServerPreset[];
  };
}

export const EnvironmentVariablesService = new InjectionToken<EnvironmentVariables>('EnvironmentVariables');
