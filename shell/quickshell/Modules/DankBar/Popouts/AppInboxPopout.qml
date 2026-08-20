import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

DankPopout {
    id: root

    layerNamespace: "dms:app-inbox"

    property var triggerScreen: null
    property string activeProvider: "github"
    property string searchQuery: ""
    property string activeFilter: "all"
    property string githubSortMode: "Latest update"
    property string githubRepoFilter: "All repositories"
    property int selectedIndex: 0

    readonly property color panelColor: "#181825"
    readonly property color insetColor: "#11111b"
    readonly property color controlColor: "#25283a"
    readonly property color raisedColor: "#313244"
    readonly property color textColor: "#cdd6f4"
    readonly property color mutedColor: "#a6adc8"
    readonly property color outlineColor: "#45475a"
    readonly property color accentColor: "#89b4fa"
    readonly property color accentTextColor: "#11111b"

    readonly property var providers: [
        { key: "github", label: "GitHub", icon: "code", count: GitHubService.openPrCount, enabled: true },
        { key: "slack", label: "Slack", icon: "forum", count: SlackService.unreadCount, enabled: true },
        { key: "linear", label: "Linear", icon: "line_axis", count: LinearService.activeIssueCount, enabled: true },
        { key: "gmail", label: "Gmail", icon: "mail", count: GmailService.unreadCount, enabled: true },
        { key: "calendar", label: "Calendar", icon: "event", count: AppCalendarService.eventCount, enabled: true },
        { key: "deployments", label: "Deploy", icon: "deployed_code", count: DeploymentService.problemCount, enabled: true }
    ]
    readonly property var githubRepositories: ["All repositories"].concat(GitHubService.repositoryNames())
    readonly property var sourceItems: activeProvider === "github"
        ? GitHubService.prRows(20, githubRepoFilter, githubSortMode)
        : activeProvider === "slack" ? SlackService.conversationRows()
        : activeProvider === "linear" ? LinearService.issueRows(50)
        : activeProvider === "gmail" ? GmailService.messageRows(50)
        : activeProvider === "calendar" ? AppCalendarService.eventRows(100)
        : activeProvider === "deployments" ? DeploymentService.rows : []
    readonly property var visibleItems: filterItems(sourceItems)
    readonly property var selectedItem: visibleItems.length > 0 ? visibleItems[Math.min(selectedIndex, visibleItems.length - 1)] : null

    popupWidth: Math.min(920, (screen ? screen.width : 960) - 40)
    popupHeight: Math.min(620, (screen ? screen.height : 700) - 80)
    triggerWidth: 84
    positioning: ""
    screen: triggerScreen

    onBackgroundClicked: close()
    onActiveProviderChanged: {
        resetView();
        refreshActiveProvider();
    }
    onActiveFilterChanged: selectedIndex = 0
    onGithubSortModeChanged: selectedIndex = 0
    onGithubRepoFilterChanged: selectedIndex = 0
    onSearchQueryChanged: selectedIndex = 0
    onGithubRepositoriesChanged: {
        if (githubRepositories.indexOf(githubRepoFilter) < 0)
            githubRepoFilter = "All repositories";
    }

    function resetView() {
        searchQuery = "";
        activeFilter = "all";
        selectedIndex = 0;
    }

    function refreshActiveProvider() {
        if (activeProvider === "github")
            GitHubService.refresh();
        else if (activeProvider === "slack")
            SlackService.refresh();
        else if (activeProvider === "linear")
            LinearService.refresh();
        else if (activeProvider === "gmail")
            GmailService.refresh();
        else if (activeProvider === "calendar")
            AppCalendarService.refresh();
        else if (activeProvider === "deployments")
            DeploymentService.refresh();
    }

    function filterItems(items) {
        const query = searchQuery.trim().toLowerCase();
        const filtered = items.filter(item => {
            const searchable = activeProvider === "github"
                ? [item.title, item.repo, item.ciLabel].join(" ").toLowerCase()
                : activeProvider === "slack"
                    ? [item.title, item.kind, item.body].join(" ").toLowerCase()
                : activeProvider === "linear"
                    ? [item.identifier, item.title, item.context, item.state, item.priorityLabel].join(" ").toLowerCase()
                    : activeProvider === "gmail"
                        ? [item.sender, item.senderAddress, item.title, item.body].join(" ").toLowerCase()
                    : activeProvider === "deployments"
                        ? [item.name, item.source, item.scope, item.status, item.detail].join(" ").toLowerCase()
                    : [item.title, item.location, item.dayLabel, item.timeLabel].join(" ").toLowerCase();
            if (query && searchable.indexOf(query) < 0)
                return false;

            if (activeProvider === "linear") {
                const state = (item.state || "").trim().toLowerCase();
                if (activeFilter === "all" && (state === "done" || state === "done archive" || state === "duplicate"))
                    return false;
                if (activeFilter === "urgent" && item.priority !== 1)
                    return false;
                if (activeFilter === "high" && item.priority !== 2)
                    return false;
                if (activeFilter !== "all" && activeFilter !== "urgent" && activeFilter !== "high" && state.indexOf(activeFilter) < 0)
                    return false;
            }
            if (activeProvider === "slack") {
                if (activeFilter === "unread" && item.unread <= 0)
                    return false;
                if (activeFilter === "dms" && !item.isDm)
                    return false;
                if (activeFilter === "channels" && item.isDm)
                    return false;
            }
            if (activeProvider === "github" && activeFilter === "failed" && item.ciStatus !== "FAILURE" && item.ciStatus !== "ERROR")
                return false;
            if (activeProvider === "calendar") {
                const eventDate = new Date(item.start);
                const eventEnd = new Date(item.end);
                const now = new Date();
                if ((activeFilter === "all" || activeFilter === "week") && eventEnd.getTime() <= now.getTime())
                    return false;
                if (activeFilter === "today" && eventDate.toDateString() !== now.toDateString())
                    return false;
                if (activeFilter === "week" && eventDate.getTime() > now.getTime() + 7 * 86400000)
                    return false;
            }
            if (activeProvider === "deployments") {
                if (activeFilter === "problems" && !item.problem)
                    return false;
                if (activeFilter === "docker" && item.source !== "docker")
                    return false;
                if (activeFilter === "kubernetes" && item.source !== "kubernetes")
                    return false;
            }
            if (activeProvider === "gmail") {
                if (activeFilter === "unread" && !item.unread)
                    return false;
                if (activeFilter === "important" && !item.important)
                    return false;
                if (activeFilter === "starred" && !item.starred)
                    return false;
            }
            return true;
        });

        if (activeProvider === "linear" && activeFilter === "all") {
            const stateRank = {
                "in review": 0,
                "in progress": 1,
                "todo": 2,
                "backlog": 3
            };
            filtered.sort((a, b) => {
                const aState = (a.state || "").trim().toLowerCase();
                const bState = (b.state || "").trim().toLowerCase();
                const aRank = stateRank[aState] === undefined ? 4 : stateRank[aState];
                const bRank = stateRank[bState] === undefined ? 4 : stateRank[bState];
                return aRank - bRank;
            });
        }

        return filtered;
    }

    function itemId(item) {
        if (activeProvider === "github") return "#" + item.number;
        if (activeProvider === "slack") return item.activity;
        if (activeProvider === "linear") return item.identifier;
        if (activeProvider === "gmail") return item.starred ? "STAR" : "MAIL";
        if (activeProvider === "deployments") return item.id;
        return item.dayLabel;
    }

    function itemTitle(item) {
        if (activeProvider === "github") return item.title.replace(/^#[0-9]+\s*/, "");
        if (activeProvider === "deployments") return item.name;
        return item.title;
    }

    function itemMeta(item) {
        if (activeProvider === "github") return item.repo + " · " + item.ciLabel + " · " + item.detail;
        if (activeProvider === "slack") return item.kind + " · " + I18n.tr("%1 recent messages").arg(item.activity);
        if (activeProvider === "linear") return item.context + " · " + (item.commentLabel || item.updatedLabel);
        if (activeProvider === "gmail") return item.sender + " · " + item.receivedLabel;
        if (activeProvider === "deployments") return item.scope + " · " + item.status + (item.detail ? " · " + item.detail : "");
        return item.timeLabel + (item.location ? " · " + item.location : "");
    }

    function linearStateIcon(item) {
        const state = (item.state || "").toLowerCase();
        if (state.indexOf("review") >= 0)
            return "rate_review";
        if (state.indexOf("progress") >= 0 || state.indexOf("started") >= 0)
            return "progress_activity";
        if (state.indexOf("backlog") >= 0)
            return "inventory_2";
        return "radio_button_unchecked";
    }

    function linearPriorityIcon(item) {
        if (item.priority === 1)
            return "priority_high";
        if (item.priority === 2)
            return "keyboard_double_arrow_up";
        if (item.priority === 3)
            return "drag_handle";
        if (item.priority === 4)
            return "keyboard_arrow_down";
        return "remove";
    }

    function linearPriorityColor(item) {
        if (item.priority === 1)
            return "#f38ba8";
        if (item.priority === 2)
            return "#f9e2af";
        if (item.priority === 3)
            return accentColor;
        return mutedColor;
    }

    function detailContext(item) {
        if (activeProvider === "github") return item.repo;
        if (activeProvider === "slack") return SlackService.workspace || I18n.tr("Slack");
        if (activeProvider === "linear") return item.context;
        if (activeProvider === "gmail") return item.senderAddress || item.sender;
        if (activeProvider === "deployments") return item.source === "docker" ? I18n.tr("Local Docker") : DeploymentService.kubernetesContext;
        return item.location || I18n.tr("Google Calendar");
    }

    function detailMeta(item) {
        if (activeProvider === "github") return item.ciLabel + " · " + item.detail;
        if (activeProvider === "slack") return item.kind + " · " + I18n.tr("%1 recent messages").arg(item.activity);
        if (activeProvider === "linear") return item.state + " · " + item.priorityLabel + " · " + (item.commentLabel || item.updatedLabel);
        if (activeProvider === "gmail") return (item.unread ? I18n.tr("Unread") : I18n.tr("Read")) + (item.important ? " · " + I18n.tr("Important") : "") + " · " + item.receivedLabel;
        if (activeProvider === "deployments") return item.status + (item.detail ? " · " + item.detail : "");
        return item.dayLabel + " · " + item.timeLabel;
    }

    function detailBody(item) {
        if (activeProvider === "deployments") {
            const source = item.source === "docker" ? I18n.tr("Docker container") : I18n.tr("Kubernetes pod");
            return source + "\n" + I18n.tr("Scope: %1").arg(item.scope) + "\n" + I18n.tr("Status: %1").arg(item.status) + (item.detail ? "\n" + item.detail : "");
        }
        return item.body || I18n.tr("No description provided.");
    }

    function statusColor(item) {
        if (!item)
            return mutedColor;
        if (activeProvider === "linear")
            return item.stateColor;
        if (activeProvider === "slack")
            return "#cba6f7";
        if (activeProvider === "gmail")
            return item.starred ? "#f9e2af" : "#f38ba8";
        if (activeProvider === "deployments")
            return item.problem ? "#f38ba8" : "#a6e3a1";
        if (activeProvider === "calendar")
            return "#f38ba8";
        if (item.ciStatus === "SUCCESS")
            return "#a6e3a1";
        if (item.ciStatus === "PENDING" || item.ciStatus === "EXPECTED")
            return "#f9e2af";
        if (item.ciStatus === "FAILURE" || item.ciStatus === "ERROR")
            return "#f38ba8";
        return mutedColor;
    }

    content: Component {
        Rectangle {
            id: panel

            implicitHeight: root.popupHeight
            color: root.panelColor
            radius: 10
            border.width: 1
            border.color: root.outlineColor
            clip: true
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: Theme.spacingM

                    DankIcon {
                        name: root.activeProvider === "linear" ? "line_axis" : root.activeProvider === "github" ? "code" : root.activeProvider === "slack" ? "forum" : root.activeProvider === "gmail" ? "mail" : root.activeProvider === "calendar" ? "event" : root.activeProvider === "deployments" ? "deployed_code" : "inbox"
                        size: 22
                        color: root.accentColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: root.activeProvider === "github" ? I18n.tr("GitHub Pull Requests") : root.activeProvider === "linear" ? I18n.tr("Linear Issues") : root.activeProvider === "gmail" ? I18n.tr("Gmail") : root.activeProvider === "calendar" ? I18n.tr("Google Calendar") : root.activeProvider === "deployments" ? I18n.tr("Deployment Status") : I18n.tr("Slack")
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.DemiBold
                            font.family: Theme.monoFontFamily
                            color: root.textColor
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.activeProvider === "github"
                                ? I18n.tr("%1 open PRs · authored by you").arg(GitHubService.openPrCount)
                                : root.activeProvider === "linear" ? I18n.tr("%1 active issues · assigned to you").arg(LinearService.activeIssueCount)
                                : root.activeProvider === "gmail" ? GmailService.summary
                                : root.activeProvider === "calendar" ? AppCalendarService.summary
                                : root.activeProvider === "deployments" ? DeploymentService.summary : SlackService.summary
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.monoFontFamily
                            color: root.mutedColor
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }

                    DankActionButton {
                        buttonSize: 34
                        iconName: "refresh"
                        iconSize: 17
                        iconColor: root.accentTextColor
                        backgroundColor: root.accentColor
                        tooltipText: I18n.tr("Refresh")
                        onClicked: root.refreshActiveProvider()
                    }

                    DankActionButton {
                        buttonSize: 34
                        iconName: "close"
                        iconSize: 17
                        iconColor: root.accentTextColor
                        backgroundColor: root.accentColor
                        tooltipText: I18n.tr("Close")
                        onClicked: root.close()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.providers

                        Rectangle {
                            required property var modelData
                            readonly property bool selected: root.activeProvider === modelData.key

                            Layout.preferredWidth: providerContent.implicitWidth + 22
                            Layout.preferredHeight: 34
                            radius: 10
                            color: selected ? root.accentColor : (providerMouse.containsMouse && modelData.enabled ? root.raisedColor : root.controlColor)
                            opacity: modelData.enabled ? 1.0 : 0.48

                            RowLayout {
                                id: providerContent
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: modelData.icon
                                    size: 15
                                    color: parent.parent.selected ? root.accentTextColor : root.textColor
                                }

                                StyledText {
                                    text: modelData.label
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    font.family: Theme.monoFontFamily
                                    color: parent.parent.selected ? root.accentTextColor : root.textColor
                                }
                            }

                            MouseArea {
                                id: providerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (modelData.enabled)
                                        root.activeProvider = modelData.key;
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                DankTextField {
                    visible: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: root.searchQuery
                    placeholderText: root.activeProvider === "github" ? I18n.tr("Search PR number, title, repository, CI...") : root.activeProvider === "slack" ? I18n.tr("Search conversation or message...") : root.activeProvider === "linear" ? I18n.tr("Search issue number, title, project, status...") : root.activeProvider === "gmail" ? I18n.tr("Search sender, subject, message...") : root.activeProvider === "deployments" ? I18n.tr("Search workload, namespace, image, status...") : I18n.tr("Search event title, location, date...")
                    leftIconName: "search"
                    showClearButton: true
                    font.family: Theme.monoFontFamily
                    textColor: root.textColor
                    placeholderColor: root.mutedColor
                    leftIconColor: root.mutedColor
                    leftIconFocusedColor: root.accentColor
                    backgroundColor: root.insetColor
                    normalBorderColor: root.accentColor
                    focusedBorderColor: "#cba6f7"
                    cornerRadius: 10
                    onTextEdited: root.searchQuery = text
                }

                RowLayout {
                    visible: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.activeProvider === "linear"
                            ? [{ label: "All", value: "all" }, { label: "Urgent", value: "urgent" }, { label: "High", value: "high" }, { label: "Todo", value: "todo" }, { label: "In Progress", value: "in progress" }, { label: "In Review", value: "review" }]
                            : root.activeProvider === "gmail"
                                ? [{ label: "All", value: "all" }, { label: "Unread", value: "unread" }, { label: "Important", value: "important" }, { label: "Starred", value: "starred" }]
                            : root.activeProvider === "calendar"
                                ? [{ label: "All", value: "all" }, { label: "Today", value: "today" }, { label: "Next 7 days", value: "week" }]
                                : root.activeProvider === "deployments"
                                    ? [{ label: "All", value: "all" }, { label: "Problems", value: "problems" }, { label: "Docker", value: "docker" }, { label: "Kubernetes", value: "kubernetes" }]
                                : root.activeProvider === "slack"
                                    ? [{ label: "All", value: "all" }, { label: "Unread", value: "unread" }, { label: "DMs", value: "dms" }, { label: "Channels", value: "channels" }]
                                : [{ label: "All", value: "all" }, { label: "CI failed", value: "failed" }]

                        Rectangle {
                            required property var modelData
                            readonly property bool selected: root.activeFilter === modelData.value

                            Layout.preferredWidth: filterText.implicitWidth + 24
                            Layout.preferredHeight: 30
                            radius: 10
                            color: selected ? root.accentColor : (filterMouse.containsMouse ? root.raisedColor : root.controlColor)
                            border.width: selected ? 0 : 1
                            border.color: root.outlineColor

                            StyledText {
                                id: filterText
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.monoFontFamily
                                color: parent.selected ? root.accentTextColor : root.textColor
                            }

                            MouseArea {
                                id: filterMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeFilter = modelData.value
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                    visible: root.activeProvider === "github"
                        Layout.preferredWidth: sortContent.implicitWidth + 20
                        Layout.preferredHeight: 30
                        radius: 10
                        color: root.accentColor

                        RowLayout {
                            id: sortContent
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon { name: "sort"; size: 14; color: root.accentTextColor }
                            StyledText {
                                text: root.githubSortMode === "Latest update" ? I18n.tr("Latest") : I18n.tr("Failed first")
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.monoFontFamily
                                color: root.accentTextColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.githubSortMode = root.githubSortMode === "Latest update" ? "CI failed first" : "Latest update"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.horizontalStretchFactor: 11
                        radius: 8
                        color: root.controlColor
                        border.width: 1
                        border.color: root.outlineColor
                        clip: true

                        DankListView {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            model: root.visibleItems
                            spacing: 4
                            clip: true

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool selected: root.selectedIndex === index

                                width: ListView.view.width
                                height: 68
                                radius: 7
                                clip: true
                                color: selected ? root.raisedColor : (itemMouse.containsMouse ? Theme.withAlpha(root.accentColor, 0.08) : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingM

                                    ColumnLayout {
                                        spacing: 2

                                        Rectangle {
                                            Layout.preferredWidth: idText.implicitWidth + 20
                                            Layout.preferredHeight: 28
                                            radius: 9
                                            color: "transparent"
                                            border.width: 1
                                            border.color: root.outlineColor

                                            StyledText {
                                                id: idText
                                                anchors.centerIn: parent
                                                text: root.itemId(modelData)
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.DemiBold
                                                font.family: Theme.monoFontFamily
                                                color: root.accentColor
                                            }
                                        }

                                        RowLayout {
                                            visible: root.activeProvider === "linear"
                                            Layout.alignment: Qt.AlignHCenter
                                            spacing: Theme.spacingXS

                                            DankIcon {
                                                name: root.linearStateIcon(modelData)
                                                size: 14
                                                color: modelData.stateColor || root.mutedColor
                                            }

                                            DankIcon {
                                                name: root.linearPriorityIcon(modelData)
                                                size: 15
                                                color: root.linearPriorityColor(modelData)
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: root.itemTitle(modelData)
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Medium
                                            font.family: Theme.monoFontFamily
                                            color: root.textColor
                                            wrapMode: Text.NoWrap
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                            clip: true
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: root.itemMeta(modelData)
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.family: Theme.monoFontFamily
                                            color: root.mutedColor
                                            wrapMode: Text.NoWrap
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                            clip: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 6
                                        Layout.preferredHeight: 34
                                        radius: 3
                                        color: root.statusColor(modelData)
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedIndex = index
                                    onDoubleClicked: {
                                        if (modelData.url)
                                            Qt.openUrlExternally(modelData.url);
                                    }
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            width: Math.max(0, parent.width - Theme.spacingL * 2)
                            visible: root.visibleItems.length === 0
                            text: root.activeProvider === "calendar" && (!AppCalendarService.configured || AppCalendarService.hasError) ? AppCalendarService.summary : root.activeProvider === "gmail" ? GmailService.summary : root.activeProvider === "deployments" ? DeploymentService.summary : root.activeProvider === "slack" ? SlackService.summary : I18n.tr("No matching items")
                            font.pixelSize: Theme.fontSizeMedium
                            font.family: Theme.monoFontFamily
                            color: root.mutedColor
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAnywhere
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.horizontalStretchFactor: 9
                        radius: 8
                        color: root.insetColor
                        border.width: 1
                        border.color: root.outlineColor
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM
                            visible: root.selectedItem !== null

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                Rectangle {
                                    Layout.preferredWidth: detailId.implicitWidth + 20
                                    Layout.preferredHeight: 28
                                    radius: 9
                                    color: root.controlColor
                                    border.width: 1
                                    border.color: root.outlineColor

                                    StyledText {
                                        id: detailId
                                        anchors.centerIn: parent
                                        text: root.selectedItem ? root.itemId(root.selectedItem) : ""
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.DemiBold
                                        font.family: Theme.monoFontFamily
                                        color: root.accentColor
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.selectedItem ? root.detailContext(root.selectedItem) : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.monoFontFamily
                                    color: root.mutedColor
                                    elide: Text.ElideRight
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.selectedItem ? root.itemTitle(root.selectedItem) : ""
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.DemiBold
                                font.family: Theme.monoFontFamily
                                color: root.textColor
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.selectedItem ? root.detailMeta(root.selectedItem) : ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.monoFontFamily
                                color: root.selectedItem ? root.statusColor(root.selectedItem) : root.mutedColor
                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: root.outlineColor
                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: width
                                contentHeight: detailBody.implicitHeight
                                clip: true

                                StyledText {
                                    id: detailBody
                                    width: parent.width
                                    text: root.selectedItem ? root.detailBody(root.selectedItem) : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.monoFontFamily
                                    color: root.textColor
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Rectangle {
                                visible: root.activeProvider !== "deployments"
                                Layout.preferredWidth: openContent.implicitWidth + 24
                                Layout.preferredHeight: 34
                                radius: 10
                                color: root.accentColor

                                RowLayout {
                                    id: openContent
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS
                                    DankIcon { name: "open_in_new"; size: 15; color: root.accentTextColor }
                                    StyledText {
                                        text: root.activeProvider === "github" ? I18n.tr("Open on GitHub") : root.activeProvider === "slack" ? I18n.tr("Open in Slack") : root.activeProvider === "linear" ? I18n.tr("Open in Linear") : root.activeProvider === "gmail" ? I18n.tr("Open in Gmail") : I18n.tr("Open Google Calendar")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.DemiBold
                                        font.family: Theme.monoFontFamily
                                        color: root.accentTextColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.selectedItem && root.selectedItem.url)
                                            Qt.openUrlExternally(root.selectedItem.url);
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
