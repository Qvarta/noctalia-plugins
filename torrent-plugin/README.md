# Torrent plugin for Noctalia Shell( in development)

A widget for monitoring and managing torrent downloads via Noctalia/Quickshell.

## Requirements

- **transmission-daemon**
- **transmission-cli**

Install with:
  - ALT: `sudo apt-get install transmission-daemon transmission-cli`


Connects to localhost:9091 by default.


## Components

- **BarWidget.qml**: Compact widget shown in the system bar
- **Panel.qml**: Expanded panel showing list torrents
- **Main.qml**: Core logic