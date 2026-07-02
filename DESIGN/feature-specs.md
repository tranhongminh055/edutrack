# EduTrack — Feature Specs (Developer-ready)

This document summarizes the developer-ready specification for the requested features: Quiz Flow, Course Enrollment, Resources (upload/preview), Announcements, Notifications & Calendar. It complements the service templates in `elearning-web/src/services/`.

## Quick links
- Services templates: `elearning-web/src/services/` (quizService, enrollmentService, resourceService, announcementService, notificationService)

## Goals
- Provide safe, incremental backend and frontend features.
- Maintain security: only describe and add service wrappers — no breaking changes.

## Firestore Schemas
- See earlier design notes in project handoff (use same collection names: `elearning_quizzes`, `quiz_submissions`, `quiz_drafts`, `course_resources`, `announcements`, `enrollments`, `notifications_{userId}`).

## Services
- Templates were added under `elearning-web/src/services/`.
- These are minimal wrappers using Firebase modular SDK intended as a safe starting point.

## Developer notes
- The service templates perform basic auth checks via `getAuth().currentUser` and throw if not authenticated.
- `quizService.submitQuiz` computes an automatic score for multiple choice questions client-side and writes a submission document; for production you should move scoring to a Cloud Function for authoritative enforcement and anti-tampering.
- `notificationService` uses a per-user collection name `notifications_{userId}` to avoid nested subcollections complexity; adjust to `users/{uid}/notifications` if preferred.

## Next steps for implementers
1. Review security rules and add Firestore/Storage rules that match the schemas. Use server-side validation in Cloud Functions where trust is required (scoring/time enforcement).
2. Integrate the service templates into existing components (e.g., wire `TakeQuizView` to `quizService.startSubmission`, autosave to `saveDraft`, submit to `submitQuiz`).
3. Add Cloud Functions for `submitQuiz` (server-side scoring), scheduled announcement publishing, and any manual-grade endpoints.
4. Add tests: unit (scoring), integration (autosave/restore), E2E (full flows).

## Files added
- `elearning-web/src/services/quizService.js`
- `elearning-web/src/services/enrollmentService.js`
- `elearning-web/src/services/resourceService.js`
- `elearning-web/src/services/announcementService.js`
- `elearning-web/src/services/notificationService.js`

---
If you want, I can now:
- wire `TakeQuizView` to these services (implement front-end integration), or
- create Cloud Function stubs for server-side scoring and scheduled publishing.
