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
    
    // Таймер для задержки проверки после запуска демона
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
    
    // Функция запуска демона
    function startDaemon() {
        Logger.i("Transmission", "Запуск transmission-daemon");
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
                    Logger.i("Transmission", "Демон завершился с кодом: " + exitCode);
                    root.isLoading = false;
                }
            }
        `, root);
        
        // Запускаем таймер для проверки через 2 секунды
        checkAfterStartTimer.start();
    }
    
    // Функция остановки демона
    function stopDaemon() {
        Logger.i("Transmission", "Остановка transmission-daemon");
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
                        Logger.i("Transmission", "Демон остановлен через --exit");
                        root.daemonRunning = false;
                        root.torrentModel.clear();
                        root.errorMessage = "Демон остановлен";
                        refreshTimer.stop();
                        root.isLoading = false;
                    } else {
                        Logger.i("Transmission", "Не удалось остановить демон, пробуем kill");
                        // Запускаем процесс kill
                        var killProcess = Qt.createQmlObject('
                            import QtQuick
                            import Quickshell
                            import Quickshell.Io
                            Process {
                                command: ["pkill", "-f", "transmission-daemon"]
                                running: true
                                onExited: function(killExitCode) {
                                    Logger.i("Transmission", "Демон убит через pkill: " + killExitCode);
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
    
    // Проверка статуса демона
    function checkDaemonStatus() {
        if (root.checkingDaemon) return;
        
        root.checkingDaemon = true;
        Logger.i("Transmission", "Проверка статуса демона через подключение");
        
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
                        Logger.i("Transmission", "Демон активен и отвечает");
                        root.daemonRunning = true;
                        root.errorMessage = "";
                        if (!refreshTimer.running) {
                            refreshTimer.start();
                            root.refreshTorrents();
                        }
                    } else {
                        Logger.i("Transmission", "Демон не отвечает");
                        root.daemonRunning = false;
                        root.errorMessage = "Демон не запущен";
                        refreshTimer.stop();
                    }
                }
            }
        `, root);
    }
    
    // Функция добавления торрента из файла
    function addTorrentFromFile(filePath) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        Logger.i("Transmission", "Добавление торрента из файла: " + filePath);
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
                
                stdout: SplitParser {
                    onRead: data => {
                        Logger.i("Transmission", "Вывод добавления файла: " + data);
                    }
                }
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка добавления файла: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    Logger.i("Transmission", "Добавление файла завершено с кодом: " + exitCode);
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        // Обновляем список торрентов после успешного добавления
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка добавления торрента из файла";
                    }
                }
            }
        `, root);
    }
    
    // Функция добавления торрента по magnet ссылке
    function addTorrentFromMagnet(magnetLink) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        Logger.i("Transmission", "Добавление торрента по magnet ссылке: " + magnetLink);
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
                
                stdout: SplitParser {
                    onRead: data => {
                        Logger.i("Transmission", "Вывод добавления magnet: " + data);
                    }
                }
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка добавления magnet: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    Logger.i("Transmission", "Добавление magnet завершено с кодом: " + exitCode);
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        // Обновляем список торрентов после успешного добавления
                        root.refreshTorrents();
                    } else {
                        root.errorMessage = "Ошибка добавления торрента по magnet ссылке";
                    }
                }
            }
        `, root);
    }
    
    // Функция удаления торрента по ID
    function deleteTorrent(torrentId) {
        if (!daemonRunning) {
            errorMessage = "Демон не запущен";
            return;
        }
        
        if (!torrentId) {
            errorMessage = "ID торрента не указан";
            return;
        }
        
        Logger.i("Transmission", "Удаление торрента с ID: " + torrentId);
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
                
                stdout: SplitParser {
                    onRead: data => {
                        Logger.i("Transmission", "Вывод удаления: " + data);
                    }
                }
                
                stderr: SplitParser {
                    onRead: data => {
                        Logger.e("Transmission", "Ошибка удаления: " + data);
                    }
                }
                
                onExited: function(exitCode) {
                    Logger.i("Transmission", "Удаление завершено с кодом: " + exitCode);
                    root.isLoading = false;
                    
                    if (exitCode === 0) {
                        root.errorMessage = "";
                        // Обновляем список торрентов после удаления
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