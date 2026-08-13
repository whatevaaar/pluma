# Pluma ✍️

**Premium offline writing app. No ads. No account. No server. Just you and your words.**

Pluma is a free and open-source writing app for iOS and Android, built with Flutter. It is the first app of the *Sin Anuncios Nunca* initiative — a commitment to software that respects the user completely.

---

## Features

- **Rich text editor** — Bold, italic, headings, lists. Powered by flutter_quill.
- **Autosave** — Silently saves every 3 seconds. No save button. No "discard changes?" dialogs.
- **Projects / folders** — Organize your writing into folders with custom colors.
- **Trash & restore** — Soft-delete with 30-day auto-purge. Restore anything before it expires.
- **Writing statistics** — Daily goal ring, current streak, heatmap, total words, best session.
- **Full-text search** — FTS5-powered instant search across all your documents.
- **100% offline** — No network requests. Your data never leaves your device.
- **Zero tracking** — No analytics, no crash reporters, no telemetry of any kind.

## Planned

- Focus mode & typewriter mode
- Export to TXT, Markdown, PDF
- Import from TXT / Markdown
- Writing heatmap (GitHub-style)
- Configurable fonts and themes (sepia, dark, minimal)

---

## Tech Stack

| Layer | Library |
|-------|---------|
| UI | Flutter 3.x + Material 3 |
| Editor | flutter_quill 11.5.x |
| Database | Drift 2.x (SQLite + FTS5) |
| State | Riverpod 3.x + codegen |
| Navigation | go_router 17.x |
| Models | freezed v4 |
| Settings | Hive CE |

## Privacy

Pluma will **never** include:
- Any analytics SDK (Firebase, Amplitude, Mixpanel, Sentry, Datadog…)
- Any ad network
- Any in-app purchase or subscription
- Any login or cloud sync

All data is stored locally on-device using SQLite.

---

## Building

**Requirements:** Flutter stable, Dart 3.x

```bash
git clone https://github.com/whatevaaar/pluma.git
cd pluma
flutter pub get
dart run build_runner build
flutter run
```

**iOS** builds require macOS + Xcode. CI is handled via [Codemagic](https://codemagic.io).

---

## License

Copyright (C) 2026 Emiliano Hidalgo

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License v3.0** as published by the Free Software Foundation.

See [LICENSE](LICENSE) for the full text.
