# Mood Tracker

A Flutter web app for logging and visualising daily moods. Five mood levels (Ecstatic → Awful) are rendered as expressive faces drawn entirely with `CustomPainter` — no emoji, no icon fonts, no images.

## Features

- **5 mood levels** — Ecstatic, Happy, Neutral, Sad, Awful
- **CustomPainter faces** — head, eyes, brows, mouth, and cheeks drawn with canvas primitives (`drawCircle`, `drawArc`, `drawPath`, `cubicTo`)
- **Mood graph** — smooth Catmull-Rom spline timeline showing the last 7 entries; face icons sit directly on the data points
- **Insight card** — contextual narrative insight plus streak and average stats
- **Persistence** — entries survive page reloads via `shared_preferences`
- **Responsive** — face size adapts down to narrow viewports

## Run locally

```bash
flutter run -d chrome
```

## Build for production

```bash
flutter build web
```

Output is written to `build/web/`. Serve it with any static host.

## Tech

- Flutter 3.x, Dart 3.x, CanvasKit renderer
- Packages: `uuid`, `shared_preferences`, `intl`
