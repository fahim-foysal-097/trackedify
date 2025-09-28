# Spendle

Spendle is a lightweight personal expense tracker designed to help you take control of your finances with ease.

- Track & categorize your expenses
- Analyze your spending patterns with detailed insights
- Interactive charts & visualizations
- Create custom categories
- Simple, clean, and intuitive UI
- Works fully offline (your data stays on your device)
- Delete or edit expenses anytime
- Search expenses by category, amount, date or note
- Swipe feature
- Built in Calculator
- Import & Export Database
- Add notes
- App Locker
- Voice Commands
- Daily Reminder

## Screenshots

<p float="center">
    <img src="readme_assets/ss_home.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_pie.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_bar.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_add.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_calculator.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_all.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_edit.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_monthly.jpg" alt="App Screenshot" width="200"/>
</p>

## Test/Build

### Test in debug mode

```bash
flutter run
```

### Build

first run :

```bash
flutter build apk --split-per-abi
```

Then install compatible apk from build forlder.

[Learn More](https://docs.flutter.dev/deployment/android)

#### Structure

```
Project Root
├── analysis_options.yaml
├── android
├── assets
│   ├── icons
│   ├── img
│   └── lotties
├── flutter_launcher_icons.yaml
├── ios
├── lib
│   ├── data
│   │   └── notifiers.dart
│   ├── database
│   │   ├── database_helper.dart
│   │   ├── Logic
│   │   └── models
│   ├── main.dart
│   ├── shared
│   │   ├── constants
│   │   └── widgets
│   └── views
│       ├── pages
│       ├── stats
│       └── widget_tree.dart
├── LICENSE
├── pubspec.lock
├── pubspec.yaml
├── readme_assets
├── README.md
```
