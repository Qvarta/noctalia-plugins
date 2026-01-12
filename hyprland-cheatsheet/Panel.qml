import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    property var rawCategories: pluginApi?.pluginSettings?.cheatsheetData || []
    property var categories: rawCategories
    
    property int columnCount: {
        if (width < 800) return 1;
        if (width < 1200) return 2;
        return 3;
    }
    
    onRawCategoriesChanged: {
        updateColumnItems();
    }
    
    function updateColumnItems() {
        var columns = [];
        for (var i = 0; i < columnCount; i++) {
            columns.push([]);
        }
        
        var sortedCategories = [];
        for (var i = 0; i < categories.length; i++) {
            sortedCategories.push({
                index: i,
                bindCount: categories[i].binds.length
            });
        }
        
        sortedCategories.sort((a, b) => b.bindCount - a.bindCount);
        
        var columnHeights = new Array(columnCount).fill(0);
        
        for (var i = 0; i < sortedCategories.length; i++) {
            var catIndex = sortedCategories[i].index;
            var weight = categories[catIndex].binds.length + 1;
            
            var minHeight = columnHeights[0];
            var minColumn = 0;
            for (var c = 1; c < columnCount; c++) {
                if (columnHeights[c] < minHeight) {
                    minHeight = columnHeights[c];
                    minColumn = c;
                }
            }
            
            columns[minColumn].push(catIndex);
            columnHeights[minColumn] += weight;
        }
        
        columnRepeater.model = columnCount;
    }
    
    property real contentPreferredWidth: 1300
    property real contentPreferredHeight: 880
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: false 
    readonly property bool panelAnchorHorizontalCenter: true
    readonly property bool panelAnchorVerticalCenter: true
    anchors.fill: parent
    
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusL
        clip: true
        
        NText {
            id: emptyText
            anchors.centerIn: parent
            text: pluginApi?.tr("panel.no_data") || "No data available"
            font.pointSize: Style.fontSizeL
            color: Color.mOnSurface
            visible: categories.length === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width * 0.8
        }
        
        GridLayout {
            id: mainLayout
            visible: root.categories.length > 0
            anchors.fill: parent
            anchors.margins: Style.marginL
            columns: columnCount
            columnSpacing: Style.marginL
            rowSpacing: Style.marginM
            
            Repeater {
                id: columnRepeater
                model: columnCount
                
                ColumnLayout {
                    id: column
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Style.marginM
                    
                    property var columnCategories: {
                        var result = [];
                        var categoriesPerColumn = Math.ceil(categories.length / columnCount);
                        var startIndex = index * categoriesPerColumn;
                        var endIndex = Math.min(startIndex + categoriesPerColumn, categories.length);
                        
                        for (var i = startIndex; i < endIndex; i++) {
                            result.push(i);
                        }
                        return result;
                    }
                    
                    Repeater {
                        model: column.columnCategories
                        
                        Rectangle {
                            id: categoryContainer
                            Layout.fillWidth: true
                            Layout.minimumHeight: categoryContent.implicitHeight + 24
                            radius: 12
                            color: Color.mSurfaceVariant
                            opacity: 0.9
                            
                            ColumnLayout {
                                id: categoryContent
                                width: parent.width - 24
                                anchors.centerIn: parent
                                spacing: 0
                                
                                Rectangle {
                                    id: categoryHeader
                                    Layout.fillWidth: true
                                    height: 50
                                    radius: 8
                                    color: Qt.lighter(Color.mSurfaceVariant, 1.2)
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: Style.marginS
                                        
                                    NIcon {
                                        icon: pluginApi?.mainInstance?.getCategoryIcon(categories[modelData].title) || "keyboard-filled"
                                        pointSize: 22
                                        color: Color.mOnSurfaceVariant
                                    }
                                        
                                        NText {
                                            text: categories[modelData].title
                                            font.pointSize: 12
                                            font.weight: Font.Medium
                                            color: Color.mOnSurfaceVariant
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    id: bindsContainer
                                    Layout.fillWidth: true
                                    Layout.topMargin: 12
                                    Layout.preferredHeight: Math.min(bindsContent.implicitHeight + 16, 320) // Максимальная высота 320 (примерно 8 строк * 36 + отступы)
                                    radius: 8
                                    color: Color.mSurface
                                    clip: true // Важно для корректного отображения прокрутки

                                    Flickable {
                                        id: bindsFlickable
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        contentWidth: parent.width - 16
                                        contentHeight: bindsContent.implicitHeight
                                        boundsBehavior: Flickable.StopAtBounds
                                        clip: true

                                        ColumnLayout {
                                            id: bindsContent
                                            width: parent.width
                                            spacing: 4
                                            
                                            // Тот же самый Repeater с биндами остается здесь
                                            Repeater {
                                                model: categories[modelData].binds
                                                
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 36
                                                    radius: 6
                                                    color: index % 2 === 0 ? "transparent" : Qt.lighter(Color.mSurfaceVariant, 1.1)
                                                    
                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 8
                                                        spacing: Style.marginM
                                                        
                                                        Flow {
                                                            Layout.preferredWidth: 180
                                                            Layout.alignment: Qt.AlignVCenter
                                                            spacing: 4
                                                            
                                                            Repeater {
                                                                model: modelData.keys.split(" + ")
                                                                Rectangle {
                                                                    width: Math.max(keyText.implicitWidth + 12, 28)
                                                                    height: 24
                                                                    color: pluginApi?.mainInstance?.getKeyColor(modelData) || Qt.lighter(Color.mPrimary, 1.3)
                                                                    radius: 4
                                                                    
                                                                    NText {
                                                                        id: keyText
                                                                        anchors.centerIn: parent
                                                                        text: modelData
                                                                        font.pointSize: {
                                                                            if (modelData.length > 12) return 8;
                                                                            if (modelData.length > 8) return 9;
                                                                            return 10;
                                                                        }
                                                                        font.weight: Font.Medium
                                                                        color: Color.mOnPrimary
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        
                                                        NText {
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignVCenter
                                                            text: modelData.desc
                                                            font.pointSize: 11
                                                            color: Color.mOnSurface
                                                            wrapMode: Text.WrapAnywhere
                                                            maximumLineCount: 2
                                                            elide: Text.ElideRight
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            NText {
                                                Layout.fillWidth: true
                                                Layout.topMargin: 12
                                                Layout.bottomMargin: 12
                                                horizontalAlignment: Text.AlignHCenter
                                                text: pluginApi?.tr("panel.no_binds") || "No keybindings"
                                                font.pointSize: 10
                                                color: Color.mOnSurfaceVariant
                                                visible: categories[modelData].binds.length === 0
                                            }
                                        }
                                        
                                        ScrollBar.vertical: ScrollBar {
                                            width: 8
                                            policy: ScrollBar.AsNeeded
                                            visible: bindsFlickable.contentHeight > bindsFlickable.height
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}