/**
 * Fetch Tool Helpers
 *
 * Utility functions for the fetch tool extension, implementing best practices from:
 * - @mozilla/readability for content extraction (same algorithm as Firefox Reader View)
 * - node-html-markdown for fast HTML→Markdown conversion (1.57× faster than turndown)
 * - Retry-with-exponential-backoff for resilient fetching
 * - Proper charset detection and URL absolutification
 */

import { JSDOM } from "jsdom";
import { Readability } from "@mozilla/readability";
import { NodeHtmlMarkdown } from "node-html-markdown";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/**
 * Cleaning levels for HTML content before markdown conversion.
 * - 'none': No cleaning, pass through as-is
 * - 'basic': Remove script/style tags and event handlers only
 * - 'aggressive': Remove scripts/styles + structural bloat (nav, footer, ads, etc.)
 *                 and run @mozilla/readability to extract the main article body
 */
export type CleanLevel = "none" | "basic" | "aggressive";

export interface ExtractedContent {
  title: string;
  html: string;          // Cleaned HTML ready for Markdown conversion
  textContent: string;   // Plain text (for length checks)
  excerpt: string;
  byline: string;        // Author if detected
  usedReadability: boolean;
}

// ---------------------------------------------------------------------------
// Singleton Markdown converter (reuse for JIT warm-up performance)
// ---------------------------------------------------------------------------

let _nhm: NodeHtmlMarkdown | null = null;

function getMarkdownConverter(): NodeHtmlMarkdown {
  if (!_nhm) {
    _nhm = new NodeHtmlMarkdown(
      {
        useInlineLinks: true,
        keepDataImages: false,
        // Prefer fenced code blocks and ATX-style headings
        codeBlockStyle: "fenced",
      },
      /* customTranslators */ undefined,
      /* customCodeBlockTranslators */ undefined,
    );
  }
  return _nhm;
}

// ---------------------------------------------------------------------------
// Content extraction
// ---------------------------------------------------------------------------

/**
 * AGGRESSIVE clean: strip obvious bloat elements from the DOM before scoring.
 * Readability handles most noise itself, but pre-removing these consistently
 * improves output quality without harming extraction accuracy.
 */
const PRE_CLEAN_SELECTORS = [
  "script", "style", "noscript", "iframe", "embed", "object", "applet",
  "nav", "footer", "header", "aside", "template",
  "[aria-hidden='true']",
  ".advertisement", ".ad", ".ads", ".sidebar", ".cookie-banner",
  ".modal", ".popup", ".overlay",
].join(", ");

/**
 * CSS selector fallback chain when Readability fails or returns too little text.
 * Tried in order — first match with ≥100 chars of text content wins.
 */
const FALLBACK_SELECTORS = [
  "article",
  "main",
  "[role='main']",
  ".post",
  ".post-content",
  ".article-body",
  ".entry-content",
  ".content",
  "#content",
  "body",
];

/**
 * Extract the main article content from raw HTML.
 *
 * Pipeline:
 *  1. Parse HTML with jsdom (passes `url` so relative URLs resolve correctly)
 *  2. Pre-strip known bloat elements from the DOM
 *  3. Run @mozilla/readability — same algorithm as Firefox Reader View
 *  4. If Readability returns nothing or < 100 chars, fall back to CSS selector heuristic
 *
 * @param url   - The page URL (used for relative→absolute link resolution)
 * @param html  - Raw HTML string from the fetch response
 * @param level - Cleaning aggressiveness
 */
export function extractContent(url: string, html: string, level: CleanLevel): ExtractedContent {
  if (level === "none") {
    return {
      title: "",
      html,
      textContent: html,
      excerpt: "",
      byline: "",
      usedReadability: false,
    };
  }

  // Parse with jsdom — passing url enables correct relative-link resolution
  const dom = new JSDOM(html, { url });
  const doc = dom.window.document;

  // Basic level: remove scripts/styles/event-handlers only
  doc.querySelectorAll("script, style, noscript").forEach(el => el.remove());
  stripInlineHandlers(doc);

  if (level === "basic") {
    return {
      title: doc.title || "",
      html: doc.documentElement.outerHTML,
      textContent: doc.body?.textContent?.trim() ?? "",
      excerpt: "",
      byline: "",
      usedReadability: false,
    };
  }

  // Aggressive: also remove structural bloat before Readability scoring
  doc.querySelectorAll(PRE_CLEAN_SELECTORS).forEach(el => el.remove());

  // Try Readability
  try {
    const reader = new Readability(doc.cloneNode(true) as Document);
    const article = reader.parse();

    if (article && article.textContent.trim().length >= 100) {
      return {
        title:          article.title ?? doc.title ?? "",
        html:           article.content,
        textContent:    article.textContent.trim(),
        excerpt:        article.excerpt ?? "",
        byline:         article.byline ?? "",
        usedReadability: true,
      };
    }
  } catch (err) {
    // Readability can throw on malformed DOMs — fall through to selector heuristic
    console.warn(`[Fetch] Readability failed: ${(err as Error).message}`);
  }

  // Fallback: CSS selector heuristic
  for (const selector of FALLBACK_SELECTORS) {
    const el = doc.querySelector(selector);
    if (el && (el.textContent?.trim().length ?? 0) >= 100) {
      return {
        title:           doc.title ?? "",
        html:            el.outerHTML,
        textContent:     el.textContent?.trim() ?? "",
        excerpt:         "",
        byline:          "",
        usedReadability: false,
      };
    }
  }

  // Last resort: return the whole cleaned document
  return {
    title:           doc.title ?? "",
    html:            doc.documentElement.outerHTML,
    textContent:     doc.body?.textContent?.trim() ?? "",
    excerpt:         "",
    byline:          "",
    usedReadability: false,
  };
}

