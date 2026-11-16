# Kiasu Kakis · launch website

A standalone, animated marketing site for the Kiasu Kakis iOS app. It is separate from the iOS project: nothing in the app's source, config or assets was changed. Screenshots and a few icons were **copied** into `public/`.

**Story:** *Life's too short to queue.* Hero → Singapore queue scene (scroll-driven) → Meet the app (pinned phone walkthrough) → Interactive demo → What you can do while waiting → Features → Final CTA.

**Stack:** React + TypeScript + Vite, GSAP + ScrollTrigger (scroll timelines), Motion (UI springs), React Three Fiber (hero 3D phone), CSS/SVG for everything else. No backend, no paid services, no API keys.

## Run it

```bash
cd website
npm install
npm run dev      # http://localhost:5173
npm run build    # outputs website/dist
npm run preview  # serve the production build
```

Requires Node 18+.

## Update the launch status

Edit [`src/launch.ts`](src/launch.ts). It is the only place the call-to-action reads from.

```ts
released: true,
appStoreUrl: 'https://apps.apple.com/app/idXXXXXXXXX',
```

While `released` is `false`, the CTA shows "Coming soon to the App Store" and is not a link. There is no fake listing, user count, testimonial or launch date.

## Replace app screenshots

Screens live in `public/screens/*.jpg` (600×1304). Overwrite a file with the same name to update it everywhere. Which screens appear where is set in [`src/content.ts`](src/content.ts):

- `walkthrough`: the 4 pinned phone steps, including the highlight ring position (`hot.x`, `hot.y` in % of the screen) and label.
- `features`: the feature cards.
- The waiting scene uses `ticket1`, `ticket2`, `ticket3`; the hero uses `map`; the final section uses `ticket3`.

## Change content

- Copy and structure: `src/components/*.tsx` (one file per scene).
- Demo venues and waits: `venues` in `src/content.ts`. These are fictional demo data and are labelled as such on screen.
- Colours: CSS variables at the top of `src/styles.css`. They mirror the app's `Theme.swift` (brand `#BD091C`, cream `#FBF4EA`, wait colours green/amber/orange, dark mode).
- Illustrated scenes for the waiting sequence: `src/components/Scenery.tsx` (original SVG).

## What is real vs simulated

Same as the app: places are real, **queues are simulated**. The site says so, and the interactive demo is a self-contained simulation that never contacts a business or backend. The "On the way" note about real restaurant data is marked as planned, not available.

## Performance and accessibility

- The 3D hero phone is lazy-loaded, capped at 1.5× pixel ratio and pauses when off screen. It is used only on desktop with WebGL and without reduced motion; otherwise a CSS phone with the same screenshot is shown.
- `prefers-reduced-motion`: no intro, no pinned/scrubbed scenes, static layouts, near-zero animation.
- Skip link, semantic headings, keyboard-operable demo, light/dark toggle (follows the system by default), sound off by default. The "Your turn, kaki!" chime is synthesised in the browser and only plays if the visitor turns sound on.

## Hosting

`vite.config.ts` uses a relative `base`, so `dist/` works from any path. For GitHub Pages, publish the contents of `website/dist`. The repo's existing `docs/` site is untouched; to replace it with this site, copy `dist/` into `docs/` (keep `.nojekyll`).

## Assumptions

- The feature list and flow come from the iOS project, its README and the existing docs site (map, queue list, details, join with party size, My Queues ticket with Waiting/Almost/Called/Done, saved places, search, dark mode, accessibility).
- Demo wait colours follow the app: 15 min or less green, under 30 amber, 30+ orange.
