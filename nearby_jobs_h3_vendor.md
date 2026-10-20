# Nearby Jobs (H3) — vendor app implementation

Vendor-side work for `MrBob-Nearby-Jobs-H3-Guide.pdf` (21 October 2026).

Jobs now reach the vendors nearest to the customer first. This document lists
what the vendor app does with the new endpoints, and where each piece lives in
the code.

Base URL: `https://home-services-backend-7cyx.onrender.com/api/v1`
Live reference: `https://home-services-backend-7cyx.onrender.com/api-docs`
(sections *"Vendor app - going online (nearby jobs)"* and
*"Customer app - vendors nearby"*)

Sign-in, tokens and the rest of the job flow (start code, completion code,
photos, complete) are unchanged.

## What changed

| Area | Change |
| --- | --- |
| Presence | Online/Offline switch + a position every 30 s while online |
| Jobs list | Polled every 5 s while online, offers show a 60 s countdown |
| Jobs list | New Decline button on offered jobs |
| Jobs list | `distanceKm`, `offer` and `openToAll` on every available job |
| Accept/Decline | HTTP 409 ("job no longer available") is handled |

## Endpoints used

| Call | Where |
| --- | --- |
| `GET /vendor/presence` | `VendorRepository.getPresence` |
| `PUT /vendor/presence` | `VendorRepository.updatePresence` |
| `GET /vendor/jobs/available` | `VendorRepository.getAvailableJobs` |
| `GET /vendor/jobs/available/{id}` | `VendorRepository.getAvailableJob` |
| `POST /vendor/jobs/{id}/accept` | `VendorRepository.acceptJob` |
| `POST /vendor/jobs/{id}/decline` | `VendorRepository.declineJob` |

The customer-side endpoints (`GET /customer/nearby-vendors`, address
latitude/longitude) belong to the customer app and are not part of this repo.

## Code map

| File | Role |
| --- | --- |
| `lib/core/models/vendor_presence.dart` | Presence payload: online, position, `h3Cell`, `canReceiveOffers`, `activeOffers`, `updateEverySeconds` |
| `lib/core/models/job_offer.dart` | Offer block: `expiresAt` + `wave`, with a countdown helper |
| `lib/core/models/gig_booking.dart` | Parses `offer`, `openToAll`, `distanceKm` (nullable), `bookingNumber`, `paymentMode`, and the `area` fallback for the address line |
| `lib/core/services/location_service.dart` | geolocator wrapper: foreground permission + current position |
| `lib/core/state/app_state.dart` | Presence state, 30 s heartbeat, 5 s poll, 409 handling |
| `lib/features/vendor/data/vendor_repository.dart` | The endpoints above, plus `JobUnavailableException` (409) and `LocationRequiredException` (400) |
| `lib/features/feed/presentation/pages/booking_feed_page.dart` | Home: online switch, polling, offer-first ordering |
| `lib/features/feed/presentation/widgets/job_request_card.dart` | Offer countdown, "Open to all vendors", Decline button |
| `lib/features/feed/presentation/widgets/offer_countdown.dart` | The ticking countdown |
| `lib/features/shell/presentation/pages/partner_shell.dart` | Loads the presence when the shell opens |

## Online / Offline

`PUT /vendor/presence` with `{"online": true, "latitude": …, "longitude": …}`,
or `{"online": false}` to go offline.

- The switch on the Home screen is bound to `AppState.presence`.
- On app start the presence is read with `GET /vendor/presence` so the switch
  starts in the right position (`AppState.initialize` and `PartnerShell`).
- Going online asks for the location permission first. Without a position the
  server answers `400 Send your location`; the app shows
  *"Turn on location access to receive nearby job requests."*
- While online the app sends the position again every
  `updateEverySeconds` (30 by default) — `AppState.refreshPosition`.
- The heartbeat also fires when the app returns to the foreground, because
  the OS may have throttled the timer in the background.
- Going offline stops the timer and hands the unanswered offers back.
- Signing out calls `{"online": false}` before the session ends, so no more
  offers are routed to a vendor who left the app.

### Approval

`canReceiveOffers: false` while online means the vendor is not approved yet.
The Home screen then shows **"Your profile is under review"** instead of the
job feed.

### Permissions

- Android: `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` in
  `android/app/src/main/AndroidManifest.xml`.
- iOS: `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`.

Only foreground location is used — the app keeps sending the position while
it is open, which is what the guide asks for.

## The jobs list

`GET /vendor/jobs/available` is polled every **5 seconds** while the vendor
is online and the Home screen is open (`BookingFeedPage._syncPolling`). The
poll is silent: it does not flash the loading spinner and does not clear the
error banner.

Each item now carries three fields:

| Field | How the app shows it |
| --- | --- |
| `distanceKm` | `"0.2 km away"` — dropped when the server has no position |
| `offer` | `"Offered to you - 52s left"`, counting down to `offer.expiresAt` |
| `openToAll` | `"Open to all vendors"` |

- Jobs with a live offer are moved to the top of the list, soonest expiry
  first, and the top card shows the countdown with **Accept** and
  **Decline**.
- A job that is open to all shows **Accept** only.
- When the countdown reaches zero the job leaves the list. It may come back
  later as open to all.

The address line falls back to the service area when the job has no full
address yet: `"Bandra West, Mumbai, 400050"`.

## Accept and Decline

| Action | Call | Result |
| --- | --- | --- |
| Accept | `POST /vendor/jobs/{id}/accept` | The job becomes `ASSIGNED` to this vendor |
| Decline | `POST /vendor/jobs/{id}/decline` (no body) | `{"declined": true}`, the job leaves the list |

`409` means the offer ran out or another vendor was faster:

- on **Accept** the job is dropped from the feed, the list is refreshed and
  the server message is shown;
- on **Decline** the job is simply removed.

Both are surfaced as `JobUnavailableException` from the repository and handled
in `AppState.acceptBooking` / `AppState.declineBooking`.

## Not implemented (yet)

- **Push notifications.** The server already sends a *"New job near you"*
  push with `{"type": "JOB_OFFER", "bookingId": "…"}`, but it only goes out
  once Firebase (FCM) is set up and device registration is added. Until then
  the 5 second poll is how offers reach the vendor. When the push lands it
  should open the jobs screen and refresh it.
- **Customer side.** `GET /customer/nearby-vendors` and the address
  latitude/longitude belong to the customer app.

## Tests

`test/h3_nearby_jobs_test.dart` covers the presence payload, the offer
countdown, the available-job parsing, the three new endpoints, the 409 and
400 error paths, the poll and the offer/decline behaviour in `AppState`.
