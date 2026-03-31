import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    property real contentPreferredWidth: 360 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    
    readonly property int buttonCount: buttonModel.length
    readonly property real buttonHeight: 52 * Style.uiScaleRatio
    readonly property real buttonSpacing: 4 * Style.uiScaleRatio
    readonly property real verticalMargins: Style.marginM * Style.uiScaleRatio * 2
    
    property real contentPreferredHeight: (buttonCount * buttonHeight) + 
                                          ((buttonCount - 1) * buttonSpacing) + 
                                          2*verticalMargins
    
    width: contentPreferredWidth
    height: contentPreferredHeight
    
    readonly property var geometryPlaceholder: panelContainer
    
    readonly property var buttonModel: [
        {id: "app-launcher", displayName: "Приложения", icon: "apps"},
        {id: "online-radio", displayName: "Интернет-радио", icon: "radio"},
        {id: "screenshot-plugin", displayName: "Скриншот", icon: "camera"},
        {id: "notes-scratchpad", displayName: "Заметки", icon: "notes"},
        {id: "torrent-plugin", displayName: "Торренты", icon: "download"},
        {id: "hyprland-cheatsheet", displayName: "Горячие клавиши", icon: "keyboard"}
    ]
    
    property int currentIndex: 0
    
    function openPlugin(index) {
        if (index >= 0 && index < buttonCount) {
            var main = pluginApi.mainInstance;
            if (main && main.openPluginPanel) {
                main.openPluginPanel(buttonModel[index].id);
            } else {
                Logger.e("Failed to call openPluginPanel function");
            }
        }
    }
    
    function moveSelection(delta) {
        var newIndex = currentIndex + delta;
        if (newIndex >= 0 && newIndex < buttonCount) {
            currentIndex = newIndex;
            
            // Ensure the selected item is visible in the flickable
            var targetY = currentIndex * (buttonHeight + buttonSpacing);
            var viewportHeight = flickable.height;
            
            if (targetY < flickable.contentY) {
                flickable.contentY = targetY;
            } else if (targetY + buttonHeight > flickable.contentY + viewportHeight) {
                flickable.contentY = targetY + buttonHeight - viewportHeight;
            }
        }
    }
    
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: openPlugin(currentIndex)
    Keys.onEnterPressed: openPlugin(currentIndex)
    
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        anchors.margins: Style.marginS
        color: Color.mSurface
        radius: Style.radiusM
        border.width: Style.borderS
        border.color: Color.mOutline
        clip: true
        
        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.margins: Style.marginM
            contentWidth: width
            contentHeight: buttonsColumn.height
            boundsBehavior: Flickable.StopAtBounds
            
            Column {
                id: buttonsColumn
                width: parent.width
                spacing: buttonSpacing
                
                y: Math.max(0, (flickable.height - height) / 2)
                
                Repeater {
                    model: buttonModel
                    
                    Rectangle {
                        id: buttonContainer
                        width: buttonsColumn.width
                        height: buttonHeight
                        radius: 8
                        color: "transparent"
                        
                        readonly property bool isSelected: index === currentIndex
                        readonly property bool isHovered: mouseArea.containsMouse
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                        
                        Rectangle {
                            id: buttonRect
                            anchors.fill: parent
                            radius: 8
                            
                            color: (mouseArea.containsMouse || isSelected) ? 
                                   Color.mHover : Color.mSurfaceVariant
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                
                                onContainsMouseChanged: {
                                    if (containsMouse) {
                                        currentIndex = index;
                                    }
                                }
                                
                                onClicked: {
                                    currentIndex = index;
                                    root.openPlugin(index);
                                }
                            }
                            
                            Row {
                                id: buttonRow
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: Style.marginL
                                
                                NIcon {
                                    id: buttonIcon
                                    icon: modelData.icon
                                    pointSize: 20
                                    
                                    color: (mouseArea.containsMouse || isSelected) ? 
                                           Color.mOnHover : Color.mPrimary
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                    
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                NText {
                                    id: buttonText
                                    text: modelData.displayName
                                    font.pointSize: Style.fontSizeXL
                                    font.weight: Font.Medium
                                    
                                    color: (mouseArea.containsMouse || isSelected) ? 
                                           Color.mOnHover : Color.mPrimary
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                    
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - buttonIcon.width - 32 - (Style.marginL * 2)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        forceActiveFocus();
    }
}