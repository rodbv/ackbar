import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.notification

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Pomodoro mode")
            icon.name: "chronometer"
            checkable: true
            checked: plasmoid.configuration.pomodoroEnabled
            onTriggered: plasmoid.configuration.pomodoroEnabled = checked
        },
        PlasmaCore.Action {
            text: i18n("Rest now")
            icon.name: "media-playback-pause"
            visible: root.pomodoroActive && root.pomodoroPhase.startsWith("work")
            onTriggered: root.startRest(root.restDurationMs)
        },
        PlasmaCore.Action {
            text: i18n("Restart pomodoro")
            icon.name: "view-refresh"
            visible: root.pomodoroActive
            onTriggered: root.startWork(Math.max(1, root.pomodoroCount))
        }
    ]

    readonly property string taskText: plasmoid.configuration.taskText
    readonly property bool hasTask: taskText.length > 0
    readonly property string fontFamily: plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
    // Alpha 0 = "follow the theme"; the config UI stores fully transparent
    // when theme mode is on and always writes alpha 1 for custom colors.
    readonly property color cfgFontColor: plasmoid.configuration.fontColor
    readonly property bool useThemeColor: cfgFontColor.a === 0
    readonly property color textColor: useThemeColor
        ? Kirigami.Theme.textColor
        : Qt.rgba(cfgFontColor.r, cfgFontColor.g, cfgFontColor.b, 1)
    readonly property bool showTimer: plasmoid.configuration.showTimer
                                      && root.hasTask
                                      && plasmoid.configuration.taskStartedAt !== ""
    property string elapsedText: ""

    readonly property bool pomodoroEnabled: plasmoid.configuration.pomodoroEnabled
    readonly property string pomodoroPhase: plasmoid.configuration.pomodoroPhase
    readonly property int pomodoroCount: plasmoid.configuration.pomodoroCount
    readonly property bool pomodoroActive: pomodoroEnabled && hasTask && pomodoroPhase !== ""
    property string pomodoroText: ""
    signal pomodoroPhaseExpired(string endedPhase)

    function startWork(count) {
        plasmoid.configuration.pomodoroCount = count;
        plasmoid.configuration.pomodoroPhase = "work";
        plasmoid.configuration.phaseEndsAt = String(Date.now() + workDurationMs);
    }

    // Compressed durations for manual testing: 20s work / 15s rest / 10s snooze.
    readonly property bool testMode: false
    readonly property int workDurationMs: testMode
        ? 20 * 1000 : plasmoid.configuration.pomodoroMinutes * 60000
    readonly property int restDurationMs: testMode
        ? 15 * 1000 : plasmoid.configuration.restMinutes * 60000
    readonly property int snoozeDurationMs: testMode
        ? 10 * 1000 : 60000

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
        const isWork = current.startsWith("work");
        const nominalMin = isWork ? cfgPomodoroMinutes : cfgRestMinutes;
        const time = overtime
            ? `${nominalMin}+${formatMMSS(secs)}`
            : formatMMSS(secs);
        pomodoroText = isWork
            ? `🍅x${pomodoroCount} ${time}`
            : `☕ ${time}`;
    }

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
                onActivated: root.startRest(root.restDurationMs)
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
                onActivated: root.startRest(root.snoozeDurationMs)
            },
            NotificationAction {
                label: i18n("Yes, same task")
                onActivated: root.startWork(root.pomodoroCount + 1)
            },
            // NotificationReplyAction is not creatable from QML in this KF6
            // build (isCreatable: false), so "new task" opens the editor.
            NotificationAction {
                label: i18n("New task…")
                onActivated: root.expanded = true
            }
        ]
    }

    onPomodoroPhaseExpired: endedPhase => {
        flashRequested();
        if (endedPhase === "work") workEndNotification.sendEvent();
        else restEndNotification.sendEvent();
    }

    // QML fires *Changed handlers while initial bindings evaluate, in
    // declaration order — without this gate a plasmashell restart could
    // reset or wipe a persisted pomodoro.
    property bool pomodoroInitialized: false

    onTaskTextChanged: {
        if (!pomodoroInitialized || !pomodoroEnabled) return;
        // Read taskText directly: derived bindings like hasTask may not
        // have refreshed yet when this handler runs (stale-read race).
        if (taskText.length > 0) startWork(1);
        else clearPomodoro();
    }

    // Duration changes restart the countdown of the matching running phase
    // with the new value (session count untouched).
    readonly property int cfgPomodoroMinutes: plasmoid.configuration.pomodoroMinutes
    readonly property int cfgRestMinutes: plasmoid.configuration.restMinutes

    onCfgPomodoroMinutesChanged: {
        if (pomodoroInitialized && pomodoroPhase === "work")
            plasmoid.configuration.phaseEndsAt = String(Date.now() + workDurationMs);
    }

    onCfgRestMinutesChanged: {
        if (pomodoroInitialized && pomodoroPhase === "rest")
            plasmoid.configuration.phaseEndsAt = String(Date.now() + restDurationMs);
    }

    onPomodoroEnabledChanged: {
        if (!pomodoroInitialized) return;
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
        // Self-heal the invariant "mode on + task set ⇔ pomodoro running",
        // whatever state a previous session left behind.
        if (pomodoroEnabled && hasTask && pomodoroPhase === "")
            startWork(1);
        else if ((!pomodoroEnabled || !hasTask) && pomodoroPhase !== "")
            clearPomodoro();
        pomodoroInitialized = true;
    }

    function updateElapsed() {
        const startedAt = Number(plasmoid.configuration.taskStartedAt);
        if (!startedAt) {
            elapsedText = "";
            return;
        }
        const secs = Math.max(0, Math.floor((Date.now() - startedAt) / 1000));
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const s = secs % 60;
        const pad = n => String(n).padStart(2, "0");
        elapsedText = h > 0
            ? `${h}:${pad(m)}:${pad(s)}`
            : `${pad(m)}:${pad(s)}`;
    }

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

    readonly property color flashColor: plasmoid.configuration.blinkColor
    readonly property int flashIntervalMs: plasmoid.configuration.blinkEnabled
        ? plasmoid.configuration.blinkIntervalMinutes * 60 * 1000
        : 0
    signal flashRequested()

    Timer {
        running: root.hasTask && root.flashIntervalMs > 0
        interval: Math.max(1000, root.flashIntervalMs)
        repeat: true
        onTriggered: {
            // Hold the reminder blink when a pomodoro phase flip (with its
            // own flash) is less than 20s away — avoids back-to-back flashes.
            if (root.pomodoroActive
                && (root.pomodoroPhase === "work" || root.pomodoroPhase === "rest")) {
                const msLeft = Number(plasmoid.configuration.phaseEndsAt) - Date.now();
                if (msLeft < 20000) return;
            }
            root.flashRequested();
        }
    }

    preferredRepresentation: compactRepresentation

    // Vertical panels: pomodoro stacks on top, elapsed timer sits at the
    // bottom (both horizontal — they fit the panel width); only the task
    // text rotates (-90°, reads bottom-to-top).
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    compactRepresentation: Item {
        Layout.minimumWidth: root.vertical ? 0 : Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: root.vertical ? -1 : Kirigami.Units.gridUnit * 22
        Layout.fillWidth: !root.vertical
        Layout.minimumHeight: root.vertical ? Kirigami.Units.gridUnit * 10 : 0
        Layout.preferredHeight: root.vertical ? Kirigami.Units.gridUnit * 22 : -1
        Layout.fillHeight: root.vertical

        Rectangle {
            id: bar
            anchors.fill: parent
            anchors.topMargin: root.vertical ? 0 : 2
            anchors.bottomMargin: root.vertical ? 0 : 2
            anchors.leftMargin: root.vertical ? 2 : 0
            anchors.rightMargin: root.vertical ? 2 : 0
            radius: Math.min(width, height) / 2
            color: root.pomodoroActive && root.pomodoroPhase.startsWith("rest")
                ? plasmoid.configuration.restColor
                : plasmoid.configuration.barColor
            // Full opacity with a task: the bar shows exactly the picked
            // color. Translucency only for the idle nudge.
            opacity: root.hasTask ? 1.0 : 0.05

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.longDuration }
            }

            Behavior on color {
                ColorAnimation { duration: Kirigami.Units.longDuration }
            }
        }

        Rectangle {
            id: flashOverlay
            anchors.fill: bar
            radius: bar.radius
            color: root.flashColor
            opacity: 0

            Connections {
                target: root
                function onFlashRequested() {
                    flashAnimation.restart();
                }
            }

            SequentialAnimation {
                id: flashAnimation
                loops: 3
                NumberAnimation {
                    target: flashOverlay
                    property: "opacity"
                    to: 1.0
                    duration: 60
                }
                PauseAnimation { duration: 180 }
                NumberAnimation {
                    target: flashOverlay
                    property: "opacity"
                    to: 0
                    duration: 80
                }
                PauseAnimation { duration: 160 }
            }
        }

        readonly property string displayText: root.hasTask
            ? root.taskText
            : (plasmoid.configuration.placeholderText || i18n("What are you doing now?"))

        // --- Horizontal layout ---

        PlasmaComponents3.Label {
            visible: !root.vertical
            anchors.fill: bar
            anchors.leftMargin: root.pomodoroActive
                ? pomodoroLabel.width + Kirigami.Units.largeSpacing * 2
                : Kirigami.Units.largeSpacing
            anchors.rightMargin: root.showTimer
                ? timerLabel.width + Kirigami.Units.largeSpacing * 2
                : Kirigami.Units.largeSpacing
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: parent.displayText
            opacity: root.hasTask ? 1.0 : 0.6
            font.bold: root.hasTask
            font.family: root.fontFamily
            font.pixelSize: Math.max(8, bar.height * 0.54)
            color: root.textColor
        }

        PlasmaComponents3.Label {
            id: pomodoroLabel
            visible: root.pomodoroActive && !root.vertical
            anchors.left: bar.left
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.verticalCenter: bar.verticalCenter
            text: root.pomodoroText
            opacity: 0.9
            font.family: plasmoid.configuration.timerFontFamily || "monospace"
            font.pixelSize: Math.max(7, bar.height * 0.36)
            color: root.textColor
        }

        PlasmaComponents3.Label {
            id: timerLabel
            visible: root.showTimer && !root.vertical
            anchors.right: bar.right
            anchors.rightMargin: Kirigami.Units.largeSpacing
            anchors.verticalCenter: bar.verticalCenter
            text: root.elapsedText
            opacity: 0.75
            font.family: plasmoid.configuration.timerFontFamily || "monospace"
            font.pixelSize: Math.max(7, bar.height * 0.36)
            color: root.textColor
        }

        // --- Vertical layout ---

        PlasmaComponents3.Label {
            id: pomodoroLabelV
            visible: root.pomodoroActive && root.vertical
            anchors.top: bar.top
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: bar.horizontalCenter
            // "🍅x2 14:33" stacks as two lines in the panel's width
            text: root.pomodoroText.replace(" ", "\n")
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.9
            font.family: plasmoid.configuration.timerFontFamily || "monospace"
            font.pixelSize: Math.max(7, bar.width * 0.28)
            color: root.textColor
        }

        PlasmaComponents3.Label {
            id: timerLabelV
            visible: root.showTimer && root.vertical
            anchors.bottom: bar.bottom
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: bar.horizontalCenter
            text: root.elapsedText
            opacity: 0.75
            font.family: plasmoid.configuration.timerFontFamily || "monospace"
            font.pixelSize: Math.max(7, bar.width * 0.28)
            color: root.textColor
        }

        PlasmaComponents3.Label {
            visible: root.vertical
            // Left edge reads bottom-to-top, right edge top-to-bottom —
            // matches how you tilt your head toward the panel.
            rotation: Plasmoid.location === PlasmaCore.Types.RightEdge ? 90 : -90
            anchors.centerIn: bar
            // Rotation is visual only: the layout box stays unrotated, so
            // width here is the *vertical* space the text may occupy.
            anchors.verticalCenterOffset: {
                const top = root.pomodoroActive
                    ? pomodoroLabelV.height + Kirigami.Units.largeSpacing : 0;
                const bottom = root.showTimer
                    ? timerLabelV.height + Kirigami.Units.largeSpacing : 0;
                return (top - bottom) / 2;
            }
            width: {
                const top = root.pomodoroActive
                    ? pomodoroLabelV.height + Kirigami.Units.largeSpacing : 0;
                const bottom = root.showTimer
                    ? timerLabelV.height + Kirigami.Units.largeSpacing : 0;
                return bar.height - top - bottom - Kirigami.Units.largeSpacing * 2;
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: parent.displayText
            opacity: root.hasTask ? 1.0 : 0.6
            font.bold: root.hasTask
            font.family: root.fontFamily
            font.pixelSize: Math.max(8, bar.width * 0.54)
            color: root.textColor
        }

        MouseArea {
            anchors.fill: bar
            onDoubleClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.maximumHeight: Kirigami.Units.gridUnit * 4

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    editField.text = root.taskText;
                    editField.forceActiveFocus();
                    editField.selectAll();
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.TextField {
                id: editField
                Layout.fillWidth: true
                font.family: root.fontFamily
                placeholderText: i18n("What are you doing now?")
                onAccepted: {
                    const newText = text.trim();
                    if (newText !== root.taskText) {
                        plasmoid.configuration.taskStartedAt =
                            newText === "" ? "" : String(Date.now());
                    }
                    plasmoid.configuration.taskText = newText;
                    root.expanded = false;
                }
                Keys.onEscapePressed: root.expanded = false
            }

            PlasmaComponents3.Button {
                icon.name: "checkmark"
                text: i18n("Set")
                onClicked: editField.accepted()
            }

            PlasmaComponents3.Button {
                icon.name: "edit-clear"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Clear task")
                onClicked: {
                    plasmoid.configuration.taskText = "";
                    plasmoid.configuration.taskStartedAt = "";
                    root.expanded = false;
                }
            }
        }
    }
}
