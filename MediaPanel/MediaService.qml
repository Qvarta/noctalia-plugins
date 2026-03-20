pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons

Singleton {
  id: root

  // ============ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ============
  
  function formatTime(seconds) {
    if (isNaN(seconds) || seconds < 0)
      return "0:00";
    var h = Math.floor(seconds / 3600);
    var m = Math.floor((seconds % 3600) / 60);
    var s = Math.floor(seconds % 60);
    var pad = function (n) {
      return (n < 10) ? ("0" + n) : n;
    };

    if (h > 0) {
      return h + ":" + pad(m) + ":" + pad(s);
    } else {
      return m + ":" + pad(s);
    }
  }

  function getControlTarget() {
    return currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null;
  }

  function isCurrentLyricsTrack(artist, track) {
    return currentLyricsArtist === artist && currentLyricsTitle === track;
  }

  // логгер 
  function logLyrics(message, ...args) {
    if (debugLyrics) {
      Logger.i("[Lyrics] " + message);
    }
  }

  function setLyricsError(text) {
    lyricsText = text;
    lyricsLines = [text];
    lyricsTimes = [];
  }

  property var timeRegex: /^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/

  // ============ ОСНОВНЫЕ СВОЙСТВА ============

  property var currentPlayer: null
  property string lastArtUrl: ""
  
  property string playerIdentity: currentPlayer ? (currentPlayer.identity || "") : ""
  property real currentPosition: 0
  property bool isSeeking: false
  property int selectedPlayerIndex: 0
  property bool isPlaying: currentPlayer ? (currentPlayer.playbackState === MprisPlaybackState.Playing || currentPlayer.isPlaying) : false
  property string trackTitle: currentPlayer ? (currentPlayer.trackTitle !== undefined ? currentPlayer.trackTitle.replace(/(\r\n|\n|\r)/g, "") : "") : ""
  property string trackArtist: currentPlayer ? (currentPlayer.trackArtist || "") : ""
  property string trackAlbum: currentPlayer ? (currentPlayer.trackAlbum || "") : ""
  
  property string trackArtUrl: {
    if (currentPlayer && currentPlayer.trackArtUrl && currentPlayer.trackArtUrl !== "") {
      lastArtUrl = currentPlayer.trackArtUrl
      return currentPlayer.trackArtUrl
    }
    return lastArtUrl
  }
  
  property real trackLength: currentPlayer ? ((currentPlayer.length < infiniteTrackLength) ? currentPlayer.length : 0) : 0
  property bool canPlay: currentPlayer ? currentPlayer.canPlay : false
  property bool canPause: currentPlayer ? currentPlayer.canPause : false
  property bool canGoNext: currentPlayer ? currentPlayer.canGoNext : false
  property bool canGoPrevious: currentPlayer ? currentPlayer.canGoPrevious : false
  property bool canSeek: currentPlayer ? currentPlayer.canSeek : false
  property string positionString: formatTime(currentPosition)
  property string lengthString: formatTime(trackLength)
  property real infiniteTrackLength: 922337203685

  // ============ TEXT ============
  
  property string lyricsText: ""
  property var lyricsLines: []
  property var lyricsTimes: []
  property bool isFetchingLyrics: false
  property bool useSyncedLyrics: false
  property bool hasLyrics: lyricsLines.length > 0 && !isFetchingLyrics
  
  property string currentLyricsArtist: ""
  property string currentLyricsTitle: ""
  property string lastLyricsArtist: ""
  property string lastLyricsTitle: ""
  property bool debugLyrics: false

  property int currentLineIndex: {
    if (!useSyncedLyrics || lyricsTimes.length === 0 || lyricsLines.length === 0) {
      return -1;
    }
    
    var pos = currentPosition;
    
    for (var i = lyricsTimes.length - 1; i >= 0; i--) {
      if (pos >= lyricsTimes[i]) {
        if (i < lyricsTimes.length - 1 && pos >= lyricsTimes[i + 1]) {
          continue;
        }
        return i;
      }
    }
    
    return -1;
  }

  // Функция для проверки мусорных метаданных
  function isGarbageMetadata(title, artist) {
    if (!title && !artist) return true;
    
    // Проверяем только если строка не пустая
    if (title) {
      if (title.includes("Яндекс Музыка")) return true;
      if (title.includes("Yandex Music")) return true;
    }
    
    return false;
  }

  function updateLyricsTrackInfo() {
    var rawArtist = trackArtist || "";
    var rawTitle = trackTitle || "";
    
    if (isGarbageMetadata(rawTitle, rawArtist)) {
      logLyrics("Garbage metadata detected, ignoring: " + rawArtist + " - " + rawTitle);
      return;
    }
    
    var newArtist = rawArtist;
    var newTitle = rawTitle;
    
    var trackChanged = (currentLyricsArtist !== newArtist || currentLyricsTitle !== newTitle) && 
                       (newArtist !== "" || newTitle !== "");
    
    if (trackChanged) {
      logLyrics("Track changed from: " + currentLyricsArtist + " - " + currentLyricsTitle + 
                " to: " + newArtist + " - " + newTitle);
      
      resetLyrics();
      
      currentLyricsArtist = newArtist;
      currentLyricsTitle = newTitle;
      lastLyricsArtist = newArtist;
      lastLyricsTitle = newTitle;
      
      if (newArtist && newTitle) {
        if (!fetchLyricsTimer.running) {
          fetchLyricsTimer.start();
        } else {
          fetchLyricsTimer.restart();
        }
      }
    }
  }

  function resetLyrics() {
    lyricsText = "";
    lyricsLines = [];
    lyricsTimes = [];
    useSyncedLyrics = false;
    isFetchingLyrics = false;
  }

  // Универсальная функция для создания HTTP запросов
  function createRequest(url, onDone, onError, timeoutMs = 5000) {
    var xhr = new XMLHttpRequest();
    xhr.timeout = timeoutMs;
    
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        onDone(xhr);
      }
    };
    
    xhr.ontimeout = function() {
      onError("timeout");
    };
    
    xhr.onerror = function() {
      onError("network");
    };
    
    xhr.open("GET", url);
    xhr.setRequestHeader("User-Agent", "noctalia-shell/1.0");
    xhr.setRequestHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    xhr.setRequestHeader("Pragma", "no-cache");
    xhr.setRequestHeader("Expires", "0");
    xhr.send();
    
    return xhr;
  }

  function fetchLyrics(artist, track) {
    logLyrics("fetchLyrics called for: " + artist + " - " + track +
              " current: " + currentLyricsArtist + " - " + currentLyricsTitle);
    
    if (isFetchingLyrics) {
      logLyrics("Already fetching lyrics for current track");
      return;
    }
    
    if (!isCurrentLyricsTrack(artist, track)) {
      logLyrics("Request doesn't match current track, ignoring");
      return;
    }
    
    if (lyricsLines.length > 0 && lyricsText !== "Запрашиваю текст..." && lyricsText !== "") {
      logLyrics("Lyrics already loaded for current track");
      return;
    }
    
    if (!artist || !track || artist === "" || track === "") {
      setLyricsError("Исполнитель или название трека не указаны");
      isFetchingLyrics = false;
      return;
    }

    isFetchingLyrics = true;
    lyricsText = "Запрашиваю текст...";
    lyricsLines = ["Запрашиваю текст..."];

    var encodedArtist = encodeURIComponent(artist);
    var encodedTrack = encodeURIComponent(track);
    var timestamp = new Date().getTime();
    var apiUrl = "https://lrclib.net/api/get?artist_name=" + encodedArtist + 
                 "&track_name=" + encodedTrack + 
                 "&_=" + timestamp;

    logLyrics("Fetching lyrics for: " + artist + " - " + track);

    createRequest(apiUrl,
      function(xhr) {
        if (!isCurrentLyricsTrack(artist, track)) {
          logLyrics("Track changed during request, ignoring response");
          root.isFetchingLyrics = false;
          return;
        }
        
        logLyrics("Lyrics response status: " + xhr.status + " for: " + artist + " - " + track);
        
        if (xhr.status === 200) {
          try {
            var response = JSON.parse(xhr.responseText);
            
            if (!isCurrentLyricsTrack(artist, track)) {
              logLyrics("Track changed after parsing, ignoring response");
              root.isFetchingLyrics = false;
              return;
            }
            
            var syncedLyrics = response.syncedLyrics || "";
            var plainLyrics = response.plainLyrics || "";
            
            if (syncedLyrics !== "" && syncedLyrics !== null) {
              logLyrics("Synced lyrics found");
              root.useSyncedLyrics = true;
              
              var lines = syncedLyrics.split('\n');
              var textLines = [];
              var times = [];
              
              for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "") continue;
                
                var match = line.match(root.timeRegex);
                if (match) {
                  var minutes = parseInt(match[1]);
                  var seconds = parseFloat(match[2]);
                  var timeInSeconds = minutes * 60 + seconds;
                  var text = match[3];
                  
                  times.push(timeInSeconds);
                  textLines.push(text);
                } else {
                  textLines.push(line);
                }
              }
              
              root.lyricsLines = textLines;
              root.lyricsTimes = times;
              root.lyricsText = syncedLyrics;
              
              logLyrics("Parsed " + textLines.length + " lines with times");
              
            } else if (plainLyrics !== "" && plainLyrics !== null) {
              logLyrics("Plain lyrics found");
              root.useSyncedLyrics = false;
              var plainLines = plainLyrics.split('\n').filter(line => line.trim() !== "");
              root.lyricsLines = plainLines;
              root.lyricsTimes = [];
              root.lyricsText = plainLyrics;
            } else {
              setLyricsError("Текст не найден для этого трека");
            }
            
          } catch (e) {
            logLyrics("Failed to parse lyrics data: " + e);
            setLyricsError("Ошибка парсинга ответа");
          }
        } else if (xhr.status === 404) {
          logLyrics("Lyrics not found (404) for: " + artist + " - " + track);
          setLyricsError("Текст не найден для этого трека");
        } else {
          logLyrics("Error " + xhr.status + " for: " + artist + " - " + track);
          setLyricsError("Ошибка загрузки текста");
        }
        
        if (isCurrentLyricsTrack(artist, track)) {
          root.isFetchingLyrics = false;
        }
      },
      function(errorType) {
        logLyrics("Request " + errorType + " for: " + artist + " - " + track);
        if (isCurrentLyricsTrack(artist, track)) {
          if (errorType === "timeout") {
            setLyricsError("Таймаут запроса");
          } else {
            setLyricsError("Сетевая ошибка");
          }
          root.isFetchingLyrics = false;
        } else {
          root.isFetchingLyrics = false;
        }
      }
    );
  }

  Timer {
    id: fetchLyricsTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (root.currentLyricsArtist && root.currentLyricsTitle) {
        root.fetchLyrics(root.currentLyricsArtist, root.currentLyricsTitle);
      }
    }
  }

  // ============ ЛОГИКА ПЛЕЕРОВ ============

  function getAvailablePlayers() {
    if (!Mpris.players || !Mpris.players.values) {
      return [];
    }

    let allPlayers = Mpris.players.values;
    let finalPlayers = [];
    const genericBrowsers = ["firefox", "chromium", "chrome"];
    
    const blacklist = (Settings.data.audio && Settings.data.audio.mprisBlacklist) || [];
    const normalizedBlacklist = blacklist.map(b => (b || "").toLowerCase());

    let specificPlayers = [];
    let genericPlayers = [];
    
    for (var i = 0; i < allPlayers.length; i++) {
      const player = allPlayers[i];
      const identity = (player.identity || "").toLowerCase();
      const name = (player.name || "").toLowerCase();
      
      // Проверяем blacklist
      const isBlacklisted = normalizedBlacklist.some(b => 
        b && (identity.includes(b) || name.includes(b))
      );
      
      if (isBlacklisted) continue;
      
      player._normalizedIdentity = identity;
      player._normalizedName = name;
      
      if (genericBrowsers.some(b => identity.includes(b))) {
        genericPlayers.push(player);
      } else {
        specificPlayers.push(player);
      }
    }

    let genericMap = {};
    for (let g of genericPlayers) {
      let title = String(g.trackTitle || "").trim().toLowerCase();
      if (title && !isGarbageMetadata(title, "")) {
        let key = title.substring(0, 50);
        if (!genericMap[key] || g.trackArtUrl) {
          genericMap[key] = g;
        }
      }
    }

    for (var i = 0; i < specificPlayers.length; i++) {
      let specificPlayer = specificPlayers[i];
      
      let title1 = String(specificPlayer.trackTitle || "").trim();
      let artist1 = String(specificPlayer.trackArtist || "").trim();
      
      if (isGarbageMetadata(title1, artist1)) continue;
      
      let wasMatched = false;
      
      if (title1) {
        let key = title1.substring(0, 50).toLowerCase();
        let genericPlayer = genericMap[key];
        
        if (genericPlayer) {
          let dataPlayer = genericPlayer;
          let identityPlayer = specificPlayer;
          
          if (specificPlayer.trackArtUrl) {
            dataPlayer = specificPlayer;
          }
          
          let virtualPlayer = {
            "identity": identityPlayer.identity,
            "desktopEntry": identityPlayer.desktopEntry,
            "trackTitle": dataPlayer.trackTitle,
            "trackArtist": dataPlayer.trackArtist,
            "trackAlbum": dataPlayer.trackAlbum,
            "trackArtUrl": dataPlayer.trackArtUrl || specificPlayer.trackArtUrl || genericPlayer.trackArtUrl || root.lastArtUrl,
            "length": dataPlayer.length || 0,
            "position": dataPlayer.position || 0,
            "playbackState": dataPlayer.playbackState,
            "isPlaying": dataPlayer.isPlaying || false,
            "canPlay": dataPlayer.canPlay || false,
            "canPause": dataPlayer.canPause || false,
            "canGoNext": dataPlayer.canGoNext || false,
            "canGoPrevious": dataPlayer.canGoPrevious || false,
            "canSeek": dataPlayer.canSeek || false,
            "canControl": dataPlayer.canControl || false,
            "_stateSource": dataPlayer,
            "_controlTarget": identityPlayer
          };
          finalPlayers.push(virtualPlayer);
          wasMatched = true;
          
          delete genericMap[key];
        }
      }
      
      if (!wasMatched) {
        finalPlayers.push(specificPlayer);
      }
    }

    for (let key in genericMap) {
      finalPlayers.push(genericMap[key]);
    }

    let controllablePlayers = [];
    for (var i = 0; i < finalPlayers.length; i++) {
      let player = finalPlayers[i];
      if (player && player.canPlay) {
        controllablePlayers.push(player);
      }
    }
    
    return controllablePlayers;
  }

  function findActivePlayer() {
    let availablePlayers = getAvailablePlayers();
    if (availablePlayers.length === 0) {
      return null;
    }

    for (var i = 0; i < availablePlayers.length; i++) {
      if (availablePlayers[i] && availablePlayers[i].playbackState === MprisPlaybackState.Playing) {
        Logger.d("Media", "Found actively playing player: " + availablePlayers[i].identity);
        selectedPlayerIndex = i;
        return availablePlayers[i];
      }
    }

    const preferred = (Settings.data.audio.preferredPlayer || "");
    if (preferred !== "") {
      const prefLower = preferred.toLowerCase();
      for (var i = 0; i < availablePlayers.length; i++) {
        const p = availablePlayers[i];
        const identity = (p.identity || "").toLowerCase();
        if (identity.includes(prefLower)) {
          selectedPlayerIndex = i;
          return p;
        }
      }
    }

    if (selectedPlayerIndex < availablePlayers.length) {
      return availablePlayers[selectedPlayerIndex];
    } else {
      selectedPlayerIndex = 0;
      return availablePlayers[0];
    }
  }

  property bool autoSwitchingPaused: false

  function switchToPlayer(index) {
    let availablePlayers = getAvailablePlayers();
    if (index >= 0 && index < availablePlayers.length) {
      let newPlayer = availablePlayers[index];
      if (newPlayer !== currentPlayer) {
        currentPlayer = newPlayer;
        selectedPlayerIndex = index;
        currentPosition = currentPlayer ? currentPlayer.position : 0;
        Logger.d("Media", "Manually switched to player " + currentPlayer.identity);
      }
    }
  }

  function updateCurrentPlayer() {
    let newPlayer = findActivePlayer();
    
    if (newPlayer && currentPlayer && newPlayer.identity === currentPlayer.identity)
        return
    
    if (newPlayer !== currentPlayer) {
      currentPlayer = newPlayer;
      currentPosition = currentPlayer ? currentPlayer.position : 0;
      Logger.d("Media", "Switching player");
    }
  }

  // ============ УПРАВЛЕНИЕ ВОСПРОИЗВЕДЕНИЕМ ============

  function playPause() {
    if (currentPlayer) {
      let stateSource = currentPlayer._stateSource || currentPlayer;
      let controlTarget = currentPlayer._controlTarget || currentPlayer;
      if (stateSource.playbackState === MprisPlaybackState.Playing) {
        controlTarget.pause();
      } else {
        controlTarget.play();
      }
    }
  }

  function play() {
    let target = getControlTarget();
    if (target && target.canPlay) {
      target.play();
    }
  }

  function stop() {
    let target = getControlTarget();
    if (target) {
      target.stop();
    }
  }

  function pause() {
    let target = getControlTarget();
    if (target && target.canPause) {
      target.pause();
    }
  }

  function next() {
    let target = getControlTarget();
    if (target && target.canGoNext) {
      target.next();
    }
  }

  function previous() {
    let target = getControlTarget();
    if (target && target.canGoPrevious) {
      target.previous();
    }
  }

  function seek(position) {
    let target = getControlTarget();
    if (target && target.canSeek) {
      target.position = position;
      currentPosition = position;
    }
  }

  function seekRelative(offset) {
    let target = getControlTarget();
    if (target && target.canSeek && target.length > 0) {
      let seekPosition = target.position + offset;
      target.position = seekPosition;
      currentPosition = seekPosition;
    }
  }

  function seekByRatio(ratio) {
    let target = getControlTarget();
    if (target && target.canSeek && target.length > 0) {
      let seekPosition = ratio * target.length;
      target.position = seekPosition;
      currentPosition = seekPosition;
    }
  }

  // ============ ТАЙМЕРЫ И СОЕДИНЕНИЯ ============

  Timer {
    id: positionTimer
    interval: 1000
    running: currentPlayer && !root.isSeeking && currentPlayer.isPlaying && 
             currentPlayer.length > 0 && currentPlayer.playbackState === MprisPlaybackState.Playing
    repeat: true
    onTriggered: {
      if (currentPlayer && !root.isSeeking && currentPlayer.isPlaying && 
          currentPlayer.playbackState === MprisPlaybackState.Playing) {
        currentPosition = currentPlayer.position;
      } else {
        running = false;
      }
    }
  }

  Connections {
    target: currentPlayer
    function onPositionChanged() {
      if (!root.isSeeking && currentPlayer) {
        currentPosition = currentPlayer.position;
      }
    }
    function onPlaybackStateChanged() {
      if (!root.isSeeking && currentPlayer) {
        currentPosition = currentPlayer.position;
      }
    }
  }

  onCurrentPlayerChanged: {
    if (!currentPlayer || !currentPlayer.isPlaying || currentPlayer.playbackState !== MprisPlaybackState.Playing) {
      currentPosition = 0;
    }
  }

  Timer {
    id: playerStateMonitor
    interval: 2000
    repeat: true
    running: (currentPlayer === null || !currentPlayer.isPlaying) && !autoSwitchingPaused
    onTriggered: {
      if (!autoSwitchingPaused && (!currentPlayer || !currentPlayer.isPlaying)) {
        updateCurrentPlayer();
      }
    }
  }

  Connections {
    target: Mpris.players
    function onValuesChanged() {
      Logger.d("Media", "Players changed");
      updateCurrentPlayer();
    }
  }

  Connections {
    target: root
    function onTrackArtistChanged() {
      updateLyricsTrackInfo();
    }
    function onTrackTitleChanged() {
      updateLyricsTrackInfo();
    }
    function onCurrentPlayerChanged() {
      updateLyricsTrackInfo();
    }
  }

  Component.onCompleted: {
    updateCurrentPlayer();
    updateLyricsTrackInfo();
  }
}