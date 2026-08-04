import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    // Keep in sync with the defaults in config/main.xml
    readonly property color defaultRestColor: "#95a5a6"
    readonly property int defaultPomodoroMinutes: 20
    readonly property int defaultRestMinutes: 5
    property alias cfg_pomodoroEnabled: enabledCheck.checked
    property alias cfg_pomodoroMinutes: workSpin.value
    property alias cfg_restMinutes: restSpin.value
    property alias cfg_restColor: restColorButton.color

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: enabledCheck
            text: i18n("Enable Pomodoro mode")
        }

        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.largeSpacing }

        RowLayout {
            Kirigami.FormData.label: i18n("Pomodoro duration:")

            QQC2.SpinBox {
                id: workSpin
                enabled: enabledCheck.checked
                from: 1
                to: 120
                stepSize: 1
                textFromValue: (value, locale) => i18np("%1 minute", "%1 minutes", value)
                valueFromText: (text, locale) => parseInt(text) || 20
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: enabledCheck.checked && workSpin.value !== defaultPomodoroMinutes
                onClicked: workSpin.value = defaultPomodoroMinutes
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Rest duration:")

            QQC2.SpinBox {
                id: restSpin
                enabled: enabledCheck.checked
                from: 1
                to: 60
                stepSize: 1
                textFromValue: (value, locale) => i18np("%1 minute", "%1 minutes", value)
                valueFromText: (text, locale) => parseInt(text) || 5
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: enabledCheck.checked && restSpin.value !== defaultRestMinutes
                onClicked: restSpin.value = defaultRestMinutes
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Rest bar color:")

            KQuickControls.ColorButton {
                id: restColorButton
                enabled: enabledCheck.checked
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: enabledCheck.checked
                    && !Qt.colorEqual(restColorButton.color, defaultRestColor)
                onClicked: restColorButton.color = defaultRestColor
            }

            ColorSwatches {
                enabled: enabledCheck.checked
                onPicked: c => restColorButton.color = c
            }
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
