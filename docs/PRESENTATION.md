# Kiasu Kakis: presentation notes

*"Kiasu" is Singlish for being afraid to lose out. "Kaki" means buddy. The app is your kiasu buddy for queues.*

**One-line pitch:** Kiasu Kakis doesn't tell you where to eat. It tells you how long the queue is, so you never stand in a line you didn't need to.

---

## 1. The idea in 30 seconds

- **Problem:** Singapore's best food has long queues. Google Maps shows *places*, not *waits*, and you can't queue remotely.
- **Solution:** a map and a ranked list of food places that have a queue, with the wait, its trend, how many groups are ahead, and a virtual ticket you can join from your phone.
- **Different from Google Maps:** it opens on *queues*, not on places. Only food places where a queue makes sense appear (no malls, shops or parks).
- **Honest about data:** the places are real, but **the queues are simulated**. No public Singapore queue data exists. The app is built so a real data source can replace the simulation later.

## 2. What is real and what is simulated

| Real | Simulated (and labelled "Simulated" in the app) |
|---|---|
| Map, places and locations (Apple Maps) | Wait times and their ups and downs |
| Search suggestions, ratings, reviews, opening hours, photos (Google Places) | Groups ahead, ticket numbers, ticket progress |
| Travel time (Apple Maps directions) | Which places have a queue (11 hand-picked, plus about a quarter of the rest) |
| Your location (CoreLocation) | Who can join remotely (hawker stalls cannot) |

## 3. Features

- **Map:** colour-coded wait pins (green under 15 min, amber 15 to 29, orange 30+). Places load as you move the map. Pins hide when crowded and appear as you zoom in.
- **Queue-first bottom sheet:** a ranked list of the shortest waits. Tap a place for its summary: wait, trend, "about N groups ahead", **Join queue**, **Save**, **See full details**.
- **Live queues:** waits drift in real time with trend arrows. Your ticket advances by itself: Waiting, Almost your turn, Called.
- **Demo or realistic speed:** a switch in About & Settings. Demo moves in seconds, realistic in minutes.
- **Search:** forgiving ("yakun" finds "Ya Kun"), food places only. Google autocomplete, with an Apple Maps fallback.
- **Venue details:** Google photo, rating, open now, today's hours, travel time, open in Apple Maps.
- **Join queue** with party size, **My Queues** (swipe right to save a place, swipe left to delete a finished ticket), **Saved** places.
- **Launch experience:** custom icon (light, dark, tinted), a static launch screen, and a splash with a different food by time of day (toast, noodles, boba, chilli, dumpling) and moving eyes.
- **Accessibility:** VoiceOver labels, live Dynamic Type, contrast fixes, Reduce Motion, 44 pt touch targets.
- **Offline:** an offline banner, and the app keeps working with saved data.

## 4. Demo script (about 5 minutes)

> Tip: set **About & Settings → Queue simulation speed → Demo** before starting, and do a practice run once. Have Wi-Fi on. Keep a screen recording as a backup.

| Time | Do | Say |
|---|---|---|
| 0:00 | Open the app. Let the splash play. | "Kiasu Kakis, your kiasu buddy. The eyes are the brand: watching the queue for you. The food on the splash changes with the time of day." |
| 0:30 | Show the map and the sheet at the bottom. | "It opens on queues, not on places. Pins show the wait in minutes, coloured by how long. Unlike Google Maps, it only shows food places where a queue makes sense." |
| 1:00 | Pull the sheet up, then down. | "The list is ranked by shortest wait. The numbers and arrows are live." |
| 1:30 | Tap a place (for example Song Fa Bak Kut Teh). | "Wait, trend, about how many groups ahead, and I can join from my phone. Hawker stalls like Tian Tian can't be joined remotely, so they show community reports." |
| 2:00 | Tap **See full details**. | "Photo, rating and opening hours come from Google. Travel time comes from Apple Maps." |
| 2:30 | Go back, tap **Join queue**, choose 2 people, confirm. | "A virtual ticket." |
| 3:00 | Watch the ticket. | "The queue moves by itself. Groups ahead drops, then Almost your turn, then Called. In the real world the restaurant's system would drive this." |
| 3:30 | Tap the bookmark on a place. Open **My Queues**, swipe right on a ticket. | "I can save a place from the sheet, or from a past ticket without searching again." |
| 4:00 | Search "yakun", then "tampines mall". | "Search finds food places only. Searching a mall lists the restaurants inside it. A shop returns nothing." |
| 4:30 | Move the map to Tampines. | "Places load as you move. Real places with no queue show as small grey dots." |
| 4:45 | Open About & Settings, switch to Realistic. | "Demo speed is for presentations. Realistic shows how it would feel: minutes, not seconds." |
| 5:00 | Switch phone to dark mode. | "Light and dark mode, and an icon for each." |

