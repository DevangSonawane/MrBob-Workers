Vendor Onboarding — Mobile App Integration Guide
7 Oct 2026 · @Asynk
This guide covers everything the vendor app needs to take a vendor from phone number to verified. Exact request and response schemas for every call are in the API docs at <SERVER>/api-docs, under the five "Vendor onboarding" sections.
Basics
Base URL: <SERVER>/api/v1. Every path below is relative to it. Open question: the production server address, to be supplied by the backend team.
Auth: after OTP verification, send Authorization: Bearer <accessToken> on every call.
Success: { "success": true, "data": { ... } }
Error: { "success": false, "message": "...", "details": { ... } } with a matching HTTP status. Show message to the vendor.
Phone numbers: E.164 format, for example +919812345678.
OTP: 4 digits, valid for 5 minutes, single use. Five wrong attempts discard it.
Test OTP: while no SMS service is connected, the server accepts one fixed 4-digit code for every number. Ask the backend team for the current value. The app must still call the request endpoint before verifying.
The flow at a glance
Five steps, five screens. The vendor acts in steps 1 to 3; steps 4 and 5 are the app waiting for, then showing, the review outcome.
Step
Screen
What the app calls
1. Phone number
Enter mobile number
POST /vendor-onboarding/otp/request
2. Verify OTP
Enter 4-digit code
POST /vendor-onboarding/otp/verify
3. Enter details
Six-part form, then submit
Six PUT calls, then POST /vendor-onboarding/submit
4. Verification
"Verification in progress"
Poll GET /vendor-onboarding/status
5. Verified
Success, enter the main app
status is APPROVED

Every response that contains the application includes a flow object. Use it to draw the progress tracker and to decide which screen to show:
"flow": {
  "currentStep": 3,
  "isVerified": false,
  "steps": [
    { "step": 1, "key": "PHONE_NUMBER",  "title": "Phone number",  "status": "COMPLETE" },
    { "step": 2, "key": "VERIFY_OTP",    "title": "Verify OTP",    "status": "COMPLETE" },
    { "step": 3, "key": "ENTER_DETAILS", "title": "Enter details", "status": "CURRENT" },
    { "step": 4, "key": "VERIFY_VENDOR", "title": "Verification",  "status": "PENDING" },
    { "step": 5, "key": "VERIFIED",      "title": "Verified",      "status": "PENDING" }
  ]
}
A step's status is one of PENDING, CURRENT, COMPLETE, ACTION_REQUIRED (the reviewer sent it back; the vendor must fix and resubmit) or REJECTED.
Steps 1 and 2: phone number and OTP
Both calls are public; no token is needed.
Step 1. Send the OTP
POST /vendor-onboarding/otp/request
{ "phone": "+919812345678" }

200 -> { "success": true, "data": { "sent": true, "expiresInSeconds": 300 } }
400: the phone number is not valid.
403: the number belongs to an admin or a deactivated account. Show message.
"Resend OTP" is the same call again; it replaces the previous code.
Step 2. Verify the OTP
POST /vendor-onboarding/otp/verify
{ "phone": "+919812345678", "otp": "1234" }

200 -> {
  "success": true,
  "data": {
    "isNewUser": true,
    "user": { "id": "...", "name": "New Vendor", "phone": "+919812345678", "role": "PROFESSIONAL", "isOnboarded": false },
    "accessToken": "...",
    "refreshToken": "...",
    "application": { ...the full application, see step 3... }
  }
}
400: wrong or expired code. After five wrong attempts the vendor must request a new one.
Store both tokens, then route using application (see "Routing on app launch"). A returning vendor gets isNewUser: false and their existing application, so they resume where they stopped.
The same two calls are used for every later sign-in. There is no separate login.
Tokens
The access token lasts 15 minutes and the refresh token 30 days.
Store both in secure storage (Keychain on iOS, Keystore / EncryptedSharedPreferences on Android).
On any 401, refresh once and retry the original call:
POST /auth/refresh
{ "refreshToken": "..." }

200 -> { "success": true, "data": { "accessToken": "...", "refreshToken": "..." } }
Save the new pair; the old refresh token should be discarded.
If the refresh call itself returns 401, clear the tokens and send the vendor back to the phone number screen.
Sign out is local: delete the stored tokens. There is no sign-out call.
Step 3: enter details
Six parts, each saved with its own call, in any order. Every save returns the full updated application, so the app never needs a separate reload.
Part (detailSteps key)
Call
Format
personalDetails
PUT /vendor-onboarding/personal-details
JSON
profilePhoto
PUT /vendor-onboarding/profile-photo
multipart
services
PUT /vendor-onboarding/services
JSON
aadhaar
PUT /vendor-onboarding/documents/aadhaar
multipart
pan
PUT /vendor-onboarding/documents/pan
multipart
bankDetails
PUT /vendor-onboarding/bank-details
multipart

Reading progress. In every application response:
detailSteps: [{ "key": "personalDetails", "complete": true }, ...]. Use it for the checklist ticks.
nextStep: the first unfinished part, or submit when all six are done.
canSubmit: enable the submit button when true.
isEditable: when false, the form is read-only (the application is under review or decided).
Dropdown data (public, no token):
Cities: GET /zones/cities
Zones in a city: GET /zones?cityId=<id>
Services: GET /categories
Personal details (JSON)
Field
Required
Rule
name
Yes
2 to 100 characters, as on the Aadhaar card
dateOfBirth
Yes
YYYY-MM-DD, must be 18 or older
gender
Yes
MALE, FEMALE or OTHER
cityId
Yes
From the cities list
addressLine1
Yes
5 to 200 characters
pincode
Yes
6 digits
state
Yes
2 to 60 characters
email
No
Valid email
alternatePhone
No
E.164
addressLine2, landmark
No
Text
emergencyContactName, emergencyContactPhone
No
Send both or neither

