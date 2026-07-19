import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    readonly property string taskText: plasmoid.configuration.taskText
    readonly property bool hasTask: taskText.length > 0
    readonly property string fontFamily: plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
    // Alpha 0 = "follow the theme". Force alpha to 1 on real picks: the
    // config color button hides the alpha channel, so a color picked while
    // the stored value was transparent keeps alpha 0.
    readonly property color cfgFontColor: plasmoid.configuration.fontColor
    readonly property bool useThemeColor: cfgFontColor.a === 0
        && cfgFontColor.r === 0 && cfgFontColor.g === 0 && cfgFontColor.b === 0
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
            font.pixelSize: Math.max(8, bar.height * 0.45)
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
