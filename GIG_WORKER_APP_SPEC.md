# MrBob Partner — Gig Worker App (Build Spec)

> **For:** the implementation agent building the **separate Flutter project** for gig workers (vendors/partners).
> **Reference repo:** `/Users/devangsonawane/mrbob` — the finished **client-facing** app. Read it for patterns; do NOT modify it.
> **Status:** demo-first build. No real backend, no real OCR, no real KYC, no real maps SDK. Everything local/simulated, exactly like the client app.

---

## 0. How to use this document

- Sections 1–5 are **context + contracts** (read fully before coding).
- Section 6 is the **screen-by-screen spec** — this is the build order.
- Section 12 is a **file-by-file checklist** to track progress.
- Section 13 lists **open questions / assumptions**. If an answer changes behavior, follow the assumption stated and note the deviation in the PR description.

---

## 1. Product summary

**Persona:** a gig worker (plumber, electrician, carpenter, painter, AC tech, etc.) who receives service bookings from the MrBob platform.

**Goal:** let a worker sign up, get KYC-verified, declare their skills, then receive → accept → navigate → arrive → verify OTP → work → complete bookings.

**Demo scope (v1):**

| In scope | Out of scope (v1) |
|---|---|
| Phone-OTP signup (same as client app) | Real SMS/OTP backend |
| Aadhar + PAN entry, simulated scan + field extraction | Real OCR / ML extraction |
| Simulated KYC verification (auto-approves) | Real KYC vendor integration |
| Multi-select skills from the service catalog | Skill pricing/availability rules |
| Incoming booking feed with **swipe-to-accept** | Real booking dispatch / push notifications |
| Booking detail: map, address, "how to reach" | Real navigation SDK (use OSM tiles + directions URL) |
| Job session: **arrived → OTP (demo) → start → complete** | Real OTP verification, payments |
| Earnings/wallet + profile tabs | Real payouts, bank accounts |

**Working title:** "MrBob Partner" (placeholder — confirm with client).

---

## 2. Reference: the existing client app (`mrbob`)

The partner app must **look and feel identical** to the client app. These files are the source of truth for patterns — read them before writing the equivalent:

| What | Reference file in mrbob |
|---|---|
| Phone login sheet (+91 field, Google/Apple buttons, policy links) | `lib/features/auth/presentation/pages/login_page.dart` |
| 3-step signup flow: OTP boxes → name + gender pills → address map confirm | `lib/features/auth/presentation/pages/email_login_page.dart` |
| Email/password signup form (alternate variant) | `lib/features/auth/presentation/pages/email_sign_up_page.dart` |
| Tab shell with liquid-glass tab bar | `lib/features/shell/presentation/pages/main_shell.dart` |
| Service catalog (8 services: icons, prices, durations, badges) | `lib/core/data/services_data.dart` |
| Booking model + status enum | `lib/core/models/booking.dart` |
| Booking detail screen layout (header, sheet, detail cards, action rows, price-summary bottom sheet) | `lib/features/bookings/presentation/pages/booking_detail_page.dart` |
| Hand-rolled OSM map (tile math, drag, pin) — **no google_maps dependency** | `_OsmTileBackground` / `_LocationMap` inside `email_login_page.dart` |
| Design tokens | `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart` |
| Haptics language | `lib/core/utils/app_haptics.dart` |
| Glass usage rules | `CLAUDE.md` + `vendor/liquid_glass_widgets/skills/liquid-glass-widgets/SKILL.md` |

**Architecture conventions to copy:**

```
lib/
  core/
    data/      # mock data sources (services, bookings, worker profile)
    models/    # plain Dart models + enums
    theme/     # AppColors, AppTheme
    utils/     # AppHaptics, formatters
  features/
    <feature>/presentation/
      pages/
      widgets/
  shared/widgets/
```

- **No state-management package.** Plain `setState` (client app style). For cross-tab state (booking feed, job session), use a lightweight singleton `AppState` with `ValueNotifier`/`ChangeNotifier` — still zero-package.
- **No router package.** Plain `Navigator` with `RouteSettings(name: ...)` like `MainShell.routeName`.
- **No HTTP/backend.** All data is local mock data + timers.

---

## 3. Tech stack & project setup

