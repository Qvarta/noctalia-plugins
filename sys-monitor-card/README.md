# System Monitor для Control Center

<img width="426" height="208" alt="preview1" src="https://github.com/user-attachments/assets/fa0baf42-0774-4967-8946-70add98b4859" />

## Установка 

- Добавить SysMonitorCard.qml в папку noctalia-shell/Modules/Cards.
- Заменить ControlCenterPanel.qml в папке noctalia-shell/Modules/Panels/ControlCenter
- Заменить ControlCenterTab.qml в папке noctalia-shell/Modules/Panels/Settings/Tabs/ControlCenter

## Установка других карточек

- Добавить ваш виджет в папку Cards (например, SysMonitorCard.qml).

- Внести изменения в ControlCenterPanel.qml:

    - Добавить новую константу для высоты вашего виджета
    ```
    readonly property int sysMonitorHeight: Math.round(120 * Style.uiScaleRatio)

    ```

    - Добавить новый Component с вашим виджетом
    ```
    Component {
        id: sysMonitorCard
        SysMonitorCard {}
    }

    ```

    - Обновить preferredHeight для учета высоты вашего виджета
    ```
        preferredHeight: {
        ...
        case "sysmonitor-card": 
                height += sysMonitorHeight;
                break;
        ...

    ```

    - Добавить новый элемент в Repeater

    ```
        ...
            case "sysmonitor-card": 
                return sysMonitorHeight
        ...

    ```

    - Зарегистрировать в ControlCenterTab.qml:
    ```
        ...
            {
                "id": "sysmonitor-card",
                "text": "System Monitor",
                "enabled": true,
                "required": false
            }
        ...

    ```
