import { Component } from '@angular/core';

import { PageComponent } from '../../../shared/page/page.component';
import { LiveJsonComponent } from '../live-json/live-json.component';
import { QuestionsListComponent } from '../questions-list/questions-list.component';
import { ExtractionPanelComponent } from '../extraction-panel/extraction-panel.component';

@Component({
  selector: 'app-questionnaire-home',
  standalone: true,
  imports: [LiveJsonComponent, QuestionsListComponent, PageComponent, ExtractionPanelComponent],
  templateUrl: './questionnaire-home.component.html',
  styleUrl: './questionnaire-home.component.scss',
})
export class QuestionnaireHomeComponent {}
