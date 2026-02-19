# Tailwind CSS v4 Reference

## What Changed from v3

Tailwind v4 is a ground-up rewrite. It is **NOT backward-compatible** in many ways.

### Installation (v4)

```bash
npm install tailwindcss @tailwindcss/postcss
# or with Vite (recommended):
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts (preferred — faster than PostCSS)
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [tailwindcss()],
})
```

```css
/* app/globals.css — just one import, no @tailwind directives */
@import "tailwindcss";
```

**No `tailwind.config.js` needed by default** — everything is configured in CSS.

---

## CSS-First Configuration

```css
/* globals.css */
@import "tailwindcss";

@theme {
  /* Override or extend design tokens */
  --font-sans: "Inter", ui-sans-serif, system-ui;
  --font-mono: "JetBrains Mono", ui-monospace;

  /* Custom colors (use oklch for modern displays) */
  --color-brand-50: oklch(0.97 0.01 250);
  --color-brand-500: oklch(0.55 0.2 250);
  --color-brand-900: oklch(0.25 0.1 250);

  /* Custom breakpoints */
  --breakpoint-3xl: 1920px;

  /* Custom spacing */
  --spacing: 0.25rem;  /* base unit for all spacing utilities */

  /* Custom animations */
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
}
```

All `@theme` values become CSS custom properties on `:root`:
- `--color-brand-500` → usable as `var(--color-brand-500)` anywhere
- Automatically generates utilities: `bg-brand-500`, `text-brand-500`, `border-brand-500`

### Extending vs Overriding

```css
/* Replace the entire color palette (removes defaults) */
@theme {
  --color-*: initial;  /* clears defaults */
  --color-blue-500: oklch(0.6 0.24 264);
}

/* Add to the palette (keeps defaults) */
@theme {
  --color-brand-500: oklch(0.55 0.2 250);  /* adds without removing others */
}
```

---

## Key Breaking Changes from v3

### 1. No `@tailwind` directives
```css
/* ❌ v3 */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* ✅ v4 */
@import "tailwindcss";
```

### 2. Custom Utilities — `@utility` replaces `@layer utilities`
```css
/* ❌ v3 */
@layer utilities {
  .tab-4 { tab-size: 4; }
}

/* ✅ v4 */
@utility tab-4 {
  tab-size: 4;
}
```

### 3. `@apply` in separate files requires `@reference`
```css
/* In a CSS module or Vue <style> block */
@reference "../../globals.css";  /* gives access to theme vars + utilities */

.my-component {
  @apply text-brand-500 font-semibold;
}
```

### 4. Renamed utilities (v3 → v4)
| v3 | v4 |
|----|-----|
| `shadow-sm` | `shadow-xs` |
| `shadow` | `shadow-sm` |
| `blur-sm` | `blur-xs` |
| `blur` | `blur-sm` |
| `rounded-sm` | `rounded-xs` |
| `rounded` | `rounded-sm` |
| `outline-none` | `outline-hidden` |
| `ring` | `ring-3` |
| `flex-shrink-*` | `shrink-*` |
| `flex-grow-*` | `grow-*` |
| `bg-opacity-*` | `bg-black/50` (opacity modifier) |
| `text-opacity-*` | `text-black/50` |

### 5. `ring` default changed
- v3: `ring` = 3px blue ring
- v4: `ring` = 1px currentColor ring
- Migration: replace `ring` → `ring-3`, add `ring-blue-500` explicitly

### 6. Default border/divide color
- v3: `gray-200` by default
- v4: `currentColor` — **always specify a color**: `border border-gray-200`

### 7. CSS variable syntax in arbitrary values
```html
<!-- ❌ v3 -->
<div class="bg-[--brand-color]">

<!-- ✅ v4 -->
<div class="bg-(--brand-color)">
```

### 8. Important modifier position
```html
<!-- ❌ v3 (old, deprecated in v4) -->
<div class="!bg-red-500">

<!-- ✅ v4 -->
<div class="bg-red-500!">
```

