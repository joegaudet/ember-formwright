# Formwright

Contributor guide: [CONTRIBUTING.md](CONTRIBUTING.md). Gates are in its "The gate" section; run
them, don't assume them.

## Keep the website in sync

The site at `docs/site/` is hand-written HTML, not generated. When a change touches anything it
shows (packages, controls, arguments, an API used in one of its snippets), update `docs/site/`
in the same PR. The live demo is `test-app/app`.

## Keep the guide in sync

The guide (`docs-app/`) documents every public argument, control and hook, each with a live,
tested example. A change to the public API updates its guide page and example in the same PR.
See "The guide" in CONTRIBUTING.md.
