# Pomodoro Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Opt-in pomodoro mode: countdown + session counter on the bar's left side, all-manual phase transitions via notification buttons, full reset on task change.

**Architecture:** All state lives in `plasmoid.configuration` (the existing `taskStartedAt` pattern), so it survives plasmashell restarts. A single 1 s timer in `main.qml` drives both the existing elapsed label and the new pomodoro countdown. Phase transitions happen only in named functions; the tick function detects countdown expiry and fires notifications. The settings gain a second `ConfigCategory` page; the context menu gains a checkable toggle bound to the same config key.

**Tech Stack:** Plasma 6 QML plasmoid (no build step), KF6 KNotifications QML (`org.kde.notification`), gettext for pt_BR.

**Spec:** `docs/superpowers/specs/2026-08-01-pomodoro-mode-design.md`

## Global Constraints

- Defaults: `pomodoroEnabled=false`, `pomodoroMinutes=20`, `restMinutes=5`.
- Phase names, verbatim: `work`, `workEnded`, `rest`, `restEnded`, `""` (idle).
- Display: `🍅3 12:34` (work), `🍅3 +2:34` (work overtime), `☕ 4:12` (rest), `☕ +1:05` (rest overtime).
- Mode off ⇒ zero visual/behavioral change vs 1.3.x.
- No test harness exists: every task verifies by deploying (`./install.sh && systemctl --user restart plasma-plasmashell`) and checking by hand. For countdown checks, temporarily set durations to 1 minute via the settings UI — never hardcode test values in code.
- Commits: conventional commits, no AI co-author trailers.
- All user-visible strings wrapped in `i18n()`/`i18np()`; pt_BR catalog updated in Task 5 (not before, to avoid churn).
- Work on branch `feat/pomodoro`.

---

### Task 1: Config schema + Pomodoro settings page

**Files:**
- Modify: `contents/config/main.xml` (append entries before `</group>`)
- Modify: `contents/config/config.qml`
- Create: `contents/ui/configPomodoro.qml`

**Interfaces:**
- Produces config keys consumed by every later task: `pomodoroEnabled` (Bool), `pomodoroMinutes` (Int), `restMinutes` (Int), `pomodoroPhase` (String), `phaseEndsAt` (String, epoch ms), `pomodoroCount` (Int).

- [ ] **Step 1: Add config entries**

In `contents/config/main.xml`, after the `blinkColor` entry and before `</group>`:

```xml
        <entry name="pomodoroEnabled" type="Bool">
            <default>false</default>
        </entry>
        <entry name="pomodoroMinutes" type="Int">
            <default>20</default>
        </entry>
        <entry name="restMinutes" type="Int">
            <default>5</default>
        </entry>
        <entry name="pomodoroPhase" type="String">
            <default></default>
        </entry>
        <entry name="phaseEndsAt" type="String">
            <default></default>
        </entry>
        <entry name="pomodoroCount" type="Int">
            <default>0</default>
        </entry>
```

- [ ] **Step 2: Register the settings page**

Replace the body of `contents/config/config.qml` with:

```qml
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Pomodoro")
        icon: "chronometer"
        source: "configPomodoro.qml"
    }
}
```

- [ ] **Step 3: Create the settings page**

Create `contents/ui/configPomodoro.qml`:

```qml
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_pomodoroEnabled: enabledCheck.checked
    property alias cfg_pomodoroMinutes: workSpin.value
    property alias cfg_restMinutes: restSpin.value

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: enabledCheck
            text: i18n("Enable Pomodoro mode")
        }

        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.largeSpacing }

        QQC2.SpinBox {
            id: workSpin
            Kirigami.FormData.label: i18n("Pomodoro duration:")
            enabled: enabledCheck.checked
            from: 1
            to: 120
            stepSize: 1
            textFromValue: (value, locale) => i18np("%1 minute", "%1 minutes", value)
            valueFromText: (text, locale) => parseInt(text) || 20
        }

        QQC2.SpinBox {
            id: restSpin
            Kirigami.FormData.label: i18n("Rest duration:")
            enabled: enabledCheck.checked
            from: 1
            to: 60
            stepSize: 1
            textFromValue: (value, locale) => i18np("%1 minute", "%1 minutes", value)
            valueFromText: (text, locale) => parseInt(text) || 5
        }

        QQC2.Label {
            text: i18n("Setting a task starts a pomodoro. You will be notified when it ends; nothing advances without your say-so.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
```

