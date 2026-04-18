# Bootstrap: New App From Template

Follow this document exactly when creating a new app from `flutter_template`. Run once per project — it is not project-specific and does not need to be re-specified.

**Prerequisites:** project CLAUDE.md exists (produced by brainstorming), Firebase project created in Firebase Console.

---

## Step 1: Copy template to new project directory

```bash
# Replace <appname> with your project slug (e.g. mealplanner, taskr, habitly)
rsync -av --exclude='.git' --exclude='build/' --exclude='.dart_tool/' \
  /Users/stephenmcnicholas/Developer/flutter_template/ \
  /Users/stephenmcnicholas/Developer/<appname>/
```

Then initialise a fresh git repo:

```bash
cd /Users/stephenmcnicholas/Developer/<appname>
git init
git add -A
git commit -m "chore: initialise from flutter_template"
```

---

## Step 2: Rename the app identity

**Four places to update.** Replace `com.fytter.app` / `com.example.fytter` / `fytter` with your new values.

### pubspec.yaml

```yaml
name: <appname>          # e.g. mealplanner
description: "<One line description>"
```

### iOS bundle ID

Edit `ios/Runner.xcodeproj/project.pbxproj` — replace every occurrence of `com.fytter.app` with your bundle ID (e.g. `com.stephenmcnicholas.mealplanner`):

```bash
sed -i '' 's/com\.fytter\.app/com.stephenmcnicholas.<appname>/g' \
  ios/Runner.xcodeproj/project.pbxproj
```

Verify: `grep PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj`

### Android application ID

Edit `android/app/build.gradle.kts` — replace `com.example.fytter`:

```bash
sed -i '' 's/com\.example\.fytter/com.stephenmcnicholas.<appname>/g' \
  android/app/build.gradle.kts
```

### App display name

- **iOS:** edit `ios/Runner/Info.plist` → `CFBundleDisplayName` and `CFBundleName`
- **Android:** edit `android/app/src/main/AndroidManifest.xml` → `android:label`

```bash
# iOS
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName <Display Name>" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName <Display Name>" ios/Runner/Info.plist

# Android — edit android:label in AndroidManifest.xml manually or via sed
sed -i '' 's/android:label="[^"]*"/android:label="<Display Name>"/' \
  android/app/src/main/AndroidManifest.xml
```

### Rename the database file

Edit `lib/src/data/app_database_connection_io.dart` — change `fytter.sqlite` to `<appname>.sqlite`.

---

## Step 3: Strip unused modules

Read the project CLAUDE.md → **Active modules** table. For each module marked **No**, follow its removal checklist in `modules/<name>/MODULE.md` exactly.

Commit after all removals:

```bash
git add -A
git commit -m "chore: strip unused modules per project spec"
```

---

## Step 4: Wire Firebase

In the Firebase Console, open your project and add two apps (iOS + Android) with the bundle ID / application ID from Step 2.

**iOS:**
1. Download `GoogleService-Info.plist`
2. Place at `ios/Runner/GoogleService-Info.plist`
3. Open Xcode (`open ios/Runner.xcworkspace`) and drag the plist into the Runner group — ensure "Copy items if needed" is checked

**Android:**
1. Download `google-services.json`
2. Place at `android/app/google-services.json`

These files contain API keys — they are already in `.gitignore`. Do not commit them.

---

## Step 5: Write project CLAUDE.md

Copy the template and fill it in:

```bash
cp processes/project-claude-md-template.md CLAUDE.md
```

Fill in every section: what the app is, active modules, domain vocabulary, Firebase project ID, key product decisions. This replaces the template's own `CLAUDE.md` in this project.

---

## Step 6: Create docs directory and move spec/plan

The spec and plan produced during brainstorming lived in `flutter_template`. Copy them into this project:

```bash
mkdir -p docs/superpowers/specs docs/superpowers/plans
cp /Users/stephenmcnicholas/Developer/flutter_template/docs/superpowers/specs/<spec-file>.md docs/superpowers/specs/
cp /Users/stephenmcnicholas/Developer/flutter_template/docs/superpowers/plans/<plan-file>.md docs/superpowers/plans/
```

Update the References section in `CLAUDE.md` to point to these files.

---

## Step 7: Install dependencies and regenerate code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` generated, no errors.

---

## Step 8: First run — verify clean start

```bash
flutter run -d "iPhone 16"
```

Expected: app launches to splash screen. No red screen, no crash.

If the app crashes, read the error — most common causes:
- Firebase not configured (missing plist / json)
- A module removal left a dangling import (run `flutter analyze`)

---

## Step 9: Create GitHub repo and push

```bash
gh repo create stephenmcnicholas/<appname> \
  --private \
  --description "<one line description>" \
  --source=. \
  --remote=origin \
  --push
```

---

## Step 10: Commit

```bash
git add -A
git commit -m "chore: bootstrap complete — app runs on simulator"
```

The project is ready. Begin the feature development loop.
