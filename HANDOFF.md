# HABITFORGE — PROJECT HANDOFF

> **Read this file first before touching any code.**
> This file lives at the root of the Xcode project folder (next to `HabitForge.xcodeproj`).
> It is the single source of truth for project state, conventions, and next steps.
>
> **Snapshot date:** September 2026 (updated after Workouts module implementation)
> **Verify before trusting:** This document describes the state at handoff. Before making
> changes, run `xcodebuild` (see Build section) and read the actual files. If this document
> and the code disagree, **the code wins** — then update this file.

---

## 1. WHAT THIS APP IS

**HabitForge** is a native iOS app that merges three product categories into one:

| Module | Inspired by | Purpose |
|--------|-------------|---------|
| Habits | Streaks | Daily habit tracking with rings, streaks, charts |
| Todos | Things 3 | GTD task management with projects and areas |
| Workouts | Strong / Strong Pro | Custom routines, set logging, progress graphs |

Built for personal use first, with a planned App Store release on a freemium
subscription model.

**Owner:** Praveet Gupta
**Bundle ID:** `com.praveetgupta.HabitForge`
**Target:** iOS 17.0+
**Signing:** Free personal Apple Developer team (see Constraints)

---

## 2. TECH STACK

| Layer | Technology | Status |
|-------|-----------|--------|
| UI | SwiftUI | In use |
| Persistence | SwiftData (`@Model`) | In use |
| Architecture | MVVM with `@Observable` view models | In use |
| Charts | Swift Charts (built into iOS 16+, no package) | In use |
| Notifications | `UserNotifications` (local only) | Working for habits |
| Auth | Firebase Auth | **Not integrated — stub only** |
| Subscriptions | RevenueCat | **Not integrated — stub only** |
| Cloud sync | CloudKit | **Not integrated — disabled on purpose** |

No third-party Swift packages are currently installed. Everything is first-party Apple
frameworks. Do not add dependencies without a clear reason.

---

## 3. CURRENT STATE

### ✅ DONE — Habits module (fully functional)

- Dashboard: overall "X of Y today" summary ring, then a 3-column grid of habit rings,
  then the overall progress graph at the bottom (in that vertical order).
- Habit types: **Build** (do it) and **Break** (avoid it).
- Three tracking modes:
  - **Simple** — tap ring to toggle complete.
  - **Count** — tap ring to increment (e.g. 8 glasses of water); context menu to decrement.
  - **Duration** — tap ring opens a full-screen timer; ring fills toward the target.
- Frequencies: `"Daily"`, `"Times per Week"`, `"Times per Month"` (stored as `String`).
- Scheduling by weekday; pause/resume; archive.
- Streaks: current + best, recalculated on every entry change.
- Calendar heatmap (month view), per-habit charts (7/14/30/90 day toggles),
  and a combined all-habits progress graph with per-habit sparklines.
- Notes and mood per daily entry.
- Local notification reminders — **verified working on device**.
- Custom emoji: preset grid *plus* a free-text field so the iOS emoji keyboard works.

### ✅ DONE — Todos module (fully functional)

- Full GTD flow: Inbox → Today → Upcoming → Anytime → Someday → Logbook (+ Trash).
- Two-date model: `whenDate` (when you plan to start) vs `deadline` (hard due date).
- `autoPromoteUpcoming()` moves scheduled todos into Today when their date arrives.
- Areas → Projects → Headings → Todos → Checklist items.
- **AreaView** — tapping an area in the sidebar opens a dedicated screen: loose todos
  (swipe-to-complete, context menus), its projects with progress rings, completed
  loose tasks, "Add Task" (Quick Add pre-assigned to the area), and "New Project in Area".
- Project progress bars; headings as section dividers.
- Quick Add ("magic plus") with destination chips: Inbox / Today / Evening / Tomorrow /
  Next Week; return key saves and keeps focus for rapid entry with an "N added" counter.
