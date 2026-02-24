import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Media

Item {
  id: root

  property var pluginApi: null
  property string widgetId: ""
  property string section: ""

  readonly property int headerHeight: 35
  readonly property int loadingHeight: isFetchingLyrics ? 25 : 0
  readonly property int hintHeight: (!isFetchingLyrics && lyricsLines.length === 0 && 
                                    MediaService.currentPlayer != null && 
                                    MediaService.trackArtist && 
                                    MediaService.trackTitle) ? 20 : 0
  readonly property int lyricsAreaHeight: {
    if (lyricsLines.length === 0 || isFetchingLyrics) return 0;
    if (lyricsLines.length < 4) return Math.min(140, lyricsLines.length * 40);
    return 160;
  }
  readonly property int typeHeight: (lyricsLines.length > 0) ? 15 : 0

  property real contentPreferredWidth: 350
  property real contentPreferredHeight: 5 + headerHeight + loadingHeight + hintHeight + lyricsAreaHeight + typeHeight + 5

  // Данные для текста песни
  property string lyricsText: ""
  property var lyricsLines: []
  property var lyricsTimes: []
  property bool isFetchingLyrics: false
  property bool useSyncedLyrics: false

  // Текущая позиция 
  property int currentPosition: MediaService.currentPosition

  function fetchLyrics(artist, track) {
    if (!artist || !track || artist === "" || track === "") {
      lyricsText = "Исполнитель или название трека не указаны";
      lyricsLines = [];
      lyricsTimes = [];
      return;
    }

    if (isFetchingLyrics) return;

    isFetchingLyrics = true;
    lyricsText = "Запрашиваю текст...";
    lyricsLines = [];
    lyricsTimes = [];

    var encodedArtist = encodeURIComponent(artist);
    var encodedTrack = encodeURIComponent(track);
    var apiUrl = "https://lrclib.net/api/get?artist_name=" + encodedArtist + "&track_name=" + encodedTrack;

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            var response = JSON.parse(xhr.responseText);
            
            var syncedLyrics = response.syncedLyrics || "";
            var plainLyrics = response.plainLyrics || "";
            
            if (syncedLyrics !== "" && syncedLyrics !== null) {
              console.log("Synced lyrics found");
              useSyncedLyrics = true;
              
              // Разбираем синхронизированный текст
              var lines = syncedLyrics.split('\n');
              var textLines = [];
              var times = [];
              
              for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "") continue;
                
                // Ищем временную метку в начале строки
                var match = line.match(/^\[(\d+):(\d+\.\d+)\]\s*(.*)$/);
                if (match) {
                  var minutes = parseInt(match[1]);
                  var seconds = parseFloat(match[2]);
                  var timeInSeconds = minutes * 60 + seconds;
                  var text = match[3];
                  
                  times.push(timeInSeconds);
                  textLines.push(text);
                }
              }
              
              lyricsLines = textLines;
              lyricsTimes = times;
              lyricsText = syncedLyrics;
              
              console.log("Parsed", textLines.length, "lines with times");
              
            } else if (plainLyrics !== "" && plainLyrics !== null) {
              console.log("Plain lyrics found");
              useSyncedLyrics = false;
              var plainLines = plainLyrics.split('\n').filter(line => line.trim() !== "");
              lyricsLines = plainLines;
              lyricsTimes = [];
              lyricsText = plainLyrics;
            } else {
              lyricsText = "Текст не найден";
              lyricsLines = ["Текст не найден"];
              lyricsTimes = [];
            }
            
          } catch (e) {
            lyricsText = "Ошибка парсинга ответа";
            lyricsLines = ["Ошибка парсинга ответа"];
            lyricsTimes = [];
            console.error("Failed to parse lyrics data:", e);
          }
        } else if (xhr.status === 404) {
          lyricsText = "Текст не найден";
          lyricsLines = ["Текст не найден"];
          lyricsTimes = [];
        } else {
          lyricsText = "Ошибка: " + xhr.status;
          lyricsLines = ["Ошибка: " + xhr.status];
          lyricsTimes = [];
        }
        isFetchingLyrics = false;
      }
    };
    
    xhr.onerror = function() {
      lyricsText = "Сетевая ошибка";
      lyricsLines = ["Сетевая ошибка"];
      lyricsTimes = [];
      isFetchingLyrics = false;
    };
    
    xhr.open("GET", apiUrl);
    xhr.setRequestHeader("User-Agent", "noctalia-shell/1.0");
    xhr.send();
  }

  property int currentLineIndex: {
    if (!useSyncedLyrics || lyricsTimes.length === 0 || lyricsLines.length === 0) {
      return -1;
    }
    
    var pos = currentPosition;
    
    // Ищем строку, время которой меньше или равно текущей позиции
    // и следующая строка имеет большее время
    for (var i = lyricsTimes.length - 1; i >= 0; i--) {
      if (pos >= lyricsTimes[i]) {
        // Проверяем, не закончилась ли текущая строка
        if (i < lyricsTimes.length - 1 && pos >= lyricsTimes[i + 1]) {
          continue;
        }
        return i;
      }
    }
    
    return -1;
  }

  onCurrentLineIndexChanged: {
    if (useSyncedLyrics && currentLineIndex >= 0) {
      lyricsList.currentIndex = currentLineIndex;
    }
  }

  // Основной фон
  Rectangle {
    anchors.fill: parent
    color: "#1e1e2e"
    radius: 8
    border.width: 1
    border.color: "#313244"
  }

  Item {
    anchors.fill: parent
    anchors.margins: 5

    // Верхняя строка с информацией о треке
    Row {
      x: 0
      y: 0
      width: parent.width
      height: 30
      spacing: 5

      // Информация о треке
      Column {
        width: parent.width - 35
        height: parent.height

        Text {
          width: parent.width
          text: MediaService.trackArtist || "No artist"
          color: "#89b4fa"
          font.pixelSize: 10
          font.capitalization: Font.AllUppercase
          elide: Text.ElideRight
        }

        // Название трека как кнопка
        Rectangle {
          width: parent.width
          height: 16
          color: mouseArea.containsMouse ? "#313244" : "transparent"
          radius: 4

          Text {
            id: titleText
            anchors.centerIn: parent
            text: MediaService.trackTitle || "No title"
            color: mouseArea.containsMouse ? "#cdd6f4" : "#ffffff"
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: MediaService.currentPlayer != null && 
                    MediaService.trackArtist && 
                    MediaService.trackTitle && 
                    !isFetchingLyrics

            onClicked: {
              if (MediaService.trackArtist && MediaService.trackTitle) {
                fetchLyrics(MediaService.trackArtist, MediaService.trackTitle);
              }
            }
          }
        }
      }

      // Кнопка закрытия
      Rectangle {
        width: 30
        height: 30
        color: closeMouse.containsMouse ? "#f38ba8" : "transparent"
        radius: 4

        Text {
          anchors.centerIn: parent
          text: "✕"
          color: closeMouse.containsMouse ? "#ffffff" : "#cdd6f4"
          font.pixelSize: 14
        }

        MouseArea {
          id: closeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (pluginApi) {
              pluginApi.closePanel(pluginApi.panelOpenScreen)
            }
          }
        }
      }
    }

    // Индикатор загрузки
    Row {
      x: 0
      y: headerHeight
      width: parent.width
      height: loadingHeight
      visible: isFetchingLyrics
      spacing: 5

      Rectangle {
        width: 20
        height: 20
        color: "transparent"

        Text {
          anchors.centerIn: parent
          text: "⟳"
          color: "#89b4fa"
          font.pixelSize: 16
          rotation: 0
          NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
          }
        }
      }

      Text {
        text: "Загрузка текста..."
        color: "#89b4fa"
        font.pixelSize: 11
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // Подсказка
    Text {
      x: 0
      y: headerHeight + loadingHeight
      width: parent.width
      height: hintHeight
      visible: height > 0
      text: "👆 нажмите на название для загрузки текста"
      color: "#6c7086"
      font.pixelSize: 10
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    // Текст песни
    Item {
      x: 0
      y: headerHeight + loadingHeight + hintHeight
      width: parent.width
      height: lyricsAreaHeight
      visible: height > 0
      clip: true

      ListView {
        id: lyricsList
        anchors.fill: parent
        model: useSyncedLyrics ? lyricsLines : lyricsLines
        spacing: 2
        currentIndex: -1
        highlightMoveDuration: 250
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0.4
        preferredHighlightEnd: 0.6

        highlight: Rectangle {
          color: "#313244"
          radius: 4
          opacity: 0.5
        }

        delegate: Item {
          width: lyricsList.width
          height: {
            if (useSyncedLyrics && index === currentLineIndex) {
              return textCurrentItem.height + 16;
            }
            return textNormalItem.height + 8;
          }

          Text {
            id: textNormalItem
            anchors.centerIn: parent
            visible: !(useSyncedLyrics && index === currentLineIndex)
            text: modelData
            color: {
              if (useSyncedLyrics && index < currentLineIndex) return "#6c7086";
              if (useSyncedLyrics && index > currentLineIndex) return "#cdd6f4";
              return "#ffffff";
            }
            opacity: {
              if (useSyncedLyrics && index < currentLineIndex) return 0.4;
              if (useSyncedLyrics && index > currentLineIndex) return 0.7;
              return 1.0;
            }
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - 10
          }

          Text {
            id: textCurrentItem
            anchors.centerIn: parent
            visible: useSyncedLyrics && index === currentLineIndex
            text: modelData
            color: "#89b4fa"
            font.pixelSize: 18
            font.bold: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - 10
          }
        }

        ScrollBar.vertical: ScrollBar {
          policy: ScrollBar.AsNeeded
          width: 4
          background: Rectangle { color: "transparent" }
          contentItem: Rectangle {
            color: "#89b4fa"
            radius: 2
            opacity: 0.3
          }
        }
      }
    }

    // Тип текста
    Text {
      x: 0
      y: headerHeight + loadingHeight + hintHeight + lyricsAreaHeight
      width: parent.width
      height: typeHeight
      visible: height > 0
      text: useSyncedLyrics ? "🎤 синхронизировано" : "📝 текст"
      color: "#6c7086"
      font.pixelSize: 9
      horizontalAlignment: Text.AlignRight
    }
  }
}