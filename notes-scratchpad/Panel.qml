import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: (pluginApi?.pluginSettings?.panelWidth ?? 600) * Style.uiScaleRatio
  property real contentPreferredHeight: (pluginApi?.pluginSettings?.panelHeight ?? 400) * Style.uiScaleRatio
  readonly property bool allowAttach: true
  anchors.fill: parent

  // File storage path (if configured)
  property string filePath: pluginApi?.pluginSettings?.filePath ?? ""
  property bool useFileStorage: filePath !== ""

  // Local state for the text content
  property string textContent: ""
  property int fontSize: pluginApi?.pluginSettings?.fontSize ?? 14
  property int savedCursorPosition: pluginApi?.pluginSettings?.cursorPosition ?? 0
  property real savedScrollX: pluginApi?.pluginSettings?.scrollPositionX ?? 0
  property real savedScrollY: pluginApi?.pluginSettings?.scrollPositionY ?? 0
  property bool restoringState: false

  // FileView for external file storage
  FileView {
    id: externalFile
    path: root.filePath
    watchChanges: false

    onLoaded: {
      if (root.useFileStorage) {
        root.textContent = text() || "";
      }
    }

    onLoadFailed: function(error) {
      if (error === 2) {
        // File doesn't exist yet, will be created on save
        Logger.d("NotesScratchpad", "File doesn't exist yet:", root.filePath);
      } else {
        Logger.w("NotesScratchpad", "Failed to load file:", root.filePath, "error:", error);
      }
    }
  }

  // Auto-save timer
  Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (pluginApi && !restoringState) {
        saveContent();
      }
    }
  }

  function saveContent() {
    if (!pluginApi) return;

    if (root.useFileStorage) {
      // Save to external file
      try {
        // Always ensure the content ends with a newline
        externalFile.setText(root.textContent.endsWith("\n") ? root.textContent : root.textContent + "\n");
      } catch (e) {
        Logger.e("NotesScratchpad", "Failed to save to file:", e);
      }
    } else {
      // Save to plugin settings
      pluginApi.pluginSettings.scratchpadContent = root.textContent;
    }

    // Always save cursor and scroll positions to settings
    pluginApi.pluginSettings.cursorPosition = textArea.cursorPosition;
    pluginApi.pluginSettings.scrollPositionX = scrollView.ScrollBar.horizontal.position;
    pluginApi.pluginSettings.scrollPositionY = scrollView.ScrollBar.vertical.position;
    pluginApi.saveSettings();
  }

  onTextContentChanged: {
    if (!restoringState) {
      saveTimer.restart();
    }
  }

  onFilePathChanged: {
    // Reload content when file path changes
    if (useFileStorage) {
      externalFile.reload();
    }
  }

  Component.onCompleted: {
    restoringState = true;
    
    if (pluginApi) {
      // Load content based on storage mode
      if (root.useFileStorage) {
        externalFile.reload();
      } else {
        textContent = pluginApi.pluginSettings.scratchpadContent || "";
      }
      
      savedCursorPosition = pluginApi.pluginSettings.cursorPosition ?? 0;
      savedScrollX = pluginApi.pluginSettings.scrollPositionX ?? 0;
      savedScrollY = pluginApi.pluginSettings.scrollPositionY ?? 0;
    }
    
    Qt.callLater(() => {
      textArea.forceActiveFocus();
      textArea.cursorPosition = savedCursorPosition;
      scrollView.ScrollBar.horizontal.position = savedScrollX;
      scrollView.ScrollBar.vertical.position = savedScrollY;
      restoringState = false;
    });
  }

  Component.onDestruction: {
    // Save everything when the panel is closed
    if (pluginApi) {
      saveContent();
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      textContent = pluginApi.pluginSettings.scratchpadContent || "";
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"
    radius: Style.radiusL

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "file-text"
          pointSize: Style.fontSizeL
        }

        NText {
          text: pluginApi?.tr("panel.header.title") || "Scratchpad"
          pointSize: Style.fontSizeL
          font.weight: Font.Bold
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "x"
          onClicked: {
            if (pluginApi) {
              pluginApi.closePanel(pluginApi.panelOpenScreen)
            }
          }
        }
      }

      // Main text area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: 1

        ScrollView {
          id: scrollView
          anchors.fill: parent
          anchors.margins: Style.marginM

          ScrollBar.horizontal.onPositionChanged: {
            if (!restoringState) saveTimer.restart();
          }
          ScrollBar.vertical.onPositionChanged: {
            if (!restoringState) saveTimer.restart();
          }

          TextArea {
            id: textArea
            text: root.textContent
            placeholderText: pluginApi?.tr("panel.placeholder") || "Start typing your notes here..."
            wrapMode: TextArea.Wrap
            selectByMouse: true
            color: Color.mOnSurface
            font.pixelSize: root.fontSize
            background: Item {}
            focus: true

            property int savedSelectionStart: 0
            property int savedSelectionEnd: 0
            property bool hasSavedSelection: false

            onTextChanged: {
              if (text !== root.textContent) {
                root.textContent = text;
              }
            }

            onCursorPositionChanged: {
              if (!restoringState) saveTimer.restart();
            }

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.RightButton
              cursorShape: Qt.IBeamCursor
              
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                  if (textArea.selectedText.length > 0) {
                    textArea.savedSelectionStart = textArea.selectionStart;
                    textArea.savedSelectionEnd = textArea.selectionEnd;
                    textArea.hasSavedSelection = true;
                  } else {
                    textArea.hasSavedSelection = false;
                  }
                  
                  var cursorPos = textArea.positionAt(mouse.x, mouse.y);
                  textArea.cursorPosition = cursorPos;
                  textArea.forceActiveFocus();
                  
                  var clickPos = mapToItem(panelContainer, mouse.x, mouse.y);
                  contextMenu.show(clickPos.x, clickPos.y);
                  mouse.accepted = true;
                }
              }
            }
          }
        }
      }

      // Character count
      NText {
        text: {
          var chars = textArea.text.length;
          var words = textArea.text.trim().split(/\s+/).filter(w => w.length > 0).length;
          var charText = pluginApi?.tr("panel.stats.characters") || "characters";
          var wordText = pluginApi?.tr("panel.stats.words") || "words";
          return chars + " " + charText + " · " + words + " " + wordText;
        }
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignRight
      }
    }

    Rectangle {
      id: contextMenu
      visible: false
      width: 150
      height: menuColumn.height + 10
      color: Color.mSurface
      radius: Style.radiusM
      border.width: 1
      border.color: Color.mOutline
      z: 1000
      
      Column {
          id: menuColumn
          anchors {
              top: parent.top
              left: parent.left
              right: parent.right
              margins: 5
          }
          spacing: 2
          
          Rectangle {
              id: copyButton
              width: parent.width
              height: 30
              color: copyMouseArea.containsMouse ? Color.mHover : "transparent"
              radius: Style.radiusS
              
              property bool enabled: textArea.hasSavedSelection || textArea.selectedText.length > 0
              
              MouseArea {
                  id: copyMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                  enabled: parent.enabled
                  
                  onClicked: {
                      if (textArea.hasSavedSelection) {
                          textArea.select(textArea.savedSelectionStart, textArea.savedSelectionEnd);
                      }
                      
                      if (textArea.selectedText.length > 0) {
                          textArea.copy();
                          contextMenu.hide();
                      }
                  }
              }
              
              Row {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 8
                  
                  NIcon {
                      icon: "copy"
                      color: copyButton.enabled ? Color.mOnSurface : Color.mOnSurfaceVariant
                      width: 16
                      height: 16
                      anchors.verticalCenter: parent.verticalCenter
                  }
                  
                  NText {
                      text: pluginApi?.tr("panel.popup.copy") || "copy"
                      color: copyButton.enabled ? Color.mOnSurface : Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeS
                      anchors.verticalCenter: parent.verticalCenter
                  }
              }
          }
          
          Rectangle {
              width: parent.width
              height: 1
              color: Color.mOutline
          }
          
          Rectangle {
              id: pasteButton
              width: parent.width
              height: 30
              color: pasteMouseArea.containsMouse ? Color.mHover : "transparent"
              radius: Style.radiusS
              
              MouseArea {
                  id: pasteMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  
                  onClicked: {
                      textArea.paste();
                      contextMenu.hide();
                  }
              }
              
              Row {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 8
                  
                  NIcon {
                      icon: "clipboard"
                      color: Color.mOnSurface
                      width: 16
                      height: 16
                      anchors.verticalCenter: parent.verticalCenter
                  }
                  
                  NText {
                      text: pluginApi?.tr("panel.popup.paste") || "paste"
                      color: Color.mOnSurface
                      font.pointSize: Style.fontSizeS
                      anchors.verticalCenter: parent.verticalCenter
                  }
              }
          }
          
          Rectangle {
              width: parent.width
              height: 1
              color: Color.mOutline
          }
          
          Rectangle {
              id: cancelButton
              width: parent.width
              height: 30
              color: cancelMouseArea.containsMouse ? Color.mHover : "transparent"
              radius: Style.radiusS
              
              MouseArea {
                  id: cancelMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  
                  onClicked: {
                      contextMenu.hide();
                  }
              }
              
              Row {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 8
                  
                  NIcon {
                      icon: "x"
                      color: Color.mOnSurface
                      width: 16
                      height: 16
                      anchors.verticalCenter: parent.verticalCenter
                  }
                  
                  NText {
                      text: pluginApi?.tr("panel.popup.cancel") || "cancel"
                      color: Color.mOnSurface
                      font.pointSize: Style.fontSizeS
                      anchors.verticalCenter: parent.verticalCenter
                  }
              }
          }
      }
      
      function show(x, y) {
          contextMenu.x = x;
          contextMenu.y = y;
          contextMenu.visible = true;
      }
      
      function hide() {
          contextMenu.visible = false;
          textArea.hasSavedSelection = false;
      }
    }
  }
}
