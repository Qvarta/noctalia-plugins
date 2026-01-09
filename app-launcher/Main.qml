import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    
    property var allApps: []
    property string searchQuery: ""
    property int selectedIndex: 0
    property var filteredApps: []
    
    Component.onCompleted: {
        if (pluginApi) {
            pluginApi.mainInstance = root;
        }
        
        // loadApps();
    }
    
    // function loadApps() {
    //     allApps = getAllApps();
    //     updateFilteredApps();
    // }
    
    // function getAllApps() {
    //     var apps = [];
    //     try {
    //         if (typeof DesktopEntries !== 'undefined') {
    //             const allApps = DesktopEntries.applications.values || [];
                
    //             apps = allApps.filter(function(app) {
    //                 if (!app) return false;
                    
    //                 var noDisplay = app.noDisplay || false;
    //                 var hidden = app.hidden || false;
                    
    //                 return !noDisplay && !hidden;
    //             });
                
    //             apps.sort(function(a, b) {
    //                 var nameA = (a.name || "").toLowerCase();
    //                 var nameB = (b.name || "").toLowerCase();
    //                 return nameA.localeCompare(nameB);
    //             });
                
    //             apps = apps.map(function(app) {
    //                 var executableName = "";
                    
    //                 if (app.command && Array.isArray(app.command) && app.command.length > 0) {
    //                     var cmd = app.command[0];
    //                     var parts = cmd.split('/');
    //                     var executable = parts[parts.length - 1];
    //                     executableName = executable.split(' ')[0];
    //                 } else if (app.exec) {
    //                     var parts = app.exec.split('/');
    //                     var executable = parts[parts.length - 1];
    //                     executableName = executable.split(' ')[0];
    //                 } else if (app.id) {
    //                     executableName = app.id.replace('.desktop', '');
    //                 }
                    
    //                 app.executableName = executableName;
    //                 return app;
    //             });
                
    //         }
    //     } catch (e) {
    //     }
        
    //     return apps;
    // }
    
    // function updateFilteredApps() {
    //     var query = searchQuery.toLowerCase().trim();
        
    //     if (query === "") {
    //         filteredApps = allApps.slice(0, 30);
    //     } else {
    //         filteredApps = allApps.filter(function(app) {
    //             var name = (app.name || "").toLowerCase();
    //             var comment = (app.comment || "").toLowerCase();
    //             return name.includes(query) || comment.includes(query);
    //         }).slice(0, 30);
    //     }
        
    //     filteredApps = filteredApps;
    // }
    
    // function launchApp(app) {
    //     if (pluginApi) {
    //         pluginApi.closePanel();
    //     }
        
    //     Qt.callLater(function() {
    //         try {
    //             if (app.command && Array.isArray(app.command) && app.command.length > 0) {
    //                 if (typeof Quickshell !== 'undefined' && Quickshell.execDetached) {
    //                     Quickshell.execDetached(app.command);
    //                 }
    //             } else if (app.execute && typeof app.execute === 'function') {
    //                 app.execute();
    //             } else if (app.exec) {
    //                 var command = app.exec.split(' ');
    //                 if (typeof Quickshell !== 'undefined' && Quickshell.execDetached) {
    //                     Quickshell.execDetached(command);
    //                 }
    //             }
    //         } catch (e) {
    //         }
    //     });
    // }
    
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