Note: `QtQuick.Layouts` import is needed for `Layout.fillWidth` — add `import QtQuick.Layouts` after the QtQuick import.

- [ ] **Step 4: Deploy and verify**

Run: `./install.sh && systemctl --user restart plasma-plasmashell`

Verify: right-click widget → Configure AckBar… → "Pomodoro" page appears in sidebar with chronometer icon; checkbox off by default; spinboxes disabled until checked; values persist across Apply + reopen; spinboxes show "20 minutes" / "5 minutes".

- [ ] **Step 5: Commit**

```bash
git add contents/config/ contents/ui/configPomodoro.qml
git commit -m "feat(pomodoro): config schema and settings page"
```

---

### Task 2: Context menu toggle

**Files:**
- Modify: `contents/ui/main.qml` (inside the `PlasmoidItem` root, after the `Plasmoid.backgroundHints` line)

**Interfaces:**
- Consumes: `plasmoid.configuration.pomodoroEnabled` (Task 1).
- Produces: nothing new; UI affordance only.

- [ ] **Step 1: Add the contextual action**

In `contents/ui/main.qml`, directly after the `Plasmoid.backgroundHints:` line:

```qml
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Pomodoro mode")
            icon.name: "chronometer"
            checkable: true
            checked: plasmoid.configuration.pomodoroEnabled
            onTriggered: plasmoid.configuration.pomodoroEnabled = checked
        }
    ]
```

Note: `PlasmaCore` is already imported. `checked` reflects the post-toggle state inside `onTriggered` for checkable actions; if testing shows it doesn't toggle, use `onTriggered: plasmoid.configuration.pomodoroEnabled = !plasmoid.configuration.pomodoroEnabled` instead.

- [ ] **Step 2: Deploy and verify**

Run: `./install.sh && systemctl --user restart plasma-plasmashell`

Verify: right-click widget → "Pomodoro mode" entry with checkbox appears near "Configure AckBar…"; toggling it and reopening settings shows the checkbox in the Pomodoro page matching; toggling the settings checkbox updates the menu checkmark.

- [ ] **Step 3: Commit**

```bash
git add contents/ui/main.qml
git commit -m "feat(pomodoro): context menu mode toggle"
```

---

### Task 3: State machine + bar display (silent transitions)

**Files:**
- Modify: `contents/ui/main.qml`

**Interfaces:**
- Consumes: config keys from Task 1.
- Produces (used by Task 4):
  - `root.startWork(count: int)` — sets `pomodoroCount = count`, phase `work`, `phaseEndsAt = now + pomodoroMinutes*60000`.
  - `root.startRest(ms: int)` — phase `rest`, `phaseEndsAt = now + ms`.
  - `root.clearPomodoro()` — phase `""`, `phaseEndsAt = ""`, count 0.
  - `root.pomodoroCount` (readonly int), `root.pomodoroPhase` (readonly string).
  - Tick transitions `work→workEnded` and `rest→restEnded` call `root.pomodoroPhaseExpired(phase)` — a signal Task 4 connects notifications to. Declared in this task, unused until Task 4.

- [ ] **Step 1: Add state properties, functions, and tick logic**

In `contents/ui/main.qml`, after the `elapsedText` property declaration, add:

