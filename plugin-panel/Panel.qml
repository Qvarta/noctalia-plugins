import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    property real contentPreferredWidth: 260 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    
    readonly property int buttonCount: buttonModel.length
    readonly property real buttonHeight: 52 * Style.uiScaleRatio
    readonly property real buttonSpacing: 4 * Style.uiScaleRatio
    readonly property real verticalMargins: Style.marginM * Style.uiScaleRatio * 2
    
    property real contentPreferredHeight: (buttonCount * buttonHeight) + 
                                          ((buttonCount - 1) * buttonSpacing) + 
                                          verticalMargins
    
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
        color: Color.mSurface
        radius: Style.radiusM
        
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
                    spacing: 4
                    
                    Repeater {
                        model: buttonModel
                        
                        Item {
                            id: buttonContainer
                            width: buttonsColumn.width
                            height: 52
                            
                            readonly property bool isSelected: index === currentIndex
                            
                            Rectangle {
                                id: buttonRect
                                anchors.fill: parent
                                radius: 6
                                border.width: Style.borderS
                                border.color: Color.mOutline
                                color: (mouseArea.containsMouse || isSelected) ? 
                                       Color.mHover : Color.mSurfaceVariant
                                
                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    
                                    onClicked: {
                                        currentIndex = index;
                                        root.openPlugin(index);
                                    }
                                }
                                
                                Row {
                                    id: buttonRow
                                    anchors.fill: parent
                                    anchors.margins: Style.marginM
                                    spacing: Style.marginM
                                    
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 8
                                        color: Color.mOutline
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        NIcon {
                                            anchors.centerIn: parent
                                            icon: modelData.icon
                                            color: Color.mPrimary
                                            pointSize: 24
                                        }
                                    }
                                    
                                    NText {
                                        text: modelData.displayName
                                        font.pointSize: Style.fontSizeS
                                        font.weight: (mouseArea.containsMouse || isSelected) ? 
                                                    Font.Bold : Font.Normal
                                        color: (mouseArea.containsMouse || isSelected) ? 
                                               Color.mOnSecondary : Color.mOnSurface
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 40 - 32 - (Style.marginM * 2)
                                    }
                                    
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        NIcon {
                                            anchors.centerIn: parent
                                            icon: "chevron-right"
                                            color: Color.mSurfaceVariant
                                            pointSize: 16
                                        }
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