# Next.js App Router Patterns (v15/v16)

## Breaking Changes — MUST KNOW

### Next.js 15: Async Request APIs
`cookies()`, `headers()`, `draftMode()`, `params`, `searchParams` are now **async Promises**:

```ts
// ✅ v15/v16 — await everything
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const cookieStore = await cookies()
  const headersList = await headers()
}

// ❌ v14 pattern — breaks in v15+
export default function Page({ params }: { params: { id: string } }) {
  const { id } = params // TypeError in v15+
}
```

### Next.js 15: Caching Defaults Flipped
- `fetch()` is **NOT cached** by default (was cached in v14)
- `GET` Route Handlers are **NOT cached** by default
- Client Router Cache `staleTime` is `0` (was 30s for dynamic, 5min for static)

### Next.js 16: New APIs
- **`proxy.ts`** replaces `middleware.ts` (old name still works but deprecated)
  - Exported function renamed to `proxy()` instead of `middleware()`
  - Now runs **Node.js runtime** by default (not Edge)
- **`after()`** (was `unstable_after()` in v15) — defer non-critical work post-response
- **`updateTag(tag)`** — Server Actions only: immediate cache expiry for read-your-writes
- **`refresh()`** — Server Actions only: refresh uncached data
- **`"use cache"` directive** — new explicit opt-in caching (requires `cacheComponents: true` in config)
- **`revalidateTag(tag, cacheLife)`** — second arg now required when using Cache Components

### Next.js 16: Parallel Routes
`default.tsx` **required** in all parallel route slots — builds fail without it.

---

## Caching Model (4 Layers)

| Cache | Where | Duration | Controls |
|-------|-------|----------|----------|
| Request Memoization | Server, per-render | Single request | `React.cache()`, auto for `fetch` |
| Data Cache | Server, persistent | Until revalidated | `fetch` options, `unstable_cache` |
| Full Route Cache | Server, persistent | Until revalidated | Dynamic APIs opt out |
| Router Cache | Client, in-memory | Session / staleTime | `router.refresh()`, Server Actions |

### fetch() Caching Options

```ts
// Not cached (default in v15+)
fetch('https://api.example.com/data')

// Cache indefinitely (opt-in)
fetch('https://api.example.com/data', { cache: 'force-cache' })

// Revalidate every N seconds (ISR-style)
fetch('https://api.example.com/data', { next: { revalidate: 3600 } })

// Tag for on-demand revalidation
fetch('https://api.example.com/data', { next: { tags: ['products'] } })
```

### Route Segment Config

```ts
// In any layout.tsx, page.tsx, or route.ts:
export const dynamic = 'force-dynamic'      // Always dynamic, never cached
export const dynamic = 'force-static'       // Force static, error on dynamic usage
export const revalidate = 3600              // ISR: revalidate every hour
export const revalidate = false             // Cache forever
export const dynamicParams = false          // 404 for unknown dynamic params
```

### On-Demand Revalidation (Server Actions / Route Handlers)

```ts
import { revalidatePath, revalidateTag } from 'next/cache'

// Invalidate a specific path
revalidatePath('/products')
revalidatePath('/products/[id]', 'page')  // just pages
revalidatePath('/products', 'layout')     // layout + all children

// Invalidate by tag
revalidateTag('products')

// v16 with Cache Components: requires cacheLife profile
revalidateTag('products', 'max')  // profiles: 'seconds', 'minutes', 'hours', 'days', 'weeks', 'max'
```

### "use cache" Directive (v16, opt-in)

```ts
// next.config.ts
export default {
  cacheComponents: true,  // enables "use cache"
}

// In a Server Component or function:
async function getProducts() {
  'use cache'
  return db.products.findMany()
}

// With custom cache profile
import { cacheLife, cacheTag } from 'next/cache'

async function getProduct(id: string) {
  'use cache'
  cacheLife('hours')           // built-in profiles: 'seconds', 'minutes', 'hours', 'days', 'weeks', 'max'
  cacheTag(`product-${id}`)
  return db.products.findUnique({ where: { id } })
}
```

---

## Routing Conventions

### File Hierarchy

