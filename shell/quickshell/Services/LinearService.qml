pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property bool configured: false
    property bool authenticated: false
    property bool loading: false
    property bool hasError: false
    property string errorMessage: ""
    property string viewerName: ""
    property var issues: []
    property int lastUpdatedUnix: 0

    readonly property string keyPath: (Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")) + "/DankMaterialShell/secrets/linear-api-key"
    readonly property int activeIssueCount: authenticated ? issues.length : 0
    readonly property string summary: {
        if (!configured)
            return I18n.tr("Personal API key required");
        if (hasError)
            return errorMessage || I18n.tr("Linear refresh failed");
        if (loading && issues.length === 0)
            return I18n.tr("Checking assigned issues...");
        if (!authenticated)
            return I18n.tr("Linear authentication failed");
        if (issues.length === 0)
            return I18n.tr("No active issues assigned to you");
        if (issues.length === 1)
            return I18n.tr("1 active issue assigned to you");
        return I18n.tr("%1 active issues assigned to you").arg(issues.length);
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        loading = true;
        hasError = false;

        Proc.runCommand("linear-app-inbox", [
            "sh",
            "-c",
            "keyfile=\"$1\"; if [ ! -s \"$keyfile\" ]; then printf '%s\\n' '{\"configured\":false,\"data\":null,\"error\":\"\"}'; exit 0; fi; key=$(tr -d '\\r\\n' < \"$keyfile\"); response=$(curl -sS --fail-with-body --max-time 18 -X POST -H 'Content-Type: application/json' -H \"Authorization: $key\" --data-raw '{\"query\":\"query AppInbox { viewer { name assignedIssues(first: 50) { nodes { id identifier title description url priority priorityLabel updatedAt dueDate team { name key } project { name } state { name type color } comments(last: 1) { nodes { createdAt user { name } } } } } } }\"}' https://api.linear.app/graphql 2>/dev/null) || { printf '%s\\n' '{\"configured\":true,\"data\":null,\"error\":\"Linear API request failed\"}'; exit 0; }; printf '{\"configured\":true,\"data\":%s,\"error\":\"\"}\\n' \"$response\"",
            "linear-app-inbox",
            keyPath
        ], function (stdout, exitCode) {
            root.loading = false;
            root.lastUpdatedUnix = Math.floor(Date.now() / 1000);

            try {
                const parsed = JSON.parse((stdout || "").trim());
                root.configured = parsed.configured === true;
                const response = parsed.data || {};
                const errors = Array.isArray(response.errors) ? response.errors : [];
                const viewer = response.data && response.data.viewer ? response.data.viewer : null;
                root.authenticated = root.configured && viewer !== null && errors.length === 0;
                root.viewerName = viewer && viewer.name ? viewer.name : "";

                const nodes = viewer && viewer.assignedIssues && Array.isArray(viewer.assignedIssues.nodes) ? viewer.assignedIssues.nodes : [];
                root.issues = nodes.filter(issue => {
                    const type = issue.state && issue.state.type ? issue.state.type : "";
                    return type !== "completed" && type !== "canceled";
                });

                root.errorMessage = parsed.error || (errors.length > 0 ? errors[0].message : "");
                root.hasError = root.errorMessage.length > 0 || exitCode !== 0;
            } catch (e) {
                root.configured = true;
                root.authenticated = false;
                root.issues = [];
                root.hasError = true;
                root.errorMessage = I18n.tr("Could not parse Linear response");
            }
        }, 50, 22000);
    }

    function _relativeTime(isoTime) {
        if (!isoTime)
            return I18n.tr("unknown");
        const then = Date.parse(isoTime);
        if (isNaN(then))
            return I18n.tr("unknown");
        const seconds = Math.max(0, Math.floor((Date.now() - then) / 1000));
        if (seconds < 60)
            return I18n.tr("just now");
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60)
            return I18n.tr("%1m ago").arg(minutes);
        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return I18n.tr("%1h ago").arg(hours);
        return I18n.tr("%1d ago").arg(Math.floor(hours / 24));
    }

    function _priorityRank(priority) {
        return priority === 0 ? 5 : priority;
    }

    function issueRows(limit) {
        const max = limit || 20;
        const sorted = issues.slice().sort((a, b) => {
            const priorityDifference = _priorityRank(a.priority || 0) - _priorityRank(b.priority || 0);
            if (priorityDifference !== 0)
                return priorityDifference;
            return Date.parse(b.updatedAt || 0) - Date.parse(a.updatedAt || 0);
        });

        return sorted.slice(0, max).map(issue => {
            const comments = issue.comments && Array.isArray(issue.comments.nodes) ? issue.comments.nodes : [];
            const latestComment = comments.length > 0 ? comments[comments.length - 1] : null;
            const context = issue.project && issue.project.name ? issue.project.name : (issue.team && issue.team.name ? issue.team.name : "Linear");
            return {
                identifier: issue.identifier || "",
                title: issue.title || I18n.tr("Untitled issue"),
                body: issue.description || "",
                url: issue.url || "",
                priority: issue.priority || 0,
                priorityLabel: issue.priorityLabel || I18n.tr("No priority"),
                state: issue.state && issue.state.name ? issue.state.name : I18n.tr("Unknown"),
                stateColor: issue.state && issue.state.color ? issue.state.color : Theme.surfaceVariantText,
                context: context,
                dueDate: issue.dueDate || "",
                updatedLabel: I18n.tr("updated %1").arg(_relativeTime(issue.updatedAt)),
                commentLabel: latestComment ? I18n.tr("%1 commented %2").arg(latestComment.user && latestComment.user.name ? latestComment.user.name : I18n.tr("Someone")).arg(_relativeTime(latestComment.createdAt)) : "",
                hasRecentComment: latestComment ? Date.now() - Date.parse(latestComment.createdAt) < 86400000 : false
            };
        });
    }
}
