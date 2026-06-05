# Rendering Patterns

## Architecture at a Glance

```mermaid
graph TD
    subgraph CSR["Client-Side Rendering"]
        A1[Browser Request] --> A2[Empty HTML Shell]
        A2 --> A3[Download JS Bundle]
        A3 --> A4[Execute & Render]
    end

    subgraph SSR["Server-Side Rendering"]
        B1[Browser Request] --> B2[Server Fetches Data]
        B2 --> B3[Server Renders HTML]
        B3 --> B4[Send HTML + Hydrate]
    end

    subgraph SSG["Static Site Generation"]
        C1[Build Time] --> C2[Fetch Data]
        C2 --> C3[Generate Static HTML]
        C3 --> C4[Deploy to CDN]
    end

    subgraph ISR["Incremental Static Regeneration"]
        D1[First Request] --> D2[Serve Stale HTML]
        D2 --> D3[Revalidate in BG]
        D3 --> D4[Update Cache]
    end

    subgraph StreamingSSR["Streaming SSR"]
        E1[Request] --> E2[Stream HTML Shell]
        E2 --> E3[Stream Suspense Fallbacks]
        E3 --> E4[Stream Resolved Content]
    end

    subgraph RSC["React Server Components"]
        F1[Server Component] --> F2[Renders to Special Format]
        F2 --> F3[Streams to Client]
        F3 --> F4[Client Component Hydrates]
    end
```

## What is it?

Rendering patterns define HOW and WHEN a web application converts components into HTML/CSS/JS that the browser can display. The evolution spans from fully client-rendered SPAs (CSR) to server-dominant approaches (SSR, RSC), with static variants (SSG, ISR) and streaming strategies that progressively deliver content. Each pattern trades off first-load performance, SEO-friendliness, interactivity, and operational complexity.

## Why it was created

CSR SPAs gave rich interactivity but suffered slow initial loads and poor SEO. SSR solved SEO and perceived performance but increased server load and time-to-interactive (hydration penalty). SSG eliminated server cost for static content but couldn't handle dynamic data. ISR bridged static + dynamic. Streaming SSR fixed the "all-or-nothing" SSR waterfall. RSC moved component logic to the server, reducing JS shipped to the client. Each pattern emerged from the tension between fast initial render, rich interactivity, and operational cost.

## When to use it

| Pattern | Best For |
|---|---|
| CSR | Dashboards, authenticated apps, internal tools |
| SSR | Content sites needing SEO + interactivity (e-commerce, news) |
| SSG | Blogs, docs, marketing pages (content rarely changes) |
| ISR | E-commerce with frequent product updates, headless CMS |
| Streaming SSR | Large pages with mixed slow/fast content |
| Edge SSR | Global audience, low-latency dynamic pages |
| RSC | Data-heavy apps, reducing client JS bundle |

## Hands-on Example — Next.js App Router with RSC + Streaming

```tsx
// app/layout.tsx — Server Component Layout
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header>
          {/* This runs on the server — no JS sent to client */}
          <ServerHeader />
        </header>
        <main>{children}</main>
      </body>
    </html>
  );
}

// app/page.tsx — Server Component with Streaming
import { Suspense } from "react";
import { ProductList } from "@/components/ProductList";
import { ProductListSkeleton } from "@/components/ProductListSkeleton";
import { Reviews } from "@/components/Reviews";
import { ReviewsSkeleton } from "@/components/ReviewsSkeleton";

export default async function HomePage() {
  return (
    <div>
      <h1>Welcome to our Store</h1>

      {/* Fast data fetched on server — part of initial HTML */}
      <HeroBanner />

      {/* Slow queries stream in as they resolve */}
      <Suspense fallback={<ProductListSkeleton />}>
        <ProductList />
      </Suspense>

      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews />
      </Suspense>
    </div>
  );
}

// components/ProductList.tsx — Server Component
// This component fetches data and renders on the server — zero JS to client
export async function ProductList() {
  const products = await fetch("https://api.example.com/products", {
    next: { revalidate: 60 }, // ISR: revalidate every 60s
  }).then((r) => r.json());

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>
          <ProductCard product={p} />
        </li>
      ))}
    </ul>
  );
}

// components/ProductCard.tsx — Client Component (needs interactivity)
"use client";

import { useState } from "react";

export function ProductCard({ product }: { product: { id: string; name: string; price: number } }) {
  const [added, setAdded] = useState(false);

  return (
    <div>
      <h2>{product.name}</h2>
      <p>${product.price}</p>
      <button onClick={() => setAdded(true)}>
        {added ? "Added!" : "Add to Cart"}
      </button>
    </div>
  );
}
```

