Sign-in & Tokens
Mr Bob customer app and vendor app - login and refresh flow
How the customer app and the vendor app sign in, stay signed in, and sign out.
Base URL https://home-services-backend-7cyx.onrender.com/api/v1
Live reference https://home-services-backend-7cyx.onrender.com/api-docs (section
"Sign-in & tokens (both apps)", first in the list)
Version 21 October 2026
The two tokens
Token What it is Lifetime Used for
accessToken Signed JWT 15 minutes
(accessTokenExpiresIn
seconds)
Sent on every API call
refreshToke
n
Opaque string
<sessionId>.<secret>
30 days after it was last used Only to get a new access token
The access token is short-lived so a leaked one is useless within minutes. The refresh token keeps the device signed
in: every refresh extends it by another 30 days, so a user who opens the app at least once a month never has to sign
in again.
Mr Bob - Sign-in & Tokens Guide Page 1
1. Signing in
Sign-in is a phone number and a 4-digit OTP. Always call *request* before *verify*.
Test OTP. No SMS provider is connected yet, so the server accepts one fixed 4-digit code for every number. Ask the
backend team for the current value.
App Step Call Body
Customer 1. Send code POST
{ "phone": "+919812345678" }
/customer-onboarding/otp/request
Customer 2. Verify POST
/customer-onboarding/otp/verify
{ "phone": "+919812345678",
"otp": "<4-digit code>" }
Vendor 1. Send code POST
{ "phone": "+919812345678" }
/vendor-onboarding/otp/request
Vendor 2. Verify POST /vendor-onboarding/otp/verify { "phone": "+919812345678",
"otp": "<4-digit code>" }
VERIFY RESPONSE (BOTH APPS)
{
"success": true,
"data": {
"accessToken": "eyJhbGciOiJIUzI1NiIs...",
"refreshToken": "6f1c2a9e-0b7d-4c3e-9a51-2d8e4f6a7b10.Qm9iLXNlc3Npb24t...",
"accessTokenExpiresIn": 900,
"...": "the user and onboarding details, as before"
}
}
Save all three securely, in the iOS Keychain or Android EncryptedSharedPreferences / Keystore, never in plain
preferences. Also save the moment the access token expires: *now + accessTokenExpiresIn seconds*.
A phone number is either a customer or a vendor. Customer endpoints return 403 for a vendor token and the other
way round.
2. Making API calls
Add this header to every call except sign-in, refresh and logout:
Authorization: Bearer <accessToken>
Files the API gives as paths (profile photos, work photos, invoice PDFs) need the same header. Download them with
the token; a plain link or image URL will not load.
3. Errors that mean "token problem"
Every 401 response carries a details.code:
{ "success": false, "message": "Access token expired", "details": { "code": "TOKEN_EXPIRED"
} }
details.code Meaning What the app does
TOKEN_EXPIRED The access token ran out (normal, every 15
minutes)
Refresh (section 4), then retry the same request
once
TOKEN_MISSING No Authorization header was sent A bug in the app: attach the token
Mr Bob - Sign-in & Tokens Guide Page 2
details.code Meaning What the app does
TOKEN_INVALID The token is damaged or not ours Clear tokens and show sign-in
SESSION_EXPIRED Returned by /auth/refresh: the session is over Clear tokens and show sign-in
A 403 is not a token problem: the user is signed in but not allowed to do that (wrong role, not their booking, vendor not
approved yet). Show the message.
Mr Bob - Sign-in & Tokens Guide Page 3
4. Refreshing the access token
REQUEST
POST /auth/refresh
Content-Type: application/json
{ "refreshToken": "6f1c2a9e-0b7d-4c3e-9a51-2d8e4f6a7b10.Qm9iLXNlc3Npb24t..." }
SUCCESS (200)
{
"success": true,
"data": {
)",
"accessToken": "eyJhbGciOiJIUzI1NiIs...(new)",
"refreshToken": "6f1c2a9e-0b7d-4c3e-9a51-2d8e4f6a7b10.Qm9iLXNlc3Npb24t...(same as before
"accessTokenExpiresIn": 900
}
}
• Save the new accessToken and its new expiry time.
• The refreshToken stays the same. Still save whatever comes back, in case that changes later.
• Each successful refresh extends the session by another 30 days.
Failure (401, SESSION_EXPIRED): the refresh token was not used for 30 days, the user logged out, or the account was
deactivated or deleted. Clear the tokens and show sign-in.
Refresh tokens issued before 21 October 2026 (they look like a JWT) still work once and are then replaced by the
new kind in the response, so existing users are not signed out.
5. When to refresh
Do both:
• Before calls (recommended): if the access token expires in less than 60 seconds, refresh first, then make the
call.
• On error (safety net): if a call still returns 401 TOKEN_EXPIRED, refresh and retry that call once. If the retry fails
again, do not loop.
Only one refresh at a time. If several calls need a refresh together, they should all wait for one shared refresh
request. (Two at once would still work, because the refresh token does not change, but one is cleaner.)
Coming back to the foreground after a long time in the background: check the expiry and refresh before the first
call.
Network errors and 5xx during refresh are not sign-outs. Keep the tokens, show the usual "no connection" state
and try again later. Only a 401 from /auth/refresh (SESSION_EXPIRED), or TOKEN_INVALID, means sign the user out.
Mr Bob - Sign-in & Tokens Guide Page 4
PSEUDOCODE FOR THE HTTP CLIENT
function request(call):
if tokens.accessExpiresAt - now < 60 seconds:
refreshOnce() // concurrent callers share the same refresh
response = send(call with "Authorization: Bearer " + tokens.access)
if response.status == 401 and response.details.code == "TOKEN_EXPIRED" and not call.retr
ied:
refreshOnce()
call.retried = true
return request(call)
if response.status == 401 and response.details.code in ["TOKEN_INVALID", "SESSION_EXPIRE
D"]:
signOutLocally()
return response
function refreshOnce():
if refreshInProgress: return await refreshInProgress
refreshInProgress = POST /auth/refresh { refreshToken: tokens.refresh }
result = await refreshInProgress
refreshInProgress = null
if result.ok:
tokens.access = result.data.accessToken
tokens.refresh = result.data.refreshToken
tokens.accessExpiresAt = now + result.data.accessTokenExpiresIn seconds
else if result.status == 401:
signOutLocally()
// network error or 5xx: keep the tokens and show a connection error
function signOutLocally():
delete the stored tokens
show the sign-in screen
Mr Bob - Sign-in & Tokens Guide Page 5
6. Logging out
When the user taps Log out:
REQUEST
POST /auth/logout
Content-Type: application/json
{ "refreshToken": "<the refresh token>" }
Response: { "success": true, "data": { "signedOut": true } }. It always succeeds. Then delete the stored
tokens and show the sign-in screen.
After logout the refresh token no longer works. The old access token could work for up to 15 more minutes, but the
app has deleted it.
Deleting the account (DELETE /customer/profile or DELETE /vendor/profile) also ends every session: clear
the tokens afterwards too.
7. Signed out without logging out
The next refresh returns SESSION_EXPIRED when:
Situation Why
The app was not used for 30 days The session expired
An admin deactivated the account All the user's sessions are ended on every device
The account was deleted All sessions are ended
Send the user to sign-in with a short message such as "Please sign in again".
8. Checklist
Item
[ ] Save accessToken, refreshToken and the expiry time from the OTP verify response, in secure storage
[ ] Send Authorization: Bearer <accessToken> on every call, including file downloads
[ ] Refresh when under 60 seconds remain, and when the app returns to the foreground
[ ] On 401 TOKEN_EXPIRED: refresh once, retry once
[ ] Share a single in-flight refresh across concurrent calls
[ ] On SESSION_EXPIRED / TOKEN_INVALID: clear the tokens and show sign-in
[ ] Do not sign out on network errors or 5xx
[ ] Log out with POST /auth/logout, then clear the tokens
Mr Bob - Sign-in & Tokens Guide Page 6lease 