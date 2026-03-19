import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.Media
import qs.Services.UI
import qs.Widgets
import qs.Widgets.AudioSpectrum

SmartPanel {
  id: root

  preferredWidth: Math.round((root.isSideBySide ? 480 : 400) * Style.uiScaleRatio)
  preferredHeight: Math.round(calculatePreferredHeight() * Style.uiScaleRatio)

  function calculatePreferredHeight() {
    var baseHeight = 0;
    
    // Заголовок (NBox)
    baseHeight += 48; 
    
    if (root.showLyrics) {
      baseHeight += 300; 
    } else {
      baseHeight += 60;
    }
    
    // Область текста (lyricsBox)
    if (root.showLyrics) {
      if (MediaService.isFetchingLyrics) {
        baseHeight += 20; 
      } else if (MediaService.hasLyrics) {
        var linesCount = Math.min(MediaService.lyricsLines.length, 10);
        baseHeight += 40 + (linesCount * 24);
      } else {
        baseHeight += 20; 
      }
    }
    
    baseHeight += Style.marginL * 3; 
    
    return baseHeight;
  }

  property var mediaMiniSettings: {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    return widget ? widget.widgetSettings : null;
  }

  function refreshMediaMiniSettings() {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    root.mediaMiniSettings = widget ? widget.widgetSettings : null;
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      root.refreshMediaMiniSettings();
    }
  }

  Connections {
    target: Settings
    function onSettingsSaved() {
      root.refreshMediaMiniSettings();
    }
  }

  readonly property string visualizerType: (mediaMiniSettings && mediaMiniSettings.visualizerType !== undefined) ? mediaMiniSettings.visualizerType : "linear"
  readonly property bool showArtistFirst: !!(mediaMiniSettings && mediaMiniSettings.showArtistFirst !== undefined ? mediaMiniSettings.showArtistFirst : true)
  readonly property bool showAlbumArt: !!(mediaMiniSettings && mediaMiniSettings.panelShowAlbumArt !== undefined ? mediaMiniSettings.panelShowAlbumArt : true)
  readonly property bool showVisualizer: !!(mediaMiniSettings && mediaMiniSettings.showVisualizer !== undefined ? mediaMiniSettings.showVisualizer : true)
  readonly property bool compactMode: !!(mediaMiniSettings && mediaMiniSettings.compactMode !== undefined ? mediaMiniSettings.compactMode : false)
  readonly property string scrollingMode: (mediaMiniSettings && mediaMiniSettings.scrollingMode !== undefined) ? mediaMiniSettings.scrollingMode : "hover"
  readonly property bool showLyrics: true

  readonly property bool isSideBySide: root.compactMode && root.showAlbumArt

  readonly property bool needsCava: root.showVisualizer && root.visualizerType !== "" && root.visualizerType !== "none" && root.isPanelOpen

  onNeedsCavaChanged: {
    if (root.needsCava) {
      CavaService.registerComponent("mediaplayerpanel");
    } else {
      CavaService.unregisterComponent("mediaplayerpanel");
    }
  }

  // Динамическая высота области с текстом
  readonly property int lyricsAreaHeight: {
    if (MediaService.isFetchingLyrics) {
      return 20; 
    } else if (MediaService.hasLyrics) {
      var displayLines = Math.min(MediaService.lyricsLines.length, 10);
      return 40 + (displayLines * 24); 
    } else {
      return 20;
    }
  }

  readonly property int loadingHeight: MediaService.isFetchingLyrics ? 25 : 0
  readonly property int typeHeight: (MediaService.hasLyrics && !MediaService.isFetchingLyrics) ? 15 : 0

  Component.onCompleted: {
    if (root.needsCava) {
      CavaService.registerComponent("mediaplayerpanel");
    }
  }

  Component.onDestruction: {
    CavaService.unregisterComponent("mediaplayerpanel");
  }

  panelContent: Item {
    id: playerContent
    anchors.fill: parent

    readonly property real contentPreferredHeight: root.preferredHeight

    property Component visualizerSource: {
      switch (root.visualizerType) {
      case "linear":
        return linearComponent;
      case "mirrored":
        return mirroredComponent;
      case "wave":
        return waveComponent;
      default:
        return null;
      }
    }

    ColumnLayout {
      id: mainLayout
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginL
      z: 1

    // Заголовок
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginXL

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: "music"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
          }

          NText {
            text: I18n.tr("common.media-player")
            font.weight: Style.fontWeightBold
            pointSize: Style.fontSizeL
            color: Color.mOnSurface
            Layout.fillWidth: true
          }

          Rectangle {
            radius: Style.radiusS
            color: playerSelectorMouse.containsMouse ? Color.mPrimary : "transparent"
            implicitWidth: playerRow.implicitWidth + Style.marginM
            implicitHeight: Style.baseWidgetSize * 0.8
            visible: MediaService.getAvailablePlayers().length > 1

            RowLayout {
              id: playerRow
              anchors.centerIn: parent
              spacing: Style.marginXS

              NText {
                text: MediaService.currentPlayer ? MediaService.currentPlayer.identity : "Select Player"
                pointSize: Style.fontSizeXS
                color: playerSelectorMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurfaceVariant
              }
              NIcon {
                icon: "chevron-down"
                pointSize: Style.fontSizeXS
                color: playerSelectorMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurfaceVariant
              }
            }

            MouseArea {
              id: playerSelectorMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: playerContextMenu.open()
            }

            Popup {
              id: playerContextMenu
              x: 0
              y: parent.height
              width: 160
              padding: Style.marginS

              background: Rectangle {
                color: Color.mSurfaceVariant
                border.color: Color.mOutline
                border.width: Style.borderS
                radius: Style.iRadiusM
              }

              contentItem: ColumnLayout {
                spacing: 0
                Repeater {
                  model: MediaService.getAvailablePlayers()
                  delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "transparent"

                    Rectangle {
                      anchors.fill: parent
                      color: itemMouse.containsMouse ? Color.mPrimary : "transparent"
                      radius: Style.iRadiusS
                    }

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: Style.marginS
                      spacing: Style.marginS

                      NIcon {
                        visible: MediaService.currentPlayer && MediaService.currentPlayer.identity === modelData.identity
                        icon: "check"
                        color: itemMouse.containsMouse ? Color.mOnPrimary : Color.mPrimary
                        pointSize: Style.fontSizeS
                      }

                      NText {
                        text: modelData.identity
                        pointSize: Style.fontSizeS
                        color: itemMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                      }
                    }

                    MouseArea {
                      id: itemMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        MediaService.currentPlayer = modelData;
                        playerContextMenu.close();
                      }
                    }
                  }
                }
              }
            }
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.close()
          }
        }
      }

      // Основная область
      NBox {
        id: mediaBox
        Layout.fillWidth: true
        Layout.preferredHeight: root.showLyrics ? 200 * Style.uiScaleRatio : 110 * Style.uiScaleRatio
        radius: Style.iRadiusL

        // Visualizer background for content area
        Loader {
          anchors.fill: parent
          z: 0
          active: !!(root.needsCava && !root.showAlbumArt)
          sourceComponent: visualizerSource
        }

        // Градиентный оверлей для визуала
        Rectangle {
          anchors.fill: parent
          radius: parent.radius
          color: "transparent"
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 0.8; color: Qt.rgba(0, 0, 0, 0.1) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
          }
          visible: root.needsCava && root.showAlbumArt
        }

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginL

          // Album Art 
          Item {
            id: albumArtItem
            Layout.preferredWidth: root.compactMode ? 90 * Style.uiScaleRatio : 110 * Style.uiScaleRatio
            Layout.preferredHeight: root.compactMode ? 90 * Style.uiScaleRatio : 110 * Style.uiScaleRatio
            Layout.alignment: Qt.AlignVCenter
            visible: root.showAlbumArt

            NImageRounded {
              anchors.fill: parent
              radius: Style.iRadiusM
              imagePath: MediaService.trackArtUrl
              imageFillMode: Image.PreserveAspectCrop
              fallbackIcon: "disc"
              fallbackIconSize: Style.fontSizeXXXL * 2
              borderWidth: 0

              // Тень для обложки
              layer.enabled: true
              layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Color.mHover
                shadowBlur: 0.5
                shadowOpacity: 0.5
                shadowHorizontalOffset: 2
                shadowVerticalOffset: 2
              }
            }
          }

          // Информация о треке и контролы
          ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.marginS

            // Информация о треке
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                Layout.fillWidth: true
                text: MediaService.trackTitle || "No Media"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              NText {
                Layout.fillWidth: true
                text: {
                  if (MediaService.trackArtist && MediaService.trackAlbum) {
                    return MediaService.trackArtist + " • " + MediaService.trackAlbum;
                  } else if (MediaService.trackArtist) {
                    return MediaService.trackArtist;
                  } else if (MediaService.trackAlbum) {
                    return MediaService.trackAlbum;
                  }
                  return "Unknown Artist";
                }
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
              }
            }

            // Прогресс бар
            Item {
              id: progressWrapper
              visible: (MediaService.currentPlayer && MediaService.trackLength > 0)
              Layout.fillWidth: true
              Layout.preferredHeight: 32 * Style.uiScaleRatio

              property real localSeekRatio: -1
              property real lastSentSeekRatio: -1
              property real seekEpsilon: 0.01
              property real progressRatio: {
                if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
                  return 0;
                const r = MediaService.currentPosition / MediaService.trackLength;
                if (isNaN(r) || !isFinite(r))
                  return 0;
                return Math.max(0, Math.min(1, r));
              }

              Timer {
                id: seekDebounce
                interval: 75
                repeat: false
                onTriggered: {
                  if (MediaService.isSeeking && progressWrapper.localSeekRatio >= 0) {
                    const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio));
                    if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                      MediaService.seekByRatio(next);
                      progressWrapper.lastSentSeekRatio = next;
                    }
                  }
                }
              }

              NSlider {
                id: progressSlider
                anchors.fill: parent
                from: 0
                to: 1
                stepSize: 0
                snapAlways: false
                enabled: MediaService.trackLength > 0 && MediaService.canSeek
                heightRatio: 0.3

                value: (!MediaService.isSeeking) ? progressWrapper.progressRatio : (progressWrapper.localSeekRatio >= 0 ? progressWrapper.localSeekRatio : 0)

                onMoved: {
                  progressWrapper.localSeekRatio = value;
                  seekDebounce.restart();
                }
                onPressedChanged: {
                  if (pressed) {
                    MediaService.isSeeking = true;
                    progressWrapper.localSeekRatio = value;
                    MediaService.seekByRatio(value);
                    progressWrapper.lastSentSeekRatio = value;
                  } else {
                    seekDebounce.stop();
                    MediaService.seekByRatio(value);
                    MediaService.isSeeking = false;
                    progressWrapper.localSeekRatio = -1;
                    progressWrapper.lastSentSeekRatio = -1;
                  }
                }
              }

              RowLayout {
                anchors.top: parent.bottom
                anchors.topMargin: 2
                width: parent.width
                spacing: Style.marginXS

                NText {
                  text: MediaService.positionString || "0:00"
                  pointSize: Style.fontSizeXS
                  color: Color.mOnSurfaceVariant
                }

                Item { Layout.fillWidth: true }

                NText {
                  text: MediaService.lengthString || "0:00"
                  pointSize: Style.fontSizeXS
                  color: Color.mOnSurfaceVariant
                }
              }
            }

            // Кнопки управления
            RowLayout {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter
              spacing: Style.marginM

              NIconButton {
                icon: "media-prev"
                baseSize: Style.baseWidgetSize * 0.9
                tooltipText: "Previous"
                opacity: 0.8
                onClicked: MediaService.previous()
              }

              Rectangle {
                implicitWidth: Style.baseWidgetSize * 1.4
                implicitHeight: Style.baseWidgetSize * 1.4
                radius: Style.iRadiusCircle
                color: Color.mPrimary

                NIcon {
                  anchors.centerIn: parent
                  icon: MediaService.isPlaying ? "media-pause" : "media-play"
                  pointSize: Style.fontSizeL
                  color: Color.mOnPrimary
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  onEntered: parent.color = Qt.lighter(Color.mPrimary, 1.1)
                  onExited: parent.color = Color.mPrimary
                  onClicked: MediaService.playPause()
                }
              }

              NIconButton {
                icon: "media-next"
                baseSize: Style.baseWidgetSize * 0.9
                tooltipText: "Next"
                opacity: 0.8
                onClicked: MediaService.next()
              }
            }
          }
        }
      }

      // Lyrics section
      NBox {
        id: lyricsBox
        Layout.fillWidth: true
        Layout.preferredHeight: root.lyricsAreaHeight + root.typeHeight + Style.marginL * 2
        visible: root.showLyrics

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Индикатор загрузки
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            visible: MediaService.isFetchingLyrics
            spacing: Style.marginS

            Loader {
              id: loadingIcon
              Layout.preferredWidth: Style.fontSizeM
              Layout.preferredHeight: Style.fontSizeM
              
              sourceComponent: Item {
                anchors.fill: parent
                
                Rectangle {
                  anchors.centerIn: parent
                  width: Style.fontSizeM * 0.7
                  height: Style.fontSizeM * 0.7
                  radius: Style.fontSizeM * 0.35
                  color: Color.mPrimary
                  
                  Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: parent.height * 0.8
                    radius: parent.radius * 0.8
                    color: "transparent"
                    border.color: Color.mSurface
                    border.width: 2
                    
                    RotationAnimation on rotation {
                      from: 0
                      to: 360
                      duration: 1000
                      loops: Animation.Infinite
                    }
                  }
                }
              }
            }

            NText {
              text: "Загрузка текста..."
              pointSize: Style.fontSizeS
              color: Color.mPrimary
            }
          }

          // Текст песни или сообщение
          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: MediaService.isFetchingLyrics ? 0 : 
                                   (MediaService.hasLyrics ? root.lyricsAreaHeight - 25 : 40)
            visible: !MediaService.isFetchingLyrics
            clip: true

            // Сообщение когда нет текста
            NText {
              anchors.centerIn: parent
              visible: !MediaService.hasLyrics
              text: MediaService.lyricsText || "Текст не найден для этого трека"
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
              opacity: 0.7
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              width: parent.width - 20
            }


            Flickable {
              id: lyricsFlickable
              anchors.fill: parent
              contentWidth: parent.width
              contentHeight: lyricsColumn.height
              boundsBehavior: Flickable.StopAtBounds
              visible: MediaService.hasLyrics
              
              Behavior on contentY {
                SmoothedAnimation {
                  duration: 500
                  velocity: 200
                }
              }
              
              Column {
                id: lyricsColumn
                width: parent.width
                spacing: 4 
                topPadding: 15
                bottomPadding: 15
                
                Repeater {
                  model: MediaService.lyricsLines
                  
                  delegate: Item {
                    width: lyricsColumn.width
                    height: {
                      if (MediaService.useSyncedLyrics && index === MediaService.currentLineIndex) {
                        return textCurrentItem.height + 16;
                      } else {
                        return textNormalItem.height + 4;
                      }
                    }
                    
                    // Для предыдущих строк (2 строки до текущей)
                    NText {
                      id: textPreviousItem
                      anchors.centerIn: parent
                      visible: MediaService.useSyncedLyrics && (index === MediaService.currentLineIndex - 1 || index === MediaService.currentLineIndex - 2)
                      text: modelData
                      pointSize: {
                        if (index === MediaService.currentLineIndex - 1) return Style.fontSizeL;
                        if (index === MediaService.currentLineIndex - 2) return Style.fontSizeM;
                        return Style.fontSizeM;
                      }
                      opacity: {
                        if (index === MediaService.currentLineIndex - 1) return 0.9;
                        if (index === MediaService.currentLineIndex - 2) return 0.8;
                        return 0.4;
                      }
                      color: Color.mOnSurfaceVariant
                      horizontalAlignment: Text.AlignHCenter
                      wrapMode: Text.WordWrap
                      width: parent.width - 20
                      
                      Behavior on opacity {
                        NumberAnimation { duration: 200 }
                      }
                      
                      Behavior on pointSize {
                        NumberAnimation { duration: 200 }
                      }
                    }
                    
                    // Для последующих строк (2 строки после текущей)
                    NText {
                      id: textNextItem
                      anchors.centerIn: parent
                      visible: MediaService.useSyncedLyrics && (index === MediaService.currentLineIndex + 1 || index === MediaService.currentLineIndex + 2)
                      text: modelData
                      pointSize: {
                        if (index === MediaService.currentLineIndex + 1) return Style.fontSizeL;
                        if (index === MediaService.currentLineIndex + 2) return Style.fontSizeM;
                        return Style.fontSizeM;
                      }
                      opacity: {
                        if (index === MediaService.currentLineIndex + 1) return 0.9;
                        if (index === MediaService.currentLineIndex + 2) return 0.8;
                        return 0.4;
                      }
                      color: Color.mOnSurfaceVariant
                      horizontalAlignment: Text.AlignHCenter
                      wrapMode: Text.WordWrap
                      width: parent.width - 20
                      
                      Behavior on opacity {
                        NumberAnimation { duration: 200 }
                      }
                      
                      Behavior on pointSize {
                        NumberAnimation { duration: 200 }
                      }
                    }
                    
                    // Для обычных строк
                    NText {
                      id: textNormalItem
                      anchors.centerIn: parent
                      visible: !MediaService.useSyncedLyrics || 
                              (index !== MediaService.currentLineIndex && 
                                index !== MediaService.currentLineIndex - 1 && 
                                index !== MediaService.currentLineIndex - 2 &&
                                index !== MediaService.currentLineIndex + 1 &&
                                index !== MediaService.currentLineIndex + 2)
                      text: modelData
                      pointSize: Style.fontSizeS
                      color: {
                        if (!MediaService.useSyncedLyrics) return Color.mOnSurface;
                        return Color.mOnSurfaceVariant;
                      }
                      opacity: {
                        if (!MediaService.useSyncedLyrics) return 1.0;
                        return 0.3;
                      }
                      horizontalAlignment: Text.AlignHCenter
                      wrapMode: Text.WordWrap
                      width: parent.width - 20
                      
                      Behavior on opacity {
                        NumberAnimation { duration: 200 }
                      }
                    }
                    
                    // Текущая строка
                    NText {
                      id: textCurrentItem
                      anchors.centerIn: parent
                      visible: MediaService.useSyncedLyrics && index === MediaService.currentLineIndex
                      text: modelData
                      pointSize: Style.fontSizeXXL
                      font.weight: Style.fontWeightBold
                      color: Color.mPrimary
                      horizontalAlignment: Text.AlignHCenter
                      wrapMode: Text.WordWrap
                      width: parent.width - 20
                      
                      Behavior on pointSize {
                        NumberAnimation { duration: 200 }
                      }
                    }
                  }
                }
              }
            }

            // Обработчик изменения текущей строки для скролла к центру
            Connections {
              target: MediaService
              function onCurrentLineIndexChanged() {
                if (MediaService.useSyncedLyrics && MediaService.currentLineIndex >= 0) {
                  scrollTimer.restart();
                }
              }
            }

            // Таймер для отложенного скролла
            Timer {
              id: scrollTimer
              interval: 50
              repeat: false
              onTriggered: {
                if (MediaService.currentLineIndex < 0) return;
                
                var currentItem = lyricsColumn.children[MediaService.currentLineIndex];
                if (!currentItem) return;
                
                var itemCenterY = currentItem.y + currentItem.height / 2;
                var targetY = itemCenterY - root.lyricsAreaHeight / 2;
                targetY = Math.max(0, Math.min(targetY, lyricsFlickable.contentHeight - root.lyricsAreaHeight));
                
                lyricsFlickable.contentY = targetY;
              }
            }

            Connections {
              target: lyricsColumn
              function onHeightChanged() {
                if (MediaService.currentLineIndex >= 0) {
                  scrollTimer.restart();
                }
              }
            }
          }

          // Тип текста
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 15
            visible: MediaService.hasLyrics && !MediaService.isFetchingLyrics

            Item { Layout.fillWidth: true }

            NText {
              text: MediaService.useSyncedLyrics ? "🎤 синхронизировано" : "📝 текст"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }
        }
      }
    }
  }

  // Visualizer Components
  Component {
    id: linearComponent
    NLinearSpectrum {
      width: parent.width - Style.marginS
      height: 20
      values: CavaService.values
      fillColor: Color.mPrimary
      opacity: 0.4
      barPosition: Settings.getBarPositionForScreen(root.screen?.name)
    }
  }

  Component {
    id: mirroredComponent
    NMirroredSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: CavaService.values
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }

  Component {
    id: waveComponent
    NWaveSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: CavaService.values
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }
}