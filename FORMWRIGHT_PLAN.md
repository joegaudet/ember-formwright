# Formwright — modernization plan for ember-foxy-forms

Status: implemented 2026-10-14 (phases 0–7; phase 8 is ready but not published).

Deviations from the plan, and why:
- Phases 1–4 landed as one rewrite, not a behaviour-preserving port first: the new API breaks
  every component anyway, so porting the old suite to Ember 7 first would have been thrown away.
  The old tests were used as the spec for the new ones.
- Ember versions: latest is 7.3, previous LTS is 6.12. CI tests both.
- The classic-build example runs on the workspace's Ember (7.3). In the monorepo a different
  version only for one app loads two copies of Ember; the 6.12 job overrides it workspace-wide.
- `@ember-formwright/real-enums` reads real-enums duck-typed: real-enums 2 isn't on npm yet (1.1.0 ships
  no JavaScript), so it's an optional peer.
- Dropped and documented in MIGRATION.md rather than ported: composite fields, the form-for
  service (notifications, navigation guard, class config), the destroy button, submit queueing.

## Decisions (from intake)

| Area | Decision |
|---|---|
| Name | **Formwright** |
| npm | Scoped family: `@ember-formwright/ember`, `@ember-formwright/warp-drive`, `@ember-formwright/real-enums`, `@ember-formwright/maskito`, `@ember-formwright/test-support` |
| Repo | Move to `joegaudet/formwright`, **keep git history** |
| Old package | `ember-foxy-forms` left untouched (no deprecate, no shim) |
| Ember | Latest stable + previous LTS |
| Format | v2 addon (`@embroider/addon-dev` + rollup) |
| Types | Full TypeScript + Glint, strict |
| Templates | `.gts` template-tag |
| API | New major version, with a migration guide (no codemod) |
| Naming | Short names (`<Form>`, `<f.Field>`), **named args only**: no positional params (they're removed in strict mode) |
| Data layer | Agnostic core (tracked POJOs) + optional adapter packages, the same way real-enums is set up |
| Validation | Pluggable validator interface (Standard Schema: zod/valibot/etc.) |
| Popovers | Native Popover API + CSS anchor positioning; `ember-attacher` dropped |
| Masks | `Intl.NumberFormat` in core; masking via optional `@ember-formwright/maskito` |
| Dep purge | Drop composable-helpers, event-helpers, element-helper, render-modifiers, macro-decorators, prop-types, ember-arg-types |
| Styling | Unstyled with stable class/`data-*` hooks + optional CSS-variables theme |
| PM / layout | pnpm, mirror real-enums (`packages/`, `examples/`, `docs/site/`, `scripts/`) |
| Tests | ember-qunit on a Vite test-app; ember-a11y-testing (WCAG 2.2 AA) |
| Release | Changesets + GitHub Actions (copy real-enums `release.yml` / `ci.yml`) |
| Node | `>=22.12` |
| Consumers | Vite/Embroider **and** classic ember-cli apps, both covered in CI |
| Old docs | Delete `ember-cli-addon-docs` dummy app; replaced by site + examples |
| Site | Hand-written HTML in `docs/site/` (like real-enums) + one embedded live Ember demo |
| Hosting | GitHub Pages at `joegaudet.github.io/formwright`, no custom domain |
| Brand | Sibling of real-enums: same layout and type system, own accent and logo |
| real-enums | Use the adapter (`@ember-formwright/real-enums`) and cross-link the sites |
| **New scope** | **Form harness system** (see Phase 6) |
| Sequencing | Phased PRs |

## Target layout

```
formwright/
  packages/
    ember/           @ember-formwright/ember          v2 addon: Form, Field, controls, validator contract
    test-support/    @ember-formwright/test-support   form harnesses + normalized selectors
    warp-drive/      @ember-formwright/warp-drive     WarpDrive / ember-data model adapter
    real-enums/      @ember-formwright/real-enums     enum-backed Select/Radio options
    maskito/         @ember-formwright/maskito        optional masked inputs
  test-app/          Vite Ember app, ember-qunit (+ classic-build smoke app in CI)
  examples/          ember-vite-basic, ember-warp-drive, ember-real-enums, ember-classic
  docs/site/         hand-written marketing page + built demo under docs/site/demo/
  scripts/           publish.mjs etc. (from real-enums)
  .changeset/  .github/workflows/{ci,release,pages}.yml
```

## Phases (one PR each, master stays green throughout)

### Phase 0 — Repo move and rename
- Transfer/push to `joegaudet/formwright` with history; `master` → `main` to match real-enums.
- Check that `@ember-formwright` is free on npm and claim the org first. **Blocker if taken.**
- README/LICENSE/CONTRIBUTING renamed; CLAUDE.md with "keep the website in sync" rule copied from real-enums.

### Phase 1 — Monorepo and tooling skeleton
- pnpm workspace, Node ≥22.12, flat ESLint 10 + typescript-eslint, Prettier 3, `tsconfig.base.json`.
- `packages/ember` from the v2 addon blueprint; `test-app` from the Vite app blueprint.
- Move existing source **unchanged** into `packages/ember/src` and get the old QUnit suite running in `test-app`. That suite becomes the safety net for later phases.
- CI: lint, typecheck, test against the ember-try scenarios (latest stable + previous LTS) plus a classic-build smoke app.
- Changesets wired; `release.yml` + `bootstrap-publish.yml` adapted from real-enums.

### Phase 2 — TS + `.gts` port (behaviour-preserving)
- Convert every component in `addon/components/**` (FormFor, FieldFor, LabelFor, FormButton, Form, CommitButtons, ErrorsFor, ~22 `ff-*` controls, `abstract-select`) and the `form-for` service to `.gts` with Glint signatures.
- `@arg(...)` decorators → TS signature types. The suite stays green with no changes to the tests.

### Phase 3 — Dependency purge
- ember-attacher → native `popover` + `anchor-name`/`position-anchor` (with a non-anchor fallback position for browsers without anchor support).
- ember-inputmask / currency → `Intl.NumberFormat` parse/format.
- render-modifiers → `ember-modifier`; composable/event/element helpers → built-ins (`fn`, `on`, `array`, `hash`, `element`); macro-decorators → getters; drop prop-types, is-plain-object, webpack.
- Remove `ember-cli-addon-docs`, deploy-git, uglify, etc.
- Each removal gets a test first wherever behaviour could change (popover placement, currency round-trip).

### Phase 4 — New public API (the breaking major)
Illustrative shape, to finalize in the PR:
```gts
<Form @model={{this.user}} @validator={{userSchema}} @onSubmit={{this.save}} as |f|>
  <f.Field @for="email" @control="email" @label="Email" />
  <f.Field @for="role" @control="select" @options={{Role.values}} />
  <f.Submit />
</Form>
```
- Named args only. The `@for` path replaces the old positional property name.
- Model contract: a plain object with tracked props. The core writes through a small `FormwrightModelAdapter` interface (get/set/rollback/save/errors).
- Validator contract: Standard Schema `~standard.validate`, async-safe, mapped to per-field errors.
- a11y: label `for`/`id`, `aria-invalid`, `aria-describedby` → error/hint ids, focus first invalid field on submit, and axe checks in every integration test.
- Theme: `@ember-formwright/ember/theme.css` with `--fw-*` custom properties.
- `MIGRATION.md`: an old → new table for every component and arg.

### Phase 5 — Adapter packages
- `@ember-formwright/warp-drive`: adapter for WarpDrive/ember-data records (dirty tracking, rollback, server errors → field errors).
- `@ember-formwright/real-enums`: enum → `@options` for Select/Radio/CheckboxSelect, labels from the enum.
- `@ember-formwright/maskito`: a `control="masked"` registration.
- Each package gets an example app in `examples/` that runs in CI (`test:examples`, like real-enums).

### Phase 6 — Form harness system (`@ember-formwright/test-support`)
- **Normalized selectors**, emitted by every control and documented as public API:
  `data-test-fw-form="<name>"`, `data-test-fw-field="<path>"`, `data-test-fw-control="<type>"`, `data-test-fw-label`, `data-test-fw-error`, `data-test-fw-hint`, `data-test-fw-submit`, `data-test-fw-cancel`.
  Paths normalized (`user.address.city`), so nested/child forms get stable, collision-free selectors.
- **Harnesses are classes** (page-object style, async, work in any `@ember/test-helpers` test).
  A form is a `FormHarness` subclass; decorators declare its fields and nested forms, and each
  child harness is created once (on first use) and cached, while its DOM lookup stays live:
  ```ts
  class SignupForm extends FormHarness {
    static formName = 'signup'
    @field(InputHarness) declare email: InputHarness
    @field(SelectHarness, 'role') declare role: SelectHarness
    @form(AddressForm) declare address: AddressForm
  }
  const signup = new SignupForm()
  await signup.email.fillIn('a@b.co')
  await signup.role.select('admin')
  await signup.submit()
  assert.deepEqual(signup.email.errors, ['…'])
  ```
  Each control type has a harness class (`InputHarness`, `NumberHarness`, `CurrencyHarness`,
  `SelectHarness`, `RadioHarness`, `CheckboxHarness`, `CheckboxGroupHarness`) that checks it is
  pointed at that control. Custom controls subclass `FieldHarness`. The decorators work with
  both legacy (`declare`) and standard (`accessor`) decorators.
- The library's own test suite is rewritten onto the harnesses, which is how the harnesses get tested.

### Phase 7 — Marketing site + live demo
- `docs/site/index.html` + `site.css`, built as a sibling of real-enums' page: hero, feature grid, code snippets for Form/Field/validator/adapters/harness, install block, migration link, and Open Graph/social card (copy real-enums' `social-card.html` approach).
- Own accent color + Formwright logo/favicon (SVG).
- Live demo: a small Vite Ember app in `examples/site-demo` built into `docs/site/demo/` and embedded as an iframe. `pages.yml` builds the demo, then uploads `docs/site`.
- Cross-link with real-enums both ways.
- Add the CONTRIBUTING "website" checklist + PR template box.