/**
 * Strip all inline event handlers (onclick, onmouseover, etc.) from the document.
 */
function stripInlineHandlers(doc: Document): void {
  const all = doc.querySelectorAll("*");
  all.forEach(el => {
    const attrs = Array.from(el.attributes);
    attrs.forEach(attr => {
      if (attr.name.startsWith("on")) {
        el.removeAttribute(attr.name);
      }
    });
  });
}

// ---------------------------------------------------------------------------
// HTML → Markdown conversion
// ---------------------------------------------------------------------------

/**
 * Convert HTML to Markdown using node-html-markdown (singleton, JIT-warmed).
 * Resolves relative URLs to absolute before conversion.
 *
 * @param html    - Cleaned HTML string
 * @param baseUrl - Original page URL, used to absolutify relative links/images
 */
export function htmlToMarkdown(html: string, baseUrl?: string): string {
  let processedHtml = html;

  // Absolutify relative URLs so Markdown links point somewhere useful
  if (baseUrl) {
    try {
      const origin = new URL(baseUrl).origin;
      // href="/" or href="/path"
      processedHtml = processedHtml.replace(
        /\s(href|src)="(\/[^"]*)"/gi,
        (_match, attr, path) => ` ${attr}="${origin}${path}"`,
      );
    } catch {
      // Invalid base URL — skip absolutification
    }
  }

  return getMarkdownConverter().translate(processedHtml);
}

// ---------------------------------------------------------------------------
// Retry-with-exponential-backoff
// ---------------------------------------------------------------------------

export interface FetchWithRetryOptions {
  maxRetries?: number;       // default: 3
  baseDelayMs?: number;      // default: 1000
  timeoutMs?: number;        // default: 20_000
  headers?: Record<string, string>;
  signal?: AbortSignal;
}

/**
 * Fetch a URL with automatic retry on transient errors (network failures, 429, 5xx).
 *
 * - Respects `Retry-After` header on 429 responses
 * - Uses exponential back-off with jitter for other retryable errors
 * - Honours the caller's AbortSignal so either the outer signal or the per-request
 *   timeout can cancel the operation
 */
export async function fetchWithRetry(
  url: string,
  options: FetchWithRetryOptions = {},
): Promise<Response> {
  const {
    maxRetries  = 3,
    baseDelayMs = 1_000,
    timeoutMs   = 20_000,
    headers     = {},
    signal,
  } = options;

  let lastError: unknown;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    // Per-request AbortController so we can enforce the timeout independently
    const controller = new AbortController();
    const timeoutId  = setTimeout(() => controller.abort(), timeoutMs);

    // Chain the caller's signal — if it fires, abort our controller too
    const onCallerAbort = () => controller.abort();
    signal?.addEventListener("abort", onCallerAbort, { once: true });

    try {
      const response = await fetch(url, {
        headers,
        signal: controller.signal,
      });

      // Success path
      if (response.ok || (response.status < 500 && response.status !== 429)) {
        return response;
      }

      // Retry-able server error or rate-limit
      if (attempt < maxRetries) {
        let delayMs: number;

        if (response.status === 429) {
          const retryAfter = response.headers.get("Retry-After");
          delayMs = retryAfter
            ? parseInt(retryAfter, 10) * 1_000
            : baseDelayMs * Math.pow(2, attempt);
        } else {
          // 5xx: exponential back-off with ±20% jitter
          delayMs = baseDelayMs * Math.pow(2, attempt) * (0.8 + Math.random() * 0.4);
        }

        console.warn(
          `[Fetch] HTTP ${response.status} on attempt ${attempt + 1}/${maxRetries + 1}. ` +
          `Retrying in ${Math.round(delayMs)}ms…`,
        );

        await sleep(delayMs, signal);
        continue;
      }

      // Exhausted retries — return the last response so the caller can inspect the status
      return response;
    } catch (err) {
      lastError = err;

      // Don't retry on abort (caller-initiated or timeout on final attempt)
      if (isAbortError(err)) {
        throw err;
      }

      if (attempt < maxRetries) {
        const delayMs = baseDelayMs * Math.pow(2, attempt);
        console.warn(
          `[Fetch] Network error on attempt ${attempt + 1}/${maxRetries + 1}: ` +
          `${(err as Error).message}. Retrying in ${delayMs}ms…`,
        );
        await sleep(delayMs, signal);
      }
    } finally {
      clearTimeout(timeoutId);
      signal?.removeEventListener("abort", onCallerAbort);
    }
  }

  throw lastError ?? new Error("Max retries exceeded");
}

