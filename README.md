# Flutter Supabase To-Do App

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