```qml
    readonly property bool pomodoroEnabled: plasmoid.configuration.pomodoroEnabled
    readonly property string pomodoroPhase: plasmoid.configuration.pomodoroPhase
    readonly property int pomodoroCount: plasmoid.configuration.pomodoroCount
    readonly property bool pomodoroActive: pomodoroEnabled && hasTask && pomodoroPhase !== ""
    property string pomodoroText: ""
    signal pomodoroPhaseExpired(string endedPhase)

    function startWork(count) {
        plasmoid.configuration.pomodoroCount = count;
        plasmoid.configuration.pomodoroPhase = "work";
        plasmoid.configuration.phaseEndsAt =
            String(Date.now() + plasmoid.configuration.pomodoroMinutes * 60000);
    }

    function startRest(ms) {
        plasmoid.configuration.pomodoroPhase = "rest";
        plasmoid.configuration.phaseEndsAt = String(Date.now() + ms);
    }

    function clearPomodoro() {
        plasmoid.configuration.pomodoroPhase = "";
        plasmoid.configuration.phaseEndsAt = "";
        plasmoid.configuration.pomodoroCount = 0;
    }

    function formatMMSS(secs) {
        const m = Math.floor(secs / 60);
        const s = secs % 60;
        return `${m}:${String(s).padStart(2, "0")}`;
    }

    function updatePomodoro() {
        if (!pomodoroActive) {
            pomodoroText = "";
            return;
        }
        const endsAt = Number(plasmoid.configuration.phaseEndsAt);
        const now = Date.now();
        const phase = pomodoroPhase;

        // Live expiry: flip to the ended state and announce it.
        if (phase === "work" && now >= endsAt) {
            plasmoid.configuration.pomodoroPhase = "workEnded";
            pomodoroPhaseExpired("work");
        } else if (phase === "rest" && now >= endsAt) {
            plasmoid.configuration.pomodoroPhase = "restEnded";
            pomodoroPhaseExpired("rest");
        }

        const current = plasmoid.configuration.pomodoroPhase;
        const overtime = current === "workEnded" || current === "restEnded";
        const secs = Math.max(0, Math.floor(Math.abs(endsAt - now) / 1000));
        const time = overtime ? `+${formatMMSS(secs)}` : formatMMSS(secs);
        pomodoroText = current.startsWith("work")
            ? `🍅${pomodoroCount} ${time}`
            : `☕ ${time}`;
    }
```

- [ ] **Step 2: React to task and mode changes; restore silently on startup**

Still in `main.qml` root, after the functions from Step 1:

```qml
    onTaskTextChanged: {
        if (!pomodoroEnabled) return;
        if (hasTask) startWork(1);
        else clearPomodoro();
    }

    onPomodoroEnabledChanged: {
        if (pomodoroEnabled && hasTask) startWork(1);
        else if (!pomodoroEnabled) clearPomodoro();
    }

    Component.onCompleted: {
        // Normalize stale state from before a plasmashell restart without
        // firing notifications: an expired running phase becomes its Ended
        // twin; the tick then shows overtime from the nominal end.
        const endsAt = Number(plasmoid.configuration.phaseEndsAt);
        if (endsAt && Date.now() >= endsAt) {
            if (pomodoroPhase === "work")
                plasmoid.configuration.pomodoroPhase = "workEnded";
            else if (pomodoroPhase === "rest")
                plasmoid.configuration.pomodoroPhase = "restEnded";
        }
    }
```

Caveat: `onTaskTextChanged` fires only when the text actually changes — re-entering the same text keeps the running pomodoro, matching the elapsed-timer semantics.

- [ ] **Step 3: Drive the tick from the shared timer**

Replace the existing 1 s timer in `main.qml`:

```qml
    Timer {
        running: root.showTimer || root.pomodoroActive
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updateElapsed();
            root.updatePomodoro();
        }
    }
```

- [ ] **Step 4: Add the left-side label to the compact representation**

In the `compactRepresentation` Item, after the existing `timerLabel` Label:

```qml
        PlasmaComponents3.Label {
            id: pomodoroLabel
            visible: root.pomodoroActive
            anchors.left: bar.left
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.verticalCenter: bar.verticalCenter
            text: root.pomodoroText
            opacity: 0.9
            font.family: plasmoid.configuration.timerFontFamily || "monospace"
            font.pixelSize: Math.max(7, bar.height * 0.3)
            color: root.textColor
        }
```

And widen the task label's left margin so text never overlaps — change its `anchors.leftMargin` from `Kirigami.Units.largeSpacing` to:

