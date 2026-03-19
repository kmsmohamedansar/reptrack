# RepTrack — Pre-Submission Audit (Apple App Store)

**Auditor perspective:** Senior iOS engineer, QA, Apple App Store reviewer.  
**Date:** 2026-03-13.  
**Scope:** RepTrack (Northstar Forge) — SwiftUI + SwiftData workout/exercise tracker.

---

## STEP 1 — FUNCTIONAL TEST

### Core flows evaluated

| Flow | Result | Notes |
|------|--------|--------|
| **Add workout** | ✅ Works | FAB and empty-state CTA open sheet; date picker → Add creates workout and navigates to detail. |
| **Add exercise** | ✅ Works | Detail FAB → Add Exercise sheet; picker + details → Add inserts and dismisses. |
| **Edit exercise (inline)** | ✅ Works | Weight/reps/sets text fields with 300ms debounce; commit on blur and onDisappear. |
| **Edit exercise (full)** | ✅ Works | Pencil → Edit sheet; name/weight/reps/sets/notes → Save updates via ViewModel. |
| **Delete exercise** | ✅ Works | Trash → confirmation alert → delete and refresh. |
| **Delete workout** | ✅ Works | Context menu on card → confirmation → delete and fetchWorkouts(). |
| **Navigate between screens** | ✅ Works | List → detail via navigationDestination; sheets for add/edit; back behaves correctly. |

### Bugs / confusing flows

1. **Duplicate “today” workouts (important)**  
   - **Today Focus** “Start Workout” reuses existing today workout or creates one.  
   - **FAB “Add”** always creates a new workout via `AddWorkoutView`; if the user picks today’s date, a second workout for the same day is created.  
   - Result: Two “Today” cards possible; no merge or “use existing today” when adding with today’s date.  
   - **Recommendation:** When saving from Add Workout sheet, if the chosen date is “today” and a today workout already exists, either reuse it (navigate to it) or show a clear choice (“Add to today’s workout” vs “New workout for today”).

2. **Add Workout sheet always dismisses on Save**  
   - On save failure, `addWorkout(date:)` returns `nil`, error is shown via `onError`, but the sheet is still dismissed.  
   - Acceptable: user sees the toast; they can add again. Not ideal for accessibility (toast may be missed). Consider keeping sheet open on save failure.

### Missing states

- **Add Workout:** No loading state on “Add” (save is fast; optional improvement).  
- **Add/Edit Exercise:** Loading state for exercise picker is present (skeleton/loading).  
- No obvious missing UI states for the main flows.

---

## STEP 2 — DATA RELIABILITY

### Persistence

- **SwiftData:** Single `ModelContainer` (disk, with in-memory fallback if disk fails). Schema: `Workout`, `ExerciseLog` only.  
- **Saves:** All mutations go through `modelContext` with `do { try modelContext.save() } catch { ... }`. No `try?` in persistence paths; errors are logged and surfaced via `onError` or notices.  
- **Background/termination:** `scenePhase` `.inactive` / `.background` triggers save on both `WorkoutListView` and `WorkoutDetailView`. User sees “Couldn’t save changes” if save fails.  
- **Inline edit (ExerciseCardView):** Autosave with debounce; `onDisappear` calls `commitToModelAndSave()`. If save fails, only `AppLog` is used — user is not notified. Minor gap.

### Data loss risk

- **Low** for normal use: saves on every mutation and on background.  
- **Edge case:** If the user backgrounds during the 300ms debounce before commit, the last keystroke could be lost. Acceptable for a simple tracker.  
- **Reset:** Settings “Reset data” uses confirmation and do/catch; no silent failure.

### Verdict

- No unsafe `try?` or silent persistence failures in critical paths.  
- Background save is implemented and errors are shown.  
- **Recommendation:** On inline autosave failure in `ExerciseCardView`, consider calling `onError` or a small notice so the user knows to retry.

---

## STEP 3 — PERFORMANCE

- **Heavy work in views:**  
  - List uses `viewModel.workouts` and derived computed properties (`todayWorkouts`, `previousWorkouts`, `workoutsThisWeek`). No heavy computation inside the view body.  
  - Detail view uses `workout.sortedExercises` and ViewModel helpers; `weightProgression(for:)` and `progressInsight(for:)` perform fetches. These are called from the view but are not in a tight loop; acceptable for typical workout sizes.  

- **Repeated fetches:**  
  - `WorkoutDetailViewModel` fetches all logs for comparison and for progression. With many workouts/exercises this could add up. No caching beyond `previousLogsByName`.  
  - Summary/streak use in-memory `workouts` from the list ViewModel; no extra fetch per cell.  

- **Scalability:**  
  - `fetchWorkouts()` loads **all** workouts with a single descriptor (no limit). With hundreds/thousands of workouts, list load and memory could grow.  
  - **Recommendation:** For a 1.0 release this is acceptable; consider a cap or paging later if you expect very large histories.

