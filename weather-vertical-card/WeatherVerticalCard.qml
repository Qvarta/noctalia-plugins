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
                spacing: Style.marginS
                
                // Иконка погоды
                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 70 * Style.uiScaleRatio
                    icon: weatherReady ? LocationService.weatherSymbolFromCode(LocationService.data.weather.current_weather.weathercode) : ""
                    pointSize: Style.fontSizeXXXL * 2.5
                    color: Color.mHover
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
                
                // Описание погоды
                NText {
                    visible: weatherReady
                    text: {
                        if (!weatherReady) return "";
                        var code = LocationService.data.weather.current_weather.weathercode;
                        
                        if (code === 0) return I18n.tr("weather.clear-sky");
                        if (code === 1 || code === 2) return I18n.tr("weather.mainly-clear");
                        if (code === 3) return I18n.tr("weather.overcast");
                        if (code >= 45 && code <= 48) return I18n.tr("weather.fog");
                        if (code >= 51 && code <= 67) return I18n.tr("weather.drizzle");
                        if (code >= 80 && code <= 82) return I18n.tr("weather.rain-showers");
                        if (code >= 71 && code <= 77) return I18n.tr("weather.snow");
                        if (code >= 85 && code <= 86) return I18n.tr("weather.snow");
                        if (code >= 95 && code <= 99) return I18n.tr("weather.thunderstorm");
                        return I18n.tr("weather.partly-cloudy");
                    }
                    pointSize: Style.fontSizeM
                    color: Color.mHover
                    font.weight: Style.fontWeightMedium
                    anchors.horizontalCenter: parent.horizontalCenter
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }
        
        Rectangle {
            width: 2
            height: parent.height
            color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.3)
            visible: weatherReady
        }
        
        // ПРАВАЯ ЧАСТЬ: Прогноз на несколько дней
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
                    width: forecastList.width
                    height: 38 * Style.uiScaleRatio
                    
                    // Фон для каждого дня
                    Rectangle {
                        anchors.fill: parent
                        color: index % 2 === 0 ? Color.mSurfaceVariant : Qt.rgba(Color.mOnSurface.r, Color.mOnSurface.g, Color.mOnSurface.b, 0.07) 
                        radius: 4
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
                            
                            // NText {
                            //     text: "/"
                            //     color: Color.mOnSurface
                            //     pointSize: Style.fontSizeM
                            // }
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