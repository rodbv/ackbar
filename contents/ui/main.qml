import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

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
        running: root.showTimer
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateElapsed()
    }

    readonly property color flashColor: plasmoid.configuration.blinkColor
    readonly property int flashIntervalMs: plasmoid.configuration.blinkIntervalMinutes * 60 * 1000
    signal flashRequested()

    Timer {
        running: root.hasTask && root.flashIntervalMs > 0
        interval: Math.max(1000, root.flashIntervalMs)
        repeat: true
        onTriggered: root.flashRequested()
    }

    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.fillWidth: true

        Rectangle {
            id: bar
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: height / 2
            color: plasmoid.configuration.barColor
            opacity: root.hasTask ? plasmoid.configuration.barOpacity : 0.05

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.longDuration }
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

        PlasmaComponents3.Label {
            anchors.fill: bar
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: root.showTimer
                ? timerLabel.width + Kirigami.Units.largeSpacing * 2
                : Kirigami.Units.largeSpacing
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.hasTask
                ? root.taskText
                : (plasmoid.configuration.placeholderText || i18n("What are you doing now?"))
            opacity: root.hasTask ? 1.0 : 0.6
            font.bold: root.hasTask
            font.family: root.fontFamily
            font.pixelSize: Math.max(8, bar.height * 0.54)
            color: root.textColor
        }

        PlasmaComponents3.Label {
            id: timerLabel
            visible: root.showTimer
            anchors.right: bar.right
            anchors.rightMargin: Kirigami.Units.largeSpacing
            anchors.verticalCenter: bar.verticalCenter
            text: root.elapsedText
            opacity: 0.75
            font.family: plasmoid.configuration.timerFontFamily || "monospace"
            font.pixelSize: Math.max(7, bar.height * 0.3)
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
