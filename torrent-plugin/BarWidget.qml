import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    readonly property bool isBarVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
    readonly property string displayMode: "auto"

    implicitWidth: pill.width
    implicitHeight: pill.height

    BarPill {
        id: pill

        screen: root.screen
        oppositeDirection: BarService.getPillDirection(root)
        icon: "file-download"
        // text: ""
        autoHide: false
        forceOpen: false
        forceClose: false
        tooltipText: pluginApi?.tr("tooltipLabel")
        
        onClicked: {
            pluginApi.openPanel(root.screen,this);
        }
    }
}