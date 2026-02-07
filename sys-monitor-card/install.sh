#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICKSHELL_CONFIG="$HOME/.config/quickshell"
NOCTALIA_SHELL="$QUICKSHELL_CONFIG/noctalia-shell"

SYS_MONITOR_CARD_DEST="$NOCTALIA_SHELL/Modules/Cards/SysMonitorCard.qml"
CONTROL_CENTER_PANEL_DEST="$NOCTALIA_SHELL/Modules/Panels/ControlCenter/ControlCenterPanel.qml"
CONTROL_CENTER_TAB_DEST="$NOCTALIA_SHELL/Modules/Panels/Settings/Tabs/ControlCenter/ControlCenterTab.qml"

if [ ! -d "$NOCTALIA_SHELL" ]; then
    echo "Ошибка: не найдена noctalia-shell в ~/.config/quickshell"
    exit 1
fi

copy_file() {
    local source="$1"
    local destination="$2"
    local description="$3"
    local file_type="$4"
    
    if [ ! -f "$source" ]; then
        echo "Ошибка: $(basename "$source") не найден в папке со скриптом!"
        return 1
    fi
    
    echo "$description:"
    echo "  Копируем $(basename "$source")"
    echo "  в $destination"
    
    cp -f "$source" "$destination"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Успешно скопировано"
        return 0
    else
        echo "  ✗ Ошибка при копировании"
        return 1
    fi
}

copy_file "$SCRIPT_DIR/SysMonitorCard.qml" "$SYS_MONITOR_CARD_DEST" "1. Добавление SysMonitorCard.qml" "добавлен"

echo "----------------------------------------"

copy_file "$SCRIPT_DIR/ControlCenterPanel.qml" "$CONTROL_CENTER_PANEL_DEST" "2. Замена ControlCenterPanel.qml" "заменен"

echo "----------------------------------------"

copy_file "$SCRIPT_DIR/ControlCenterTab.qml" "$CONTROL_CENTER_TAB_DEST" "3. Замена ControlCenterTab.qml" "заменен"

echo "========================================"
echo "Все операции завершены!"
