import { Type } from "@sinclair/typebox";
import type { ExtensionAPI, TextContent } from "@mariozechner/pi-coding-agent";
import {
  extractContent,
  htmlToMarkdown,
  fetchWithRetry,
  decodeResponseText,
  truncateContent,
  getExtensionFromUrl,
  isValidCleanLevel,
  type CleanLevel,
} from "./utils/helpers.js";

/**
 * Fetch Tool — Best-Practice Implementation
 *
 * HTML → Markdown pipeline (per research report docs/typescript-fetch-research.md):
 *
 *  1. FETCH  — native fetch with per-request AbortController timeout +
 *              automatic retry with exponential back-off (respects Retry-After)
 *
 *  2. EXTRACT — @mozilla/readability + jsdom to isolate the article body
 *               (same algorithm as Firefox Reader View); falls back to CSS
 *               selector heuristics when Readability fails.
 *
 *  3. CONVERT — node-html-markdown (singleton, JIT-warmed) for fast, clean
 *               HTML → Markdown conversion. Relative URLs are absolutified
 *               before conversion so links remain clickable.
 *
 * Cleaning levels:
 *  - 'aggressive' (default): Full three-stage pipeline with Readability
 *  - 'basic':  Strip script/style/event-handlers; skip Readability
 *  - 'none':   Convert raw HTML to Markdown as-is
 *
 * Additional best practices applied:
 *  - Honest User-Agent string identifying the bot
 *  - Content-Type charset detection (non-UTF-8 pages decoded correctly)
 *  - llms.txt / .well-known/llmstxt discovery (plaintext/markdown responses only)
 *  - 50 KB output truncation with byte-accurate boundary detection
 */

const USER_AGENT =
  "Mozilla/5.0 (compatible; pi-fetch/1.0; +https://github.com/mariozechner/pi)";

