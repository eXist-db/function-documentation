# eXist-db Function Documentation Browser App

[![Build](https://github.com/eXist-db/function-documentation/actions/workflows/build.yml/badge.svg)](https://github.com/eXist-db/function-documentation/actions/workflows/build.yml)
[![eXist-db version](https://img.shields.io/badge/eXist_db-6.2.0-blue.svg)](http://www.exist-db.org/exist/apps/homepage/index.html)

<img src="src/main/xar-resources/icon.png" align="left" width="15%"/>

This repository contains the source code for the Function Documentation application for the [eXist-db native XML database](https://exist-db.org).

## Dependencies

- [Node.js](https://nodejs.org): LTS
- [eXist-db](https://exist-db.org): `6.2.0` or later

## Installation

- Function Documentation is installed by default in the eXist distribution. Just go to your eXist server's Dashboard and select Function Documentation.
- Update to the latest release via Dashboard > Package Manager, or download a release via the exist-db.org public app repository at [https://exist-db.org/exist/apps/public-repo/](https://exist-db.org/exist/apps/public-repo/).

## Building from source

1. Clone the repository to your system:

   ```bash
   git clone https://github.com/eXist-db/function-documentation.git
   cd function-documentation
   ```

2. Install dependencies and build the application package (`.xar` file):

   ```bash
   npm ci
   npm run build
   ```

   The package is written to `dist/exist-function-documentation-<version>.xar`. On a fresh clone, `<version>` will be the placeholder in `package.json` (the real version is set in-memory on the CI runner during the release pipeline).

3. Install the package via Dashboard > Package Manager.

For local development against a running eXist-db, use `npm run develop` (live-reload) and `npm run deploy` (install the built package into the configured eXist-db instance — set credentials in `.env`, see `.env.example`).

## Release Procedure

Releases are fully automated: every push to `master` triggers [semantic-release](https://semantic-release.gitbook.io/), which computes the next version from [Conventional Commits](https://www.conventionalcommits.org/) since the last tag, builds the package, and publishes a GitHub Release with the package attached at [https://github.com/eXist-db/function-documentation/releases](https://github.com/eXist-db/function-documentation/releases).

### What contributors need to do

- **Write [Conventional Commits](https://www.conventionalcommits.org/).** A `commitlint` + `husky` `commit-msg` hook enforces this locally (`@commitlint/config-conventional`). The commit type determines the version bump:
  - `feat:` → minor bump
  - `fix:`, `perf:` → patch bump
  - any commit with a `BREAKING CHANGE:` footer or a `!` after the type (e.g. `feat!:`) → major bump
  - `chore:`, `docs:`, `ci:`, `build:`, `style:`, `refactor:`, `test:` → no release (cosmetic / housekeeping)
- That's it. No version bump, no tag creation, no manual release commit.

### What release managers need to do

Pushes to `master` are released automatically. If the release pipeline fails (check the `Release` job in the [Actions tab](https://github.com/eXist-db/function-documentation/actions)) the commit history is still intact, and re-running the job is safe, since semantic-release is idempotent.

## License

LGPL v2.1 [exist-db.org](https://exist-db.org/exist/apps/homepage/index.html)
