# Gravity Brewing — Static Site Migration Plan

Migrate `thegravitybrewing.com` off Squarespace to a static **Hugo** site deployed on
**Netlify**, with announcements/news authored in **Kit** (`/home/mrdon/dev/kit`) and the
site treated primarily as a **machine-readable data source** for Google and AI assistants.

---

## 1. Guiding principles

- **Static-first.** No server in the visitor path. Site is files on Netlify's CDN.
- **Machine-first audience.** Few humans browse; most info is consumed via Google and AI
  assistants (ChatGPT/Perplexity/AI Overviews) plus Google Business Profile. Optimize for
  crawlers first, high-intent human clicks (“should I go tonight?”) second.
- **Facts in text, never trapped in images.** Hours, on-tap, event date/time, food today are
  real HTML text + JSON-LD. Graphics are decoration only.
- **Kit is the authoring + source-of-truth layer.** The site is a read-only projection of Kit.
  Kit being down means “can't publish new posts,” never “site is down.”
- **Reversible decisions.** Prefer choices we can change later without reworking the other side
  (e.g. the image-URL contract is stable whether bytes live in Postgres or a bucket).

---

## 2. Architecture

```
Kit (authoring: Slack / mobile card stack / MCP)
  │   announcements JSON  +  signed build-only image URLs (GET /media/:id)
  ▼
Netlify build (Hugo)
  │   content adapter: resources.GetRemote → download JSON + images
  │   generate pages, image derivatives (resize/WebP/srcset), JSON-LD
  ▼
Static site on Netlify CDN
  │   emits standard RSS/Atom + JSON Feed + llms.txt
  ▼
Downstream: RSS readers, social publishing tool (FeedHive/Publer) or Kit push, AI crawlers
```

**Publish flow:** staff posts in Kit → Kit Task pings the **Netlify build hook** → Hugo
rebuilds → new content live in ~30s. Kit down = last good build stays served.

### Data contract (Kit → Hugo): custom JSON

- The **Kit → Hugo** hop uses **custom JSON** (holds image URLs, Markdown bodies, and typed
  fields with zero XML ceremony). Only Hugo consumes it.
- The **Hugo → world** hop emits **standard RSS/Atom + JSON Feed** — standards where they earn
  their keep (subscribers, social tools, crawlers).
- **No syndication routing in the feed.** Kit decides push targets itself; consumers never
  interpret a `syndicate` field.

### Content model: base post + `type` discriminator + typed blocks

```jsonc
{
  "id": "2026-07-15-golden-mosaic",
  "type": "release | event | festival | news", // routes layout + JSON-LD
  "slug": "golden-mosaic-return",
  "title": "Golden Mosaic is back",
  "date": "2026-07-15T09:00:00-06:00",
  "updated": "2026-07-15T09:00:00-06:00",
  "body_markdown": "...",
  "tags": ["ipa", "seasonal"],
  "images": [{ "url": "https://kit/media/abc?sig=...", "alt": "...", "role": "hero | gallery" }],

  "event": {                              // present when type=event
    "starts_at": "2026-07-18T17:00:00-06:00",
    "ends_at":   "2026-07-18T20:00:00-06:00",
    "recurrence": "FREQ=WEEKLY;BYDAY=TU", // optional iCal RRULE (trivia etc.)
    "location":  { "name": "Murphy's Market", "address": "...", "geo": {"lat":0,"lng":0} }, // omit → taproom
    "host": "The D'Arc Brothers",         // band / food truck / vendor
    "ticket_url": "...", "price": "Free"
  },

  "beer": {                               // present when type=release
    "style": "Hazy IPA", "abv": 6.8, "ibu": 40,
    "availability": ["on_tap", "crowler"],// on_tap | crowler | distro | seasonal
    "untappd_url": "...", "order_url": "https://gravitybrewing.square.site"
  }
}
```

