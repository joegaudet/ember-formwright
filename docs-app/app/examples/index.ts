import type { ComponentLike } from '@glint/template'

/** What every example module exports. */
export interface ExampleModule {
  default: ComponentLike<{ Args: { model: any } }>
  /** A fresh model for each render (and each test). */
  createModel: () => object
}

const modules = import.meta.glob<ExampleModule>('./*.gts', { eager: true })
const sources = import.meta.glob<string>('./*.gts', {
  eager: true,
  query: '?raw',
  import: 'default',
})
const tests = import.meta.glob<string>('../../tests/examples/*-test.gts', {
  eager: true,
  query: '?raw',
  import: 'default',
})

export interface Example {
  name: string
  module: ExampleModule
  source: string
  test: string | undefined
}

export function example(name: string): Example {
  const module = modules[`./${name}.gts`]
  if (!module) throw new Error(`No example named "${name}" in docs-app/app/examples`)
  return {
    name,
    module,
    source: sources[`./${name}.gts`]!,
    test: tests[`../../tests/examples/${name}-test.gts`],
  }
}

export function exampleNames(): string[] {
  return Object.keys(modules).map(path => path.slice(2, -4))
}
