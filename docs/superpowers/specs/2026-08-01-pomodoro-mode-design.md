# Pomodoro Mode — Design

Date: 2026-08-01
Status: approved

## Summary

Opt-in pomodoro mode for AckBar. When enabled, setting a task starts a
pomodoro countdown shown on the left side of the bar, with a session
counter. All phase transitions are manual, driven by system notification
buttons. Everything resets when the task changes. Default behavior of the
widget is unchanged while the mode is off.

## Goals

- Opt-in: zero visual or behavioral change when disabled (default).
- All-manual transitions: the widget never advances a phase on its own.
- Reuse existing patterns: config-backed state (like `taskStartedAt`),
  the timer monospace font, the blink/flash overlay.

## Non-goals (v1)

- Long breaks / cycle targets ("N of M").
- Pause/resume.
- Daily statistics or history.
- Sounds.
- Auto-starting any phase.

## Configuration

New entries in `contents/config/main.xml` (group General):

| Entry | Type | Default | Purpose |
|---|---|---|---|
| `pomodoroEnabled` | Bool | `false` | Mode toggle |
| `pomodoroMinutes` | Int | `20` | Work duration |
| `restMinutes` | Int | `5` | Rest duration |
| `pomodoroPhase` | String | `""` | Runtime state: `work`, `workEnded`, `rest`, `restEnded`, or empty (idle) |
| `phaseEndsAt` | String | `""` | Epoch ms when current phase nominally ends |
| `pomodoroCount` | Int | `0` | Current session number for this task |

Runtime state lives in configuration so it survives plasmashell restarts,
matching the existing `taskStartedAt` pattern. On restore, remaining time
is computed from `phaseEndsAt`; a phase whose time already elapsed while
plasmashell was down restores into its `*Ended` state (no notification
replay).

### Settings UI

New "Pomodoro" page via `ConfigCategory` in `contents/config/config.qml`
(`configPomodoro.qml`):

- Checkbox: "Enable Pomodoro mode" (`pomodoroEnabled`)
- SpinBox: "Pomodoro duration:" minutes, 1–120, default 20
- SpinBox: "Rest duration:" minutes, 1–60, default 5
- Duration spinboxes disabled while the checkbox is off.
- Whitespace grouping, no section headers (matches General page style).

### Context menu

`Plasmoid.contextualActions` gains one checkable `PlasmaCore.Action`
"Pomodoro mode", bound to `pomodoroEnabled`. Appears in the widget's
right-click menu near "Configure AckBar…". Menu and settings checkbox are
two views of the same config key.

## State machine

```
(idle) ──task set──▶ work(count=1)
work ──countdown reaches 0──▶ workEnded            (notification A)
workEnded ──[Keep working]──▶ work(count+1)
workEnded ──[Take break]────▶ rest
rest ──countdown reaches 0──▶ restEnded            (notification B)
restEnded ──[Not yet]───────▶ rest (+1 min, notification B re-fires at 0)
restEnded ──[Yes, same task]▶ work(count+1)
restEnded ──[reply: new task]▶ task change → work(count=1)
any ──task changed──▶ work(count=1)                (fresh start)
any ──task cleared──▶ (idle)
any ──mode disabled──▶ (idle, state cleared)
```

- Notification A: "Pomodoro #N finished. Time for a break?" with actions
  **Keep working** and **Take break**.
- Notification B: "Rest over — start the next pomodoro?" with actions
  **Not yet** (extends rest by 1 minute, then notifies again),
  **Yes, same task**, and an inline-reply action **New task…**
  (`NotificationReplyAction`) whose submitted text replaces the task —
  triggering the normal task-change reset (count back to 1, timer reset).
- If the inline reply proves crowded or janky in practice, fallback:
  "New task…" becomes a plain action that opens the bar's edit popup
  (`root.expanded = true`).
- Enabling the mode while a task is already set starts `work` with
  count = 1 immediately.

## Bar display

Left side of the bar, using the existing timer font
(`timerFontFamily` / monospace), mirroring the elapsed timer on the right:

| State | Shows | Direction |
|---|---|---|
| `work` | `🍅3 12:34` | counts down |
| `workEnded` | `🍅3 +2:34` | counts up (overtime since phase end) |
| `rest` | `☕ 4:12` | counts down |
| `restEnded` | `☕ +1:05` | counts up |

- `🍅` + count = current session number; `☕` marks rest.
- One shared 1s `Timer` drives both this and the existing elapsed label.
- The task label's right/left margins account for the new label so text
  never overlaps.
- The right-side elapsed timer is unchanged (total time on task).

## Notifications

- `import org.kde.notification` (KF6 KNotifications QML plugin).
- Two `Notification` objects (work end, rest end) with `actions`; each
  action's `activated` handler performs the state transition.
- Phase end also triggers the existing flash overlay (blink color) via the
  `flashRequested` signal so the panel itself catches the eye.
- The periodic blink reminder feature stays fully independent.

## Error handling / edge cases

- Plasmashell restart mid-phase: remaining time recomputed from
  `phaseEndsAt`; already-elapsed phases restore as `*Ended` (overtime
  counting from the phase's nominal end), without re-firing notifications.
- Notification dismissed without clicking a button: state stays in
  `*Ended`, overtime keeps counting; the bar's overtime display is the
  persistent cue. No re-notify, except the explicit [Not yet] snooze,
  which re-fires notification B once per press.
- Duration changed mid-phase: applies from the next phase; the running
  countdown keeps its original target (computed at phase start).

## Testing

Manual test matrix (no test harness exists for this plasmoid):

1. Mode off → widget identical to 1.3.x behavior.
2. Enable via context menu, set task → `🍅1` countdown appears.
3. Let work end → notification A, overtime counts up, bar flashes.
4. [Keep working] → `🍅2` fresh countdown, no rest.
5. [Take break] → `☕` rest countdown.
6. Let rest end → notification B, overtime.
7. [Yes, same task] → `🍅` count+1.
7a. [Not yet] → `☕ 1:00` countdown, notification B again at zero.
7b. Inline reply with new text → task replaced, `🍅1` fresh countdown.
8. Change task mid-work → count back to 1, fresh countdown.
9. Clear task → left label disappears.
10. Restart plasmashell mid-work → countdown resumes correctly.
11. Disable mode mid-work → left label disappears, state cleared.
