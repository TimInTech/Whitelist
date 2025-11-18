# Copilot CLI Instructions – Pi-hole Personal Whitelist (Alexa + Spotify)

## 1. Kontext

Du arbeitest in einem Git-Repository, das eine **persönliche Pi-hole-Whitelist** enthält.  
Struktur (wichtigste Dateien):

- `Whitelist.final.personal.txt`  
  - Haupt-Whitelist mit **Nummerierung** in der Form:  
    `123| api.spotify.com`
- `Whitelist.final.personal.plain.txt`  
  - Plain-Version: **nur Hostnamen**, eine Domain pro Zeile, ohne Nummern.
  - Diese Datei wird von **Pi-hole v6** als Allow-Adlist verwendet.
- Skripte:
  - `update_alexa_spotify_whitelist.sh`  
    → Crawlt offizielle Amazon-/Alexa- und Spotify-Developer-Seiten und extrahiert Hostnamen.
  - `check_all_urls.sh`  
    → Prüft Hosts (DNS, HTTPS-HEAD, Redirects) und erzeugt Prüf-Output (`urls.*`).
  - `whitelist_audit_update.sh`  
    → Für breitere Audits/Refactors der Whitelist.
  - `whitelist-import.sh`  
    → Minimaler Import in Pi-hole via `pihole allow`.

Zielumgebung:

- Pi-hole **v6.x** auf Raspberry Pi / Debian.
- Listen werden per **GitHub Raw URL** als Adlists eingebunden.
- Keine Legacy-Pi-hole-Befehle wie `pihole -r` verwenden.

---

## 2. Ziele für Copilot

Du sollst Copilot so nutzen, dass er dir in der CLI hilft, **lokal Änderungen vorzubereiten**, die dann mit Git/GitHub verteilt und später auf dem Pi mit `pihole -g` aktiv werden.

Konkret soll Copilot:

1. **Alexa-/Spotify-Hosts aktualisieren**
   - `update_alexa_spotify_whitelist.sh` so pflegen, dass:
     - Nur relevante Hosts aus offiziellen Developer-Dokumentationen von Amazon/Alexa und Spotify extrahiert werden.
     - Artefakte wie `AMAZON.LITERAL` oder Dateinamen (`.html`, `.png`, `.js`, …) konsequent herausgefiltert werden.
     - Sehr breite Domains (`amazon.com`, `spotify.com`) optional **gefiltert** oder zumindest in einem Kommentar markiert werden, damit der Nutzer sie leicht wieder entfernen kann.

2. **Whitelist-Hauptdatei aktualisieren**
   - Neue, als sinnvoll erkannte Hosts sollen in `Whitelist.final.personal.txt` landen:
     - Format: `<laufende Nummer>| <hostname>`
     - Nummerierung soll **vollständig neu aufgebaut** werden, damit sie fortlaufend und konsistent ist.
   - Vor jeder Änderung:
     - `Whitelist.final.personal.txt.bak` als Backup anlegen.

3. **Plain-Whitelist regenerieren**
   - Aus `Whitelist.final.personal.txt` soll eine konsistente `Whitelist.final.personal.plain.txt` erzeugt werden:
     - Nur FQDNs, keine Dateinamen, keine lokalen/Interface-Bezeichner.
     - Optional dieselbe Filterlogik nutzen wie in `check_all_urls.sh`.
   - Diese Plain-Datei wird später von Pi-hole als Allow-Adlist gezogen.

4. **Prüf-Skripte unterstützen**
   - `check_all_urls.sh` soll Hostlisten:
     - per DNS (`dig`) prüfen,
     - optionale HTTPS-HEAD-Checks durchführen,
     - Redirect-Vorschläge und Timeouts protokollieren,
     - eine einfache Zusammenfassung in der CLI ausgeben.
   - Copilot darf die Skripte **strukturieren und kommentieren**, aber nicht unlesbar machen.

5. **Git-Workflow vorbereiten**
   - Nach Änderungen sollen sinnvolle Commits erzeugt werden, z. B.:
     - `chore(whitelist): add/update Amazon Alexa + Spotify hostnames (filtered)`
     - `chore(whitelist): refresh plain whitelist`
   - Keine automatischen Force-Pushes generieren.