1. `flutter create --org com.example --project-name mrbob_partner .` (Dart SDK ^3.10.0, same as client).
2. `pubspec.yaml` dependencies (mirror client, plus 2 additions):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.3.0
  lucide_icons_flutter: ^3.1.20
  liquid_glass_widgets:
    path: vendor/liquid_glass_widgets   # copy the vendored package from mrbob/vendor/
  image_picker: ^1.1.2                  # NEW — Aadhar/PAN scan (camera/gallery)
  url_launcher: ^6.3.0                  # NEW — "How to reach" directions intent
  # Optional, only if real GPS is wanted (client app fakes location — see §9):
  # geolocator: ^13.0.0
```

> **Important:** `liquid_glass_widgets` is a **vendored path dependency** in mrbob (`vendor/liquid_glass_widgets`), not on pub.dev. Copy the whole `vendor/` folder into the new project. Before writing any glass UI, read `vendor/liquid_glass_widgets/skills/liquid-glass-widgets/SKILL.md` (per mrbob's `CLAUDE.md` rule).

3. `dev_dependencies`: `flutter_lints: ^6.0.0` (same as client).
4. Android: add camera permission in `android/app/src/main/AndroidManifest.xml` (`android.permission.CAMERA`) for the document scan. iOS: add `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`.
5. `main.dart`: mirror client's `LiquidGlassWidgets.initialize()` + `LiquidGlassWidgets.wrap(...)` bootstrap (copy from mrbob `lib/main.dart`, including the `adaptiveConfig` with `allowStepUp: false` — the comment there explains why).

---

## 4. Design system (reuse from client, don't reinvent)

Copy `core/theme/` and `core/utils/app_haptics.dart` verbatim from mrbob:

- **Colors:** `brandForest #0D230D` (primary), `brandGold #FCB723` (accent), `border #E8E3D5`, `borderSubtle #140D230D`, `mutedText #6B726B`, white background.
- **Radii:** card 15, pill 999, inputs 10.
- **Haptics (mandatory on every interaction):** `AppHaptics.tick()` (chip/tab/stepper), `press()` (buttons/tiles), `confirm()` (committed actions: accept booking, OTP submit, mark arrived), `success()` (flow finished: KYC verified, job complete).
- **Typography:** titles 22/w900 forest, subtitles 17/w700 grey, body 14–16/w600, card titles 15/w800 (see reference files).
- **Components:** white cards with `borderSubtle` hairline + soft shadow (`Colors.black.withValues(alpha: 0.05)`, blur 14, offset (0,4)); forest 48–52px CTAs (radius 11–999 per context); glass tab bar via `GlassScaffold` + `GlassTabBar.bottom` (copy metrics from `MainShell`).
- **Icons:** `lucide_icons_flutter` only (no custom assets needed).
- **Status bar:** `AnnotatedRegion<SystemUiOverlayStyle>` per screen (dark on white, light on green headers).

---

## 5. Data models (contracts — implement exactly)

`lib/core/models/skill.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_flutter.dart';

class Skill {
  const Skill({
    required this.id,        // 'plumbing', 'electrical', ...
    required this.title,     // 'Plumbing fixes'
    required this.subtitle,  // 'Leaks, faucets, traps'
    required this.icon,      // LucideIcons.wrench
    required this.color,     // chip background tint
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
```

`lib/core/data/skills_data.dart` — seed from the client's 8 services (`services_data.dart`): Civil touch-ups, Plumbing fixes, Electrical snags, Painting repairs, Carpentry fixes, Deep inspection, AC servicing, Appliance repair. Same titles/subtitles/icons/colors so both apps share vocabulary.

`lib/core/models/gig_booking.dart`:

