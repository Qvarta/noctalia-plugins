import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 250 * Style.uiScaleRatio
    property real contentPreferredHeight: 340 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    component ActionButton: Rectangle {
        id: buttonRoot
        property string iconName: ""
        property string text: ""
        property string actionType: ""
        property var mouseArea: mouseArea
        
        width: parent.width
        height: 64
        radius: Style.radiusS
        color: mouseArea.containsPress ? Color.mSurfaceVariant : 
               mouseArea.containsMouse ? Qt.darker(Color.mSurface, 1.05) : 
               Color.mSurface
        border.width: Style.borderS
        border.color: mouseArea.containsMouse ? Color.mOutline : Color.mSurface
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM
            
            NIcon {
                Layout.alignment: Qt.AlignVCenter
                icon: buttonRoot.iconName
                color: Color.mPrimary
                pointSize: 20  
                applyUiScale: true
            }
            
            NText {
                Layout.alignment: Qt.AlignVCenter
                text: buttonRoot.text
                color: Color.mOnSurface
                font.pointSize: Style.fontSizeM
                font.weight: Font.Medium
            }
            
            Item {
                Layout.fillWidth: true
            }
            
            NIcon {
                Layout.alignment: Qt.AlignVCenter
                icon: "chevron-right"
                color: Color.mOnSurfaceVariant
                pointSize: 16  
                applyUiScale: true
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                if (pluginApi && pluginApi.mainInstance && buttonRoot.actionType) {
                    pluginApi.mainInstance.takeScreenshot(buttonRoot.actionType);
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
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Color.mSurfaceVariant
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: "screenshot"
                        color: Color.mPrimary
                        pointSize: 24  
                        applyUiScale: true
                    }
                }
                
                ColumnLayout {
                    spacing: Style.marginXS
                    Layout.fillWidth: true
                    
                    NText {
                        text: pluginApi?.tr("titleLabel")
                        color: Color.mOnSurface
                        font.pointSize: Style.fontSizeL
                        font.weight: Font.Bold
                    }
                    
                    NText {
                        text: pluginApi?.tr("titleSubLabel")
                        color: Color.mOnSurfaceVariant
                        font.pointSize: Style.fontSizeS
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            Column {
                id: buttonsColumn
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                spacing: Style.marginM
                
                ActionButton {
                    iconName: "screenshot"
                    text: pluginApi?.tr("windowLabel")
                    actionType: "output"
                }
                
                ActionButton {
                    iconName: "crop"
                    text: pluginApi?.tr("areaLabel")
                    actionType: "region"
                }
                
                ActionButton {
                    iconName: "zoom-in-area"
                    text: pluginApi?.tr("activeWindowLabel")
                    actionType: "window"
                }
            }
        }
    }
}