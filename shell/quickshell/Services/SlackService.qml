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
    property string errorMessage: ""
    property string workspace: ""
    property string userName: ""
    property string tokenMode: ""
    property var conversations: []
    property int unreadCount: 0

    readonly property string scriptPath: Quickshell.env("DMS_SLACK_SCRIPT") || "/usr/share/quickshell/dms/scripts/slack_inbox.py"
    readonly property string summary: {
        if (!configured)
            return errorMessage || I18n.tr("Slack token required");
        if (!authenticated)
            return errorMessage || I18n.tr("Slack authentication failed");
        if (loading && conversations.length === 0)
            return I18n.tr("Checking Slack...");
        if (tokenMode === "bot")
            return conversations.length === 0
                ? I18n.tr("No bot-visible activity in 7 days")
                : I18n.tr("%1 active bot-visible conversations").arg(conversations.length);
        if (conversations.length === 0)
            return I18n.tr("No recent Slack activity");
        return I18n.tr("%1 recent conversations").arg(conversations.length);
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (loading)
            return;
        loading = true;
        Proc.runCommand("slack-app-inbox", ["/usr/bin/python3", scriptPath], function(stdout, exitCode) {
            root.loading = false;
            try {
                const payload = JSON.parse((stdout || "").trim());
                root.configured = payload.configured === true;
                root.authenticated = payload.authenticated === true;
                root.errorMessage = payload.error || (exitCode !== 0 ? I18n.tr("Slack refresh failed") : "");
                if (root.authenticated) {
                    root.conversations = Array.isArray(payload.rows) ? payload.rows : [];
                    root.unreadCount = payload.total || 0;
                    root.workspace = payload.workspace || "";
                    root.userName = payload.user || "";
                    root.tokenMode = payload.mode || "user";
                }
            } catch (error) {
                root.authenticated = false;
                root.errorMessage = I18n.tr("Could not parse Slack response");
            }
        }, 50, 45000);
    }

    function conversationRows() {
        return conversations.map(conversation => ({
            id: conversation.id,
            title: conversation.name,
            kind: conversation.kind,
            isDm: conversation.isDm === true,
            unread: conversation.unread || 0,
            activity: conversation.activity || 0,
            messages: Array.isArray(conversation.messages) ? conversation.messages : [],
            body: (conversation.messages || []).map(message => message.sender + ": " + message.text).join("\n\n"),
            url: conversation.url
        }));
    }
}
