# Formwright — modernization plan for ember-foxy-forms

Status: implemented 2026-10-14 (phases 0–7; phase 8 is ready but not published).

Deviations from the plan, and why:
- Phases 1–4 landed as one rewrite, not a behaviour-preserving port first: the new API breaks
  every component anyway, so porting the old suite to Ember 7 first would have been thrown away.
  The old tests were used as the spec for the new ones.
- Ember versions: latest is 7.3, previous LTS is 6.12. CI tests both.
- The classic-build example runs on the workspace's Ember (7.3). In the monorepo a different
  version only for one app loads two copies of Ember; the 6.12 job overrides it workspace-wide.
- `@formwright/real-enums` reads real-enums duck-typed: real-enums 2 isn't on npm yet (1.1.0 ships
  no JavaScript), so it's an optional peer.
- Dropped and documented in MIGRATION.md rather than ported: composite fields, the form-for
  service (notifications, navigation guard, class config), the destroy button, submit queueing.

## Decisions (from intake)

| Area | Decision |
|---|---|
| Name | **Formwright** |
| npm | Scoped family: `@formwright/ember`, `@formwright/warp-drive`, `@formwright/real-enums`, `@formwright/maskito`, `@formwright/test-support` |
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
| Masks | `Intl.NumberFormat` in core; masking via optional `@formwright/maskito` |
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
| real-enums | Use the adapter (`@formwright/real-enums`) and cross-link the sites |
| **New scope** | **Form harness system** (see Phase 6) |
| Sequencing | Phased PRs |

## Target layout

```
formwright/
  packages/
    ember/           @formwright/ember          v2 addon: Form, Field, controls, validator contract
    test-support/    @formwright/test-support   form harnesses + normalized selectors
    warp-drive/      @formwright/warp-drive     WarpDrive / ember-data model adapter
    real-enums/      @formwright/real-enums     enum-backed Select/Radio options
    maskito/         @formwright/maskito        optional masked inputs
  test-app/          Vite Ember app, ember-qunit (+ classic-build smoke app in CI)
  examples/          ember-vite-basic, ember-warp-drive, ember-real-enums, ember-classic
  docs/site/         hand-written marketing page + built demo under docs/site/demo/
  scripts/           publish.mjs etc. (from real-enums)
  .changeset/  .github/workflows/{ci,release,pages}.yml
```

## Phases (one PR each, master stays green throughout)

### Phase 0 — Repo move and rename
- Transfer/push to `joegaudet/formwright` with history; `master` → `main` to match real-enums.
- Check that `@formwright` is free on npm and claim the org first. **Blocker if taken.**
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
- Theme: `@formwright/ember/theme.css` with `--fw-*` custom properties.
- `MIGRATION.md`: an old → new table for every component and arg.

### Phase 5 — Adapter packages
- `@formwright/warp-drive`: adapter for WarpDrive/ember-data records (dirty tracking, rollback, server errors → field errors).
- `@formwright/real-enums`: enum → `@options` for Select/Radio/CheckboxSelect, labels from the enum.
- `@formwright/maskito`: a `control="masked"` registration.
- Each package gets an example app in `examples/` that runs in CI (`test:examples`, like real-enums).

### Phase 6 — Form harness system (`@formwright/test-support`)
- **Normalized selectors**, emitted by every control and documented as public API:
  `data-test-fw-form="<name>"`, `data-test-fw-field="<path>"`, `data-test-fw-control="<type>"`, `data-test-fw-label`, `data-test-fw-error`, `data-test-fw-hint`, `data-test-fw-submit`, `data-test-fw-cancel`.
  Paths normalized (`user.address.city`), so nested/child forms get stable, collision-free selectors.
- **Harnesses** (page-object style, async, work in any `@ember/test-helpers` test):
  ```ts
  const form = formHarness('signup');
  await form.field('email').fillIn('a@b.co');
  await form.field('role').select(Role.ADMIN);
  await form.submit();
  assert.deepEqual(form.field('email').errors, ['…']);
  ```
  Each control type gets a harness (`fillIn`, `select`, `check`, `value`, `errors`, `isDisabled`, `isInvalid`), and they're extensible for custom controls.
- The library's own test suite is rewritten onto the harnesses, which is how the harnesses get tested.

### Phase 7 — Marketing site + live demo
- `docs/site/index.html` + `site.css`, built as a sibling of real-enums' page: hero, feature grid, code snippets for Form/Field/validator/adapters/harness, install block, migration link, and Open Graph/social card (copy real-enums' `social-card.html` approach).
- Own accent color + Formwright logo/favicon (SVG).
- Live demo: a small Vite Ember app in `examples/site-demo` built into `docs/site/demo/` and embedded as an iframe. `pages.yml` builds the demo, then uploads `docs/site`.
- Cross-link with real-enums both ways.
- Add the CONTRIBUTING "website" checklist + PR template box.

### Phase 8 — 1.0 release
- Changesets major → publish all `@formwright/*` packages; GitHub release notes link MIGRATION.md.
- `ember-foxy-forms` stays as it is (per decision).

## Risks / open items
- `@formwright` npm scope availability: not checked yet. It blocks Phase 0.
- CSS anchor positioning support is still uneven across browsers, so a fallback is required (see Phase 3).
- The classic ember-cli consumer path for a `.gts` v2 addon needs ember-auto-import ≥2 in that app; the classic smoke test in CI proves it.
- The existing tests depend on the dummy app's ember-data 3.22 and faker. Port the fixtures to tracked POJOs in Phase 1 or 2.
