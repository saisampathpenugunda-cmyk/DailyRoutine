# UI / UX Design

## Principles
The design of the Daily Routine app focuses on simplicity, readability, and modern Material 3 aesthetics.

## Theme & Styling
- **Color Scheme**: Uses Flutter's dynamic color schemes based on a primary seed color. Surface containers are used to group related content softly.
- **Typography**: Emphasizes bold headers and clean body text. The timer uses tabular figures (`FontFeature.tabularFigures()`) to prevent the text from jittering as the seconds tick down.

## Key Screens
### Home Screen
- Displays a prominent "Today's Plan" summary card tracking overall completion.
- Lists activities in rounded, elevated cards.
- Provides immediate visual feedback when an activity is completed (checkboxes and status text).

### Meditation Screen
- **Info Card**: Displays the selected activity's metadata cleanly at the top.
- **Timer Display**: Features a large, circular progress indicator wrapping the countdown text. Provides color-coded feedback (e.g., green upon completion).
- **Controls**: Big, thumb-friendly buttons for Start, Pause, Resume, and Finish actions. Outlined and Filled button variants are used to indicate primary vs secondary actions.
