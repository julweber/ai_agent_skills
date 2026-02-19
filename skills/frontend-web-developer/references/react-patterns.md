# React 19 Patterns for Next.js App Router

## Server Components vs Client Components

### Decision Rules

**Use Server Components (default) when:**
- Accessing databases, ORMs, or file system
- Using secrets / environment variables
- Fetching data (reduces client-side JS and waterfalls)
- Rendering static or infrequently updated content
- Large dependencies that don't need interactivity (markdown renderers, data viz)

**Use Client Components (`'use client'`) when:**
- State: `useState`, `useReducer`
- Effects: `useEffect`, `useLayoutEffect`
- Event handlers: `onClick`, `onChange`, `onSubmit`
- Browser APIs: `localStorage`, `sessionStorage`, `window`, `document`
- Custom hooks that use any of the above
- Third-party components that require client context

### Component Composition Rules

```tsx
// ✅ Server Component passing children to a Client Component
// ServerPage.tsx (no directive = Server)
import { ClientWrapper } from './client-wrapper'

export default function ServerPage() {
  return (
    <ClientWrapper>
      <ServerOnlyContent />  {/* Server Component as children ✅ */}
    </ClientWrapper>
  )
}

// client-wrapper.tsx
'use client'
export function ClientWrapper({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false)
  return <div onClick={() => setOpen(!open)}>{children}</div>
}

// ❌ WRONG: Importing a Server Component directly into a Client Component
'use client'
import { ServerOnlyContent } from './server-only'  // ← will be bundled as client code
```

### server-only Package

```ts
// lib/db.ts — prevents accidental client-side import
import 'server-only'

export const db = createClient(process.env.DATABASE_URL!)
```

---

## Context and Providers

Context providers must be Client Components, but keep them small:

```tsx
// providers/theme-provider.tsx
'use client'

import { createContext, useContext, useState } from 'react'

const ThemeContext = createContext<'light' | 'dark'>('light')

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light')
  return (
    <ThemeContext.Provider value={theme}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => useContext(ThemeContext)

// app/layout.tsx — wrap only what needs the context
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ThemeProvider>  {/* ← Client Component wrapping Server children ✅ */}
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
```

---

## React 19 New Hooks and APIs

### useActionState (replaces deprecated useFormState)

```tsx
'use client'
import { useActionState } from 'react'

type State = { error?: string; success?: boolean } | null

async function serverAction(prevState: State, formData: FormData): Promise<State> {
  'use server'
  const name = formData.get('name') as string
  if (!name) return { error: 'Name is required' }
  await saveToDb(name)
  return { success: true }
}

export function MyForm() {
  const [state, action, isPending] = useActionState(serverAction, null)

  return (
    <form action={action}>
      <input name="name" disabled={isPending} />
      {state?.error && <p className="text-destructive">{state.error}</p>}
      {state?.success && <p className="text-green-600">Saved!</p>}
      <button type="submit" disabled={isPending}>
        {isPending ? 'Saving…' : 'Save'}
      </button>
    </form>
  )
}
```

### useOptimistic — Optimistic UI

```tsx
'use client'
import { useOptimistic } from 'react'

export function LikeButton({ postId, initialLikes }: { postId: string; initialLikes: number }) {
  const [optimisticLikes, addOptimisticLike] = useOptimistic(
    initialLikes,
    (current, _action) => current + 1
  )

  async function handleLike() {
    addOptimisticLike(null)  // immediately update UI
    await likePost(postId)   // Server Action — reconciles after
  }

  return (
    <button onClick={handleLike}>
      ❤️ {optimisticLikes}
    </button>
  )
}
```

### use() — Consume Promises and Context

```tsx
'use client'
import { use, Suspense } from 'react'

// Pass promise from Server Component to Client Component
// The Client Component suspends until the promise resolves
function ProductDetails({ productPromise }: { productPromise: Promise<Product> }) {
  const product = use(productPromise)  // suspends here
  return <div>{product.name}</div>
}

// In the Server Component:
export default function Page() {
  const productPromise = getProduct(id)  // NOT awaited — passed as promise
  return (
    <Suspense fallback={<Skeleton />}>
      <ProductDetails productPromise={productPromise} />
    </Suspense>
  )
}

// use() also works for Context (simpler than useContext)
function Component() {
  const theme = use(ThemeContext)  // equivalent to useContext(ThemeContext)
}
```

### useFormStatus — Within a Form

