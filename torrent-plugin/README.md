# Torrent plugin for Noctalia Shell( in development)

Widget for monitoring downloads through Noctalia/Quickshell.
It can add/remove torrents and monitor the download status.

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