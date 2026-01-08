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
                
                Rectangle {
                    width: buttonsColumn.width
                    height: 64
                    radius: Style.radiusS
                    color: mouseArea1.containsPress ? Color.mSurfaceVariant : 
                          mouseArea1.containsMouse ? Qt.darker(Color.mSurface, 1.05) : 
                          Color.mSurface
                    border.width: Style.borderS
                    border.color: mouseArea1.containsMouse ? Color.mOutline : Color.mSurface
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM
                        
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "screenshot"
                            color: Color.mPrimary
                            pointSize: 20  
                            applyUiScale: true
                        }
                        
                        NText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: pluginApi?.tr("windowLabel")
                            color: Color.mOnSurface
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                        }
                        
                        
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "chevron-right"
                            color: Color.mOnSurfaceVariant
                            pointSize: 16 
                            applyUiScale: true
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            if (pluginApi && pluginApi.mainInstance) {
                                pluginApi.mainInstance.takeScreenshot("output");
                            }
                        }
                    }
                }
                
                Rectangle {
                    width: buttonsColumn.width
                    height: 64
                    radius: Style.radiusS
                    color: mouseArea2.containsPress ? Color.mSurfaceVariant : 
                          mouseArea2.containsMouse ? Qt.darker(Color.mSurface, 1.05) : 
                          Color.mSurface
                    border.width: Style.borderS
                    border.color: mouseArea2.containsMouse ? Color.mOutline : Color.mSurface
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM
                        
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "crop"
                            color: Color.mPrimary
                            pointSize: 20  
                            applyUiScale: true
                        }
                        
                        NText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: pluginApi?.tr("areaLabel")
                            color: Color.mOnSurface
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                        }
                        
                        
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "chevron-right"
                            color: Color.mOnSurfaceVariant
                            pointSize: 16  
                            applyUiScale: true
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            if (pluginApi && pluginApi.mainInstance) {
                                pluginApi.mainInstance.takeScreenshot("region");
                            }
                        }
                    }
                }
                
                Rectangle {
                    width: buttonsColumn.width
                    height: 64
                    radius: Style.radiusS
                    color: mouseArea3.containsPress ? Color.mSurfaceVariant : 
                          mouseArea3.containsMouse ? Qt.darker(Color.mSurface, 1.05) : 
                          Color.mSurface
                    border.width: Style.borderS
                    border.color: mouseArea3.containsMouse ? Color.mOutline : Color.mSurface
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM
                        
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "zoom-in-area"
                            color: Color.mPrimary
                            pointSize: 20  
                            applyUiScale: true
                        }
                        
                        NText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: pluginApi?.tr("activeWindowLabel")
                            color: Color.mOnSurface
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                        }
                        
                        
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "chevron-right"
                            color: Color.mOnSurfaceVariant
                            pointSize: 16  
                            applyUiScale: true
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea3
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            if (pluginApi && pluginApi.mainInstance) {
                                pluginApi.mainInstance.takeScreenshot("window");
                            }
                        }
                    }
                }
            }
        }
    }
}