```tsx
'use client'
import { useFormStatus } from 'react-dom'

// Must be a CHILD of the <form> element
function SubmitButton() {
  const { pending } = useFormStatus()
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting…' : 'Submit'}
    </button>
  )
}
```

### useTransition — Non-Blocking Updates

```tsx
'use client'
import { useTransition } from 'react'

export function FilterPanel() {
  const [isPending, startTransition] = useTransition()
  const [filter, setFilter] = useState('all')

  function handleFilterChange(newFilter: string) {
    startTransition(() => {
      setFilter(newFilter)  // marked as non-urgent
    })
  }

  return (
    <div className={isPending ? 'opacity-50' : ''}>
      {/* filter UI */}
    </div>
  )
}
```

---

## Data Fetching in Client Components

### Pattern 1: Pass data from Server Component (preferred)

```tsx
// page.tsx (Server Component)
export default async function Page() {
  const data = await getData()
  return <ClientComponent initialData={data} />  // hydrate with server data
}

// client-component.tsx
'use client'
export function ClientComponent({ initialData }: { initialData: Data }) {
  const [data, setData] = useState(initialData)
  // can mutate locally without refetch
}
```

### Pattern 2: SWR for client-side data fetching

```tsx
'use client'
import useSWR from 'swr'

const fetcher = (url: string) => fetch(url).then(r => r.json())

export function LiveData() {
  const { data, error, isLoading, mutate } = useSWR('/api/data', fetcher, {
    refreshInterval: 5000,  // poll every 5s
  })

  if (isLoading) return <Skeleton />
  if (error) return <Error />
  return <div>{data.value}</div>
}
```

### Pattern 3: TanStack Query

```tsx
'use client'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

export function ProductsView() {
  const { data, isLoading } = useQuery({
    queryKey: ['products'],
    queryFn: () => fetch('/api/products').then(r => r.json()),
    staleTime: 60_000,
  })

  const queryClient = useQueryClient()
  const mutation = useMutation({
    mutationFn: (newProduct) => fetch('/api/products', {
      method: 'POST',
      body: JSON.stringify(newProduct),
    }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
  })
}
```

---

## Component Patterns

### Error Boundaries (must be Client Components)

```tsx
// error.tsx — MUST be 'use client'
'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
  }, [error])

  return (
    <div className="flex flex-col items-center gap-4 p-8">
      <h2 className="text-xl font-semibold">Something went wrong</h2>
      <button onClick={reset} className="btn-primary">
        Try again
      </button>
    </div>
  )
}
```

### Suspense Boundaries

```tsx
// ✅ Suspense AROUND the async component, not inside it
<Suspense fallback={<Skeleton />}>
  <AsyncComponent />
</Suspense>

// ❌ WRONG: Suspense inside the async component does nothing useful
export async function AsyncComponent() {
  return (
    <Suspense fallback={<Skeleton />}>  {/* ← too late, already suspending */}
      {await getData()}
    </Suspense>
  )
}
```

### Skeleton Loading Pattern

```tsx
// loading.tsx — wraps page in Suspense automatically
export default function Loading() {
  return (
    <div className="animate-pulse space-y-4">
      <div className="h-8 w-48 rounded bg-muted" />
      <div className="h-4 w-full rounded bg-muted" />
      <div className="h-4 w-3/4 rounded bg-muted" />
    </div>
  )
}
```

### Dynamic Imports (code splitting)

```tsx
import dynamic from 'next/dynamic'

// Lazy load heavy Client Component
const HeavyChart = dynamic(() => import('./heavy-chart'), {
  loading: () => <Skeleton />,
  ssr: false,  // disable SSR for browser-only libraries
})

// Lazy load with named export
const Modal = dynamic(() => import('./modal').then(m => ({ default: m.Modal })))
```

---

## TypeScript Patterns

### Server Action return types

```ts
type ActionResult<T = void> =
  | { success: true; data: T }
  | { success: false; error: string }

export async function createUser(formData: FormData): Promise<ActionResult<User>> {
  // ...
}
```

### Page and Layout Props

```ts
// All params/searchParams are Promises in v15+
type PageProps = {
  params: Promise<{ slug: string }>
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>
}

export default async function Page({ params, searchParams }: PageProps) {
  const { slug } = await params
  const { q } = await searchParams
}
```

### Component with children

```ts
// Prefer React.ReactNode for children
type Props = {
  children: React.ReactNode
  className?: string
}

// For async Server Components, return type is JSX.Element or Promise<JSX.Element>
export default async function AsyncPage(): Promise<JSX.Element> {
  // ...
}
```