```
app/
├── layout.tsx            # Shared UI (required at root), NEVER re-renders on navigation
├── template.tsx          # Like layout but re-renders on navigation
├── page.tsx              # Route UI, makes segment publicly accessible
├── loading.tsx           # Suspense skeleton, shown during page/layout load
├── error.tsx             # Error boundary — MUST be 'use client'
├── global-error.tsx      # Root error boundary (replaces root layout on error)
├── not-found.tsx         # 404 UI (triggered by notFound() call)
└── route.ts              # API endpoint (no page.tsx allowed in same segment)
```

### Dynamic Segments

```ts
// app/products/[id]/page.tsx
type Props = { params: Promise<{ id: string }> }

export default async function ProductPage({ params }: Props) {
  const { id } = await params
}

// Generate static params at build time
export async function generateStaticParams() {
  const products = await db.products.findMany({ select: { id: true } })
  return products.map(p => ({ id: p.id }))
}

// Return partial list → remaining resolved on-demand (hybrid)
// export const dynamicParams = false → 404 for anything not in list
```

### Parallel Routes

```
app/
├── layout.tsx         # Receives @team and @analytics as props
├── @team/
│   ├── page.tsx
│   └── default.tsx    # REQUIRED in v16 (build fails without it)
└── @analytics/
    ├── page.tsx
    └── default.tsx    # REQUIRED in v16
```

```tsx
// app/layout.tsx
export default function Layout({
  children,
  team,
  analytics,
}: {
  children: React.ReactNode
  team: React.ReactNode
  analytics: React.ReactNode
}) {
  return (
    <div>
      {children}
      <div className="grid grid-cols-2">
        {team}
        {analytics}
      </div>
    </div>
  )
}
```

### Intercepting Routes

```
app/
├── feed/
│   └── page.tsx
├── photos/
│   └── [id]/
│       └── page.tsx        # Full photo page (direct URL)
└── (.)photos/              # (.) = same level
    └── [id]/
        └── page.tsx        # Modal overlay when navigating from feed
```

Intercepting levels: `(.)` same, `(..)` one up, `(..)(..)` two up, `(...)` root.

---

## Server Actions (Server Functions)

### Definition Rules

```ts
// Option 1: Separate file — all exports are Server Functions
'use server'

export async function createProduct(data: FormData) {
  // ...
}

// Option 2: Inline in Server Component (directive inside function body)
export default function Page() {
  async function create(data: FormData) {
    'use server'
    // ...
  }
  return <form action={create}>...</form>
}

// ❌ WRONG: 'use server' in a Client Component file
// Client Component files cannot contain Server Functions inline
// Import them from a separate 'use server' file instead
```

### Security Pattern — Always Follow This Order

```ts
'use server'

import { auth } from '@/lib/auth'
import { z } from 'zod'

const schema = z.object({
  title: z.string().min(1).max(100),
  price: z.number().positive(),
})

export async function createProduct(prevState: unknown, formData: FormData) {
  // 1. Authenticate
  const session = await auth()
  if (!session) return { error: 'Unauthorized' }

  // 2. Authorize
  if (!session.user.canCreateProducts) return { error: 'Forbidden' }

  // 3. Validate
  const parsed = schema.safeParse({
    title: formData.get('title'),
    price: Number(formData.get('price')),
  })
  if (!parsed.success) return { error: parsed.error.flatten() }

  // 4. Process
  await db.products.create({ data: parsed.data })

  // 5. Revalidate BEFORE redirect (redirect throws internally)
  revalidatePath('/products')
  redirect('/products')   // ← never inside try/catch
}
```

### useActionState (React 19 — replaces useFormState)

```tsx
'use client'

import { useActionState } from 'react'
import { createProduct } from './actions'

export function ProductForm() {
  const [state, action, isPending] = useActionState(createProduct, null)

  return (
    <form action={action}>
      <input name="title" />
      <input name="price" type="number" />
      {state?.error && <p className="text-red-500">{state.error}</p>}
      <button type="submit" disabled={isPending}>
        {isPending ? 'Saving...' : 'Save'}
      </button>
    </form>
  )
}
```

### v16 Additions

```ts
'use server'
import { updateTag, refresh } from 'next/cache'

// Read-your-writes: immediately expire a tag after mutation
export async function updateProduct(id: string, data: unknown) {
  await db.products.update({ where: { id }, data })
  updateTag(`product-${id}`)  // client sees updated data immediately
}

// Refresh uncached data (non-cached route handlers, external APIs)
export async function refreshFeed() {
  refresh()
}
```

