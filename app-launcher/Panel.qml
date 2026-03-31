import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 360 * Style.uiScaleRatio
    property real contentPreferredHeight: 480 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    
    function getSafeIcon(iconName) {
        if (!iconName) return "apps";
        var knownIcons = ["apps", "star", "search", "search-off", "player-play", "star-filled", "camera", "radio", "notes", "download", "keyboard", "chevron-right"];
        if (knownIcons.indexOf(iconName) !== -1) {
            return iconName;
        }
        return "apps";
    }
    
    function isValidApi() {
        return pluginApi && pluginApi.mainInstance && typeof pluginApi.mainInstance.getFilteredApps === 'function';
    }
    
    function getUiState() {
        if (!pluginApi || !pluginApi.mainInstance) {
            return { searchQuery: "", showAllAppsMode: true, favoriteApps: [] };
        }
        return {
            searchQuery: pluginApi.mainInstance.searchQuery,
            showAllAppsMode: pluginApi.mainInstance.showAllAppsMode,
            favoriteApps: pluginApi.mainInstance.favoriteApps || []
        };
    }
    
    function getEmptyStateText() {
        var state = getUiState();
        if (state.searchQuery !== "") return "Ничего не найдено";
        if (!state.showAllAppsMode) return state.favoriteApps.length === 0 ? "Избранное пусто" : "Начните вводить название";
        return "Начните вводить название приложения";
    }
    
    function getEmptyStateDescription() {
        var state = getUiState();
        if (state.searchQuery !== "") return "Попробуйте другой запрос";
        if (!state.showAllAppsMode) return state.favoriteApps.length === 0 ? "Добавьте приложения в избранное" : "Используйте поле поиска";
        return "Используйте поле поиска выше";
    }
    
    function getEmptyStateIcon() {
        if (!pluginApi || !pluginApi.mainInstance) return "apps";
        var state = getUiState();
        if (state.searchQuery !== "") return "search-off";
        if (!state.showAllAppsMode) return state.favoriteApps.length === 0 ? "star" : "search";
        return "apps";
    }
    
    function ensureVisible(index) {
        if (!appListView) return;
        
        var item = appListView.itemAtIndex(index);
        if (!item) {
            appListView.positionViewAtIndex(index, ListView.Contain);
            return;
        }
        
        var itemY = item.y;
        var viewportHeight = appListView.height;
        var contentY = appListView.contentY;
        
        if (itemY < contentY) {
            appListView.contentY = itemY;
        } else if (itemY + item.height > contentY + viewportHeight) {
            appListView.contentY = itemY + item.height - viewportHeight;
        }
    }
    
    function updateSelectedIndex(newIndex, filteredApps) {
        if (pluginApi && pluginApi.mainInstance) {
            pluginApi.mainInstance.selectedIndex = Math.max(0, Math.min(newIndex, filteredApps.length - 1));
            ensureVisible(pluginApi.mainInstance.selectedIndex);
        }
    }
    
    function getRealAppsCount(filteredApps) {
        if (!filteredApps) return 0;
        return filteredApps.filter(function(app) {
            return !app.isShowAllButton && !app.isShowFavoritesButton;
        }).length;
    }
    
    function moveSelection(delta) {
        if (!isValidApi()) return;
        
        var filteredApps = pluginApi.mainInstance.getFilteredApps();
        var newIndex = pluginApi.mainInstance.selectedIndex + delta;
        
        if (newIndex >= 0 && newIndex < filteredApps.length) {
            pluginApi.mainInstance.selectedIndex = newIndex;
            ensureVisible(newIndex);
        }
    }
    
    function launchCurrentApp() {
        if (!isValidApi()) return;
        
        var filteredApps = pluginApi.mainInstance.getFilteredApps();
        if (filteredApps.length > 0) {
            pluginApi.mainInstance.launchApp(filteredApps[pluginApi.mainInstance.selectedIndex]);
        }
    }
    
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: launchCurrentApp()
    Keys.onEnterPressed: launchCurrentApp()
    Keys.onEscapePressed: {
        if (pluginApi) {
            pluginApi.closePanel();
        }
    }
    
    anchors.fill: parent

    NPopupContextMenu {
        id: appContextMenu
        itemHeight: 36
        minWidth: 160
        
        property var currentApp: null
        
        onTriggered: function(action, item) {
            if (currentApp) {
                if (action === "launch") {
                    if (pluginApi && pluginApi.mainInstance) {
                        pluginApi.mainInstance.launchApp(currentApp);
                    }
                } else if (action === "add-to-favorites") {
                    if (pluginApi && pluginApi.mainInstance) {
                        pluginApi.mainInstance.addToFavorites(currentApp);
                    }
                    Qt.callLater(updateMenuModel);
                } else if (action === "remove-from-favorites") {
                    if (pluginApi && pluginApi.mainInstance) {
                        pluginApi.mainInstance.removeFromFavorites(currentApp.id);
                    }
                    Qt.callLater(updateMenuModel);
                }
            }
            close();
        }
        
        function updateMenuModel() {
            if (!currentApp) return;
            
            var isFav = pluginApi && pluginApi.mainInstance ? 
                       pluginApi.mainInstance.isFavorite(currentApp.id) : false;
            
            var newModel = [
                {
                    "label": "Запустить",
                    "action": "launch",
                    "icon": "player-play",
                    "enabled": true
                }
            ];
            
            if (isFav) {
                newModel.push({
                    "label": "Удалить из избранного",
                    "action": "remove-from-favorites",
                    "icon": "star",
                    "enabled": true
                });
            } else {
                newModel.push({
                    "label": "Добавить в избранное",
                    "action": "add-to-favorites",
                    "icon": "star-filled",
                    "enabled": true
                });
            }
            
            model = newModel;
        }
        
        function openForApp(app, mouseX, mouseY) {
            currentApp = app;
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
            
            var closedHandler = function() {
                if (anchor) {
                    anchor.destroy();
                }
                appContextMenu.closed.disconnect(closedHandler);
            };
            appContextMenu.closed.connect(closedHandler);
        }
        
        function close() {
            visible = false;
            currentApp = null;
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

            NTextInput {
                id: searchInput
                placeholderText: "Поиск приложений..."
                inputIconName: "search"
                radius: Style.radiusM       
                Keys.onReturnPressed: {
                    launchCurrentApp();
                }
                
                onTextChanged: {
                    if (isValidApi()) {
                        pluginApi.mainInstance.searchQuery = text;
                        pluginApi.mainInstance.selectedIndex = 0;
                        ensureVisible(0);
                        if (appListView.contentHeight > appListView.height) {
                            appListView.positionViewAtBeginning();
                        }
                    }
                }
                
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        root.forceActiveFocus();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                border.width: Style.borderS
                border.color: Color.mShadow

                ListView {
                    id: appListView
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    model: isValidApi() ? pluginApi.mainInstance.getFilteredApps() : []
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: false 

                    delegate: Item {
                        id: delegateContainer
                        width: appListView.width
                        height: 52
                        
                        readonly property bool isShowAllButton: modelData && modelData.isShowAllButton === true
                        readonly property bool isShowFavoritesButton: modelData && modelData.isShowFavoritesButton === true
                        readonly property bool isNavButton: isShowAllButton || isShowFavoritesButton
                        readonly property bool isSelected: pluginApi && pluginApi.mainInstance && pluginApi.mainInstance.selectedIndex === index
                        
                        Rectangle {
                            id: delegateRect
                            anchors.fill: parent
                            radius: 8
                            border.width: Style.borderS
                            border.color: Color.mOutline
                            color: {
                                if (isNavButton) {
                                    if (delegateMouseArea.containsMouse || isSelected) {
                                        return Color.mHover;
                                    } else {
                                        return Color.mSurfaceVariant;
                                    }
                                } else if (isSelected || delegateMouseArea.containsMouse) {
                                    return Color.mPrimary;
                                } else {
                                    return Color.mSurfaceVariant;
                                }
                            }

                            MouseArea {
                                id: delegateMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                
                                onClicked: function(mouse) {
                                    if (pluginApi && pluginApi.mainInstance) {
                                        pluginApi.mainInstance.selectedIndex = index;
                                        ensureVisible(index);
                                        
                                        if (isNavButton) {
                                            pluginApi.mainInstance.launchApp(modelData);
                                        } else if (mouse.button === Qt.LeftButton) {
                                            pluginApi.mainInstance.launchApp(modelData);
                                        } else if (mouse.button === Qt.RightButton) {
                                            var delegatePos = delegateContainer.mapToItem(root, 0, 0);
                                            var clickX = mouse.x + delegatePos.x;
                                            var clickY = mouse.y + delegatePos.y;
                                            appContextMenu.openForApp(modelData, clickX, clickY);
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
                                    color: 'transparent'
                                    
                                    Image {
                                        id: appIcon
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        fillMode: Image.PreserveAspectFit
                                        source: {
                                            if (isNavButton) {
                                                return "";
                                            }
                                            if (modelData.icon && modelData.icon !== "") {
                                                if (modelData.icon.includes("/")) {
                                                    return "file://" + modelData.icon;
                                                }
                                                return "image://icon/" + modelData.icon;
                                            }
                                            return "";
                                        }
                                        asynchronous: true
                                        visible: !isNavButton && status === Image.Ready && source !== ""
                                    }
                                    
                                    NIcon {
                                        anchors.centerIn: parent
                                        icon: {
                                            if (isShowAllButton) return "apps";
                                            if (isShowFavoritesButton) return "star";
                                            if (!modelData.icon || modelData.icon === "") return "apps";
                                            return getSafeIcon("apps");
                                        }
                                        color: {
                                            if (isNavButton) {
                                                if (delegateMouseArea.containsMouse || isSelected) {
                                                    return Color.mOnSecondary;
                                                } else {
                                                    return Color.mOnSurface;
                                                }
                                            } else if (isSelected || delegateMouseArea.containsMouse) {
                                                return Color.mOnPrimary;
                                            } else {
                                                return Color.mOnSurface;
                                            }
                                        }
                                        pointSize: 28
                                        visible: {
                                            if (isNavButton) return true;
                                            if (!modelData.icon || modelData.icon === "") return true;
                                            return appIcon.status !== Image.Ready || appIcon.source === "";
                                        }
                                    }
                                }
                                
                                NText {
                                    text: {
                                        if (isShowAllButton) return "Все приложения";
                                        if (isShowFavoritesButton) return "Избранное";
                                        return modelData.name || "Unknown";
                                    }
                                    color: {
                                        if (isNavButton) {
                                            if (delegateMouseArea.containsMouse || isSelected) {
                                                return Color.mOnSecondary;
                                            } else {
                                                return Color.mOnSurface;
                                            }
                                        } else if (isSelected || delegateMouseArea.containsMouse) {
                                            return Color.mOnPrimary;
                                        } else {
                                            return Color.mPrimary;
                                        }
                                    }
                                    font.pointSize: Style.fontSizeL
                                    font.weight: {
                                        if (isNavButton) {
                                            if (delegateMouseArea.containsMouse || isSelected) {
                                                return Font.Bold;
                                            } else {
                                                return Font.Medium;
                                            }
                                        } else if (isSelected || delegateMouseArea.containsMouse) {
                                            return Font.Bold;
                                        } else {
                                            return Font.Medium;
                                        }
                                    }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    height: 120
                    visible: {
                        if (!isValidApi()) return true;
                        var filteredApps = pluginApi.mainInstance.getFilteredApps();
                        return getRealAppsCount(filteredApps) === 0;
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginM
                        
                        NIcon {
                            icon: getSafeIcon(getEmptyStateIcon())
                            color: Color.mOnSurfaceVariant
                            width: 64
                            height: 64
                            opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        NText {
                            text: isValidApi() ? getEmptyStateText() : "Нет данных"
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        NText {
                            text: isValidApi() ? getEmptyStateDescription() : "Ожидание данных..."
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
        forceActiveFocus();
        
        if (pluginApi && pluginApi.mainInstance) {
            pluginApi.mainInstance.initializePanel();
            pluginApi.mainInstance.allApps = pluginApi.mainInstance.getAllApps();
            ensureVisible(0);
        }
    }
}