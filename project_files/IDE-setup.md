**QuizziO project skeleton compiling in VS Code**

## 🎯 Product Overview

**QuizziO** is a mobile app that enables teachers and professors to instantly grade multiple-choice quizzes using on-device OMR (Optical Mark Recognition) scanning. Teachers after create quizzes, set answer keys, and grade student papers by simply pointing their camera at the answer sheet.

---

## 🧩 TL;DR – Setup Phases

1. **Toolchain & IDE** – Flutter, Xcode, Android Studio, VS Code (from previous steps).
2. **Create project & pubspec** – Add your dependencies + assets config.
3. **Create folder structure** – Exactly as you specified under `lib/` and `assets/`.
4. **Wire base app** – `main.dart`, `app.dart`, and a minimal `QuizzesPage` as home.
5. **Set up DI/Hive/init shell** – `get_it` + `injectable` + `hive` basic bootstrap.
6. **Platform config** – Android/iOS permissions for camera, pods, run on device.

Below is what Codex should actually do step-by-step 👇

---

## 0️⃣ Prereqs (Quick Checklist)

Codex should already have (from earlier instructions):

* Flutter SDK installed & in `PATH`
* `flutter doctor` mostly clean
* Xcode + iOS command line tools
* Android Studio + SDK + emulator (optional)
* VS Code + Flutter & Dart extensions
* CocoaPods installed

If any of that’s missing, fix that first.

---

## 1️⃣ Create the Flutter Project & Apply `pubspec.yaml`

From terminal:

```bash
cd ~/development   # or wherever you keep projects
flutter create quizzio
cd quizzio
```

Open the project in VS Code:

```bash
code .
```

Now replace the generated `pubspec.yaml` dependencies with **your stack** (what you pasted to me). Make sure:

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'
```

And under `flutter:` add:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/templates/
    - assets/templates/marker.png
    - assets/templates/template_10q.json
    - assets/templates/template_20q.json
    - assets/templates/template_50q.json
```

Then install:

```bash
flutter pub get
```

If there are any version conflicts—fix them now before going further.

---

## 2️⃣ Create the Project Structure Under `lib/`

From the project root:

```bash
mkdir -p lib/core/constants
mkdir -p lib/core/errors
mkdir -p lib/core/services
mkdir -p lib/core/utils
mkdir -p lib/core/extensions

mkdir -p lib/features/quiz/data/models
mkdir -p lib/features/quiz/data/datasources
mkdir -p lib/features/quiz/data/repositories
mkdir -p lib/features/quiz/domain/entities
mkdir -p lib/features/quiz/domain/repositories
mkdir -p lib/features/quiz/domain/usecases
mkdir -p lib/features/quiz/presentation/bloc
mkdir -p lib/features/quiz/presentation/pages
mkdir -p lib/features/quiz/presentation/widgets

mkdir -p lib/features/omr/data/models
mkdir -p lib/features/omr/data/datasources
mkdir -p lib/features/omr/data/repositories
mkdir -p lib/features/omr/domain/entities
mkdir -p lib/features/omr/domain/repositories
mkdir -p lib/features/omr/domain/usecases
mkdir -p lib/features/omr/services
mkdir -p lib/features/omr/presentation/bloc
mkdir -p lib/features/omr/presentation/pages
mkdir -p lib/features/omr/presentation/widgets

mkdir -p lib/features/export/data/repositories
mkdir -p lib/features/export/domain/usecases
mkdir -p lib/features/export/services
mkdir -p lib/features/export/presentation/widgets
```

Then create the **key files** (at minimum) so the project compiles:

```bash
touch lib/app.dart
touch lib/core/constants/app_constants.dart
touch lib/core/constants/omr_constants.dart
touch lib/core/errors/failures.dart
touch lib/core/errors/exceptions.dart
touch lib/core/services/camera_service.dart
touch lib/core/utils/image_utils.dart
touch lib/core/utils/math_utils.dart
touch lib/core/extensions/list_extensions.dart

touch lib/features/quiz/presentation/pages/quizzes_page.dart
touch lib/features/quiz/presentation/bloc/quiz_bloc.dart
touch lib/features/quiz/presentation/widgets/quiz_card.dart
touch lib/features/quiz/presentation/widgets/new_quiz_dialog.dart

touch lib/features/omr/presentation/pages/scan_papers_page.dart
touch lib/features/omr/presentation/pages/graded_papers_page.dart

touch lib/features/export/services/pdf_export_service.dart
touch lib/features/export/presentation/widgets/export_button.dart
```

