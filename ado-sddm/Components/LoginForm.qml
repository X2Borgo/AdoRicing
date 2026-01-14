//
// This file is part of SDDM Sugar Candy.
// A theme for the Simple Display Desktop Manager.
//
// Copyright (C) 2018–2020 Marian Arlt
//
// SDDM Sugar Candy is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or any later version.
//
// You are required to preserve this and any additional legal notices, either
// contained in this file or in other files that you received along with
// SDDM Sugar Candy that refer to the author(s) in accordance with
// sections §4, §5 and specifically §7b of the GNU General Public License.
//
// SDDM Sugar Candy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SDDM Sugar Candy. If not, see <https://www.gnu.org/licenses/>
//

import QtQuick 2.11
import QtQuick.Layouts 1.11
import SddmComponents 2.0 as SDDM
import Qt5Compat.GraphicalEffects 
import QtQuick.Controls 2.4

ColumnLayout {
    id: formContainer
    SDDM.TextConstants { id: textConstants }

    // --- Configuration ---
    spacing: 8  // Reduced space between the 3 lines for tighter layout
    width: 520   // Wider for more horizontal space

    property int p: config.ScreenPadding
    property string a: config.FormPosition
    property alias systemButtonVisibility: systemButtons.visible
    property alias clockVisibility: clock.visible
    property bool virtualKeyboardActive
    
    // Selected user state
    property string selectedUsername: ""
    property int selectedUserIndex: -1

    // Animation properties for entrance effect
    property real animationOpacity: 0

    Component.onCompleted: {
        // 1. Staggered entrance animations
        line1Animation.start()
        line2Animation.start()
        line3Animation.start()

        // 2. Auto-select the first user if none is selected
        // We access the internal list of the userPicker
        if (userPicker.userList && userPicker.userList.currentIndex === -1 && userModel.count > 0) {
            userPicker.userList.currentIndex = 0;
            input.focusPasswordField();
        }
    }

    // --- LINE 1: Clock & User Picker ---
    RowLayout {
        id: line1
        opacity: 0
        transform: Translate { id: line1Translate; y: 30 }
        
        ParallelAnimation {
            id: line1Animation
            NumberAnimation {
                target: line1
                property: "opacity"
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: line1Translate
                property: "y"
                from: 30
                to: 0
                duration: 600
                easing.type: Easing.OutCubic
            }
        }
        Layout.alignment: Qt.AlignHCenter
        spacing: 15

        // The Clock (Date/Time)
        Clock {
            id: clock
            Layout.alignment: Qt.AlignVCenter
        }
        
        // User Profile Picture Picker
        UserPicker {
            id: userPicker
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 100
            Layout.preferredHeight: 100
            
            onUserSelected: function(username, index) {
                formContainer.selectedUsername = username
                formContainer.selectedUserIndex = index
                input.setSelectedUser(username)
                // Focus password field after selection
                input.focusPasswordField()
            }
        }
    }

    // --- LINE 2: Password Input ---
    Input {
        id: input
        Layout.fillWidth: true
        Layout.preferredHeight: 50  // Increased height for larger appearance
        Layout.alignment: Qt.AlignRight
        
        opacity: 0
        transform: Translate { id: line2Translate; y: 30 }
        
        ParallelAnimation {
            id: line2Animation
            NumberAnimation {
                target: input
                property: "opacity"
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: line2Translate
                property: "y"
                from: 30
                to: 0
                duration: 600
                easing.type: Easing.OutCubic
            }
            // Delay to create staggered effect
            PauseAnimation { duration: 200 }
        }
    }

    // --- LINE 3: System Buttons (Power/Reboot) ---
    SystemButtons {
        id: systemButtons
        Layout.alignment: Qt.AlignRight
        Layout.preferredHeight: 30  // Very compact buttons
        exposedSession: input.exposeSession
        
        opacity: 0
        
        NumberAnimation {
            id: line3Animation
            target: systemButtons
            property: "opacity"
            from: 0
            to: 1
            duration: 600
            easing.type: Easing.OutCubic
        }
        
        // Delay to create staggered effect (longest delay for bottom element)
        Timer {
            interval: 400
            running: true
            onTriggered: line3Animation.start()
        }
    }
}