```dart
enum GigBookingStatus {
  incoming,    // in feed, swipeable
  accepted,    // accepted, en route
  arrived,     // worker marked arrived (OTP pending)
  inProgress,  // OTP verified, working
  completed,   // marked complete
  declined,    // swiped left
  cancelled;   // worker or customer cancelled

  const GigBookingStatus(this.label);
  final String label;
}

class GigBooking {
  const GigBooking({
    required this.id,
    required this.skill,          // Skill
    required this.customerName,
    required this.customerRating, // double, e.g. 4.8
    required this.addressLine,    // '2nd Floor, Green Heights, Andheri East...'
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,     // from worker's current location
    required this.etaMinutes,
    required this.slotLabel,      // 'Today, 4:30 PM' or 'ASAP'
    required this.payout,         // int, rupees
    required this.platformFee,    // int
    required this.notes,          // customer instructions
    this.status = GigBookingStatus.incoming,
  });
  // ...fields + total getter = payout + platformFee? (see §13 Q5)
}
```

`lib/core/models/kyc_document.dart`:

```dart
enum KycDocType { aadhar, pan }
enum KycStatus { notStarted, inProgress, submitted, verifying, verified, rejected }

class KycDocument {
  const KycDocument({
    required this.type,
    required this.number,      // Aadhar: 12 digits; PAN: 10-char alphanumeric
    required this.holderName,
    required this.dob,         // 'DD/MM/YYYY'
    this.imagePath,            // local path after "scan"
  });
}
```

`lib/core/models/job_session.dart` — the live job state machine (§7):

```dart
enum JobPhase { enroute, arrived, otpPending, otpVerified, inProgress, completed }

class JobSession {
  const JobSession({required this.booking, this.phase = JobPhase.enroute});
  final GigBooking booking;
  JobPhase phase;
  DateTime? arrivedAt;
  DateTime? startedAt;
  DateTime? completedAt;
  Duration get elapsed => ...; // startedAt → now (or completedAt)
}
```

`lib/core/state/app_state.dart` — singleton holding: `GigWorkerProfile` (name, phone, gender, serviceArea, skills, kyc), `List<GigBooking>` feed, active `JobSession?`, earnings totals. Expose via `ValueListenableBuilder` at the shell level.

---

## 6. App flow — screen by screen (build order)

### Flow diagram

```
Login (phone OTP) → Name/Gender → Service area (map)
  → KYC: Aadhar/PAN entry → Scan + extraction → Review → Verifying → Verified
  → Skills multi-select
  → Main shell: [Home(feed) | Jobs | Earnings | Profile]
  → Swipe right on booking → Booking detail (map, address, how to reach)
  → Mark as arrived → OTP dialog (demo) → Start working → (timer) → Mark as complete
  → Success screen → Done → back to feed
```

### S1. Login / phone OTP — *same as client*
Copy `login_page.dart` + `email_login_page.dart` step 1 (phone field, +91, 10-digit, Continue → 4-box OTP). Demo rule: **any 4 digits pass** (client behavior). Google/Apple buttons → skip straight into app (demo).

### S2. Name + gender — *same as client*
Copy step 2 of `email_login_page.dart`: large name field, gender pills (Male/Female/Other).

### S3. Service area — *same as client*
Copy step 3: full-screen OSM map, drag to move pin, "Current Location" button, bottom confirm sheet ("Your current location is selected" → Confirm Location). This is the worker's **home/service area**.

### S4. KYC — document details
New screen. Header: "Verify your identity", subtitle "Required before you can receive bookings".
- **Document type selector:** two large selectable cards — Aadhar Card / PAN Card (icons: `LucideIcons.idCard`, `LucideIcons.creditCard`).
- **Manual entry fields** (per type):
  - Aadhar: 12-digit number (auto-format `#### #### ####`), name, DOB (DD/MM/YYYY).
  - PAN: 10-char alphanumeric (auto-uppercase, format `AAAAA9999A`), name, DOB.
- **"Scan card" button** → `image_picker` (camera first, gallery fallback) → after pick, show **extraction animation** (progress indicator + "Extracting details…" ~2s) → **auto-fill the fields** with mock extracted data (e.g. name "RAMESH KUMAR", Aadhar "1234 5678 9012") and a green "Details extracted" chip. User can edit after extraction.
- Validation: Aadhar = 12 digits; PAN regex `^[A-Z]{5}[0-9]{4}[A-Z]$`. Inline errors, forest-colored focus.
- CTA: "Verify & continue" (disabled until valid).

