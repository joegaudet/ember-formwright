import type { TOC } from '@ember/component/template-only'

interface ErrorsSignature {
  Element: HTMLDivElement
  Args: { errors: string[]; id?: string }
}

/** Always rendered, so screen readers announce errors as they appear. */
const Errors: TOC<ErrorsSignature> = <template>
  <div id={{@id}} class="fw-errors" aria-live="polite" data-test-fw-errors ...attributes>
    {{#if @errors.length}}
      <ul>
        {{#each @errors as |message|}}
          <li class="fw-error" data-test-fw-error>{{message}}</li>
        {{/each}}
      </ul>
    {{/if}}
  </div>
</template>

export default Errors
