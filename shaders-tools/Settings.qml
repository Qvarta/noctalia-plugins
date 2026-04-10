import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property ListModel paramsModel: ListModel {}

    spacing: Style.marginL
    height: 480 * Style.uiScaleRatio

    // Заголовок с кнопками
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // Верхняя панель с заголовком и кнопками
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    text: "Shader Parameters"
                    color: Color.mPrimary
                    font.pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: "add"
                    baseSize: 32
                    onClicked: addNewParameter()
                }

                NIconButton {
                    icon: "device-floppy"
                    baseSize: 32
                    onClicked: saveAllSettings()
                }
            }

            // Список параметров
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurface
                radius: Style.radiusM
                border.color: Color.mOutlineVariant
                border.width: Style.borderS

                ListView {
                    id: paramsListView
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    clip: true
                    spacing: Style.marginS

                    model: paramsModel

                    delegate: Rectangle {
                        id: delegateRect
                        width: paramsListView.width
                        height: rowLayout.implicitHeight + Style.marginS * 2
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS

                        required property var modelData
                        required property int index

                        RowLayout {
                            id: rowLayout
                            anchors.fill: parent
                            anchors.margins: Style.marginS
                            spacing: Style.marginS

                            NComboBox {
                                id: typeBox
                                Layout.fillWidth: true
                                model: [
                                    {
                                        key: "real",
                                        name: "Real"
                                    },
                                    {
                                        key: "color",
                                        name: "Color"
                                    },
                                    {
                                        key: "point",
                                        name: "Point"
                                    }
                                ]
                                currentKey: modelData.type

                                onSelected: function (key) {
                                    paramsModel.setProperty(index, "type", key);
                                    if (key === "color") {
                                        // Если переключились на цвет, проверяем валидность HEX
                                        if (!/^#[0-9A-F]{6}$/i.test(valueInput.text)) {
                                            paramsModel.setProperty(index, "value", "#000000");
                                        }
                                        valueInput.placeholderText = "#RRGGBB";
                                    } else if (key === "point") {
                                        valueInput.placeholderText = "0.5,0.5";
                                    } else {
                                        valueInput.placeholderText = "0.0";
                                    }
                                }
                            }

                            NTextInput {
                                id: nameInput
                                Layout.fillWidth: true
                                Layout.minimumWidth: 120
                                placeholderText: "Parameter name"
                                text: modelData.name
                                onTextChanged: paramsModel.setProperty(index, "name", text)
                            }

                            // NTextInput для обычных типов (real, point)
                            NTextInput {
                                id: valueInput
                                Layout.fillWidth: true
                                Layout.minimumWidth: 100
                                visible: modelData.type !== "color"
                                placeholderText: {
                                    if (modelData.type === "point")
                                        return "0.5,0.5";
                                    return "0.0";
                                }
                                text: modelData.value
                                onTextChanged: {
                                    if (modelData.type !== "color") {
                                        paramsModel.setProperty(index, "value", text);
                                    }
                                }
                            }

                            // NColorPicker для типа color
                            NColorPicker {
                                id: colorPicker
                                width: parent.width
                                visible: modelData.type === "color"

                                selectedColor: {
                                    var colorValue = modelData.value;
                                    if (/^#[0-9A-F]{6}$/i.test(colorValue)) {
                                        return colorValue;
                                    }
                                    return "#000000";
                                }

                                onColorSelected: function (color) {
                                    paramsModel.setProperty(index, "value", color.toString().toUpperCase());
                                }

                                Binding {
                                    target: colorPicker
                                    property: "selectedColor"
                                    value: {
                                        var colorValue = modelData.value;
                                        if (/^#[0-9A-F]{6}$/i.test(colorValue)) {
                                            return colorValue;
                                        }
                                        return "#000000";
                                    }
                                }
                            }

                            NIconButton {
                                icon: "trash"
                                baseSize: 28
                                onClicked: paramsModel.remove(index)
                            }
                        }
                    }

                    // Заглушка, если нет параметров
                    Item {
                        anchors.fill: parent
                        visible: paramsModel.count === 0

                        Text {
                            anchors.centerIn: parent
                            text: "No parameters. Click '+' to add"
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeM
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    function addNewParameter() {
        paramsModel.append({
            "name": "",
            "type": "real",
            "value": ""
        });
    }

    function loadParameters() {
        if (!pluginApi || !pluginApi.pluginSettings) {
            return;
        }

        var loadedParams = pluginApi.pluginSettings.shaderParams;

        if (!loadedParams) {
            loadedParams = [];
        }

        paramsModel.clear();

        for (var i = 0; i < loadedParams.length; i++) {
            // Проверяем валидность цвета при загрузке
            var value = loadedParams[i].value || "";
            if (loadedParams[i].type === "color" && !/^#[0-9A-F]{6}$/i.test(value)) {
                value = "#000000";
            }

            paramsModel.append({
                "name": loadedParams[i].name || "",
                "type": loadedParams[i].type || "real",
                "value": value
            });
        }
    }

    function saveAllSettings() {
        if (!pluginApi) {
            return;
        }

        var validParams = [];
        for (var i = 0; i < paramsModel.count; i++) {
            var param = paramsModel.get(i);

            if (param.name && param.name.trim() !== "" && param.value && param.value.trim() !== "") {
                // Дополнительная валидация для цвета
                var valueToSave = param.value.trim();
                if (param.type === "color" && !/^#[0-9A-F]{6}$/i.test(valueToSave)) {
                    valueToSave = "#000000";
                }

                validParams.push({
                    "name": param.name.trim(),
                    "type": param.type,
                    "value": valueToSave
                });
            }
        }

        pluginApi.pluginSettings.shaderParams = validParams;
        pluginApi.saveSettings();

        if (pluginApi.closePanel) {
            pluginApi.closePanel();
        }
    }

    Component.onCompleted: {
        loadParameters();
    }
}
