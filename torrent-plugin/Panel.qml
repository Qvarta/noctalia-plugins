import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 450 * Style.uiScaleRatio
    property real contentPreferredHeight: 600 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    
    property ListModel torrentModel: pluginApi?.mainInstance?.torrentModel || null
    property bool isLoading: pluginApi?.mainInstance?.isLoading || false
    property string errorMessage: pluginApi?.mainInstance?.errorMessage || ""
    property bool daemonRunning: pluginApi?.mainInstance?.daemonRunning || false
    
    anchors.fill: parent
    
    component TorrentItem: Rectangle {
        id: torrentRoot
        property int torrentId: 0
        property string torrentName: ""
        property int torrentPercent: 0
        property string torrentStatus: ""
        
        width: parent.width
        height: 70
        radius: Style.radiusS
        color: Color.mSurface
        border.width: Style.borderS
        border.color: Color.mOutline
        
        Rectangle {
            width: 4
            height: parent.height
            radius: 2
            color: {
                switch(torrentRoot.torrentStatus) {
                    case "downloading": return Color.mPrimary;
                    case "seeding": return Color.mSecondary;
                    case "completed": return Color.mTertiary;
                    case "stopped": return Color.mError;
                    default: return Color.mOutline;
                }
            }
        }
        
        ColumnLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 12
                topMargin: 8
                bottomMargin: 8
            }
            spacing: 4
            
            NText {
                Layout.fillWidth: true
                text: torrentRoot.torrentName
                color: Color.mOnSurface
                font.pointSize: Style.fontSizeS
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                NText {
                    text: torrentRoot.torrentPercent + "%"
                    color: Color.mOnSurfaceVariant
                    font.pointSize: Style.fontSizeXS
                    font.weight: Font.Bold
                    Layout.preferredWidth: 40
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Color.mSurfaceVariant
                    
                    Rectangle {
                        id: progressBar
                        width: parent.width * (torrentRoot.torrentPercent / 100)
                        height: parent.height
                        radius: 3
                        color: parent.parent.parent.children[0].color
                        
                        Behavior on width {
                            NumberAnimation {
                                duration: 800
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
                
                NIcon {
                    icon: {
                        if (torrentRoot.torrentStatus === "downloading") return "player-play";
                        if (torrentRoot.torrentStatus === "stopped") return "player-pause";
                        if (torrentRoot.torrentStatus === "completed") return "check";
                        if (torrentRoot.torrentStatus === "seeding") return "upload";
                        return "help-circle";
                    }
                    color: parent.parent.parent.children[0].color
                    pointSize: 16
                    applyUiScale: true
                    Layout.preferredWidth: 24
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Item { Layout.fillWidth: true }
                
                NText {
                    text: {
                        var statusText = "";
                        switch(torrentRoot.torrentStatus) {
                            case "downloading": statusText = "Скачивается"; break;
                            case "seeding": statusText = "Раздача"; break;
                            case "completed": statusText = "Завершен"; break;
                            case "stopped": statusText = "Пауза"; break;
                            default: statusText = "Неизвестно";
                        }
                        return statusText;
                    }
                    color: Color.mOnSurfaceVariant
                    font.pointSize: Style.fontSizeXS
                    font.weight: Font.Medium
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
                    color: Qt.darker(Color.mSurface, 1.2)
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: "download"
                        color: daemonRunning ? Color.mPrimary : Color.mOnSurfaceVariant
                        pointSize: 24
                        applyUiScale: true
                    }
                }
                
                ColumnLayout {
                    spacing: Style.marginXS
                    Layout.fillWidth: true
                    
                    NText {
                        text: "Торренты"
                        color: Color.mOnSurface
                        font.pointSize: Style.fontSizeL
                        font.weight: Font.Bold
                    }
                    
                    NText {
                        text: {
                            if (!daemonRunning) return "Демон не запущен";
                            if (!torrentModel) return "Загрузка...";
                            if (errorMessage) return errorMessage;
                            return torrentModel.count + " активных";
                        }
                        color: errorMessage || !daemonRunning ? Color.mError : Color.mOnSurfaceVariant
                        font.pointSize: Style.fontSizeS
                    }
                }
                
                // Кнопка запуска/остановки демона
                Rectangle {
                    id: daemonButton
                    width: 40
                    height: 40
                    radius: 20
                    color: daemonButtonMouseArea.containsPress ? Color.mSurfaceVariant : 
                           daemonButtonMouseArea.containsMouse ? Color.mSurfaceVariant : 
                           "transparent"
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: daemonRunning ? "player-stop" : "player-play"
                        color: daemonRunning ? Color.mError : Color.mPrimary
                        pointSize: 20
                        applyUiScale: true
                    }
                    
                    MouseArea {
                        id: daemonButtonMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            if (pluginApi?.mainInstance) {
                                if (daemonRunning) {
                                    pluginApi.mainInstance.stopDaemon();
                                } else {
                                    pluginApi.mainInstance.startDaemon();
                                }
                            }
                        }
                    }
                }
            }
            
            NDivider {
                Layout.fillWidth: true
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                
                // Состояние: демон не запущен
                Loader {
                    anchors.fill: parent
                    active: !daemonRunning && !isLoading
                    
                    sourceComponent: ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginM
                        
                        NIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "power"
                            color: Color.mError
                            pointSize: 64
                            applyUiScale: true
                        }
                        
                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Демон Transmission не запущен"
                            color: Color.mError
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                        }
                        
                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: parent.width * 0.7
                            text: "Запустите демон для просмотра торрентов"
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeS
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: Style.marginL
                            width: 180
                            height: 50
                            radius: 8
                            color: startButtonMouseArea.containsPress ? Color.mSurfaceVariant : 
                                   startButtonMouseArea.containsMouse ? Qt.darker(Color.mSurface, 1.1) : 
                                   Color.mSurfaceVariant
                            
                            border.width: 1
                            border.color: Color.mPrimary
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Style.marginS
                                
                                NIcon {
                                    icon: "player-play"
                                    color: Color.mPrimary
                                    pointSize: 18
                                    applyUiScale: true
                                }
                                
                                NText {
                                    text: "Запустить демон"
                                    color: Color.mPrimary
                                    font.pointSize: Style.fontSizeS
                                    font.weight: Font.Medium
                                }
                            }
                            
                            MouseArea {
                                id: startButtonMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    if (pluginApi?.mainInstance) {
                                        pluginApi.mainInstance.startDaemon();
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Состояние загрузки
                Loader {
                    anchors.fill: parent
                    active: isLoading && (!torrentModel || torrentModel.count === 0)
                    
                    sourceComponent: ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginL
                        
                        NIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "download"
                            color: Color.mPrimary
                            pointSize: 48
                            applyUiScale: true
                        }
                        
                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Загрузка списка..."
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeM
                        }
                    }
                }
                
                // Список торрентов (когда демон работает)
                ScrollView {
                    anchors.fill: parent
                    visible: daemonRunning && torrentModel && torrentModel.count > 0
                    
                    ListView {
                        id: torrentListView
                        anchors.fill: parent
                        model: torrentModel
                        spacing: Style.marginS
                        clip: true
                        
                        delegate: TorrentItem {
                            width: torrentListView.width
                            torrentId: model.id
                            torrentName: model.name
                            torrentPercent: model.percent
                            torrentStatus: model.status
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            visible: torrentModel && torrentModel.count === 0 && !isLoading
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Style.marginM
                                
                                NIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    icon: "download-off"
                                    color: Color.mOnSurfaceVariant
                                    pointSize: 48
                                    applyUiScale: true
                                }
                                
                                NText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Нет активных торрентов"
                                    color: Color.mOnSurfaceVariant
                                    font.pointSize: Style.fontSizeM
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}