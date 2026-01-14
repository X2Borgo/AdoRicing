//
// User Picker Component - Profile Picture Selection
// Displays user avatars for selection before password entry
//

import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import Qt5Compat.GraphicalEffects

Item {
    id: userPicker
    
    implicitHeight: 120
    implicitWidth: parent.width
    
    property int selectedUserIndex: userModel.lastIndex
    property string selectedUserName: userModel.data(userModel.index(selectedUserIndex, 0), 257) // 257 is NameRole
    
    signal userSelected(string username, int index)
    
    // Grid layout for user avatars
    Row {
        id: userRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20
        
        Repeater {
            model: userModel
            
            delegate: Item {
                id: userDelegate
                width: 80
                height: 80
                
                property bool isSelected: userPicker.selectedUserIndex === index
                
                // Avatar container with hover and selection effects
                Rectangle {
                    id: avatarContainer
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "transparent"
                    border.width: isSelected ? 3 : (avatarMouseArea.containsMouse ? 2 : 0)
                    border.color: config.AccentColor
                    
                    // Glow effect when selected
                    layer.enabled: isSelected
                    layer.effect: Glow {
                        samples: 15
                        spread: 0.5
                        color: config.AccentColor
                        transparentBorder: true
                    }
                    
                    // Profile picture
                    Image {
                        id: userAvatar
                        anchors.fill: parent
                        anchors.margins: 4
                        source: model.icon || "../Assets/User.svgz"
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        
                        // Circular mask
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: userAvatar.width
                                height: userAvatar.height
                                radius: width / 2
                            }
                        }
                    }
                    
                    // Fallback icon if no picture
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: width / 2
                        visible: userAvatar.status !== Image.Ready
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: config.AccentColor }
                            GradientStop { position: 1.0; color: Qt.darker(config.AccentColor, 1.5) }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.name ? model.name.charAt(0).toUpperCase() : "?"
                            font.pointSize: root.font.pointSize * 2
                            font.bold: true
                            color: "white"
                        }
                    }
                    
                    // Hover overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: config.AccentColor
                        opacity: avatarMouseArea.containsMouse && !isSelected ? 0.2 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }
                
                // Username label below avatar
                Text {
                    anchors.top: avatarContainer.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: model.name
                    font.pointSize: root.font.pointSize * 0.8
                    font.capitalization: Font.Capitalize
                    color: isSelected ? config.AccentColor : root.palette.text
                    font.bold: isSelected
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                // Mouse area for selection
                MouseArea {
                    id: avatarMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        userPicker.selectedUserIndex = index
                        userPicker.selectedUserName = model.name
                        userPicker.userSelected(model.name, index)
                    }
                }
                
                // Scale animation on hover
                scale: avatarMouseArea.containsMouse ? 1.1 : 1.0
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
    
    // Entrance animation
    opacity: 0
    Component.onCompleted: {
        fadeIn.start()
    }
    
    NumberAnimation {
        id: fadeIn
        target: userPicker
        property: "opacity"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.OutCubic
    }
}
