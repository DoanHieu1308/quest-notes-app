# Quest Notes Flutter App

Flutter mobile app for Quest Notes.

The app now uses the shared Node.js API when it is reachable and keeps `SharedPreferences` as its offline store. Every write is saved locally first, then synced to the backend. If the network is down, the pending local state is pushed again on the next load.

## Run with local backend

Start the API in `../quest_notes_api`:

```bash
npm run dev
```

Android emulator:

```bash
flutter run --dart-define=QUEST_API_BASE_URL=http://10.0.2.2:3000/api
```

Desktop or web target:

```bash
flutter run --dart-define=QUEST_API_BASE_URL=http://localhost:3000/api
```

Production backend:

```bash
flutter run --dart-define=QUEST_API_BASE_URL=https://your-project.vercel.app/api
```
