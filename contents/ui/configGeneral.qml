import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    // Keep in sync with the barColor default in config/main.xml
    readonly property color defaultBarColor: "#2ecc71"
    property alias cfg_placeholderText: placeholderField.text
    property alias cfg_barColor: colorButton.color
    property alias cfg_barOpacity: opacitySlider.value
    property alias cfg_fontColor: fontColorButton.color
    property alias cfg_showTimer: showTimerCheck.checked
    property string cfg_timerFontFamily
    property string cfg_fontFamily

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Default text:")

            QQC2.TextField {
                id: placeholderField
                placeholderText: i18n("What are you doing now?")
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: placeholderField.text !== ""
                onClicked: placeholderField.text = ""
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Bar color:")

            KQuickControls.ColorButton {
                id: colorButton
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: !Qt.colorEqual(colorButton.color, defaultBarColor)
                onClicked: colorButton.color = defaultBarColor
            }
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
                // Dialog hides the alpha channel, so a pick made while the
                // stored value was transparent keeps alpha 0 — force opaque.
                onColorChanged: {
                    if (color.a === 0 && (color.r > 0 || color.g > 0 || color.b > 0)) {
                        color = Qt.rgba(color.r, color.g, color.b, 1);
                    }
                }
            }

            QQC2.Button {
                text: i18n("Use theme color")
                onClicked: fontColorButton.color = "transparent"
            }
        }

        QQC2.CheckBox {
            id: showTimerCheck
            Kirigami.FormData.label: i18n("Timer:")
            text: i18n("Show timer on task")
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
