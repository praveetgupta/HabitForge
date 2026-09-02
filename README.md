<p align="center">
  <img src="HabitForge/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" alt="HabitForge icon">
</p>

# HabitForge

**Habits, todos, and workouts — one native iOS app.**

HabitForge merges three product categories that usually live in three separate apps:
Streaks-style habit tracking, Things 3-style task management, and Strong-style workout
logging. Built natively in SwiftUI with SwiftData, designed dark-first with an
"old money" gold-on-near-black aesthetic.

| Habits | Todos | Workouts | Active workout |
|---|---|---|---|
| ![Habits](screenshots/habits.png) | ![Todos](screenshots/todos.png) | ![Workouts](screenshots/workouts.png) | ![Active workout](screenshots/active-workout.png) |

## Modules

### 🔥 Habits
- Daily dashboard: overall completion ring, habit ring grid, all-habits progress graph
- **Build** and **Break** habit types with daily / weekly / monthly frequencies
- Three tracking modes: simple toggle, count (e.g. 8 glasses of water), and duration
  with a full-screen timer
- Current + best streaks, month calendar heatmap, 7/14/30/90-day charts
- Per-entry notes and mood, weekday scheduling, pause/resume, archive
- Local notification reminders

### ✅ Todos
- Full GTD flow: **Inbox → Today → Upcoming → Anytime → Someday → Logbook**
- Two-date model: *when* you plan to start vs. hard *deadlines*
- Areas → Projects → Headings → Todos → Checklists, with project progress rings
- Repeating todos that spawn their next occurrence on completion
- Quick Add with destination chips (Inbox / Today / Evening / Tomorrow / Next Week) and
  rapid multi-entry ("N added"); a floating "+" is available from every tab
- Tags, priority flags, evening section, swipe actions, drag-to-reorder, search

### 🏋️ Workouts
- **No fixed splits** — build any routine (PPL, Upper/Lower, full body, whatever)
- 88-exercise seeded library across 12 muscle groups, filterable by muscle and
  equipment; custom exercises supported
- Active workout screen: live session clock, `SET | PREVIOUS | KG | REPS | ✓` grid,
  weights auto-filled from your last session
- PR detection with badges, automatic volume totals, per-set rest timer with ±15s / skip
- Post-session summary with mood, per-exercise history charts (weight & volume),
  session history grouped by month, 8-week volume progress

## Tech

| | |
|---|---|
| UI | SwiftUI, Swift Charts |
| Persistence | SwiftData (14 `@Model` classes, local store) |
| Architecture | MVVM with `@Observable` view models |
| Target | iOS 17+ |
| Dependencies | None — first-party frameworks only |

Views own `@Query` for live updates and push results into view models; view models are
`@Observable` classes initialised with a `ModelContext`. Enum-like fields are stored as
raw strings (SwiftData `#Predicate` limitation) — the canonical value lists live in
[HANDOFF.md](HANDOFF.md).

## Building

```bash
xcodebuild -project HabitForge.xcodeproj \
           -scheme HabitForge \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build
```

Or open `HabitForge.xcodeproj` in Xcode and press ⌘R. The project uses automatic
signing with a free personal Apple ID — device builds need
`-allowProvisioningUpdates` and stay valid for **7 days** (free-account limitation).

## Testing

End-to-end UI tests cover the full workout flow (routine creation → set logging →
rest-timer adjust/skip → finish → summary → history/progress). They are self-contained
and pass against a fresh app container:

```bash
xcodebuild test -project HabitForge.xcodeproj \
                -scheme HabitForge \
                -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
                -only-testing:HabitForgeUITests/WorkoutFlowUITests
```

The app icon is generated code — tweak and re-run `make_icon.swift` (a CoreGraphics
script) rather than hand-editing the PNG.

## Roadmap

- Firebase Auth (email + Sign in with Apple)
- RevenueCat freemium paywall (free: 3 habits / 3 routines / 30-day history)
- Onboarding, settings (units, export), App Store release
