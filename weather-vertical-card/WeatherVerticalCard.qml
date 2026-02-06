import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Location
import qs.Widgets
import QtQuick.Controls

// Weather overview card (placeholder data)
NBox {
  id: root

  property int forecastDays: 6
  property bool showLocation: true
  property bool showEffects: Settings.data.location.weatherShowEffects
  readonly property bool weatherReady: Settings.data.location.weatherEnabled && (LocationService.data.weather !== null)

  // Test mode: set to "rain" or "snow"
  property string testEffects: ""

  // Weather condition detection
  readonly property int currentWeatherCode: weatherReady ? LocationService.data.weather.current_weather.weathercode : 0
  readonly property bool isRaining: testEffects === "rain" || (testEffects === "" && ((currentWeatherCode >= 51 && currentWeatherCode <= 67) || (currentWeatherCode >= 80 && currentWeatherCode <= 82)))
  readonly property bool isSnowing: testEffects === "snow" || (testEffects === "" && ((currentWeatherCode >= 71 && currentWeatherCode <= 77) || (currentWeatherCode >= 85 && currentWeatherCode <= 86)))

  visible: Settings.data.location.weatherEnabled
  implicitHeight: Math.max(320 * Style.uiScaleRatio, content.implicitHeight + (Style.marginXL * 2))

  // Weather effect layer (rain/snow)
  Loader {
    id: weatherEffectLoader
    anchors.fill: parent
    active: root.showEffects && (root.isRaining || root.isSnowing)

    sourceComponent: Item {
      anchors.fill: parent

      // Animated time for shaders
      property real shaderTime: 0
      NumberAnimation on shaderTime {
        loops: Animation.Infinite
        from: 0
        to: 1000
        duration: 100000
      }

      ShaderEffect {
        id: weatherEffect
        anchors.fill: parent
        // Snow fills the box, rain matches content margins
        anchors.margins: root.isSnowing ? root.border.width : Style.marginXL

        property var source: ShaderEffectSource {
          sourceItem: content
          hideSource: root.isRaining // Only hide for rain (distortion), show for snow
        }

        property real time: parent.shaderTime
        property real itemWidth: weatherEffect.width
        property real itemHeight: weatherEffect.height
        property color bgColor: root.color
        property real cornerRadius: root.isSnowing ? (root.radius - root.border.width) : 0

        fragmentShader: root.isSnowing ? Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/weather_snow.frag.qsb") : Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/weather_rain.frag.qsb")
      }
    }
  }

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: Style.marginXL
    spacing: Style.marginM
    clip: true

    // ЗАГОЛОВОК: Название города и часовой пояс
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginXL
        
        NText {
            visible: showLocation && !Settings.data.location.hideWeatherCityName && weatherReady
            text: {
                if (!showLocation || Settings.data.location.hideWeatherCityName || !weatherReady) {
                    return "";
                }
                const chunks = Settings.data.location.name.split(",");
                return chunks[0];
            }
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            elide: Text.ElideRight
        }
        
        NText {
            text: weatherReady ? `(${LocationService.data.weather.timezone_abbreviation})` : ""
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            visible: weatherReady && showLocation && !Settings.data.location.hideWeatherTimezone
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 2 * Style.uiScaleRatio
        }
        
        Item { Layout.fillWidth: true }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 2
        color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.3)
        visible: weatherReady
    }

    // Основная часть
    Row {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.marginL
        
        // ЛЕВАЯ ЧАСТЬ: Текущая погода
        Item {
            width: parent.width * 0.25
            height: parent.height
            
            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Style.marginXL
                
                // Иконка погоды
                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 70 * Style.uiScaleRatio
                    icon: weatherReady ? LocationService.weatherSymbolFromCode(
                        LocationService.data.weather.current_weather.weathercode,
                        LocationService.data.weather.current_weather.is_day
                        ) : ""
                    pointSize: Style.fontSizeXXXL * 3
                    color: Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.7)
                }
                
                // Текущая температура
                NText {
                    visible: weatherReady
                    text: {
                        if (!weatherReady) {
                            return "";
                        }
                        var temp = LocationService.data.weather.current_weather.temperature;
                        var suffix = "°";
                        if (Settings.data.location.useFahrenheit) {
                            temp = LocationService.celsiusToFahrenheit(temp);
                            suffix = "°F";
                        }
                        temp = Math.round(temp);
                        return `${temp}${suffix}`;
                    }
                    pointSize: Style.fontSizeXXXL
                    font.weight: Style.fontWeightBold
                    color: Color.mHover
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        
        Rectangle {
            width: 2
            height: parent.height
            color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.3)
            visible: weatherReady
        }
        
        // ПРАВАЯ ЧАСТЬ: Прогноз на 6 дней
        Item {
            width: parent.width * 0.75 - Style.marginL
            height: parent.height
            
            // Список прогноза
            NListView {
                id: forecastList
                visible: weatherReady
                anchors.fill: parent
                
                orientation: ListView.Vertical
                spacing: Style.marginXXS
                interactive: true
                verticalPolicy: ScrollBar.AlwaysOff
                
                model: weatherReady ? root.forecastDays : 0
                
                delegate: Item {
                    id: dayDelegate
                    width: forecastList.width
                    height: 38 * Style.uiScaleRatio
                    
                    function hPaToMmHg(hpa) {
                        return Math.round(hpa * 0.750062);
                    }
                    
                    function windDirectionToCardinal(degrees) {
                        if (degrees === undefined || degrees === null) return "--";
                        var directions = ["С", "ССВ", "СВ", "ВСВ", "В", "ВЮВ", "ЮВ", "ЮЮВ", "Ю", "ЮЮЗ", "ЮЗ", "ЗЮЗ", "З", "ЗСЗ", "СЗ", "ССЗ"];
                        var index = Math.round((degrees % 360) / 22.5);
                        return directions[index % 16];
                    }
                    
                    // Popup для детальной информации
                    Popup {
                        id: dayPopup
                        visible: false
                        modal: false
                        focus: false
                        closePolicy: Popup.CloseOnPressOutsideParent
                        padding: 0
                        margins: 10
                        
                        x: dayDelegate.width + 20
                        y: -dayDelegate.height * .7
                        
                        width: 360
                        height: popupContent.height + 40
                        
                        background: Rectangle {
                            id: popupBackground
                            radius: 8
                            
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.95) }
                                GradientStop { position: 1.0; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.95) }
                            }
                            
                            border.color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.3)
                            border.width: 1
                        }
                        
                        // Контент Popup
                        Column {
                            id: popupContent
                            anchors.centerIn: parent
                            width: parent.width - 40
                            spacing: 12
                            
                            // Заголовок с датой
                            Column {
                                width: parent.width
                                spacing: 4
                                
                                Text {
                                    text: {
                                        try {
                                            var dailyData = LocationService.data.weather.daily;
                                            if (dailyData && dailyData.time && dailyData.time[index]) {
                                                var dateStr = dailyData.time[index];
                                                var weatherDate = new Date(dateStr.replace(/-/g, "/"));
                                                return I18n.locale.toString(weatherDate, "d MMMM");
                                            }
                                        } catch(e) {
                                            return "";
                                        }
                                        return "";
                                    }
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeL
                                    font.bold: true
                                    color: Color.mTertiary
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                                
                                // Разделитель
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Color.mOutline
                                }
                            }
                            
                            GridLayout {
                                width: parent.width
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 8
                                
                                // Температура
                                Text {
                                    text: "Температура:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }

                                Row {
                                    
                                    Text {
                                        text: {
                                            try {
                                                var dailyData = LocationService.data.weather.daily;
                                                if (dailyData && dailyData.temperature_2m_max) {
                                                    var max = dailyData.temperature_2m_max[index];
                                                    
                                                    if (Settings.data.location.useFahrenheit) {
                                                        max = Math.round(LocationService.celsiusToFahrenheit(max));
                                                    } else {
                                                        max = Math.round(max);
                                                    }
                                                    
                                                    var suffix = Settings.data.location.useFahrenheit ? "°F" : "°C";
                                                    return max + suffix ;
                                                }
                                            } catch(e) {
                                                return "--";
                                            }
                                            return "--";
                                        }
                                        font.family: Settings.data.ui.fontFixed
                                        font.pointSize: Style.fontSizeM
                                        color: Color.mOnSurface
                                    }
                                    
                                    NIcon {
                                        icon: "dots-vertical"
                                        pointSize: Style.fontSizeM
                                        color: Color.mHover
                                        verticalAlignment: Image.AlignVCenter
                                    }
                                    
                                    Text {
                                        text: {
                                            try {
                                                var dailyData = LocationService.data.weather.daily;
                                                if (dailyData && dailyData.temperature_2m_min) {
                                                    var min = dailyData.temperature_2m_min[index];
                                                    
                                                    if (Settings.data.location.useFahrenheit) {
                                                        min = Math.round(LocationService.celsiusToFahrenheit(min));
                                                    } else {
                                                        min = Math.round(min);
                                                    }
                                                    
                                                    var suffix = Settings.data.location.useFahrenheit ? "°F" : "°C";
                                                    return min + suffix;
                                                }
                                            } catch(e) {
                                                return "--";
                                            }
                                            return "--";
                                        }
                                        font.family: Settings.data.ui.fontFixed
                                        font.pointSize: Style.fontSizeM
                                        color: Color.mOnSurface
                                    }
                                }

                                // Text {
                                //     text: {
                                //         try {
                                //             var dailyData = LocationService.data.weather.daily;
                                //             if (dailyData && dailyData.temperature_2m_max && dailyData.temperature_2m_min) {
                                //                 var max = dailyData.temperature_2m_max[index];
                                //                 var min = dailyData.temperature_2m_min[index];
                                                
                                //                 if (Settings.data.location.useFahrenheit) {
                                //                     max = Math.round(LocationService.celsiusToFahrenheit(max));
                                //                     min = Math.round(LocationService.celsiusToFahrenheit(min));
                                //                 } else {
                                //                     max = Math.round(max);
                                //                     min = Math.round(min);
                                //                 }
                                                
                                //                 var suffix = Settings.data.location.useFahrenheit ? "°F" : "°C";
                                //                 return max + suffix + " / " + min + suffix;
                                //             }
                                //         } catch(e) {
                                //             return "--";
                                //         }
                                //         return "--";
                                //     }
                                //     font.family: Settings.data.ui.fontFixed
                                //     font.pointSize: Style.fontSizeM
                                //     color: Color.mPrimary
                                // }
                                
                                // Погодные условия
                                Text {
                                    text: "Состояние:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                Text {
                                    text: {
                                        try {
                                            var dailyData = LocationService.data.weather.daily;
                                            if (dailyData && dailyData.weathercode) {
                                                var code = dailyData.weathercode[index];
                                                var condition =  LocationService.weatherDescriptionFromCode(code).toLowerCase();
                                                condition = condition.replace(/\s+/g, '-');
                                                return I18n.tr(`weather.${condition}`);
                                            }
                                        } catch(e) {
                                            return "--";
                                        }
                                        return "--";
                                    }
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                // Ветер
                                Text {
                                    text: "Ветер:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeS
                                    color:Color.mOnSurface
                                }
                                
                                Row {
                                    spacing: 3
                                    
                                    Text {
                                        text: {
                                            try {
                                                var dailyData = LocationService.data.weather.daily;
                                                if (dailyData && dailyData.wind_speed_10m_max) {
                                                    var speed = dailyData.wind_speed_10m_max[index];
                                                    return speed.toFixed(1) + " м/с";
                                                }
                                            } catch(e) {
                                                return "--";
                                            }
                                            return "--";
                                        }
                                        font.family: Settings.data.ui.fontFixed
                                        font.pointSize: Style.fontSizeM
                                        color: Color.mOnSurface
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    NIcon {
                                        icon: "windsock"
                                        pointSize: Style.fontSizeL
                                        color: Color.mHover
                                        verticalAlignment: Image.AlignVCenter
                                    }
                                    
                                    Text {
                                        text: {
                                            try {
                                                var dailyData = LocationService.data.weather.daily;
                                                if (dailyData && dailyData.wind_direction_10m_dominant) {
                                                    var dir = dailyData.wind_direction_10m_dominant[index];
                                                    return windDirectionToCardinal(dir);
                                                }
                                            } catch(e) {
                                                return "";
                                            }
                                            return "";
                                        }
                                        font.family: Settings.data.ui.fontFixed
                                        font.pointSize: Style.fontSizeM
                                        color: Color.mOnSurface
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                                
                                // Влажность
                                Text {
                                    text: "Влажность:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                Text {
                                    text: {
                                        try {
                                            var dailyData = LocationService.data.weather.daily;
                                            if (dailyData && dailyData.relative_humidity_2m_mean) {
                                                var humidity = dailyData.relative_humidity_2m_mean[index];
                                                return humidity + "%";
                                            }
                                        } catch(e) {
                                            return "--";
                                        }
                                        return "--";
                                    }
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                // Давление 
                                Text {
                                    text: "Давление:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                Text {
                                    text: {
                                        try {
                                            var dailyData = LocationService.data.weather.daily;
                                            if (dailyData && dailyData.surface_pressure_mean) {
                                                var pressureHpa = dailyData.surface_pressure_mean[index];
                                                var pressureMmHg = hPaToMmHg(pressureHpa);
                                                return pressureMmHg + " мм.рт.ст";
                                            }
                                        } catch(e) {
                                            return "--";
                                        }
                                        return "--";
                                    }
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                // Восход
                                Text {
                                    text: "Восход:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                Text {
                                    text: {
                                        try {
                                            var dailyData = LocationService.data.weather.daily;
                                            if (dailyData && dailyData.sunrise) {
                                                var sunrise = dailyData.sunrise[index];
                                                var sunriseTime = new Date(sunrise.replace(/-/g, "/"));
                                                return I18n.locale.toString(sunriseTime, "HH:mm");
                                            }
                                        } catch(e) {
                                            return "--";
                                        }
                                        return "--";
                                    }
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                // Закат
                                Text {
                                    text: "Закат:"
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                                
                                Text {
                                    text: {
                                        try {
                                            var dailyData = LocationService.data.weather.daily;
                                            if (dailyData && dailyData.sunset) {
                                                var sunset = dailyData.sunset[index];
                                                var sunsetTime = new Date(sunset.replace(/-/g, "/"));
                                                return I18n.locale.toString(sunsetTime, "HH:mm");
                                            }
                                        } catch(e) {
                                            return "--";
                                        }
                                        return "--";
                                    }
                                    font.family: Settings.data.ui.fontFixed
                                    font.pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }
                            }
                        }
                        
                        // Анимация появления
                        enter: Transition {
                            ParallelAnimation {
                                NumberAnimation { 
                                    property: "opacity"; 
                                    from: 0; 
                                    to: 1; 
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation { 
                                    property: "scale"; 
                                    from: 0.95; 
                                    to: 1; 
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        
                        // Анимация скрытия
                        exit: Transition {
                            ParallelAnimation {
                                NumberAnimation { 
                                    property: "opacity"; 
                                    from: 1; 
                                    to: 0; 
                                    duration: 100
                                    easing.type: Easing.InCubic
                                }
                                NumberAnimation { 
                                    property: "scale"; 
                                    from: 1; 
                                    to: 0.98; 
                                    duration: 100
                                    easing.type: Easing.InCubic
                                }
                            }
                        }
                    }
                    
                    // Фон для каждого дня
                    Rectangle {
                        id: dayBackground
                        anchors.fill: parent
                        color: index % 2 === 0 ? Color.mSurfaceVariant : Qt.rgba(Color.mOnSurface.r, Color.mOnSurface.g, Color.mOnSurface.b, 0.07) 
                        radius: 4
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: {
                            dayBackground.color = Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.15);
                            if (weatherReady) {
                                dayPopup.open();
                            }
                        }
                        
                        onExited: {
                            dayBackground.color = index % 2 === 0 ? Color.mSurfaceVariant : Qt.rgba(Color.mOnSurface.r, Color.mOnSurface.g, Color.mOnSurface.b, 0.07);
                            dayPopup.close();
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Style.marginXS
                        spacing: Style.marginS

                        Item { 
                            Layout.preferredWidth: 10
                        }

                        // День недели 
                        NText {
                            Layout.preferredWidth: 70 * Style.uiScaleRatio
                            Layout.alignment: Qt.AlignVCenter
                            text: {
                                if (!weatherReady) return "";
                                
                                try {
                                    var dailyData = LocationService.data.weather.daily;
                                    if (dailyData && dailyData.time && dailyData.time[index]) {
                                        var weatherDate = new Date(dailyData.time[index].replace(/-/g, "/"));
                                        var dayName = I18n.locale.toString(weatherDate, "ddd");
                                        return dayName;
                                    }
                                } catch(e) {
                                    return "";
                                }
                                return "";
                            }
                            color: Color.mOnSurface
                            pointSize: Style.fontSizeM
                        }
                        
                        // Иконка погоды 
                        NIcon {
                            Layout.preferredWidth: 30 * Style.uiScaleRatio
                            Layout.preferredHeight: 30 * Style.uiScaleRatio
                            Layout.alignment: Qt.AlignVCenter
                            icon: {
                                if (!weatherReady) return "";
                                
                                try {
                                    var dailyData = LocationService.data.weather.daily;
                                    if (dailyData && dailyData.weathercode && dailyData.weathercode[index] !== undefined) {
                                        return LocationService.weatherSymbolFromCode(dailyData.weathercode[index]);
                                    }
                                } catch(e) {
                                    return "";
                                }
                                return "";
                            }
                            pointSize: Style.fontSizeXXL
                            color: Color.mOnSurface
                        }
                        
                        Item { 
                            Layout.fillWidth: true
                        }
                        
                        // Температуры
                        Row {
                            spacing: Style.marginXS
                            
                            NText {
                                text: {
                                    if (!weatherReady) return "--°";
                                    
                                    try {
                                        var dailyData = LocationService.data.weather.daily;
                                        if (dailyData && dailyData.temperature_2m_max && 
                                            dailyData.temperature_2m_max[index] !== undefined) {
                                            var max = dailyData.temperature_2m_max[index];
                                            if (Settings.data.location.useFahrenheit) {
                                                max = LocationService.celsiusToFahrenheit(max);
                                            }
                                            max = Math.round(max);
                                            return `${max}°`;
                                        }
                                    } catch(e) {
                                        return "--°";
                                    }
                                    return "--°";
                                }
                                color: Color.mOnSurface
                                pointSize: Style.fontSizeS
                            }

                            NIcon {
                            Layout.alignment: Qt.AlignVCenter
                            icon: "dots-vertical"
                            pointSize: Style.fontSizeM
                            color: Color.mOnSurface
                            }
                            
                            NText {
                                text: {
                                    if (!weatherReady) return "--°";
                                    
                                    try {
                                        var dailyData = LocationService.data.weather.daily;
                                        if (dailyData && dailyData.temperature_2m_min && 
                                            dailyData.temperature_2m_min[index] !== undefined) {
                                            var min = dailyData.temperature_2m_min[index];
                                            if (Settings.data.location.useFahrenheit) {
                                                min = LocationService.celsiusToFahrenheit(min);
                                            }
                                            min = Math.round(min);
                                            return `${min}°`;
                                        }
                                    } catch(e) {
                                        return "--°";
                                    }
                                    return "--°";
                                }
                                color: Color.mOnSurface
                                pointSize: Style.fontSizeS
                            }
                        }

                        Item { 
                            Layout.preferredWidth: 20
                        }
                    }
                }
            }
        }
    }

    Loader {
      active: !weatherReady
      Layout.alignment: Qt.AlignCenter
      sourceComponent: NBusyIndicator {}
    }
  }
}