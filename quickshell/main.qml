import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    PanelWindow {
        id: root
        anchors {
            top: true
            left: true
            right: true
        }
        // [FIX] Updated to use the modern implicitHeight
        implicitHeight: 40
        color: "transparent"
        exclusionMode: ExclusionMode.Normal

        // --- MAIN BAR CONTAINER ---
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 10

                // ==========================================
                // LEFT MODULE: ADO ROSE & SPOTIFY
                // ==========================================
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth + 30
                    color: "#1a2035" // Module BG
                    border.color: "#00f0ff" // Neon Cyan
                    border.width: 1
                    radius: 5

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 10

                        // [FIX] Exact User Path
                        Image {
                            source: Qt.resolvedUrl("Ado-Rose.svg")
                            sourceSize.width: 20
                            sourceSize.height: 20
                            onStatusChanged: if (status == Image.Error) fallbackIcon.visible = true

                            Label {
                                id: fallbackIcon
                                text: "󰽉"
                                visible: false
                                color: "#ff4d4d"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }
                        }

                        // [FIX] Null-safety on stdout
                        Label {
                            text: spotifyProc.stdout ? spotifyProc.stdout.trim() : "System Idle"
                            color: "#c0c0c0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            Layout.maximumWidth: 300
                            elide: Text.ElideRight
                        }
                    }
                }

                // ==========================================
                // CENTER SPACER
                // ==========================================
                Item { Layout.fillWidth: true }

                // ==========================================
                // RIGHT MODULE: SYSTEM TRAY & CLOCK
                // ==========================================
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth + 30
                    color: "#1a2035" // Module BG
                    border.color: "#d000ff" // Magenta Glow
                    border.width: 1
                    radius: 5

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 15

                        Label { text: "󰂚 0"; color: "#00f0ff"; font.family: "JetBrainsMono Nerd Font" }
                        Rectangle { width: 1; height: 15; color: "#0f152e" }

                        // [FIX] Null-safety on all hardware fetches
                        Label { text: "󰖩  " + (wifiProc.stdout ? wifiProc.stdout.trim() : "..."); color: "#c0c0c0"; font.family: "JetBrainsMono Nerd Font" }
                        Label { text: "󰂯 ON"; color: "#c0c0c0"; font.family: "JetBrainsMono Nerd Font" }
                        Rectangle { width: 1; height: 15; color: "#0f152e" }
                        Label { text: "󰕾  " + (volProc.stdout ? volProc.stdout.trim() : "..."); color: "#c0c0c0"; font.family: "JetBrainsMono Nerd Font" }
                        Label { text: "󰁹 " + (batProc.stdout ? batProc.stdout.trim() : "...") + "%"; color: "#00f0ff"; font.family: "JetBrainsMono Nerd Font" }
                        Rectangle { width: 1; height: 15; color: "#0f152e" }

                        // [FIX] Safe date checking
                        Label {
                            text: SystemClock.date ? Qt.formatDateTime(SystemClock.date, "HH:mm // dd MMM") : "Loading..."
                            color: "#d000ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                        }
                    }
                }
            }
        }

        // ==========================================
        // BACKGROUND DAEMONS
        // ==========================================

        Process { id: spotifyProc; command: ["sh", "-c", "playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'No Media Playing'"] }
        Process { id: wifiProc; command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -n 1 || echo 'Disconnected'"] }
        Process { id: volProc; command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100 \"%\"}'"] }
        Process { id: batProc; command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 'AC'"] }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                spotifyProc.running = true
                wifiProc.running = true
                volProc.running = true
                batProc.running = true
            }
        }
    }
}
