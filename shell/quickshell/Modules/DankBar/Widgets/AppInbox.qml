import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

BasePill {
    id: root

    readonly property var appPanels: [
        { key: "github", label: "GH", count: GitHubService.openPrCount, icon: "code", color: GitHubService.authenticated ? Theme.surfaceText : Theme.error },
        { key: "slack", label: "SL", count: SlackService.unreadCount, icon: "forum", color: SlackService.authenticated ? Theme.primary : Theme.surfaceVariantText },
        { key: "linear", label: "LN", count: LinearService.activeIssueCount, icon: "line_axis", color: LinearService.authenticated ? Theme.secondary : Theme.surfaceVariantText },
        { key: "gmail", label: "GM", count: GmailService.unreadCount, icon: "mail", color: GmailService.authenticated ? Theme.primary : Theme.surfaceVariantText },
        { key: "calendar", label: "CA", count: AppCalendarService.todayEventCount, icon: "event", color: AppCalendarService.configured ? Theme.error : Theme.surfaceVariantText },
        { key: "deployments", label: "DP", count: DeploymentService.problemCount, icon: "deployed_code", color: DeploymentService.problemCount > 0 ? Theme.error : Theme.primary }
    ]
    readonly property int totalCount: appPanels.reduce((sum, app) => sum + app.count, 0)
    readonly property bool maximizeWidgetIcons: barConfig && barConfig.maximizeWidgetIcons !== undefined ? barConfig.maximizeWidgetIcons : false
    readonly property real iconScale: barConfig && barConfig.iconScale !== undefined ? barConfig.iconScale : 1
    property bool isActive: false
    signal providerClicked(string provider)

    content: Component {
        Item {
            implicitWidth: root.isVerticalOrientation ? root.widgetThickness - root.horizontalPadding * 2 : appInboxRow.implicitWidth
            implicitHeight: root.widgetThickness - root.horizontalPadding * 2

            RowLayout {
                id: appInboxRow
                anchors.centerIn: parent
                visible: !root.isVerticalOrientation
                spacing: Theme.spacingS

                Repeater {
                    model: root.appPanels

                    Rectangle {
                        required property var modelData

                        Layout.preferredWidth: appChipContent.implicitWidth + 12
                        Layout.preferredHeight: 24
                        radius: 12
                        color: Theme.withAlpha(modelData.color, root.isMouseHovered || root.isActive ? 0.18 : 0.1)
                        border.width: modelData.key === "github" ? 1 : 0
                        border.color: Theme.withAlpha(modelData.color, root.isMouseHovered || root.isActive ? 0.55 : 0.28)

                        RowLayout {
                            id: appChipContent
                            anchors.centerIn: parent
                            spacing: 5

                            DankIcon {
                                name: modelData.icon
                                size: 14
                                color: modelData.color
                            }

                            StyledText {
                                text: modelData.label + " " + modelData.count
                                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig && root.barConfig.fontScale !== undefined ? root.barConfig.fontScale : 1, root.barConfig && root.barConfig.maximizeWidgetText === true) - 1
                                font.weight: Font.Medium
                                color: Theme.widgetTextColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.providerClicked(modelData.key)
                        }
                    }
                }
            }

            Item {
                anchors.centerIn: parent
                visible: root.isVerticalOrientation
                width: root.widgetThickness - root.horizontalPadding * 2
                height: root.widgetThickness - root.horizontalPadding * 2

                DankIcon {
                    anchors.centerIn: parent
                    name: "inbox"
                    size: Theme.barIconSize(root.barThickness, -7, root.maximizeWidgetIcons, root.iconScale)
                    color: GitHubService.authenticated ? (root.isActive || root.isMouseHovered ? Theme.primary : Theme.widgetIconColor) : Theme.error
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    anchors.right: parent.right
                    anchors.top: parent.top
                    color: Theme.primary
                    visible: root.totalCount > 0

                    StyledText {
                        anchors.centerIn: parent
                        text: root.totalCount
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.background
                    }
                }
            }
        }
    }
}
