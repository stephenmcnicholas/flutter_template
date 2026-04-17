# Fytter Cloud Functions

Workout reminder push notifications: a scheduled function runs every 15 minutes and sends FCM to users when it's their reminder time in their timezone.

## Prerequisites

- Node 20
- Firebase CLI: `npm install -g firebase-tools`
- Logged in: `firebase login`
- Project: `firebase use fytter-df3e7` (or your project ID)

## Setup

```bash
cd functions
npm install
```

## Deploy

### Redeploy all Cloud Functions (step-by-step)

1. **Open a terminal** and go to the Fytter project root:
   ```bash
   cd /Users/stephenmcnicholas/Developer/flutter_projects/fytter
   ```

2. **Confirm Firebase CLI and project**
   - If you haven’t already: `npm install -g firebase-tools` then `firebase login`
   - Use the correct project:
     ```bash
     firebase use fytter-df3e7
     ```
   - Check: `firebase projects:list` and ensure the active project is the one you want.

3. **Install dependencies and build** (from project root):
   ```bash
   cd functions
   npm install
   npm run build
   ```
   - If `npm run build` fails, fix any TypeScript errors before deploying.

4. **Deploy**
   - **Option A — Deploy only the AI programme function** (faster, use after prompt/code changes in `generateProgram`):
     ```bash
     cd /Users/stephenmcnicholas/Developer/flutter_projects/fytter
     firebase deploy --only functions:generateProgram
     ```
   - **Option B — Deploy all Cloud Functions**:
     ```bash
     cd /Users/stephenmcnicholas/Developer/flutter_projects/fytter
     firebase deploy --only functions
     ```
     Or from inside `functions/`: `npm run deploy`

5. **Confirm**
   - The CLI will print the function URL(s) and “Deploy complete”.
   - To view logs: `firebase functions:log` (or `firebase functions:log --only generateProgram`).

---

**One-liner from project root (all functions):**
```bash
cd functions && npm install && npm run build && cd .. && firebase deploy --only functions
```

**One-liner to redeploy only generateProgram:**
```bash
cd functions && npm run build && cd .. && firebase deploy --only functions:generateProgram
```

## Firestore structure (written by the app)

- `users/{uid}`: `fcmToken`, `timezoneOffsetMinutes`, `updatedAt`
- `users/{uid}/dailySchedule/{yyyy-MM-dd}`: map of `minuteOfDay` (string) → list of workout names

The function reads these and sends one notification per user per time slot when the user's local time matches.