```qml
            anchors.leftMargin: root.pomodoroActive
                ? pomodoroLabel.width + Kirigami.Units.largeSpacing * 2
                : Kirigami.Units.largeSpacing
```

- [ ] **Step 5: Deploy and verify (durations set to 1 minute in settings)**

Run: `./install.sh && systemctl --user restart plasma-plasmashell`

Verify each, with pomodoro duration temporarily set to 1 minute in settings:
1. Mode off, set task → no left label (identical to 1.3.x).
2. Enable mode (context menu), task already set → `🍅1 1:00` counting down.
3. Wait past zero → display flips to `🍅1 +0:01` counting up (no notification yet — that's Task 4).
4. Change task text → `🍅1` fresh countdown.
5. Clear task → left label gone.
6. Restart plasmashell mid-countdown → countdown resumes with correct remaining time.
7. Disable mode → label gone; re-enable → fresh `🍅1` countdown.

- [ ] **Step 6: Commit**

```bash
git add contents/ui/main.qml
git commit -m "feat(pomodoro): state machine and countdown display"
```

---

### Task 4: Notifications, buttons, inline reply, flash

**Files:**
- Modify: `contents/ui/main.qml`

**Interfaces:**
- Consumes: `startWork(count)`, `startRest(ms)`, `pomodoroCount`, `pomodoroPhaseExpired(endedPhase)` signal (Task 3); `flashRequested()` signal and flash overlay (pre-existing).

- [ ] **Step 1: Add the notification import**

At the top of `contents/ui/main.qml`, with the other imports:

```qml
import org.kde.notification
```

- [ ] **Step 2: Declare the two notifications**

In the `PlasmoidItem` root (near the timers):

```qml
    Notification {
        id: workEndNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        title: i18n("Pomodoro finished")
        text: i18n("Pomodoro #%1 finished. Time for a break?", root.pomodoroCount)
        iconName: "chronometer"
        flags: Notification.Persistent
        actions: [
            NotificationAction {
                label: i18n("Keep working")
                onActivated: root.startWork(root.pomodoroCount + 1)
            },
            NotificationAction {
                label: i18n("Take break")
                onActivated: root.startRest(plasmoid.configuration.restMinutes * 60000)
            }
        ]
    }

    Notification {
        id: restEndNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        title: i18n("Rest over")
        text: i18n("Start the next pomodoro?")
        iconName: "chronometer"
        flags: Notification.Persistent
        actions: [
            NotificationAction {
                label: i18n("Not yet")
                onActivated: root.startRest(60000)
            },
            NotificationAction {
                label: i18n("Yes, same task")
                onActivated: root.startWork(root.pomodoroCount + 1)
            }
        ]
        replyAction: NotificationReplyAction {
            label: i18n("New task…")
            placeholderText: i18n("What are you doing now?")
            submitButtonText: i18n("Start")
            onReplied: text => {
                const newText = text.trim();
                if (newText === "") return;
                plasmoid.configuration.taskStartedAt = String(Date.now());
                plasmoid.configuration.taskText = newText;
                // onTaskTextChanged handles startWork(1)
            }
        }
    }
```

Fallback (spec-sanctioned) if `NotificationReplyAction` is unavailable in the installed KF6 version or renders badly: delete the `replyAction` block and add a third `NotificationAction` labeled `i18n("New task…")` with `onActivated: root.expanded = true`.

- [ ] **Step 3: Fire notifications and flash on live expiry**

Connect to the Task 3 signal, inside the root:

```qml
    onPomodoroPhaseExpired: endedPhase => {
        flashRequested();
        if (endedPhase === "work") workEndNotification.sendEvent();
        else restEndNotification.sendEvent();
    }
```

- [ ] **Step 4: Deploy and verify (1-minute durations)**

Run: `./install.sh && systemctl --user restart plasma-plasmashell`

Verify:
1. Work end → bar flashes in blink color AND notification "Pomodoro #1 finished" with [Keep working] [Take break].
2. [Keep working] → `🍅2` fresh countdown, no rest.
3. [Take break] → `☕ 1:00` countdown.
4. Rest end → flash + "Rest over" with [Not yet] [Yes, same task] [New task…].
5. [Not yet] → `☕ 1:00` again; at zero, notification B re-fires.
6. [Yes, same task] → `🍅` count+1 countdown.
7. [New task…] inline reply, type text, submit → task text replaced, `🍅1` fresh countdown, elapsed timer reset.
8. Dismiss a notification with the X → state stays in overtime, counting up; no re-notify.
9. Restart plasmashell while in `workEnded` → overtime label back, NO duplicate notification.

If step 7's inline reply is crowded or broken, apply the fallback from Step 2 and re-verify (button opens the bar's edit popup instead).

