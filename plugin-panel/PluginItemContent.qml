import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
    id: root
    
    property var pluginData: ({})
    property color iconBgColor: Color.mOutline
    property color iconColor: Color.mPrimary
    property color textColor: Color.mOnSurface
    property real iconRadius: 4
    property real iconOpacity: 1.0
    
    spacing: Style.marginM
    
    Rectangle {
        width: 40
        height: 40
        radius: root.iconRadius
        color: root.iconBgColor
        opacity: root.iconOpacity
        
        NIcon {
            anchors.centerIn: parent
            icon: root.pluginData.icon || "puzzle"
            color: root.iconColor
            pointSize: 24
        }
    }
    
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS
        
        NText {
            id: nameText
            Layout.fillWidth: true
            text: root.pluginData.name || "Без названия"
            color: root.textColor
            font.pointSize: Style.fontSizeM
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        
        NText {
            Layout.fillWidth: true
            text: root.pluginData.id || ""
            color: root.textColor
            font.pointSize: Style.fontSizeXS
            opacity: 0.7
            elide: Text.ElideRight
        }
    }
}