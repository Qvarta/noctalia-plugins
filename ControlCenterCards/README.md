# System Monitor для Control Center

<img width="428" height="207" alt="preview" src="https://github.com/user-attachments/assets/b4d4971b-64ba-4b04-a8f5-b285cd4bc59f" />

# Weather Vertical для Control Center

<img width="431" height="350" alt="preview" src="https://github.com/user-attachments/assets/0423e1fa-e5ff-4202-badf-97c33039c4a2" />

## Установка 

- Запустить install.sh
- Выбрать карточку в настройках центра управления

## Установка кастомных карточек

- Добавить ваш виджет в папку Cards (например, SysMonitorCard.qml).

- Внести изменения в ControlCenterPanel.qml:

  - Добавить новый Component с вашим виджетом
    ```
    Component {
        id: sysMonitorCard
        SysMonitorCard {}
    }

    ```

    - Добавить новую константу для высоты вашего виджета
    ```
    readonly property int sysMonitorHeight: Math.round(120 * Style.uiScaleRatio)

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
    Layout.preferredHeight: 
        ...
            case "sysmonitor-card": 
                return sysMonitorHeight
        ...

    ```
            и
  
    ```
        sourceComponent: {
            ...
                case "sysmonitor-card":
                  return sysMonitorCard;
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
