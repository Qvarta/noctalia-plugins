import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.Noctalia

Item {
    id: root
    property var pluginApi: null

    signal pluginsListChanged

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
            var plugins = pluginApi.pluginSettings.plugins;

            // Сортировка плагинов по полю order
            var sortedPlugins = {};
            var pluginsArray = [];

            for (var pluginId in plugins) {
                if (plugins.hasOwnProperty(pluginId)) {
                    pluginsArray.push({
                        id: pluginId,
                        data: plugins[pluginId]
                    });
                }
            }

            // Сортировка по order, если поле отсутствует - помещаем в конец
            pluginsArray.sort(function (a, b) {
                var orderA = a.data.order !== undefined ? a.data.order : Number.MAX_VALUE;
                var orderB = b.data.order !== undefined ? b.data.order : Number.MAX_VALUE;
                return orderA - orderB;
            });

            // Восстанавливаем объект с отсортированными ключами
            for (var i = 0; i < pluginsArray.length; i++) {
                sortedPlugins[pluginsArray[i].id] = pluginsArray[i].data;
            }

            return sortedPlugins;
        }
        return {};
    }

    function openPluginPanel(pluginId) {
        if (typeof PluginService !== 'undefined' && PluginService.togglePluginPanel) {
            if (PluginService.screenDetector) {
                PluginService.screenDetector.withCurrentScreen(function(screen) {
                    if (screen) {
                        PluginService.togglePluginPanel(pluginId, screen, null);
                    }
                });
            } else {
                var primaryScreen = Quickshell.screens[0];
                if (primaryScreen) {
                    PluginService.togglePluginPanel(pluginId, primaryScreen, null);
                }
            }
        } else {
            Logger.w("Plugin-Panel", "PluginService or togglePluginPanel not available, falling back to CLI method for plugin:", pluginId);
            
            var toggleProcess = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root);
            toggleProcess.command = ["qs", "-c", "noctalia-shell", "ipc", "call", "plugin:" + pluginId, "toggle"];
            toggleProcess.startDetached();

            toggleProcess.exited.connect(function (exitCode) {
                if (exitCode !== 0) {
                    Logger.e("Plugin-Panel", "Failed to open plugin " + pluginId + " via CLI with exit code: " + exitCode);
                }
                toggleProcess.destroy();
            });
        }
    }

    function movePlugin(pluginId, toIndex) {
        if (!pluginApi || !pluginApi.pluginSettings || !pluginApi.pluginSettings.plugins)
            return false;

        var pluginsArray = getSortedPluginsArray();
        var fromIndex = pluginsArray.findIndex(p => p.id === pluginId);
        if (fromIndex === -1 || toIndex < 0 || toIndex >= pluginsArray.length)
            return false;

        // Убираем элемент из текущей позиции
        var [movedPlugin] = pluginsArray.splice(fromIndex, 1);

        // Вставляем на новое место
        pluginsArray.splice(toIndex, 0, movedPlugin);

        // Обновляем поле order для всех плагинов
        var updatedPlugins = {};
        for (var i = 0; i < pluginsArray.length; i++) {
            pluginsArray[i].data.order = i;
            updatedPlugins[pluginsArray[i].id] = pluginsArray[i].data;
        }

        pluginApi.pluginSettings.plugins = updatedPlugins;
        pluginApi.saveSettings();

        // Сигнализируем QML, что список изменился
        pluginsListChanged();

        return true;
    }

    function notifyPluginsChanged() {
        pluginsListChanged();
    }

    function getNextOrderNumber() {
        if (!pluginApi || !pluginApi.pluginSettings || !pluginApi.pluginSettings.plugins) {
            return 0;
        }

        var plugins = pluginApi.pluginSettings.plugins;
        var maxOrder = 0;

        for (var pluginId in plugins) {
            if (plugins.hasOwnProperty(pluginId)) {
                var order = plugins[pluginId].order;
                if (order !== undefined && order > maxOrder) {
                    maxOrder = order;
                }
            }
        }

        return maxOrder + 1;
    }

    function getSortedPluginsArray() {
        if (!pluginApi || !pluginApi.pluginSettings || !pluginApi.pluginSettings.plugins) {
            return [];
        }

        var plugins = pluginApi.pluginSettings.plugins;
        var pluginsArray = [];

        for (var pluginId in plugins) {
            if (plugins.hasOwnProperty(pluginId)) {
                pluginsArray.push({
                    id: pluginId,
                    data: plugins[pluginId]
                });
            }
        }

        pluginsArray.sort(function (a, b) {
            var orderA = a.data.order !== undefined ? a.data.order : Number.MAX_VALUE;
            var orderB = b.data.order !== undefined ? b.data.order : Number.MAX_VALUE;
            return orderA - orderB;
        });

        return pluginsArray;
    }

    function deletePlugin(pluginId) {
        if (!pluginApi || !pluginApi.pluginSettings || !pluginApi.pluginSettings.plugins) {
            return false;
        }

        var plugins = pluginApi.pluginSettings.plugins;
        if (plugins[pluginId]) {
            delete plugins[pluginId];
            pluginApi.pluginSettings.plugins = plugins;
            pluginApi.saveSettings();
            return true;
        }

        return false;
    }

    onPluginApiChanged: {
        if (pluginApi && pluginApi.pluginSettings) {
            var settings = pluginApi.pluginSettings;
            if (settings.pluginsChanged) {
                settings.pluginsChanged.connect(notifyPluginsChanged);
            }
        }
    }
}
