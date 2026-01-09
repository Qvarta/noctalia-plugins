import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    // Свойства для конфигурации
    property var colors: Color
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 250 * Style.uiScaleRatio
    property real contentPreferredHeight: 340 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    property int itemHeight: 48
    
    // Состояние
    property var allApps: []
    property string searchQuery: ""
    property int selectedIndex: 0
    property bool isOpen: false
    
    property var filteredApps: {
        var apps = getAllApps();
        var query = searchQuery.toLowerCase().trim();
        
        if (query === "") {
            return apps.slice(0, 30);
        }
        
        return apps.filter(function(app) {
            var name = (app.name || "").toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            return name.includes(query) || comment.includes(query);
        }).slice(0, 30);
    }
    
    function getAllApps() {
        try {
            if (typeof DesktopEntries !== 'undefined') {
                var apps = DesktopEntries.applications.values || [];
                return apps.filter(function(app) {
                    return !app.noDisplay && !app.hidden;
                });
            }
        } catch (e) {
            Logger.i("Error loading apps:", e);
        }
        return [];
    }
    
    function launchApp(app) {
        pluginApi.closePanel();
        
        Qt.callLater(function() {
            if (app.execute) {
                app.execute();
            } else if (app.command && app.command.length > 0) {
                Quickshell.execDetached(app.command);
            }
        });
    }
    
    Rectangle {
        id: panelContainer
        width: root.panelWidth
        height: Math.min(root.panelHeight, root.filteredApps.length * root.itemHeight + 100)
        anchors.centerIn: parent
        color: colors.mSurface
        radius: 12
        border.width: 1
        border.color: colors.mOutline
        
        layer.enabled: true
        layer.effect: DropShadow {
            radius: 24
            samples: 48
            color: "#60000000"
            verticalOffset: 8
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0
            
            // Заголовок с поиском
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: colors.mSurfaceVariant
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    
                    Text {
                        text: "󰍉"
                        font.pixelSize: 20
                        font.family: "Symbols Nerd Font"
                        color: colors.mPrimary
                    }
                    
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        background: null
                        color: colors.mOnSurface
                        font.pixelSize: 14
                        placeholderText: "Поиск приложений..."
                        placeholderTextColor: colors.mOnSurfaceVariant
                        
                        onTextChanged: {
                            searchQuery = text;
                            selectedIndex = 0;
                        }
                        
                        Keys.onReturnPressed: {
                            if (filteredApps.length > 0) {
                                launchApp(filteredApps[selectedIndex]);
                            }
                        }
                        
                        Keys.onEscapePressed: {
                            root.close();
                        }
                        
                        Keys.onDownPressed: {
                            if (selectedIndex < filteredApps.length - 1) {
                                selectedIndex++;
                                appList.positionViewAtIndex(selectedIndex, ListView.Contain);
                            }
                        }
                        
                        Keys.onUpPressed: {
                            if (selectedIndex > 0) {
                                selectedIndex--;
                                appList.positionViewAtIndex(selectedIndex, ListView.Contain);
                            }
                        }
                    }
                    
                    Text {
                        text: filteredApps.length
                        font.pixelSize: 12
                        color: colors.mOnSurfaceVariant
                        opacity: 0.7
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: colors.mOutline
                    opacity: 0.3
                }
            }
            
            // Список приложений
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filteredApps
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                
                delegate: Rectangle {
                    width: appList.width
                    height: root.itemHeight
                    color: selectedIndex === index ? colors.mPrimaryContainer : "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: selectedIndex = index
                        onClicked: launchApp(modelData)
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        
                        Image {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            fillMode: Image.PreserveAspectFit
                            source: {
                                if (!modelData.icon) return "";
                                if (modelData.icon.includes("/")) {
                                    return "file://" + modelData.icon;
                                }
                                return "image://icon/" + modelData.icon;
                            }
                            asynchronous: true
                            
                            Rectangle {
                                anchors.fill: parent
                                color: colors.mSurfaceVariant
                                radius: 4
                                z: -1
                                visible: parent.status === Image.Loading || parent.status === Image.Error
                            }
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || "Unknown"
                            color: selectedIndex === index ? colors.mOnPrimaryContainer : colors.mOnSurface
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            text: "↵"
                            color: colors.mPrimary
                            font.pixelSize: 12
                            opacity: selectedIndex === index ? 1 : 0
                        }
                    }
                }
                
                // Сообщения при пустом списке
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 32
                    height: 100
                    color: "transparent"
                    visible: filteredApps.length === 0
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Text {
                            text: searchQuery === "" ? "👋" : "😕"
                            font.pixelSize: 32
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: searchQuery === "" 
                                  ? "Начните вводить название приложения" 
                                  : "Ничего не найдено"
                            color: colors.mOnSurfaceVariant
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
            
            // Подвал
            Rectangle {
                Layout.fillWidth: true
                height: 30
                color: colors.mSurfaceVariant
                
                Text {
                    anchors.centerIn: parent
                    text: filteredApps.length + " приложений"
                    font.pixelSize: 11
                    color: colors.mOnSurfaceVariant
                    opacity: 0.7
                }
                
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: colors.mOutline
                    opacity: 0.3
                }
            }
        }
    }
    
    MouseArea {
        onClicked: pluginApi.closePanel();
    }
}