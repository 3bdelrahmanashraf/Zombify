# Zombify

Music player integration for Project Zomboid - Display and control Spotify, YouTube Music, and other players in-game with track info, album art, and playback controls.

Inspired by the Minecraft mod [Craftify](https://github.com/ThatGravyBoat/Craftify).

## Features

- **In-game music overlay** - Shows current track, artist, album, and album art
- **Playback controls** - Play/pause, next, previous, volume control
- **Multiple music player support**:
  - Spotify (requires Spotify Premium for playback control)
  - YouTube Music Desktop App
  - Local music files
- **Highly configurable** - Position, scale, theme, display mode, and more
- **Keybind support** - Customizable hotkeys for all controls
- **Mod Options integration** - Full configuration via PZ's Mod Options menu
- **Console commands** - Quick access via `/zombify` command

## Installation

1. Download the latest release from [GitHub Releases](https://github.com/3bdelrahmanashraf/Zombify/releases)
2. Extract the `Zombify` folder to your Project Zomboid mods directory:
   - Windows: `C:\Users\[username]\Zomboid\mods\`
   - Steam Workshop: Subscribe to the mod on Steam Workshop
3. Enable the mod in the Project Zomboid mod selector
4. Restart the game

## Configuration

### Mod Options (Recommended)
1. Open Project Zomboid main menu
2. Click "Mod Options"
3. Find "Zombify" in the list
4. Configure all settings through the UI

### Console Commands
```
/zombify toggle          - Toggle overlay visibility
/zombify show            - Show overlay
/zombify hide            - Hide overlay
/zombify settings        - Open settings panel
/zombify next            - Next track
/zombify prev            - Previous track
/zombify play            - Play/pause
/zombify vol [0-100]     - Get/set volume
/zombify connect <player> - Connect to music player (spotify|youtubemusic|local)
/zombify disconnect      - Disconnect from music player
/zombify status          - Show current status
/zombify help            - Show this help
```

### Keybinds
Default keybinds (customizable in Mod Options):
- **F10** - Toggle overlay
- **Media Play/Pause** - Play/pause
- **Media Next** - Next track
- **Media Previous** - Previous track
- **Media Volume Up** - Volume up
- **Media Volume Down** - Volume down

## Music Player Setup

### Spotify
1. Create a Spotify Developer application at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/)
2. Copy your Client ID and Client Secret
3. In Zombify settings, enter your Client ID and Client Secret
4. Select "Spotify" as the music player
5. The mod will guide you through OAuth authentication

**Note**: Playback control requires Spotify Premium. Free users can only see track info.

### YouTube Music Desktop App
1. Install [YouTube Music Desktop App](https://github.com/ytmdesktop/ytmdesktop)
2. Enable "Remote Control" in YTM settings
3. Select "YouTube Music" as the music player in Zombify
4. Follow the pairing instructions

### Local Files
1. Set your local music directory in Zombify settings
2. Select "Local Files" as the music player
3. The mod will scan for music files (MP3, FLAC, OGG, etc.)

## Settings

| Setting | Description |
|---------|-------------|
| **Enabled** | Enable/disable the mod entirely |
| **Music Player** | Select which music player to integrate |
| **Anchor Point** | Position of the overlay on screen |
| **X/Y Offset** | Fine-tune position from anchor |
| **Scale** | Overlay size multiplier |
| **Show When** | When to display overlay (Always, When Playing, In Vehicle, etc.) |
| **Display Mode** | Full, Compact, or Minimal info display |
| **Show Album Art** | Display album artwork |
| **Show Progress Bar** | Display playback progress |
| **Show Controls** | Display playback control buttons |
| **Theme** | Visual theme (Default, Dark, Light, Transparent) |
| **Spotify Client ID/Secret | Spotify API credentials |

## Building from Source

### Prerequisites
- Project Zomboid Build 42.20+
- Basic knowledge of Lua

### Structure
```
Zombify/
├── init.lua                    # Main entry point
├── mod.info                    # Mod metadata
├── poster.png                  # Mod poster image
├── media/
│   ├── lua/
│   │   ├── client/
│   │   │   ├── ZombifyMain.lua       # Core mod logic
│   │   │   ├── ZombifyUI.lua         # Overlay rendering
│   │   │   ├── ZombifySettings.lua   # Settings panel
│   │   │   └── ZombifyMusicPlayer.lua # Music player integration
│   │   └── shared/
│   │       └── ZombifyShared.lua     # Shared utilities
│   └── textures/
│       └── UI/                     # UI textures (optional)
```

## How It Works

Zombify uses a client-side Lua implementation that:
1. Registers for game events (OnTick, OnKeyPressed, OnGameStart)
2. Maintains a connection to music players (via external WebSocket bridge in production)
3. Renders an overlay using PZ's ISUI system
4. Provides configuration via Mod Options and console commands

**Note**: The current implementation includes placeholder music player connections. For full functionality, an external bridge application (Python/Node.js) is needed to connect to Spotify/YouTube Music APIs and communicate with the mod via WebSocket.

## External Controller (Required for Full Functionality)

For real music player integration, you need to run a separate controller application. This is a known limitation of PZ's sandboxed Lua environment.

A reference implementation in Python:
```python
# zombify_controller.py
import asyncio
import websockets
import spotipy
from spotipy.oauth2 import SpotifyOAuth

# This would handle:
# - Spotify OAuth authentication
# - WebSocket server for mod communication
# - Playback control via Spotify Web API
# - Track info polling and pushing to mod
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details

## Credits

- Inspired by [Craftify](https://github.com/ThatGravyBoat/Craftify) by ThatGravyBoat
- Project Zomboid modding community for documentation and examples
- The Indie Stone for creating Project Zomboid

## Support

- **Issues**: [GitHub Issues](https://github.com/3bdelrahmanashraf/Zombify/issues)
- **Discussions**: [GitHub Discussions](https://github.com/3bdelrahmanashraf/Zombify/discussions)
- **Discord**: [Project Zomboid Modding Discord](https://discord.gg/projectzomboid)

---

**Disclaimer**: This mod is not affiliated with Spotify, YouTube Music, or The Indie Stone. Use at your own risk.