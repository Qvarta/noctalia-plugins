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
        interval: pluginApi?.manifest?.metadata?.refreshInterval 
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
        repeat: true
        property int attempts: 0
        property int maxAttempts: 10
        
        onTriggered: {
            attempts++;
            root.checkDaemonStatus();
            
            if (root.daemonRunning || attempts >= maxAttempts) {
                stop();
                attempts = 0;
                if (!root.daemonRunning) {
                    root.errorMessage = "Не удалось запустить демон";
                    root.isLoading = false;
                }
            }
        }
    }
    
    Process {
        id: transmissionProcess
        command: ["transmission-remote", "-j", "-l"]
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
                var fullOutput = root.processOutput.join("");
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
        root.daemonRunning = false;
        
        var startProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            import qs.Commons
            Process {
                id: daemonProc
                command: ["transmission-daemon"]
                running: true
                
                onExited: function(exitCode) {
                    if (exitCode !== 0) {
                        root.isLoading = false;
                        root.errorMessage = "Ошибка запуска демона";
                    }
                }
            }
        `, root);
        
        // Даем демону время запуститься
        checkAfterStartTimer.attempts = 0;
        checkAfterStartTimer.start();
    }
    
    function stopDaemon() {
        root.isLoading = true;
        root.errorMessage = "";
        
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
                    var checkProcess = Qt.createQmlObject('
                        import QtQuick
                        import Quickshell
                        import Quickshell.Io
                        import qs.Commons
                        Process {
                            id: checkProc
                            command: ["pgrep", "-f", "transmission-daemon"]
                            running: true
                            
                            onExited: function(checkExitCode) {
                                // Если процесс найден, убиваем его
                                if (checkExitCode === 0) {
                                    var killProcess = Qt.createQmlObject(\`
                                        import QtQuick
                                        import Quickshell
                                        import Quickshell.Io
                                        import qs.Commons
                                        Process {
                                            id: killProc
                                            command: ["pkill", "-9", "-f", "transmission-daemon"]
                                            running: true
                                            
                                            onExited: function(killExitCode) {
                                                root.daemonRunning = false;
                                                root.torrentModel.clear();
                                                root.errorMessage = "Демон остановлен";
                                                refreshTimer.stop();
                                                root.isLoading = false;
                                            }
                                        }
                                    \`, checkProc);
                                } else {
                                    // Процесс уже завершен
                                    root.daemonRunning = false;
                                    root.torrentModel.clear();
                                    root.errorMessage = "Демон остановлен";
                                    refreshTimer.stop();
                                    root.isLoading = false;
                                }
                            }
                        }
                    ', stopProc);
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
                id: checkDaemonProc
                command: ["transmission-remote", "--session-info"]
                running: true
                
                onExited: function(exitCode) {
                    root.checkingDaemon = false;
                    if (exitCode === 0) {
                        root.daemonRunning = true;
                        root.errorMessage = "";
                        root.isLoading = false;
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
        try {
            var jsonData = JSON.parse(output);
            
            if (jsonData.result !== "success" || !jsonData.arguments.torrents) {
                return;
            }
            
            var foundTorrents = [];
            var torrents = jsonData.arguments.torrents;
            
            for (var i = 0; i < torrents.length; i++) {
                var torrent = torrents[i];
                var parsedTorrent = parseJsonTorrent(torrent);
                if (parsedTorrent) {
                    foundTorrents.push(parsedTorrent);
                }
            }
            
            if (foundTorrents.length > 0) {
                smoothUpdateModel(foundTorrents);
            }
        } catch (error) {
            return;
        }
    }
    
    function parseJsonTorrent(torrent) {
        try {
            if (!torrent.id || !torrent.name) {
                return null;
            }
            
            var percent = 0;
            if (torrent.sizeWhenDone && torrent.sizeWhenDone > 0) {
                var downloaded = torrent.sizeWhenDone - torrent.leftUntilDone;
                percent = Math.round((downloaded / torrent.sizeWhenDone) * 100);
            } else if (torrent.percentDone) {
                percent = Math.round(torrent.percentDone * 100);
            }
            
            percent = Math.min(100, Math.max(0, percent));
            
            var status = "unknown";
            if (torrent.status !== undefined) {
                status = parseJsonStatus(torrent.status);
                
                if (torrent.isFinished && status === "idle") {
                    status = "completed";
                }
            }
            
            return {
                "id": torrent.id,
                "percent": percent,
                "status": status,
                "name": torrent.name || "Без названия"
            };
            
        } catch (error) {
            return null;
        }
    }
    
    function parseJsonStatus(statusCode) {
        switch(statusCode) {
            case 0: return "stopped";
            case 1: return "queued";
            case 2: return "verifying";
            case 3: return "queued";
            case 4: return "downloading";
            case 5: return "queued";
            case 6: return "seeding";
            default: return "unknown";
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
        target: "plugin:torrent-widget"
        
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