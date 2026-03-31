import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  IpcHandler {
    target: "plugin:plugins-panel"
    
    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen);
        });
      }
    }
  }

  function getPluginsList() {
    if (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.plugins) {
      return pluginApi.pluginSettings.plugins;
    }
    return {};
  }

  function openPluginPanel(modelData) {

    if (pluginApi && pluginApi.closePanel) {
      pluginApi.closePanel();
    }
    
    var toggleProcess = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root);
    toggleProcess.command = ["qs", "-c", "noctalia-shell", "ipc", "call", "plugin:" + modelData, "toggle"];
    toggleProcess.startDetached();
    
    toggleProcess.exited.connect(function(exitCode) {
      if (exitCode !== 0) {
        Logger.e("Failed to open plugin " + modelData + " with exit code: " + exitCode);
      } else {
        Logger.d("Successfully opened plugin: " + modelData);
      }
      toggleProcess.destroy();
    });
  }
}