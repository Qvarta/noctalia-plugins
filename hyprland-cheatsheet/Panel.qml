import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    property var rawCategories: pluginApi?.pluginSettings?.cheatsheetData || []
    property var categories: rawCategories
    
    property real contentPreferredWidth: 500
    property real contentPreferredHeight: {
        var hasExpanded = false;
        for (var i = 0; i < categories.length; i++) {
            if (categoryExpanded[i]) {
                hasExpanded = true;
                break;
            }
        }
        
        if (!hasExpanded) {
            return 480;
        } else {
            return 600;
        }
    }
    
    property var categoryExpanded: ({})
    property int currentExpandedIndex: -1

    Component.onCompleted: {
        var expanded = {};
        for (var i = 0; i < categories.length; i++) {
            expanded[i] = false;
        }
        categoryExpanded = expanded;
        currentExpandedIndex = -1;
    }
    
    onCategoriesChanged: {
        var expanded = {};
        for (var i = 0; i < categories.length; i++) {
            expanded[i] = (i === currentExpandedIndex);
        }
        categoryExpanded = expanded;
    }
    
    function toggleCategory(index) {
        var newExpanded = {};
        
        if (currentExpandedIndex === index) {
            for (var i = 0; i < categories.length; i++) {
                newExpanded[i] = false;
            }
            currentExpandedIndex = -1;
        } else {
            for (var i = 0; i < categories.length; i++) {
                newExpanded[i] = (i === index);
            }
            currentExpandedIndex = index;
        }
        
        categoryExpanded = newExpanded;
    }
    
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
            text: pluginApi?.tr("panel.no_data")
            font.pointSize: Style.fontSizeL
            color: Color.mOnSurface
            visible: categories.length === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width * 0.8
        }
        
        Flickable {
            id: flickable
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width - 2 * Style.marginS
            contentWidth: width
            contentHeight: categoriesColumn.height
            boundsBehavior: Flickable.StopAtBounds
            visible: categories.length > 0
            
            onContentHeightChanged: {
                if (contentHeight < height) {
                    contentY = 0;
                }
            }
            
            Column {
                id: categoriesColumn
                width: flickable.width
                spacing: Style.marginS
                
                y: Math.max(0, (flickable.height - height) / 2)
                
                Repeater {
                    model: categories
                    
                    Rectangle {
                        id: categoryContainer
                        width: categoriesColumn.width
                        height: expanded ? 50 + bindsColumn.height + 12 : 50
                        color: "transparent"
                        
                        readonly property bool expanded: categoryExpanded[index] || false
                        
                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                        
                        Rectangle {
                            id: header
                            width: parent.width - 24
                            height: 50
                            radius: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            color: expanded ? Color.mHover : Color.mSurfaceVariant
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.toggleCategory(index)
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: Style.marginL
                                    
                                    NIcon {
                                        id: categoryIcon
                                        icon: pluginApi?.mainInstance?.getCategoryIcon(modelData.title)
                                        pointSize: 20
                                        
                                        // Анимированное изменение цвета иконки
                                        color: expanded ? Color.mOnHover : Color.mPrimary
                                        
                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                        
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    NText {
                                        id: categoryTitle
                                        text: modelData.title
                                        font.pointSize: Style.fontSizeXL
                                        font.weight: Font.Medium
                                        
                                        // Анимированное изменение цвета текста
                                        color: expanded ? Color.mOnHover : Color.mPrimary
                                        
                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                        
                                        width: parent.width - 32
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                        
                        Column {
                            id: bindsColumn
                            width: parent.width - 24
                            anchors.top: header.bottom
                            anchors.topMargin: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2
                            visible: expanded
                            
                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                            
                            Repeater {
                                model: modelData.binds
                                visible: expanded
                                
                                Rectangle {
                                    width: bindsColumn.width
                                    height: 28
                                    color: index % 2 === 0 ? Color.mSurface : Color.mSurfaceVariant
                                    
                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8
                                        
                                        Rectangle {
                                            width: 200
                                            height: 20
                                            anchors.verticalCenter: parent.verticalCenter
                                            clip: true
                                            color: "transparent"
                                            
                                            Row {
                                                height: 20
                                                spacing: 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                
                                                Repeater {
                                                    model: modelData.keys.split(" + ")
                                                    Rectangle {
                                                        width: Math.max(keyText.implicitWidth + 8, 24)
                                                        height: 20
                                                        color: pluginApi?.mainInstance?.getKeyColor(modelData)
                                                        radius: 3
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        
                                                        NText {
                                                            id: keyText
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.pointSize: Style.fontSizeL
                                                            font.weight: Font.Medium
                                                            color: Color.mOnPrimary
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        NText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.desc
                                            font.pointSize: Style.fontSizeL
                                            color: Color.mOnSurface
                                            wrapMode: Text.NoWrap
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                            
                            NText {
                                width: parent.width
                                height: 28
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: pluginApi?.tr("panel.no_data")
                                font.pointSize: 9
                                color: Color.mOnSurfaceVariant
                                visible: modelData.binds.length === 0 && expanded
                            }
                        }
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                width: 8
                policy: ScrollBar.AsNeeded
                visible: false
                active: false
            }
        }
    }
}