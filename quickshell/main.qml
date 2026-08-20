import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell

    property bool notificationsOpen: false
    property var appPanels: [
        { key: "github", name: "GitHub", icon: "", count: 4, tone: "#c0c0c0", detail: "2 reviews, 1 CI fail" },
        { key: "slack", name: "Slack", icon: "󰒱", count: 7, tone: "#00f0ff", detail: "3 DMs, 4 mentions" },
        { key: "linear", name: "Linear", icon: "󰰔", count: 3, tone: "#d000ff", detail: "Assigned issues" },
        { key: "calendar", name: "Calendar", icon: "󰃭", count: 1, tone: "#ff4d4d", detail: "Next in 24m" }
    ]
    property var notifications: [
        { app: "GitHub", icon: "", title: "Review requested", body: "AdoRicing PR #42 is waiting for your pass.", time: "Now", priority: "normal", color: "#c0c0c0" },
        { app: "GitHub", icon: "󰅙", title: "CI failed", body: "quickshell-panel check failed on lint.", time: "8m", priority: "urgent", color: "#ff4d4d" },
        { app: "Slack", icon: "󰒱", title: "Mention in #desktop", body: "Andrea asked about the notification adapter shape.", time: "12m", priority: "normal", color: "#00f0ff" },
        { app: "Linear", icon: "󰰔", title: "Issue moved to urgent", body: "ADO-18: app panels need real provider wiring.", time: "31m", priority: "urgent", color: "#d000ff" },
        { app: "Calendar", icon: "󰃭", title: "Design review", body: "Starts in 24 minutes.", time: "24m", priority: "normal", color: "#ff4d4d" }
    ]

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

                Item { Layout.fillWidth: true }

                // ==========================================
                // CENTER MODULE: APP PANELS
                // ==========================================
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: appPanelRow.implicitWidth + 24
                    color: "#1a2035"
                    border.color: "#00f0ff"
                    border.width: 1
                    radius: 5

                    RowLayout {
                        id: appPanelRow
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Repeater {
                            model: shell.appPanels

                            Rectangle {
                                required property var modelData

                                Layout.preferredWidth: Math.max(74, appPanelContent.implicitWidth + 16)
                                Layout.fillHeight: true
                                color: appMouse.containsMouse ? "#252d46" : "transparent"
                                border.color: modelData.count > 0 ? modelData.tone : "#0f152e"
                                border.width: modelData.count > 0 ? 1 : 0
                                radius: 4

                                RowLayout {
                                    id: appPanelContent
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Label {
                                        text: modelData.icon
                                        color: modelData.tone
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 15
                                    }

                                    Label {
                                        text: modelData.count
                                        color: "#c0c0c0"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: appMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: shell.notificationsOpen = !shell.notificationsOpen
                                }

                                ToolTip.visible: appMouse.containsMouse
                                ToolTip.text: modelData.name + ": " + modelData.detail
                                ToolTip.delay: 400
                            }
                        }
                    }
                }

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

                        Rectangle {
                            Layout.preferredWidth: notificationButtonContent.implicitWidth + 18
                            Layout.fillHeight: true
                            color: notificationMouse.containsMouse || shell.notificationsOpen ? "#252d46" : "transparent"
                            border.color: shell.notificationsOpen ? "#00f0ff" : "transparent"
                            border.width: shell.notificationsOpen ? 1 : 0
                            radius: 4

                            RowLayout {
                                id: notificationButtonContent
                                anchors.centerIn: parent
                                spacing: 6

                                Label {
                                    text: "󰂚"
                                    color: "#00f0ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Label {
                                    text: shell.notifications.length
                                    color: "#c0c0c0"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: notificationMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: shell.notificationsOpen = !shell.notificationsOpen
                            }

                            ToolTip.visible: notificationMouse.containsMouse
                            ToolTip.text: "Notifications"
                            ToolTip.delay: 400
                        }
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

    PanelWindow {
        id: notificationDrawer
        anchors {
            top: true
            right: true
        }
        implicitWidth: 430
        implicitHeight: shell.notificationsOpen ? 500 : 0
        visible: shell.notificationsOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 48
            anchors.rightMargin: 8
            color: "#1a2035"
            border.color: "#d000ff"
            border.width: 1
            radius: 6

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: "App Inbox"
                            color: "#c0c0c0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            text: "GitHub, Slack, Linear and system events"
                            color: "#8f98aa"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 26
                        color: closeMouse.containsMouse ? "#252d46" : "transparent"
                        border.color: "#0f152e"
                        border.width: 1
                        radius: 4

                        Label {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: "#c0c0c0"
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: shell.notificationsOpen = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#0f152e"
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: shell.notifications

                    delegate: Rectangle {
                        required property var modelData

                        width: ListView.view.width
                        height: Math.max(78, notificationText.implicitHeight + 24)
                        color: notificationItemMouse.containsMouse ? "#252d46" : "#0f152e"
                        border.color: modelData.priority === "urgent" ? modelData.color : "#252d46"
                        border.width: 1
                        radius: 5

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                color: "#1a2035"
                                border.color: modelData.color
                                border.width: 1
                                radius: 5

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.color
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                id: notificationText
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: "#c0c0c0"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: modelData.time
                                        color: "#8f98aa"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                    }
                                }

                                Label {
                                    text: modelData.app
                                    color: modelData.color
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.body
                                    color: "#aeb6c6"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: notificationItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
