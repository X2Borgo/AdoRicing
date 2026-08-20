import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var summary: null
    property bool refreshing: false
    property var wtData: null
    property bool wtRefreshing: false

    readonly property string scriptsDir: Qt.resolvedUrl("./scripts/").toString().replace("file://", "")
    // Health tracks the repos' real state: main checkouts only. Feature
    // worktrees carry duplicate catalogs and would inflate the numbers.
    readonly property var mainTrees: summary ? summary.worktrees.filter(w => w.branch === "main") : []
    readonly property int mainUntr: mainTrees.reduce((a, w) => a + w.untranslated, 0)
    readonly property int mainFuzzy: mainTrees.reduce((a, w) => a + w.fuzzy, 0)

    popoutWidth: 380

    function applySummary(raw, fromRefresh) {
        try {
            root.summary = JSON.parse(raw);
            if (fromRefresh)
                ToastService.showInfo("i18n data refreshed");
        } catch (e) {
            if (fromRefresh)
                ToastService.showError("i18n refresh failed");
        }
    }

    Process {
        id: summaryProc
        command: [root.scriptsDir + "summary.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.applySummary(this.text, false)
        }
    }

    Process {
        id: refreshProc
        command: [root.scriptsDir + "refresh.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshing = false;
                root.applySummary(this.text, true);
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.refreshing = false;
                ToastService.showError("i18n refresh failed (exit " + code + ")");
            }
        }
    }

    Process {
        id: wtCachedProc
        command: ["python3", root.scriptsDir + "worktrees.py", "cached"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.wtData = JSON.parse(this.text) } catch (e) {}
            }
        }
    }

    Process {
        id: wtRefreshProc
        command: ["python3", root.scriptsDir + "worktrees.py", "collect"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wtRefreshing = false;
                try {
                    root.wtData = JSON.parse(this.text);
                } catch (e) {
                    ToastService.showError("worktree scan failed");
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.wtRefreshing = false;
                ToastService.showError("worktree scan failed (exit " + code + ")");
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: {
            summaryProc.running = true;
            wtCachedProc.running = true;
        }
    }

    function refreshWorktrees() {
        if (root.wtRefreshing)
            return;
        root.wtRefreshing = true;
        wtRefreshProc.running = true;
    }

    function wtStateLabel(w) {
        switch (w.state) {
        case "broken": return "broken";
        case "dirty": return "dirty";
        case "unpushed": return w.upstream ? w.ahead + " unpushed" : "no upstream";
        case "merged-clean": return "merged · cleanable";
        case "open-pr": return "PR open";
        default: return "no PR";
        }
    }

    function wtStateColor(w) {
        switch (w.state) {
        case "broken":
        case "dirty": return Theme.error;
        case "unpushed": return Theme.warning;
        case "merged-clean": return Theme.primary;
        default: return Theme.surfaceVariantText;
        }
    }

    function refresh() {
        if (root.refreshing)
            return;
        root.refreshing = true;
        refreshProc.running = true;
    }

    function openDashboard() {
        // Open the freshest dashboard.html; build it first if missing.
        // open.sh avoids xdg-open, which hangs on this system (xprop probe).
        Quickshell.execDetached(["sh", "-c",
            'f="${XDG_CACHE_HOME:-$HOME/.cache}/instal-i18n/dashboard.html"; '
            + '[ -f "$f" ] || "' + root.scriptsDir + 'refresh.sh" > /dev/null; '
            + 'exec "' + root.scriptsDir + 'open.sh" "file://$f"']);
    }

    horizontalBarPill: Component {
        Image {
            source: Qt.resolvedUrl("./assets/amaki-icon.png")
            width: root.iconSize
            height: root.iconSize
            sourceSize.width: root.iconSize * 2
            sourceSize.height: root.iconSize * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    verticalBarPill: Component {
        Image {
            source: Qt.resolvedUrl("./assets/amaki-icon.png")
            width: root.iconSize
            height: root.iconSize
            sourceSize.width: root.iconSize * 2
            sourceSize.height: root.iconSize * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        Item {
            implicitHeight: contentCol.height + Theme.spacingM * 2

            Column {
                id: contentCol
                x: Theme.spacingM
                y: Theme.spacingM
                width: parent.width - Theme.spacingM * 2
                spacing: Theme.spacingM

                StyledText {
                    text: "Instal tools"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }

                // Translations tool card — more tools slot in below later.
                Rectangle {
                    width: parent.width
                    height: cardCol.height + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: cardCol
                        x: Theme.spacingM
                        y: Theme.spacingM
                        width: parent.width - Theme.spacingM * 2
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            Column {
                                width: parent.width - refreshButton.width - Theme.spacingS
                                spacing: 2

                                StyledText {
                                    text: "Translations"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: {
                                        if (root.refreshing)
                                            return "re-scanning worktrees…";
                                        if (!root.summary)
                                            return "no data yet — refresh";
                                        return root.mainUntr + " untranslated · " + root.mainFuzzy
                                               + " fuzzy on main\ndata from " + root.summary.generated;
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }

                            DankActionButton {
                                id: refreshButton
                                iconName: "refresh"
                                iconColor: root.refreshing ? Theme.surfaceVariantText : Theme.surfaceText
                                tooltipText: "Re-scan all worktrees"
                                onClicked: root.refresh()
                            }
                        }

                        DankButton {
                            text: "Open dashboard"
                            iconName: "open_in_browser"
                            onClicked: root.openDashboard()
                        }
                    }
                }

                // Worktrees tool card
                Rectangle {
                    width: parent.width
                    height: wtCol.height + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: wtCol
                        x: Theme.spacingM
                        y: Theme.spacingM
                        width: parent.width - Theme.spacingM * 2
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            Column {
                                width: parent.width - wtRefreshButton.width - Theme.spacingS
                                spacing: 2

                                StyledText {
                                    text: "Worktrees"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: {
                                        if (root.wtRefreshing)
                                            return "scanning worktrees + PR state…";
                                        if (!root.wtData)
                                            return "no data yet — refresh";
                                        return root.wtData.total + " worktrees · "
                                               + root.wtData.cleanable + " cleanable · "
                                               + root.wtData.dirty + " dirty\ndata from "
                                               + root.wtData.generated;
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }

                            DankActionButton {
                                id: wtRefreshButton
                                iconName: "refresh"
                                iconColor: root.wtRefreshing ? Theme.surfaceVariantText : Theme.surfaceText
                                tooltipText: "Re-scan worktrees and PR state"
                                onClicked: root.refreshWorktrees()
                            }
                        }

                        DankFlickable {
                            width: parent.width
                            height: Math.min(wtListCol.height, 300)
                            contentHeight: wtListCol.height
                            clip: true

                            Column {
                                id: wtListCol
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: root.wtData ? root.wtData.worktrees : []

                                    Item {
                                        required property var modelData
                                        width: wtListCol.width
                                        height: 24

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.right: wtState.left
                                            anchors.rightMargin: Theme.spacingS
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name + "  ·  " + modelData.branch
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceText
                                            elide: Text.ElideMiddle
                                        }

                                        StyledText {
                                            id: wtState
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.wtStateLabel(modelData)
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.DemiBold
                                            color: root.wtStateColor(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
