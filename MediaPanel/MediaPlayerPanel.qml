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

SmartPanel {
  id: root

  preferredWidth: Math.round((root.isSideBySide ? 480 : 400) * Style.uiScaleRatio)
  preferredHeight: Math.round(calculatePreferredHeight() * Style.uiScaleRatio)

  property var mediaMiniSettings: {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    return widget ? widget.widgetSettings : null;
  }
  readonly property bool showAlbumArt: !!(mediaMiniSettings && mediaMiniSettings.panelShowAlbumArt !== undefined ? mediaMiniSettings.panelShowAlbumArt : true)
  readonly property bool compactMode: !!(mediaMiniSettings && mediaMiniSettings.compactMode !== undefined ? mediaMiniSettings.compactMode : false)
  readonly property bool showLyrics: true
  readonly property bool isSideBySide: root.compactMode && root.showAlbumArt
  readonly property bool shouldShowLyricsSection: root.hasValidLyrics && !MediaService.isFetchingLyrics
  readonly property int loadingHeight: MediaService.isFetchingLyrics ? 25 : 0
  readonly property int typeHeight: (root.hasValidLyrics && !MediaService.isFetchingLyrics) ? 15 : 0
  readonly property bool hasValidLyrics: {
    if (!MediaService.hasLyrics) return false;
    if (MediaService.isFetchingLyrics) return false;
    
    var lyricsText = MediaService.lyricsText || "";
    if (lyricsText.trim() === "Текст не найден для этого трека") return false;
    if (MediaService.lyricsLines.length === 0) return false;
    
    return true;
  }
  readonly property int lyricsAreaHeight: {
    if (!root.hasValidLyrics) return 0;
    if (!MediaService.lyricsLines || MediaService.lyricsLines.length === 0) return 0;
    
    var displayLines = Math.min(MediaService.lyricsLines.length, 10);
    var height = 40 + (displayLines * 24);
    
    if (isNaN(height) || !isFinite(height)) return 100;
    return height;
  }

  function calculatePreferredHeight() {
    var baseHeight = 300;
      if (root.hasValidLyrics) {
        baseHeight += lyricsAreaHeight + 60;
      }
    return baseHeight;
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

  panelContent: Item {
    id: playerContent
    anchors.fill: parent

    readonly property real contentPreferredHeight: root.preferredHeight

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

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
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
                  radius: 8
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

          // Сообщение о загрузке/отсутствии текста 
          RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            visible: MediaService.isFetchingLyrics || (!root.hasValidLyrics && !MediaService.isFetchingLyrics)

            NText {
              text: {
                if (MediaService.isFetchingLyrics)
                  return "⏳ Загрузка текста..."
                else
                  return "📝 Текст не найден"
              }
              pointSize: Style.fontSizeS
              color: MediaService.isFetchingLyrics ? Color.mPrimary : Color.mOnSurfaceVariant
              opacity: MediaService.isFetchingLyrics ? 1.0 : 0.7
              font.italic: !MediaService.isFetchingLyrics
            }
          }
        }
      }

      // Lyrics section
      NBox {
        id: lyricsBox
        Layout.fillWidth: true
        Layout.preferredHeight: root.lyricsAreaHeight + root.typeHeight + Style.marginL * 2
        visible: root.shouldShowLyricsSection

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Текст песни
          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.lyricsAreaHeight - 25
            clip: true

            Flickable {
              id: lyricsFlickable
              anchors.fill: parent
              contentWidth: parent.width
              contentHeight: lyricsColumn.height
              boundsBehavior: Flickable.StopAtBounds
              
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
                    
                    // 2 строки до текущей
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
                    
                    // 2 строки после текущей
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

            Connections {
              target: MediaService
              function onCurrentLineIndexChanged() {
                if (MediaService.useSyncedLyrics && MediaService.currentLineIndex >= 0) {
                  scrollTimer.restart();
                }
              }
            }

            Timer {
              id: scrollTimer
              interval: 50
              repeat: false
              onTriggered: {
                if (MediaService.currentLineIndex < 0) return;
                
                var currentItem = lyricsColumn.children[MediaService.currentLineIndex];
                if (!currentItem) return;
                
                var itemCenterY = (currentItem.y || 0) + (currentItem.height || 0) / 2;
                var lyricsHeight = root.lyricsAreaHeight;
                
                if (isNaN(lyricsHeight) || lyricsHeight === undefined || lyricsHeight <= 0) {
                  lyricsHeight = 200;
                }
                
                var targetY = itemCenterY - lyricsHeight / 2;
                
                var contentHeight = lyricsFlickable.contentHeight || 0;
                var maxY = Math.max(0, contentHeight - lyricsHeight);
                
                if (isNaN(targetY) || !isFinite(targetY)) {
                  targetY = 0;
                }
                
                targetY = Math.max(0, Math.min(targetY, maxY));
                
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
            visible: root.hasValidLyrics

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
}