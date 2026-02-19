# Quick Reference — Anti-Patterns & Common Mistakes

## Top Anti-Patterns (NEVER DO THESE)

### 1. Calling Route Handlers from Server Components
```ts
// ❌ Unnecessary HTTP round-trip to yourself
export default async function Page() {
  const data = await fetch('http://localhost:3000/api/products').then(r => r.json())
}

// ✅ Call the logic directly
export default async function Page() {
  const data = await db.products.findMany()
}
```

### 2. Not Awaiting Async APIs in v15+
```ts
// ❌ Breaks in Next.js 15+
export default function Page({ params }: { params: { id: string } }) {
  const id = params.id  // ← TypeError: params is a Promise
}

// ✅ Always await
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
}
```

### 3. `'use client'` on Layout or Page
```tsx
// ❌ Kills RSC benefits for the entire subtree
'use client'
export default function Layout({ children }) { ... }

// ✅ Keep layouts as Server Components — only mark leaf interactive parts
export default function Layout({ children }) {
  return (
    <div>
      <NavBar />    {/* Server Component */}
      <ThemeToggle /> {/* 'use client' only this small component */}
      {children}
    </div>
  )
}
```

### 4. Importing Server Component into Client Component
```tsx
// ❌ ServerComponent gets bundled as client code
'use client'
import { ServerComponent } from './server-component'

// ✅ Use children prop pattern
'use client'
export function ClientWrapper({ children }: { children: React.ReactNode }) {
  return <div>{children}</div>
}
// Then in a Server Component:
// <ClientWrapper><ServerComponent /></ClientWrapper>
```

### 5. `redirect()` inside try/catch
```ts
// ❌ redirect() throws internally — catch will swallow it
try {
  await doSomething()
  redirect('/success')  // ← throws NEXT_REDIRECT, caught here!
} catch (e) {
  console.error(e)  // will log the redirect "error"
}

// ✅ revalidate first, then redirect outside try/catch
await doSomething()
revalidatePath('/products')
redirect('/success')  // ← outside try/catch
```

### 6. `error.tsx` without `'use client'`
```tsx
// ❌ Cryptic error — error.tsx MUST be a Client Component
export default function Error({ error, reset }) { ... }

// ✅ Always add 'use client' to error.tsx
'use client'
export default function Error({ error, reset }: {
  error: Error & { digest?: string }
  reset: () => void
}) { ... }
```

### 7. Sequential awaits when parallel is possible
```ts
// ❌ Waterfall — 200ms + 200ms = 400ms
const user = await getUser()
const posts = await getPosts(user.id)

// ✅ Parallel — both fire at once = 200ms
const [user, posts] = await Promise.all([getUser(), getPosts(id)])
```

### 8. Forgetting revalidation after mutations
```ts
// ❌ Mutation works but page still shows stale data
export async function deleteProduct(id: string) {
  'use server'
  await db.products.delete({ where: { id } })
  // Missing revalidation!
}

// ✅ Always revalidate after mutations
export async function deleteProduct(id: string) {
  'use server'
  await db.products.delete({ where: { id } })
  revalidatePath('/products')
}
```

### 9. Defining Server Functions inline in Client Component files
```tsx
// ❌ Can't use 'use server' inline in a Client Component file
'use client'
export function MyForm() {
  async function action(formData: FormData) {
    'use server'  // ← ERROR in a 'use client' file
    await saveData(formData)
  }
}

// ✅ Import from a separate 'use server' file
import { saveAction } from './actions'  // actions.ts has 'use server' at top
```

### 10. `<Suspense>` inside the async component
```tsx
// ❌ Suspense is inside the thing that suspends — does nothing useful
async function ProductList() {
  return (
    <Suspense fallback={<Skeleton />}>
      <ul>{(await getProducts()).map(...)}</ul>
    </Suspense>
  )
}

// ✅ Suspense WRAPS the component that suspends
export default function Page() {
  return (
    <Suspense fallback={<Skeleton />}>
      <ProductList />  {/* ProductList suspends; Suspense catches it */}
    </Suspense>
  )
}
```

### 11. Context provider in a Server Component
```tsx
// ❌ createContext/useContext require Client Components
export default function Layout() {
  return (
    <MyContext.Provider value={...}>  {/* Error: can't use React context in SC */}
      {children}
    </MyContext.Provider>
  )
}

// ✅ Wrap provider in a Client Component
// providers/my-provider.tsx → 'use client' + <MyContext.Provider>
// layout.tsx → <MyProvider>{children}</MyProvider>
```

---

## Next.js 15 vs 16 Cheat Sheet

