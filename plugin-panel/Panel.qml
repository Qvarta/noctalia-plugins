import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null

    property real contentPreferredWidth: 360 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    readonly property real buttonHeight: 52 * Style.uiScaleRatio
    readonly property real buttonSpacing: 4 * Style.uiScaleRatio
    readonly property real verticalMargins: Style.marginM * Style.uiScaleRatio * 2

    property var buttonModel: []

    property real contentPreferredHeight: (buttonModel.length * buttonHeight) + ((buttonModel.length - 1) * buttonSpacing) + 2 * verticalMargins + headerHeight + (20 * Style.uiScaleRatio * 2)

    width: contentPreferredWidth
    height: contentPreferredHeight

    readonly property var geometryPlaceholder: panelContainer

    property int currentIndex: 0
    readonly property real headerHeight: 52 * Style.uiScaleRatio
    readonly property real panelMargin: 20 * Style.uiScaleRatio

    function updatePluginsModel() {
        if (!pluginApi || !pluginApi.mainInstance) {
            buttonModel = [];
            return;
        }

        var pluginsObj = pluginApi.mainInstance.getPluginsList();

        if (!pluginsObj) {
            buttonModel = [];
            return;
        }

        var pluginsList = [];

        for (var pluginId in pluginsObj) {
            if (pluginsObj.hasOwnProperty(pluginId)) {
                var plugin = pluginsObj[pluginId];
                pluginsList.push({
                    id: pluginId,
                    displayName: plugin.name || pluginId,
                    icon: plugin.icon || "puzzle",
                    order: plugin.order !== undefined ? plugin.order : Number.MAX_VALUE
                });
            }
        }
        
        // Сортировка по полю order
        pluginsList.sort(function(a, b) {
            return a.order - b.order;
        });

        buttonModel = pluginsList;

        if (currentIndex >= buttonModel.length) {
            currentIndex = Math.max(0, buttonModel.length - 1);
        }
    }

    function openPlugin(index) {
        if (index >= 0 && index < buttonModel.length) {
            var main = pluginApi.mainInstance;
            if (main && main.openPluginPanel) {
                main.openPluginPanel(buttonModel[index].id);
            }
        }
    }

    function moveSelection(delta) {
        var newIndex = currentIndex + delta;
        if (newIndex >= 0 && newIndex < buttonModel.length) {
            currentIndex = newIndex;

            var targetY = currentIndex * (buttonHeight + buttonSpacing);
            var viewportHeight = flickable.height;

            if (targetY < flickable.contentY) {
                flickable.contentY = targetY;
            } else if (targetY + buttonHeight > flickable.contentY + viewportHeight) {
                flickable.contentY = targetY + buttonHeight - viewportHeight;
            }
        }
    }

    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: openPlugin(currentIndex)
    Keys.onEnterPressed: openPlugin(currentIndex)

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        anchors.margins: Style.marginS
        color: Color.mSurface
        radius: Style.radiusM
        border.width: Style.borderS
        border.color: Color.mOutline
        clip: true

        Column {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: panelMargin
            spacing: panelMargin

            Rectangle {
                width: parent.width
                height: headerHeight
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
                            id: puzzleIcon
                            icon: "puzzle"
                            anchors.centerIn: parent
                            pointSize: Style.fontSizeXL * 1.2
                            color: Color.mPrimary
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        NText {
                            text: "Плагины"
                            font.weight: Font.Bold
                            font.pointSize: Style.fontSizeXL * 1.1
                            color: Color.mOnSurface
                        }

                        NText {
                            text: "Быстрый запуск"
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

            Flickable {
                id: flickable
                width: parent.width
                height: parent.height - headerHeight - panelMargin
                contentWidth: width
                contentHeight: buttonsColumn.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: buttonsColumn
                    width: parent.width
                    spacing: buttonSpacing

                    y: Math.max(0, (flickable.height - height) / 2)

                    Repeater {
                        model: buttonModel

                        Rectangle {
                            id: buttonContainer
                            width: buttonsColumn.width
                            height: buttonHeight
                            radius: 8
                            color: "transparent"
                            visible: buttonModel.length > 0

                            readonly property bool isSelected: index === currentIndex
                            readonly property bool isHovered: mouseArea.containsMouse

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }

                            Rectangle {
                                id: buttonRect
                                anchors.fill: parent
                                radius: 8

                                color: (mouseArea.containsMouse || isSelected) ? Color.mHover : Color.mSurfaceVariant

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

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
                                        root.openPlugin(index);
                                    }
                                }

                                Row {
                                    id: buttonRow
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: Style.marginL

                                    NIcon {
                                        id: buttonIcon
                                        icon: modelData.icon
                                        pointSize: 20

                                        color: (mouseArea.containsMouse || isSelected) ? Color.mOnHover : Color.mPrimary

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    NText {
                                        id: buttonText
                                        text: modelData.displayName
                                        font.pointSize: Style.fontSizeXL
                                        font.weight: Font.Medium

                                        color: (mouseArea.containsMouse || isSelected) ? Color.mOnHover : Color.mPrimary

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - buttonIcon.width - 32 - (Style.marginL * 2)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: flickable.height
                        visible: buttonModel.length === 0
                        color: "transparent"

                        Column {
                            anchors.centerIn: parent
                            spacing: Style.marginM

                            NIcon {
                                icon: "puzzle"
                                color: Color.mOnSurfaceVariant
                                pointSize: 48
                                opacity: 0.5
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            NText {
                                text: "Нет доступных плагинов"
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeM
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            NText {
                                text: "Нажмите на иконку настроек чтобы добавить"
                                color: Color.mOnSurfaceVariant
                                font.pointSize: Style.fontSizeS
                                opacity: 0.7
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: pluginApi ? pluginApi.mainInstance : null
        enabled: pluginApi !== null && pluginApi.mainInstance !== null
        
        function onPluginsListChanged() {
            updatePluginsModel();
        }
    }

    onPluginApiChanged: {
        updatePluginsModel();
    }

    Component.onCompleted: {
        updatePluginsModel();
        forceActiveFocus();
    }
}