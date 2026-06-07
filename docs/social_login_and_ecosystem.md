# AdsyClub — Social Login + Profile Completion (Phase 1)

This document covers everything implemented in Phase 1 of the "Assistant
Ecosystem" and the configuration still required to ship it to production.

## What was implemented

### Backend (Django)
- **`POST /api/auth/social/`** — `base/views.py` `social_login()`.
  Accepts `{ "provider": "google"|"facebook", "id_token": "<firebase id token>" }`.
  Verifies the token with the Firebase Admin SDK (already initialized in
  `base/fcm_service.py`), finds-or-creates the `User` by email, imports the
  provider name/photo, and returns the same `{ refresh, access, user, created }`
  shape as the normal login endpoint.
- **Profile completion** — `base/serializers.py`:
  - `PROFILE_COMPLETION_STEPS` + `compute_profile_completion()`.
  - `ProfileCompletionMixin` adds `profile_completion` (int %) and
    `missing_steps` (`[{key,label}]`) to `UserSerializer` and
    `UserSerializerGet`. No DB migration — computed from existing fields
    (photo, name, phone, about, address, profession, date_of_birth, gender).
- Route registered in `base/urls.py` (`auth/social/`).

### Flutter (oxius_native)
- `services/social_auth_service.dart` — Firebase sign-in for Google
  (`google_sign_in`) and Facebook (`flutter_facebook_auth`); returns a Firebase
  ID token.
- `services/auth_service.dart` — `AuthService.socialLogin(provider)`; `User`
  model now parses `profile_completion` + `missing_steps`; logout signs out of
  social providers.
- `widgets/social_login_buttons.dart` — shared Google/Facebook button row.
- `widgets/profile_completion_sheet.dart` — bottom sheet shown once after login
  when the profile is incomplete; "Complete Profile" → `/settings`.
- `pages/login_page.dart` & `pages/register_page.dart` — social buttons +
  handlers; queue the completion sheet via `markPendingIfNeeded`.
- `screens/home_screen.dart` — shows the queued sheet once after login.
- `pubspec.yaml` — added `google_sign_in`, `flutter_facebook_auth`.

## Configuration required before it works in production

### 1. Firebase Console (for Google sign-in)
The current `android/app/google-services.json` has an **empty `oauth_client`**,
so Google sign-in will not work until:
1. Firebase Console → **Authentication → Sign-in method** → enable **Google**.
2. Firebase Console → **Project settings → Your apps (Android `com.oxius.app`)**
   → add the **SHA-1 and SHA-256** fingerprints for both your debug and
   **release/upload** keystores.
   - Get them with:
     `keytool -list -v -keystore <your.keystore> -alias <alias>`
3. **Re-download `google-services.json`** and replace
   `android/app/google-services.json` (it will now contain a `client_type: 3`
   web client — required by `google_sign_in` + Firebase).

### 2. Firebase Console + Facebook (for Facebook sign-in)
1. Create an app at https://developers.facebook.com/apps (Facebook Login product).
2. Firebase Console → **Authentication → Sign-in method** → enable **Facebook**,
   paste the Facebook **App ID** and **App Secret**. Copy the **OAuth redirect
   URI** Firebase shows and paste it into Facebook → Facebook Login → Settings →
   Valid OAuth Redirect URIs.
3. Fill `android/app/src/main/res/values/strings.xml`:
   - `facebook_app_id` = numeric App ID
   - `facebook_client_token` = Facebook → Settings → Advanced → Client Token
   - `fb_login_protocol_scheme` = `fb<App ID>` (e.g. `fb1234567890`)
4. Add your release key hash in the Facebook app's Android settings.

### 3. Backend deploy (when server access is provided)
- No new pip packages required (`firebase_admin`, `google-auth`, `requests`
  already in `requirements.txt`).
- Ensure `firebase-adminsdk.json` is present on the server (already used by FCM).
- Run `python manage.py collectstatic` if needed; no migrations are required for
  Phase 1.
- Restart the app server (gunicorn/daphne) so the new route loads.

## Quick test (after config)
```bash
# Get a Firebase ID token from the app, then:
curl -X POST https://adsyclub.com/api/auth/social/ \
  -H "Content-Type: application/json" \
  -d '{"provider":"google","id_token":"<FIREBASE_ID_TOKEN>"}'
# Expect: { "refresh": "...", "access": "...", "user": {...}, "created": true|false }
```

## Roadmap (next phases — not yet built)
- **Phase 2**: `UserEvent` tracking model + `track()` helper wired into existing
  views (register, post, order, message).
- **Phase 3**: `GrowthTask` / `UserTaskProgress` / `Badge` / `UserBadge` /
  `PointsLedger` + "Congratulations" UI.
- **Phase 4**: generic in-app `Notification` model + Celery-beat behavior-driven
  nudges over the existing FCM pipeline.
- **Phase 5**: feed personalization / recommendations / AI helpers (needs Phase 2
  data first).
