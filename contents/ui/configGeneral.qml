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
    property color cfg_fontColor
    property alias cfg_showTimer: showTimerCheck.checked
    property string cfg_timerFontFamily
    property string cfg_fontFamily

    // No controls here — declared so "Reset all settings" can restore the
    // Blink reminder and Pomodoro pages' keys too. Defaults must match
    // config/main.xml.
    property bool cfg_blinkEnabled
    property int cfg_blinkIntervalMinutes
    property color cfg_blinkColor
    property bool cfg_pomodoroEnabled
    property int cfg_pomodoroMinutes
    property int cfg_restMinutes
    property color cfg_restColor

    function resetAllSettings() {
        placeholderField.text = "";
        colorButton.color = defaultBarColor;
        fontCombo.currentIndex = 0;
        cfg_fontFamily = "";
        themeFontColorCheck.checked = true;
        syncFontColor();
        showTimerCheck.checked = true;
        timerFontCombo.currentIndex = 0;
        cfg_timerFontFamily = "";
        cfg_blinkEnabled = false;
        cfg_blinkIntervalMinutes = 3;
        cfg_blinkColor = "#32CD32";
        cfg_pomodoroEnabled = false;
        cfg_pomodoroMinutes = 20;
        cfg_restMinutes = 5;
        cfg_restColor = "#95a5a6";
    }

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

            ColorSwatches {
                enabled: !themeFontColorCheck.checked
                onPicked: c => fontColorButton.color = c
            }
        }

        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.largeSpacing }

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

            ColorSwatches {
                onPicked: c => colorButton.color = c
            }
        }

        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.largeSpacing }

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

        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.largeSpacing }

        QQC2.Button {
            text: i18n("Reset all settings")
            icon.name: "edit-undo"
            onClicked: resetAllSettings()
        }
    }
}
