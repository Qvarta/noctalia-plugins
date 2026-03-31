import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import QtQuick.Controls

ColumnLayout {
    id: root
    property var pluginApi: null
    property string pluginName: ""
    property string pluginId: ""
    property string pluginIcon: "puzzle"

    spacing: Style.marginL

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 350
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NText {
                text: "Плагины"
                color: Color.mPrimary
                font.pointSize: Style.fontSizeL
                font.weight: Font.Bold
            }
            
            NDivider {
                Layout.fillWidth: true
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
                
                model: {
                    if (pluginApi && pluginApi.mainInstance) {
                        var plugins = pluginApi.mainInstance.getPluginsList();
                        var pluginsList = Object.keys(plugins);
                        return ["__add_plugin__"].concat(pluginsList);
                    }
                    return ["__add_plugin__"];
                }
                
                cellWidth: 120
                cellHeight: 140
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                delegate: Rectangle {
                    width: gridView.cellWidth - Style.marginM
                    height: gridView.cellHeight - Style.marginM
                    color: {
                        if (modelData === "__add_plugin__") {
                            return addMouseArea.containsMouse ? Color.mPrimary : Color.mSurface
                        } else {
                            return deleteMouseArea.containsMouse ? Color.mPrimary : Color.mSurface
                        }
                    }
                    radius: Style.radiusM
                    border.color: Color.mOutline
                    border.width: Style.borderS
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    Rectangle {
                        id: deleteButton
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: Style.marginXS
                        }
                        width: 24
                        height: 24
                        radius: 12
                        color: deleteMouseArea.containsMouse ? Color.mError : Color.mSurfaceVariant
                        visible: modelData !== "__add_plugin__" && deleteMouseArea.containsMouse
                        z: 1
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        NIcon {
                            anchors.centerIn: parent
                            icon: "trash"
                            color: deleteMouseArea.containsMouse ? Color.mOnError : Color.mError
                            pointSize: 14
                        }
                    }
                    
                    MouseArea {
                        id: deleteMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: modelData !== "__add_plugin__"
                        onClicked: {
                            var plugins = pluginApi.mainInstance.getPluginsList();
                            if (plugins[modelData]) {
                                delete plugins[modelData];
                                pluginApi.pluginSettings.plugins = plugins;
                                pluginApi.saveSettings();
                                
                                if (root.pluginId === modelData) {
                                    root.pluginName = "";
                                    root.pluginId = "";
                                    root.pluginIcon = "puzzle";
                                }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: addMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: modelData === "__add_plugin__"
                        onClicked: {
                            root.pluginName = "";
                            root.pluginId = "";
                            root.pluginIcon = "puzzle";
                            addPluginPopup.open();
                        }
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.marginS
                        spacing: Style.marginS
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: "transparent"
                            
                            NIcon {
                                anchors.centerIn: parent
                                icon: {
                                    if (modelData === "__add_plugin__") {
                                        return "plus"
                                    } else {
                                        var plugins = pluginApi.mainInstance.getPluginsList();
                                        return plugins[modelData].icon || "puzzle";
                                    }
                                }
                                color: {
                                    if (modelData === "__add_plugin__") {
                                        return addMouseArea.containsMouse ? Color.mOnPrimary : Color.mPrimary
                                    } else {
                                        return deleteMouseArea.containsMouse ? Color.mOnPrimary : Color.mPrimary
                                    }
                                }
                                pointSize: 32
                            }
                        }
                        
                        NText {
                            Layout.fillWidth: true
                            text: {
                                if (modelData === "__add_plugin__") {
                                    return "Добавить плагин"
                                } else {
                                    var plugins = pluginApi.mainInstance.getPluginsList();
                                    return plugins[modelData].name || "Без названия";
                                }
                            }
                            color: {
                                if (modelData === "__add_plugin__") {
                                    return addMouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurface
                                } else {
                                    return deleteMouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurface
                                }
                            }
                            font.pointSize: Style.fontSizeS
                            font.weight: {
                                if (modelData === "__add_plugin__") {
                                    return addMouseArea.containsMouse ? Font.Bold : Font.Normal
                                } else {
                                    return deleteMouseArea.containsMouse ? Font.Bold : Font.Normal
                                }
                            }
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                        }
                        
                        NText {
                            Layout.fillWidth: true
                            text: {
                                if (modelData === "__add_plugin__") {
                                    return ""
                                } else {
                                    var plugins = pluginApi.mainInstance.getPluginsList();
                                    return plugins[modelData].id || modelData;
                                }
                            }
                            color: {
                                if (modelData === "__add_plugin__") {
                                    return Color.mOnSurfaceVariant
                                } else {
                                    return deleteMouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurfaceVariant
                                }
                            }
                            font.pointSize: Style.fontSizeXS
                            opacity: 0.7
                            horizontalAlignment: Text.AlignHCenter
                            visible: modelData !== "__add_plugin__" && deleteMouseArea.containsMouse
                        }
                    }
                }
                
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    height: 120
                    visible: gridView.count === 1 && model[0] === "__add_plugin__" && (!pluginApi || !pluginApi.mainInstance || Object.keys(pluginApi.mainInstance.getPluginsList()).length === 0)
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
                            text: "Нажмите + чтобы добавить"
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
    
    Popup {
        id: addPluginPopup
        visible: false
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        padding: 0
        margins: 10
        
        x: -width - 20
        y: 0
        
        width: 500
        height: popupContent.height + 60
        
        background: Rectangle {
            color: Color.mSurfaceVariant
            radius: Style.radiusM
            border.color: Color.mPrimary
            border.width: Style.borderM
        }
        
        Column {
            id: popupContent
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: Style.marginM
            
            Column {
                width: parent.width
                spacing: Style.marginXS
                
                NText {
                    text: "Добавить плагин"
                    color: Color.mPrimary
                    font.pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                }
                
                NDivider {
                    width: parent.width
                }
            }
            
            RowLayout {
                width: parent.width
                spacing: Style.marginM
                
                Rectangle {
                    id: iconBlock
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    color: iconMouseArea.containsMouse ? Color.mPrimary : Color.mSurface
                    radius: Style.radiusM
                    border.color: Color.mOutline
                    border.width: Style.borderS
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: root.pluginIcon
                        color: iconMouseArea.containsMouse ? Color.mOnPrimary : Color.mPrimary
                        pointSize: 40
                    }
                    
                    MouseArea {
                        id: iconMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            iconPicker.open();
                        }
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS
                    
                    NTextInput {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        label: "Отображаемое имя"
                        placeholderText: "Имя плагина"
                        text: root.pluginName
                        onTextChanged: root.pluginName = text
                    }
                    
                    NTextInput {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        label: "Уникальный идентификатор ID"
                        placeholderText: "id плагина"
                        text: root.pluginId
                        onTextChanged: root.pluginId = text
                    }
                }
            }
            
            RowLayout {
                width: parent.width
                spacing: Style.marginM
                Layout.alignment: Qt.AlignRight
                
                Item {
                    Layout.fillWidth: true
                }
                
                NButton {
                    text: "Отмена"
                    onClicked: {
                        addPluginPopup.close();
                        root.pluginName = "";
                        root.pluginId = "";
                        root.pluginIcon = "puzzle";
                    }
                }
                
                NButton {
                    text: "Сохранить"
                    enabled: root.pluginName !== "" && root.pluginId !== ""
                    onClicked: {
                        savePlugin();
                        addPluginPopup.close();
                    }
                }
            }
        }
    }

    NIconPicker {
        id: iconPicker
        onIconSelected: function(icon) {
            root.pluginIcon = icon;
        }
    }
    
    function savePlugin() {
        if (!pluginApi) {
            return;
        }
        
        if (root.pluginName !== "" && root.pluginId !== "") {
            var pluginKey = root.pluginId;
            
            if (!pluginApi.pluginSettings.plugins) {
                pluginApi.pluginSettings.plugins = {};
            }
            
            pluginApi.pluginSettings.plugins[pluginKey] = {
                name: root.pluginName,
                id: root.pluginId,
                icon: root.pluginIcon || "puzzle"
            };
            
            pluginApi.saveSettings();
        }
        
        root.pluginName = "";
        root.pluginId = "";
        root.pluginIcon = "puzzle";
        
        if (pluginApi.closePanel) {
            pluginApi.closePanel();
        }
    }
    
    function saveSettings() {
        savePlugin();
    }
}