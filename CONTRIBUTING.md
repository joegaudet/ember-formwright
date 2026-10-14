# Contributing

## Setup

```bash
pnpm install
pnpm build   # the test app and examples import the packages' built output
pnpm start   # the demo (test-app); Vite prints its URL
```

pnpm runs scripts on Node 24 (`useNodeVersion` in `pnpm-workspace.yaml`); ember-eslint-parser
fails on some Node 22 releases.

## The gate

CI runs exactly these; run them before opening a PR.

```bash
pnpm format:check
pnpm build
pnpm lint
pnpm typecheck
node --test scripts/*.test.mjs
pnpm test                               # test-app, Ember 7.3
pnpm --filter ember-classic test        # the classic ember-cli example
```

CI also runs the suite against the previous LTS (6.12) by overriding `ember-source` for the
whole workspace. To do that locally, add `ember-source: ~6.12.0` under `overrides:` in
`pnpm-workspace.yaml`, then run `pnpm install --no-frozen-lockfile && pnpm build && pnpm test`
(and revert both files afterwards). Overriding only the test app loads two copies of Ember.

## Tests first

Behaviour changes start with a failing test in `test-app/tests/`. Prefer the harness
(a `FormHarness` subclass with `@field` declarations; see `test-app/tests/helpers/test-form.ts`)
over raw selectors. A new control gets a `FieldHarness` subclass.

## Changesets

Every change to a published package needs a changeset (`pnpm changeset`). The packages version
together.

## The website

`docs/site/` is hand-written HTML, not generated; the live demo is `test-app/app`, built into
`docs/site/demo/` by `pnpm demo:build`. When a change touches anything the site shows
(packages, controls, arguments, an API used in a snippet), update `docs/site/` in the same PR.
`docs/social-card.html` is the source of `docs/site/social-card.png`.