---

## 3. Arbeitsweise und Regeln für Copilot

Du bist ein technischer Assistent für Bash, Git und Pi-hole-Whitelist-Dateien. Halte dich an folgende Regeln:

1. **Sicherheit & Robustheit**
   - In Shell-Skripten immer:
     ```bash
     #!/usr/bin/env bash
     set -euo pipefail
     ```
   - Keine destruktiven Befehle wie `rm -rf /`, `rm -rf .git`, oder Löschen des gesamten Repos.
   - Backups anlegen, bevor zentrale Dateien verändert werden:
     - `cp Whitelist.final.personal.txt Whitelist.final.personal.txt.bak`
   - Keine Klartext-Passwörter, -Tokens oder Secrets in Dateien einfügen.

2. **Pi-hole v6-Kompatibilität**
   - Pi-hole-spezifische Beispiele dürfen nur v6-Befehle verwenden:
     - erlaubt: `pihole -v`, `pihole -g`, `pihole status`
     - nicht verwenden: `pihole -r` oder alte v5-only Optionen.
   - Skripte sollen **unabhängig** vom Pi-hole laufen (nur Listen vorbereiten), Pi-hole-Aufrufe höchstens als **Kommentar** beschreiben.

3. **Shell & Tools**
   - Zielsystem: Debian/Ubuntu/Raspberry Pi OS.
   - Paketinstallation nur beispielhaft zeigen mit `apt`, z. B.:
     ```bash
     sudo apt update -y
     sudo apt install -y curl dnsutils gawk sed coreutils diffutils
     ```
   - Verwendete Tools:
     - `bash`, `curl`, `dig`, `awk`, `sed`, `sort`, `comm`, `grep`.
   - In `curl`-Beispielen:
     - möglichst `curl -fsSL` (quiet+fail), sinnvolle Timeouts.
     - HTTPS-HEAD-Checks nur, wenn sinnvoll (z. B. für Web-Hosts).

4. **Listen- & Filterlogik**
   - Nur gültige Hostnamen übernehmen:
     - Regex: `^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
   - Dateiendungen/Assets verwerfen:
     - `.html`, `.htm`, `.png`, `.jpg`, `.jpeg`, `.svg`, `.gif`, `.css`, `.js`, `.pdf`, `.ico`, `.webp`, `.zip`, `.gz`, `.bz2`, `.tar` etc.
   - `www.` am Anfang entfernen, wenn sinnvoll.
   - Domainlänge prüfen (`length($0)<=253`).
   - Optional: bekannte Nicht-HTTPS-Services in einer Negativliste halten (z. B. `ntp`, `mqtt`, `ocsp`, `syncthing`, `lan`, `local`).

5. **Code-Stil**
   - Skripte klar strukturieren:
     - Abschnittskommentare wie `# 1) Normalisieren`, `# 2) DNS-Check`, `# 3) HTTPS-Check`.
   - Keine übertrieben kompakten One-Liner, wenn sie die Lesbarkeit erschweren.
   - Variablennamen sprechend halten: `WL_FILE`, `WL_PLAIN`, `SOURCES`, `additions-candidate.txt` etc.

---

## 4. Konkrete Aufgaben für Copilot

Wenn der Nutzer dich in der CLI mit dieser Instructions-Datei aufruft, sollst du insbesondere bei diesen Aufgaben helfen:

### Aufgabe A – `update_alexa_spotify_whitelist.sh` verfeinern

- Überprüfe:
  - `SOURCES`-Array → sind die Amazon-/Spotify-Quellen aktuell strukturiert?
  - Hostextraktion:
    ```bash
    curl -fsSL "$url" \
      | tr '"'\''<>()[]{} ' '\n' \
      | grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
    ```
  - Filter:
    - `grep -Ei 'amazon|alexa|spotify'`
    - Ausschluss von Assets/Dateien.
- Ergänze:
  - Optionalen Filter für **zu breite Domains** (`amazon.com`, `spotify.com`):
    - z. B. Kommentarblock mit Liste und Hinweis, dass der Nutzer diese bei Bedarf wieder einkommentieren kann.
