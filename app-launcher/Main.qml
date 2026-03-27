import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    
    // Свойства для работы с приложениями
    property var allApps: []
    property var favoriteApps: []
    property string searchQuery: ""
    property int selectedIndex: 0
    property int currentTab: 1 // 0 - Все приложения, 1 - Избранное
    property bool showAllAppsMode: false // false - показываем избранное, true - показываем все приложения
    
    // Экспортируем функции для доступа извне
    function getFilteredApps() {
        var query = searchQuery.toLowerCase().trim();
        var appsToFilter;
        
        // Определяем, какие приложения фильтровать
        if (showAllAppsMode) {
            appsToFilter = allApps;
        } else {
            appsToFilter = favoriteApps;
        }
        
        var filteredApps;
        
        if (query === "") {
            filteredApps = appsToFilter.slice(); // Копируем массив
        } else {
            filteredApps = appsToFilter.filter(function(app) {
                // Пропускаем кнопки навигации при поиске
                if (app && (app.isShowAllButton || app.isShowFavoritesButton)) return false;
                
                var name = (app && app.name || "").toLowerCase();
                var comment = (app && app.comment || "").toLowerCase();
                return name.includes(query) || comment.includes(query);
            });
        }
        
        // Добавляем кнопку навигации в начало списка, если нет поискового запроса
        if (query === "") {
            if (!showAllAppsMode) {
                // В режиме избранного - показываем кнопку "Все приложения"
                var showAllButton = {
                    name: "Все приложения",
                    isShowAllButton: true,
                    id: "__show_all_apps_button__"
                };
                filteredApps.unshift(showAllButton);
            } else {
                // В режиме всех приложений - показываем кнопку "Избранное"
                var showFavoritesButton = {
                    name: "Избранное",
                    isShowFavoritesButton: true,
                    id: "__show_favorites_button__"
                };
                filteredApps.unshift(showFavoritesButton);
            }
        }
        
        return filteredApps;
    }
    
    Component.onCompleted: {
        if (pluginApi) {
            pluginApi.mainInstance = root;
        }
        
        loadFavoriteApps();
        // Загружаем приложения после инициализации
        Qt.callLater(function() {
            allApps = getAllApps();
        });
    }
    
    // Функция для инициализации при открытии панели
    function initializePanel() {
        // Загружаем все приложения при открытии панели
        if (allApps.length === 0) {
            allApps = getAllApps();
        }
        loadFavoriteApps();
        showAllAppsMode = false; // Сбрасываем режим при открытии
        selectedIndex = 0;
        searchQuery = "";
    }
    
    function loadFavoriteApps() {
        // Загрузка избранных приложений из конфигурации
        if (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.favorites) {
            favoriteApps = pluginApi.pluginSettings.favorites;
            if (typeof Logger !== 'undefined') {
                Logger.i("Загружено избранных приложений:", favoriteApps.length);
            }
        } else {
            favoriteApps = [];
            if (typeof Logger !== 'undefined') {
                Logger.i("Избранные приложения не найдены в настройках");
            }
        }
    }
    
    function getAllApps() {
        var apps = [];
        try {
            if (typeof DesktopEntries !== 'undefined') {
                const desktopEntries = DesktopEntries.applications.values || [];
                
                apps = desktopEntries.filter(function(app) {
                    if (!app) return false;
                    
                    var noDisplay = app.noDisplay || false;
                    var hidden = app.hidden || false;
                    
                    return !noDisplay && !hidden;
                });
                
                apps.sort(function(a, b) {
                    var nameA = (a.name || "").toLowerCase();
                    var nameB = (b.name || "").toLowerCase();
                    return nameA.localeCompare(nameB);
                });
                
                apps.forEach(function(app) {
                    var executableName = "";
                    
                    if (app.command && Array.isArray(app.command) && app.command.length > 0) {
                        var cmd = app.command[0];
                        var parts = cmd.split('/');
                        var executable = parts[parts.length - 1];
                        executableName = executable.split(' ')[0];
                    } else if (app.exec) {
                        var parts = app.exec.split('/');
                        var executable = parts[parts.length - 1];
                        executableName = executable.split(' ')[0];
                    } else if (app.id) {
                        executableName = app.id.replace('.desktop', '');
                    }
                    
                    app.executableName = executableName;
                });
                
            }
        } catch (e) {
            if (typeof Logger !== 'undefined') {
                Logger.e("Ошибка при загрузке приложений:", e);
            }
        }
        
        return apps;
    }
    
    function isFavorite(appId) {
        return favoriteApps.some(function(app) {
            return app && app.id === appId;
        });
    }
    
    function addToFavorites(app) {
        // Проверяем, что это не кнопка навигации
        if (!app || app.isShowAllButton || app.isShowFavoritesButton) return;
        
        // Проверяем, нет ли уже этого приложения в избранном
        var alreadyInFavorites = favoriteApps.some(function(favApp) {
            return favApp && favApp.id === app.id;
        });
        
        if (!alreadyInFavorites) {
            // Сохраняем только идентификатор и данные для отображения
            var favApp = {
                id: app.id || "",
                name: app.name || "",
                icon: app.icon || "",
                comment: app.comment || "",
                isFavorite: true
            };
            
            favoriteApps.push(favApp);
            if (typeof Logger !== 'undefined') {
                Logger.i("Добавлено в избранное:", app.name || app.id);
            }
            
            // Сохраняем избранное в настройках
            if (pluginApi && typeof pluginApi.saveSettings === 'function') {
                try {
                    pluginApi.pluginSettings.favorites = favoriteApps;
                    pluginApi.saveSettings();
                    if (typeof Logger !== 'undefined') {
                        Logger.i("MyPlugin", "Избранное сохранено в настройках");
                    }
                } catch (e) {
                    if (typeof Logger !== 'undefined') {
                        Logger.e("Ошибка при сохранении избранного:", e);
                    }
                }
            }
            
            // Принудительно обновляем свойство для реактивности
            favoriteApps = favoriteApps.slice();
        } else {
            if (typeof Logger !== 'undefined') {
                Logger.i("Приложение уже в избранном:", app.name || app.id);
            }
        }
    }
    
    function removeFromFavorites(appId) {
        var oldLength = favoriteApps.length;
        
        favoriteApps = favoriteApps.filter(function(app) {
            return app && app.id !== appId;
        });
        
        if (favoriteApps.length < oldLength) {
            if (typeof Logger !== 'undefined') {
                Logger.i("Удалено из избранного:", appId);
            }
            
            // Сохраняем изменения в настройках
            if (pluginApi && typeof pluginApi.saveSettings === 'function') {
                try {
                    pluginApi.pluginSettings.favorites = favoriteApps;
                    pluginApi.saveSettings();
                    if (typeof Logger !== 'undefined') {
                        Logger.i("MyPlugin", "Избранное обновлено в настройках");
                    }
                } catch (e) {
                    if (typeof Logger !== 'undefined') {
                        Logger.e("Ошибка при сохранении избранного:", e);
                    }
                }
            }
            
            favoriteApps = favoriteApps.slice();
        }
    }
    
    function findAppById(appId) {
        if (!allApps || allApps.length === 0) {
            // Попробуем загрузить приложения, если список пустой
            allApps = getAllApps();
        }
        
        return allApps.find(function(app) {
            return app && app.id === appId;
        });
    }
    
    function getFullAppFromFavorite(favApp) {
        if (!favApp || !favApp.id) return null;
        
        var fullApp = findAppById(favApp.id);
        if (!fullApp) {
            if (typeof Logger !== 'undefined') {
                Logger.w("Приложение не найдено в общем списке:", favApp.id, favApp.name);
            }
            // Попробуем найти по имени, если не нашли по ID
            fullApp = allApps.find(function(app) {
                return app && app.name === favApp.name;
            });
            if (fullApp && typeof Logger !== 'undefined') {
                Logger.i("Найдено приложение по имени:", favApp.name);
            }
        }
        return fullApp;
    }
    
    function launchApp(app) {
        // Проверяем навигационные кнопки
        if (app) {
            if (app.isShowAllButton) {
                // Переключаем режим на отображение всех приложений
                showAllAppsMode = true;
                searchQuery = "";
                selectedIndex = 0;
                return;
            } else if (app.isShowFavoritesButton) {
                // Переключаем режим на отображение избранного
                showAllAppsMode = false;
                searchQuery = "";
                selectedIndex = 0;
                return;
            }
        }
        
        if (pluginApi) {
            pluginApi.closePanel();
        }
        
        Qt.callLater(function() {
            try {
                // Определяем, какое приложение запускать
                var appToLaunch;
                
                if (showAllAppsMode) {
                    // В режиме всех приложений - используем напрямую
                    appToLaunch = app;
                } else {
                    // Из избранного - ищем полное приложение
                    appToLaunch = getFullAppFromFavorite(app);
                    
                    if (!appToLaunch) {
                        if (typeof Logger !== 'undefined') {
                            Logger.e("Не удалось найти полное приложение для запуска:", app.name || app.id);
                        }
                        // Пробуем запустить напрямую из избранного
                        appToLaunch = app;
                        if (typeof Logger !== 'undefined') {
                            Logger.i("Пробуем запустить из избранного напрямую");
                        }
                    }
                }
                
                if (appToLaunch) {
                    if (typeof Logger !== 'undefined') {
                        Logger.i("Запуск приложения:", appToLaunch.name || appToLaunch.id);
                    }
                    
                    if (appToLaunch.command && Array.isArray(appToLaunch.command) && appToLaunch.command.length > 0) {
                        if (typeof Quickshell !== 'undefined' && Quickshell.execDetached) {
                            Quickshell.execDetached(appToLaunch.command);
                        }
                    } else if (appToLaunch.execute && typeof appToLaunch.execute === 'function') {
                        appToLaunch.execute();
                    } else if (appToLaunch.exec) {
                        var command = appToLaunch.exec.split(' ');
                        if (typeof Quickshell !== 'undefined' && Quickshell.execDetached) {
                            Quickshell.execDetached(command);
                        }
                    } else {
                        if (typeof Logger !== 'undefined') {
                            Logger.e("Нет команды для запуска приложения:", appToLaunch.name || appToLaunch.id);
                        }
                    }
                }
            } catch (e) {
                if (typeof Logger !== 'undefined') {
                    Logger.e("Ошибка при запуске приложения:", e);
                }
            }
        });
    }
    
    IpcHandler {
        target: "plugin:app-launcher"
        
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen, this);
                });
            }
        }
    }
}