**JSON-LD mapping** (emitted per item by the content adapter):
`release → Product`, `event → Event`, `news → BlogPosting`; a site-wide
**`Brewery`/`LocalBusiness`** (address, geo, `openingHoursSpecification`, phone) from Hugo
config powers “open now,” hours, and the map panel.

### Authoring workflow (the reason Kit beats an off-the-shelf CMS)

The intended UX — via Slack / MCP / the mobile card stack / a new **`/web` UI**:

1. **Ask** in natural language: *"Announce that for the 4th of July our hours are X and we'll be
   watching the game."*
2. **Kit drafts** a short announcement (eventually **one variant per social channel**) and
   **finds/generates an image**.
3. **Iterate conversationally** in the AI harness until it's right.
4. **Say "go"** → Kit publishes: writes the item to the announcements feed **and** triggers the
   Netlify build → live in ~30s.
5. **Later:** *"modify that 4th-of-July post"* / *"delete it"* → Kit updates/removes and rebuilds.

Design implications this locks in:
- **Drafts live entirely in Kit and never reach the website.** The JSON endpoint serves
  **published** items only — so "draft filtering at build" isn't needed; the build simply never
  sees drafts. Announcements have a real **lifecycle/state**: `draft → published → (edited →
  republished) | unpublished/deleted`, each publish/edit/unpublish firing a rebuild.
- **Per-channel social variants are Kit's concern, not the website's.** The website feed carries
  the **canonical** post only; social variants live in Kit and feed the syndication path — keeps
  the "no syndication routing in the feed" rule intact.
- **AI drafting + iteration + image-finding + multi-channel** is exactly what Decap/Markdown
  can't do → this **resolves the Phase 2.5 gate toward GO** (but we still build the site first).
- Kit needs a **`/web` management UI** (list drafts + published, edit, delete, "go") in addition
  to Slack/MCP — extra Phase-3 frontend scope beyond the API + tools.
- **Scheduled publish** ("post this, but go live July 3") is a natural extension for events —
  note for later, not v1.

### Media

**This is already built in Kit — reuse it, don't invent a `media` table.** Kit's
`internal/attachment` + `apps/attachment` already store originals as `bytea` in Postgres
(`060_attachments.sql`: `id, tenant_id, mime, size, data BYTEA`, AES-256-GCM encrypted at rest,
10 MiB cap) and serve them via a **signed deep-link token** route
(`GET /{slug}/apps/attachment/{id}?t=<token>`, 6h TTL) designed to work as `<img src>`.

So: JSON carries a signed attachment URL; Hugo downloads at build, generates all derivatives,
and self-hosts them on Netlify's CDN. Store originals only — Hugo makes every variant.
No new infra; stays on the Dokku single-VPS setup. Migration to object storage later is
transparent to the site (URL contract unchanged).
- **To decide:** the existing token binds `(user, tenant, attachment)` with a 6h TTL — fine for
  a build that runs on publish, but confirm the TTL/scope works for scheduled rebuilds, or add a
  build-scoped token.
- **EXIF:** Hugo strips EXIF from derivatives, but the **original** in Postgres retains GPS/PII —
  strip on ingest.

---

## 3. Content types breweries actually publish (drives the schema)

**Confirmed content types for Gravity** (no food trucks): `event`, `release`, `festival`, `news`.

| `type` | Covers | Structured data |
|---|---|---|
| `release` | new beer, “what's pouring” | style, ABV/IBU, availability, Untappd, order link, photo |
| `event` | live music, trivia, release party, tap takeover, tour, seasonal (Oktoberfest/anniversary/holiday hours) | date, start/end time, recurrence (RRULE), performer/host, image, optional ticket/price |
| `festival` | festivals/events Gravity **participates in off-site** | date, **non-taproom location**, link (ties to “Find Our Beers”) |
| `news` | general announcements: hours changes, awards, merch, closures, story/behind-the-scenes | title, body, image |

