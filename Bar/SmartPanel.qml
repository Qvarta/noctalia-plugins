import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

/**
* SmartPanel for use within MainScreen
*/
Item {
  id: root

  // Screen property provided by MainScreen
  property ShellScreen screen: null

  // Panel content: Text, icons, etc...
  property Component panelContent: null

  // PanelID for binding panels to widgets of the same type
  property var panelID: null

  // Panel size properties
  property real preferredWidth: 700
  property real preferredHeight: 900
  property real preferredWidthRatio
  property real preferredHeightRatio
  property color panelBackgroundColor: Color.mSurface
  property color panelBorderColor: Color.mOutline
  property var buttonItem: null
  property bool forceAttachToBar: false

  // Anchoring properties
  property bool panelAnchorHorizontalCenter: false
  property bool panelAnchorVerticalCenter: false
  property bool panelAnchorTop: false
  property bool panelAnchorBottom: false
  property bool panelAnchorLeft: false
  property bool panelAnchorRight: false

  // Button position properties
  property bool useButtonPosition: false
  property point buttonPosition: Qt.point(0, 0)
  property int buttonWidth: 0
  property int buttonHeight: 0

  // Edge snapping: if panel is within this distance (in pixels) from a screen edge, snap
  property real edgeSnapDistance: 50

  // Track whether panel is open
  property bool isPanelOpen: false

  // Track actual visibility (delayed until content is loaded and sized)
  property bool isPanelVisible: false

  // Track size animation completion for sequential opacity animation
  property bool sizeAnimationComplete: false

  // Derived state: track opening transition
  readonly property bool isOpening: isPanelVisible && !isClosing && !sizeAnimationComplete

  // Track close animation state: fade opacity first, then shrink size
  property bool isClosing: false
  property bool opacityFadeComplete: false
  property bool closeFinalized: false // Prevent double-finalization

  // Safety: Watchdog timers to prevent stuck states
  property bool closeWatchdogActive: false
  property bool openWatchdogActive: false

  // Cached animation direction - set when panel opens, doesn't change during animation
  // These are computed once when opening and used for the entire open/close cycle
  property bool cachedAnimateFromTop: false
  property bool cachedAnimateFromBottom: false
  property bool cachedAnimateFromLeft: false
  property bool cachedAnimateFromRight: false
  property bool cachedShouldAnimateWidth: false
  property bool cachedShouldAnimateHeight: false

  // Close with escape key
  property bool closeWithEscape: true

  property bool exclusiveKeyboard: true

  // ========== НАСТРОЙКИ ШИРИНЫ БАРА (ДОЛЖНЫ СОВПАДАТЬ С BarContentWindow) ==========
  readonly property string barWidthMode: "percent"  // "full", "fixed", "percent"
  readonly property real barFixedWidth: 1200
  readonly property real barPercentWidth: 70
  readonly property bool centerBarHorizontally: true

  // Keyboard event handler
  // These are called from MainScreen's centralized shortcuts
  // override these in specific panels to handle shortcuts
  function onEscapePressed() {
    if (closeWithEscape)
      close();
  }

  // Expose panel region for background rendering
  readonly property var panelRegion: panelContent.geometryPlaceholder

  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: barShouldShow ? Style.getBarHeightForScreen(screen?.name) : 0
  readonly property bool hasBar: modelData && modelData.name ? (Settings.data.bar.monitors.includes(modelData.name) || (Settings.data.bar.monitors.length === 0)) : false
  readonly property bool isFramed: Settings.data.bar.barType === "framed" && hasBar
  readonly property real frameThickness: Settings.data.bar.frameThickness ?? 12
  readonly property bool barFloating: Settings.data.bar.floating
  readonly property real barMarginH: (barFloating && barShouldShow) ? Math.ceil(Settings.data.bar.marginHorizontal) : 0
  readonly property real barMarginV: (barFloating && barShouldShow) ? Math.ceil(Settings.data.bar.marginVertical) : 0
  readonly property real attachmentOverlap: 1 // Panel extends into bar area to fix hairline gap with fractional scaling

  // Функция для вычисления фактической ширины бара (должна совпадать с BarContentWindow)
  function getActualBarWidth() {
    if (barIsVertical) return barHeight
    
    var availableWidth = screen?.width || 0
    if (isFramed) {
      availableWidth = screen.width - frameThickness * 2
    } else if (barFloating) {
      availableWidth = screen.width - barMarginH * 2
    }
    
    if (barWidthMode === "fixed") {
      return Math.min(barFixedWidth, availableWidth)
    } else if (barWidthMode === "percent") {
      return Math.min(screen.width * (barPercentWidth / 100), availableWidth)
    }
    return availableWidth
  }

  // Функция для вычисления левого отступа бара (центрирование)
  function getBarLeftMargin() {
    if (barPosition === "left") return barMarginH
    if (barPosition === "right") return 0
    if (!centerBarHorizontally) return isFramed ? frameThickness : barMarginH
    
    var barWidth = getActualBarWidth()
    var availableWidth = screen?.width || 0
    
    if (isFramed) {
      var framedWidth = availableWidth - frameThickness * 2
      if (barWidth < framedWidth) {
        return frameThickness + (framedWidth - barWidth) / 2
      }
      return frameThickness
    }
    
    if (barWidth < availableWidth - barMarginH * 2) {
      return barMarginH + (availableWidth - barMarginH * 2 - barWidth) / 2
    }
    return barMarginH
  }

  // Функция для вычисления X позиции бара (левый край)
  function getBarX() {
    if (barPosition === "right") {
      return (screen?.width || 0) - getActualBarWidth() - getBarRightMargin()
    }
    if (barPosition === "left") {
      return getBarLeftMargin()
    }
    // Для верхнего/нижнего бара - возвращаем левый отступ
    return getBarLeftMargin()
  }

  // Функция для вычисления правого отступа бара
  function getBarRightMargin() {
    if (barPosition === "right") return barMarginH
    if (barPosition === "left") return 0
    if (!centerBarHorizontally) return isFramed ? frameThickness : barMarginH
    
    var barWidth = getActualBarWidth()
    var availableWidth = screen?.width || 0
    var leftMargin = getBarLeftMargin()
    
    return availableWidth - (leftMargin + barWidth)
  }

  // Check if bar should be visible on this screen
  readonly property bool barShouldShow: {
    if (!BarService.effectivelyVisible)
      return false;
    var monitors = Settings.data.bar.monitors || [];
    var screenName = screen?.name || "";
    return monitors.length === 0 || monitors.includes(screenName);
  }

  // Helper to detect if any anchor is explicitly set
  readonly property bool hasExplicitHorizontalAnchor: panelAnchorHorizontalCenter || panelAnchorLeft || panelAnchorRight
  readonly property bool hasExplicitVerticalAnchor: panelAnchorVerticalCenter || panelAnchorTop || panelAnchorBottom

  // Effective anchor properties (depend on allowAttach)
  readonly property bool effectivePanelAnchorTop: panelContent.allowAttach && (panelAnchorTop || (useButtonPosition && barPosition === "top") || (!hasExplicitVerticalAnchor && barPosition === "top" && !barIsVertical))
  readonly property bool effectivePanelAnchorBottom: panelContent.allowAttach && (panelAnchorBottom || (useButtonPosition && barPosition === "bottom") || (!hasExplicitVerticalAnchor && barPosition === "bottom" && !barIsVertical))
  readonly property bool effectivePanelAnchorLeft: panelContent.allowAttach && (panelAnchorLeft || (useButtonPosition && barPosition === "left") || (!hasExplicitHorizontalAnchor && barPosition === "left" && barIsVertical))
  readonly property bool effectivePanelAnchorRight: panelContent.allowAttach && (panelAnchorRight || (useButtonPosition && barPosition === "right") || (!hasExplicitHorizontalAnchor && barPosition === "right" && barIsVertical))

  signal opened
  signal closed

  Connections {
    target: Style

    function onUiScaleRatioChanged() {
      if (root.isPanelOpen && root.isPanelVisible) {
        root.setPosition();
      }
    }
  }

  // Panel visibility and sizing
  visible: isPanelVisible
  width: parent ? parent.width : 0
  height: parent ? parent.height : 0

  // Panel control functions
  function toggle(buttonItem, buttonName) {
    if (!isPanelOpen) {
      open(buttonItem, buttonName);
    } else {
      close();
    }
  }

  function open(buttonItem, buttonName) {
    // Reset immediate close flag to ensure animations work properly
    PanelService.closedImmediately = false;

    if (!buttonItem && buttonName) {
      buttonItem = BarService.lookupWidget(buttonName, screen.name);
    }

    // Validate buttonItem is a valid QML Item with mapToItem function
    if (buttonItem && typeof buttonItem.mapToItem === "function") {
      try {
        root.buttonItem = buttonItem;
        // Map button position within its window
        var buttonLocal = buttonItem.mapToItem(null, 0, 0);

        // Calculate the bar window's position on screen based on bar settings
        // Используем обновленную логику с учетом центрирования бара
        var barWindowX = getBarX();
        var barWindowY = 0;
        var screenWidth = root.screen?.width || 0;
        var screenHeight = root.screen?.height || 0;

        if (root.barPosition === "bottom") {
          barWindowY = screenHeight - root.barMarginV - root.barHeight;
        } else if (root.barPosition === "top") {
          barWindowY = root.barMarginV;
        } else if (root.isFramed) {
          barWindowY = root.frameThickness;
        }
        // For left/right bars, barWindowY stays 0 (full height window) unless framed

        root.buttonPosition = Qt.point(barWindowX + buttonLocal.x, barWindowY + buttonLocal.y);
        root.buttonWidth = buttonItem.width;
        root.buttonHeight = buttonItem.height;
        root.useButtonPosition = true;
      } catch (e) {
        Logger.w("SmartPanel", "Failed to get button position, using default positioning:", e);
        root.buttonItem = null;
        root.useButtonPosition = false;
      }
    } else {
      // No valid button provided: reset button position mode
      root.buttonItem = null;
      root.useButtonPosition = false;
    }

    // Set isPanelOpen to trigger content loading, but don't show yet
    isPanelOpen = true;

    // Notify PanelService
    PanelService.willOpenPanel(root);

    // Position and visibility will be set by Loader.onLoaded
    // This ensures no flicker from default size to content size
  }

  function close() {
    // Reset immediate close flag to ensure animations work properly
    PanelService.closedImmediately = false;

    // Start close sequence: fade opacity first
    isClosing = true;
    sizeAnimationComplete = false;
    closeFinalized = false;

    // Stop the open animation timer if it's still running
    opacityTrigger.stop();
    openWatchdogActive = false;
    openWatchdogTimer.stop();

    // Start close watchdog timer
    closeWatchdogActive = true;
    closeWatchdogTimer.restart();

    // If opacity is already 0 (closed during open animation before fade-in),
    // skip directly to size animation
    if (root.opacity === 0.0) {
      opacityFadeComplete = true;
    } else {
      opacityFadeComplete = false;
    }

    // Opacity will fade out, then size will shrink, then finalizeClose() will complete
    Logger.d("SmartPanel", "Closing panel", objectName);
  }

  function closeImmediately() {
    // Close without any animation, useful for app launches to avoid focus issues
    opacityTrigger.stop();
    openWatchdogActive = false;
    openWatchdogTimer.stop();
    closeWatchdogActive = false;
    closeWatchdogTimer.stop();

    // Don't set opacity directly as it breaks the binding
    root.isPanelVisible = false;
    root.sizeAnimationComplete = false;
    root.isClosing = false;
    root.opacityFadeComplete = false;
    root.closeFinalized = true;
    root.isPanelOpen = false;
    panelBackground.dimensionsInitialized = false;

    // Signal immediate close so MainScreen can skip dimmer animation
    PanelService.closedImmediately = true;
    PanelService.closedPanel(root);
    closed();

    Logger.d("SmartPanel", "Panel closed immediately", objectName);
  }

  function finalizeClose() {
    // Prevent double-finalization
    if (root.closeFinalized) {
      Logger.w("SmartPanel", "finalizeClose called but already finalized - ignoring", objectName);
      return;
    }

    // Complete the close sequence after animations finish
    root.closeFinalized = true;
    root.closeWatchdogActive = false;
    closeWatchdogTimer.stop();

    root.isPanelVisible = false;
    root.isPanelOpen = false;
    root.isClosing = false;
    root.opacityFadeComplete = false;

    // Reset dimensionsInitialized for next opening
    panelBackground.dimensionsInitialized = false;

    PanelService.closedPanel(root);
    closed();

    Logger.d("SmartPanel", "Panel close finalized", objectName);
  }

  function setPosition() {
    // Don't calculate position if parent dimensions aren't available yet
    // This prevents centering around (0,0) when width/height are still 0
    if (!root.width || !root.height) {
      Logger.d("SmartPanel", "Skipping setPosition - dimensions not ready:", root.width, "x", root.height);
      // Retry on next frame when dimensions should be available
      Qt.callLater(setPosition);
      return;
    }

    // Effective screen margins (account for frame thickness)
    var effMarginL = Style.marginL + (root.isFramed ? root.frameThickness : 0);
    var effMarginR = Style.marginL + (root.isFramed ? root.frameThickness : 0);
    var effMarginT = Style.marginL + (root.isFramed ? root.frameThickness : 0);
    var effMarginB = Style.marginL + (root.isFramed ? root.frameThickness : 0);

    // Calculate panel dimensions first (needed for positioning)
    var w;
    // Priority 1: Content-driven size (dynamic)
    if (contentLoader.item && contentLoader.item.contentPreferredWidth !== undefined) {
      w = contentLoader.item.contentPreferredWidth;
    } // Priority 2: Ratio-based size
    else if (root.preferredWidthRatio !== undefined) {
      w = Math.round(Math.max(root.width * root.preferredWidthRatio, root.preferredWidth));
    } // Priority 3: Static preferred width
    else {
      w = root.preferredWidth;
    }
    var panelWidth = Math.min(w, root.width - effMarginL - effMarginR);

    var h;
    // Priority 1: Content-driven size (dynamic)
    if (contentLoader.item && contentLoader.item.contentPreferredHeight !== undefined) {
      h = contentLoader.item.contentPreferredHeight;
    } // Priority 2: Ratio-based size
    else if (root.preferredHeightRatio !== undefined) {
      h = Math.round(Math.max(root.height * root.preferredHeightRatio, root.preferredHeight));
    } // Priority 3: Static preferred height
    else {
      h = root.preferredHeight;
    }
    var panelHeight = Math.min(h, root.height - root.barHeight - effMarginT - effMarginB);

    // Update panelBackground target size (will be animated)
    panelBackground.targetWidth = panelWidth;
    panelBackground.targetHeight = panelHeight;

    // Получаем реальную позицию бара с учетом центрирования
    var actualBarX = getBarX();
    var actualBarWidth = getActualBarWidth();
    var barLeftEdge = actualBarX;
    var barRightEdge = actualBarX + actualBarWidth;

    // Pre-compute bar edge positions with overlap (used multiple times below)
    // For attached panels, we extend slightly into the bar area to prevent hairline gaps
    var leftBarEdgeWithOverlap = barLeftEdge + root.barHeight - root.attachmentOverlap;
    var rightBarEdgeWithOverlap = barRightEdge - root.barHeight + root.attachmentOverlap;
    var topBarEdgeWithOverlap = root.barMarginV + root.barHeight - root.attachmentOverlap;
    var bottomBarEdgeWithOverlap = root.height - root.barMarginV - root.barHeight + root.attachmentOverlap;

    if (root.isFramed) {
      if (root.barPosition === "left")
        leftBarEdgeWithOverlap = root.barHeight - root.attachmentOverlap;
      if (root.barPosition === "right")
        rightBarEdgeWithOverlap = root.width - root.barHeight + root.attachmentOverlap;
      if (root.barPosition === "top")
        topBarEdgeWithOverlap = root.barHeight - root.attachmentOverlap;
      if (root.barPosition === "bottom")
        bottomBarEdgeWithOverlap = root.height - root.barHeight + root.attachmentOverlap;
    }

    // Calculate position
    var calculatedX;
    var calculatedY;

    // ===== X POSITIONING =====
    if (root.useButtonPosition && root.width > 0 && panelWidth > 0) {
      if (root.barIsVertical) {
        // For vertical bars
        if (panelContent.allowAttach) {
          // Attached panels: align with bar edge (left or right side)
          if (root.barPosition === "left") {
            calculatedX = leftBarEdgeWithOverlap;
          } else {
            calculatedX = rightBarEdgeWithOverlap - panelWidth;
          }
        } else {
          // Detached panels: center on button X position
          var panelX = root.buttonPosition.x + root.buttonWidth / 2 - panelWidth / 2;
          var minX = effMarginL;
          var maxX = root.width - panelWidth - effMarginR;

          // Account for vertical bar taking up space
          if (root.barPosition === "left") {
            minX = (root.isFramed ? 0 : root.barMarginH) + root.barHeight + Style.marginL;
          } else if (root.barPosition === "right") {
            maxX = root.width - (root.isFramed ? 0 : root.barMarginH) - root.barHeight - panelWidth - Style.marginL;
          }

          panelX = Math.max(minX, Math.min(panelX, maxX));
          calculatedX = panelX;
        }
      } else {
        // For horizontal bars, center panel on button X position
        // Используем реальную позицию бара для вычислений
        var panelX = root.buttonPosition.x + root.buttonWidth / 2 - panelWidth / 2;
        if (panelContent.allowAttach) {
          var cornerInset = root.barFloating ? Style.radiusL * 2 : 0;
          var barLeftEdgeWithCorner = barLeftEdge + cornerInset;
          var barRightEdgeWithCorner = barRightEdge - cornerInset;
          panelX = Math.max(barLeftEdgeWithCorner, Math.min(panelX, barRightEdgeWithCorner - panelWidth));
        } else {
          panelX = Math.max(effMarginL, Math.min(panelX, root.width - panelWidth - effMarginR));
        }
        calculatedX = panelX;
      }
    } else {
      // Standard anchor positioning
      if (root.panelAnchorHorizontalCenter) {
        if (root.barIsVertical) {
          if (root.barPosition === "left") {
            var availableStart = (root.isFramed ? 0 : root.barMarginH) + root.barHeight;
            var availableWidth = root.width - availableStart - (root.isFramed ? root.frameThickness : 0);
            calculatedX = availableStart + (availableWidth - panelWidth) / 2;
          } else if (root.barPosition === "right") {
            var availableWidth = root.width - (root.isFramed ? 0 : root.barMarginH) - root.barHeight - (root.isFramed ? root.frameThickness : 0);
            calculatedX = (root.isFramed ? root.frameThickness : 0) + (availableWidth - panelWidth) / 2;
          } else {
            calculatedX = (root.width - panelWidth) / 2;
          }
        } else {
          calculatedX = (root.width - panelWidth) / 2;
        }
      } else if (root.panelAnchorRight) {
        if (root.effectivePanelAnchorRight) {
          // Attached: snap to edge/bar
          if (root.barIsVertical && root.barPosition === "right") {
            calculatedX = rightBarEdgeWithOverlap - panelWidth;
          } else {
            var panelOnSameEdgeAsBar = (root.barPosition === "top" && root.effectivePanelAnchorTop) || (root.barPosition === "bottom" && root.effectivePanelAnchorBottom);
            if (!root.barIsVertical && root.barFloating && panelOnSameEdgeAsBar) {
              var rightCornerInset = Style.radiusL * 2;
              calculatedX = barRightEdge - rightCornerInset - panelWidth;
            } else {
              calculatedX = root.width - panelWidth - (root.isFramed ? root.frameThickness - root.attachmentOverlap : 0);
            }
          }
        } else {
          // Not attached: position at right with margin
          calculatedX = root.width - panelWidth - effMarginR;
        }
      } else if (root.panelAnchorLeft) {
        if (root.effectivePanelAnchorLeft) {
          // Attached: snap to edge/bar
          if (root.barIsVertical && root.barPosition === "left") {
            calculatedX = leftBarEdgeWithOverlap;
          } else {
            var panelOnSameEdgeAsBar = (root.barPosition === "top" && root.effectivePanelAnchorTop) || (root.barPosition === "bottom" && root.effectivePanelAnchorBottom);
            if (!root.barIsVertical && root.barFloating && panelOnSameEdgeAsBar) {
              var leftCornerInset = Style.radiusL * 2;
              calculatedX = barLeftEdge + leftCornerInset;
            } else {
              calculatedX = (root.isFramed ? root.frameThickness - root.attachmentOverlap : 0);
            }
          }
        } else {
          // Not attached: position at left with margin
          calculatedX = effMarginL;
        }
      } else {
        // No explicit anchor: attach to bar if allowAttach, otherwise center
        if (root.barIsVertical) {
          if (panelContent.allowAttach) {
            // Attach to the bar edge (with overlap into bar area)
            if (root.barPosition === "left") {
              calculatedX = leftBarEdgeWithOverlap;
            } else {
              calculatedX = rightBarEdgeWithOverlap - panelWidth;
            }
          } else {
            // Not attached: center in available space
            if (root.barPosition === "left") {
              var availableStart = (root.isFramed ? 0 : root.barMarginH) + root.barHeight;
              var availableWidth = root.width - availableStart - effMarginR;
              calculatedX = availableStart + (availableWidth - panelWidth) / 2;
            } else {
              var availableWidth = root.width - (root.isFramed ? 0 : root.barMarginH) - root.barHeight - effMarginL;
              calculatedX = effMarginL + (availableWidth - panelWidth) / 2;
            }
          }
        } else {
          if (panelContent.allowAttach) {
            var cornerInset = Style.radiusL + (root.barFloating ? Style.radiusL : 0);
            var barLeftEdgeWithCorner = barLeftEdge + cornerInset;
            var barRightEdgeWithCorner = barRightEdge - cornerInset;
            var centeredX = (root.width - panelWidth) / 2;
            calculatedX = Math.max(barLeftEdgeWithCorner, Math.min(centeredX, barRightEdgeWithCorner - panelWidth));
          } else {
            calculatedX = (root.width - panelWidth) / 2;
          }
        }
      }
    }

    // Edge snapping for X
    if (panelContent.allowAttach && !root.barFloating && root.width > 0 && panelWidth > 0) {
      var leftEdgePos = root.barPosition === "left" ? leftBarEdgeWithOverlap : (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginH);
      var rightEdgePos = root.barPosition === "right" ? rightBarEdgeWithOverlap - panelWidth : root.width - (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginH) - panelWidth;

      var shouldSnapToLeft = root.effectivePanelAnchorLeft || (!root.hasExplicitHorizontalAnchor && root.barPosition === "left");
      var shouldSnapToRight = root.effectivePanelAnchorRight || (!root.hasExplicitHorizontalAnchor && root.barPosition === "right");

      if (shouldSnapToLeft && Math.abs(calculatedX - leftEdgePos) <= root.edgeSnapDistance) {
        calculatedX = leftEdgePos;
      } else if (shouldSnapToRight && Math.abs(calculatedX - rightEdgePos) <= root.edgeSnapDistance) {
        calculatedX = rightEdgePos;
      }
    }

    // ===== Y POSITIONING =====
    if (root.useButtonPosition && root.height > 0 && panelHeight > 0) {
      if (root.barPosition === "top") {
        if (panelContent.allowAttach) {
          calculatedY = topBarEdgeWithOverlap;
        } else {
          calculatedY = (root.isFramed ? 0 : root.barMarginV) + root.barHeight + Style.marginM;
        }
      } else if (root.barPosition === "bottom") {
        if (panelContent.allowAttach) {
          calculatedY = bottomBarEdgeWithOverlap - panelHeight;
        } else {
          calculatedY = root.height - (root.isFramed ? 0 : root.barMarginV) - root.barHeight - panelHeight - Style.marginM;
        }
      } else if (root.barIsVertical) {
        var panelY = root.buttonPosition.y + root.buttonHeight / 2 - panelHeight / 2;
        var extraPadding = (panelContent.allowAttach && root.barFloating) ? Style.radiusL : 0;
        if (panelContent.allowAttach) {
          var cornerInset = extraPadding + (root.barFloating ? Style.radiusL : 0);
          var barTopEdge = (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginV) + cornerInset;
          var barBottomEdge = root.height - (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginV) - cornerInset;
          panelY = Math.max(barTopEdge, Math.min(panelY, barBottomEdge - panelHeight));
        } else {
          panelY = Math.max(effMarginT + extraPadding, Math.min(panelY, root.height - panelHeight - effMarginB - extraPadding));
        }
        calculatedY = panelY;
      }
    } else {
      // Standard anchor positioning
      var barOffset = !panelContent.allowAttach && (root.barPosition === "top" || root.barPosition === "bottom") ? (root.isFramed ? 0 : root.barMarginV) + root.barHeight + Style.marginM : 0;

      if (panelContent.allowAttach && !root.barIsVertical) {
        // Attached to horizontal bar: position with overlap
        if ((root.effectivePanelAnchorTop && root.barPosition === "top") || (!root.hasExplicitVerticalAnchor && root.barPosition === "top")) {
          calculatedY = topBarEdgeWithOverlap;
        } else if ((root.effectivePanelAnchorBottom && root.barPosition === "bottom") || (!root.hasExplicitVerticalAnchor && root.barPosition === "bottom")) {
          calculatedY = bottomBarEdgeWithOverlap - panelHeight;
        }
      }

      if (calculatedY === undefined) {
        if (root.panelAnchorVerticalCenter) {
          if (!root.barIsVertical) {
            if (root.barPosition === "top") {
              var availableStart = (root.isFramed ? 0 : root.barMarginV) + root.barHeight;
              var availableHeight = root.height - availableStart - (root.isFramed ? root.frameThickness : 0);
              calculatedY = availableStart + (availableHeight - panelHeight) / 2;
            } else if (root.barPosition === "bottom") {
              var availableHeight = root.height - (root.isFramed ? 0 : root.barMarginV) - root.barHeight - (root.isFramed ? root.frameThickness : 0);
              calculatedY = (root.isFramed ? root.frameThickness : 0) + (availableHeight - panelHeight) / 2;
            } else {
              calculatedY = (root.height - panelHeight) / 2;
            }
          } else {
            calculatedY = (root.height - panelHeight) / 2;
          }
        } else if (root.panelAnchorTop) {
          if (root.effectivePanelAnchorTop) {
            calculatedY = root.barPosition === "top" ? topBarEdgeWithOverlap : (root.isFramed ? root.frameThickness - root.attachmentOverlap : 0);
          } else {
            var topBarOffset = (root.barPosition === "top") ? barOffset : 0;
            calculatedY = topBarOffset + effMarginT;
          }
        } else if (root.panelAnchorBottom) {
          if (root.effectivePanelAnchorBottom) {
            calculatedY = root.barPosition === "bottom" ? bottomBarEdgeWithOverlap - panelHeight : root.height - panelHeight - (root.isFramed ? root.frameThickness - root.attachmentOverlap : 0);
          } else {
            var bottomBarOffset = (root.barPosition === "bottom") ? barOffset : 0;
            calculatedY = root.height - panelHeight - bottomBarOffset - effMarginB;
          }
        } else {
          // No explicit vertical anchor
          if (root.barIsVertical) {
            if (panelContent.allowAttach) {
              var cornerInset = root.barFloating ? Style.radiusL * 2 : 0;
              var barTopEdge = (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginV) + cornerInset;
              var barBottomEdge = root.height - (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginV) - cornerInset;
              var centeredY = (root.height - panelHeight) / 2;
              calculatedY = Math.max(barTopEdge, Math.min(centeredY, barBottomEdge - panelHeight));
            } else {
              calculatedY = (root.height - panelHeight) / 2;
            }
          } else {
            // Horizontal bar, not attached
            if (root.barPosition === "top") {
              calculatedY = barOffset + effMarginT;
            } else if (root.barPosition === "bottom") {
              calculatedY = effMarginT;
            } else {
              calculatedY = effMarginT;
            }
          }
        }
      }
    }

    // Edge snapping for Y
    if (panelContent.allowAttach && !root.barFloating && root.height > 0 && panelHeight > 0) {
      var topEdgePos = root.barPosition === "top" ? topBarEdgeWithOverlap : (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginV);
      var bottomEdgePos = root.barPosition === "bottom" ? bottomBarEdgeWithOverlap - panelHeight : root.height - (root.isFramed ? root.frameThickness - root.attachmentOverlap : root.barMarginV) - panelHeight;

      var shouldSnapToTop = root.effectivePanelAnchorTop || (!root.hasExplicitVerticalAnchor && root.barPosition === "top");
      var shouldSnapToBottom = root.effectivePanelAnchorBottom || (!root.hasExplicitVerticalAnchor && root.barPosition === "bottom");

      if (shouldSnapToTop && Math.abs(calculatedY - topEdgePos) <= root.edgeSnapDistance) {
        calculatedY = topEdgePos;
      } else if (shouldSnapToBottom && Math.abs(calculatedY - bottomEdgePos) <= root.edgeSnapDistance) {
        calculatedY = bottomEdgePos;
      }
    }

    // Apply calculated positions (set targets for animation)
    panelBackground.targetX = calculatedX;
    panelBackground.targetY = calculatedY;
  }

  // Watch for changes in content-driven sizes and update position
  Connections {
    target: contentLoader.item
    ignoreUnknownSignals: true

    function onContentPreferredWidthChanged() {
      if (root.isPanelOpen && root.isPanelVisible) {
        root.setPosition();
      }
    }

    function onContentPreferredHeightChanged() {
      if (root.isPanelOpen && root.isPanelVisible) {
        root.setPosition();
      }
    }
  }

  // Opacity animation
  opacity: {
    if (isClosing)
      return 0.0;
    if (isPanelVisible && sizeAnimationComplete)
      return 1.0;
    return 0.0;
  }

  Behavior on opacity {
    enabled: !PanelService.closedImmediately
    NumberAnimation {
      id: opacityAnimation
      duration: root.isClosing ? Style.animationFaster : Style.animationFast
      easing.type: Easing.OutQuad

      onRunningChanged: {
        if (!running && duration === 0) {
          if (root.isClosing && root.opacity === 0.0) {
            root.opacityFadeComplete = true;
            var shouldFinalizeNow = panelContent.geometryPlaceholder && !panelContent.geometryPlaceholder.shouldAnimateWidth && !panelContent.geometryPlaceholder.shouldAnimateHeight;
            if (shouldFinalizeNow) {
              Qt.callLater(root.finalizeClose);
            }
          } else if (root.isPanelVisible && root.opacity === 1.0) {
            root.openWatchdogActive = false;
            openWatchdogTimer.stop();
          }
          return;
        }

        if (!running && root.isClosing && root.opacity === 0.0) {
          root.opacityFadeComplete = true;
          var shouldFinalizeNow = panelContent.geometryPlaceholder && !panelContent.geometryPlaceholder.shouldAnimateWidth && !panelContent.geometryPlaceholder.shouldAnimateHeight;
          if (shouldFinalizeNow) {
            Qt.callLater(root.finalizeClose);
          }
        } else if (!running && root.isPanelVisible && root.opacity === 1.0) {
          root.openWatchdogActive = false;
          openWatchdogTimer.stop();
        }
      }
    }
  }

  Timer {
    id: opacityTrigger
    interval: Style.animationNormal * 0.5
    repeat: false
    onTriggered: {
      if (root.isPanelVisible) {
        root.sizeAnimationComplete = true;
      }
    }
  }

  Timer {
    id: openWatchdogTimer
    interval: Style.animationNormal * 3
    repeat: false
    onTriggered: {
      if (root.openWatchdogActive) {
        Logger.w("SmartPanel", "Open watchdog timeout - forcing panel visible state", root.objectName);
        root.openWatchdogActive = false;
        if (root.isPanelOpen && !root.isPanelVisible) {
          root.isPanelVisible = true;
          root.sizeAnimationComplete = true;
        }
      }
    }
  }

  Timer {
    id: closeWatchdogTimer
    interval: Style.animationFast * 3
    repeat: false
    onTriggered: {
      if (root.closeWatchdogActive && !root.closeFinalized) {
        Logger.w("SmartPanel", "Close watchdog timeout - forcing panel close", root.objectName);
        Qt.callLater(root.finalizeClose);
      }
    }
  }

  // ------------------------------------------------
  // Panel Content
  Item {
    id: panelContent
    anchors.fill: parent

    readonly property bool allowAttach: {
      if (contentLoader.item && contentLoader.item.allowAttach !== undefined) {
        return contentLoader.item.allowAttach;
      }
      return Settings.data.ui.panelsAttachedToBar || root.forceAttachToBar;
    }
    readonly property bool allowAttachToBar: {
      if (!(Settings.data.ui.panelsAttachedToBar || root.forceAttachToBar)) {
        return false;
      }
      var monitors = Settings.data.bar.monitors || [];
      var result = monitors.length === 0 || monitors.includes(root.screen?.name || "");
      return result;
    }

    readonly property bool touchingLeftEdge: allowAttach && panelBackground.x <= (isFramed ? frameThickness + 1 : 1)
    readonly property bool touchingRightEdge: allowAttach && (panelBackground.x + panelBackground.width) >= (root.width - (isFramed ? frameThickness + 1 : 1))
    readonly property bool touchingTopEdge: allowAttach && panelBackground.y <= (isFramed ? frameThickness + 1 : 1)
    readonly property bool touchingBottomEdge: allowAttach && (panelBackground.y + panelBackground.height) >= (root.height - (isFramed ? frameThickness + 1 : 1))

    readonly property bool touchingTopBar: allowAttachToBar && root.barPosition === "top" && !root.barIsVertical && Math.abs(panelBackground.y - ((isFramed ? 0 : root.barMarginV) + root.barHeight)) <= 1
    readonly property bool touchingBottomBar: allowAttachToBar && root.barPosition === "bottom" && !root.barIsVertical && Math.abs((panelBackground.y + panelBackground.height) - (root.height - (isFramed ? 0 : root.barMarginV) - root.barHeight)) <= 1
    readonly property bool touchingLeftBar: allowAttachToBar && root.barPosition === "left" && root.barIsVertical && Math.abs(panelBackground.x - (getBarLeftMargin() + root.barHeight)) <= 1
    readonly property bool touchingRightBar: allowAttachToBar && root.barPosition === "right" && root.barIsVertical && Math.abs((panelBackground.x + panelBackground.width) - (root.width - getBarRightMargin() - root.barHeight)) <= 1

    property alias geometryPlaceholder: panelBackground

    Item {
      id: panelBackground

      readonly property var panelItem: panelBackground

      property real targetWidth: 0
      property real targetHeight: 0
      property real targetX: root.x
      property real targetY: root.y

      property bool dimensionsInitialized: false

      property var bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

      readonly property bool willTouchTopBar: {
        if (!panelContent.allowAttachToBar || root.barPosition !== "top" || root.barIsVertical)
          return false;
        var targetTopBarY = (isFramed ? 0 : root.barMarginV) + root.barHeight;
        return Math.abs(panelBackground.targetY - targetTopBarY) <= 1;
      }
      readonly property bool willTouchBottomBar: {
        if (!panelContent.allowAttachToBar || root.barPosition !== "bottom" || root.barIsVertical)
          return false;
        var targetBottomBarY = root.height - (isFramed ? 0 : root.barMarginV) - root.barHeight - panelBackground.targetHeight;
        return Math.abs(panelBackground.targetY - targetBottomBarY) <= 1;
      }
      readonly property bool willTouchLeftBar: {
        if (!panelContent.allowAttachToBar || root.barPosition !== "left" || !root.barIsVertical)
          return false;
        var targetLeftBarX = getBarLeftMargin() + root.barHeight;
        return Math.abs(panelBackground.targetX - targetLeftBarX) <= 1;
      }
      readonly property bool willTouchRightBar: {
        if (!panelContent.allowAttachToBar || root.barPosition !== "right" || !root.barIsVertical)
          return false;
        var targetRightBarX = root.width - getBarRightMargin() - root.barHeight - panelBackground.targetWidth;
        return Math.abs(panelBackground.targetX - targetRightBarX) <= 1;
      }
      readonly property bool willTouchTopEdge: panelContent.allowAttach && panelBackground.targetY <= (isFramed ? frameThickness + 1 : 1)
      readonly property bool willTouchBottomEdge: panelContent.allowAttach && (panelBackground.targetY + panelBackground.targetHeight) >= (root.height - (isFramed ? frameThickness + 1 : 1))
      readonly property bool willTouchLeftEdge: panelContent.allowAttach && panelBackground.targetX <= (isFramed ? frameThickness + 1 : 1)
      readonly property bool willTouchRightEdge: panelContent.allowAttach && (panelBackground.targetX + panelBackground.targetWidth) >= (root.width - (isFramed ? frameThickness + 1 : 1))

      readonly property bool isActuallyAttachedToAnyEdge: {
        return willTouchTopBar || willTouchBottomBar || willTouchLeftBar || willTouchRightBar || willTouchTopEdge || willTouchBottomEdge || willTouchLeftEdge || willTouchRightEdge;
      }

      readonly property bool animateFromTop: {
        if (!panelContent.allowAttach || !isActuallyAttachedToAnyEdge) {
          return true;
        }
        if (!root.isPanelVisible) {
          if (panelContent.allowAttachToBar && root.effectivePanelAnchorTop && !root.barIsVertical) {
            return true;
          }
          var attachedToVerticalBar = panelContent.allowAttachToBar && root.barIsVertical && ((root.effectivePanelAnchorLeft && root.barPosition === "left") || (root.effectivePanelAnchorRight && root.barPosition === "right"));
          if (attachedToVerticalBar) {
            return false;
          }
          var touchingNonTopEdge = (willTouchLeftEdge || willTouchRightEdge || willTouchBottomEdge) && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar;
          if (touchingNonTopEdge) {
            return false;
          }
          if (willTouchTopEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar) {
            return true;
          }
          if (root.panelAnchorLeft || root.panelAnchorRight || root.panelAnchorBottom) {
            return false;
          }
          if (panelContent.allowAttach && root.panelAnchorTop) {
            return true;
          }
          return true;
        }
        if (willTouchTopBar) {
          return true;
        }
        if (willTouchTopEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar) {
          return true;
        }
        if (!isActuallyAttachedToAnyEdge) {
          return true;
        }
        return false;
      }
      readonly property bool animateFromBottom: {
        if (!panelContent.allowAttach || !isActuallyAttachedToAnyEdge) {
          return false;
        }
        if (!root.isPanelVisible) {
          if (panelContent.allowAttachToBar && root.effectivePanelAnchorBottom && !root.barIsVertical) {
            return true;
          }
          var attachedToVerticalBar = panelContent.allowAttachToBar && root.barIsVertical && ((root.effectivePanelAnchorLeft && root.barPosition === "left") || (root.effectivePanelAnchorRight && root.barPosition === "right"));
          if (attachedToVerticalBar) {
            return false;
          }
          if (willTouchBottomEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar) {
            return true;
          }
          if (root.panelAnchorTop || root.panelAnchorLeft || root.panelAnchorRight) {
            return false;
          }
          if (panelContent.allowAttach && root.panelAnchorBottom) {
            return true;
          }
          return false;
        }
        if (willTouchBottomBar) {
          return true;
        }
        if (willTouchBottomEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar) {
          return true;
        }
        return false;
      }
      readonly property bool animateFromLeft: {
        if (!panelContent.allowAttach || !isActuallyAttachedToAnyEdge) {
          return false;
        }
        if (!root.isPanelVisible) {
          if (panelContent.allowAttachToBar && root.effectivePanelAnchorLeft && root.barIsVertical && root.barPosition === "left") {
            return true;
          }
          if (willTouchLeftEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar) {
            return true;
          }
          if (root.panelAnchorLeft) {
            return true;
          }
          return false;
        }
        if (willTouchTopBar || willTouchBottomBar) {
          return false;
        }
        if (willTouchLeftBar) {
          return true;
        }
        if (willTouchTopEdge || willTouchBottomEdge) {
          return false;
        }
        if (willTouchLeftEdge && !willTouchLeftBar && !willTouchTopBar && !willTouchBottomBar && !willTouchRightBar) {
          return true;
        }
        return false;
      }
      readonly property bool animateFromRight: {
        if (!panelContent.allowAttach || !isActuallyAttachedToAnyEdge) {
          return false;
        }
        if (!root.isPanelVisible) {
          if (panelContent.allowAttachToBar && root.effectivePanelAnchorRight && root.barIsVertical && root.barPosition === "right") {
            return true;
          }
          if (willTouchRightEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar) {
            return true;
          }
          if (root.panelAnchorRight) {
            return true;
          }
          return false;
        }
        if (willTouchTopBar || willTouchBottomBar) {
          return false;
        }
        if (willTouchRightBar) {
          return true;
        }
        if (willTouchTopEdge || willTouchBottomEdge) {
          return false;
        }
        if (willTouchRightEdge && !willTouchLeftBar && !willTouchTopBar && !willTouchBottomBar && !willTouchRightBar) {
          return true;
        }
        return false;
      }

      readonly property bool shouldAnimateWidth: !shouldAnimateHeight && (animateFromLeft || animateFromRight)
      readonly property bool shouldAnimateHeight: animateFromTop || animateFromBottom

      readonly property real currentWidth: {
        if (isClosing && opacityFadeComplete && shouldAnimateWidth)
          return 0;
        if (isClosing || isPanelVisible)
          return targetWidth;
        return shouldAnimateWidth ? 0 : targetWidth;
      }
      readonly property real currentHeight: {
        if (isClosing && opacityFadeComplete && shouldAnimateHeight)
          return 0;
        if (isClosing || isPanelVisible)
          return targetHeight;
        return shouldAnimateHeight ? 0 : targetHeight;
      }

      width: currentWidth
      height: currentHeight

      x: {
        if (root.cachedAnimateFromRight && root.cachedShouldAnimateWidth) {
          var targetRightEdge = targetX + targetWidth;
          return targetRightEdge - width;
        }
        return targetX;
      }
      y: {
        if (root.cachedAnimateFromBottom && root.cachedShouldAnimateHeight) {
          var targetBottomEdge = targetY + targetHeight;
          return targetBottomEdge - height;
        }
        return targetY;
      }

      Behavior on width {
        enabled: !PanelService.closedImmediately
        NumberAnimation {
          id: widthAnimation
          duration: !panelBackground.dimensionsInitialized ? 0 : (root.isOpening && !panelBackground.shouldAnimateWidth) ? 0 : root.isOpening ? Style.animationNormal : (root.isClosing && !panelBackground.shouldAnimateWidth) ? 0 : root.isClosing ? Style.animationFast : Style.animationNormal
          easing.type: Easing.BezierSpline
          easing.bezierCurve: panelBackground.bezierCurve

          onRunningChanged: {
            if (!running && duration === 0) {
              if (root.isClosing && panelBackground.width === 0 && panelBackground.shouldAnimateWidth) {
                Qt.callLater(root.finalizeClose);
              }
              return;
            }
            if (!running && root.isClosing && panelBackground.width === 0 && panelBackground.shouldAnimateWidth) {
              Qt.callLater(root.finalizeClose);
            }
          }
        }
      }

      Behavior on height {
        enabled: !PanelService.closedImmediately
        NumberAnimation {
          id: heightAnimation
          duration: !panelBackground.dimensionsInitialized ? 0 : (root.isOpening && !panelBackground.shouldAnimateHeight) ? 0 : root.isOpening ? Style.animationNormal : (root.isClosing && !panelBackground.shouldAnimateHeight) ? 0 : root.isClosing ? Style.animationFast : Style.animationNormal
          easing.type: Easing.BezierSpline
          easing.bezierCurve: panelBackground.bezierCurve

          onRunningChanged: {
            if (!running && duration === 0) {
              if (root.isClosing && panelBackground.height === 0 && panelBackground.shouldAnimateHeight) {
                Qt.callLater(root.finalizeClose);
              }
              return;
            }
            if (!running && root.isClosing && panelBackground.height === 0 && panelBackground.shouldAnimateHeight) {
              Qt.callLater(root.finalizeClose);
            }
          }
        }
      }

      property int topLeftCornerState: {
        if (!root.barShouldShow) {
          var edgeInverted = panelContent.allowAttach && (panelContent.touchingLeftEdge || panelContent.touchingTopEdge);
          if (edgeInverted) {
            if (panelContent.touchingLeftEdge && panelContent.touchingTopEdge)
              return 0;
            if (panelContent.touchingLeftEdge)
              return 2;
            if (panelContent.touchingTopEdge)
              return 1;
          }
          return 0;
        }

        var barTouchInverted = panelContent.touchingTopBar || panelContent.touchingLeftBar;
        var edgeInverted = panelContent.allowAttach && (panelContent.touchingLeftEdge || panelContent.touchingTopEdge);

        if (barTouchInverted || edgeInverted) {
          if (panelContent.touchingLeftEdge && panelContent.touchingTopEdge)
            return 0;
          if (panelContent.touchingLeftEdge)
            return 2;
          if (panelContent.touchingTopEdge)
            return 1;
          return root.barIsVertical ? 2 : 1;
        }
        return 0;
      }

      property int topRightCornerState: {
        if (!root.barShouldShow) {
          var edgeInverted = panelContent.allowAttach && (panelContent.touchingRightEdge || panelContent.touchingTopEdge);
          if (edgeInverted) {
            if (panelContent.touchingRightEdge && panelContent.touchingTopEdge)
              return 0;
            if (panelContent.touchingRightEdge)
              return 2;
            if (panelContent.touchingTopEdge)
              return 1;
          }
          return 0;
        }

        var barTouchInverted = panelContent.touchingTopBar || panelContent.touchingRightBar;
        var edgeInverted = panelContent.allowAttach && (panelContent.touchingRightEdge || panelContent.touchingTopEdge);

        if (barTouchInverted || edgeInverted) {
          if (panelContent.touchingRightEdge && panelContent.touchingTopEdge)
            return 0;
          if (panelContent.touchingRightEdge)
            return 2;
          if (panelContent.touchingTopEdge)
            return 1;
          return root.barIsVertical ? 2 : 1;
        }
        return 0;
      }

      property int bottomLeftCornerState: {
        if (!root.barShouldShow) {
          var edgeInverted = panelContent.allowAttach && (panelContent.touchingLeftEdge || panelContent.touchingBottomEdge);
          if (edgeInverted) {
            if (panelContent.touchingLeftEdge && panelContent.touchingBottomEdge)
              return 0;
            if (panelContent.touchingLeftEdge)
              return 2;
            if (panelContent.touchingBottomEdge)
              return 1;
          }
          return 0;
        }

        var barTouchInverted = panelContent.touchingBottomBar || panelContent.touchingLeftBar;
        var edgeInverted = panelContent.allowAttach && (panelContent.touchingLeftEdge || panelContent.touchingBottomEdge);

        if (barTouchInverted || edgeInverted) {
          if (panelContent.touchingLeftEdge && panelContent.touchingBottomEdge)
            return 0;
          if (panelContent.touchingLeftEdge)
            return 2;
          if (panelContent.touchingBottomEdge)
            return 1;
          return root.barIsVertical ? 2 : 1;
        }
        return 0;
      }

      property int bottomRightCornerState: {
        if (!root.barShouldShow) {
          var edgeInverted = panelContent.allowAttach && (panelContent.touchingRightEdge || panelContent.touchingBottomEdge);
          if (edgeInverted) {
            if (panelContent.touchingRightEdge && panelContent.touchingBottomEdge)
              return 0;
            if (panelContent.touchingRightEdge)
              return 2;
            if (panelContent.touchingBottomEdge)
              return 1;
          }
          return 0;
        }

        var barTouchInverted = panelContent.touchingBottomBar || panelContent.touchingRightBar;
        var edgeInverted = panelContent.allowAttach && (panelContent.touchingRightEdge || panelContent.touchingBottomEdge);

        if (barTouchInverted || edgeInverted) {
          if (panelContent.touchingRightEdge && panelContent.touchingBottomEdge)
            return 0;
          if (panelContent.touchingRightEdge)
            return 2;
          if (panelContent.touchingBottomEdge)
            return 1;
          return root.barIsVertical ? 2 : 1;
        }
        return 0;
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        z: -1
        onClicked: mouse => {
          mouse.accepted = true;
        }
      }
    }

    Loader {
      id: contentLoader
      active: isPanelOpen
      x: panelBackground.x
      y: panelBackground.y
      width: panelBackground.width
      height: panelBackground.height
      sourceComponent: root.panelContent

      onLoaded: {
        Qt.callLater(function () {
          setPosition();
          panelBackground.dimensionsInitialized = true;

          root.cachedAnimateFromTop = panelBackground.animateFromTop;
          root.cachedAnimateFromBottom = panelBackground.animateFromBottom;
          root.cachedAnimateFromLeft = panelBackground.animateFromLeft;
          root.cachedAnimateFromRight = panelBackground.animateFromRight;
          root.cachedShouldAnimateWidth = panelBackground.shouldAnimateWidth;
          root.cachedShouldAnimateHeight = panelBackground.shouldAnimateHeight;

          root.isPanelVisible = true;
          opacityTrigger.start();

          root.openWatchdogActive = true;
          openWatchdogTimer.start();

          opened();
        });
      }
    }
  }

  Component.onCompleted: {
    PanelService.registerPanel(root);
  }
}