import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property ShellScreen screen

  implicitWidth: Style.barHeight
  implicitHeight: Style.barHeight

  // Фоновый круг с отступами 4px
  Rectangle {
    id: background
    anchors {
      fill: parent
      margins: 4
    }
    radius: width * 0.5
    color: mouseArea.containsMouse ? Color.mHover : "transparent"
  }

  NIcon {
    id: icon
    anchors.centerIn: parent
    icon: "bubble-text" 
    applyUiScale: false
    color: mouseArea.containsMouse ? Color.mOnHover : Color.mPrimary
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (pluginApi) pluginApi.openPanel(root.screen)
  }
}