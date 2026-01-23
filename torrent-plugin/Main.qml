import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    
    property ListModel torrentModel: ListModel {}
    property bool isLoading: false
    property string errorMessage: ""
    property var processOutput: []
    
    Timer {
        id: refreshTimer
        interval: pluginApi?.manifest?.metadata?.refreshInterval
        running: true
        repeat: true
        onTriggered: {
            root.refreshTorrents();
        }
    }
    
    Process {
        id: transmissionProcess
        command: ["transmission-remote", "-l"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                root.processOutput.push(data);
            }
        }
        
        onStarted: {
            root.processOutput = [];
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.processOutput.length > 0) {
                var fullOutput = root.processOutput.join("\n");
                parseAndUpdateTorrents(fullOutput);
            } else if (exitCode !== 0) {
                root.errorMessage = "Ошибка (код: " + exitCode + ")";
            }
            
            root.isLoading = false;
            root.processOutput = [];
        }
    }
    
    // Парсинг вывода transmission-remote
    function parseAndUpdateTorrents(output) {
        var lines = output.trim().split('\n');
        var foundTorrents = [];
        
        var dataStartIndex = -1;
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].includes("ID") && lines[i].includes("Done") && lines[i].includes("Name")) {
                dataStartIndex = i + 1;
                break;
            }
        }
        
        if (dataStartIndex === -1) return;
        
        if (dataStartIndex < lines.length && lines[dataStartIndex].includes("---")) {
            dataStartIndex++;
        }
        
        for (var j = dataStartIndex; j < lines.length; j++) {
            var line = lines[j].trim();
            if (line === "" || line.startsWith("Sum:")) continue;
            
            var torrent = parseTorrentLine(line);
            if (torrent) {
                foundTorrents.push(torrent);
            }
        }
        
        if (foundTorrents.length > 0) {
            smoothUpdateModel(foundTorrents);
        }
    }
    
    function parseTorrentLine(line) {
        try {
            line = line.replace(/\s+/g, ' ').trim();
            var parts = line.split(' ');
            
            if (parts.length < 9) return null;
            
            var idStr = parts[0];
            var hasStar = idStr.endsWith('*');
            var id = parseInt(hasStar ? idStr.slice(0, -1) : idStr);
            
            var percent = parseInt(parts[1].replace('%', ''));
            
            var status = "unknown";
            for (var i = 4; i < parts.length; i++) {
                if (isStatusWord(parts[i])) {
                    status = parseStatus(parts[i]);
                    break;
                }
            }
            
            var name = "";
            for (var j = i + 1; j < parts.length; j++) {
                if (name) name += " ";
                name += parts[j];
            }
            
            if (!name) name = "Без названия";
            
            return {
                "id": id,
                "percent": percent,
                "status": status,
                "name": name
            };
            
        } catch (error) {
            return null;
        }
    }
    
    function isStatusWord(word) {
        var statusWords = ["Idle", "Seeding", "Downloading", "Stopped", "Verifying", "Queued"];
        return statusWords.includes(word);
    }
    
    function parseStatus(statusStr) {
        if (statusStr === "Stopped") return "stopped";
        if (statusStr === "Idle") return "completed";
        if (statusStr === "Downloading") return "downloading";
        if (statusStr === "Seeding") return "seeding";
        return "unknown";
    }
    
    function getStatusText(status) {
        switch(status) {
            case "downloading": return "Скачивается";
            case "seeding": return "Раздача";
            case "completed": return "Завершен";
            case "stopped": return "Пауза";
            default: return "Неизвестно";
        }
    }
    
    function smoothUpdateModel(newTorrents) {
        var existingIds = {};
        
        for (var i = 0; i < torrentModel.count; i++) {
            existingIds[torrentModel.get(i).id] = i;
        }
        
        for (var j = 0; j < newTorrents.length; j++) {
            var newTorrent = newTorrents[j];
            var existingIndex = existingIds[newTorrent.id];
            
            if (existingIndex !== undefined) {
                var current = torrentModel.get(existingIndex);
                var changed = false;
                
                if (current.percent !== newTorrent.percent) changed = true;
                if (current.status !== newTorrent.status) changed = true;
                
                if (changed) {
                    torrentModel.set(existingIndex, {
                        "percent": newTorrent.percent,
                        "status": newTorrent.status
                    });
                }
                
                delete existingIds[newTorrent.id];
            } else {
                torrentModel.append(newTorrent);
            }
        }
        
        var idsToRemove = Object.keys(existingIds);
        if (idsToRemove.length > 0) {
            idsToRemove.sort((a, b) => b - a);
            for (var k = 0; k < idsToRemove.length; k++) {
                var indexToRemove = existingIds[idsToRemove[k]];
                if (indexToRemove !== undefined) {
                    torrentModel.remove(indexToRemove);
                }
            }
        }
    }
    
    function refreshTorrents() {
        if (!transmissionProcess.running) {
            transmissionProcess.running = true;
        }
    }
    
    Component.onCompleted: {
        if (pluginApi) {
            pluginApi.mainInstance = root;
            refreshTorrents();
        }
    }
    
    // IPC обработчик для открытия панели
    IpcHandler {
        target: "plugin: torrent-plugin"
        
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen, this);
                    root.refreshTorrents();
                });
            }
        }
    }
}