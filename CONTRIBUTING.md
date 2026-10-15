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
pnpm --filter docs-app test             # every guide example and page
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

## Releasing

A release is cut by pushing a tag. Nothing publishes on merge.

1. PRs that change a published package carry a changeset (`pnpm changeset`). While any are
   pending on `main`, CI keeps a "chore: version packages" PR open with the next version and
   the changelogs.
2. Merge that PR.
3. Tag the merge commit with the new version and push the tag:

   ```bash
   git switch main && git pull
   git tag -a v1.2.3 -m v1.2.3
   git push origin v1.2.3
   ```

`release.yml` checks that the tag is on `main` and matches every public package's version,
publishes whatever is not already on npm through `scripts/publish.mjs` (OIDC trusted publishing
with provenance; there is no `NPM_TOKEN`), then creates the GitHub release. If a run fails, re-run
it: it skips what is already published.

**A brand-new package** cannot publish through OIDC: npm only configures a trusted publisher for
a name that already exists. Its first release goes out once through `bootstrap-publish.yml` with
a short-lived token (restore that file from git history if it has been deleted; its header has
the steps). After that, set `joegaudet/ember-formwright` / `release.yml` as the package's trusted
publisher on npmjs.com.

The version PR is opened by a GitHub App, not `GITHUB_TOKEN`: GitHub runs no workflows for
pushes made with `GITHUB_TOKEN`, so the PR would never get its required checks. One App serves
every repository that uses this workflow. To set it up:

1. Create a GitHub App (Settings → Developer settings → GitHub Apps → New) with webhooks off and
   repository permissions **Contents: read and write** and **Pull requests: read and write**.
2. Install it on this repository.
3. Generate a private key, then in this repository (Settings → Secrets and variables → Actions)
   add the variable `RELEASE_APP_CLIENT_ID` (the App's client ID) and the secret
   `RELEASE_APP_PRIVATE_KEY` (the whole `.pem` file).

## The guide

`docs-app/` is the guide at `/ember-formwright/guide/`, built with [Kolay](https://github.com/universal-ember/kolay).
`pnpm guide:start` serves it locally.

- Pages are markdown in `docs-app/app/templates/<section>/<page>.md`; `meta.json` files set the
  order. Add a new page to `PAGES` in `docs-app/tests/acceptance/pages-test.ts`.
- Examples are `.gts` files in `docs-app/app/examples/`. Each exports a default component taking
  `@model`, and a `createModel()` function. Show one in a page with `<Example @name="…" />`.
- Every example has a test, `docs-app/tests/examples/<name>-test.gts`, written with harness
  classes and ending in an axe audit. The guide shows it in the example's Test tab, so write it
  as you'd want a reader to write theirs.
- Callouts are `<div class="callout">` blocks with a blank line inside, so markdown still works.

## The website

`docs/site/` is hand-written HTML, not generated; the live demo is `test-app/app`, built into
`docs/site/demo/` by `pnpm demo:build`. When a change touches anything the site shows
(packages, controls, arguments, an API used in a snippet), update `docs/site/` in the same PR.
`docs/social-card.html` is the source of `docs/site/social-card.png`.
