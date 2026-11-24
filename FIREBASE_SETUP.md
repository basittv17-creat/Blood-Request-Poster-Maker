# WhatsApp donation groups

Poster editing, drafts, templates, rendering, export, and Android sharing use
local code. The groups page connects to Firebase only when opened.

1. In Firebase Console, create a project on **Spark**, leave billing disabled,
   and register the Android application `com.awasigogera.blood`.
2. Create a Cloud Firestore Standard database in production mode. Deploy the
   repository rules with `firebase deploy --only firestore:rules --project PROJECT_ID`.
3. Enable the Anonymous and Email/Password sign-in providers. Create the
   moderator's Firebase Authentication account in the console. Add a document
   named with that account's UID to `admins` from the console. The document
   can contain `active: true`. Remove the document to revoke moderation
   access. App clients cannot provision roles.
4. For a local build, set the Android Firebase client configuration with
   `--dart-define-from-file=PATH`. Use a JSON object with
   `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, and
   `FIREBASE_SENDER_ID`. For GitHub Actions, define repository variables with
   the same names. Use the registered Android app values from Firebase.
   Never put an admin password or service-account credential in the file or
   repository.
5. In the app, open the Home menu, choose Admin, and sign in with the
   moderator's Firebase account. Use Add to publish a group directly, or
   review a visitor's submission. Approved group names and invites are public.
   The app accepts an HTTPS WhatsApp group invite and strips query parameters.
   Each anonymous installation can have one pending suggestion at a time.

Validate with two app sessions. Submit a group as a visitor, confirm it remains
hidden, then approve it as the moderator and check that it appears in the live
list. Test reject, edit, delete, non-moderator login, WhatsApp opening and
poster creation with airplane mode enabled.
