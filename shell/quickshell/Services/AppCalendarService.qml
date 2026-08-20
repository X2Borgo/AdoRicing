pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property bool configured: false
    property bool loading: false
    property bool hasError: false
    property string errorMessage: ""
    property var events: []

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")
    readonly property string urlPath: configHome + "/DankMaterialShell/secrets/google-calendar-ical-url"
    readonly property string scriptPath: Quickshell.env("DMS_CALENDAR_FEED_SCRIPT") || "/usr/share/quickshell/dms/scripts/google_calendar_feed.py"
    readonly property string uvPath: (Quickshell.env("HOME") || "") + "/.local/bin/uv"
    readonly property int eventCount: configured && !hasError ? events.length : 0
    readonly property int todayEventCount: {
        if (!configured || hasError)
            return 0;
        const today = new Date();
        return events.filter(event => new Date(event.start).toDateString() === today.toDateString()).length;
    }
    readonly property string summary: {
        if (!configured)
            return I18n.tr("Private iCal URL required");
        if (hasError)
            return errorMessage || I18n.tr("Calendar refresh failed");
        if (loading && events.length === 0)
            return I18n.tr("Loading upcoming events...");
        if (events.length === 0)
            return I18n.tr("No events in the next 30 days");
        return I18n.tr("%1 events in the next 30 days").arg(events.length);
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
        Proc.runCommand("calendar-app-inbox", [
            "sh", "-c",
            "if [ ! -s \"$1\" ]; then printf '%s\\n' '{\"configured\":false,\"events\":[],\"error\":\"\"}'; exit 0; fi; uv_bin=\"$3\"; if [ ! -x \"$uv_bin\" ]; then uv_bin=$(command -v uv 2>/dev/null) || { printf '%s\\n' '{\"configured\":true,\"events\":[],\"error\":\"Calendar runtime not found\"}'; exit 0; }; fi; output=$(\"$uv_bin\" run --script \"$2\" \"$1\" 2>/dev/null) || { printf '%s\\n' '{\"configured\":true,\"events\":[],\"error\":\"Calendar feed request failed\"}'; exit 0; }; printf '{\"configured\":true,\"payload\":%s,\"error\":\"\"}\\n' \"$output\"",
            "calendar-app-inbox", urlPath, scriptPath, uvPath
        ], function (stdout, exitCode) {
            root.loading = false;
            try {
                const parsed = JSON.parse((stdout || "").trim());
                root.configured = parsed.configured === true;
                root.errorMessage = parsed.error || "";
                root.hasError = root.errorMessage.length > 0 || exitCode !== 0;
                if (!root.hasError && parsed.payload && Array.isArray(parsed.payload.events))
                    root.events = parsed.payload.events;
            } catch (e) {
                root.configured = true;
                root.hasError = true;
                root.errorMessage = I18n.tr("Could not parse calendar response");
            }
        }, 50, 30000);
    }

    function _dayLabel(start) {
        const eventDate = new Date(start);
        const today = new Date();
        const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
        if (eventDate.toDateString() === today.toDateString())
            return I18n.tr("Today");
        if (eventDate.toDateString() === tomorrow.toDateString())
            return I18n.tr("Tomorrow");
        return Qt.formatDate(eventDate, "ddd, MMM d");
    }

    function eventRows(limit) {
        return events.slice(0, limit || 100).map(event => ({
            id: event.id,
            title: event.title,
            body: event.description || "",
            url: event.url || "https://calendar.google.com/calendar/u/0/r",
            location: event.location || "",
            start: event.start,
            end: event.end,
            allDay: event.allDay === true,
            dayLabel: _dayLabel(event.start),
            timeLabel: event.allDay ? I18n.tr("All day") : Qt.formatTime(new Date(event.start), "HH:mm") + "–" + Qt.formatTime(new Date(event.end), "HH:mm")
        }));
    }
}
