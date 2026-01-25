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
    
    property bool daemonRunning: false
    property bool checkingDaemon: false
    
    Timer {
        id: refreshTimer
        interval: 5000
        running: false
        repeat: true
        onTriggered: {
            root.refreshTorrents();
        }
    }
    
    Timer {
        id: checkAfterStartTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            root.checkDaemonStatus();
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
                root.daemonRunning = true;
                root.errorMessage = "";
                if (!refreshTimer.running) refreshTimer.start();
            } else if (exitCode !== 0) {
                root.daemonRunning = false;
                root.errorMessage = "Демон не запущен";
                refreshTimer.stop();
            }
            
            root.isLoading = false;
            root.processOutput = [];
        }
    }
    
    function startDaemon() {
        root.isLoading = true;
        root.errorMessage = "";
        
        var startProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                command: ["transmission-daemon", "--foreground"]
                running: true
                onExited: function(exitCode) {
                    root.isLoading = false;
                }
            }
        `, root);
        
        checkAfterStartTimer.start();
    }
    
    function stopDaemon() {
        root.isLoading = true;
        
        var stopProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: stopProc
                command: ["transmission-remote", "--exit"]
                running: true
                
                onExited: function(exitCode) {
                    if (exitCode === 0) {
                        root.daemonRunning = false;
                        root.torrentModel.clear();
                        root.errorMessage = "Демон остановлен";
                        refreshTimer.stop();
                        root.isLoading = false;
                    } else {
                        var killProcess = Qt.createQmlObject('
                            import QtQuick
                            import Quickshell
                            import Quickshell.Io
                            Process {
                                command: ["pkill", "-f", "transmission-daemon"]
                                running: true
                                onExited: function(killExitCode) {
                                    root.daemonRunning = false;
                                    root.torrentModel.clear();
                                    root.errorMessage = "Демон остановлен";
                                    refreshTimer.stop();
                                    root.isLoading = false;
                                }
                            }
                        ', stopProc);
                    }
                }
            }
        `, root);
    }
    
    function checkDaemonStatus() {
        if (root.checkingDaemon) return;
        
        root.checkingDaemon = true;
        
        var checkProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                command: ["transmission-remote", "--session-info"]
                running: true
                
                onExited: function(exitCode) {
                    root.checkingDaemon = false;
                    if (exitCode === 0) {
                        root.daemonRunning = true;
                        root.errorMessage = "";
                        if (!refreshTimer.running) {
                            refreshTimer.start();
                            root.refreshTorrents();
                        }
                    } else {
                        root.daemonRunning = false;
                        root.errorMessage = "Демон не запущен";
                        refreshTimer.stop();
                    }
                }
            }
        `, root);
    }
    
    function pauseTorrent(torrentId) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        if (!torrentId) {
            errorMessage = "ID торрента не указан";
            return;
        }
        
        root.isLoading = true;
        
        var pauseProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: pauseProc
                command: ["transmission-remote", "-t", "${torrentId}", "--stop"]
                running: true
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка остановки: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка остановки торрента";
                    }
                }
            }
        `, root);
    }
    
    function resumeTorrent(torrentId) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        if (!torrentId) {
            errorMessage = "ID торрента не указан";
            return;
        }
        
        root.isLoading = true;
        
        var resumeProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: resumeProc
                command: ["transmission-remote", "-t", "${torrentId}", "--start"]
                running: true
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка запуска: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка возобновления торрента";
                    }
                }
            }
        `, root);
    }
    
    function addTorrentFromFile(filePath) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        root.isLoading = true;
        
        var addProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: fileAddProcess
                command: ["transmission-remote", "-a", "${filePath}"]
                running: true
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка добавления файла: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка добавления торрента из файла";
                    }
                }
            }
        `, root);
    }
    
    function addTorrentFromMagnet(magnetLink) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        root.isLoading = true;
        
        var addProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: magnetAddProcess
                command: ["transmission-remote", "-a", "${magnetLink}"]
                running: true
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка добавления magnet: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка добавления торрента по magnet ссылке";
                    }
                }
            }
        `, root);
    }
    
    function deleteTorrent(torrentId) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        if (!torrentId) {
            errorMessage = "ID торрента не указан";
            return;
        }
        
        root.isLoading = true;
        
        var deleteProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: deleteProc
                command: ["transmission-remote", "-t", "${torrentId}", "--remove-and-delete"]
                running: true
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка удаления: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка удаления торрента";
                    }
                }
            }
        `, root);
    }
    
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
                    if (percent === 100 && status === "idle") {
                        status = "completed";
                    }
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
        var statusWords = ["Idle", "Seeding", "Downloading", "Stopped", "Verifying", "Queued", "Finished", "Paused", "Up", "Down"];
        return statusWords.includes(word);
    }
    
    function parseStatus(statusStr) {
        if (statusStr === "Stopped" || statusStr === "Paused") return "stopped";
        if (statusStr === "Idle" || statusStr === "Finished") return "idle";
        if (statusStr === "Downloading" || statusStr === "Down") return "downloading";
        if (statusStr === "Seeding" || statusStr === "Up") return "seeding";
        if (statusStr === "Verifying") return "verifying";
        if (statusStr === "Queued") return "queued";
        return "unknown";
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
        if (!transmissionProcess.running && root.daemonRunning) {
            transmissionProcess.running = true;
        }
    }
    
    Component.onCompleted: {
        if (pluginApi) {
            pluginApi.mainInstance = root;
            root.checkDaemonStatus();
        }
    }
    
    IpcHandler {
        target: "plugin:transmission-widget"
        
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen, this);
                    root.checkDaemonStatus();
                });
            }
        }
    }
}