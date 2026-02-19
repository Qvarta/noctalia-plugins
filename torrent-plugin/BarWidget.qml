import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    readonly property bool isBarVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
    readonly property string displayMode: "auto"

    implicitWidth: 32
    implicitHeight: 32

    anchors {
        fill: parent
        margins: 4
    }

    Rectangle {
        id: button
        anchors.fill: parent
        radius: 20
        
        color: getColor()
        
        NIcon {
            id: icon
            anchors.centerIn: parent
            icon: getIcon()
            color: getColor(true)
            
            pointSize: 16
            applyUiScale: true
        }
        
        RotationAnimator {
            id: rotationAnimator
            target: button
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            running: getIsLoading()
            
            onRunningChanged: {
                if (!running) {
                    button.rotation = 0;
                }
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                handleClick();
            }
        }
    }
    
    function getIsLoading() {
        return pluginApi?.mainInstance?.isLoading || false;
    }
    
    function getDaemonRunning() {
        return pluginApi?.mainInstance?.daemonRunning || false;
    }
    
    function getIcon() {
        if (getIsLoading()) {
            return "loader-3";
        } else if (getDaemonRunning()) {
            return "magnet";
        } else {
            return "loader-3";
        }
    }

    function getColor(icon = false) {
        return mouseArea.containsMouse 
            ? (icon ? Color.mOnHover : Color.mHover)
            : (icon ? Color.mOnSurface : Color.mSurface);
    }
    
    function handleClick() {
        var mainInstance = pluginApi?.mainInstance;
        if (!mainInstance) {
            pluginApi.openPanel(root.screen, root);
            return;
        }
        
        if (mainInstance.daemonRunning) {
            pluginApi.openPanel(root.screen, root);
        } else if (!mainInstance.isLoading) {
            mainInstance.startDaemon();
        }
    }
    
    Timer {
        id: updateIconTimer
        interval: 100
        repeat: true
        running: true
        
        onTriggered: {
            icon.icon = getIcon();
        }
    }
}