- [ ] **Step 5: Commit**

```bash
git add contents/ui/main.qml
git commit -m "feat(pomodoro): phase-end notifications with manual transitions"
```

---

### Task 5: pt_BR translations + README

**Files:**
- Modify: `po/pt_BR.po`
- Modify: `contents/locale/pt_BR/LC_MESSAGES/plasma_applet_com.rodbv.ackbar.mo` (compiled)
- Modify: `README.md`

**Interfaces:**
- Consumes: every `i18n()` string introduced in Tasks 1–4, verbatim.

- [ ] **Step 1: Append translations to `po/pt_BR.po`**

```po
msgid "Pomodoro"
msgstr "Pomodoro"

msgid "Enable Pomodoro mode"
msgstr "Ativar modo Pomodoro"

msgid "Pomodoro duration:"
msgstr "Duração do pomodoro:"

msgid "Rest duration:"
msgstr "Duração do descanso:"

msgid "%1 minute"
msgid_plural "%1 minutes"
msgstr[0] "%1 minuto"
msgstr[1] "%1 minutos"

msgid "Setting a task starts a pomodoro. You will be notified when it ends; nothing advances without your say-so."
msgstr "Definir uma tarefa inicia um pomodoro. Você será notificado quando ele terminar; nada avança sem a sua confirmação."

msgid "Pomodoro mode"
msgstr "Modo Pomodoro"

msgid "Pomodoro finished"
msgstr "Pomodoro concluído"

msgid "Pomodoro #%1 finished. Time for a break?"
msgstr "Pomodoro nº %1 concluído. Hora de uma pausa?"

msgid "Keep working"
msgstr "Continuar trabalhando"

msgid "Take break"
msgstr "Fazer pausa"

msgid "Rest over"
msgstr "Descanso encerrado"

msgid "Start the next pomodoro?"
msgstr "Iniciar o próximo pomodoro?"

msgid "Not yet"
msgstr "Ainda não"

msgid "Yes, same task"
msgstr "Sim, mesma tarefa"

msgid "New task…"
msgstr "Nova tarefa…"

msgid "Start"
msgstr "Iniciar"
```

- [ ] **Step 2: Compile and verify strings appear**

Run:
```bash
msgfmt --check -o contents/locale/pt_BR/LC_MESSAGES/plasma_applet_com.rodbv.ackbar.mo po/pt_BR.po
./install.sh && systemctl --user restart plasma-plasmashell
```

Verify: settings Pomodoro page, context menu entry, and one notification cycle all show pt_BR strings.

- [ ] **Step 3: Update README**

In `README.md` Features section, after the "Blink reminder" bullet:

```markdown
- **Pomodoro mode (opt-in)** — countdown and session counter on the bar (`🍅3 12:34`), all-manual transitions via notification buttons (keep working / take break / start next / new task), everything resets when the task changes. Toggle it from the widget's right-click menu.
```

In the Usage table, after the "Right-click → Configure AckBar…" row:

```markdown
| Right-click → *Pomodoro mode* | Toggle pomodoro mode on/off |
```

- [ ] **Step 4: Commit**

```bash
git add po/ contents/locale/ README.md
git commit -m "feat(i18n): pt_BR translations for pomodoro mode; document in README"
```

---

## Final verification

Run the full manual test matrix from the spec (section "Testing") end to end with real-ish durations (2 min work / 1 min rest), then:

```bash
git checkout main && git merge --no-ff feat/pomodoro
```

(Release bump + `./package.sh` + store upload remain a separate, user-initiated step.)