### S5. KYC verification (simulated)
- On submit → `KycStatus.verifying` screen: animated seal/spinner, "Verifying your Aadhar with the database…" (~2.5s).
- → **Verified** success screen: green check seal, "You're verified", summary card (doc type + masked number `•••• •••• 9012`), CTA "Continue".
- `AppHaptics.success()` on verified. **Gate:** Main shell is unreachable until `KycStatus.verified`.
- (Demo only) Add a hidden "Simulate rejection" option in the profile screen to test the rejected state: red seal, reason text, "Try again" → back to S4.

### S6. Skills multi-select
- Header: "What can you do?", subtitle "Select all the services you can perform. You'll only get bookings for these."
- Grid (2 columns) of selectable skill cards: icon in tinted circle (use skill.color), title, subtitle. Selected = forest border + forest check badge + tinted bg; `AppHaptics.tick()` on toggle.
- Bottom bar: "3 selected" + forest CTA "Continue" (disabled until ≥1 selected). "Select all" text button top-right.
- On continue → save to profile → Main shell.

### S7. Main shell (4 tabs)
Copy `MainShell` structure (`GlassScaffold` + `GlassTabBar.bottom`, icon-only tabs, same metrics):
1. **Home** — booking feed (S8).
2. **Jobs** — active job session (if any) + accepted/history list (status chips: Arrived / In progress / Completed).
3. **Earnings** — wallet-style (copy `wallet_page.dart` layout): total earned, pending payout, available balance; payout rows per completed booking (service, date, amount). Completing a job moves its payout from pending → available.
4. **Profile** — name/phone, **KYC status badge** (Verified green / Pending amber), skills chips (tap "Edit" → back to S6), documents (masked numbers), "Sign out" (demo: resets to S1).

### S8. Home — incoming booking feed (swipe to accept)
- **Top of feed:** the newest pending booking as a **swipeable card** (primary interaction):
  - Card content: skill icon + title, subtitle, address line, `distanceKm` + `etaMinutes` ("2.4 km • ~8 min"), slot label, **payout** in forest/gold ("₹399"), customer name + star rating, notes snippet.
  - **Gesture:** horizontal drag — right = **Accept** (green overlay + check icon, "Release to accept"), left = **Decline** (red overlay + x icon, "Release to decline"). Threshold ~120px or velocity; below threshold snaps back with spring. Use `GestureDetector` + `AnimatedPositioned`/`Transform.translate` (do NOT use `Dismissible` — need directional overlays).
  - **Accessibility fallback:** explicit "Accept" (forest) and "Decline" (outline) buttons under the card — required, swipe alone is not enough.
  - On accept: `AppHaptics.confirm()`, status → `accepted`, navigate to **S9 booking detail**.
  - On decline: card flies off, next booking becomes top card, haptic tick.
- **Below:** "Upcoming for you" list of remaining pending bookings (non-swipeable, tap → S9).
- **Demo simulation:** a timer injects a new mock booking every ~45s while the feed is visible (max 3 pending at once). Also add a debug "New booking" button in the profile tab to trigger on demand.
- Empty state: illustration + "No new bookings right now. We'll notify you when one comes in."

### S9. Booking detail — map, address, how to reach
Layout: copy `booking_detail_page.dart` structure (header zone + white rounded sheet + detail cards + action rows), but with a **full map** instead of the pink seal:
- **Map section (top ~45%):** OSM tile background (reuse `_OsmTileBackground` math from `email_login_page.dart`) centered on booking lat/lng, pin marker at destination, "Current location" button. Distance/ETA chip overlaid ("2.4 km • ~8 min").
- **Address card:** full address line + landmark, copy button (haptic + snackbar "Address copied").
- **"How to reach" row** (primary action row): opens directions via `url_launcher`:
  `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>` with `geo:<lat>,<lng>?q=<lat>,<lng>` fallback. Label: "How to reach" / subtitle "Open directions".
- **Customer card:** name, rating, "Call" / "Message" rows (demo: snackbar "Calling is disabled in demo").
- **Job summary card:** skill, slot, duration, notes.
- **Earnings row:** opens price-summary bottom sheet (copy `_showPriceSummary`): service charge + platform fee = total payout.
- **Bottom CTA (sticky):** forest button **"Mark as arrived"** → `AppHaptics.confirm()` → status `arrived` → push **S10**.

