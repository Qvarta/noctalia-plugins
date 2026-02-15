import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 260 * Style.uiScaleRatio
    property real contentPreferredHeight: 400 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    readonly property bool isPlaying: pluginApi && pluginApi.mainInstance && 
                                     pluginApi.mainInstance.currentPlayingProcessState === "start"

    function isStationPlaying(stationName) {
        return isPlaying && 
               pluginApi.mainInstance.currentPlayingStation === stationName
    }

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusM
        
        ColumnLayout {
            anchors {
                centerIn: parent
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginM

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                border.width: Style.borderS
                border.color: Color.mOutline

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    model: pluginApi && pluginApi.mainInstance ? 
                           pluginApi.mainInstance.getStations() : []
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    
                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        policy: ScrollBar.AsNeeded
                        visible: false 
                    }

                    delegate: Rectangle {
                        property string stationName: modelData.name
                        property string stationUrl: modelData.url
                        property int stationIndex: index + 1
                        readonly property bool isPlaying: root.isStationPlaying(stationName)

                        id: stationButton
                        width: listView.width
                        height: 48
                        color: {
                            if (isStationPlaying(stationName)) {
                                return Color.mSurface;
                            } else if (mouseArea.containsPress) {
                                return Qt.darker(Color.mSurface, 1.1);
                            } else if (mouseArea.containsMouse) {
                                return Color.mHover;
                            } else {
                                return Color.mSurface;
                            }
                        }
                        radius: 8
                        border.width: Style.borderL
                        border.color: isPlaying ? Color.mOutline : Color.mSurface


                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginM

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 20
                                color: stationButton.isPlaying ? Color.mOnSurfaceVariant : Color.mSurface
                                border.width: Style.borderS
                                border.color: stationButton.isPlaying ? Color.mOnSurfaceVariant : Color.mOutline
                                
                                // Иконка 
                                Loader {
                                    anchors.centerIn: parent
                                    sourceComponent: stationButton.isPlaying ? playingIcon : numberIcon
                                }
                                
                                Component {
                                    id: playingIcon
                                    NIcon {
                                        icon: "player-play"
                                        color: Color.mOnPrimary
                                        pointSize: 18
                                    }
                                }
                                
                                Component {
                                    id: numberIcon
                                    NIcon {
                                        icon: "number-" + stationIndex + "-small"
                                        color: Color.mHover
                                        pointSize: 22
                                    }
                                }
                                
                                // Индикатор воспроизведения
                                // Rectangle {
                                //     visible: isStationPlaying(modelData.name)
                                //     width: 10
                                //     height: 10
                                //     radius: 5
                                //     anchors.right: parent.right
                                //     anchors.bottom: parent.bottom
                                //     color: Color.mError
                                //     border.width: 2
                                //     border.color: Color.mSurface
                                // }

                            }

                            NText {
                                text: modelData.name
                                color: {
                                    if (stationButton.isPlaying) {
                                        return Color.mOnSurface;
                                    } else if (mouseArea.containsMouse) {
                                        return Color.mOnHover;
                                    } else {
                                        return Color.mOnSurface;
                                    }
                                }
                                font.pointSize: stationButton.isPlaying ? Style.fontSizeM : Style.fontSizeS
                                elide: Text.ElideRight
                                font.weight: stationButton.isPlaying ? Font.Bold : Font.Normal
                                Layout.fillWidth: true
                            }

                            NIcon {
                                visible: mouseArea.containsMouse || stationButton.isPlaying 
                                icon: stationButton.isPlaying ? "power" : ""
                                verticalAlignment: Image.AlignVCenter
                                color: Color.mError
                                pointSize: 16
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (pluginApi && pluginApi.mainInstance) {
                                    var main = pluginApi.mainInstance;
                                    
                                    if (stationButton.isPlaying) {
                                        main.stopPlayback();
                                    } else {
                                        main.playStation(stationName, stationUrl);
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        height: 120
                        visible: listView.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.marginM
                            
                            NIcon {
                                icon: "radio"
                                color: Color.mOnSurfaceVariant
                                opacity: 0.5
                                Layout.alignment: Qt.AlignHCenter
                                pointSize: 16
                            }
                            
                            NText {
                                text: pluginApi?.tr("NotLoaded")
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeM
                                font.weight: Font.Medium
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            NText {
                                text: pluginApi?.tr("addStations")
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeS
                                opacity: 0.7
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: currentPlayingContainer
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 60 : 0
                color: Color.mSurfaceVariant
                radius: 8
                border.width: Style.borderS
                border.color: Color.mOutline
                
                visible: isPlaying && pluginApi.mainInstance.currentPlayingStation !== ""

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Color.mPrimary
                        
                        NIcon {
                            anchors.centerIn: parent
                            icon: "volume"
                            color: Color.mOnPrimary
                            pointSize: 16
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        
                        NText {
                            text: pluginApi?.tr("nowPlay")
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeXS
                            font.weight: Font.Medium
                            opacity: 0.8
                        }
                        
                        NText {
                            text: pluginApi && pluginApi.mainInstance ? 
                                  pluginApi.mainInstance.currentPlayingStation || "" : ""
                            color: Color.mOnSurface
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    
                    Rectangle {
                        width: 36
                        height: 36
                        color: "transparent"

                        NIcon {
                            anchors.centerIn: parent
                            icon: "power"
                            color: stopButton.containsMouse ? Qt.darker(Color.mError, 1.6) : Color.mError
                            pointSize: 16
                        }

                        MouseArea {
                            id: stopButton
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (pluginApi && pluginApi.mainInstance) {
                                    pluginApi.mainInstance.stopPlayback();
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginL
                
                Item {
                    Layout.fillWidth: true
                }
                
                NText {
                    text: pluginApi && pluginApi.mainInstance ? 
                         pluginApi?.tr("available") + pluginApi.mainInstance.getStations().length : ""
                    color: Color.mOnSurfaceVariant
                    font.pointSize: Style.fontSizeM
                    opacity: 0.8
                }
                
                Item {
                    Layout.fillWidth: true
                }
            }


        }
    }
}