Do not send phone; it comes from the OTP login. This call replaces the whole part, so always send every field the vendor has filled, not only the changed ones.
Profile photo (multipart)
File field photo. JPEG, PNG or WebP, up to 5 MB. Uploading again replaces it.
Services (JSON)
{ "categories": ["<categoryId>", "<categoryId>"], "experienceYears": 6, "homeZoneId": "<zoneId>" }
categories: at least one id from the services list.
experienceYears: whole number, 0 to 60.
homeZoneId: optional; must be a zone in the city chosen in personal details.
Aadhaar and PAN (multipart)
Field
Aadhaar
PAN
number
12 digits, spaces allowed
10 characters, for example ABCPE1234F
nameOnDocument
Required
Required
front (file)
Required
Required
back (file)
Required
Do not send

Files: JPEG, PNG, WebP or PDF, up to 5 MB each. The number is validated on the server (Aadhaar checksum, PAN format), so show the returned message on a 400.
Bank details (multipart)
Field
Required
Rule
accountHolderName
Yes
2 to 100 characters
accountNumber
Yes
9 to 18 digits
ifsc
Yes
11 characters, for example HDFC0001234
bankName
Yes
Text
accountType
Yes
SAVINGS or CURRENT
branchName, upiId
No
UPI format name@bank
proof (file)
Yes
Cancelled cheque or passbook first page; JPEG, PNG, WebP or PDF, up to 5 MB

What comes back for documents
Numbers are never returned in full. The app receives a masked value and a status per item:
"documents": [
  { "type": "AADHAAR", "status": "PENDING", "maskedNumber": "XXXX XXXX 0124", "nameOnDocument": "Ravi Kumar",
    "rejectionReason": null, "files": { "front": "/vendor-onboarding/documents/aadhaar/files/front", "back": "/vendor-onboarding/documents/aadhaar/files/back" } },
  { "type": "PAN", "status": "NOT_UPLOADED" }
],
"bankDetails": { "status": "PENDING", "maskedAccountNumber": "XXXXXX6789", "ifsc": "HDFC0001234", "proofFile": "/vendor-onboarding/documents/bank_account/files/front" }
status is NOT_UPLOADED, PENDING, VERIFIED or REJECTED.
A REJECTED item shows its rejectionReason and must be uploaded again.
A VERIFIED item is locked; trying to replace it returns 409.
When replacing an item, the files can be left out to keep the ones already uploaded.
Submit
POST /vendor-onboarding/submit      (no body)
200: status becomes SUBMITTED and flow.currentStep becomes 4. Go to the verification screen.
400 with details.missing, for example ["pan", "bankDetails"]: take the vendor to the first missing part.
Steps 4 and 5: verification and verified
After submit the vendor waits while the team reviews. The app polls one small endpoint:
GET /vendor-onboarding/status

200 -> {
  "success": true,
  "data": {
    "id": "<applicationId>",
    "status": "SUBMITTED",
    "flow": { "currentStep": 4, "isVerified": false, "steps": [ ... ] },
    "reviewNote": null,
    "submittedAt": "2026-10-06T10:15:00.000Z",
    "reviewedAt": null
  }
}
Poll on screen open, on pull-to-refresh, and every 30 to 60 seconds while the screen is visible.
status
Screen to show
Notes
SUBMITTED
Verification in progress
Documents are being checked
PENDING_APPROVAL
Verification in progress
Documents verified, awaiting final approval
CHANGES_REQUESTED
Back to step 3
Show reviewNote. Call GET /vendor-onboarding to find rejected items and their rejectionReason, let the vendor fix them, then submit again
APPROVED
Verified (step 5)
flow.isVerified is true. Enter the main app
REJECTED
Not approved
Show reviewNote. The form is locked; only the team can reopen it, after which the status becomes CHANGES_REQUESTED

Routing on app launch
With a stored token, call GET /vendor-onboarding once at launch and route on flow.currentStep. It returns the full application, the same shape as in the OTP verify response.
flow.currentStep
Go to
3
Details form, opened at the part named in nextStep (or the submit screen when it is submit)
4
Verification in progress, or the "not approved" screen when status is REJECTED
5
Main app

With no stored token, or when the refresh fails, start at the phone number screen.
Errors and edge cases
Status
Meaning
What the app does
400
Validation failed or a rule was broken
Show message. For forms, details.fieldErrors maps each field name to its messages
401
Token missing or expired
Refresh once and retry; if that fails, sign out
403
Not allowed (admin number, deactivated account)
Show message
404
File not uploaded yet
Treat as "no image"
409
Application is not editable, a document is already verified, or the Aadhaar, PAN or bank account is registered on another account
Show message, then reload the application and re-route
503
Upload storage is not available on the server
Show a "try again later" message and report it to the backend team

Other points:
Showing uploaded images. profilePhoto, documents[].files.front / back and bankDetails.proofFile are API paths relative to the base URL, not public links. Fetch them with the Authorization header (for example through an authenticated image loader). They are served with no-store caching.
Multipart uploads. Send text fields and files in one multipart/form-data request and let the HTTP client set the Content-Type boundary. Compress camera photos to stay well under 5 MB.
Empty optional fields. Leave them out or send an empty string; both mean "not provided".
Double taps. A second submit returns 409; disable the button while a request is in flight.
Rate limit. The API allows 300 requests per 15 minutes per IP, so keep status polling at 30 seconds or slower.

