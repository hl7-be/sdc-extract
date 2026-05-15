import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'fhirquestionnairemapper', pathMatch: 'full' },
  {
    path: 'fhirquestionnairemapper',
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./fhir-questionnaire-mapper/components/shell/fhir-questionnaire-mapper.component').then(
            (m) => m.FhirQuestionnaireMapperComponent
          ),
      },
      {
        path: 'questionnaireeditor',
        loadComponent: () =>
          import(
            './fhir-questionnaire-mapper/components/questionnaire-home/questionnaire-home.component'
          ).then((m) => m.QuestionnaireHomeComponent),
      },
    ],
  },
];
