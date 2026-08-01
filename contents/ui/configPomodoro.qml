import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
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
