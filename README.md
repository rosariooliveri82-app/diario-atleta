# Diario Atletica

2026 Designed & Developed by Rosario OLIVERI — Vers. 0.1

Diario di allenamento di un singolo atleta (profilo unico). Dati salvati sul dispositivo, export/import in .zip.

## Compilare con GitHub
1. Crea un repository e carica tutto il contenuto di questa cartella (compresa `.github/`).
2. **Settings → Pages → Source: GitHub Actions** (una volta sola).
3. Vai su **Actions → Build app → Run workflow** (parte anche a ogni push su `main`).
4. Risultati:
   - **Android**: Artifact `diario-atletica-android-apk` → `app-release.apk`.
   - **iOS (web app)**: sito su `https://<utente>.github.io/<repo>/`. Su iPhone apri il link in Safari →
     Condividi → **Aggiungi a Home**: si installa come app con l'icona.

Le cartelle `android/` e `web/` vengono generate dal workflow, nel repo c'è solo il codice.

## Funzioni (v0.1)
Profilo unico (categoria FIDAL, tessere con "Visualizza", società e numeri utili da chiamare, scadenze),
Gare (PB/SB, grafico), Allenamenti (esercizi, carico settimanale), Agenda (gare, visite, scadenze),
Obiettivi, Benessere (peso/sonno/infortuni), Ciclo (solo profili femminili), Riepilogo PDF, Backup .zip.