| Feature | v15 | v16 |
|---------|-----|-----|
| Middleware file | `middleware.ts` | `proxy.ts` (preferred) |
| Middleware export | `middleware()` | `proxy()` |
| Middleware runtime | Edge | Node.js (default) |
| Defer post-response | `unstable_after()` | `after()` (stable) |
| Caching opt-in | — | `"use cache"` directive |
| Parallel routes `default.tsx` | Warning if missing | Build error if missing |
| Sync params access | Deprecation warning | Removed (breaks) |
| PPR | `experimental.ppr` | `cacheComponents: true` |
| React Compiler | Experimental | Stable opt-in |
| Bundler | Webpack (default) | Turbopack (default) |

---

## next.config.ts Feature Flags

```ts
import type { NextConfig } from 'next'

const config: NextConfig = {
  // v16 features
  cacheComponents: true,         // enables "use cache" directive + Cache Components
  reactCompiler: true,           // React Compiler (auto-memoization)

  // Experimental
  experimental: {
    // Restore v14 Router Cache behavior (30s staleTime)
    staleTimes: { dynamic: 30, static: 180 },

    // Turbopack filesystem cache (v16 beta)
    turbopackFileSystemCacheForDev: true,
  },

  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'images.example.com' },
    ],
  },
}

export default config
```

---

## App Router Routing Cheat Sheet

| Pattern | File | URL Result |
|---------|------|------------|
| Static page | `app/about/page.tsx` | `/about` |
| Dynamic segment | `app/blog/[slug]/page.tsx` | `/blog/my-post` |
| Catch-all | `app/docs/[...path]/page.tsx` | `/docs/a/b/c` |
| Optional catch-all | `app/[[...path]]/page.tsx` | `/` or `/a/b` |
| Route group | `app/(marketing)/page.tsx` | `/` (no segment) |
| Parallel route | `app/@modal/page.tsx` | Injected as prop |
| Intercepting (same level) | `app/(.)photo/page.tsx` | Intercepts `/photo` |
| API route | `app/api/users/route.ts` | `/api/users` |
| Dynamic API | `app/api/users/[id]/route.ts` | `/api/users/123` |

---

## Server Action Checklist

Before shipping a Server Action, verify:

- [ ] **Authenticate** — check session/token
- [ ] **Authorize** — check permissions for this specific resource
- [ ] **Validate** — use zod/valibot, never trust raw FormData
- [ ] **Error handling** — return typed errors, not throw
- [ ] **Revalidate** — call `revalidatePath`/`revalidateTag` after mutations
- [ ] **Redirect** is OUTSIDE try/catch
- [ ] No sensitive data in return values (returned to client)
- [ ] Rate limiting for public-facing actions

---

## Tailwind v4 — Quick Migration Notes

```html
<!-- Shadow/blur/radius renames -->
shadow-sm  →  shadow-xs
shadow     →  shadow-sm
blur-sm    →  blur-xs
blur       →  blur-sm
rounded-sm →  rounded-xs
rounded    →  rounded-sm

<!-- Focus ring -->
ring           →  ring-3 ring-blue-500
focus:outline-none  →  focus:outline-hidden

<!-- Opacity utilities removed -->
bg-opacity-50  →  bg-black/50
text-opacity-75  →  text-black/75

<!-- Border needs explicit color now -->
border  →  border border-gray-200

<!-- CSS variable in arbitrary values -->
bg-[--my-var]  →  bg-(--my-var)

<!-- Important modifier moves to end -->
!bg-red-500  →  bg-red-500!
```

---

## TypeScript — Common Pitfalls

```ts
// ✅ Page props type (v15+) — params is a Promise
type Props = {
  params: Promise<{ id: string }>
  searchParams: Promise<{ q?: string }>
}

// ✅ generateMetadata also gets async params
export async function generateMetadata({ params }: Props) {
  const { id } = await params
  const product = await getProduct(id)
  return { title: product.name }
}

// ✅ generateStaticParams returns plain objects (not Promises)
export async function generateStaticParams() {
  const products = await db.products.findMany()
  return products.map(p => ({ id: p.id }))  // synchronous return type
}
```

---

## Performance Checklist

- [ ] Data fetching uses `Promise.all()` for parallel calls
- [ ] Heavy Client Components use `dynamic(() => import(...))` 
- [ ] Images use `<Image>` with explicit `width`/`height` or `fill`
- [ ] Fonts use `next/font` (eliminates layout shift)
- [ ] Interactive features are isolated to leaf Client Components
- [ ] Suspense boundaries placed around slow async components
- [ ] `generateStaticParams` used for known dynamic routes
- [ ] `loading.tsx` present for slow pages/layouts
- [ ] `after()` used for analytics, logging, webhooks