### S10. Arrived → OTP (demo) → start working
- On arriving, **auto-show the OTP dialog** (modal, non-dismissible except via input):
  - Title: "Verify customer OTP", subtitle "Ask the customer for the 4-digit code shown on their booking."
  - 4 boxed OTP inputs (reuse the `_OtpBoxes` pattern from `email_login_page.dart`), auto-focus, auto-submit at 4 digits.
  - **Demo rule:** show the code in a hint chip — "Demo OTP: 1234" — and accept **any** 4-digit input (or require the shown code; see §13 Q3). Wrong-length blocked by input formatter.
  - On submit: `AppHaptics.confirm()` → status `otpVerified`.
- **"Start working" screen/state:** big forest CTA "Start working". On tap → `inProgress`, `startedAt = now`, `AppHaptics.success()`.

### S11. In-progress job
- Header: skill title + customer address; **live elapsed timer** (mm:ss, updates every second) since `startedAt`.
- Simple checklist (optional, demo): 3 static items ("Gather tools", "Confirm scope with customer", "Clean up area") — checkable, haptic tick.
- Sticky bottom CTA: **"Mark as complete"** (gold or forest — see §13 Q4).
- On tap → `completed`, `completedAt = now` → push **S12**.

### S12. Completion / done
- Success screen: green check seal (reuse the scalloped-seal painter idea from `booking_detail_page.dart`, but green), "Job completed!", summary card (service, duration worked, address), **earnings card** ("₹399 added to your earnings", pending → available).
- Optional: customer rating prompt (1–5 stars, demo only, skippable).
- CTA: **"Done"** → pop to feed (booking now in Jobs tab history + Earnings row). `AppHaptics.success()`.

---

## 7. Booking lifecycle state machine

```
incoming ──swipe right──▶ accepted ──mark arrived──▶ arrived ──OTP ok──▶ otpVerified
   │                        │                            │
   └──swipe left──▶ declined│                            └──(demo: cancel)──▶ cancelled
                           └──(demo: cancel)──▶ cancelled
otpVerified ──start working──▶ inProgress ──mark complete──▶ completed
```

Rules:
- Only one active `JobSession` at a time; feed keeps showing other bookings, but accepting a second while one is active shows a confirm dialog ("You have an active job. Leave it and accept this one?" — demo: allow, cancels the active one).
- `Jobs` tab shows the active session prominently (phase chip + CTA deep-link into the right screen for the current phase).

---

## 8. Demo simulation rules (all client-side)

| Feature | Demo behavior |
|---|---|
| Phone OTP | Any 4 digits accepted |
| Customer OTP (S10) | Hint shows "Demo OTP: 1234"; any 4 digits accepted (configurable) |
| KYC verification | Auto-approves after 2.5s; rejection only via profile debug option |
| Document extraction | Auto-fills mock data after 2s "extraction" animation |
| New bookings | Timer every ~45s (max 3 pending) + manual trigger in Profile |
| Directions | Opens Google Maps URL / geo intent |
| Call/Message | Snackbar "disabled in demo" |
| Persistence | In-memory only (app restart → back to login). See §13 Q6 |

---

## 9. Maps & location

- **No google_maps package.** Reuse the client's hand-rolled OSM tile renderer (`_OsmTileBackground` in `email_login_page.dart`): Web-mercator tile math, `Image.network` from `tile.openstreetmap.org`, drag offset, fallback `CustomPainter` when offline.
- Worker "current location": fake fixed coordinate (client uses 19.2836, 72.8727 — Andheri East, Mumbai). Booking destinations: generate mock coords within ~2–6 km of it.
- "How to reach" = `url_launcher` directions URL (§6 S9). If real GPS is wanted later, add `geolocator` — but keep the fake default for demo parity with the client app.

---

## 10. Edge cases & validation

- OTP fields: digits-only, length-locked (4), auto-advance not needed (single hidden field pattern like client).
- Aadhar/PAN: formatters + regex validation; disable CTA until valid; clear inline error on edit.
- Image pick failure/cancel: stay on S4, show snackbar, keep manual entry.
- Swipe card: guard against swiping while a navigation is in flight; disable buttons during transition.
- App backgrounded mid-job: timer uses `DateTime` diff (not tick counting) so it survives pauses.
- Empty feed, empty earnings, empty jobs history — all need designed empty states.
- Safe areas: every screen handles `MediaQuery.paddingOf(context).bottom` for the sticky CTA (client pattern).

