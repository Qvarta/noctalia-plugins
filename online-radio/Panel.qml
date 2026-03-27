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
        return isPlaying && pluginApi.mainInstance.currentPlayingStation === stationName
    }

    anchors.fill: parent
    
    property int currentIndex: 0
    
    function updateCurrentIndex() {
        if (pluginApi && pluginApi.mainInstance) {
            var stations = pluginApi.mainInstance.getStations();
            var currentStation = pluginApi.mainInstance.currentPlayingStation;
            
            if (currentStation && currentStation !== "") {
                for (var i = 0; i < stations.length; i++) {
                    if (stations[i].name === currentStation) {
                        currentIndex = i;
                        ensureVisible(i);
                        return;
                    }
                }
            }
        }
        currentIndex = 0;
        ensureVisible(0);
    }
    
    function ensureVisible(index) {
        if (!listView || !listView.model || listView.model.length === 0) return;
        
        var item = listView.itemAtIndex(index);
        if (!item) {
            listView.positionViewAtIndex(index, ListView.Contain);
            return;
        }
        
        var itemY = item.y;
        var viewportHeight = listView.height;
        var contentY = listView.contentY;
        
        if (itemY < contentY) {
            listView.contentY = itemY;
        } else if (itemY + item.height > contentY + viewportHeight) {
            listView.contentY = itemY + item.height - viewportHeight;
        }
    }
    
    function selectStation(index) {
        if (index >= 0 && listView.model && index < listView.model.length) {
            currentIndex = index;
            ensureVisible(index);
        }
    }
    
    function moveSelection(delta) {
        if (!listView.model || listView.model.length === 0) return;
        
        var newIndex = currentIndex + delta;
        if (newIndex >= 0 && newIndex < listView.model.length) {
            selectStation(newIndex);
        }
    }
    
    function activateCurrentStation() {
        if (currentIndex >= 0 && listView.model && currentIndex < listView.model.length) {
            var station = listView.model[currentIndex];
            if (station && pluginApi && pluginApi.mainInstance) {
                var main = pluginApi.mainInstance;
                
                if (isStationPlaying(station.name)) {
                    main.stopPlayback();
                } else {
                    main.playStation(station.name, station.url);
                }
            }
        }
    }
    
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: activateCurrentStation()
    Keys.onEnterPressed: activateCurrentStation()
    
    function updateSelectionFromPlaying() {
        if (pluginApi && pluginApi.mainInstance) {
            var currentStation = pluginApi.mainInstance.currentPlayingStation;
            if (currentStation && currentStation !== "") {
                var stations = pluginApi.mainInstance.getStations();
                for (var i = 0; i < stations.length; i++) {
                    if (stations[i].name === currentStation) {
                        if (currentIndex !== i) {
                            currentIndex = i;
                            ensureVisible(i);
                        }
                        return;
                    }
                }
            }
        }
        if (currentIndex !== 0) {
            currentIndex = 0;
            ensureVisible(0);
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusM
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginL

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: 6
                border.width: Style.borderS
                border.color: Color.mShadow

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    model: pluginApi && pluginApi.mainInstance ? 
                           pluginApi.mainInstance.getStations() : []
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    
                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: delegateContainer
                        width: listView.width
                        height: 52
                        
                        readonly property bool isSelected: index === currentIndex
                        
                        Rectangle {
                            id: delegateRect
                            anchors.fill: parent
                            radius: 6       
                            border.width: Style.borderS
                            border.color: Color.mOutline
                            color: {
                                if (isStationPlaying(modelData.name)) {
                                    if (mouseArea.containsMouse || isSelected) {
                                        return Color.mHover;
                                    } else {
                                        return Color.mSurfaceVariant;
                                    }
                                } else if (mouseArea.containsMouse || isSelected) {
                                    return Color.mHover;
                                } else {
                                    return Color.mSurfaceVariant;
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                
                                onClicked: {
                                    currentIndex = index;
                                    if (pluginApi && pluginApi.mainInstance) {
                                        var main = pluginApi.mainInstance;
                                        
                                        if (isStationPlaying(modelData.name)) {
                                            main.stopPlayback();
                                        } else {
                                            main.playStation(modelData.name, modelData.url);
                                        }
                                    }
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
                                        icon: isStationPlaying(modelData.name) ? "volume" : "radio"
                                        color: Color.mPrimary
                                        width: 24
                                        height: 24
                                    }
                                }
                                
                                NText {
                                    text: modelData.name
                                    color: {
                                        if (isStationPlaying(modelData.name)) {
                                            if (mouseArea.containsMouse || isSelected) {
                                                return Color.mOnSecondary;
                                            } else {
                                                return Color.mOnSurface;
                                            }
                                        } else if (mouseArea.containsMouse || isSelected) {
                                            return Color.mOnSecondary;
                                        } else {
                                            return Color.mOnSurface;
                                        }
                                    }
                                    font.pointSize: Style.fontSizeS
                                    font.weight: {
                                        if (isStationPlaying(modelData.name)) {
                                            if (mouseArea.containsMouse || isSelected) {
                                                return Font.Bold;
                                            } else {
                                                return Font.Normal;
                                            }
                                        } else if (mouseArea.containsMouse || isSelected) {
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
                                        color: (mouseArea.containsMouse || isSelected) ? Color.mOnSurface : Color.mSurfaceVariant
                                        width: 16
                                        height: 16
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
                                width: 64
                                height: 64
                                opacity: 0.5
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            NText {
                                text: pluginApi?.tr("NotLoaded") || "Нет данных"
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeM
                                font.weight: Font.Medium
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            NText {
                                text: pluginApi?.tr("addStations") || "Добавьте радиостанции"
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
        }
    }
    
    Component.onCompleted: {
        currentIndex = 0;
        updateCurrentIndex();
        forceActiveFocus();
        ensureVisible(0);
    }
    
    Connections {
        target: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance : null
        enabled: pluginApi && pluginApi.mainInstance
        
        function onCurrentPlayingStationChanged() {
            updateSelectionFromPlaying();
        }
        
        function onCurrentPlayingProcessStateChanged() {
            updateSelectionFromPlaying();
        }
    }
}