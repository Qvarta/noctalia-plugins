#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICKSHELL_CONFIG="$HOME/.config/quickshell"
NOCTALIA_SHELL="$QUICKSHELL_CONFIG/noctalia-shell"

WEATHER_CARD_DEST="$NOCTALIA_SHELL/Modules/Cards/WeatherVerticalCard.qml"
LOCATION_SERVICE_DEST="$NOCTALIA_SHELL/Services/Location/LocationService.qml"
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


copy_file "$SCRIPT_DIR/WeatherVerticalCard.qml" "$WEATHER_CARD_DEST" "1. Добавление WeatherVerticalCard.qml"

echo "----------------------------------------"

copy_file "$SCRIPT_DIR/LocationService.qml" "$LOCATION_SERVICE_DEST" "2. Замена LocationService.qml"

echo "----------------------------------------"

copy_file "$SCRIPT_DIR/ControlCenterPanel.qml" "$CONTROL_CENTER_PANEL_DEST" "3. Замена ControlCenterPanel.qml"

echo "----------------------------------------"

copy_file "$SCRIPT_DIR/ControlCenterTab.qml" "$CONTROL_CENTER_TAB_DEST" "4. Замена ControlCenterTab.qml"

echo "========================================"
echo "Все операции завершены!"
