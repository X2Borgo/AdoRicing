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
    property var messages: []

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")
    readonly property string addressPath: configHome + "/DankMaterialShell/secrets/gmail-address"
    readonly property string passwordPath: configHome + "/DankMaterialShell/secrets/gmail-app-password"
    readonly property string scriptPath: Quickshell.env("DMS_GMAIL_SCRIPT") || "/usr/share/quickshell/dms/scripts/gmail_imap.py"
    readonly property int messageCount: authenticated ? messages.length : 0
    readonly property int unreadCount: authenticated ? messages.filter(message => message.unread === true).length : 0
    readonly property string summary: {
        if (!configured)
            return I18n.tr("Gmail address and App Password required");
        if (!authenticated)
            return errorMessage || I18n.tr("Gmail authorization required");
        if (loading && messages.length === 0)
            return I18n.tr("Checking important mail...");
        if (messages.length === 0)
            return I18n.tr("Inbox is empty");
        return I18n.tr("%1 unread · %2 recent messages").arg(unreadCount).arg(messages.length);
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 180000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        loading = true;
        Proc.runCommand("gmail-app-inbox", ["/usr/bin/python3", scriptPath, addressPath, passwordPath], function(stdout, exitCode) {
            root.loading = false;
            try {
                const payload = JSON.parse((stdout || "").trim());
                root.configured = payload.configured === true;
                root.authenticated = payload.authenticated === true;
                root.errorMessage = payload.error || (exitCode !== 0 ? I18n.tr("Gmail request failed") : "");
                if (root.authenticated && Array.isArray(payload.rows))
                    root.messages = payload.rows;
            } catch (error) {
                root.authenticated = false;
                root.errorMessage = I18n.tr("Could not parse Gmail response");
            }
        }, 50, 45000);
    }

    function relativeTime(timestamp) {
        const seconds = Math.max(0, Math.floor((Date.now() - timestamp) / 1000));
        if (seconds < 60) return I18n.tr("just now");
        if (seconds < 3600) return I18n.tr("%1m ago").arg(Math.floor(seconds / 60));
        if (seconds < 86400) return I18n.tr("%1h ago").arg(Math.floor(seconds / 3600));
        return I18n.tr("%1d ago").arg(Math.floor(seconds / 86400));
    }

    function messageRows(limit) {
        return messages.slice(0, limit || 50).map(message => ({
            id: message.id,
            title: message.subject,
            sender: message.sender,
            senderAddress: message.senderAddress,
            body: message.snippet,
            unread: message.unread === true,
            important: message.important === true,
            starred: message.starred === true,
            received: message.received,
            receivedLabel: relativeTime(message.received),
            url: message.url
        }));
    }
}