```tsx
// next.config.js — Edge Runtime for select routes
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: true,
  },
};

module.exports = nextConfig;

// app/admin/page.tsx — Route Segment Config for Edge
export const runtime = "edge"; // Runs on Vercel Edge / Cloudflare Workers
```

## Best Practices

- Prefer Server Components by default; use `"use client"` only when interactivity is needed
- Wrap async data fetches in `<Suspense>` boundaries with meaningful fallbacks
- Match revalidation frequency to your content freshness SLA (ISR)
- Measure TTFB, LCP, and TBT for every rendering strategy before choosing
- Use Streaming SSR for pages where some content is slow (e.g., recommendations widget)
- Avoid nesting client components inside server components unnecessarily — it breaks the server rendering tree
- Deploy SSR and Edge SSR behind a CDN cache layer to reduce origin load
- For SSG + ISR, use `generateStaticParams` to pre-render known dynamic routes

## Interview Questions

**Q1: What is the "hydration mismatch" problem in SSR and how do you fix it?**

A: Hydration mismatch occurs when the server-rendered HTML tree differs from the client's first React render tree. Causes include: browser-only APIs (`window`), random values (`Math.random()`), timezone-dependent formatting, or data that changed between server and client render. Fixes: use `suppressHydrationWarning` sparingly for intentional differences (like timestamps), ensure data is consistent by fetching on both sides or passing server data as serialized props, avoid `typeof window` guards in SSR code paths, and use `useEffect` for browser-only initialization instead of render-time branching.

**Q2: Explain how React Server Components differ from SSR and what problem they solve.**

A: SSR renders a React tree on the server to HTML — the JS bundle still ships and hydrates on the client. RSC renders components on the server into a special serializable format that streams to the client as a virtual representation — NO JS bundle ships for server components, and they never hydrate. RSC solves the "hydration tax" problem where SSR still requires downloading and executing the entire component tree's JS just to make it interactive. RSC also allows direct database/file-system access without exposing it to the client.

**Q3: How does Streaming SSR with Suspense improve perceived performance compared to traditional SSR?**

A: Traditional SSR follows a "all-or-nothing" waterfall: fetch data → render HTML → send response. The browser sees nothing until the entire page is ready. Streaming SSR sends the HTML shell and Suspense fallbacks immediately, then streams resolved content as it becomes ready. This gives the user a faster First Paint and Largest Contentful Paint (LCP), because the browser can begin rendering headers, navigation, and skeleton placeholders while waiting for slow data. React 18's `renderToPipeableStream` enables this. The key trade-off is that content shifts (CLS) can increase if skeletons are poorly sized.

## Real Company Usage

| Company | Pattern | Why |
|---|---|---|
| Vercel / Next.js Docs | SSG + ISR | Static docs with automatic revalidation on content changes |
| eBay | Streaming SSR + Edge | Personalized listings shipped from edge nodes close to users, reducing TTFB by 45% |
| The New York Times | SSR + RSC | News articles rendered server-side for SEO, interactive features hydrated as client components |
| TikTok | Edge SSR | Dynamic content rendering at edge locations worldwide with <100ms TTFB |
| Linear | CSRMixed) | App shell is CSR, but public pages use SSG via Next.js |