No food-truck modeling needed. `festival` is the old “off-site / distribution” type, renamed to match how they think about it.

### Site sections (Hugo), routed by `type`
- **What's On / Events** — upcoming, date-sorted, past auto-expire.
- **Beers / Releases** — featured-beer grid (replaces static “Our Beers”).
- **News** — story + plain announcements → generates outward RSS/Atom.
- *(optional)* **Food truck schedule** widget on the taproom page.
- Brochure pages: Welcome, Tasting Room, Food, Find Our Beers, Order Online (→ Square).

---

## 4. What the current Squarespace site is

Brochure site, minimal dynamic behavior of its own:
- Pages: Welcome, Our Beers, Tasting Room, Food, Find Our Beers, Order Online.
- **Order Online** → external Square store (`gravitybrewing.square.site`) — keep as a link.
- Google Maps embed, Untappd + social links, `mailto:`/`tel:` — all keep as-is.
- Beer list is **manually curated**, not a live feed.
- **No contact/newsletter forms** on the site — nothing to migrate there.

---

## 5. Phased build

### Phase 0 — Capture & baseline *(no build yet)*
- `wget` scrape current site for text + **original** images.
- Identify **domain registrar / where DNS lives** (likely the biggest gotcha).
- Confirm **Google Business Profile** claimed + NAP (name/address/phone) consistent — bigger
  local-discovery lever than the site itself; site must match it exactly.

### Phase 0.5 — URL inventory (do before writing any schema/redirects)
- Capture the **full current Squarespace URL list** → build a Netlify `_redirects` map so no
  inbound links/SEO equity break at DNS cutover.

### Phase 1 — Static brochure on Netlify *(shippable alone)*
- Rebuild ~5 pages in Hugo: semantic HTML, hours/address/map **in text**.
- Site-wide `LocalBusiness`/`Brewery` JSON-LD.
- `robots.txt` **allowing** AI crawlers (GPTBot, ClaudeBot, PerplexityBot, Google-Extended).
- Keep Order Online / Untappd / socials as outbound links.
- **`sitemap.xml`** (Hugo built-in), **favicon**, and default **OG/Twitter card image** —
  these directly shape the AI/social snippet the whole plan optimizes for.
- Deploy to Netlify (build on git push). Ship the `_redirects` map; preserve titles/meta.
- Enable **Netlify Analytics** (server-side, no cookie banner) to measure the machine-first bet.

### Phase 2 — Content model (announcements still hand-authored Markdown) *(meets the machine-readable goal)*
- `announcements` section: `type` discriminator, per-type layouts, per-item **JSON-LD**
  (Event/Product/BlogPosting), event date-sort + auto-expiry.
- **Start minimal:** `type` + Markdown body + a few front-matter fields; add typed `event`/`beer`
  fields only where JSON-LD demonstrably needs them.
- **Recurrence + timezone:** expand `RRULE` into N concrete upcoming instances **at build time**;
  store a **named TZ** (`America/Denver`), not a fixed offset (DST-safe).
- Per-type **OG images**; **draft** flag filtered out of production (preview via Netlify deploy previews).
- Emit **RSS/Atom + JSON Feed**; generate **`llms.txt`**.

### Phase 2.5 — GO/NO-GO: Kit vs. off-the-shelf CMS
**Leaning GO.** The desired authoring workflow (AI drafting, conversational iteration,
per-channel variants, image-finding, single "go" button — see §Authoring workflow) is exactly
what Decap/Markdown **can't** do, so Kit earns its keep. Still build Phases 0–2 first (they meet
the machine-readable goal with hand-authored Markdown) and confirm GO with the real site in front
of us before committing the Kit effort.

### Phase 3 — Kit integration *(if Phase 2.5 = GO; ~2–4 focused days + the `/web` UI)*
- **Reuse `internal/attachment` for media** (already built — see §Media).
- **New `announcements` app** (genuinely new — no existing Kit content type fits): goose
  migration (**`tenant_id UUID NOT NULL REFERENCES tenants(id)`** per house rule), models
  (tenant-filtered), service. Model the **lifecycle state** (`draft/published/unpublished`) and
  optional **per-channel social variants** (Kit-only; not in the website feed).
