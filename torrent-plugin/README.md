# Torent plugin for Noctalia Shell

Widget for monitoring downloads through Noctalia/Quickshell.

## Dependencies

- **transmissions-daemon**
- **transmissions-remoute**

Install with:
  - ALT: `sudo apt-get install transmissions-daemon transmissions-remoute`


Connects to localhost:9091 by default.

## Requirements

    Noctalia/Quickshell 3.6.0+
    Transmission Daemon with RPC enabled


## Components

- **BarWidget.qml**: Compact widget shown in the system bar
- **Panel.qml**: Expanded panel showing list torrents
- **Main.qml**: Core logic