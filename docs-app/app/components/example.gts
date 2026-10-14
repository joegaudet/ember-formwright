import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { htmlSafe } from '@ember/template'
import { waitForPromise } from '@ember/test-waiters'
import { example } from '../examples/index.ts'
import { highlight } from '../highlight.ts'
import { snapshot } from '../snapshot.ts'

type Tab = 'preview' | 'template' | 'test'
type Scheme = 'auto' | 'light' | 'dark'

const PRESETS = ['default', 'compact', 'rounded', 'brand'] as const
const SCHEMES: Scheme[] = ['auto', 'light', 'dark']

interface ExampleSignature {
  Element: HTMLElement
  Args: {
    /** The file name in docs-app/app/examples, without `.gts`. */
    name: string
    title?: string
    /** Hide the live model panel, e.g. for examples where it's noise. */
    noModel?: boolean
  }
}

/**
 * A live example: the rendered form on a themed card next to its model, plus tabs with the
 * example's exact source and the harness test that covers it.
 */
export class Example extends Component<ExampleSignature> {
  @tracked tab: Tab = 'preview'
  @tracked preset: (typeof PRESETS)[number] = 'default'
  @tracked scheme: Scheme = 'auto'
  @tracked sourceHtml = ''
  @tracked testHtml = ''
  @tracked copied = false

  example = example(this.args.name)
  model = this.example.module.createModel()
  presets = PRESETS
  schemes = SCHEMES

  constructor(owner: unknown, args: ExampleSignature['Args']) {
    super(owner as never, args)
    void waitForPromise(this.load())
  }

  async load() {
    const [source, test] = await Promise.all([
      highlight(this.example.source),
      this.example.test ? highlight(this.example.test) : Promise.resolve(''),
    ])
    if (this.isDestroying) return
    // Shiki output for files in this repository: trusted.
    this.sourceHtml = source
    this.testHtml = test
  }

  get Preview() {
    return this.example.module.default
  }

  get json() {
    return JSON.stringify(snapshot(this.model), null, 2)
  }

  get id() {
    return `example-${this.args.name}`
  }

  html = (markup: string) => htmlSafe(markup)
  isTab = (tab: Tab) => this.tab === tab
  select = (tab: Tab) => (this.tab = tab)
  setPreset = (event: Event) => (this.preset = (event.target as HTMLSelectElement).value as never)
  setScheme = (scheme: Scheme) => (this.scheme = scheme)
  schemeAttr = () => (this.scheme === 'auto' ? undefined : this.scheme)

  copy = async () => {
    const text = this.tab === 'test' ? (this.example.test ?? '') : this.example.source
    await navigator.clipboard?.writeText(text)
    this.copied = true
    setTimeout(() => (this.copied = false), 1500)
  }

  <template>
    <figure class="example" id={{this.id}} data-test-example={{@name}} ...attributes>
      <figcaption class="example-bar">
        <span class="example-title">{{if @title @title @name}}</span>
        <div class="example-tabs" role="tablist" aria-label="Example views">
          <button
            type="button"
            role="tab"
            aria-selected={{if (this.isTab "preview") "true" "false"}}
            aria-controls="{{this.id}}-panel"
            {{on "click" (fn this.select "preview")}}
          >Preview</button>
          <button
            type="button"
            role="tab"
            aria-selected={{if (this.isTab "template") "true" "false"}}
            aria-controls="{{this.id}}-panel"
            {{on "click" (fn this.select "template")}}
          >Template</button>
          {{#if this.example.test}}
            <button
              type="button"
              role="tab"
              aria-selected={{if (this.isTab "test") "true" "false"}}
              aria-controls="{{this.id}}-panel"
              {{on "click" (fn this.select "test")}}
            >Test</button>
          {{/if}}
        </div>
      </figcaption>

      <div id="{{this.id}}-panel" role="tabpanel" class="example-panel">
        {{#if (this.isTab "preview")}}
          <div class="example-tools">
            <label>
              Theme
              <select {{on "change" this.setPreset}}>
                {{#each this.presets as |preset|}}
                  <option
                    value={{preset}}
                    selected={{if (eqPreset preset this.preset) true false}}
                  >{{preset}}</option>
                {{/each}}
              </select>
            </label>
            <div class="example-scheme" role="group" aria-label="Colour scheme">
              {{#each this.schemes as |scheme|}}
                <button
                  type="button"
                  aria-pressed={{if (eqScheme scheme this.scheme) "true" "false"}}
                  {{on "click" (fn this.setScheme scheme)}}
                >{{scheme}}</button>
              {{/each}}
            </div>
          </div>
          <div class="example-stage">
            <div
              class="example-preview fw-preset-{{this.preset}}"
              data-fw-scheme={{this.schemeAttr}}
            >
              <this.Preview @model={{this.model}} />
            </div>
            {{#unless @noModel}}
              <div class="example-model">
                <span class="example-model-label">The model, live</span>
                <pre>{{this.json}}</pre>
              </div>
            {{/unless}}
          </div>
        {{else}}
          <div class="example-code">
            <button type="button" class="example-copy" {{on "click" this.copy}}>{{if
                this.copied
                "Copied ✓"
                "Copy"
              }}</button>
            {{#if (this.isTab "template")}}
              {{this.html this.sourceHtml}}
            {{else}}
              {{this.html this.testHtml}}
            {{/if}}
          </div>
        {{/if}}
      </div>
    </figure>
  </template>
}

function eqPreset(a: string, b: string) {
  return a === b
}

function eqScheme(a: Scheme, b: Scheme) {
  return a === b
}
