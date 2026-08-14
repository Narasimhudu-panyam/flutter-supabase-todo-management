# Flutter Supabase To-Do App

## Architecture Updates (Offline-First)

This application has been updated to support offline-first capabilities, local task reminders, and robust background synchronization.

### Offline-First & Sync
- **Local Database**: Powered by `sqflite`. The UI reads and writes to the local SQLite database first, allowing full offline access and fast interactions.
- **Sync Queue**: A dedicated `sync_queue` table tracks pending CRUD operations when offline.
- **SyncManager**: Uses `connectivity_plus` to automatically detect when internet is restored and processes pending queue items against Supabase.
- **Conflict Resolution**: Implements a Last-Write-Wins strategy based on `updated_at` timestamps to safely merge remote realtime updates with local state.

### Task Reminders
- Powered by `flutter_local_notifications` and `timezone`.
- Users can set precise reminder dates/times (in device local timezone) for tasks.
- Background alarms trigger native push notifications, even if the app is closed.

### Security
- Sensitive tokens are securely managed natively by `supabase_flutter`.
- Secure dependencies like `flutter_secure_storage` are included for any future client-side sensitive persistence requirements.

## Testing & Build

To test the application:
```bash
flutter test
```

To build a release APK:
```bash
flutter build apk --release
```

---

## Android Google Sign-In setup

This app uses Supabase's browser OAuth flow. It does **not** use the native
`google_sign_in` plugin or `google-services.json`; neither is required for this
flow.

The Android callback is:

```
io.supabase.flutter://login-callback/
```

Before testing Google sign-in, configure these two external settings:

1. In **Supabase Dashboard → Authentication → URL Configuration**, add the
   callback above to **Redirect URLs**. It must include the trailing slash.
2. In **Supabase Dashboard → Authentication → Providers → Google**, enable
   Google and set the Google OAuth client ID and secret. In Google Cloud Console,
   the web OAuth client's authorized redirect URI must be the Supabase callback
   URL shown on that provider page, normally:
   `https://<project-ref>.supabase.co/auth/v1/callback`.

The callback is declared in `android/app/src/main/AndroidManifest.xml` and
passed to `signInWithOAuth` from `lib/services/auth_service.dart`. They must
always remain identical.

### Email confirmation and password recovery

The same callback is used for signup confirmation and password-recovery email.
In **Supabase Dashboard → Authentication → Email Templates**, the **Confirm
signup** template must link to `{{ .ConfirmationURL }}`. Do not replace it with
`{{ .SiteURL }}` or a `localhost` URL. `ConfirmationURL` preserves the app's
`emailRedirectTo` value, so opening the email confirms the user first and then
returns to Android.

Keep `io.supabase.flutter://login-callback/` in **Redirect URLs**. The Site URL
may remain a web URL, such as `http://localhost`, because the app supplies an
explicit redirect URL for email actions.

Supabase automatically links a verified Google identity and a verified email
identity when their email addresses match. A Google-only account has no password
by design, so email/password login is unavailable until the user uses **Forgot
Password** and sets one in the app's recovery screen.
