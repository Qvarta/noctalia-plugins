import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets
import QtQuick.Controls
import qs.Services.UI

DraggableDesktopWidget {
    id: root

    property var pluginApi: null
    property string shaderPath: "Shaders/qsb/test.qsb"

    property int shaderAreaHeight: Math.round(300 * widgetScale)
    property int parametersHeight: Math.max(Math.round(40 * widgetScale), Math.min(Math.round(200 * widgetScale), parametersListModel.count * Math.round(28 * widgetScale) + Math.round(40 * widgetScale)))

    implicitWidth: Math.round(400 * widgetScale)
    implicitHeight: shaderAreaHeight + parametersHeight + Math.round(60 * widgetScale)
    width: implicitWidth
    height: implicitHeight

    function updateParametersDisplay() {
        if (!pluginApi || !pluginApi.pluginSettings || !parametersListModel) {
            return;
        }

        var paramsList = pluginApi.pluginSettings.shaderParams;
        if (!paramsList || paramsList.length === 0) {
            parametersListModel.clear();
            return;
        }

        parametersListModel.clear();

        for (var i = 0; i < paramsList.length; i++) {
            var param = paramsList[i];
            if (param.name && param.type && param.value) {
                parametersListModel.append({
                    paramName: param.name,
                    paramType: param.type,
                    paramValue: param.value
                });
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        color: Color.mSurface

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Заголовок
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(40 * widgetScale)
                color: Color.mSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(12 * widgetScale)
                    anchors.rightMargin: Math.round(12 * widgetScale)
                    spacing: Math.round(8 * widgetScale)

                    NText {
                        text: "Shader Tester - " + shaderPath.split('/').pop()
                        color: Color.mOnSurface
                        pointSize: Math.round(Style.fontSizeM * widgetScale)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    NIconButton {
                        icon: "refresh"
                        baseSize: Math.round(28 * widgetScale)
                        onClicked: {
                            if (contentLoader.item) {
                                contentLoader.item.reloadShader();
                                updateParametersDisplay();
                            }
                        }
                    }

                    NIconButton {
                        icon: "settings"
                        baseSize: Math.round(28 * widgetScale)
                        onClicked: {
                            BarService.openPluginSettings(screen, pluginApi.manifest);
                        }
                    }

                    NIconButton {
                        icon: "resize"
                        baseSize: Math.round(28 * widgetScale)
                        onClicked: {
                            DesktopWidgetRegistry.editMode = !DesktopWidgetRegistry.editMode;
                            if (DesktopWidgetRegistry.editMode && Settings.data.ui.settingsPanelMode !== "window") {
                                var item = root.parent;
                                while (item) {
                                    if (item.closeRequested !== undefined) {
                                        item.closeRequested();
                                        break;
                                    }
                                    item = item.parent;
                                }
                            }
                        }
                    }
                }
            }

            // Основная область с шейдером
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: shaderAreaHeight
                color: 'transparent'
                border.color: Color.mOutline
                border.width: 2
                radius: 10

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: Math.round(8 * widgetScale)
                    active: true
                    sourceComponent: contentComponent
                    asynchronous: !root.isScaling
                }
            }

            // Контейнер с параметрами шейдера
            Rectangle {
                id: parametersContainer
                Layout.fillWidth: true
                Layout.preferredHeight: parametersHeight
                Layout.topMargin: Math.round(4 * widgetScale)
                visible: parametersListModel.count > 0
                color: Color.mSurfaceVariant
                border.color: Color.mOutline
                border.width: 1
                radius: 8

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(8 * widgetScale)
                    spacing: Math.round(4 * widgetScale)

                    NText {
                        text: "Shader Parameters (" + parametersListModel.count + ")"
                        color: Color.mPrimary
                        pointSize: Math.round(Style.fontSizeS * widgetScale)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        clip: true

                        ScrollView {
                            id: parametersScroll
                            anchors.fill: parent
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded

                            ListView {
                                id: parametersListView
                                width: parametersScroll.availableWidth
                                model: ListModel {
                                    id: parametersListModel
                                }
                                spacing: Math.round(4 * widgetScale)

                                implicitHeight: contentHeight
                                height: contentHeight

                                delegate: Rectangle {
                                    width: parametersListView.width
                                    height: Math.round(24 * widgetScale)
                                    color: index % 2 === 0 ? Color.mSurfaceVariant : "transparent"
                                    radius: 4

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(8 * widgetScale)
                                        anchors.rightMargin: Math.round(8 * widgetScale)
                                        spacing: Math.round(8 * widgetScale)

                                        NText {
                                            text: paramName
                                            color: Color.mOnSurfaceVariant
                                            pointSize: Math.round(Style.fontSizeXS * widgetScale)
                                            font.bold: true
                                            Layout.preferredWidth: Math.round(100 * widgetScale)
                                        }

                                        NText {
                                            text: "(" + paramType + ")"
                                            color: Color.mPrimary
                                            pointSize: Math.round(Style.fontSizeXS * widgetScale)
                                            Layout.preferredWidth: Math.round(60 * widgetScale)
                                        }

                                        NText {
                                            text: paramValue
                                            color: Color.mOnSurface
                                            pointSize: Math.round(Style.fontSizeXS * widgetScale)
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Пустая заглушка когда нет параметров
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(40 * widgetScale)
                Layout.topMargin: Math.round(8 * widgetScale)
                visible: parametersListModel.count === 0
                color: Color.mSurfaceVariant
                border.color: Color.mOutline
                border.width: 1
                radius: 8

                NText {
                    anchors.centerIn: parent
                    text: "No parameters available"
                    color: Color.mOnSurfaceVariant
                    pointSize: Math.round(Style.fontSizeXS * widgetScale)
                }
            }
        }
    }

Component {
    id: contentComponent

    Item {
        id: shaderContainer
        anchors.fill: parent

        function getParam(name, defaultValue, transformFn) {
            var params = pluginApi?.pluginSettings?.shaderParams;
            if (!params)
                return defaultValue;

            for (var i = 0; i < params.length; i++) {
                if (params[i].name === name && params[i].value !== undefined) {
                    var value = params[i].value;
                    return transformFn ? transformFn(value) : value;
                }
            }
            return defaultValue;
        }

        function getShaderEffect() {
            return rainShader;
        }

        function reloadShader() {
            var timestamp = new Date().getTime();
            var shaderUrl = Qt.resolvedUrl(root.shaderPath) + "?" + timestamp;
            rainShader.fragmentShader = shaderUrl;
        }

        // ДОБАВИТЬ: изображение для текстуры
        Image {
            id: sourceImage
            source: "PNG/FM.png" 
            // sourceSize: Qt.size(42, 42)
            visible: false
        }

        ShaderEffect {
            id: rainShader
            anchors.fill: parent

            // Стандартные свойства шейдера
            property real time: shaderContainer.shaderTime
            property vector2d resolution: Qt.vector2d(width, height) 
            property real mouseX: area.mouseX / width
            property real mouseY: area.mouseY / height
            property var source: sourceImage  // ← ИЗМЕНИТЬ: sourceImage вместо null
            property color bgWidget: Color.mSurface

            // Пользовательские параметры с автоматическим обновлением через биндинги
            property color bgColor: shaderContainer.getParam("bgColor", "blue")
            property color bgColor1: shaderContainer.getParam("bgColor1", "white")
            property color bgColor2: shaderContainer.getParam("bgColor2", "red")
            property point center: shaderContainer.getParam("center", Qt.point(0, 0), function (v) {
                var parts = v.split(',');
                return Qt.point(parseFloat(parts[0]), parseFloat(parts[1]));
            })
            property real scale: shaderContainer.getParam("scale", 1.0, parseFloat)
            property real size: shaderContainer.getParam("size", 0.3, parseFloat)

            fragmentShader: Qt.resolvedUrl(root.shaderPath)

            onFragmentShaderChanged: {
                shaderContainer.frameCount++;
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
        }

        Rectangle {
            anchors.top: parent.top
            anchors.margins: 8
            opacity: 0.8

            Column {
                spacing: 4

                NText {
                    text: "Mouse: " + Math.round(area.mouseX) + ", " + Math.round(area.mouseY)
                    color: Color.mPrimary
                    pointSize: 10
                }
            }
        }

        property real shaderTime: 0
        property int frameCount: 0

        NumberAnimation on shaderTime {
            loops: Animation.Infinite
            from: 0
            to: 1000
            duration: 100000
        }

        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                updateParametersDisplay();
            }
        }

        onFrameCountChanged: {
            updateTimer.restart();
        }
    }
}

    Behavior on implicitHeight {
        enabled: !isScaling && !isDragging
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on opacity {
        enabled: !isScaling && !isDragging
        NumberAnimation {
            duration: 200
        }
    }
}
