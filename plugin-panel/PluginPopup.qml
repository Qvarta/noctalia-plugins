import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import QtQuick.Controls

Popup {
    id: root
    property var pluginApi: null
    property string pluginName: ""
    property string pluginId: ""
    property string pluginIcon: "puzzle"
    property int pluginOrder: 0
    
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
                    ColorAnimation {
                        duration: 150
                    }
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
                    root.close();
                    root.resetForm();
                }
            }

            NButton {
                text: "Сохранить"
                enabled: root.pluginName !== "" && root.pluginId !== ""
                onClicked: {
                    savePlugin();
                    root.close();
                }
            }
        }
    }

    NIconPicker {
        id: iconPicker
        onIconSelected: function (icon) {
            root.pluginIcon = icon;
        }
    }

    function savePlugin() {
        if (!pluginApi || !pluginApi.mainInstance) {
            return;
        }

        if (pluginName !== "" && pluginId !== "") {
            var pluginKey = pluginId;

            if (!pluginApi.pluginSettings.plugins) {
                pluginApi.pluginSettings.plugins = {};
            }

            pluginApi.pluginSettings.plugins[pluginKey] = {
                name: pluginName,
                id: pluginId,
                icon: pluginIcon || "puzzle",
                order: pluginOrder
            };

            pluginApi.saveSettings();
        }

        resetForm();

        if (pluginApi.closePanel) {
            pluginApi.closePanel();
        }
    }

    function resetForm() {
        pluginName = "";
        pluginId = "";
        pluginIcon = "puzzle";
        pluginOrder = 0;
    }

    function openWithOrder(order) {
        pluginOrder = order;
        open();
    }
}