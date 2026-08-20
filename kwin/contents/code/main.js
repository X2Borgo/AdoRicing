// KWin Script for Plasma 6 - Dim inactive windows on secondary monitors
// Version: 1.1.0
// Author: AdoRicing

const TRANSPARENCY_LEVEL = 0.85;
const SCRIPT_NAME = "AdoTransparency";
const TOGGLE_SHORTCUT_NAME = "AdoMonitorTransparencyToggle";
const TOGGLE_SHORTCUT_TEXT = "Toggle Ado Monitor Transparency";
const TOGGLE_SHORTCUT_DEFAULT = "Meta+Ctrl+Alt+T";

let scriptEnabled = true;

// Logging helper
function log(message) {
    console.log(`[${SCRIPT_NAME}] ${message}`);
}

function logError(message, error) {
    console.error(`[${SCRIPT_NAME}] ERROR: ${message}`, error);
}

// Get screen index for a client (0 = primary, 1+ = secondary)
function getScreenIndex(client) {
    try {
        if (!client || !client.output) {
            return -1;
        }
        
        const output = client.output;
        const screens = workspace.screens;
        
        for (let i = 0; i < screens.length; i++) {
            if (screens[i] === output) {
                return i;
            }
        }
        
        return -1;
    } catch (e) {
        logError("Failed to get screen index", e);
        return -1;
    }
}

// Check if window should be affected by transparency
function shouldAffectWindow(client) {
    if (!client) {
        return false;
    }
    
    // Only affect normal windows
    if (!client.normalWindow) {
        return false;
    }
    
    // Skip special window types
    if (client.desktopWindow || client.dock || client.splash || 
        client.toolbar || client.menu || client.dialog || 
        client.utility || client.notification) {
        return false;
    }
    
    return true;
}

// Update opacity for a single client
function updateClientOpacity(client) {
    if (!shouldAffectWindow(client)) {
        return;
    }
    
    try {
        if (!scriptEnabled) {
            if (client.opacity !== 1.0) {
                client.opacity = 1.0;
            }
            return;
        }

        const screenIndex = getScreenIndex(client);
        const isActive = (client === workspace.activeWindow);
        
        let newOpacity;
        
        if (screenIndex === 0) {
            // Primary monitor - always opaque
            newOpacity = 1.0;
        } else if (screenIndex > 0) {
            // Secondary monitor - transparent if inactive
            newOpacity = isActive ? 1.0 : TRANSPARENCY_LEVEL;
        } else {
            // Unknown screen - keep opaque
            newOpacity = 1.0;
        }
        
        // Only update if changed to reduce overhead
        if (client.opacity !== newOpacity) {
            client.opacity = newOpacity;
        }
    } catch (e) {
        logError(`Failed to update opacity for window: ${client.caption}`, e);
    }
}

function toggleScript() {
    scriptEnabled = !scriptEnabled;
    log(`Script ${scriptEnabled ? "enabled" : "disabled"} via shortcut`);
    updateAllWindows();
}

// Update all windows
function updateAllWindows() {
    try {
        const clients = workspace.stackingOrder;
        if (!clients || clients.length === 0) {
            return;
        }
        
        for (let i = 0; i < clients.length; i++) {
            updateClientOpacity(clients[i]);
        }
    } catch (e) {
        logError("Failed to update all windows", e);
    }
}

// Setup event handlers for a client
function setupClientHandlers(client) {
    if (!client || !shouldAffectWindow(client)) {
        return;
    }
    
    try {
        // Update when window moves to different screen
        if (client.outputChanged) {
            client.outputChanged.connect(function() {
                updateClientOpacity(client);
            });
        }
        
        // Update when window geometry changes (might affect screen)
        if (client.frameGeometryChanged) {
            client.frameGeometryChanged.connect(function() {
                updateClientOpacity(client);
            });
        }
        
        // Update when window type changes
        if (client.windowTypeChanged) {
            client.windowTypeChanged.connect(function() {
                updateClientOpacity(client);
            });
        }
    } catch (e) {
        logError(`Failed to setup handlers for window: ${client.caption}`, e);
    }
}

// Initialize script
function initialize() {
    log("Initializing script...");
    log(`Transparency level: ${TRANSPARENCY_LEVEL * 100}%`);
    log(`Number of screens: ${workspace.screens.length}`);
    log(`Default shortcut: ${TOGGLE_SHORTCUT_DEFAULT}`);
    
    // Setup handlers for existing windows
    try {
        const existingClients = workspace.stackingOrder;
        if (existingClients && existingClients.length > 0) {
            log(`Setting up handlers for ${existingClients.length} existing windows`);
            for (let i = 0; i < existingClients.length; i++) {
                setupClientHandlers(existingClients[i]);
            }
        }
    } catch (e) {
        logError("Failed to setup existing clients", e);
    }
    
    // Connect workspace signals
    try {
        registerShortcut(
            TOGGLE_SHORTCUT_NAME,
            TOGGLE_SHORTCUT_TEXT,
            TOGGLE_SHORTCUT_DEFAULT,
            toggleScript
        );

        workspace.windowActivated.connect(function() {
            updateAllWindows();
        });
        
        workspace.windowAdded.connect(function(client) {
            setupClientHandlers(client);
            updateAllWindows();
        });
        
        workspace.windowRemoved.connect(function() {
            updateAllWindows();
        });
        
        // Screen configuration changes (monitor connected/disconnected)
        workspace.screensChanged.connect(function() {
            log("Screen configuration changed, updating all windows");
            updateAllWindows();
        });
        
        log("Workspace signals connected successfully");
    } catch (e) {
        logError("Failed to connect workspace signals", e);
    }
    
    // Initial update
    updateAllWindows();
    log("Initialization complete");
}

// Start the script
initialize();