- Quick Add sheet uses `.presentationDetents([.medium, .large])` (fixed-height detent
  clipped the bottom bar — do not go back to `.height(...)`). A trailing
  `Spacer(minLength: 0)` pins the content to the top of the sheet; without it the
  fixed-height rows float mid-sheet at the medium detent.
- **Global Quick Add** — floating "+" FAB on the Habits, Workouts, and Settings tabs
  (added in `MainTabView`); opens QuickAddView with Inbox as the default destination.
  The Todos tab keeps its own per-view buttons. The FAB is bottom-padded to clear the
  tab bar (64pt above the safe area) so it never covers the Settings icon.
- Repeating todos: on completion, `createNextOccurrence()` spawns the next instance.
- Tags, priority flags (0–3), evening section in Today, swipe actions, drag-to-reorder,
  search across title/notes/tags, Logbook grouped by completion date.

### ✅ DONE — Workouts module (implemented September 2026)

- **Exercise library seeding** — `Services/ExerciseSeedData.swift` inserts 88 exercises
  (12 muscle groups × Barbell/Dumbbell/Machine/Cable/Bodyweight/Kettlebell/Smith/Other)
  on first launch when the `Exercise` table is empty. Called from `HabitForgeApp.task`
  and defensively from `WorkoutViewModel.init`; both paths are idempotent.
  **Verified on simulator: 88 rows, no duplicates.**
