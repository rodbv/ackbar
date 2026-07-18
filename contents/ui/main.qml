import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string taskText: plasmoid.configuration.taskText
    readonly property bool hasTask: taskText.length > 0
    property bool editing: false

    // Panel windows only receive keyboard focus while the applet is in
    // AcceptingInputStatus (enforced by plasmashell's PanelView).
    Plasmoid.status: editing
        ? PlasmaCore.Types.AcceptingInputStatus
        : PlasmaCore.Types.ActiveStatus

    preferredRepresentation: fullRepresentation

    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.fillWidth: true

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.fillWidth: true

        Rectangle {
            id: bar
            anchors.fill: parent
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            radius: height / 2
            color: plasmoid.configuration.barColor
            opacity: (root.hasTask || root.editing)
                ? plasmoid.configuration.barOpacity
                : 0.2

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.longDuration }
            }
        }

        PlasmaComponents3.Label {
            id: label
            anchors.fill: bar
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            visible: !root.editing
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.hasTask ? root.taskText : i18n("What are you doing now?")
            opacity: root.hasTask ? 1.0 : 0.6
            font.bold: root.hasTask
        }

        MouseArea {
            anchors.fill: bar
            visible: !root.editing
            cursorShape: Qt.IBeamCursor
            onClicked: {
                editField.text = root.taskText;
                root.editing = true;
                focusGrabTimer.restart();
            }
        }

        // Panel needs a moment to become the active window after the status
        // change before the field can take real keyboard focus.
        Timer {
            id: focusGrabTimer
            interval: 100
            onTriggered: {
                editField.forceActiveFocus();
                editField.selectAll();
            }
        }

        PlasmaComponents3.TextField {
            id: editField
            anchors.fill: bar
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            visible: root.editing
            horizontalAlignment: Text.AlignHCenter
            placeholderText: i18n("What are you doing now?")

            onAccepted: {
                plasmoid.configuration.taskText = text.trim();
                root.editing = false;
            }
            Keys.onEscapePressed: root.editing = false
            onActiveFocusChanged: {
                // Only treat focus loss as cancel after focus was actually
                // gained — panel activation is async on entering edit mode.
                if (!activeFocus && root.editing && !focusGrabTimer.running) {
                    root.editing = false;
                }
            }
        }
    }
}
