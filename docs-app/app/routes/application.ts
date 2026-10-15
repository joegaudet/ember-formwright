import Route from '@ember/routing/route'
import rehypeShikiFromHighlighter from '@shikijs/rehype/core'
import { setupKolay } from 'kolay/setup'
import type { Manifest } from 'kolay'
import { highlighter } from '../highlight.ts'
import { Example } from '../components/example.gts'
import { CommitFlow } from '../components/commit-flow.gts'

export default class ApplicationRoute extends Route {
  async model(): Promise<{ manifest: Manifest }> {
    const shiki = await highlighter()

    const manifest = await setupKolay(this, {
      // Usable in any page without an import.
      topLevelScope: { Example, CommitFlow },
      modules: {
        '@ember-formwright/ember': () => import('@ember-formwright/ember'),
        '@ember-formwright/test-support': () => import('@ember-formwright/test-support'),
      },
      rehypePlugins: [
        [
          rehypeShikiFromHighlighter,
          shiki,
          { themes: { light: 'github-light', dark: 'github-dark' }, defaultColor: 'light-dark()' },
        ],
      ],
    })

    return { manifest }
  }
}
