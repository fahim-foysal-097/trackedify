# Spendle <a href="https://fahim-foysal-097.github.io/spendle-website/"><img src="https://img.shields.io/badge/App-Download-blue?style=for-the-badge"></a>

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
- Auto Updater
- Insight Cards
- Beautiful Charts

## Screenshots

<p float="center">
    <img src="readme_assets/ss_home.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_add.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_insights.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_pie.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_monthly.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_7.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_user.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_export.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_new.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_settings.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_all.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_calculator.jpg" alt="App Screenshot" width="200"/>
    <img src="readme_assets/ss_lock.jpg" alt="App Screenshot" width="200"/>
</p>

## Download

<a href="https://fahim-foysal-097.github.io/spendle-website/"><img src="https://img.shields.io/badge/Go to Website-Download-blue?style=for-the-badge"></a>

## TODO

- [x] Voice commands & App locker
- [x] Charts & Insights
- [x] Predictions
- [x] Auto updater & Notifications
- [x] Smart Suggestions (in create category)
- [ ] Make compatible with web
- [ ] Save images as notes
- [ ] Budget & Income functionality
- [ ] Smart alerts (e.g., overspending warnings)
- [ ] Cloud backup
- [ ] AI integration
- [ ] Light/Dark theme
- [ ] Export reports as PDF/Image

## Test/Build

### Test in debug mode

```bash
flutter run
```

### Build

first run :

```bash
flutter build apk --split-per-abi --no-tree-shake-icons
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
