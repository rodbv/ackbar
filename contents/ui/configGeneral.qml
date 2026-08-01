import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    // Keep in sync with the barColor/blinkColor defaults in config/main.xml
    readonly property color defaultBarColor: "#2ecc71"
    readonly property color defaultBlinkColor: "#32CD32"
    property alias cfg_placeholderText: placeholderField.text
    property alias cfg_barColor: colorButton.color
    property alias cfg_barOpacity: opacitySlider.value
    property color cfg_fontColor
    property alias cfg_showTimer: showTimerCheck.checked
    property alias cfg_blinkIntervalMinutes: blinkIntervalSpin.value
    property alias cfg_blinkColor: blinkColorButton.color
    property string cfg_timerFontFamily
    property string cfg_fontFamily

    function syncFontColor() {
        cfg_fontColor = themeFontColorCheck.checked
            ? Qt.rgba(0, 0, 0, 0)
            : Qt.rgba(fontColorButton.color.r, fontColorButton.color.g,
                      fontColorButton.color.b, 1);
    }

    Component.onCompleted: {
        const custom = cfg_fontColor.a > 0;
        themeFontColorCheck.checked = !custom;
        fontColorButton.color = custom
            ? Qt.rgba(cfg_fontColor.r, cfg_fontColor.g, cfg_fontColor.b, 1)
            : Kirigami.Theme.textColor;
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Text")
        }

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

            // Theme mode is stored as transparent (#00000000). A hidden-alpha
            // color dialog keeps alpha 0 on picks, which made black
            // indistinguishable from the sentinel — hence an explicit checkbox
            // instead of inferring intent from channel values.
            QQC2.CheckBox {
                id: themeFontColorCheck
                text: i18n("Use theme color")
                onToggled: syncFontColor()
            }

            KQuickControls.ColorButton {
                id: fontColorButton
                enabled: !themeFontColorCheck.checked
                showAlphaChannel: false
                onColorChanged: syncFontColor()
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Bar")
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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Timer")
        }

        QQC2.CheckBox {
            id: showTimerCheck
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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Blink reminder")
        }

        QQC2.SpinBox {
            id: blinkIntervalSpin
            Kirigami.FormData.label: i18n("Interval:")
            from: 0
            to: 120
            stepSize: 1
            textFromValue: (value, locale) => value === 0
                ? i18n("Off")
                : i18np("every %1 minute", "every %1 minutes", value)
            valueFromText: (text, locale) => parseInt(text) || 0
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Color:")

            KQuickControls.ColorButton {
                id: blinkColorButton
                enabled: blinkIntervalSpin.value > 0
            }

            QQC2.Button {
                text: i18n("Reset to default")
                enabled: blinkIntervalSpin.value > 0
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
