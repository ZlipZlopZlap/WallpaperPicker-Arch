import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: window

    readonly property string srcDir: Quickshell.env("HOME") + "/Image/Wallpapers"
    readonly property string thumbDir: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_picker/thumbs"
    readonly property var transitions: ["grow", "outer", "any", "wipe", "wave", "center"]
    readonly property string targetOutput: Quickshell.env("QS_TARGET_OUTPUT") || "DP-1" //need to check your monitor
    readonly property int itemWidth: 300
    readonly property int itemHeight: 420
    readonly property int borderWidth: 3
    readonly property int spacing: 0
    readonly property real skewFactor: -0.35

    property bool initialFocusSet: false

    function shellQuote(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    function isVideoFile(name) {
        let lower = String(name).toLowerCase();
        return lower.endsWith(".mp4") || lower.endsWith(".mkv") || lower.endsWith(".mov") || lower.endsWith(".webm");
    }

    function focusFileByName(targetName) {
        if (!targetName || folderModel.count <= 0)
            return false;

        for (let i = 0; i < folderModel.count; i++) {
            const name = folderModel.get(i, "fileName");
            if (name === targetName) {
                view.currentIndex = i;
                view.positionViewAtIndex(i, ListView.Center);
                view.forceActiveFocus();
                initialFocusSet = true;
                return true;
            }
        }

        return false;
    }

    function focusCurrentWallpaper() {
        currentWall.running = true;
    }

	function pickWallpaper(fileName) {
        let cleanName = fileName.replace(/^file:\/\//, '');
        const fullPath = window.srcDir + "/" + cleanName;
        const output = window.targetOutput;
        const useMatugen = Quickshell.env("WALLPICKER_MATUGEN") === "1";

        const cacheFile = Quickshell.env("HOME") + "/.config/hypr/extra/current-wallpaper";

        //add matugen
        if (isVideoFile(fileName)) {
            const cmd = "pkill mpvpaper; " +
                        "mpvpaper -o 'loop --hwdec=auto --no-audio' " +
                        shellQuote(output) + " " +
                        shellQuote(fullPath);
            Quickshell.execDetached(["bash", "-c", cmd]);
        } else {
            const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)];

            let cmd = "pgrep -x swww-daemon >/dev/null || swww-daemon & sleep 0.2; ";
            cmd += `swww img -o ${shellQuote(output)} ${shellQuote(fullPath)} ` +
                   `--transition-type ${randomTransition} ` +
                   `--transition-pos 0.5,0.5 ` +
                   `--transition-fps 144 ` +
                   `--transition-duration 1`;

            cmd += `; echo ${shellQuote(fullPath)} > ${shellQuote(cacheFile)}`;

            if (useMatugen) {
                cmd += `; if command -v matugen >/dev/null 2>&1; then ` +
                       `matugen image ${shellQuote(fullPath)}; ` +
                       `else notify-send "Wallpicker" "matugen not found"; fi`;
            }
            cmd += `; notify-send "Обои" "$(basename ${shellQuote(fullPath)})"`;

            Quickshell.execDetached(["bash", "-c", cmd]);
        }

        Qt.quit();
    }

    Process {
        id: currentWall
        command: ["bash", "-c", "swww query 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();

                if (!out) {
                    if (!initialFocusSet && folderModel.count > 0) {
                        view.currentIndex = 0;
                        view.positionViewAtIndex(0, ListView.Center);
                        view.forceActiveFocus();
                        initialFocusSet = true;
                    }
                    return;
                }


                const match = out.match(/\/[^\n]+/);
                if (!match) {
                    if (!initialFocusSet && folderModel.count > 0) {
                        view.currentIndex = 0;
                        view.positionViewAtIndex(0, ListView.Center);
                        view.forceActiveFocus();
                        initialFocusSet = true;
                    }
                    return;
                }

                const fullPath = match[0].trim();
                const fileName = fullPath.split("/").pop();

                if (!window.focusFileByName(fileName) && !initialFocusSet && folderModel.count > 0) {
                    view.currentIndex = 0;
                    view.positionViewAtIndex(0, ListView.Center);
                    view.forceActiveFocus();
                    initialFocusSet = true;
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            view.decrementCurrentIndex();
            view.forceActiveFocus();
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            view.incrementCurrentIndex();
            view.forceActiveFocus();
        }
    }

    Shortcut {
        sequence: "A"
        onActivated: {
            view.decrementCurrentIndex();
            view.forceActiveFocus();
        }
    }

    Shortcut {
        sequence: "D"
        onActivated: {
            view.incrementCurrentIndex();
            view.forceActiveFocus();
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (view.currentIndex >= 0 && view.currentIndex < view.count) {
                const item = view.itemAtIndex(view.currentIndex);
                if (item) {
                    item.pickThisWallpaper();
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    ListView {
        id: view
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: window.spacing
        clip: false
        cacheBuffer: 2000
        focus: true
        currentIndex: 0

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - (window.itemWidth / 2)
        preferredHighlightEnd: (width / 2) + (window.itemWidth / 2)
        highlightMoveDuration: 300

        model: FolderListModel {
            id: folderModel
            folder: window.thumbDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
            showDirs: false
            sortField: FolderListModel.Name

            onStatusChanged: {
                if (status === FolderListModel.Ready && count > 0 && !window.initialFocusSet) {
                    window.focusCurrentWallpaper();
                }
            }
        }

        delegate: Item {
            id: delegateRoot
            width: window.itemWidth
            height: window.itemHeight

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isVideo: window.isVideoFile(fileName)

            function pickThisWallpaper() {
                view.currentIndex = index;
                window.pickWallpaper(fileName);
            }

            z: isCurrent ? 10 : 1

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPressed: {
                    view.currentIndex = index;
                    view.forceActiveFocus();
                }
                onClicked: {
                    delegateRoot.pickThisWallpaper();
                }
            }

            Item {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height

                scale: delegateRoot.isCurrent ? 1.15 : 0.95
                opacity: delegateRoot.isCurrent ? 1.0 : 0.6

                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 500 } }

                transform: Matrix4x4 {
                    property real s: window.skewFactor
                    matrix: Qt.matrix4x4(1, s, 0, 0,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, 0, 1)
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#101016"
                }

                Image {
                    anchors.fill: parent
                    source: delegateRoot.isVideo ? "" : fileUrl
                    fillMode: Image.Stretch
                    asynchronous: true
                    visible: !delegateRoot.isVideo
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                    }

                    clip: true

                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -50
                        width: parent.width + (parent.height * Math.abs(window.skewFactor)) + 50
                        height: parent.height
                        fillMode: Image.PreserveAspectCrop
                        source: delegateRoot.isVideo ? "" : fileUrl
                        asynchronous: true
                        visible: !delegateRoot.isVideo

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0,
                                                 0, 1, 0, 0,
                                                 0, 0, 1, 0,
                                                 0, 0, 0, 1)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: delegateRoot.isVideo
                        color: "#202030"

                        Text {
                            anchors.centerIn: parent
                            text: "VIDEO"
                            color: "white"
                            font.pixelSize: 28
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    visible: delegateRoot.isVideo
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    width: 32
                    height: 32
                    radius: 6
                    color: "#60000000"

                    transform: Matrix4x4 {
                        property real s: -window.skewFactor
                        matrix: Qt.matrix4x4(1, s, 0, 0,
                                             0, 1, 0, 0,
                                             0, 0, 1, 0,
                                             0, 0, 0, 1)
                    }

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 8
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.fillStyle = "#EEFFFFFF";
                            ctx.beginPath();
                            ctx.moveTo(4, 0);
                            ctx.lineTo(14, 8);
                            ctx.lineTo(4, 16);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        view.forceActiveFocus();
    }
}
