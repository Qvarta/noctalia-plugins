import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 340 * Style.uiScaleRatio
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
        readonly property bool isHovered: mouseArea.containsMouse
        
        width: parent.width
        height: 52
        
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
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: Style.marginL
                
                NIcon {
                    id: buttonIcon
                    icon: buttonRoot.iconName
                    pointSize: 20
                    
                    color: (mouseArea.containsMouse || isSelected) ? 
                        Color.mOnHover : Color.mPrimary
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    Layout.alignment: Qt.AlignVCenter
                }
                
                NText {
                    text: buttonRoot.text
                    font.pointSize: Style.fontSizeXL
                    font.weight: Font.Medium
                    
                    color: (mouseArea.containsMouse || isSelected) ? 
                        Color.mOnHover : Color.mPrimary
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                
                onContainsMouseChanged: {
                    if (containsMouse) {
                        currentIndex = buttonIndex;
                    }
                }
                
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
        anchors.margins: Style.marginS
        color: Color.mSurface
        radius: Style.radiusM
        border.width: Style.borderS
        border.color: Color.mOutline
        clip: true
        
        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginL

            Column {
                id: buttonsColumn
                width: parent.width
                spacing: 4
                
                y: Math.max(0, (parent.height - height) / 2)
                
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