const MAX_BYTES = 50 * 1024; // 50 KB — matches pi built-in tool limit

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "fetch",
    label: "Fetch",
    description:
      "Fetch content from a URL. Supports HTML pages, JSON, text files, and binary formats. " +
      "Automatically renders HTML to readable text using native markdown conversion with configurable cleaning levels. " +
      "Can fetch PDFs, DOCX, images, and other file types. Returns truncated output for large responses.",
    parameters: Type.Object({
      url: Type.String({ description: "URL to fetch" }),
      timeout: Type.Optional(
        Type.Number({ description: "Timeout in seconds (default: 20)" }),
      ),
      raw: Type.Optional(
        Type.Boolean({ description: "Return raw HTML without transforms (false by default)" }),
      ),
      cleanLevel: Type.Optional(
        Type.Union(
          [Type.Literal("none"), Type.Literal("basic"), Type.Literal("aggressive")],
          {
            description:
              "How aggressively to remove scripts/styles/bloat before markdown conversion. " +
              "Ignored when raw=true. Default: aggressive",
          },
        ),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const {
        url: inputUrl,
        timeout = 20,
        raw = false,
        cleanLevel: userCleanLevel = "aggressive",
      } = params;

      const cleanLevel: CleanLevel =
        !raw && isValidCleanLevel(userCleanLevel) ? userCleanLevel : "aggressive";

      // Normalize URL
      let normalizedUrl = inputUrl;
      if (!inputUrl.match(/^https?:\/\//i)) {
        normalizedUrl = `https://${inputUrl}`;
      }

      try {
        // Parse URL early — inside try/catch so invalid URLs are handled gracefully
        const origin = new URL(normalizedUrl).origin;
        let finalUrl = normalizedUrl;

        // ── llms.txt discovery ──────────────────────────────────────────────
        // Check .well-known/llmstxt only when not fetching raw HTML and the
        // URL isn't already a markdown file.  Only trust responses that are
        // genuinely plaintext/markdown (not HTML soft-404 pages).
        if (!raw && !normalizedUrl.endsWith(".md")) {
          try {
            const llmsResponse = await fetchWithRetry(`${origin}/.well-known/llmstxt`, {
              timeoutMs: 5_000,
              maxRetries: 0, // quick probe, no retry
              headers: { "User-Agent": USER_AGENT },
              signal: signal ?? undefined,
            });
            const llmsContentType = llmsResponse.headers.get("content-type") ?? "";
            const isRealTextContent =
              llmsResponse.ok &&
              !llmsContentType.includes("text/html") &&
              (llmsContentType.includes("text/") ||
                llmsContentType.includes("markdown") ||
                llmsContentType === "");

            if (isRealTextContent) {
              finalUrl = `${origin}/.well-known/llmstxt`;
              console.log(`[Fetch] Using llms.txt endpoint for ${normalizedUrl}`);
            }
          } catch {
            // Probe failed — continue with the original URL
          }
        }
        // ── Stage 1: Fetch with retry + timeout ─────────────────────────
        const response = await fetchWithRetry(finalUrl, {
          timeoutMs:   timeout * 1_000,
          maxRetries:  3,
          baseDelayMs: 1_000,
          headers: {
            Accept: raw
              ? "*/*"
              : "text/html,application/xhtml+xml,text/markdown;q=0.8,*/*;q=0.1",
            "User-Agent": USER_AGENT,
          },
          signal: signal ?? undefined,
        });

        if (!response.ok) {
          throw new Error(
            `Failed to fetch URL: ${response.statusText || "HTTP " + response.status} (${response.status})`,
          );
        }

        const contentType = response.headers.get("content-type") ?? "";

        // ── Charset-aware decoding (non-UTF-8 pages) ─────────────────────
        const content = await decodeResponseText(response);

        let processedContent: string;
        let method: string;

        // ── Content-type dispatch ─────────────────────────────────────────
        // HTML must be checked BEFORE generic `text/` because `text/html`
        // would match the plain-text branch first.

        if (
          contentType.includes("html") ||
          (!contentType && content.trimStart().startsWith("<"))
        ) {
          // ── HTML ─────────────────────────────────────────────────────────
          if (raw) {
            processedContent = content;
            method = "raw-html";
          } else {
            // Stage 2: Extract main content (Readability + jsdom or heuristic)
            const extracted = extractContent(finalUrl, content, cleanLevel);

            // Stage 3: Convert cleaned HTML → Markdown (NHM singleton)
            let markdown = htmlToMarkdown(extracted.html, finalUrl);

            // Prepend title when Readability found one
            if (extracted.title && extracted.usedReadability) {
              markdown = `# ${extracted.title}\n\n${markdown}`;
            }

            // Prepend author/excerpt metadata when available
            if (extracted.byline) {
              markdown = `*${extracted.byline}*\n\n${markdown}`;
            }

            processedContent = markdown;
            method = `rendered-html-${cleanLevel}${extracted.usedReadability ? "+readability" : ""}`;
          }
        } else if (contentType.includes("application/json")) {
          // ── JSON ──────────────────────────────────────────────────────────
          try {
            const json = JSON.parse(content);
            processedContent = JSON.stringify(json, null, 2);
            method = "json";
          } catch {
            throw new Error("Invalid JSON response");
          }
        } else if (
          contentType.includes("text/") ||
          contentType.includes("application/xml")
        ) {
          // ── Plain text / RSS / Atom ───────────────────────────────────────
          processedContent = content;
          method = raw ? "raw" : "text";
        } else {
          // ── Binary / unknown ──────────────────────────────────────────────
          const ext = getExtensionFromUrl(finalUrl);
          if (ext) {
            processedContent = `[Binary file: ${ext}] Download URL: ${finalUrl}`;
            method = "binary";
          } else {
            throw new Error(`Unsupported content type: ${contentType}`);
          }
        }

        // ── Truncation (50 KB byte-accurate) ─────────────────────────────
        const finalContent = raw ? processedContent : truncateContent(processedContent, MAX_BYTES);

        return {
          content: [
            {
              type: "text",
              text: `URL: ${finalUrl}\nMethod: ${method}\n\n${finalContent}`,
            },
          ] as TextContent[],
          details: {
            url:         finalUrl,
            method,
            contentType,
            bytes:       Buffer.byteLength(finalContent, "utf-8"),
          },
        };
      } catch (error: any) {
        return {
          content: [
            {
              type: "text",
              text: `Error fetching URL ${inputUrl}: ${error.message}`,
            },
          ] as TextContent[],
          details: {},
        };
      }
    },
  });
}
