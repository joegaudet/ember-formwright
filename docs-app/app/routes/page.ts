import Route from '@ember/routing/route'
import { service } from '@ember/service'
import { handlePotentialIndexVisit } from 'kolay'
import type RouterService from '@ember/routing/router-service'
import type Transition from '@ember/routing/transition'

/** Pages that moved, old path → new. Published READMEs link to the old paths. */
const MOVED: Record<string, string> = {
  'going-further/translation.md': '/internationalization/translation.md',
}

export default class PageRoute extends Route {
  @service declare router: RouterService

  beforeModel(transition: Transition) {
    const page = transition.to?.find(route => route.name === 'page')?.params?.['page']
    const to = MOVED[String(page)]
    if (to) return this.router.replaceWith(to)
    handlePotentialIndexVisit(this, transition)
  }
}
