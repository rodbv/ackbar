import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string taskText: plasmoid.configuration.taskText
    readonly property bool hasTask: taskText.length > 0
    property bool editing: false

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
                root.editing = true;
                editField.text = root.taskText;
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
                if (!activeFocus && root.editing) {
                    root.editing = false;
                }
            }
        }
    }
}