### 9. Prefix syntax
```html
<!-- ✅ v4 prefix looks like a variant -->
<div class="tw:flex tw:bg-red-500 tw:hover:bg-red-600">
```

### 10. `theme()` function → CSS variables
```css
/* ❌ v3 style */
background: theme(colors.red.500);

/* ✅ v4 style */
background: var(--color-red-500);

/* For media queries (CSS vars not supported): */
@media (width >= theme(--breakpoint-xl)) { ... }
```

---

## New Features in v4

### Container Queries (built-in, no plugin)

```html
<div class="@container">
  <div class="grid grid-cols-1 @sm:grid-cols-2 @lg:grid-cols-4">
    <!-- Responds to container size, not viewport -->
  </div>
</div>

<!-- Max-width container query -->
<div class="@container">
  <div class="block @max-md:hidden">hidden on small containers</div>
</div>
```

### Dynamic Values (no config needed)

```html
<!-- Any number works for grid columns -->
<div class="grid-cols-15">

<!-- Any spacing value -->
<div class="mt-17 px-29">

<!-- Custom data attributes (no config) -->
<div data-current class="opacity-50 data-current:opacity-100">
```

### 3D Transforms

```html
<div class="perspective-distant">
  <div class="rotate-x-45 rotate-z-12 transform-3d">
    <!-- 3D rotated element -->
  </div>
</div>
```

### Gradient Improvements

```html
<!-- Linear with angle -->
<div class="bg-linear-45 from-indigo-500 to-pink-500">

<!-- Radial gradient -->
<div class="bg-radial-[at_25%_25%] from-white to-zinc-900 to-75%">

<!-- Conic gradient -->
<div class="bg-conic from-red-500 to-blue-500">

<!-- OKLCH interpolation (more vivid) -->
<div class="bg-linear-to-r/oklch from-indigo-500 to-teal-400">
```

### @starting-style — CSS enter animations

```html
<!-- No JavaScript needed for enter transitions -->
<div popover class="
  opacity-100 transition-discrete
  starting:open:opacity-0
">
  Fades in when shown
</div>
```

### not-* variant

```html
<!-- Apply when NOT hovered -->
<div class="not-hover:opacity-75">

<!-- Apply when media query NOT matched -->
<div class="not-supports-[display:grid]:flex">
```

### in-* variant (implicit groups)

```html
<!-- Like group-*, but without needing group class -->
<div>
  <div class="in-hover:opacity-100 opacity-50">
    Shows fully when any ancestor is hovered
  </div>
</div>
```

### field-sizing (auto-resize textarea)

```html
<textarea class="field-sizing-content">
  Auto-resizes to fit content — no JavaScript needed
</textarea>
```

---

## Dark Mode

```css
/* globals.css */
@import "tailwindcss";

/* Variant-based (default): user adds class="dark" to <html> */
/* In v4, dark mode is configured via @variant */
@custom-variant dark (&:is(.dark *));
```

```tsx
// layout.tsx — control dark mode
<html lang="en" className={isDark ? 'dark' : ''}>

// Component usage
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
```

For system preference instead:
```css
@custom-variant dark (@media (prefers-color-scheme: dark));
```

---

## Custom Variants

```css
/* Custom variant */
@custom-variant hocus (&:hover, &:focus);

/* Usage */
/* class="hocus:ring-2" */

/* Override hover to work on touch too */
@custom-variant hover (&:hover);
```

---

## shadcn/ui with Tailwind v4

shadcn/ui v2+ supports Tailwind v4. Uses CSS variables for theming:

```css
/* globals.css */
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  /* ... */
}

:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
}
```

---

## Upgrade Tool

```bash
# Auto-migrate from v3 to v4
npx @tailwindcss/upgrade

# Run in a new branch — review the diff carefully
```

The tool handles ~90% of migrations automatically:
- Updates dependencies
- Migrates `tailwind.config.js` to `@theme` in CSS
- Updates renamed utilities in HTML/JSX
- Converts `@layer utilities` to `@utility`
