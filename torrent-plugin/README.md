# Torrent plugin for Noctalia Shell

<img width="377" height="194" alt="preview" src="https://github.com/user-attachments/assets/16bdbe8e-6e36-484b-80fc-b5668737d245" /> <img width="368" height="310" alt="preview2" src="https://github.com/user-attachments/assets/b415acc1-3afa-4f98-b5b3-300d98ccff03" />



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