- Stelle sicher:
  - Neue Hosts landen in `additions-candidate.txt`.
  - DNS-Check mit `dig` (falls vorhanden) filtert nicht-aufösbare Kandidaten raus.
  - Am Ende:
    - alle neuen Hosts werden an `Whitelist.final.personal.txt` angehängt,
    - die Datei wird neu durchnummeriert,
    - Backup wird angelegt,
    - ein Git-Commit mit sinnvollem Message-Text wird vorbereitet oder dokumentiert.

### Aufgabe B – `Whitelist.final.personal.plain.txt` generieren

- Implementiere (oder verbessere) eine Funktion/Script-Logik, die:
  - aus `Whitelist.final.personal.txt` die letzte Spalte (Hostname) extrahiert,
  - trimmt,
  - ungültige Einträge (Dateien, Artefakte) entfernt,
  - `www.` entfernt,
  - sortiert und dedupliziert,
  - nach `Whitelist.final.personal.plain.txt` schreibt.
- Diese Logik kann in:
  - `check_all_urls.sh` integriert sein (falls noch nicht), oder
  - als separates kleines Script (`build_plain_whitelist.sh`) angelegt werden.

### Aufgabe C – Prüfungen/CI vorbereiten

- Beschreibe (in Kommentaren oder einer neuen Datei), wie ein GitHub Action Workflow aussehen könnte, der:
  - bei Push/PR:
    - `check_all_urls.sh` ausführt,
    - abbricht, wenn `urls.dns_fail.txt` nicht leer ist,
    - optional ein kurzes Summary-Log als Artefakt anhängt.
- Copilot soll nur **Vorschläge für YAML-Workflows** machen (z. B. `.github/workflows/whitelist-check.yml`), nicht hart in produktive CI einbinden, ohne dass der Nutzer das Review macht.

### Aufgabe D – README-Hinweise ergänzen (optional)

- README erweitern um:
  - Abschnitt „Automatisches Update Alexa/Spotify-Whitelist":
    - Beispielaufruf: `./update_alexa_spotify_whitelist.sh`
    - danach: `./check_all_urls.sh`
    - dann: `git commit`, `git push`
  - Abschnitt „Pi-hole Deployment":
    - Hinweis, dass der Nutzer auf dem Pi:
      ```bash
      pihole -g
      ```
      ausführen muss, um die neue Allow-Adlist zu ziehen.

---

## 5. Git- und Deployment-Workflow (nur beschreiben)

Copilot soll dem Nutzer helfen, folgenden Ablauf einzuhalten:

1. **Lokal im Repo**
   - Skripte/Whitelist-Dateien bearbeiten.
   - `./update_alexa_spotify_whitelist.sh`
   - `./check_all_urls.sh`
   - `git status`
   - `git diff` prüfen.
   - `git commit -m "..."`
   - `git push`

2. **Auf dem Pi-hole**
   - SSH auf den Pi.
   - Pi-hole-Version prüfen:
     ```bash
     pihole -v
     ```
   - Gravity neu laden:
     ```bash
     sudo pihole -g
     ```

Copilot soll **keine direkten Pi-hole-Kommandos automatisch ausführen**, sondern nur die passenden Befehle vorschlagen bzw. dokumentieren.

---

## 6. Rollback-Hinweise

Copilot soll immer darauf achten, dass ein Rollback leicht möglich ist:

- Auf Dateiebene:
  - `Whitelist.final.personal.txt.bak` existiert.
- Auf Git-Ebene:
  - Der Nutzer kann mit:
    ```bash
    git log --oneline
    git revert <commit>    # oder
    git reset --hard <commit_davor>
    ```
    den Stand vor einem Whitelist-Update wiederherstellen.

---

## 7. Stil

- Antworten sollen kurz, technisch klar und ohne Marketing-Floskeln sein.
- Fokus: Reproduzierbare Shell-Kommandos und klare Schritte.
- Kommentare in Skripten vorzugsweise auf Deutsch, Funktions- und Variablennamen können englisch sein.
