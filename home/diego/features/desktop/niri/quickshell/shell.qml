import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "."

ShellRoot {
    id: root

    // ── niri IPC: workspaces via the JSON event stream ──────────────
    property var workspaces: []
    property string windowTitle: ""
    property string kbLayout: "US"

    // Live event stream from niri. Each event updates our model.
    Process {
        id: niriEvents
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const ev = JSON.parse(line);
                    if (ev.WorkspacesChanged) {
                        let ws = ev.WorkspacesChanged.workspaces;
                        ws.sort((a, b) => a.idx - b.idx);
                        root.workspaces = ws;
                    } else if (ev.WorkspaceActivated) {
                        // Re-mark active/focused workspace.
                        const id = ev.WorkspaceActivated.id;
                        let ws = root.workspaces.map(w => {
                            w.is_active = (w.id === id);
                            w.is_focused = (w.id === id);
                            return w;
                        });
                        root.workspaces = ws;
                    } else if (ev.KeyboardLayoutsChanged) {
                        const k = ev.KeyboardLayoutsChanged.keyboard_layouts;
                        root.kbLayout = root.shortLayout(k.names[k.current_idx]);
                    } else if (ev.KeyboardLayoutSwitched) {
                        // Some niri versions emit this with just the idx.
                    }
                } catch (e) {
                    // ignore non-JSON / partial lines
                }
            }
        }
    }

    // Poll focused window title (cheap, event stream window data is noisy).
    Process {
        id: niriWindow
        running: true
        command: ["sh", "-c",
            "niri msg --json event-stream | " +
            "while read -r l; do case \"$l\" in *WindowFocusChanged*|*WindowsChanged*|*WindowOpenedOrChanged*) " +
            "niri msg -j focused-window | jq -r 'if .==null then \"\" else (.title // \"\") end';; esac; done"]
        stdout: SplitParser {
            onRead: line => root.windowTitle = line.substring(0, 90)
        }
    }

    function shortLayout(name) {
        if (!name) return "??";
        if (name.indexOf("English") === 0) return "US";
        if (name.indexOf("Spanish") === 0) return "ES";
        return name.substring(0, 2).toUpperCase();
    }

    // ── Clock ───────────────────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Battery (sysfs poll) ────────────────────────────────────────
    property string batteryText: ""
    Process {
        id: batteryProc
        command: ["sh", "-c",
            "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); " +
            "[ -z \"$b\" ] && exit 0; " +
            "c=$(cat $b/capacity); s=$(cat $b/status); " +
            "echo \"$s $c\""]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(" ");
                if (parts.length < 2) return;
                const charging = (parts[0] === "Charging" || parts[0] === "Full");
                root.batteryText = (charging ? "\uf0e7 " : "") + parts[1] + "%";
            }
        }
    }
    Timer {
        interval: 20000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: batteryProc.running = true
    }

    // ── Volume (wpctl poll) ─────────────────────────────────────────
    property string volumeText: ""
    Process {
        id: volumeProc
        command: ["sh", "-c",
            "v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); " +
            "echo \"$v\""]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/Volume: ([0-9.]+)/);
                if (!m) return;
                const pct = Math.round(parseFloat(m[1]) * 100);
                root.volumeText = (line.indexOf("MUTED") >= 0)
                    ? "\uf6a9 muted"
                    : "\uf028 " + pct + "%";
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: volumeProc.running = true
    }

    // ── Bar: one panel per screen ───────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 36
            color: Theme.base00
            WlrLayershell.namespace: "quickshell-bar"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 0

                // Left: workspaces
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignLeft
                    Repeater {
                        model: root.workspaces
                        Rectangle {
                            required property var modelData
                            implicitWidth: 26
                            implicitHeight: 24
                            radius: 6
                            color: modelData.is_urgent ? Theme.base08
                                 : modelData.is_focused ? Theme.base0D
                                 : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.idx
                                color: (modelData.is_focused || modelData.is_urgent)
                                    ? Theme.base00
                                    : (modelData.is_active ? Theme.base05 : Theme.base04)
                                font.family: Theme.font
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: niriFocus.exec(
                                    ["niri", "msg", "action", "focus-workspace",
                                     String(modelData.idx)])
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Center: clock
                Text {
                    text: Qt.formatDateTime(clock.date, "ddd dd MMM   HH:mm")
                    color: Theme.base05
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                // Right: window title + modules
                RowLayout {
                    spacing: 14
                    Layout.alignment: Qt.AlignRight

                    Text {
                        text: root.windowTitle
                        color: Theme.base04
                        elide: Text.ElideRight
                        Layout.maximumWidth: 360
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    Text {
                        text: root.kbLayout
                        color: Theme.base0A
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        visible: root.volumeText !== ""
                        text: root.volumeText
                        color: Theme.base0C
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    Text {
                        visible: root.batteryText !== ""
                        text: root.batteryText
                        color: Theme.base0E
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    Process { id: niriFocus }
}
