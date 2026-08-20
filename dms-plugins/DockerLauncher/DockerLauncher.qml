import QtQuick
import Quickshell

Item {
    id: root

    property var pluginService: null
    property string trigger: ""

    signal itemsChanged()

    readonly property var baseItems: [
        {
            name: "Docker Menu",
            icon: "material:deployed_code",
            comment: "Open the full Docker management menu",
            action: "script:~/.config/hypr/scripts/DockerMenu.sh",
            keywords: ["docker", "containers", "menu", "compose"],
            categories: ["Docker"]
        },
        {
            name: "Docker Running Containers",
            icon: "material:list_alt",
            comment: "Show running containers in a terminal",
            action: "script:~/.config/hypr/scripts/DockerMenu.sh --ps",
            keywords: ["docker", "ps", "running", "containers"],
            categories: ["Docker"]
        },
        {
            name: "Docker All Containers",
            icon: "material:inventory_2",
            comment: "Show all containers in a terminal",
            action: "script:~/.config/hypr/scripts/DockerMenu.sh --ps-all",
            keywords: ["docker", "ps", "all", "containers"],
            categories: ["Docker"]
        },
        {
            name: "Docker Images",
            icon: "material:package_2",
            comment: "Show Docker images in a terminal",
            action: "script:~/.config/hypr/scripts/DockerMenu.sh --images",
            keywords: ["docker", "images", "containers"],
            categories: ["Docker"]
        },
        {
            name: "Docker Compose Projects",
            icon: "material:view_list",
            comment: "Show docker compose projects in a terminal",
            action: "script:~/.config/hypr/scripts/DockerMenu.sh --compose-ps",
            keywords: ["docker", "compose", "projects", "ps"],
            categories: ["Docker"]
        }
    ]

    function getItems(query) {
        if (!query || query.length === 0)
            return baseItems;

        const lowerQuery = query.toLowerCase();
        return baseItems.filter(item => {
            const haystacks = [
                item.name || "",
                item.comment || "",
                ...(item.keywords || [])
            ];
            return haystacks.some(part => part.toLowerCase().includes(lowerQuery));
        });
    }

    function executeItem(item) {
        if (!item || !item.action)
            return;

        const separator = item.action.indexOf(":");
        const actionType = separator === -1 ? item.action : item.action.slice(0, separator);
        const actionData = separator === -1 ? "" : item.action.slice(separator + 1);

        if (actionType === "script" && actionData) {
            Quickshell.execDetached(["sh", "-lc", actionData]);
        }
    }
}
