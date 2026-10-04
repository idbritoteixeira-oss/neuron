---
name: enxOS header scope
description: Where to make changes to the shared enxOS header.
---

For changes to the enxOS header, edit Flutter/Dart only; do not alter the React web preview unless the user explicitly requests web changes.

**Why:** The user explicitly scoped header work to Flutter/Dart and said not to change the web preview.

**How to apply:** Update the Flutter shell and module screens in `lib/core/enxos/`. Keep `artifacts/enxos-webview` unchanged unless asked.