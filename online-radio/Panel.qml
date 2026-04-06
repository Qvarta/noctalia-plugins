import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root
    anchors.fill: parent

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 600 * Style.uiScaleRatio
    property real contentPreferredHeight: 400 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    readonly property bool isPlaying: pluginApi && pluginApi.mainInstance && pluginApi.mainInstance.currentPlayingProcessState === "start"

    property int currentIndex: 0
    property int columns: 4
    property int rows: 4
    property int cellSpacing: Style.marginM

    readonly property real headerHeight: 52 * Style.uiScaleRatio
    readonly property real panelMargin: 20 * Style.uiScaleRatio
    
    function isStationPlaying(stationName) {
        return isPlaying && pluginApi.mainInstance.currentPlayingStation === stationName;
    }

    function getImageUrl(stationName) {
        return Qt.resolvedUrl("images/" + stationName + ".png");
    }

    function getCurrentRow() {
        return Math.floor(currentIndex / columns);
    }

    function getCurrentColumn() {
        return currentIndex % columns;
    }

    function updateCurrentIndex() {
        if (pluginApi && pluginApi.mainInstance) {
            var stations = pluginApi.mainInstance.getStations();
            var currentStation = pluginApi.mainInstance.currentPlayingStation;

            if (currentStation && currentStation !== "") {
                for (var i = 0; i < stations.length; i++) {
                    if (stations[i].name === currentStation) {
                        currentIndex = i;
                        Qt.callLater(ensureVisible);
                        return;
                    }
                }
            }
        }
        currentIndex = 0;
        Qt.callLater(ensureVisible);
    }

    function ensureVisible() {
        if (!gridView || !gridView.model || gridView.model.length === 0)
            return;
        gridView.positionViewAtIndex(currentIndex, GridView.Contain);
    }

    function selectStation(index) {
        if (index >= 0 && gridView.model && index < gridView.model.length) {
            currentIndex = index;
            ensureVisible();
        }
    }

    function moveSelection(deltaX, deltaY) {
        if (!gridView.model || gridView.model.length === 0)
            return;
        var currentRow = getCurrentRow();
        var currentCol = getCurrentColumn();
        var newRow = currentRow + deltaY;
        var newCol = currentCol + deltaX;
        var newIndex = newRow * columns + newCol;

        if (deltaY !== 0) {
            if (newRow >= 0 && newRow < Math.ceil(gridView.model.length / columns)) {
                var maxColInNewRow = Math.min(columns - 1, gridView.model.length - 1 - newRow * columns);
                if (maxColInNewRow >= 0) {
                    newCol = Math.min(currentCol, maxColInNewRow);
                    newIndex = newRow * columns + newCol;
                    selectStation(newIndex);
                }
            }
        } else if (deltaX !== 0) {
            if (newIndex >= 0 && newIndex < gridView.model.length) {
                var rowForNewIndex = Math.floor(newIndex / columns);
                if (rowForNewIndex === currentRow) {
                    selectStation(newIndex);
                }
            }
        }
    }

    function activateCurrentStation() {
        if (currentIndex >= 0 && gridView.model && currentIndex < gridView.model.length) {
            var station = gridView.model[currentIndex];
            if (station && pluginApi && pluginApi.mainInstance) {
                var main = pluginApi.mainInstance;

                if (isStationPlaying(station.name)) {
                    main.stopPlayback();
                } else {
                    if (isPlaying) {
                        main.stopPlayback();
                        stopPlaybackTimer.stationToPlay = station;
                        stopPlaybackTimer.start();
                    } else {
                        main.playStation(station.name, station.url);
                    }
                }
            }
        }
    }

    function updateSelectionFromPlaying() {
        if (pluginApi && pluginApi.mainInstance) {
            var currentStation = pluginApi.mainInstance.currentPlayingStation;
            if (currentStation && currentStation !== "") {
                var stations = pluginApi.mainInstance.getStations();
                for (var i = 0; i < stations.length; i++) {
                    if (stations[i].name === currentStation) {
                        if (currentIndex !== i) {
                            currentIndex = i;
                            Qt.callLater(ensureVisible);
                        }
                        return;
                    }
                }
            }
        }
        if (currentIndex !== 0) {
            currentIndex = 0;
            Qt.callLater(ensureVisible);
        }
    }

    Keys.onUpPressed: moveSelection(0, -1)
    Keys.onDownPressed: moveSelection(0, 1)
    Keys.onLeftPressed: moveSelection(-1, 0)
    Keys.onRightPressed: moveSelection(1, 0)
    Keys.onReturnPressed: activateCurrentStation()
    Keys.onEnterPressed: activateCurrentStation()

    Timer {
        id: stopPlaybackTimer
        interval: 100
        repeat: false
        property var stationToPlay: null

        onTriggered: {
            if (stationToPlay && pluginApi && pluginApi.mainInstance) {
                pluginApi.mainInstance.playStation(stationToPlay.name, stationToPlay.url);
                stationToPlay = null;
            }
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        anchors.margins: Style.marginS

        radius: Style.radiusM
        border.width: Style.borderS
        border.color: Color.mOutline
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginS
            spacing: Style.marginM

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: headerHeight
                Layout.topMargin: 20 * Style.uiScaleRatio
                Layout.leftMargin: 20 * Style.uiScaleRatio
                Layout.rightMargin: 20 * Style.uiScaleRatio
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: Style.marginM

                    Rectangle {
                        width: headerHeight * 0.8
                        height: headerHeight * 0.8
                        radius: 4
                        color: Color.mSurfaceVariant
                        border.width: Style.borderS
                        border.color: Color.mOutline

                        NIcon {
                            id: radioIcon
                            icon: "radio"
                            anchors.centerIn: parent
                            pointSize: Style.fontSizeXL * 1.2
                            color: Color.mPrimary
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        NText {
                            text: "Онлайн радио"
                            font.weight: Font.Bold
                            font.pointSize: Style.fontSizeXL * 1.1
                            color: Color.mOnSurface
                        }

                        NText {
                            text: "Выберите радиостанцию"
                            font.pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                            opacity: 0.8
                        }
                    }

                    NIconButton {
                        icon: "settings"
                        tooltipText: I18n.tr("common.settings")
                        baseSize: Style.baseWidgetSize * 0.8
                        onClicked: BarService.openPluginSettings(screen, pluginApi.manifest)
                    }

                    NIconButton {
                        icon: "close"
                        tooltipText: I18n.tr("common.close")
                        baseSize: Style.baseWidgetSize * 0.8
                        onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance.getStations() : []
                cellWidth: (gridView.width - (columns - 1) * cellSpacing) / columns
                cellHeight: cellWidth + 70
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    parent: gridView
                    anchors {
                        top: parent.top
                        right: parent.right
                        bottom: parent.bottom
                        rightMargin: 10
                    }

                    background: Rectangle {
                        color: Color.mOutline
                        implicitWidth: 6
                        radius: 4
                    }

                    contentItem: Rectangle {
                        color: Color.mPrimary
                        radius: 4
                    }
                }

                delegate: Item {
                    id: delegateContainer
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    readonly property bool isSelected: index === currentIndex
                    readonly property bool isHovered: mouseArea.containsMouse
                    readonly property bool isNowPlaying: isStationPlaying(modelData.name)
                    readonly property bool isActive: isSelected || isHovered || isNowPlaying

                    Rectangle {
                        id: delegateRect
                        anchors.fill: parent
                        anchors.margins: cellSpacing / 2
                        radius: Style.radiusM
                        color: Color.mSurface

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
                                if (pluginApi && pluginApi.mainInstance) {
                                    var main = pluginApi.mainInstance;

                                    if (isStationPlaying(modelData.name)) {
                                        main.stopPlayback();
                                    } else {
                                        if (isPlaying) {
                                            main.stopPlayback();
                                            stopPlaybackTimer.stationToPlay = modelData;
                                            stopPlaybackTimer.start();
                                        } else {
                                            main.playStation(modelData.name, modelData.url);
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginS

                            Rectangle {
                                id: imageSquare
                                Layout.fillWidth: true
                                Layout.preferredHeight: width
                                Layout.minimumHeight: 60
                                color: isNowPlaying ? "transparent" : Color.mSurfaceVariant
                                radius: Style.radiusM
                                clip: true

                                scale: isActive ? 1.2 : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }
                                }

                                transformOrigin: Item.Center

                                Rectangle {
                                    id: iconPlaceholder
                                    anchors.fill: parent
                                    radius: Style.radiusM
                                    color: Color.mSurfaceVariant
                                    visible: true

                                    NIcon {
                                        anchors.centerIn: parent
                                        icon: "radio"
                                        color: Color.mOnSurfaceVariant
                                        pointSize: Math.min(parent.width * 0.4, 36)
                                    }
                                }

                                Image {
                                    id: stationImage
                                    anchors.fill: parent
                                    source: getImageUrl(modelData.name)
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    visible: false
                                    cache: true
                                    asynchronous: true

                                    onStatusChanged: {
                                        if (status === Image.Ready) {
                                            iconPlaceholder.visible = false;
                                            stationImage.visible = true;
                                        } else if (status === Image.Error) {
                                            iconPlaceholder.visible = true;
                                            stationImage.visible = false;
                                        }
                                    }
                                }

                                Loader {
                                    id: rippleLoader
                                    anchors.fill: stationImage
                                    active: isNowPlaying && stationImage.visible

                                    sourceComponent: Item {
                                        anchors.fill: parent

                                        property real shaderTime: 0
                                        NumberAnimation on shaderTime {
                                            loops: Animation.Infinite
                                            from: 0
                                            to: 1000
                                            duration: 30000
                                        }

                                        ShaderEffect {
                                            id: rippleEffect
                                            anchors.fill: parent

                                            property var source: ShaderEffectSource {
                                                sourceItem: stationImage
                                                hideSource: true
                                            }

                                            property real time: parent.shaderTime
                                            property real speed: 0.1     // Скорость волн (меньше = медленнее)
                                            property real waveFrequency: 20.0  // Частота (меньше = шире волны)
                                            property real waveAmplitude: 0.1 // Амплитуда (меньше = слабее эффект)
                                            property real itemWidth: rippleEffect.width
                                            property real itemHeight: rippleEffect.height

                                            fragmentShader: "Shaders/ripple.qsb"
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: isNowPlaying
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        margins: Style.marginXS
                                    }
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: Color.mPrimary

                                    NIcon {
                                        anchors.centerIn: parent
                                        icon: "volume"
                                        color: Color.mOnPrimary
                                        pointSize: 16
                                    }
                                }
                            }

                            NText {
                                text: modelData.name
                                color: '#ffffff'
                                font.pointSize: isActive ? Style.fontSizeM : Style.fontSizeS
                                font.weight: (isNowPlaying || isActive) ? Font.Bold : Font.Normal
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                Layout.maximumHeight: 40
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    height: 120
                    visible: gridView.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginM

                        NIcon {
                            icon: "radio"
                            color: Color.mOnSurfaceVariant
                            pointSize: 32
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

    Component.onCompleted: {
        currentIndex = 0;
        updateCurrentIndex();
        forceActiveFocus();
        Qt.callLater(ensureVisible);
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