- **WorkoutViewModel** — complete: routine CRUD (create/update/archive/delete),
  routine exercise add/remove/reorder, `searchExercises(query:muscleFilter:equipmentFilter:)`,
  `createCustomExercise`, `startSession(from:)` (pre-populates sets, auto-fills each
  set's weight from the last completed session of that exercise), `startEmptySession()`,
  `completeSet` (PR detection vs `Exercise.prMaxWeight`, volume recalc, rest timer start),
  `addSet` (copies previous set), `removeSet` (renumbers), `finishSession`, `discardSession`,
  rest timer with ±15s adjust and skip, `getExerciseHistory(for:limit:)`, `previousWeights`,
  `getLastWeight`, `recentPRSets`.
- **WorkoutDashboardView** — resume banner when a session is in progress, routine cards
  (long-press → edit/archive confirmation dialog, per handoff gotcha #2), Start Workout,
  recent sessions, empty state with "New Routine" action. Toolbar: Progress (chart icon),
  "+" menu (New Routine / Empty Workout / History).
- **CreateRoutineView** — create *and* edit (same view, optional `routine` param).
  Name, emoji presets + free text, 8-color picker grid, exercise list with per-exercise
  defaults editor (`RoutineExerciseEditorView`: sets/reps/weight/rest/superset tag),
  reorder via EditButton + onMove, swipe to delete. In create mode a draft Routine is
  inserted when the first exercise is added; cancelling deletes the draft.
- **ExercisePickerView** — search, muscle-group and equipment filter menus in the bottom
  bar, tap row to select, chart icon navigates to that exercise's history,
  "+" opens `CreateCustomExerciseView` (name/muscle/equipment/type).
- **ActiveWorkoutView** — full-screen (`fullScreenCover`, `interactiveDismissDisabled`).
  Live session clock (`TimelineView`), one card per exercise with the
  `SET | PREVIOUS | KG | REPS | ✓` grid, PREVIOUS shows last session's weight per set
  index, completed sets tint green, PR badge under the checkmark, "+ Add Set" per
  exercise, trash to remove an exercise, "+ Add Exercise", rest-timer bar overlay with
  −15s/+15s/skip, Finish (→ summary) and Discard (confirmation dialog).
- **WorkoutSummaryView** — post-session sheet: icon/name, duration/volume/PRs/exercises
  stat cells, per-exercise set counts, 4-emoji mood picker saved on the session.
- **ExerciseDetailView** — best-weight/best-volume/sessions/sets stat row, weight-over-time
  line chart + volume-over-time bar chart (Swift Charts, shown from 2 sessions),
  session-by-session list. Reached from the picker's chart icon.
- **WorkoutHistoryView / SessionDetailView** — history grouped by month; session detail
  shows stats, all sets per exercise with PR tags, editable notes (auto-saves).
- **WorkoutProgressView** — totals row, 8-week volume bar chart, recent PRs list.
  Reached from the dashboard toolbar chart icon.
- **UI tests** — `HabitForgeUITests/WorkoutFlowUITests.swift` covers the whole chain
  self-contained (creates "QA Routine" through the UI → logs a set → verifies ±15s and
  skip on the rest timer → finish → summary sheet → history → progress). Run with:

  ```bash
  xcodebuild test -project HabitForge.xcodeproj -scheme HabitForge \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:HabitForgeUITests/WorkoutFlowUITests
  ```

  Note: UI tests always run against a fresh app container, so they must never depend
  on pre-existing data. Key accessibility identifiers/labels used by tests (and
  VoiceOver): `routineNameField`, `restCountdown`, "Complete set N", "Skip rest",
  "Resume workout in progress", "Workout menu", "Close". Keep them intact.
- **Accessibility labels** — workout set checkmarks, weight/reps fields, rest-timer
  controls, and the discard button all carry labels; the global FAB is reachable as
  "Add". Extend this pattern to new controls.

### 📋 NOT STARTED

- Firebase Auth (email + Sign in with Apple).
- RevenueCat paywall and subscription gating.
- Onboarding flow.
- Settings screens beyond placeholders.
- App Store assets, TestFlight, submission.

---

## 4. FILE MAP

```
HabitForge/
├── App/
│   ├── HabitForgeApp.swift        @main; registers all 14 models in .modelContainer;
│   │                              .task requests notification permission;
│   │                              .task seeds the exercise library
│   └── MainTabView.swift          4 tabs (tagged AppTab enum); global Quick Add FAB
│                                  on non-Todos tabs; habit reminder rescheduling
│
├── Models/                        SwiftData @Model classes — 14 total
│   ├── Habit.swift                habitType/frequency stored as String, not enum
│   ├── HabitEntry.swift           one per habit per day; duration/count/note/mood
│   ├── Todo.swift                 status/priority as String/Int; when vs deadline
│   ├── ChecklistItem.swift
│   ├── Area.swift
│   ├── Project.swift              has computed progressFraction
│   ├── ProjectHeading.swift
│   ├── Tag.swift
│   ├── Routine.swift              workout template
│   ├── Exercise.swift             library entry; tracks PRs
│   ├── RoutineExercise.swift      exercise + defaults inside a routine
│   ├── WorkoutSession.swift       a logged workout
│   ├── PerformedExercise.swift    an exercise as performed in a session
│   └── PerformedSet.swift         one set: reps, weight, type, isPR
│
├── ViewModels/
│   ├── HabitViewModel.swift       COMPLETE
│   ├── TodoViewModel.swift        COMPLETE
│   ├── WorkoutViewModel.swift     COMPLETE
│   └── AuthViewModel.swift        STUB
│
├── Views/
│   ├── Habits/                    COMPLETE
│   │   HabitDashboardView, HabitRingView, HabitDetailView, AddHabitView,
│   │   HabitCalendarView, HabitChartView, HabitTimerView, HabitOverallGraphView
│   ├── Todos/                     COMPLETE
│   │   TodoSidebarView, TodayView, InboxView, UpcomingView, AnytimeView,
│   │   SomedayView, LogbookView, AreaView, TodoDetailView, QuickAddView,
│   │   ProjectView, TodoRowView
│   │   (+ shared: ScheduleTodoSheet, ProjectPickerSheet, TagPickerSheet,
│   │   TodoContextMenu — defined inside QuickAddView.swift)
│   ├── Workouts/                  COMPLETE
│   │   WorkoutDashboardView (+ RoutineCardView, SessionRowView),
│   │   CreateRoutineView (+ RoutineExerciseEditorView), ExercisePickerView
│   │   (+ CreateCustomExerciseView), ActiveWorkoutView (+ ActiveExerciseCard,
│   │   SetLogRow, RestTimerBar), WorkoutSummaryView, ExerciseDetailView,
│   │   WorkoutHistoryView (+ SessionDetailView), WorkoutProgressView
│   ├── Settings/                  STUBS — SettingsView, SubscriptionView
│   └── Auth/                      STUB — LoginView

HabitForgeUITests/
└── WorkoutFlowUITests.swift       end-to-end workout flow tests (self-contained)
│   ├── Settings/                  STUBS — SettingsView, SubscriptionView
│   └── Auth/                      STUB — LoginView
│
├── Services/
│   ├── NotificationService.swift  WORKING for habits; todo path exists
│   ├── ExerciseSeedData.swift     88-exercise seed library; idempotent
│   ├── AuthService.swift          STUB
│   └── SubscriptionService.swift  STUB
│
├── Components/
│   ├── ProgressRingView.swift     reusable ring; used by dashboard summary
│   └── EmptyStateView.swift
│
└── Extensions/
    ├── Color+Hex.swift            Color(hex:) — used everywhere for habit colors
    └── Date+Helpers.swift         startOfDay, isToday, relativeDescription, etc.
```

---

## 5. CONVENTIONS — FOLLOW THESE

**Enums are stored as `String` / `Int` on the models, not as Swift enum types.**
SwiftData `#Predicate` cannot filter on custom enums cleanly, so models store raw values
and compare against string literals. Match the exact casing:

- `Habit.habitType` → `"Build"` | `"Break"`
- `Habit.frequency` → `"Daily"` | `"Times per Week"` | `"Times per Month"`
- `Todo.status` → `"Inbox"` | `"Today"` | `"Upcoming"` | `"Anytime"` | `"Someday"` | `"Logbook"` | `"Trash"`
- `Todo.priority` → `Int` 0=none, 1=low, 2=medium, 3=high
- `Project.status` → `"Active"` | `"Completed"` | `"On Hold"` | `"Dropped"`
- `Exercise.exerciseType` → `"Weighted"` | `"Bodyweight"` | `"Timed"` | `"Cardio"`
- `PerformedSet.setType` → `"Warmup"` | `"Working"` | `"Drop Set"` | `"To Failure"`
- Exercise muscle groups and equipment types → canonical lists live in
  `ExerciseSeedData.muscleGroups` / `.equipmentTypes`; reuse them instead of retyping.

A typo in one of these strings fails silently at runtime. Grep before inventing a value.

**Weekdays are 1 = Monday … 7 = Sunday.** Apple's `Calendar` uses 1 = Sunday, so the code
remaps: `isoWeekday = (weekday == 1) ? 7 : weekday - 1`. An **empty** `scheduledDays`
array means *every day*, not *no days*. The Add Habit form converts "all seven selected"
back into an empty array on save.

**Views own a `@Query`; the ViewModel receives the results.** Dashboards declare
`@Query` for live SwiftData updates, then push the array into the view model via
`.onAppear` and `.onChange(of:)`. Do not fetch in the view model and expect the UI to
refresh on its own. (Workout views instead read models directly — SwiftData `@Model`
objects are observable, so set/PR/volume mutations refresh the UI without a re-fetch.)

**View models are `@Observable` classes initialised with a `ModelContext`**, created lazily
in `.onAppear` and held in `@State`. They call `try? modelContext.save()` after mutations.

**Colors come from hex strings** on the models via `Color(hex:)`. Do not hardcode colors
in views for anything habit- or routine-specific.

**Dark mode is the primary design target.** Branding leans "old money": deep near-black
backgrounds, gold accents (`#C9A84C`, `#D4AF61`, `#E8C96B`), serif type for the wordmark.

---

## 6. KNOWN GOTCHAS — THESE COST HOURS ALREADY

1. **`.sheet(isPresented:)` + a separately-set item = blank form on first open.**
   Setting `itemToEdit = x` and `showingSheet = true` in the same frame loses the item.
   Use **two sheets**: `.sheet(isPresented:)` for "new", `.sheet(item:)` for "edit".
   This bug was hit on the habit edit flow; do not reintroduce it in Todos or Workouts.
   (WorkoutDashboardView follows the rule for routine editing.)

2. **`contextMenu` always draws a lifted preview box.** It cannot be fully removed. The
   habit rings and the routine cards use **`confirmationDialog`** triggered by
   `.onLongPressGesture` instead. Follow that pattern for any new long-press menus.

3. **`ShapeStyle` vs `Color` type mismatch.** `.foregroundStyle(cond ? .primary : .tertiary)`
   fails to compile. Always write the ternary with explicit types:
   `.foregroundStyle(cond ? Color.primary : Color.secondary)`.
   `Color.tertiary` does not exist — use `Color(UIColor.tertiaryLabel)` or `.secondary`.

4. **Free Apple Developer team cannot use Push Notifications or iCloud.** Both
   capabilities are removed from the target on purpose, and the model container is plain
   local storage (no CloudKit). Re-enabling either breaks device builds until the paid
   ($99/yr) program is active. Local notifications still work — they need no capability.

5. **Notifications only appear when the app is backgrounded.** Test by saving a reminder
   ~2 minutes out, then swiping the app away. Permission is requested in a `.task` on
   `MainTabView`; the console prints `🔔 Notification permission granted: true`.

6. **`IOSurfaceClientSetSurfaceNotify failed e00002c7`** in the console is harmless
   simulator noise. Ignore it.

7. **A habit will not toggle if today is not in its `scheduledDays`.** `toggleHabit` and
   `progressFraction` both guard on `isScheduled`. This looks like a broken tap; it isn't.

8. **Periodic habits (weekly/monthly) allow one completion per day**, and the daily
   summary counts them as "done today" if tapped today — even at 1 of 3 for the week.
   Do not change this back to requiring the full weekly target.

9. **`TextField(value:format:)` rejects optional bindings.** `Binding<Double?>` /
   `Binding<Int?>` will not compile — wrap in a custom binding
   (`Binding(get: { set.weightKg ?? 0 }, set: { set.weightKg = $0 })`).
   Hit in `SetLogRow` and `RoutineExerciseEditorView`. Do not "simplify" these back.

10. **First-ever logged weight on an exercise always counts as a PR** (`weight > prMaxWeight ?? 0`).
    This is intentional (Strong behaves the same). Weightless exercises (bodyweight/timed/
    cardio) never generate PRs because the guard requires `weight > 0`.

11. **`xcodebuild -destination 'generic/platform=iOS'` fails on signing** with the free
    team. Build against the simulator instead:
    `-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.

12. **UI tests always get a fresh app container** (even with parallel testing off, the
    runner may clone the device). Never write tests that assume existing routines or
    habits — create data through the UI first, as `WorkoutFlowUITests` does.

13. **SwiftUI TextField placeholders get rewritten by Form sections** — a
    `TextField("Routine name")` can surface as placeholder 'Name' in the accessibility
    tree. Query by `.accessibilityIdentifier`, not by placeholder text.

---

## 7. BUILD & RUN

Editing happens in any editor; **compiling only happens in Xcode.** After every code
change the app must be rebuilt.

```bash
# Verify a build from the command line (simulator destination — no signing needed)
cd /path/to/HabitForge
xcodebuild -project HabitForge.xcodeproj \
           -scheme HabitForge \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build
```

For interactive testing: open `HabitForge.xcodeproj` in Xcode and press **⌘R**.
Physical device used for testing is an iPhone; the simulator target is iPhone 17 Pro.

**Workflow contract for the incoming agent:**
1. Read the relevant files before editing — do not write from this document alone.
2. Make one coherent change at a time.
3. Run `xcodebuild` and fix errors before reporting done.
4. Summarise what changed, file by file.
5. Update Section 3 of this file when a milestone moves from "not started" to "done".

---

## 8. WORKOUTS MODULE — IMPLEMENTATION NOTES (was: full spec)

The module is implemented; this section now documents how it fits together and how to
regression-test it.

### Design principle (unchanged)
**No fixed splits.** The user creates any routine they want — Push/Pull/Legs,
Upper/Lower, Full Body, a five-day bro split, whatever. A routine is a reusable template;
a session is one performance of it.

### Data flow
- `HabitForgeApp.task` → `ExerciseSeedData.seedIfNeeded(modelContext:)` on launch (idempotent).
- `WorkoutDashboardView.onAppear` lazily creates `WorkoutViewModel` (also seeds defensively).
- `startSession(from:)` copies `RoutineExercise` templates into `PerformedExercise` +
  empty `PerformedSet`s, pre-filling each set's weight from the most recent completed
  session of that exercise (`previousWeights`), falling back to the routine default.
- `completeSet` stamps the set, checks `weight > exercise.prMaxWeight` (PR badge +
  `session.numberOfPRs += 1`), recalculates `session.totalVolumeKg`, restarts the rest
  timer using the routine's `restSeconds` for that exercise (default 90).
- `finishSession` stamps end time/duration, marks `isCompleted`, updates the routine's
  `lastPerformedAt`, and hands the session back so the dashboard can present
  `WorkoutSummaryView` ~0.6s later (after the full-screen cover dismisses).

### Acceptance check (run after any Workouts change)
Create a routine → add three exercises → start a workout → log sets → observe the rest
timer (−15s/+15s/skip) → finish → see the summary with mood picker → open the same
exercise from the picker and confirm its progress chart and history are populated →
start a second session and confirm the PREVIOUS column shows the first session's weights.

### Deliberate v1 limitations
- PRs are weight-based only (no reps-PR or 1RM estimation).
- No per-set `setType` UI (warmup/drop set) — the field exists on the model.
- Superset tags display on rows but do not yet auto-queue rest timers between paired
  exercises.
- No rest-timer notification when the app is backgrounded (local-notifications hook is
  the obvious future addition).

---

## 9. NEXT TASKS

In rough order:

1. **Auth** — Firebase Auth with email + Sign in with Apple; gate the app behind
   `AuthViewModel.isAuthenticated`. Add `GoogleService-Info.plist` (not committed).
2. **Subscriptions** — RevenueCat. Free tier: 3 habits, basic todos, 3 routines, 30-day
   history. Pro ($4.99/mo, $39.99/yr): unlimited everything, custom exercises, full
   history, advanced charts, export, cloud sync.
3. **Onboarding** — 3–4 screens explaining the three modules.
4. **Settings** — profile, units (kg/lb), notification preferences, data export.
5. **Ship** — paid developer account, App Store Connect listing, screenshots for 6.7"
   and 6.5", privacy policy, TestFlight, submit.

---

## 10. THINGS NOT TO DO

- Do not add CloudKit or Push Notification capabilities while on the free team.
- Do not convert the model string fields to Swift enums without also rewriting every
  `#Predicate` that filters on them.
- Do not replace `confirmationDialog` long-press menus with `contextMenu`.
- Do not rewrite the Habits or Todos modules; they are done and tested. Touch them only
  to fix a specific reported bug.
- Do not commit `GoogleService-Info.plist` or any signing assets.
- Do not add Swift packages beyond Firebase and RevenueCat when those milestones arrive.
- Do not put a fixed `.height(...)` detent back on QuickAddView — it clips.

---

## 11. `.gitignore`

```
*.xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/
*.ipa
*.dSYM.zip
GoogleService-Info.plist
Pods/
.build/
.swiftpm/
.DS_Store
```
