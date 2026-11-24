# WhatsApp donation groups

Poster editing, drafts, templates, rendering, export, and Android sharing use
local code. The groups screens use Firebase for the directory and moderation.

1. In Firebase Console, select the existing `blood-request-poster-maker`
   project on **Spark** and check that `com.awasigogera.blood` is registered.
2. In Cloud Firestore Standard, compare the published rules with
   `firestore.rules`. If they differ, publish the repository rules with
   `firebase deploy --only firestore:rules --project blood-request-poster-maker`.
3. Check that Anonymous and Email/Password sign-in are enabled and that the
   moderator's Firebase Authentication UID has a matching document in `admins`. The document
   can contain `active: true`. Remove the document to revoke moderation
   access. App clients cannot provision roles.
4. Android builds use `android/app/google-services.json` and select the
   `com.awasigogera.blood` client at build time. The moderation session uses a
   separate Firebase app instance with the same project configuration to keep
   the administrator and visitor sign-ins independent.
5. In the app, open the Home menu, choose Admin, and sign in with the
   moderator's Firebase account. Use Add to publish a group directly, or
   review a visitor's submission. Approved group names and invites are public.
   The app accepts an HTTPS WhatsApp group invite and strips query parameters.
   Each anonymous installation can have one pending suggestion at a time.

Validate with two app sessions. Submit a group as a visitor, confirm it remains
hidden, then approve it as the moderator and check that it appears in the live
list. Test reject, edit, delete, non-moderator login, WhatsApp opening and
poster creation with airplane mode enabled.
