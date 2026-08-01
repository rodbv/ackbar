import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    // Keep in sync with the blinkColor default in config/main.xml
    readonly property color defaultBlinkColor: "#32CD32"
    property alias cfg_blinkEnabled: enabledCheck.checked
    property alias cfg_blinkIntervalMinutes: blinkIntervalSpin.value
    property alias cfg_blinkColor: blinkColorButton.color

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: enabledCheck
            text: i18n("Enable blink reminder")
        }

        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.largeSpacing }

        QQC2.SpinBox {
            id: blinkIntervalSpin
            Kirigami.FormData.label: i18n("Interval:")
            enabled: enabledCheck.checked
            from: 1
            to: 120
            stepSize: 1
            textFromValue: (value, locale) => i18np("every %1 minute", "every %1 minutes", value)
            valueFromText: (text, locale) => parseInt(text) || 3
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Color:")

            KQuickControls.ColorButton {
                id: blinkColorButton
                enabled: enabledCheck.checked
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: enabledCheck.checked
                    && !Qt.colorEqual(blinkColorButton.color, defaultBlinkColor)
                onClicked: blinkColorButton.color = defaultBlinkColor
            }
        }

        QQC2.Label {
            text: i18n("The bar blinks in the selected color at the selected interval, while a task is set.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
