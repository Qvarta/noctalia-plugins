import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property var allLines: []
  
  Process {
    id: catProcess
    command: ["sh", "-c", "cat " + (pluginApi?.pluginSettings?.config || "~/.config/hypr/keybind.conf")]
    running: false
    
    stdout: SplitParser {
      onRead: data => {
        root.allLines.push(data);
      }
    }
    
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root.allLines.length > 0) {
        var fullContent = root.allLines.join("\n");
        parseAndSave(fullContent);
        root.allLines = [];
      } else {
        saveToDb([{
          "title": pluginApi?.tr("panel.error_read_file") || "File read error",
          "binds": [
            { "keys": "ERROR", "desc": "Exit code: " + exitCode }
          ]
        }]);
      }
    }
  }
  
  onPluginApiChanged: {
    if (pluginApi) {
      // Экспортируем функции через pluginApi
      pluginApi.mainInstance = root;
      checkAndGenerate();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      pluginApi.mainInstance = root;
      checkAndGenerate();
    }
  }

  function checkAndGenerate() {
    if (!pluginApi?.pluginSettings?.cheatsheetData || pluginApi.pluginSettings.cheatsheetData.length === 0) {
      allLines = [];
      catProcess.running = true;
    }
  }
  
  function parseAndSave(text) {
    var lines = text.split('\n');
    var cats = [];
    var currentCat = null;
    
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.startsWith("#") && line.match(/#\s*\d+\./)) {
        if (currentCat) cats.push(currentCat);
        var title = line.replace(/#\s*\d+\.\s*/, "").trim();
        currentCat = { "title": title, "binds": [] };
      } 
      else if (line.includes("bind") && line.includes('#"')) {
        if (currentCat) {
          var descMatch = line.match(/#"(.*?)"$/);
          var desc = descMatch ? descMatch[1] : (pluginApi?.tr("panel.no_description") || "No description");
          var parts = line.split(',');
          if (parts.length >= 2) {
            var bindPart = parts[0].trim();
            var keyPart = parts[1].trim();
            var mod = "";
            if (bindPart.includes("$mod")) mod = "Super";
            if (bindPart.includes("SHIFT")) mod += (mod ? " + Shift" : "Shift");
            if (bindPart.includes("CTRL")) mod += (mod ? " + Ctrl" : "Ctrl");
            if (bindPart.includes("ALT")) mod += (mod ? " + Alt" : "Alt");
            var key = keyPart.toUpperCase();
            var fullKey = mod + (mod && key ? " + " : "") + key;
            currentCat.binds.push({ "keys": fullKey, "desc": desc });
          }
        }
      }
    }
    if (currentCat) cats.push(currentCat);
    
    if (cats.length > 0) {
      pluginApi.pluginSettings.cheatsheetData = cats;
      pluginApi.saveSettings();
    } else {
      if (pluginApi?.pluginSettings) {
        pluginApi.pluginSettings.cheatsheetData = [];
        pluginApi.saveSettings();
      }
    }
  }
  
  IpcHandler {
    target: "plugin:hyprland-cheatsheet"
    
    function toggle() {
      if (pluginApi) {
        pluginApi.pluginSettings.cheatsheetData = [];
        pluginApi.saveSettings();
        checkAndGenerate();
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen);
        });
      }
    }
    
    function refresh() {
      if (pluginApi) {
        pluginApi.pluginSettings.cheatsheetData = [];
        pluginApi.saveSettings();
        checkAndGenerate();
      }
    }
  }
  
  function getKeyColor(keyName) {
    if (keyName === "Super") return Color.mPrimary; 
    if (keyName === "PRINT") return Color.mSecondary;
    if (["Alt", "Ctrl", "Shift", "ESCAPE", "ENTER", "TAB", "SPACE", "BACKSPACE", "DELETE"].includes(keyName)) 
      return Color.mTertiary;
    if (keyName.startsWith("F")) return Color.mTertiary;
    if (keyName.startsWith("XF86")) return Qt.lighter(Color.mTertiary, 1.2);
    if (keyName.match(/^[0-9]$/)) return Qt.lighter(Color.mPrimary, 1.3);
    if (keyName.includes("MOUSE")) return Color.mSecondary;
    if (keyName.includes("ARROW")) return Qt.darker(Color.mTertiary, 1.1);
    if (keyName.includes("PAGE")) return Qt.lighter(Color.mPrimary, 1.1);
    if (keyName.includes("HOME") || keyName.includes("END")) 
      return Qt.lighter(Color.mTertiary, 1.1);
    return  Qt.lighter(Color.mPrimary, 1.3);
  }
  
  function getCategoryIcon(categoryTitle) {
      var title = categoryTitle.toLowerCase();
      
      if (title.includes("меню")) return "menu";
      if (title.includes("приложения")) return "apps-filled";
      if (title.includes("система")) return "settings-filled";
      if (title.includes("окна")) return "brand-windows-filled";
      if (title.includes("фокус")) return "focus";
      if (title.includes("мышь")) return "mouse-filled";
      if (title.includes("рабочие пространства") || title.includes("рабочие")) 
          return "circle-dot-filled";
      if (title.includes("перемещение окон")) return "arrows-move-horizontal";
      
      return "keyboard-filled";
  }
}