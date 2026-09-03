# Contributing to HabitForge

Thanks for taking an interest. Bug reports, feature ideas and pull requests are all welcome.

## Before you start

Read **[HANDOFF.md](HANDOFF.md)** first. It documents the project's conventions and a list of
gotchas that have already cost real debugging time — the string-typed enum fields, the
weekday remapping, the two-sheet rule, and why some code that looks simplifiable is not.

## Getting set up

You need Xcode 16 or newer. There are no packages to fetch and no configuration files to add:

```bash
git clone https://github.com/praveetgupta/HabitForge.git
cd HabitForge
open HabitForge.xcodeproj
```

The project uses Xcode's synchronized file groups, so adding or deleting a Swift file on disk
is enough — there is no `project.pbxproj` bookkeeping to do.

## Before you open a pull request

Both of these must pass:

```bash
xcodebuild -project HabitForge.xcodeproj -scheme HabitForge \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild test -project HabitForge.xcodeproj -scheme HabitForge \
                -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
                -only-testing:HabitForgeTests
```

The build is warning-free today; please keep it that way.

## House style

- **Match the surrounding code.** Naming, comment density and structure should be
  indistinguishable from the file you are editing.
- **Comment the *why*, not the *what*.** The existing comments explain non-obvious decisions
  (why a `try?` is there, why a binding is written the long way). Follow that.
- **Enum-like model fields are stored as `String`.** Match the exact casing listed in
  HANDOFF.md §5. A typo fails silently at runtime.
- **Weights are stored in kilograms.** `WeightUnit` converts for display and entry only —
  never write a converted value into a model.
- **Add tests for behaviour.** View model logic, conversions and data transformations belong
  in `HabitForgeTests`. Anything reachable through the UI can go in `HabitForgeUITests`.
- **Add accessibility labels** to any new control, and a stable
  `accessibilityIdentifier` if a test needs to find it.
- **No third-party dependencies.** The zero-dependency, first-party-frameworks-only property
  is a deliberate feature of this project. Open an issue before proposing one.

## Reporting a bug

Include the iOS version, the device or simulator, and the steps to reproduce. If it involves a
habit schedule, a streak or a workout calculation, the specific dates and numbers matter — a
lot of the logic is calendar-sensitive.

## Scope

HabitForge is deliberately a local-first, single-user app. Features that require an account, a
server or a third-party SDK are out of scope unless there is a strong case for them; open an
issue to discuss before writing the code.