---

## 11. Polish checklist (must-pass before handoff)

- [ ] `AppHaptics` called at every interaction point (tick/press/confirm/success per §4).
- [ ] Status bar style per screen (`AnnotatedRegion`).
- [ ] Keyboard handling: `resizeToAvoidBottomInset` + focus management like `email_login_page.dart`.
- [ ] Semantics labels on icon-only tabs and swipe card (`Semantics`/`semanticLabel`).
- [ ] No `debugShowCheckedModeBanner`.
- [ ] `flutter analyze` clean; `flutter test` has at least smoke tests for models + state machine.
- [ ] Runs on Android + iOS (permissions declared).

---

## 12. Implementation checklist (suggested file map)

```
lib/
  main.dart                                  # glass bootstrap (copy from mrbob)
  core/
    theme/app_colors.dart, app_theme.dart    # copy
    utils/app_haptics.dart                   # copy
    models/skill.dart, gig_booking.dart, kyc_document.dart, job_session.dart, gig_worker_profile.dart
    data/skills_data.dart, mock_bookings.dart, mock_worker.dart
    state/app_state.dart                     # singleton, ValueNotifier-based
  features/
    auth/presentation/pages/
      login_page.dart                        # copy/adapt from mrbob
      otp_signup_page.dart                   # 3-step flow (OTP/name/address), adapted
    kyc/presentation/pages/
      kyc_document_page.dart                 # S4: type select + fields + scan
      kyc_verifying_page.dart                # S5: spinner → verified/rejected
    skills/presentation/pages/skills_select_page.dart   # S6
    shell/presentation/pages/partner_shell.dart         # S7: 4-tab glass shell
    feed/presentation/
      pages/booking_feed_page.dart           # S8
      widgets/swipeable_booking_card.dart    # swipe gesture + overlays
      widgets/booking_list_tile.dart
    job/presentation/
      pages/booking_detail_page.dart         # S9: map + address + how to reach
      pages/arrival_otp_page.dart            # S10: OTP dialog + start working
      pages/in_progress_page.dart            # S11: timer + checklist
      pages/job_complete_page.dart           # S12: success + earnings
    earnings/presentation/pages/earnings_page.dart
    profile/presentation/pages/profile_page.dart
  shared/widgets/                            # otp_boxes, map_picker, status_badge, empty_state...
```

Build order: core/state → auth → kyc → skills → shell → feed/swipe → detail → job session → earnings/profile → polish.

---

## 13. Open questions / assumptions

Assumptions made (change only if client confirms otherwise):

1. **Signup variant:** client has both phone-OTP (`login_page` → `email_login_page`) and email/password (`email_sign_up_page`) flows. **Assumed:** partner app uses the **phone-OTP flow** as "the same signup page". Confirm if email/password is wanted instead.
2. **App name:** "MrBob Partner" is a placeholder.
3. **Customer OTP (S10):** assumed demo shows the code ("Demo OTP: 1234") and accepts any 4 digits. If it must validate against the shown code, say so.
4. **"Mark as complete" button color:** assumed forest (primary). Client uses gold for accents — confirm if gold is preferred.
5. **Payout math:** assumed worker sees `payout` (their earning) and `platformFee` separately, total = payout + platformFee shown as "customer paid". Confirm.
6. **Persistence:** assumed in-memory (demo). If signup/KYC/skills should survive restarts, add `shared_preferences`.
7. **Booking dispatch:** assumed client-side timer simulation. Real push/dispatch is a backend question.
8. **Skills catalog:** assumed the same 8 services as the client app. Confirm if workers need more/fewer (e.g. "Appliance installation", "Pest control").
9. **Gender field:** copied from client signup — confirm it's wanted for workers too.
10. **Declined bookings:** assumed they disappear from the feed permanently (demo). Confirm if they should re-appear or go to a "Declined" list.

---

*Spec generated for the mrbob partner-app build. Keep the client app (`/Users/devangsonawane/mrbob`) untouched; this is a separate Flutter project.*
