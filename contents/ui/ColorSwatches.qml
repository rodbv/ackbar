import QtQuick
import org.kde.kirigami as Kirigami

// A row of one-click preset colors, complementing the full color dialog.
Row {
    id: swatches

    signal picked(color c)

    // Flat UI palette — same family as the bar/blink defaults.
    readonly property var presets: [
        "#ffffff", "#000000", "#e74c3c", "#e67e22", "#f1c40f",
        "#2ecc71", "#1abc9c", "#3498db", "#9b59b6", "#95a5a6"
    ]

    spacing: Kirigami.Units.smallSpacing

    Repeater {
        model: swatches.presets

        Rectangle {
            width: Kirigami.Units.gridUnit
            height: Kirigami.Units.gridUnit
            radius: 3
            color: modelData
            border.width: 1
            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
            opacity: swatches.enabled ? 1.0 : 0.3

            MouseArea {
                anchors.fill: parent
                enabled: swatches.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: swatches.picked(modelData)
            }
        }
    }
}