// ---------------------------------------------------------------------------
// Charset / encoding helpers
// ---------------------------------------------------------------------------

/**
 * Decode a Response body using the charset declared in Content-Type,
 * falling back to UTF-8 when unspecified.
 *
 * Browsers do this automatically; Node.js `response.text()` always uses UTF-8
 * unless we handle it ourselves.
 */
export async function decodeResponseText(response: Response): Promise<string> {
  const contentType = response.headers.get("content-type") ?? "";
  const charsetMatch = contentType.match(/charset=([^\s;]+)/i);
  const charset = charsetMatch ? charsetMatch[1].trim() : "utf-8";

  const buffer = await response.arrayBuffer();

  try {
    return new TextDecoder(charset).decode(buffer);
  } catch {
    // Unknown charset — fall back to UTF-8
    return new TextDecoder("utf-8").decode(buffer);
  }
}

// ---------------------------------------------------------------------------
// Miscellaneous utilities
// ---------------------------------------------------------------------------

/** Validate CleanLevel parameter value */
export function isValidCleanLevel(value: unknown): value is CleanLevel {
  return ["none", "basic", "aggressive"].includes(value as string);
}

/** Extract file extension from URL */
export function getExtensionFromUrl(url: string): string {
  const match = url.match(/\.([^./?#]+)(?:[?#]|$)/);
  return match ? "." + match[1] : "";
}

/** Truncate content to maxBytes (byte-aware, not char-aware) */
export function truncateContent(content: string, maxBytes: number): string {
  const bytesUsed = Buffer.byteLength(content, "utf-8");
  if (bytesUsed <= maxBytes) return content;

  // Binary-search the character boundary that stays within maxBytes
  let lo = 0;
  let hi = content.length;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (Buffer.byteLength(content.slice(0, mid), "utf-8") <= maxBytes) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }

  return content.slice(0, lo) + `\n\n[Output truncated at ${maxBytes} bytes]`;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(new DOMException("Aborted", "AbortError"));
      return;
    }
    const id = setTimeout(resolve, ms);
    signal?.addEventListener("abort", () => {
      clearTimeout(id);
      reject(new DOMException("Aborted", "AbortError"));
    }, { once: true });
  });
}

function isAbortError(err: unknown): boolean {
  return (
    err instanceof Error &&
    (err.name === "AbortError" || err.name === "TimeoutError")
  );
}

// ---------------------------------------------------------------------------
// Legacy re-exports (kept for backward compatibility)
// ---------------------------------------------------------------------------

/** @deprecated Use extractContent() + htmlToMarkdown() instead */
export function cleanHtmlContent(content: string, cleanLevel: CleanLevel): string {
  if (cleanLevel === "none") return content;

  let cleaned = content;
  cleaned = cleaned.replace(/<script[\s\S]*?<\/script>/gi, "");
  cleaned = cleaned.replace(/<style[\s\S]*?<\/style>/gi, "");
  cleaned = cleaned.replace(/\s+on\w+="[^"]*"/gi, "");
  cleaned = cleaned.replace(/\s+on\w+='[^']*'/gi, "");

  if (cleanLevel === "basic") return cleaned;

  const bloatTags = ["nav", "footer", "header", "aside", "iframe", "embed", "object", "applet", "noscript", "template"];
  for (const tag of bloatTags) {
    cleaned = cleaned.replace(new RegExp(`<${tag}[\\s\\S]*?<\\/${tag}>`, "gi"), "");
    cleaned = cleaned.replace(new RegExp(`<${tag}[^>]*\\/>`, "gi"), "");
  }

  return cleaned;
}
