import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: daemonRunning ? 350 * Style.uiScaleRatio : 180 * Style.uiScaleRatio
    property real contentPreferredHeight: {
        if (!daemonRunning) return 100 * Style.uiScaleRatio;
        if (addTorrentMode) return 310 * Style.uiScaleRatio;
        
        var headerHeight = 50; 
        var itemHeight = 52; 
        var spacing = 8; 
        var padding = 32; 
        
        var totalTorrentsHeight = torrentModel ? (torrentModel.count * itemHeight + Math.max(0, torrentModel.count - 1) * spacing) : 0;
        var totalHeight = headerHeight + totalTorrentsHeight + padding;
        
        var maxHeight = 500 * Style.uiScaleRatio;
        return Math.min(maxHeight, totalHeight);
    }
    readonly property bool allowAttach: true
    
    property ListModel torrentModel: pluginApi?.mainInstance?.torrentModel || null
    property bool isLoading: pluginApi?.mainInstance?.isLoading || false
    property string errorMessage: pluginApi?.mainInstance?.errorMessage || ""
    property bool daemonRunning: pluginApi?.mainInstance?.daemonRunning || false
    
    property bool addTorrentMode: false
    property string magnetLink: ""
    property string torrentFilePath: ""
    
    anchors.fill: parent
    
    NPopupContextMenu {
        id: torrentContextMenu
        itemHeight: 36
        minWidth: 160
        
        property var currentTorrent: null
        
        onTriggered: function(action, item) {
            if (currentTorrent) {
                if (action === "pause") {
                    if (pluginApi && pluginApi.mainInstance && currentTorrent.torrentId) {
                        pluginApi.mainInstance.pauseTorrent(currentTorrent.torrentId);
                    }
                } else if (action === "resume") {
                    if (pluginApi && pluginApi.mainInstance && currentTorrent.torrentId) {
                        pluginApi.mainInstance.resumeTorrent(currentTorrent.torrentId);
                    }
                } else if (action === "delete") {
                    if (pluginApi && pluginApi.mainInstance && currentTorrent.torrentId) {
                        // Обновляем модель сразу после удаления
                        pluginApi.mainInstance.deleteTorrent(currentTorrent.torrentId);
                        
                        var torrentModel = pluginApi.mainInstance.torrentModel;
                        if (torrentModel) {
                            for (var i = 0; i < torrentModel.count; i++) {
                                if (torrentModel.get(i).id === currentTorrent.torrentId) {
                                    torrentModel.remove(i);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            close();
        }

        function updateMenuModel() {
            if (!currentTorrent) return;
            
            var isStopped = currentTorrent.torrentStatus === "stopped";
            
            var newModel = [];
            
            if (!isStopped) {
                newModel.push({
                    "label": pluginApi?.tr("statusPause"),
                    "action": "pause",
                    "icon": "player-pause",
                    "enabled": true
                });
            } else {
                newModel.push({
                    "label": pluginApi?.tr("continue"),
                    "action": "resume",
                    "icon": "player-play",
                    "enabled": true
                });
            }
            
            newModel.push({
                "label": pluginApi?.tr("removeTorrentTitle"),
                "action": "delete",
                "icon": "trash",
                "enabled": true
            });
            
            newModel.push({
                "label": "",
                "action": "separator",
                "enabled": false,
                "visible": false
            });
            
            newModel.push({
                "label": pluginApi?.tr("cancel"),
                "action": "cancel",
                "icon": "x",
                "enabled": true
            });
            
            model = newModel;
        }
        
        function openForTorrent(torrent, mouseX, mouseY) {
            currentTorrent = torrent;
            updateMenuModel();
            
            var anchor = Qt.createQmlObject(`
                import QtQuick
                Item {
                    width: 1
                    height: 1
                    x: ${mouseX}
                    y: ${mouseY}
                }
            `, root, "contextMenuAnchor");
            
            openAtItem(anchor, null);
            
            torrentContextMenu.closed.connect(function() {
                if (anchor) {
                    anchor.destroy();
                }
                torrentContextMenu.closed.disconnect(arguments.callee);
            });
        }
        
        function close() {
            visible = false;
            currentTorrent = null;
        }
    }
    
    component TorrentItem: Rectangle {
        id: torrentRoot
        property int torrentId: 0
        property string torrentName: ""
        property int torrentPercent: 0
        property string torrentStatus: ""
        property int itemIndex: 0
        
        width: parent.width
        height: 52
        radius: 8
        color: itemIndex % 2 === 0 ? Color.mSurface :  Color.mSurfaceVariant
        
        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 10
            
            NIcon {
                Layout.preferredWidth: 24
                Layout.alignment: Qt.AlignVCenter
                icon: {
                    if (torrentRoot.torrentStatus === "downloading") return "download";
                    if (torrentRoot.torrentStatus === "stopped") return "player-pause";
                    if (torrentRoot.torrentStatus === "completed") return "check";
                    if (torrentRoot.torrentStatus === "seeding") return "upload";
                    if (torrentRoot.torrentStatus === "verifying") return "shield-check";
                    if (torrentRoot.torrentStatus === "queued") return "clock";
                    if (torrentRoot.torrentStatus === "idle") return "clock";
                    return "help-circle";
                }
                color: {
                    switch(torrentRoot.torrentStatus) {
                        case "downloading": return Color.mPrimary;
                        case "seeding": return Color.mSecondary;
                        case "completed": return Color.mTertiary;
                        case "stopped": return Color.mError;
                        case "verifying": return Color.mHover;
                        case "queued": return Color.mInfo;
                        case "idle": return Color.mOutline;
                        default: return Color.mOutline;
                    }
                }
                pointSize: 16
                applyUiScale: true
            }
            
            // Основная информация с прогресс-баром
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                
                // Название и процент в одной строке
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    NText {
                        Layout.fillWidth: true
                        text: torrentRoot.torrentName
                        color: Color.mOnSurface
                        font.pointSize: Style.fontSizeS
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    
                    NText {
                        text: torrentRoot.torrentPercent + "%"
                        color: Color.mOnSurfaceVariant
                        font.pointSize: Style.fontSizeXS
                        font.weight: Font.Bold
                    }
                }
                
                // Прогресс бар
                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Color.mSurfaceVariant
                    
                    Rectangle {
                        width: parent.width * (torrentRoot.torrentPercent / 100)
                        height: parent.height
                        radius: 2
                        color: {
                            switch(torrentRoot.torrentStatus) {
                                case "downloading": return Color.mPrimary;
                                case "seeding": return Color.mSecondary;
                                case "completed": return Color.mTertiary;
                                case "stopped": return Color.mError;
                                case "verifying": return Color.mHover;
                                case "queued": return Color.mInfo;
                                case "idle": return Color.mOutline;
                                default: return Color.mOutline;
                            }
                        }
                        
                        Behavior on width {
                            NumberAnimation {
                                duration: 800
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
                
                // Статус под прогресс-баром
                NText {
                    text: {
                        var statusText = "";
                        switch(torrentRoot.torrentStatus) {
                            case "downloading": statusText = pluginApi?.tr("statusDownloading"); break;
                            case "seeding": statusText = pluginApi?.tr("statusSeeding"); break;
                            case "completed": statusText = pluginApi?.tr("statusCompleted"); break;
                            case "stopped": statusText = pluginApi?.tr("statusPause"); break;
                            case "verifying": statusText = pluginApi?.tr("statusVerifying"); break;
                            case "queued": statusText = pluginApi?.tr("statusQueued"); break;
                            case "idle": statusText = pluginApi?.tr("statusIdle"); break;
                            default: statusText = pluginApi?.tr("statusUnknown");
                        }
                        return statusText;
                    }
                    color: Color.mOnSurfaceVariant
                    font.pointSize: Style.fontSizeXS
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    var torrentDelegatePos = torrentRoot.mapToItem(root, 0, 0);
                    var clickX = mouse.x + torrentDelegatePos.x;
                    var clickY = mouse.y + torrentDelegatePos.y;
                    
                    var torrentData = {
                        "torrentId": torrentRoot.torrentId,
                        "torrentName": torrentRoot.torrentName,
                        "torrentPercent": torrentRoot.torrentPercent,
                        "torrentStatus": torrentRoot.torrentStatus
                    };
                    
                    torrentContextMenu.openForTorrent(torrentData, clickX, clickY);
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
                id: headerLayout
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: Style.marginM
                
                Rectangle {
                    id: daemonButton
                    width: 36
                    height: 36
                    radius: 8
                    color: daemonButtonMouseArea.containsMouse ? 
                        (daemonRunning ? Color.mError : 
                        isLoading ? Color.mHover : Qt.darker(Color.mHover, 1.2)) : Color.mOutline
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                    
                    NIcon {
                        id: daemonIcon
                        anchors.centerIn: parent
                        icon: isLoading ? "loader" :  "power"
                        color: daemonButtonMouseArea.containsMouse ? 
                            Color.mOnHover : 
                            (isLoading ? Color.mHover : 
                            daemonRunning ? Color.mError : Color.mHover)
                        pointSize: 24
                        applyUiScale: true
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationFast
                            }
                        }
                    }
                    
                    RotationAnimator {
                        id: rotationAnimator
                        target: daemonIcon
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: isLoading
                    }
                    
                    Connections {
                        target: root
                        function onIsLoadingChanged() {
                            if (!root.isLoading) {
                                daemonIcon.rotation = 0;
                            }
                        }
                    }
                    
                    MouseArea {
                        id: daemonButtonMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !isLoading
                        
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
                
                ColumnLayout {
                    spacing: Style.marginXS
                    Layout.fillWidth: true
                    
                    NText {
                        text: {
                            if (!daemonRunning) return pluginApi?.tr("stopped");
                            if (!torrentModel) return pluginApi?.tr("downloading");
                            if (errorMessage) return errorMessage;
                            return torrentModel.count + " " + pluginApi?.tr("active");
                        }
                        color: errorMessage || !daemonRunning ? Color.mError : Color.mOnSurfaceVariant
                        font.pointSize: Style.fontSizeM
                    }
                }
                
                Item {
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    id: addButton
                    width: 36
                    height: 36
                    radius: 8
                    color: addButtonMouseArea.containsMouse ? Color.mHover : Color.mSurfaceVariant
                    visible: daemonRunning && !root.addTorrentMode
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: "plus"
                        color: addButtonMouseArea.containsMouse ? Color.mOnHover : Color.mOnSurfaceVariant
                        pointSize: 24
                        applyUiScale: true
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationFast
                            }
                        }
                    }
                    
                    MouseArea {
                        id: addButtonMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            root.addTorrentMode = true;
                        }
                    }
                }
            }
            
            NDivider {
                Layout.fillWidth: true
                visible: daemonRunning
            }
            
            Item {
                id: contentArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: daemonRunning
                
                StackLayout {
                    id: mainStack
                    anchors.fill: parent
                    currentIndex: root.addTorrentMode ? 1 : 0
                    
                    Item {
                        id: torrentsTab
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.marginM
                            visible: isLoading && (!torrentModel || torrentModel.count === 0)
                            
                            NIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: "download"
                                color: Color.mPrimary
                                pointSize: 48
                                applyUiScale: true
                            }
                            
                            NText {
                                Layout.alignment: Qt.AlignHCenter
                                text: pluginApi?.tr("Activate")
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeM
                            }
                        }
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.marginM
                            visible: daemonRunning && torrentModel && torrentModel.count === 0 && !isLoading
                            
                            NIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: "download-off"
                                color: Color.mOnSurfaceVariant
                                pointSize: 48
                                applyUiScale: true
                            }
                            
                            NText {
                                Layout.alignment: Qt.AlignHCenter
                                text: pluginApi?.tr("noTorrents")
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeM
                            }
                        }
                        
                        NListView {
                            id: torrentsListView
                            anchors.fill: parent
                            visible: daemonRunning && torrentModel && torrentModel.count > 0
                            model: torrentModel
                            spacing: 0 
                            
                            delegate: TorrentItem {
                                width: ListView.view.width
                                torrentId: model.id
                                torrentName: model.name
                                torrentPercent: model.percent
                                torrentStatus: model.status
                                itemIndex: index 
                            }
                        }
                    }
                    
                    Item {
                        id: addTorrentTab
                        
                        ScrollView {
                            anchors.fill: parent
                            clip: true
                            
                            ColumnLayout {
                                width: addTorrentTab.width
                                spacing: Style.marginM
                                
                                NText {
                                    text: pluginApi?.tr("enterMagnetLink")
                                    color: Color.mOnSurfaceVariant
                                    font.pointSize: Style.fontSizeS
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    radius: Style.radiusS
                                    color: Color.mSurfaceVariant
                                    border.width: Style.borderS
                                    border.color: root.magnetLink ? Color.mSecondary : Color.mOutline
                                    
                                    TextArea {
                                        id: magnetInput
                                        anchors {
                                            fill: parent
                                            margins: Style.marginS
                                        }
                                        text: root.magnetLink
                                        color: Color.mOnSurface
                                        font.pointSize: Style.fontSizeS
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        selectByMouse: true
                                        background: null
                                        
                                        onTextChanged: {
                                            root.magnetLink = text;
                                        }
                                    }
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    spacing: Style.marginM
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        color: Color.mOutline
                                    }
                                    
                                    NText {
                                        text: pluginApi?.tr("or")
                                        color: Color.mOnSurfaceVariant
                                        font.pointSize: Style.fontSizeXS
                                        font.weight: Font.Medium
                                    }
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        color: Color.mOutline
                                    }
                                }
                                
                                Loader {
                                    id: fileInputLoader
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    
                                    sourceComponent: root.torrentFilePath ? fileSelectedComponent : selectFileComponent
                                }
                                
                                NFilePicker {
                                    id: torrentFilePicker
                                    title: pluginApi?.tr("selectFile")
                                    selectionMode: "files"
                                    nameFilters: ["*.torrent"]
                                    showHiddenFiles: false
                                    
                                    onAccepted: function(paths) {
                                        if (paths.length > 0) {
                                            root.torrentFilePath = paths[0];
                                        }
                                    }
                                    
                                    onCancelled: {
                                    }
                                }
                                
                                Item {
                                    Layout.fillHeight: true
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    spacing: Style.marginM
                                    Layout.topMargin: Style.marginL
                                    
                                    NButton {
                                        Layout.fillWidth: true
                                        text: pluginApi?.tr("cancel")
                                        outlined: true
                                        onClicked: {
                                            root.addTorrentMode = false;
                                            root.magnetLink = "";
                                            root.torrentFilePath = "";
                                        }
                                    }
                                    
                                    NButton {
                                        Layout.fillWidth: true
                                        text: pluginApi?.tr("addTorrentTitle")
                                        icon: "plus"
                                        enabled: root.magnetLink || root.torrentFilePath
                                        onClicked: {
                                            if (root.torrentFilePath) {
                                                if (pluginApi?.mainInstance && root.torrentFilePath) {
                                                    pluginApi.mainInstance.addTorrentFromFile(root.torrentFilePath);
                                                }
                                            } else if (root.magnetLink) {
                                                if (pluginApi?.mainInstance && root.magnetLink) {
                                                    pluginApi.mainInstance.addTorrentFromMagnet(root.magnetLink);
                                                }
                                            }
                                            
                                            root.addTorrentMode = false;
                                            root.magnetLink = "";
                                            root.torrentFilePath = "";
                                        }
                                    }
                                }
                            }
                        }
                        
                        Component {
                            id: selectFileComponent
                            NButton {
                                height: parent.height
                                text: pluginApi?.tr("selectFile")
                                icon: "folder"
                                onClicked: {
                                    torrentFilePicker.openFilePicker();
                                }
                            }
                        }
                        
                        // Компонент для отображения выбранного файла
                        Component {
                            id: fileSelectedComponent
                            Rectangle {
                                height: parent.height
                                radius: 8
                                color: Color.mSurface
                                border.width: Style.borderS
                                border.color: Color.mSecondary
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Style.marginS
                                    spacing: 8
                                    
                                    NText {
                                        text: root.torrentFilePath.split('/').pop()
                                        color: Color.mOnSurfaceVariant
                                        font.pointSize: Style.fontSizeS
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: width / 2
                                        color: clearButtonMouseArea.containsMouse ? Color.mHover : Color.mOutline
                                        Layout.alignment: Qt.AlignVCenter
                                        
                                        NIcon {
                                            anchors.centerIn: parent
                                            icon: "x"
                                            color: Color.mError
                                            pointSize: 12
                                            applyUiScale: true
                                        }
                                        
                                        MouseArea {
                                            id: clearButtonMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            
                                            onClicked: {
                                                root.torrentFilePath = "";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}