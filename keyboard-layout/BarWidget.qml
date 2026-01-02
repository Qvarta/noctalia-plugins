import QtQuick
import Quickshell
import qs.Services

BarWidget {
    id: root
    width: 40
    height: parent.height
    
    // Ссылки на службы
    property var keyboardService: Quickshell.singleton("KeyboardLayoutService")
    property var lockKeysService: Quickshell.singleton("LockKeysService")
    
    // Текущая раскладка (первые 2 буквы кода)
    property string displayText: keyboardService ? 
        keyboardService.currentLayout.substring(0, 2).toUpperCase() : "??"
    
    // Фон становится красным при включенном Caps Lock
    Rectangle {
        id: background
        anchors.fill: parent
        color: lockKeysService && lockKeysService.capsLockOn ? "#ff4444" : "transparent"
        radius: 3
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
    
    // Текст с раскладкой
    Text {
        id: layoutText
        anchors.centerIn: parent
        text: displayText
        font.pixelSize: Math.min(parent.height * 0.6, 14)
        font.bold: true
        color: lockKeysService && lockKeysService.capsLockOn ? "white" : palette.text
    }
    
    // Индикатор Caps Lock (маленький индикатор в углу)
    Rectangle {
        id: capsIndicator
        visible: lockKeysService && lockKeysService.capsLockOn
        width: 6
        height: 6
        radius: 3
        color: "#ff0000"
        anchors {
            top: parent.top
            right: parent.right
            margins: 2
        }
    }
    
    // Обновляем текст при изменении раскладки
    Connections {
        target: keyboardService
        function onCurrentLayoutChanged() {
            if (keyboardService) {
                displayText = keyboardService.currentLayout.substring(0, 2).toUpperCase()
            }
        }
    }
    
    // Обновляем цвет при изменении состояния Caps Lock
    Connections {
        target: lockKeysService
        function onCapsLockChanged(active) {
            // Фон обновится автоматически через binding
        }
    }
    
    // Тултип для дополнительной информации
    ToolTip {
        id: tooltip
        delay: 500
        text: {
            var text = keyboardService ? 
                keyboardService.currentLayout.toUpperCase() : "Unknown";
            if (lockKeysService) {
                var locks = [];
                if (lockKeysService.capsLockOn) locks.push("Caps Lock");
                if (lockKeysService.numLockOn) locks.push("Num Lock");
                if (lockKeysService.scrollLockOn) locks.push("Scroll Lock");
                
                if (locks.length > 0) {
                    text += "\n" + locks.join(", ");
                }
            }
            return text;
        }
    }
    
    // Показываем тултип при наведении
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: tooltip.visible = true
        onExited: tooltip.visible = false
        
        // Также можно добавить клик для переключения раскладки (если есть такая функция в системе)
        onClicked: {
            // Здесь можно добавить логику для переключения раскладки
            // если в системе есть такая возможность
            console.log("Keyboard layout clicked:", displayText);
        }
    }
    
    // Инициализация при создании
    Component.onCompleted: {
        if (keyboardService) {
            displayText = keyboardService.currentLayout.substring(0, 2).toUpperCase()
        }
        
        Logger.i("KeyboardLayoutWidget", "Widget loaded, current layout:", displayText);
    }
}