- **UI lag:**  
  - LazyVStack for exercises and workout cards; no obvious main-thread blocking.  
  - Exercise picker loads `wgerExercises` on background queue; UI stays responsive.

**Verdict:** No critical performance issues for normal use. Large datasets (e.g. 500+ workouts) are the only future risk.

---

## STEP 4 — UI/UX QUALITY

- **Consistency:** Forge theme (gold/navy), `forgeCard()`, shared spacing and typography are used across list, detail, add/edit, and settings. Looks consistent.  
- **Spacing:** `ForgeTheme.gutter`, `spaceM`, `spaceL`, etc. used in cards and sections; no obvious inconsistencies.  
- **Clutter:** Summary card, today focus, and workout cards are clear; no obvious visual clutter.  
- **Finished vs demo:** Feels like a finished 1.0: clear hierarchy, empty states, loading skeletons, confirmation dialogs, and a coherent “Northstar Forge” look.  
- **Gaps:**  
  - Detail screen FAB reuses default “Add workout” label/hint (see Step 5).  
  - No HIG violation observed; light mode enforced as intended.

---

## STEP 5 — APP STORE READINESS

| Check | Status | Notes |
|------|--------|--------|
| **Onboarding** | ⚠️ Minimal | No dedicated onboarding flow. Empty state explains “Start your first workout today” and offers “Add Workout”. Acceptable for a simple tracker; optional improvement: one-time tip or short onboarding. |
| **Empty states** | ✅ | List: empty state with CTA. Detail: “No exercises yet” card with “Add Exercise”. |
| **Loading states** | ✅ | First load: skeleton dashboard. Add/Edit exercise: loading while picker data loads. |
| **Destructive actions** | ✅ | Delete workout and delete exercise both use confirmation alerts with “This can’t be undone.” Reset data in Settings confirmed with full message. |
| **Crash risks** | ✅ Low | No force unwraps in critical paths. ModelContainer failure shows “Storage unavailable” instead of crashing. |
| **Accessibility** | ✅ Basic | Labels/hints on FAB (list), workout cards, today CTA, progress rings, chart summary, notice banner. **Issue:** Detail FAB still has default “Add workout” / “Opens the add workout screen” — should be “Add exercise” / “Opens add exercise screen”. |

---

## STEP 6 — EDGE CASES

| Scenario | Assessment |
|----------|------------|
| **No workouts at all** | Handled: empty state with “Add Workout”; today focus shows “Start Workout” and creates workout on tap. |
| **Very large number of workouts** | All loaded in memory; list and filters are in-memory. Could get slow with 500+; not a crash risk. |
| **User edits mid-typing and backgrounds** | 300ms debounce then save; onDisappear commits. Background save on scenePhase. Small risk of losing the last few characters if they background in the 300ms window. |
| **Rapid add/delete** | No rate limiting; SwiftData and UI should handle. Possible brief overlap of alerts/sheets; no crash observed from code. |

---

## STEP 7 — FINAL VERDICT

### 🔴 Critical issues (must fix before submission)

- **None.** No blocking bugs or data-loss issues; no crashes or guideline violations identified.

### 🟡 Important improvements (recommended)

1. **Duplicate same-day workouts**  
   When adding a workout from the sheet with “today” selected, reuse or clearly merge with existing today workout (or warn and offer “Add to today” vs “New workout for today”).

2. **Detail FAB accessibility**  
   In `WorkoutDetailView`, pass explicit `accessibilityLabel` and hint for the FAB, e.g. “Add exercise” and “Opens add exercise screen”, instead of the default “Add workout”.

3. **Inline autosave failure feedback**  
   In `ExerciseCardView.commitToModelAndSave()`, on save failure, surface an error to the user (e.g. via `onError` or a small notice) instead of only logging.

4. **Dead code**  
   Remove or exclude from target: `ContentView.swift` and `Item.swift` (template leftovers; app uses `WorkoutListView` and schema does not include `Item`). Keeps the project clean for review and future maintenance.

### 🟢 Good to go

- Core flows (add workout/exercise, edit inline/full, delete, navigation) work and are consistent.  
- Persistence is explicit (do/catch, no silent `try?`); background save implemented.  
- Empty and loading states present; destructive actions confirmed.  
- No crash-prone patterns; container failure handled with a clear screen.  
- Basic accessibility in place; one fix needed (detail FAB).  
- UI/UX feels consistent and “finished” for a 1.0.

---

## Is this app ready for App Store submission?

**Yes, with one strong recommendation.**

- There are **no critical issues** that would justify a rejection from a strict Apple reviewer perspective.  
- Fixing the **detail FAB accessibility** (wrong “Add workout” label on the Add Exercise button) is the only change that feels important before submission, as it directly affects VoiceOver users.  
- Addressing **same-day duplicate workouts** and **inline save error feedback** would improve quality and reduce support burden but are not strict submission blockers.  
- Removing **ContentView** and **Item** is good hygiene and reduces confusion during review.

**Summary:** Ready for submission after updating the Workout Detail FAB accessibility label and hint; other items are recommended improvements.
