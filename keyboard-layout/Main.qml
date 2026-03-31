import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    
    IpcHandler {
        target: "plugin:keyboard-layout"
        
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen, this);
                });
            }
        }
    }
}