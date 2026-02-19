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

  // Test mode: set to "clear_day", "clear_night", "rain", "snow", "cloud" or "fog"
  property string testEffects: ""

  // Weather condition detection
  readonly property int currentWeatherCode: weatherReady ? LocationService.data.weather.current_weather.weathercode : 0
  readonly property bool isDayTime: weatherReady ? LocationService.data.weather.current_weather.is_day : true
  readonly property bool isRaining: testEffects === "rain" || (testEffects === "" && ((currentWeatherCode >= 51 && currentWeatherCode <= 67) || (currentWeatherCode >= 80 && currentWeatherCode <= 82)))
  readonly property bool isSnowing: testEffects === "snow" || (testEffects === "" && ((currentWeatherCode >= 71 && currentWeatherCode <= 77) || (currentWeatherCode >= 85 && currentWeatherCode <= 86)))
  readonly property bool isCloudy: testEffects === "cloud" || (testEffects === "" && (currentWeatherCode === 3))
  readonly property bool isFoggy: testEffects === "fog" || (testEffects === "" && (currentWeatherCode >= 40 && currentWeatherCode <= 49))
  readonly property bool isClearDay: testEffects === "clear_day" || (testEffects === "" && (currentWeatherCode === 0 && isDayTime))
  readonly property bool isClearNight: testEffects === "clear_night" || (testEffects === "" && (currentWeatherCode === 0 && !isDayTime))

  visible: Settings.data.location.weatherEnabled
  implicitHeight: Math.max(100 * Style.uiScaleRatio, content.implicitHeight + (Style.marginXL * 2))

  // Weather effect layer (rain/snow)
  Loader {
    id: weatherEffectLoader
    anchors.fill: parent
    active: root.showEffects && (root.isRaining || root.isSnowing || root.isCloudy || root.isFoggy || root.isClearDay || root.isClearNight)

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
        // Rain matches content margins, everything else fills the box
        anchors.margins: root.isRaining ? Style.marginXL : root.border.width

        property var source: ShaderEffectSource {
          sourceItem: content
          hideSource: root.isRaining // Only hide for rain (distortion), show for snow
        }

        property real time: parent.shaderTime
        property real itemWidth: weatherEffect.width
        property real itemHeight: weatherEffect.height
        property color bgColor: root.color
        property real cornerRadius: root.isRaining ? 0 : (root.radius - root.border.width)
        property real alternative: root.isFoggy

        fragmentShader: {
          let shaderName;
          if (root.isSnowing)
            shaderName = "weather_snow";
          else if (root.isRaining)
            shaderName = "weather_rain";
          else if (root.isCloudy || root.isFoggy)
            shaderName = "weather_cloud";
          else if (root.isClearDay)
            shaderName = "weather_sun";
          else if (root.isClearNight)
            shaderName = "weather_stars";
          else
            shaderName = "";

          return Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/" + shaderName + ".frag.qsb");
        }
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
            width: parent.width * 0.3
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
                    color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.7)
                }
                
                // Текущая температура
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!weatherReady) return "";
                        var temp = LocationService.data.weather.current_weather.temperature;
                        var suffix = Settings.data.location.useFahrenheit ? "°F" : "°C";
                        if (Settings.data.location.useFahrenheit) {
                            temp = LocationService.celsiusToFahrenheit(temp);
                        }
                        temp = Math.round(temp);
                        return `${temp}${suffix}`;
                    }
                    pointSize: Style.fontSizeXXXL * 1.2
                    font.weight: Style.fontWeightBold
                    color: Color.mTertiary
                    opacity: 0.8
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
            width: parent.width * 0.7 - Style.marginL
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
                                    spacing: 5
                                    NIcon {
                                        icon: "arrow-big-up-lines-filled"
                                        pointSize: Style.fontSizeS
                                        color: '#dd434a'
                                        verticalAlignment: Image.AlignVCenter
                                        height: parent.height
                                    }

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
                                        icon: "arrow-big-down-lines-filled"
                                        pointSize: Style.fontSizeS
                                        color: '#1aa9ae'
                                        verticalAlignment: Image.AlignVCenter
                                        height: parent.height
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
                                        color: Color.mOnSurface
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
                        color: index % 2 === 0 ?  Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.2) : Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.1) 
                        radius: 4
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: {
                            dayBackground.color = Qt.rgba(Color.mOnSurface.r, Color.mOnSurface.g, Color.mOnSurface.b, 0.3);
                            if (weatherReady) {
                                dayPopup.open();
                            }
                        }
                        
                        onExited: {
                            dayBackground.color = index % 2 === 0 ?  Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.2) : Qt.rgba(Color.mHover.r, Color.mHover.g, Color.mHover.b, 0.1) 
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
                            Layout.preferredWidth: 50 * Style.uiScaleRatio
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
                            color: Color.mPrimary
                            pointSize: Style.fontSizeL
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
                            color: Color.mPrimary
                        }
                        
                        Item { 
                            Layout.fillWidth: true
                        }
                        
                        // Температуры 
                        RowLayout {
                            spacing: Style.marginXS
                            
                            NText {
                                Layout.preferredWidth: 50 * Style.uiScaleRatio
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignRight
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
                                color: Color.mPrimary
                                pointSize: Style.fontSizeL
                            }

                            Item { 
                                Layout.fillWidth: true
                            }

                            NText {
                                Layout.preferredWidth: 50 * Style.uiScaleRatio
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
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
                                color: Color.mPrimary
                                pointSize: Style.fontSizeM
                            }
                        }

                        Item { 
                            Layout.fillWidth: true
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