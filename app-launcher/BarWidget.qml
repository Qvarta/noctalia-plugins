import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons

Rectangle {
    id: root

    property var pluginApi: null

    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight - 6
    
    NText {
        anchors.centerIn: parent
        text: "🇦🇧"
        pointSize: Style.fontSizeS
        color: colors.mOnPrimary
            
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                pluginApi.openPanel(root.screen,this);
            }
        }
    }
}