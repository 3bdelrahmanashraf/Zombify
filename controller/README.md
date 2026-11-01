# Zombify Controller

External controller application for the Zombify Project Zomboid mod. Handles Spotify and YouTube Music integration via WebSocket.

## Overview

The Zombify mod in Project Zomboid cannot directly access Spotify/YouTube Music APIs due to Lua sandboxing. This controller app runs externally and:

1. **Authenticates** with Spotify (OAuth2) and YouTube Music (headers)
2. **Runs a WebSocket server** on `ws://127.0.0.1:8765` for the mod to connect
3. **Runs an HTTP server** on `http://127.0.0.1:8766` for OAuth callbacks and status
4. **Polls music player state** every 2 seconds and pushes updates to connected clients
5. **Accepts playback commands** from the mod (play/pause, next, previous, volume)

## Architecture

```
┌─────────────────┐     WebSocket      ┌──────────────────────┐
│  Zombify Mod    │ ◄────────────────► │  Zombify Controller  │
│  (PZ Mod)       │   Track updates    │  (Python App)        │
└─────────────────┘   Commands         └──────────┬───────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────────┐
                    ▼                             ▼                             ▼
            ┌───────────────┐             ┌───────────────┐             ┌───────────────┐
            │   Spotify     │             │ YouTube Music │             │  Local Files  │
            │   Web API     │             │   (ytmusicapi)│             │  (Future)     │
            └───────────────┘             └───────────────┘             └───────────────┘
```

## Requirements

- Python 3.10+
- Spotify Developer Account (for Spotify integration)
- YouTube Music Account (for YouTube Music integration)

## Installation

```bash
cd controller
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in your credentials:
   ```env
   SPOTIFY_CLIENT_ID=your_client_id
   SPOTIFY_CLIENT_SECRET=your_client_secret
   SPOTIFY_REDIRECT_URI=http://localhost:8765/callback
   ```

### Spotify Setup

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/)
2. Create a new app
3. Set Redirect URI to `http://localhost:8765/callback`
4. Copy Client ID and Client Secret to `.env`

### YouTube Music Setup

Run the setup script:
```bash
python setup_ytmusic.py
```

Follow the instructions to extract headers from your browser. This creates `ytmusic_headers.json`.

## Running the Controller

```bash
python zombify_controller.py
```

The controller will start:
- **WebSocket server**: `ws://127.0.0.1:8765` (for mod connection)
- **HTTP server**: `http://127.0.0.1:8766` (for OAuth and status)

### Authentication

1. Open `http://127.0.0.1:8766/auth/spotify` in browser
2. Log in to Spotify and authorize
3. You'll be redirected back with success message

### Status

Check status at: `http://127.0.0.1:8766/status`

## WebSocket Protocol

### Client → Server Messages

```json
{
  "command": "play_pause",
  "params": {}
}
```

Supported commands:
- `play_pause` - Toggle playback
- `next` - Next track
- `previous` - Previous track
- `volume` - Set volume (params: `{"volume": 0.5}`)
- `get_status` - Request current status
- `set_player` - Switch player (params: `{"player_type": "spotify"}`)

### Server → Client Messages

```json
{
  "type": "status",
  "data": {
    "track": "Song Name",
    "artist": "Artist Name",
    "album": "Album Name",
    "duration": 240000,
    "progress": 45000,
    "is_playing": true,
    "volume": 0.8,
    "album_art": "base64_encoded_png",
    "player_type": "spotify",
    "timestamp": 1234567890
  }
}
```

## Using with Zombify Mod

1. Start the controller: `python zombify_controller.py`
2. Authenticate Spotify: Open `http://localhost:8766/auth/spotify`
3. In Project Zomboid, enable Zombify mod
4. Press F10 or type `/zombify settings`
5. Select "Spotify" or "YouTubeMusic" as music player
6. The overlay will connect and display track info

## Demo Mode

If the controller is not running, the mod runs in demo mode with simulated tracks.

## Troubleshooting

### "Spotify not configured"
- Check `.env` has correct `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET`
- Ensure redirect URI matches exactly: `http://localhost:8765/callback`

### "YouTube Music headers file not found"
- Run `python setup_ytmusic.py` and follow instructions
- Ensure `ytmusic_headers.json` exists in controller directory

### Mod can't connect
- Check controller is running (`python zombify_controller.py`)
- Verify WebSocket port 8765 is not blocked by firewall
- Check mod settings: "Controller Host" should be `127.0.0.1`

### Spotify authentication fails
- Clear `tokens/spotify_token.json` and re-authenticate
- Ensure Spotify app has correct scopes

## Development

### Project Structure
```
controller/
├── zombify_controller.py    # Main controller app
├── setup_ytmusic.py         # YouTube Music setup helper
├── requirements.txt         # Python dependencies
├── .env.example            # Environment template
├── .env                    # Your configuration (gitignored)
├── tokens/                 # OAuth tokens (gitignored)
│   ├── spotify_token.json
│   └── ytmusic_token.json
├── ytmusic_headers.json    # YTMusic auth (gitignored)
└── README.md               # This file
```

### Adding New Players

To add a new music player:
1. Create a new controller class (like `SpotifyController`)
2. Implement `is_authenticated()`, `update_status()`, and control methods
3. Add to `ZombifyController` and handle in `update_loop()`
4. Update mod's player selection UI

## License

MIT License - See main repo LICENSE