### Phase 8 — 1.0 release
- Changesets major → publish all `@ember-formwright/*` packages; GitHub release notes link MIGRATION.md.
- `ember-foxy-forms` stays as it is (per decision).

### Phase 9 — Usage documentation with styled, live examples (done)

**Why.** ember-foxy-forms had six docs pages (Introduction, Usage, Forms, Fields, Controls,
Advanced; about 1,060 lines in `tests/dummy/app/templates/docs/` on `master`) rendered by
ember-cli-addon-docs. They were dropped with the dummy app. Formwright's docs today are one
README example with argument tables, one static site snippet and the demo: the control surface
isn't enumerated, extending controls is one paragraph, and nothing shows rendered output next to
the code that made it.

**Mounted with Kolay.** The guide is a separate Vite Ember app, `docs-app/` (private workspace
package), built with [Kolay](https://github.com/universal-ember/kolay) 5.4: markdown pages,
`<APIDocs>` rendered from the packages' TypeScript declarations by TypeDoc, and Shiki
highlighting. It's built into `docs/site/guide/` → `joegaudet.com/formwright/guide/`, next to the
marketing page and the demo. (A separate app, not `test-app`, because Kolay's routes own the
app root.)

**One source per example.** Each example is a `.gts` file in `docs-app/app/examples/`. A guide
page renders it with `<Example @name="…" />`, the styled frame that shows the live preview, the
example's exact source and its harness test (both imported with Vite `?raw`). The same file is
imported by `docs-app/tests/examples/<name>-test.gts`, which drives it with a harness class and
runs axe. Docs can't drift from code that is tested.

**The example frame (what "well styled" means here)**
- **Preview:** a card in the site's style (Inter, indigo/coral). It has a theme-preset switcher
  (default, compact, rounded, brand), and the presets are only `--fw-*` overrides. A live model
  panel shows the JSON each control writes.
- **Template** and **Test** tabs: the source, highlighted with Shiki, with a copy button.
- **Fit:** works at 375px and 1440px, in light and dark.

**Pages: the original six, ported and rewritten for the new API, plus what's new**

| Guide page | From foxy-forms | Covers |
| --- | --- | --- |
| Introduction | index.md | What Formwright is; install; a first form; how it relates to ember-foxy-forms |
| Usage | usage.md | Models (POJO, `@tracked` class), submit, reset, state, `f.Errors` |
| Forms | forms.md | Every Form argument and lifecycle hook, disabled/readonly, auto-submit, inline editing, confirm mode; how to do notifications, navigation guards and class config now |
| Fields | fields.md | Labels, hints, placeholders, required, values and options, `@format`, the block form (`field.Control`), callouts |
| Controls | controls.md | Every built-in control with its arguments and a live example each; the `ControlSignature` contract |
| Custom controls | controls.md ("Custom Controls") | Writing a control, `registerControl`, its harness subclass; ports of the old walkthroughs (price range, rating, JSON editor) |
| Validation | (new) | Standard Schema (zod, valibot), function validators, form-level errors, async validation |
| Nested forms | advanced.md | Child forms, legends, per-form validators, save order (the product-onboarding example) |
| Data layers | (new) | `ModelAdapter`, WarpDrive / ember-data, real-enums, Maskito |
| Theming | forms.md (BEM / grid) | `--fw-*` properties, presets, going unstyled with `.fw-*` and `data-*` |
| Testing | forms.md (testing selectors) | Harness classes, decorators, custom harnesses, the selector reference |
| API reference | (new) | `<APIDocs>` for `Form`, `Field`, `ControlSignature`, `ModelAdapter`, `FormState`, the harness classes |

**Wiring the rest of the docs to the guide**
- **README:** keeps install, one example, and links into the guide.
- **Marketing site:** its nav and Usage section link into the guide.
- **`pages.yml`:** builds the demo and the guide, then deploys `docs/site`.
- **CI:** runs the docs-app suite, which covers every example.

**Notes from building it**
- Kolay 5.4 needed three workarounds: a pnpm patch giving `ember-repl` an `addon-main.cjs` (the
  classic-compat build requires one), a workspace override unifying `@glint/template`, and
  `keepNames` in the production build (TypeDoc's renderer looks up classes by name).
- Callouts are plain `<div class="callout">` blocks: markdown inside a component tag doesn't
  survive Kolay's markdown step.
- `@ember-formwright/test-support` is one TypeDoc module, which `<APIDocs>` can't address; its API
  lives in the Testing page's tables.
- The guide uses real URLs. GitHub Pages serves deep links through `docs/site/404.html`, a copy
  of the guide's `index.html` written by the build.

**Acceptance criteria**
- Every page of the original six has a counterpart, and every feature they described is either
  documented or listed in `MIGRATION.md` as removed.
- Every example renders live in the guide, shows its exact source and test, and has a passing
  harness test with an axe audit.
- Every built-in control has its own example and argument list.
- The guide works at 375px in light and dark, and is deployed at `/formwright/guide/`.

## Risks / open items
- `@ember-formwright` npm scope availability: not checked yet. It blocks Phase 0.
- CSS anchor positioning support is still uneven across browsers, so a fallback is required (see Phase 3).
- The classic ember-cli consumer path for a `.gts` v2 addon needs ember-auto-import ≥2 in that app; the classic smoke test in CI proves it.
- The existing tests depend on the dummy app's ember-data 3.22 and faker. Port the fixtures to tracked POJOs in Phase 1 or 2.
