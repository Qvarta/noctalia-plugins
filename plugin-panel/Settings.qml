import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import QtQuick.Controls
import qs.Services.UI

ColumnLayout {
    id: root
    property var pluginApi: null
    property string pluginName: ""
    property string pluginId: ""
    property string pluginIcon: "puzzle"
    property int pluginOrder: 0

    spacing: Style.marginL

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 600
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // Заголовок
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    text: "Плагины"
                    color: Color.mPrimary
                    font.pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: "plus"
                    tooltipText: "Добавить плагин"
                    baseSize: Style.baseWidgetSize * 0.9
                    onClicked: {
                        if (pluginApi && pluginApi.mainInstance) {
                            var order = pluginApi.mainInstance.getNextOrderNumber();
                            addPluginPopup.openWithOrder(order);
                        } else {
                            addPluginPopup.open();
                        }
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Список плагинов
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 300
                spacing: Style.marginS
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: true
                model: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance.getSortedPluginsArray() : []

                delegate: Item {
                    id: delegateRoot
                    width: listView.width
                    height: 70

                    // Основной элемент
                    Rectangle {
                        id: delegateRect
                        anchors.fill: parent
                        color: Color.mSurface
                        radius: Style.radiusM
                        border.color: Color.mOutline
                        border.width: Style.borderS
                        opacity: dragArea.drag.active ? 0.5 : 1.0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginM

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 4
                                color: Color.mOutline

                                NIcon {
                                    anchors.centerIn: parent
                                    icon: modelData.data.icon || "puzzle"
                                    color: Color.mPrimary
                                    pointSize: 24
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXS

                                NText {
                                    id: modelName
                                    Layout.fillWidth: true
                                    text: modelData.data.name || "Без названия"
                                    color: Color.mOnSurface
                                    font.pointSize: Style.fontSizeM
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                NText {
                                    Layout.fillWidth: true
                                    text: modelData.data.id || modelData.id
                                    color: Color.mOnSurfaceVariant
                                    font.pointSize: Style.fontSizeXS
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                }
                            }

                            // NIconButton {
                            //     icon: "trash"
                            //     tooltipText: "Удалить плагин"
                            //     baseSize: 32
                            //     onClicked: {
                            //         if (pluginApi && pluginApi.mainInstance) {
                            //             pluginApi.mainInstance.deletePlugin(modelData.id);
                            //             if (root.pluginId === modelData.id) {
                            //                 root.pluginName = "";
                            //                 root.pluginId = "";
                            //                 root.pluginIcon = "puzzle";
                            //                 root.pluginOrder = 0;
                            //             }
                            //         }
                            //     }
                            // }
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            drag.target: dragItem
                            cursorShape: Qt.OpenHandCursor
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onEntered: TooltipService.show(modelName, "ПКМ - удалить")
                            onExited: TooltipService.hide()

                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (pluginApi && pluginApi.mainInstance) {
                                        pluginApi.mainInstance.deletePlugin(modelData.id);
                                        if (root.pluginId === modelData.id) {
                                            root.pluginName = "";
                                            root.pluginId = "";
                                            root.pluginIcon = "puzzle";
                                            root.pluginOrder = 0;
                                        }
                                    }
                                    mouse.accepted = true;
                                }
                            }

                            onPressed: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    mouse.accepted = true;
                                    return;
                                }

                                delegateRoot.z = 2;
                                dragItem.startDrag(modelData.id, index);
                                dragItem.x = 0;
                                dragItem.y = 0;
                                dragItem.width = delegateRect.width;
                                dragItem.height = delegateRect.height;
                                dragItem.visible = true;
                                dragItem.dragActive = true;
                            }

                            onReleased: {
                                if (dragItem.dragActive) {
                                    var dropIndex = Math.floor((dragItem.y + dragItem.height / 2) / delegateRect.height);
                                    dropIndex = Math.max(0, Math.min(listView.count - 1, dropIndex));

                                    if (dropIndex !== index && pluginApi && pluginApi.mainInstance) {
                                        pluginApi.mainInstance.movePlugin(modelData.id, dropIndex);
                                    }
                                }
                                delegateRoot.z = 0;
                                dragItem.visible = false;
                                dragItem.dragActive = false;
                                dragItem.draggedId = "";
                                dragItem.originalIndex = -1;
                            }
                        }
                    }

                    // копия элемента для перетаскивания
                    Rectangle {
                        id: dragItem
                        visible: false
                        z: 100
                        color: Color.mSurface
                        radius: Style.radiusM
                        border.color: Color.mPrimary
                        border.width: Style.borderM
                        opacity: 0.95

                        property bool dragActive: false
                        property string draggedId: ""
                        property int originalIndex: -1

                        function startDrag(id, idx) {
                            draggedId = id;
                            originalIndex = idx;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginM

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Color.mPrimary
                                opacity: 0.3

                                NIcon {
                                    anchors.centerIn: parent
                                    icon: modelData.data.icon || "puzzle"
                                    color: Color.mPrimary
                                    pointSize: 24
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXS

                                NText {
                                    Layout.fillWidth: true
                                    text: modelData.data.name || "Без названия"
                                    color: Color.mPrimary
                                    font.pointSize: Style.fontSizeM
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                NText {
                                    Layout.fillWidth: true
                                    text: modelData.data.id || modelData.id
                                    color: Color.mPrimary
                                    font.pointSize: Style.fontSizeXS
                                    opacity: 0.8
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        states: State {
                            when: dragItem.dragActive
                            ParentChange {
                                target: dragItem
                                parent: listView
                            }
                            AnchorChanges {
                                target: dragItem
                                anchors.horizontalCenter: undefined
                                anchors.verticalCenter: undefined
                            }
                        }

                        onXChanged: {
                            if (dragActive) {
                                updateDropIndicator();
                            }
                        }

                        onYChanged: {
                            if (dragActive) {
                                updateDropIndicator();
                            }
                        }

                        function updateDropIndicator() {
                            var currentIndex = Math.floor((dragItem.y + dragItem.height / 2) / delegateRect.height);
                            currentIndex = Math.max(0, Math.min(listView.count - 1, currentIndex));

                            for (var i = 0; i < listView.count; i++) {
                                var item = listView.itemAtIndex(i);
                                if (item && item.dropIndicator) {
                                    if (currentIndex === i && currentIndex !== originalIndex) {
                                        var indicatorY = currentIndex > originalIndex ? item.height - 1 : -1;
                                        item.dropIndicator.visible = true;
                                        item.dropIndicator.y = indicatorY;
                                    } else {
                                        item.dropIndicator.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }

                // Пустой список
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    height: 120
                    visible: listView.count === 0
                    color: "transparent"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginM

                        NIcon {
                            icon: "puzzle"
                            color: Color.mOnSurfaceVariant
                            pointSize: 32
                            opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }

                        NText {
                            text: "Нет доступных плагинов"
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter
                        }

                        NText {
                            text: "Плагины будут отображаться здесь"
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeS
                            opacity: 0.7
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    AddPluginPopup {
        id: addPluginPopup
        pluginApi: root.pluginApi
        pluginName: root.pluginName
        pluginId: root.pluginId
        pluginIcon: root.pluginIcon
        pluginOrder: root.pluginOrder

        onPluginNameChanged: root.pluginName = pluginName
        onPluginIdChanged: root.pluginId = pluginId
        onPluginIconChanged: root.pluginIcon = pluginIcon
        onPluginOrderChanged: root.pluginOrder = pluginOrder
    }

    function savePlugin() {
        addPluginPopup.savePlugin();
    }
    function saveSettings() {
        savePlugin();
    }

    Connections {
        target: pluginApi ? pluginApi.mainInstance : null
        enabled: pluginApi !== null && pluginApi.mainInstance !== null

        function onPluginsListChanged() {
            listView.model = pluginApi.mainInstance.getSortedPluginsArray();
        }
    }
}
