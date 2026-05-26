#!/usr/bin/env node
/**
 * Inserts a new <change> entry into repo.xml.tmpl based on conventional commits
 * since the previous release tag.
 *
 * Usage: node scripts/update-repo-changelog.js --version=X.Y.Z --prev-tag=X.Y.Z
 * Called by semantic-release via @semantic-release/exec prepareCmd.
 *
 * Adapted from eXist-db/semver.xq.
 */
import { execSync } from 'child_process'
import { readFileSync, writeFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { DOMParser, XMLSerializer } from '@xmldom/xmldom'
import { CommitParser } from 'conventional-commits-parser'
import { writeChangelogString } from 'conventional-changelog-writer'
import conventionalChangelogConventionalCommits from 'conventional-changelog-conventionalcommits'

const __dirname = dirname(fileURLToPath(import.meta.url))
const REPO_NS = 'http://exist-db.org/xquery/repo'
const HTML_NS = 'http://www.w3.org/1999/xhtml'

const SECTION_PREFIX = {
  Features: 'New',
  'Bug Fixes': 'Fix',
  'Performance Improvements': 'Improvement',
  Reverts: 'Revert'
}

const XML_MAIN_TEMPLATE =
  '{{#each noteGroups}}' +
  '{{#each notes}}' +
  '<li>Breaking change: {{text}}</li>\n' +
  '{{/each}}' +
  '{{/each}}' +
  '{{#each commitGroups}}' +
  '{{#each commits}}' +
  '{{#unless isBreaking}}<li>{{prefix}}: {{#if scope}}{{scope}}: {{/if}}{{subject}}</li>\n{{/unless}}' +
  '{{/each}}' +
  '{{/each}}'

function parseArgs () {
  return Object.fromEntries(
    process.argv.slice(2)
      .filter(a => a.startsWith('--') && a.includes('='))
      .map(a => {
        const eq = a.indexOf('=')
        return [a.slice(2, eq), a.slice(eq + 1)]
      })
  )
}

function tagExists (tag) {
  try {
    execSync(`git rev-parse "${tag}"`, { stdio: 'pipe' })
    return true
  } catch {
    return false
  }
}

function getRawCommits (prevTag) {
  const ref = tagExists(prevTag) ? prevTag
    : tagExists(`v${prevTag}`) ? `v${prevTag}`
      : null
  if (!ref) throw new Error(`Tag not found: ${prevTag} or v${prevTag}`)

  const hashes = execSync(`git log ${ref}..HEAD --format=%H`, { encoding: 'utf8' })
    .trim().split('\n').filter(Boolean)

  return hashes.map(hash =>
    execSync(`git log -1 --format=%B ${hash}`, { encoding: 'utf8' }).trim()
  )
}

async function buildChangeItems (rawCommits, version) {
  const { parser: parserOpts, writer: writerOpts } = await conventionalChangelogConventionalCommits()
  const commitParser = new CommitParser(parserOpts)

  const parsed = rawCommits.map(msg => commitParser.parse(msg)).filter(c => c.type)

  const presetTransform = writerOpts.transform
  const writerOptions = {
    ...writerOpts,
    mainTemplate: XML_MAIN_TEMPLATE,
    headerPartial: '',
    commitPartial: '',
    footerPartial: '',
    transform (commit, context) {
      const transformed = presetTransform(commit, context)
      if (!transformed) return null
      if (transformed.notes.length > 0) {
        transformed.isBreaking = true
        return transformed
      }
      transformed.prefix = SECTION_PREFIX[transformed.type] ?? transformed.type
      return transformed
    }
  }

  const output = await writeChangelogString(parsed, { version }, writerOptions)

  const doc = new DOMParser().parseFromString(
    `<ul xmlns="${HTML_NS}">${output}</ul>`,
    'text/xml'
  )
  const liNodes = doc.getElementsByTagNameNS(HTML_NS, 'li')
  const items = []
  for (let i = 0; i < liNodes.length; i++) {
    const text = liNodes.item(i).textContent
    if (text) items.push(text)
  }
  return items
}

function findChangeForVersion (changelog, version) {
  const changes = changelog.getElementsByTagNameNS(REPO_NS, 'change')
  for (let i = 0; i < changes.length; i++) {
    if (changes.item(i).getAttribute('version') === version) {
      return changes.item(i)
    }
  }
  return null
}

function mergeIntoExistingChange (doc, change, items) {
  const ul = change.getElementsByTagNameNS(HTML_NS, 'ul').item(0)
  if (!ul) throw new Error(`<change version="${change.getAttribute('version')}"> has no <ul>`)

  // Pull the existing <li> nodes out (preserving any inline markup like
  // <a href="...">#NNN</a>) so we can rebuild the <ul> in one pass with
  // consistent whitespace. New (generated) items are appended first; the
  // pre-existing (hand-authored) items keep their order after them.
  const existingLis = []
  const allLis = ul.getElementsByTagNameNS(HTML_NS, 'li')
  for (let i = 0; i < allLis.length; i++) {
    existingLis.push(allLis.item(i))
  }
  while (ul.firstChild) ul.removeChild(ul.firstChild)

  for (const item of items) {
    ul.appendChild(doc.createTextNode('\n                '))
    const li = doc.createElementNS(HTML_NS, 'li')
    li.textContent = item
    ul.appendChild(li)
  }
  for (const li of existingLis) {
    ul.appendChild(doc.createTextNode('\n                '))
    ul.appendChild(li)
  }
  ul.appendChild(doc.createTextNode('\n            '))
}

function insertChangeEntry (tmplPath, version, items) {
  const tmpl = readFileSync(tmplPath, 'utf8')
  const doc = new DOMParser().parseFromString(tmpl, 'text/xml')

  const changelog = doc.getElementsByTagNameNS(REPO_NS, 'changelog').item(0)
  if (!changelog) throw new Error('<changelog> not found in repo.xml.tmpl')

  // If a <change> for this version was already drafted by hand (to cover
  // commits that weren't authored in conventional-commits format and so
  // wouldn't be picked up by the commit-analyzer), prepend the generated
  // items into its <ul> instead of inserting a duplicate entry above it.
  const existing = findChangeForVersion(changelog, version)
  if (existing) {
    mergeIntoExistingChange(doc, existing, items)
    writeFileSync(tmplPath, new XMLSerializer().serializeToString(doc))
    console.log(`Merged ${items.length} item(s) into existing ${version} changelog entry`)
    return
  }

  const change = doc.createElementNS(REPO_NS, 'change')
  change.setAttribute('version', version)
  change.appendChild(doc.createTextNode('\n            '))

  const ul = doc.createElementNS(HTML_NS, 'ul')
  for (const item of items) {
    ul.appendChild(doc.createTextNode('\n                '))
    const li = doc.createElementNS(HTML_NS, 'li')
    li.textContent = item
    ul.appendChild(li)
  }
  ul.appendChild(doc.createTextNode('\n            '))

  change.appendChild(ul)
  change.appendChild(doc.createTextNode('\n        '))

  let firstChange = null
  for (let i = 0; i < changelog.childNodes.length; i++) {
    if (changelog.childNodes.item(i).nodeType === 1) {
      firstChange = changelog.childNodes.item(i)
      break
    }
  }

  changelog.insertBefore(change, firstChange)
  changelog.insertBefore(doc.createTextNode('\n        '), firstChange)

  writeFileSync(tmplPath, new XMLSerializer().serializeToString(doc))
  console.log(`Added ${version} changelog entry to repo.xml.tmpl`)
}

const { version, 'prev-tag': prevTag } = parseArgs()

if (!version || !prevTag) {
  console.error('Usage: update-repo-changelog.js --version=X.Y.Z --prev-tag=X.Y.Z')
  process.exit(1)
}

const rawCommits = getRawCommits(prevTag)
const items = await buildChangeItems(rawCommits, version)

if (items.length === 0) {
  console.log(`No notable commits since ${prevTag}, skipping changelog update`)
  process.exit(0)
}

const tmplPath = join(__dirname, '..', 'repo.xml.tmpl')
insertChangeEntry(tmplPath, version, items)
