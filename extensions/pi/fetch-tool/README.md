# Fetch Tool Extension for Pi Coding Agent

## Overview

A production-quality URL fetching tool that implements the best-practice three-stage pipeline for converting web pages to Markdown, as documented in [docs/typescript-fetch-research.md](../../../docs/typescript-fetch-research.md).

```
[Fetch HTML]  →  [Extract Main Content]  →  [Convert HTML → Markdown]
(fetch+retry)    (@mozilla/readability)       (node-html-markdown)
```

## Features

- ✅ **Retry with exponential back-off** — automatically retries on network errors, 429 (rate-limit), and 5xx responses; respects `Retry-After` header
- ✅ **Per-request timeout** — `AbortController`-based, never hangs indefinitely  
- ✅ **Content extraction via `@mozilla/readability`** — same algorithm as Firefox Reader View; strips navbars, ads, footers, and cookie banners
- ✅ **CSS selector fallback** — when Readability returns too little text, tries `article`, `main`, `[role='main']`, etc.
- ✅ **Fast HTML→Markdown via `node-html-markdown`** — singleton instance (JIT-warmed); 1.57× faster than turndown
- ✅ **Absolute URL resolution** — relative `href`/`src` attributes are absolutified before conversion so links remain clickable
- ✅ **Charset-aware decoding** — detects charset from `Content-Type` header; correctly decodes non-UTF-8 pages with `TextDecoder`
- ✅ **Honest `User-Agent`** — always identifies the bot; never spoofs a real browser string
- ✅ **llms.txt discovery** — checks `.well-known/llmstxt` for a machine-readable plain-text version of the page (skips if the response is HTML)
- ✅ **JSON pretty-printing** and plain text / RSS / Atom passthrough
- ✅ **Binary file detection** (PDF, DOCX, images, archives, …)
- ✅ **50 KB byte-accurate truncation** with binary search to find the UTF-8 boundary

## Installation

```bash
# Copy to the pi-coding-agent extensions directory
cp -r fetch-tool ~/.pi/agent/extensions/

# Install npm dependencies
cd ~/.pi/agent/extensions/fetch-tool
npm install
```

Or run the provided install script (you will still need `npm install` afterward):

```bash
bash extensions/pi/fetch-tool/install.sh
cd ~/.pi/agent/extensions/fetch-tool && npm install
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `@mozilla/readability` | Article extraction (Firefox Reader View algorithm) |
| `jsdom` | DOM parsing in Node.js (required by Readability) |
| `node-html-markdown` | Fast HTML → Markdown conversion |

## Usage

### Basic Fetch

```typescript
// Fetch a JSON endpoint
fetch("https://jsonplaceholder.typicode.com/posts/1")

// Fetch an HTML page — aggressive pipeline by default
//   1. Retry-backed fetch
//   2. Readability extraction (strips navbars/ads/footers)
//   3. node-html-markdown conversion with absolute links
fetch("https://example.com")

// Specify timeout (seconds)
fetch("https://slow-api.example.com", { timeout: 60 })

// Return raw HTML without any processing
fetch("https://example.com", { raw: true })

// Basic cleaning (scripts/styles removed, but no Readability)
fetch("https://example.com", { cleanLevel: "basic" })

// Pass HTML through as-is to the Markdown converter
fetch("https://example.com", { cleanLevel: "none" })
```

### Available Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `url` | string | URL to fetch (prepends `https://` if scheme omitted) | Required |
| `timeout` | number | Timeout per attempt in seconds | 20 |
| `raw` | boolean | Return raw HTML; skip all transforms and truncation | false |
| `cleanLevel` | `"none"` \| `"basic"` \| `"aggressive"` | HTML cleaning/extraction aggressiveness. Ignored when `raw: true`. | `"aggressive"` |

### Cleaning Levels Explained

| Level | What happens |
|-------|-------------|
| **`aggressive`** (default) | Pre-strips scripts/styles/nav/footer/ads from DOM → Readability extracts article body → node-html-markdown converts → relative URLs absolutified |
| **`basic`** | Strips `<script>`, `<style>`, and inline `on*` event handlers only. No Readability. Structural elements (nav, footer, …) are preserved. |
| **`none`** | Converts raw HTML to Markdown as-is. No cleaning. Use when you need every element (e.g., debugging or structured data pages). |

