pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property bool ghAvailable: false
    property bool authenticated: false
    property bool loading: false
    property bool hasError: false
    property string errorMessage: ""
    property var pullRequests: []
    property int lastUpdatedUnix: 0

    readonly property int openPrCount: authenticated ? pullRequests.length : 0
    readonly property string summary: {
        if (!ghAvailable)
            return I18n.tr("GitHub CLI is not installed");
        if (!authenticated)
            return I18n.tr("Run gh auth login to connect GitHub");
        if (hasError)
            return errorMessage || I18n.tr("GitHub refresh failed");
        if (loading && pullRequests.length === 0)
            return I18n.tr("Checking open PRs...");
        if (pullRequests.length === 0)
            return I18n.tr("No open PRs authored by you");
        if (pullRequests.length === 1)
            return _prSummary(pullRequests[0]);
        return I18n.tr("%1 open PRs authored by you").arg(pullRequests.length);
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

        Proc.runCommand("github-app-inbox", [
            "sh",
            "-c",
            "if ! command -v gh >/dev/null 2>&1; then printf '%s\\n' '{\"available\":false,\"authenticated\":false,\"items\":[],\"error\":\"GitHub CLI is not installed\"}'; exit 0; fi; if ! gh auth status -h github.com >/dev/null 2>&1; then printf '%s\\n' '{\"available\":true,\"authenticated\":false,\"items\":[],\"error\":\"GitHub authentication is invalid or missing\"}'; exit 0; fi; items=$(gh api graphql -f 'query=query($q:String!){search(query:$q,type:ISSUE,first:20){nodes{... on PullRequest{number title body url isDraft updatedAt comments{totalCount} repository{nameWithOwner} commits(last:1){nodes{commit{statusCheckRollup{state}}}}}}}}' -F 'q=is:pr is:open author:@me archived:false sort:updated-desc' --jq '.data.search.nodes' 2>/dev/null) || { printf '%s\\n' '{\"available\":true,\"authenticated\":true,\"items\":[],\"error\":\"GitHub PR search failed\"}'; exit 0; }; printf '{\"available\":true,\"authenticated\":true,\"items\":%s,\"error\":\"\"}\\n' \"$items\""
        ], function (stdout, exitCode) {
            root.loading = false;
            root.lastUpdatedUnix = Math.floor(Date.now() / 1000);

            try {
                const parsed = JSON.parse((stdout || "").trim());
                root.ghAvailable = parsed.available === true;
                root.authenticated = parsed.authenticated === true;
                root.pullRequests = Array.isArray(parsed.items) ? parsed.items : [];
                root.errorMessage = parsed.error || "";
                root.hasError = root.errorMessage.length > 0 || exitCode !== 0;
            } catch (e) {
                root.ghAvailable = true;
                root.authenticated = false;
                root.pullRequests = [];
                root.hasError = true;
                root.errorMessage = I18n.tr("Could not parse GitHub response");
            }
        }, 50, 20000);
    }

    function _repoName(pr) {
        if (pr.repository && pr.repository.nameWithOwner)
            return pr.repository.nameWithOwner;

        const repositoryUrl = pr.repository_url || "";
        const marker = "/repos/";
        const index = repositoryUrl.indexOf(marker);
        if (index >= 0)
            return repositoryUrl.slice(index + marker.length);
        return "GitHub";
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
        const days = Math.floor(hours / 24);
        return I18n.tr("%1d ago").arg(days);
    }

    function _commentLabel(count) {
        if (count === 0)
            return I18n.tr("no comments");
        if (count === 1)
            return I18n.tr("1 comment");
        return I18n.tr("%1 comments").arg(count);
    }

    function _prSummary(pr) {
        if (!pr)
            return I18n.tr("Open GitHub PR");
        return I18n.tr("%1, updated %2").arg(_repoName(pr)).arg(_relativeTime(pr.updatedAt || pr.updated_at));
    }

    function _ciStatus(pr) {
        const commits = pr.commits && pr.commits.nodes ? pr.commits.nodes : [];
        if (commits.length === 0 || !commits[0].commit || !commits[0].commit.statusCheckRollup)
            return "NONE";
        return commits[0].commit.statusCheckRollup.state || "NONE";
    }

    function _ciLabel(status) {
        switch (status) {
        case "SUCCESS": return I18n.tr("CI passed");
        case "FAILURE": return I18n.tr("CI failed");
        case "ERROR": return I18n.tr("CI error");
        case "PENDING": return I18n.tr("CI running");
        case "EXPECTED": return I18n.tr("CI expected");
        default: return I18n.tr("No CI run");
        }
    }

    function repositoryNames() {
        const names = pullRequests.map(item => _repoName(item));
        return names.filter((name, index) => names.indexOf(name) === index).sort();
    }

    function prRows(limit, repository, sortMode) {
        const max = limit || 5;
        let items = pullRequests.slice();

        if (repository && repository !== "All repositories")
            items = items.filter(item => _repoName(item) === repository);

        items.sort((a, b) => {
            if (sortMode === "CI failed first") {
                const aFailed = _ciStatus(a) === "FAILURE" || _ciStatus(a) === "ERROR";
                const bFailed = _ciStatus(b) === "FAILURE" || _ciStatus(b) === "ERROR";
                if (aFailed !== bFailed)
                    return aFailed ? -1 : 1;
            }
            return Date.parse(b.updatedAt || b.updated_at || 0) - Date.parse(a.updatedAt || a.updated_at || 0);
        });

        return items.slice(0, max).map(item => {
            const comments = item.comments && typeof item.comments.totalCount === "number" ? item.comments.totalCount : (item.comments || 0);
            const ciStatus = _ciStatus(item);
            return {
                number: item.number,
                title: "#" + item.number + " " + (item.title || I18n.tr("Untitled PR")),
                body: item.body || "",
                repo: _repoName(item),
                detail: _commentLabel(comments) + " • updated " + _relativeTime(item.updatedAt || item.updated_at),
                comments: comments,
                draft: item.isDraft === true || item.draft === true,
                url: item.url || item.html_url || "",
                ciStatus: ciStatus,
                ciLabel: _ciLabel(ciStatus)
            };
        });
    }
}
