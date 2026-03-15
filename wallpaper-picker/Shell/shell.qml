import Quickshell
import QtQuick
import "wallpaper"

ShellRoot {
    FloatingWindow {
        id: pickerWindow
        title: "wallpaper-picker"
        visible: true
        color: "transparent"

        implicitWidth: Screen.width
        implicitHeight: 500

        Component.onCompleted: {
            x = 0;
            y = Math.floor((Screen.height) - (implicitHeight) /2);
            requestActivate();
        }

        WallpaperPicker {
            anchors.fill: parent
        }
    }
}