You **don’t** need to implement all models/usecases/repos right now—just the shells for core entry points so the app runs.

---

## 3️⃣ Add Assets Folder for Templates

From project root:

```bash
mkdir -p assets/templates
```

Drop in:

* `marker.png`
* `template_10q.json`
* `template_20q.json`
* `template_50q.json`

(These can initially be placeholder files; real content can come later, but paths must exist for Flutter.)

---

## 4️⃣ Wire Up `main.dart` and `app.dart`

### `lib/main.dart`

Make it minimal but production-ready-ish:

```dart
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: initialize DI, Hive, etc. here when ready.
  // await configureDependencies();
  // await initLocalStorage();

  runApp(const QuizziOApp());
}
```

### `lib/app.dart`

This will be your root `MaterialApp` pointing to **Screen 1 – Quizzes**:

```dart
import 'package:flutter/material.dart';
import 'features/quiz/presentation/pages/quizzes_page.dart';

class QuizziOApp extends StatelessWidget {
  const QuizziOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizziO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const QuizzesPage(),
    );
  }
}
```

---

## 5️⃣ Minimal UI Shell for Quizzes Page (Screen 1)

`lib/features/quiz/presentation/pages/quizzes_page.dart`:

```dart
import 'package:flutter/material.dart';

class QuizzesPage extends StatelessWidget {
  const QuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We’ll wire Bloc + real UI later. For now, just a stub screen.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
      ),
      body: const Center(
        child: Text('Quizzes list will appear here'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: open NewQuizDialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

This ensures the app **boots successfully** even before you plug in blocs, repositories, etc.

---

## 6️⃣ Set Up DI & Hive Bootstrap (Prereq, but Stubbed)

You’re using `get_it` + `injectable` + `hive`. Let’s set up the minimal DI entry so it’s ready when models/usecases arrive.

### 6.1 Create `lib/injection.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
}
```

> Note: `injection.config.dart` is generated by `injectable_generator` using build_runner. For now, this will fail until you add annotations. So:

* **Option A (recommended)**: Comment out `configureDependencies()` call in `main.dart` until you annotate services/repos.
* **Option B**: Add basic `@module` or `@injectable` classes and run build_runner now.

For **initial bring-up**, it’s perfectly fine to **delay** DI wiring until core screens and repositories exist.

### 6.2 Plan for Hive init

Later, in `main()` you’ll have something like:

```dart
// await Hive.initFlutter();
// Hive.registerAdapter(QuizAdapter());
// Hive.registerAdapter(AnswerKeyAdapter());
```

For now, leave these as TODO comments so main.dart still compiles.

---

## 7️⃣ Platform Config for Camera & Permissions

### 7.1 Android – `AndroidManifest.xml`

`android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.CAMERA" />

    <application
        android:name="${applicationName}"
        android:label="QuizziO"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

Check `android/app/build.gradle`:

```gradle
defaultConfig {
    applicationId "com.yourcompany.quizzio"
    minSdkVersion 21
    targetSdkVersion 34
    // ...
}
```

### 7.2 iOS – `Info.plist`

`ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>QuizziO needs camera access to scan answer sheets.</string>
```

Then:

```bash
cd ios
pod install
cd ..
```

---

## 8️⃣ Sanity Check: Run the Barebones App

From the project root:

```bash
flutter clean
flutter pub get
```

Then run on:

* **iOS simulator** (or real device):

```bash
flutter run -d ios
```

* **Android emulator**:

```bash
flutter run -d android
```

Expected behavior:
You see a **simple Quizzes screen** with an AppBar and a FAB. No crashes, no plugin complaints. That means:

* Environment ✅
* Project structure ✅
* Core dependencies & assets wiring ✅
* Ready to implement actual Quiz / OMR / Export logic 🔥

---

If you want, next we can:

* Define **camera_service.dart** interface + basic implementation wrapping `camera` + `permission_handler`.
* Then stub the **OMR pipeline services** (`omr_scanner_service`, `marker_detector`, etc.) so your scanning flow compiles end-to-end before we make it actually smart.