## Response Format

```json
{
  "content": [
    {
      "type": "text",
      "text": "URL: https://example.com\nMethod: rendered-html-aggressive+readability\n\n# Page Title\n\n*Author Name*\n\nArticle content in Markdown…"
    }
  ],
  "details": {
    "url": "https://example.com",
    "method": "rendered-html-aggressive+readability",
    "contentType": "text/html; charset=utf-8",
    "bytes": 12345
  }
}
```

## Method Names

The `method` field in the response tells you exactly which path was taken:

| Method | Description |
|--------|-------------|
| `json` | Parsed and pretty-printed JSON |
| `text` | Plain text / RSS / Atom passthrough |
| `raw-html` | Unchanged HTML (`raw: true`) |
| `rendered-html-aggressive+readability` | Full pipeline: Readability extraction + NHM conversion |
| `rendered-html-aggressive` | Aggressive DOM cleaning, Readability failed (CSS selector fallback used) |
| `rendered-html-basic` | Scripts/styles stripped, no Readability |
| `rendered-html-none` | Raw HTML → NHM conversion only |
| `binary` | Binary file detected — returns download URL |

## Architecture

```
index.ts
  └─ execute()
       │
       ├─ llms.txt probe (quick, no retry)
       │
       ├─ fetchWithRetry()          ← utils/helpers.ts
       │    ├─ AbortController per attempt
       │    ├─ Exponential back-off + jitter
       │    └─ Retry-After header support
       │
       ├─ decodeResponseText()      ← charset detection via Content-Type
       │
       ├─ extractContent()          ← @mozilla/readability + jsdom
       │    ├─ Pre-strip bloat (script/style/nav/footer/…)
       │    ├─ Readability.parse()
       │    └─ CSS selector fallback
       │
       ├─ htmlToMarkdown()          ← node-html-markdown singleton
       │    ├─ Relative URL → absolute
       │    └─ NodeHtmlMarkdown.translate()
       │
       └─ truncateContent()         ← byte-accurate 50 KB limit
```

## Ethical Best Practices

This tool implements the responsible-scraping guidelines from the research report:

- **Honest `User-Agent`** — always `pi-fetch/1.0` with a contact link, never impersonates a browser
- **Automatic rate-limiting** — exponential back-off prevents hammering servers
- **`Retry-After` compliance** — respects server-specified back-off on 429 responses
- **No personal data stored** — the tool returns content inline; nothing is persisted

> ⚠️ You are responsible for checking `robots.txt` and Terms of Service before scraping a site at scale. This tool is designed for on-demand, single-page fetching, not bulk crawling.

## Testing

```bash
# Test JSON fetching
pi --test "fetch https://jsonplaceholder.typicode.com/posts/1"

# Test HTML rendering with Readability
pi --test "fetch https://example.com"

# Test a real article page
pi --test "fetch https://www.bbc.com/news"

# Test truncation (large page)
pi --test "fetch https://httpbin.org/html"

# Test binary detection
pi --test "fetch https://example.com/file.pdf"

# Test raw mode
pi --test 'fetch("https://example.com", { raw: true })'
```

## Directory Structure

```
fetch-tool/
├── index.ts              # Main extension entry point
├── package.json          # npm dependencies
├── install.sh            # Installation helper
├── test.sh               # Manual test runner
└── utils/
    └── helpers.ts        # Pipeline: extraction, conversion, retry, truncation
```

## Changelog

### v1.1.0 (2026-03-04)
- **New:** `@mozilla/readability` + `jsdom` content extraction (Firefox Reader View algorithm)
- **New:** `node-html-markdown` singleton for fast HTML→Markdown (replaces `pi-natives.htmlToMarkdown`)
- **New:** Retry with exponential back-off + jitter; respects `Retry-After`
- **New:** Charset-aware response decoding via `TextDecoder`
- **New:** Relative URL absolutification before Markdown conversion
- **New:** Byte-accurate truncation (binary search to UTF-8 boundary)
- **Improved:** Method name now includes `+readability` suffix when Readability succeeded
- **Improved:** Author (`byline`) prepended to output when detected

### v1.0.0
- Initial implementation: native `htmlToMarkdown`, regex-based HTML cleaning, single-attempt fetch

## License

MIT
