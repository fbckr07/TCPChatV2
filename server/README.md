# TCPChatV2 Server

Kurze Beschreibung
- Einfacher TCP-Chat-Server in C# (.NET). Nimmt Verbindungen von Clients an und vermittelt Nachrichten.

Voraussetzungen
- Installiertes .NET SDK (Target: .NET 9.0). Prüfen mit `dotnet --version`.

Projektstruktur (wichtig)
- `TCPChatV2/Program.cs` — Programmeinstieg
- `TCPChatV2/server.cs` — Server-Logik
- `TCPChatV2/TCPChatV2.csproj` — Projektdatei (TargetFramework: net9.0)

Build & Start
1. Abhängigkeiten wiederherstellen:

```
dotnet restore
```
2. Projekt bauen:

```
dotnet build TCPChatV2/TCPChatV2.csproj
```
3. Server starten:

```
dotnet run --project TCPChatV2/TCPChatV2.csproj
```

Konfiguration
- Passe ggf. Host/Port oder andere Parameter in `TCPChatV2/server.cs` an.

Weiteres
- Zum Debuggen öffne `TCPChatV2Server/TCPChatV2.sln` in Visual Studio oder verwende `dotnet` CLI.
