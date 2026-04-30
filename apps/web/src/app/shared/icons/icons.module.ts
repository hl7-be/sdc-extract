import { NgModule } from '@angular/core';
import { FontAwesomeModule, FaIconLibrary } from '@fortawesome/angular-fontawesome';
import {
  faMagnifyingGlass,
  faGear,
  faFileLines,
  faChevronRight,
  faCircleInfo,
  faArrowLeft,
} from '@fortawesome/free-solid-svg-icons';
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';

function alias(icon: IconDefinition, name: string): IconDefinition {
  return { ...icon, iconName: name as any };
}

@NgModule({
  imports: [FontAwesomeModule],
  exports: [FontAwesomeModule],
})
export class IconsModule {
  constructor(library: FaIconLibrary) {
    library.addIcons(
      alias(faMagnifyingGlass, 'search'),
      alias(faGear, 'cog'),
      alias(faFileLines, 'file-alt'),
      faChevronRight,
      alias(faCircleInfo, 'info-circle'),
      faArrowLeft
    );
  }
}