**If something fails:** no internet means no Google details or autocomplete, but the map, queues, tickets and saved places still work. If a search is slow, say "it's calling Google" and carry on.

## 5. Architecture (what to say about the code)

- **Pattern: VIPER.** Each screen is split into **V**iew (shows things), **I**nteractor (business logic), **P**resenter (glue, formats text), **E**ntity (data), **R**outer (navigation and wiring). Screens: Explore, Venue details, Join queue, Ticket, My Queues, Saved, Splash.
- **Services** are shared helpers behind protocols: venue repository, queue service, queue simulator, Google Places, place suggestions, location, travel time, network monitor, local store.
- **UIKit, written in code** (no storyboards). Minimum iOS 17.
- **Scale:** about 5,600 lines of Swift in 62 files, 35 commits. No compiler warnings. Automated checks on the engine pass.

### How the SOLID principles show up
| Principle | Example |
|---|---|
| **S**ingle responsibility | `SimulatedQueueCatalog` decides *which* places have queues. `QueueSimulator` handles *time*. `LegacyDataMigration` only cleans old data. `SearchText` only normalises text. |
| **O**pen/closed | Add a new queue source by writing another `QueueProfileProviding`. No screen changes. |
| **L**iskov | Any `QueueSimulating`, `PlaceSearching` or `PlaceSuggesting` can stand in for another, for example Google with an Apple Maps fallback. |
| **I**nterface segregation | Small protocols such as `LocationProviding` and `TravelTimeProviding` each do one job. |
| **D**ependency inversion | Interactors and presenters depend on protocols and get them through `init`, so they can be tested with fakes. |

### The live-queue flow
1. The simulator ticks (every 1 s in demo mode).
2. Each venue whose "reading time" has passed drifts a little. A trend is worked out from recent readings.
3. `QueueService` hears the tick and moves tickets forward.
4. It posts `queueDataDidChange`. Each presenter refreshes its screen.
5. Map pins update **in place**, which avoids flicker and keeps your selection.

### Frameworks used
- **MapKit:** `MKMapView`, custom annotation views, `MKLocalPointsOfInterestRequest`, `MKLocalSearch`, `MKDirections`.
- **CoreLocation:** `CLLocationManager`, permission flow, `async/await` wrapper.
- **Network:** `NWPathMonitor` for the offline banner.
- **UIKit:** diffable-free tables, Auto Layout, `UIConfigurationTextAttributesTransformer`, gesture recognisers, Dynamic Type (`UIFontMetrics`).
- **Core Animation:** the moving eyes and the loading dots.
- **Foundation:** `URLSession` + `Codable` for the Google Places API (New), `async/await`, `Task` cancellation.
- **Google Places API (New):** autocomplete, place details, photos. A field mask keeps each request cheap. Responses are cached for 24 hours.

## 6. Design decisions ("why did you…")

- **Why eyes?** Being kiasu is a look: watching the queue. Eyes avoid clichés (no map pin, ticket or merlion), work at tiny sizes and in one colour, and "kaki" means buddy. The same eyes can sit on different foods, and later on a mascot body.
- **Why a quarter of places, not all?** More than that floods the map. The number is one setting (`SimulatedQueueCatalog(share:)`).
- **Why food-only?** A queue app for a shoe shop makes no sense. Malls show the food places inside them.
- **Why simulated?** There is no public Singapore queue data. It is clearly labelled so nobody is misled.
- **Why cream and crimson, not red and white?** Pure white with red looks like the national flag. Cream is warmer, and a lighter red is used in dark mode so it stays readable.
- **Why Save at the top-left and Close at the top-right?** They are as far apart as possible, so neither is tapped by mistake.

## 7. Problems we hit and how we solved them (good for "progress and problems")

| Problem | Cause | Fix |
|---|---|---|
| Crash on launch | Two saved places had the same id and the map tried to build a dictionary with duplicate keys | De-duplicate when saving and loading, and make the map tolerate duplicates |
| Places didn't load when the map moved | Apple's text search treats the region as a hint and kept returning city-centre results | Switched to `MKLocalPointsOfInterestRequest`, which searches a real circle |
| Search too slow | One slow Apple request blocked the rest | Stream results per request, shorter debounce, search a wider area, cache searched areas |
| Locate button went to California | The simulator's default location | Zoom to 1 km, wait for the first fix, warn when outside Singapore |
| Close button only worked sometimes | A later view covered part of it | Bring it to the front, and checked with a hit test at four points |
| Save button did nothing | Built but never connected | Wired up and verified |
| Grey text hard to read | Secondary grey was 3.15:1 on cream (needs 4.5) | Warmer, darker grey (5.6:1). Darkened green and orange pins for white text |
| Malls, supermarkets and shops on the map | "Food market" category included them | Dropped it. Food-only categories and a food-only Google filter |
| Pins piled up in the city | A quarter of hundreds of places | Hide overlapping pins until zoom, cap the list at 40 |
| Old fictional places left on phones | Early versions used made-up venues | One-time cleanup (`LegacyDataMigration`) |
| App icon didn't change in dark mode | iOS: needs Customize → Automatic | Not a bug. Documented |