---

## Data Fetching Patterns

### Parallel Fetching (ALWAYS prefer over sequential)

```ts
// ✅ Parallel — both fire simultaneously
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const [product, reviews] = await Promise.all([
    getProduct(id),
    getReviews(id),
  ])
}

// ❌ Sequential — waterfall, slow
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const product = await getProduct(id)   // waits...
  const reviews = await getReviews(id)   // then waits again
}
```

### Preload Pattern

```ts
// Start fetching before conditionals block execution
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  void preloadProduct(id)  // fire immediately, don't await

  const user = await getUser()
  if (!user.hasAccess) redirect('/login')

  const product = await getProduct(id)  // already in-flight by now
}

function preloadProduct(id: string) {
  void getProduct(id)  // triggers request memoization cache
}
```

### React.cache() — Deduplication for non-fetch data

```ts
import { cache } from 'react'
import { db } from '@/lib/db'

// Wrap DB calls with React.cache() to deduplicate across component tree
export const getUser = cache(async (id: string) => {
  return db.users.findUnique({ where: { id } })
})

// Multiple Server Components calling getUser(id) in same render
// → only ONE DB query executed
```

### after() — Defer Non-Critical Work (v16, was unstable_after in v15)

```ts
import { after } from 'next/server'

export async function POST(req: Request) {
  const data = await req.json()
  await saveToDb(data)

  // Runs AFTER response is sent — doesn't block the user
  after(async () => {
    await logAnalytics(data)
    await sendWebhook(data)
  })

  return Response.json({ success: true })
}
```

---

## proxy.ts / middleware.ts (v16)

```ts
// proxy.ts (v16 — preferred name, runs Node.js by default)
// middleware.ts still works but is deprecated

import { NextRequest, NextResponse } from 'next/server'

export function proxy(request: NextRequest) {  // Note: proxy() not middleware()
  const { pathname } = request.nextUrl

  // Auth check
  if (pathname.startsWith('/dashboard')) {
    const token = request.cookies.get('token')
    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url))
    }
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
}
```

---

## Route Handlers

```ts
// app/api/products/route.ts

import { NextRequest, NextResponse } from 'next/server'

// NOT cached by default in v15+ (was cached in v14 for GET)
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const query = searchParams.get('q')

  const products = await db.products.findMany({
    where: query ? { name: { contains: query } } : undefined,
  })

  return NextResponse.json(products)
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const product = await db.products.create({ data: body })
  return NextResponse.json(product, { status: 201 })
}

// Dynamic route: app/api/products/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params  // ← must await in v15+
  const product = await db.products.findUnique({ where: { id } })
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 })
  return NextResponse.json(product)
}
```

**Do NOT call Route Handlers from Server Components** — call the logic directly instead.

---

## Performance

### Streaming with Suspense

```tsx
// app/page.tsx
import { Suspense } from 'react'
import { ProductList } from './product-list'
import { ProductListSkeleton } from './skeletons'

export default function Page() {
  return (
    <div>
      <h1>Products</h1>
      <Suspense fallback={<ProductListSkeleton />}>
        <ProductList />  {/* async Server Component — streams in */}
      </Suspense>
    </div>
  )
}

// product-list.tsx
export async function ProductList() {
  const products = await getProducts()  // suspends until resolved
  return <ul>{products.map(p => <li key={p.id}>{p.name}</li>)}</ul>
}
```

### next/image

```tsx
import Image from 'next/image'

// Always specify width/height OR fill for layout stability
<Image src="/hero.jpg" alt="Hero" width={1200} height={600} priority />

// Fill parent container
<div className="relative h-64 w-full">
  <Image src="/hero.jpg" alt="Hero" fill className="object-cover" />
</div>
```

### next/font (no layout shift)

```ts
// app/layout.tsx
import { Inter, Roboto_Mono } from 'next/font/google'

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })
const mono = Roboto_Mono({ subsets: ['latin'], variable: '--font-mono' })

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${mono.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  )
}
```

### next/form — Search Forms with Prefetch

```tsx
import Form from 'next/form'

// Automatically prefetches loading UI + navigates without full reload
export function SearchForm() {
  return (
    <Form action="/search">
      <input name="q" placeholder="Search..." />
      <button type="submit">Search</button>
    </Form>
  )
}
```
