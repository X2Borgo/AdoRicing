pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property bool loading: false
    property string dockerError: ""
    property string kubernetesError: ""
    property string kubernetesContext: ""
    property var rows: []
    property int problemCount: 0

    readonly property string scriptPath: Quickshell.env("DMS_DEPLOYMENT_STATUS_SCRIPT") || "/usr/share/quickshell/dms/scripts/deployment_status.py"
    readonly property string summary: {
        if (loading && rows.length === 0)
            return I18n.tr("Checking deployments...");
        if (problemCount > 0)
            return I18n.tr("%1 deployment problems").arg(problemCount);
        if (rows.length > 0)
            return I18n.tr("%1 workloads healthy").arg(rows.length);
        if (dockerError && kubernetesError)
            return I18n.tr("Docker and Kubernetes unavailable");
        return I18n.tr("No workloads found");
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function refresh() {
        loading = true;
        Proc.runCommand("deployment-app-inbox", ["/usr/bin/python3", scriptPath], function(stdout, exitCode) {
            root.loading = false;
            try {
                const payload = JSON.parse((stdout || "").trim());
                root.rows = Array.isArray(payload.rows) ? payload.rows : [];
                root.problemCount = payload.problemCount || 0;
                root.dockerError = payload.dockerError || "";
                root.kubernetesError = payload.kubernetesError || "";
                root.kubernetesContext = payload.context || "";
            } catch (error) {
                root.rows = [];
                root.problemCount = 0;
                root.dockerError = I18n.tr("Could not read deployment status");
                root.kubernetesError = exitCode !== 0 ? root.dockerError : "";
            }
        }, 50, 20000);
    }
}
