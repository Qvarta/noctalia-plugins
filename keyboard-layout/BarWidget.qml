import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.Keyboard

Item {
    id: root

    property var pluginApi: null
    property string currentLayout: KeyboardLayoutService ? KeyboardLayoutService.currentLayout : "??"
    property bool flag: pluginApi?.pluginSettings.showIcon 
    property bool text: pluginApi?.pluginSettings.showText
    property string componentId: "bar-layout:" + Date.now()
    
    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight - 6

    property string displayText: {
      if (!currentLayout || currentLayout === "system.unknown-layout") {
        return "??";
      }
      return currentLayout.substring(0, 2).toUpperCase();
    }

    function getFlagEmoji(layoutCode) {
        if (!layoutCode || layoutCode.length < 2) return "🇦🇧";
        
        var code = layoutCode.toLowerCase();
        
        if (pluginApi?.pluginSettings[code]) {
            return pluginApi?.pluginSettings[code];
        }
        
        return "🇦🇧";
    }

    Rectangle {
        id: backgroundRect
        anchors {
            fill: parent
            margins: 4
        }
        color: (LockKeysService && LockKeysService.capsLockOn) 
               ? Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.5) 
               : Color.mSurfaceVariant
        radius: 4

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Style.marginS

            NText {
                id: flagText
                visible: root.flag 
                text: getFlagEmoji(displayText.toLowerCase())
                color: (LockKeysService && LockKeysService.capsLockOn) ? Color.mOnHover : Color.mOnSurface
                pointSize: Style.fontSizeXL
            }

            NText {
                id: text
                visible: root.text
                text: displayText
                color: (LockKeysService && LockKeysService.capsLockOn) ? Color.mOnHover : Color.mOnSurface
                pointSize: Style.fontSizeS
            }
        }
    }

    Component.onCompleted: {
        if (LockKeysService) {
            LockKeysService.registerComponent(root.componentId);
        }
    }
    
    Component.onDestruction: {
        if (LockKeysService) {
            LockKeysService.unregisterComponent(root.componentId);
        }
    }
}