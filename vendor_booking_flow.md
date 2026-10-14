Vendor Booking Flow
Mr Bob vendor app - API guide
Base URL https://home-services-backend-7cyx.onrender.com/api/v1
Live reference (try any call) https://home-services-backend-7cyx.onrender.com/api-docs
Version 14 October 2026
How the vendor app takes a booking and carries it through: see open jobs, accept one, start it with the customer's
start code, enter the completion code, upload photos of the finished work, and complete it.
Each endpoint below lists its request fields and an example request. Full example responses for every call are in the
live reference.
CONTENTS
Before you start
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 2
Taking and doing a job
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 4
My jobs
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 6
Mr Bob - Vendor Booking Flow API Guide Page 1
Before you start
Who can call these. A signed-in vendor: send Authorization: Bearer <accessToken> on every call, using the
token from vendor onboarding's OTP step. The job endpoints also need the vendor to be approved; before that they
return 403.
Requests. Send JSON with Content-Type: application/json, except the photo upload, which is
multipart/form-data. Paths are relative to the base URL, so GET /vendor/jobs/available means GET
https://home-services-backend-7cyx.onrender.com/api/v1/vendor/jobs/available.
Responses. A single item comes back as { "success": true, "data": ... }. A list comes back as {
"success": true, "items": [...], "meta": { "page", "limit", "total", "totalPages" } }. Lists accept
page and limit (up to 100).
The two codes. Starting and completing a job each need a 4-digit code. The codes are shown in the customer's
app, on their booking, and the customer reads them out. The vendor app is never sent them: in every vendor
response otp is null. After 5 wrong tries a code is replaced and the customer sees the new one.
Test codes. While no SMS provider is connected, the server uses one fixed 4-digit code for logins, and the job start
and completion codes use that same value. Ask the backend team for it.
Errors. Any failure is { "success": false, "message": "...", "details": ... }. Show message to the vendor.
Photos. JPEG, PNG or WebP, up to 5 MB each, 1 to 5 per job. Each entry in completionImages has a url; add it to
the base URL and fetch it with the token.
What the booking response carries. Besides the booking itself: job.nextStep and job.completionOtpVerified
for the vendor's next button, completionImages for the photos, customer and the full address once the job is
accepted, and actions.canCollectPayment when the vendor should take payment on site.
Wallet. Completing a job adds its amount to the vendor's wallet, on hold for 2 days. The wallet endpoints are not part
of this guide.
Booking statuses
Status When it happens in this flow
400 Wrong code (the message says how many tries are left), a code that is not 4 digits, a file
that is not an image, or more than 5 photos
401 Token missing or expired: refresh it and retry once
403 The vendor is not approved yet, or the job belongs to another vendor
404 The open job has been taken, or the photo does not exist
409 The step is not possible now: another vendor took the job, the job is in the wrong status,
the completion code is not verified yet, or no photo is uploaded yet
503 File storage is not configured on the server: tell the backend team
Status Meaning
AWAITING_PAYMENT Online payment chosen and not completed yet
PENDING Confirmed; waiting for a vendor to take it
MATCHING The team is looking for a vendor
ASSIGNED A vendor has it. The customer's booking shows otp.start
IN_PROGRESS Started with the start code. The customer's booking shows otp.completion
COMPLETED Finished; the amount is added to the vendor's wallet
Mr Bob - Vendor Booking Flow API Guide Page 2
Status Meaning
CANCELLED Cancelled by the customer or the team
The job, end to end
Step Customer app Vendor app
1 Creates a booking Sees it in open jobs
2 Is told a vendor is assigned; booking shows the start
code
Accepts the job; now sees the customer and address
3 Reads the start code to the vendor at the door Enters it to start the job
4 Booking now shows the completion code; reads it
out when the work is done
Enters the completion code
5 Can see the photos on the booking Uploads photos of the finished work, then completes
the job
6 Is told the job is complete The amount is added to the wallet
Mr Bob - Vendor Booking Flow API Guide Page 3
Taking and doing a job
Only an approved vendor can use these; until a super admin approves the vendor they return 403. Every step returns
the booking, and job.nextStep says which screen comes next: START, VERIFY_COMPLETION_OTP, UPLOAD_IMAGES,
COMPLETE, then null once the job is done.
Method Endpoint What it does
GET /vendor/jobs/available Step 1 — jobs I can take
GET /vendor/jobs/available/{id} Step 1 — one open job
POST /vendor/jobs/{id}/accept Step 2 — take the job
POST /vendor/jobs/{id}/start Step 3 — start with the customer's start code
POST /vendor/jobs/{id}/completion-otp Step 4 — enter the customer's completion code
POST /vendor/jobs/{id}/completion-images Step 5 — upload photos of the finished work
DELETE /vendor/jobs/{id}/completion-images/{imageId} Step 5 — remove a photo
POST /vendor/jobs/{id}/complete Step 6 — complete the job
GET /vendor/jobs/available
Step 1 — jobs I can take | Professionals (vendors) only.
Bookings nobody has taken yet, for a service the vendor offers, in the vendor's city. Soonest first.
QUERY PARAMETERS
Name Meaning
page Page number, starting at 1
limit Items per page
GET /vendor/jobs/available/{id}
Step 1 — one open job | Professionals (vendors) only.
Returns 404 once someone has taken it.
POST /vendor/jobs/{id}/accept
Step 2 — take the job | Professionals (vendors) only.
The first vendor to accept gets it; anyone after gets 409. The booking becomes ASSIGNED, the customer is notified and
their app shows the start code. The response now includes the customer and the full address.
POST /vendor/jobs/{id}/start
Step 3 — start with the customer's start code | Professionals (vendors) only.
The booking becomes IN_PROGRESS and the customer's app shows the completion code. A wrong code returns 400
and says how many tries are left.
REQUEST BODY (JSON)
Field Type Required Notes
otp string Yes The 4-digit code the customer reads out
EXAMPLE
{
"otp": "<4-digit code>"
}
Mr Bob - Vendor Booking Flow API Guide Page 4
POST /vendor/jobs/{id}/completion-otp
Step 4 — enter the customer's completion code | Professionals (vendors) only.
Confirms with the customer that the work is done. A wrong code returns 400. Calling it again once verified does
nothing.
REQUEST BODY (JSON)
Field Type Required Notes
otp string Yes The 4-digit code the customer reads out
EXAMPLE
{
}
"otp": "<4-digit code>"
POST /vendor/jobs/{id}/completion-images
Step 5 — upload photos of the finished work | Professionals (vendors) only.
Send as multipart/form-data with one or more files in images. JPEG, PNG or WebP, up to 5 MB each, at most 5
photos per job (across all uploads). Can be called more than once while the job is in progress.
REQUEST BODY (multipart/form-data)
Field Type Required Notes
images file Yes
DELETE /vendor/jobs/{id}/completion-images/{imageId}
Step 5 — remove a photo | Professionals (vendors) only.
Only while the job is in progress.
POST /vendor/jobs/{id}/complete
Step 6 — complete the job | Professionals (vendors) only.
Needs the completion code verified and at least one photo, otherwise 409. The booking becomes COMPLETED, the
customer is notified, and the job's amount is added to the vendor's wallet (on hold for 2 days).
Mr Bob - Vendor Booking Flow API Guide Page 5
My jobs
The jobs the vendor has accepted or been assigned, for the "My jobs" list and the job detail screen. Recording a cash,
UPI or card payment taken on site is here too.
Method Endpoint What it does
GET /vendor/bookings List my jobs
GET /vendor/bookings/{id} Get one of my jobs
GET /bookings/{id}/completion-images/{imageId} Download a photo of the finished work
POST /bookings/{id}/payment/collect Record payment collected in person
GET /vendor/bookings
List my jobs | Professionals (vendors) only.
The bookings assigned to the signed-in vendor, newest first. Use scope=upcoming for current jobs and scope=past
for history.
QUERY PARAMETERS
Name Meaning
status scope One status, or several separated by commas. One of: AWAITING_PAYMENT, PENDING,
MATCHING, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED
upcoming = not finished yet, past = completed or cancelled. Ignored when status is given.
sortBy Field to sort by
sortOrder Sort direction
page Page number, starting at 1
limit Items per page
GET /vendor/bookings/{id}
Get one of my jobs | Professionals (vendors) only.
The booking with its timeline, the customer to visit, the address and the payment. actions.canCollectPayment says
whether the vendor should take payment on site. Returns 403 for a booking that is not assigned to this vendor.
GET /bookings/{id}/completion-images/{imageId}
Download a photo of the finished work | Any signed-in user.
The url of each entry in a booking's completionImages points here. Available to the booking's customer, the vendor
on the job, and admins.
POST /bookings/{id}/payment/collect
Record payment collected in person | Professionals (vendors) only. Admins and super admins.
For PAY_AFTER_SERVICE bookings, once the job is IN_PROGRESS or COMPLETED: records that the professional took the
money. By the assigned professional or an admin. Returns 409 if it was already collected or the job has not started.
REQUEST BODY (JSON)
Field Type Required Notes
method CASH | UPI | CARD Yes
EXAMPLE
Mr Bob - Vendor Booking Flow API Guide Page 6
{
"method": "UPI"
}
Mr Bob - Vendor Booking Flow API Guide Page 7