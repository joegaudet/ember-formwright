# Formwright

Contributor guide: [CONTRIBUTING.md](CONTRIBUTING.md). Gates are in its "The gate" section; run
them, don't assume them.

## Keep the website in sync

The site at `docs/site/` is hand-written HTML, not generated. When a change touches anything it
shows (packages, controls, arguments, an API used in one of its snippets), update `docs/site/`
in the same PR. The live demo is `test-app/app`.