- **Tool surfaces (agent + MCP parity):** create-draft, edit, publish ("go"), unpublish, delete —
  plus image find/attach. Each publish/edit/unpublish fires a rebuild.
- **`/web` management UI** in Kit: list drafts + published, edit, delete, "go" button.
- **Announcements JSON endpoint** — serves **published items only**; must require a
  **shared-secret bearer token** (Netlify build env var); reject unauthenticated reads.
- Hugo content adapter fetches JSON + images at build, with a **last-good-JSON cache** fallback;
  **treat empty/first-run as valid** so a fresh Kit with no posts can't break the build.
- **Build-hook ping:** a Kit on-publish trigger does an authenticated POST to the Netlify build
  hook. Keep the **hook URL secret in Kit config** (open URL = anyone can trigger builds);
  rate-limit. Do **not** reuse the existing `netlify` OAuth app — a bare POST is simpler.

### Phase 4 — Syndication *(defer; low priority for one location)*
- Point a publishing tool (FeedHive/Publer/Buffer, RSS-in) at the site's feed, **or** Kit pushes
  directly. Add Facebook → Instagram → X (X: pay-per-use; note **$0.20 link-post surcharge**).
- A single RSS→Buffer/Publer hookup covers ~90% at near-zero cost — do that before any per-platform API work.

---

## 6. Open questions to lock
1. **Domain/DNS** — where is `thegravitybrewing.com` registered? (Phase 0 blocker.)
2. **Theme** — hand-built minimal layout (leaning this, given AI-first/lightweight goal) vs.
   adapt an existing Hugo brewery theme.
3. ~~Food trucks~~ — **resolved: none.** Types are `event`, `release`, `festival`, `news`.
4. **Schema sign-off** — *revised: start minimal (`type` + Markdown + few fields); grow typed
   `event`/`beer` blocks only as JSON-LD needs them.*
5. **Kit vs. Decap CMS (Phase 2.5 gate)** — **leaning GO on Kit**: the AI-drafting / iterate /
   per-channel / "go" workflow is Kit's whole point. Confirm with the live site before building.

---

## 7. Key facts / constraints
- Kit runs via **Dokku on a single cheap VPS** (`git push dokku main`), Postgres-centric.
  **Do not** require new infra (no buckets, no rewrite). Reusing `attachment` respects this.
- **Redis is optional at runtime** (only web-fetch caching; Kit logs "caching disabled" and
  continues without it). So "no new infra" holds — but Kit is *not* literally Postgres-only
  (Redis in compose; whisper.cpp/ffmpeg/poppler baked into the image for optional features).
- Kit today: Go app (std-lib `http.ServeMux`, Go 1.22 method+path routing), Postgres via
  `pgxpool` + **goose** embedded migrations (68 of them); apps self-register via `RegisterRoutes`
  at `/{slug}/api/<app>/...`. Interfaces = Slack, MCP, mobile PWA card stack, HTTP API.
- **House rules that tax new work** (`kit/CLAUDE.md`): every tenant-scoped table needs
  `tenant_id`; every create/edit/delete needs **both** an agent tool and an MCP tool (parity);
  `make prepush` (race tests) green; 500-line file / 60-line function caps; doc + landing updates.
- **Media store is already built** — `internal/attachment` + `apps/attachment` (encrypted bytea +
  signed serve route). Announcements, by contrast, map onto **no** existing content type
  (Skills/Cards/Memories/Tasks all differ) → genuinely new app.
- X API 2026: pay-per-use ($0.015/post, **$0.20 if it contains a link**). Facebook Pages API
  posting supported (needs never-expiring Page token + app review). Instagram is fussiest → last.
