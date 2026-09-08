# Project Memory

## Context & Constraints
This document tracks major decisions, context, and development constraints for the Daily Routine project to aid future iterations.

## Timer Implementation Decision
- **Challenge**: Relying on a continuously running `Timer.periodic` or `Ticker` loop can lead to drift or complete suspension when the app enters the background on mobile devices.
- **Decision**: Implemented a timestamp-based timer (`RoutineTimerController`). It calculates the remaining time on each tick by comparing the current `DateTime.now()` to a pre-calculated `endTime`.
- **Outcome**: The timer stays accurate regardless of app lifecycle state.

## State Management
- **Decision**: We opted for a localized, controller-based MVP-lite approach with `setState` for the initial MVP.
- **Reasoning**: It prevents the overhead of installing and configuring third-party state management libraries (like Provider, Riverpod, or Bloc) before the core domain models are solidified.

## Architecture Guidelines
- **Rule**: Do not hardcode specific activities as unique systems.
- **Reasoning**: To ensure the application scales, activities (like Meditation, Walking, Dumbbells) must share a generic `Activity` model and `ActivityRepository`. Each may have customized UI flows (e.g., `MeditationScreen`), but the data contract remains uniform.
