export const environment = {
  production: false,
  // Public SNOMED CT browser (IHTSDO). Replace with your own instance if needed.
  snomedBrowserBaseUrl: 'https://browser.ihtsdotools.org/?perspective=full&edition=MAIN&release=&languages=en',
  fhir: {
    baseUrl: 'https://hapi.fhir.org/baseR4',
    servers: [
      {
        name: 'HAPI FHIR (public)',
        url: 'https://hapi.fhir.org/baseR4',
      },
      {
        name: 'eHealth test server (Belgium)',
        url: 'https://hapi.fhir-testserver.be/fhir/tenantID',
      },
      {
        name: 'Google Cloud Healthcare API',
        url: 'https://healthcare.googleapis.com',
      },
    ],
  },
};
