# TCPChatV2 Client

Kurze Beschreibung
- Flutter-Client für den TCPChatV2-Server. Stellt die UI, Verbindungslogik und lokale Einstellungen bereit.

Voraussetzungen
- Installierte Flutter SDK (prüfen mit `flutter --version`).

Installation & Start
1. In das Projektverzeichnis wechseln:

```
cd tcpchatv2_client
```
2. Abhängigkeiten installieren:

```
flutter pub get
```
3. App starten (verbundenes Gerät oder Emulator auswählen):

```
flutter run -d <device>
```

Builds
- Android APK: `flutter build apk`
- Windows: `flutter build windows`
- Web: `flutter build web`

Konfiguration
- Serveradresse und Konstanten befinden sich in `lib/config/app_constants.dart`. Passe sie an, falls der Server auf einem anderen Host/Port läuft.

Wichtige Dateien
- `lib/main.dart` — App-Start
- `lib/config/app_constants.dart` — Konfiguration
- `lib/services/` — Netzwerk- und Service-Logik