# Work progress

Working branch: feat/offline-poster-maker. Target: main.

| Milestone | Status |
| --- | --- |
| M0 | Existing repository and main verified; feature branch created. Flutter 3.50.1 selected from the official stable archive. |
| M1 | Requirements and rendering specification captured. Actual device proof is pending. |
| M2 | Editor, localization, first-launch selection, and local draft code written. |
| M3–M4 | Twelve template definitions and shared preview/export painter written. Visual acceptance remains pending. |
| M5 | Android document save, PNG/JPEG, Sharesheet, and configurable invitation code written. Verified public installer URL is unavailable. |
| M6 | Unit, rendering, and integration tests and CI configuration authored. Device and manual acceptance are pending. |
| M7 | Owner-controlled release signer is unavailable. Build artifacts and signing must be verified separately. |
| M8 | Merge gated on all mandatory verification. Public release requires owner approval. |

The local Flutter project-creation command was rejected by automated review after the runner detected an instance metadata endpoint request. Android project files were assembled from the SDK templates and GitHub-hosted CI is configured for verification. The local environment lacks /dev/kvm. No check is recorded as passed here without observed evidence.
