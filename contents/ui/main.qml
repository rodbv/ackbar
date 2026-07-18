import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string taskText: plasmoid.configuration.taskText
    readonly property bool hasTask: taskText.length > 0
    readonly property string fontFamily: plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family

    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
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
            opacity: root.hasTask ? plasmoid.configuration.barOpacity : 0.2

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.longDuration }
            }
        }

        PlasmaComponents3.Label {
            anchors.fill: bar
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.hasTask ? root.taskText : i18n("What are you doing now?")
            opacity: root.hasTask ? 1.0 : 0.6
            font.bold: root.hasTask
            font.family: root.fontFamily
            color: (plasmoid.configuration.fontColor && plasmoid.configuration.fontColor.toString() !== "#00000000")
                ? plasmoid.configuration.fontColor
                : Kirigami.Theme.textColor
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
                    plasmoid.configuration.taskText = text.trim();
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
                    root.expanded = false;
                }
            }
        }
    }
}
