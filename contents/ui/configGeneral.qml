import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    property alias cfg_barColor: colorButton.color
    property alias cfg_barOpacity: opacitySlider.value
    property alias cfg_fontColor: fontColorButton.color
    property alias cfg_showTimer: showTimerCheck.checked
    property string cfg_timerFontFamily
    property string cfg_fontFamily

    Kirigami.FormLayout {
        KQuickControls.ColorButton {
            id: colorButton
            Kirigami.FormData.label: i18n("Bar color:")
        }

        QQC2.Slider {
            id: opacitySlider
            Kirigami.FormData.label: i18n("Bar tint strength:")
            from: 0.2
            to: 1.0
            stepSize: 0.05
        }

        QQC2.ComboBox {
            id: fontCombo
            Kirigami.FormData.label: i18n("Font:")
            model: [i18n("Default font")].concat(Qt.fontFamilies())
            onActivated: cfg_fontFamily = currentIndex === 0 ? "" : currentText
            Component.onCompleted: {
                const idx = Qt.fontFamilies().indexOf(cfg_fontFamily);
                currentIndex = idx >= 0 ? idx + 1 : 0;
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Font color:")

            KQuickControls.ColorButton {
                id: fontColorButton
                showAlphaChannel: false
            }

            QQC2.Button {
                text: i18n("Use theme color")
                onClicked: fontColorButton.color = "transparent"
            }
        }

        QQC2.CheckBox {
            id: showTimerCheck
            Kirigami.FormData.label: i18n("Timer:")
            text: i18n("Show time on task")
        }

        QQC2.ComboBox {
            id: timerFontCombo
            Kirigami.FormData.label: i18n("Timer font:")
            enabled: showTimerCheck.checked
            model: [i18n("Default monospace")].concat(Qt.fontFamilies())
            onActivated: cfg_timerFontFamily = currentIndex === 0 ? "" : currentText
            Component.onCompleted: {
                const idx = Qt.fontFamilies().indexOf(cfg_timerFontFamily);
                currentIndex = idx >= 0 ? idx + 1 : 0;
            }
        }
    }
}
