# Diario Atletica

2026 Designed & Developed by Serg. Rosario OLIVERI — Vers. 0.1

App Flutter (Android + iOS) per atleti di atletica leggera. Dati salvati in locale, export/import in .zip.

## Compilare con GitHub
1. Crea un repository su GitHub e carica il contenuto di questa cartella (compresa `.github/`).
2. Vai su **Actions** → workflow **Build app** (parte da solo a ogni push su `main`, oppure "Run workflow").
3. A fine build scarica gli **Artifacts**:
   - `diario-atletica-android-apk` → `app-release.apk`, da installare sul telefono Android.
   - `diario-atletica-ios-unsigned` → IPA **non firmato**. Per installarlo su iPhone serve firmarlo
     (account Apple Developer, oppure strumenti tipo Sideloadly/AltStore con il proprio Apple ID).

Le cartelle `android/` e `ios/` vengono generate dal workflow (`flutter create`), quindi nel repo c'è solo il codice.

## Struttura
- `lib/models.dart` modelli dati, specialità, formattazione tempi/misure
- `lib/categories.dart` categoria FIDAL dall'età
- `lib/store.dart` salvataggio locale, export/import zip
- `lib/screens_*.dart` schermate (atleti, gare+grafico, allenamenti, società, dati)
