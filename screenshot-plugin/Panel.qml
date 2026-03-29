import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 250 * Style.uiScaleRatio
    property real contentPreferredHeight: 200 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent
    
    property int currentIndex: 0
    property var actionButtons: ["output", "region", "window"]
    
    function takeScreenshotByType(actionType) {
        if (pluginApi && pluginApi.mainInstance && actionType) {
            pluginApi.mainInstance.takeScreenshot(actionType);
        }
    }
    
    function moveSelection(delta) {
        var newIndex = currentIndex + delta;
        if (newIndex >= 0 && newIndex < actionButtons.length) {
            currentIndex = newIndex;
            
            var targetY = currentIndex * (52 + 4); 
            var viewportHeight = buttonsColumn.height;
            
            if (targetY < 0) {
            } else if (targetY + 52 > viewportHeight) {
            }
        }
    }
    
    function activateCurrentButton() {
        if (currentIndex >= 0 && currentIndex < actionButtons.length) {
            takeScreenshotByType(actionButtons[currentIndex]);
        }
    }
    
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: activateCurrentButton()
    Keys.onEnterPressed: activateCurrentButton()
    
    component ActionButton: Item {
        id: buttonRoot
        property string iconName: ""
        property string text: ""
        property string actionType: ""
        property int buttonIndex: -1
        property var mouseArea: mouseArea
        readonly property bool isSelected: buttonIndex === currentIndex
        
        width: parent.width
        height: 52
        
        Rectangle {
            id: buttonRect
            anchors.fill: parent
            radius: 6       
            border.width: Style.borderS
            border.color: Color.mOutline
            color: {
                if (mouseArea.containsMouse || isSelected) {
                    return Color.mHover;
                } else {
                    return Color.mSurfaceVariant;
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM
                
                Rectangle {
                    width: 40
                    height: 40
                    radius: 8
                    color: Color.mOutline
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: buttonRoot.iconName
                        color: Color.mPrimary
                        pointSize: 24
                    }
                }
                
                NText {
                    text: buttonRoot.text
                    color: {
                        if (mouseArea.containsMouse || isSelected) {
                            return Color.mOnSecondary;
                        } else {
                            return Color.mOnSurface;
                        }
                    }
                    font.pointSize: Style.fontSizeS
                    font.weight: {
                        if (mouseArea.containsMouse || isSelected) {
                            return Font.Bold;
                        } else {
                            return Font.Normal;
                        }
                    }
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "transparent"
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: "chevron-right"
                        color: Color.mSurfaceVariant
                        pointSize: 16
                    }
                }
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                
                onClicked: {
                    currentIndex = buttonIndex;
                    takeScreenshotByType(buttonRoot.actionType);
                }
            }
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusM
        
        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginL

                Column {
                    id: buttonsColumn
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: 10
                    
                    ActionButton {
                        iconName: "screenshot"
                        text: pluginApi?.tr("windowLabel") || "Весь экран"
                        actionType: "output"
                        buttonIndex: 0
                    }
                    
                    ActionButton {
                        iconName: "crop"
                        text: pluginApi?.tr("areaLabel") || "Область"
                        actionType: "region"
                        buttonIndex: 1
                    }
                    
                    ActionButton {
                        iconName: "zoom-in-area"
                        text: pluginApi?.tr("activeWindowLabel") || "Активное окно"
                        actionType: "window"
                        buttonIndex: 2
                    }
                }
        }
    }
    
    Component.onCompleted: {
        forceActiveFocus();
    }
}