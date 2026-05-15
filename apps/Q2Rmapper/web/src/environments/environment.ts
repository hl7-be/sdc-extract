export const environment = {
  production: false,
  // TODO: change this to your own SNOMED CT browser instance if needed
  snomedBrowserBaseUrl: 'https://snomedbrowser.uz.kuleuven.ac.be/?perspective=full&edition=MAIN/2026-03-01&release=&languages=en',
  fhir: {
    baseUrl: 'https://hapi.fhir-testserver.be/fhir/tenantID',
    servers: [
      {
        name: 'eHealth test server (Belgium)',
        url: 'https://hapi.fhir-testserver.be/fhir/tenantID',
      },
      {
        name: 'Google Cloud Healthcare API',
        url: 'https://healthcare.googleapis.com',
      },
      {
        name: 'HAPI FHIR (public)',
        url: 'https://hapi.fhir.org/baseR4',
      },
    ],
  },
};
