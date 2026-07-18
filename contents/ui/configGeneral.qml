import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    property alias cfg_barColor: colorButton.color
    property alias cfg_barOpacity: opacitySlider.value

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
    }
}