## 8. Testing

- **Automated checks on the engine (24):** wait ranges, trends, the same place always getting the same answer, about 25% share, repository marking, joining rules, ticket catch-up after a gap, notifications.
- **Simulator walkthrough (full app):** launch, map, search, sheet states, join, ticket progress, My Queues, Saved, details, About, dark mode, largest text, first-launch notice. No crash reports.
- **Builds:** Debug and Release build with no warnings.
- **Not covered:** an automated UI test target (the project has none), VoiceOver on a real device, and heavy-use performance.

## 9. Known limitations (say these before someone asks)

- Queues are simulated. Real places have no queue data.
- Party size is capped at 8 (a demo limit). Real venues would set their own.
- Groups ahead doesn't change with party size yet.
- Pull-up details in the sheet are not built. Details are on their own page.
- The Saved page has no search or filters yet.
- Google needs an API key. The free tier is limited. Results are cached to stay under it.
- The Google API key sits in a git-ignored file and ends up inside the built app. In production it should sit behind a server.
- No push notifications ("it's your turn") yet.

## 10. What's next (expansion)

1. **Real queue data:** implement `QueueProfileProviding` (or replace the simulator) with a venue API. Screens don't change.
2. **Saved page:** search and category tabs, so a long list stays manageable.
3. **Cuisine filters** (needs a data source for cuisine).
4. **Pull-up details in the sheet:** wait-trend chart, rating, hours, travel time. Keep the photo on the details page to hold API costs down.
5. **Party-size-aware queues:** "party of 2: 3 groups ahead", with different lanes for small and large tables.
6. **Notifications** when your turn is close, and a "leave now" countdown from travel time.
7. **Settings:** alternate app icons, light/dark/system theme, default maps app (Apple or Google), clear history.
8. **Menus:** a "Menu / Website" link from Google.

## 11. Likely questions, with answers

- **"Is the queue data real?"** No, it's simulated and labelled. There's no public Singapore data. The app is built to swap in a real source.
- **"How is it different from Google Maps?"** Google shows places. This shows waits and lets you join a queue, so it opens on queues and only shows food places.
- **"Why VIPER?"** It keeps each screen's responsibilities separate, and every layer talks through protocols, so pieces can be swapped and tested.
- **"What does Google cost?"** Only the autocomplete and place details calls cost anything. Results are cached for 24 hours, and the free tier covers the demo. MapKit is free.
- **"How do you protect the API key?"** It's kept out of git in `Secrets.xcconfig`. A real release would use a server so the key isn't in the app.
- **"What about privacy?"** Location is only used while the app is open, for travel time and the map dot. Nothing is sent to a server of ours. Tickets and saved places stay on the phone.
- **"How did you handle accessibility?"** VoiceOver labels (pins read "name, 15 min rising wait"), Dynamic Type that updates live, contrast fixed to 4.5:1, Reduce Motion, 44 pt targets.
- **"What would you do with another week?"** Real data integration, notifications, the Saved page filters, party-size-aware queues.

## 12. Milestones and commits

| # | Milestone | Commit |
|---|---|---|
| 1 | Foundation: VIPER, tabs, theme | `2cf01dd` |
| 2 | Explore map | `80b99d2` |
| 3 | Venue details | `9560c16` |
| 4 | Join queue and My Queues | `42e0a60` |
| 5 | Local persistence | `4235a1b` |
| 6 | Saved tab and empty states | `44e4c56` |
| 7 | Auto-search places as the map moves | `02783ec` |
| 8 | Locate button and faster pins | `0af6c6a` |
| 9 | Icon, launch screen, time-of-day splash | `05231b1` |
| 10 | Google Places: rating, hours, photo | `470d6c5` |
| 11 | Search with autocomplete | `b3526d9` |
| 12 | Live queue engine (demo and realistic speeds) | `0e3dcfd` |
| 13 | Accessibility | `401c803` |
| 14 | Map search fix | `df3bc63` |
| 15 | Food-only map, 12 real queue places | `d365dca` |
| 16 | Queue-first bottom sheet | `53b860f` |
| – | Simulated queues for any place | `e66706d` |
| – | Save, delete and swipe actions, polish | `57be5e8`, `0392914`, `356a7a7` |

## 13. Running it

1. Open `kiasu kakis.xcodeproj` in Xcode 26, iOS 17 or later.
2. Copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and put the Google Places API key after the equals sign. Without it the app still works, with Apple Maps data only.
3. Set your Team under Signing & Capabilities to run on a phone.
4. Build and run. In the simulator, set a Singapore location (Features → Location → Custom Location 1.30, 103.84).
