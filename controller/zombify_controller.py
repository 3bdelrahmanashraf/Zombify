#!/usr/bin/env python3
"""
Zombify Controller App
External controller for Spotify and YouTube Music integration with Project Zomboid Zombify mod.

This app:
1. Handles OAuth authentication for Spotify and YouTube Music
2. Runs a WebSocket server for the Zombify mod to connect to
3. Polls music player state and pushes updates to connected clients
4. Accepts playback commands from the mod
"""

import asyncio
import json
import logging
import os
import sys
import threading
import time
import base64
import io
from pathlib import Path
from typing import Optional, Dict, Any, Set
from dataclasses import dataclass, asdict
from datetime import datetime

import spotipy
from spotipy.oauth2 import SpotifyOAuth
from ytmusicapi import YTMusic
import websockets
from websockets.server import WebSocketServerProtocol
from aiohttp import web
from PIL import Image
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("ZombifyController")

# Configuration
SPOTIFY_CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID", "")
SPOTIFY_CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET", "")
SPOTIFY_REDIRECT_URI = os.getenv("SPOTIFY_REDIRECT_URI", "http://localhost:8765/callback")

YTMUSIC_HEADERS_FILE = os.getenv("YTMUSIC_HEADERS_FILE", "ytmusic_headers.json")

WS_HOST = os.getenv("WS_HOST", "127.0.0.1")
WS_PORT = int(os.getenv("WS_PORT", "8765"))
HTTP_PORT = int(os.getenv("HTTP_PORT", "8766"))

TOKEN_DIR = Path(__file__).parent / "tokens"
TOKEN_DIR.mkdir(exist_ok=True)

SPOTIFY_TOKEN_FILE = TOKEN_DIR / "spotify_token.json"
YTMUSIC_TOKEN_FILE = TOKEN_DIR / "ytmusic_token.json"


@dataclass
class TrackInfo:
    """Current track information"""
    track: str = ""
    artist: str = ""
    album: str = ""
    duration: int = 0  # milliseconds
    progress: int = 0  # milliseconds
    is_playing: bool = False
    volume: float = 1.0
    album_art: Optional[str] = None  # base64 encoded
    player_type: str = "none"
    timestamp: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class SpotifyController:
    """Handles Spotify playback control and status"""

    def __init__(self):
        self.sp: Optional[spotipy.Spotify] = None
        self.auth_manager: Optional[SpotifyOAuth] = None
        self.current_track: Optional[TrackInfo] = None
        self._initialize()

    def _initialize(self):
        if not SPOTIFY_CLIENT_ID or not SPOTIFY_CLIENT_SECRET:
            logger.warning("Spotify credentials not configured")
            return

        self.auth_manager = SpotifyOAuth(
            client_id=SPOTIFY_CLIENT_ID,
            client_secret=SPOTIFY_CLIENT_SECRET,
            redirect_uri=SPOTIFY_REDIRECT_URI,
            scope="user-read-playback-state user-modify-playback-state user-read-currently-playing",
            cache_path=str(SPOTIFY_TOKEN_FILE),
            open_browser=False
        )

        try:
            self.sp = spotipy.Spotify(auth_manager=self.auth_manager)
            # Test connection
            self.sp.current_user()
            logger.info("Spotify controller initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Spotify: {e}")
            self.sp = None

    def is_authenticated(self) -> bool:
        return self.sp is not None and self.auth_manager is not None

    def get_auth_url(self) -> str:
        if self.auth_manager:
            return self.auth_manager.get_authorize_url()
        return ""

    def handle_callback(self, code: str) -> bool:
        if self.auth_manager:
            try:
                self.auth_manager.get_access_token(code)
                self.sp = spotipy.Spotify(auth_manager=self.auth_manager)
                logger.info("Spotify authentication successful")
                return True
            except Exception as e:
                logger.error(f"Spotify callback error: {e}")
        return False

    async def update_status(self) -> Optional[TrackInfo]:
        if not self.sp:
            return None

        try:
            playback = self.sp.current_playback()
            if not playback:
                return None

            track = playback.get("item")
            if not track:
                return None

            album_art_url = None
            if track.get("album", {}).get("images"):
                album_art_url = track["album"]["images"][0]["url"]

            # Download and encode album art
            album_art_b64 = None
            if album_art_url:
                album_art_b64 = await self._download_image_base64(album_art_url)

            self.current_track = TrackInfo(
                track=track.get("name", ""),
                artist=", ".join([a["name"] for a in track.get("artists", [])]),
                album=track.get("album", {}).get("name", ""),
                duration=track.get("duration_ms", 0),
                progress=playback.get("progress_ms", 0),
                is_playing=playback.get("is_playing", False),
                volume=playback.get("device", {}).get("volume_percent", 100) / 100.0,
                album_art=album_art_b64,
                player_type="spotify",
                timestamp=int(time.time() * 1000)
            )
            return self.current_track

        except Exception as e:
            logger.error(f"Error updating Spotify status: {e}")
            return None

    async def _download_image_base64(self, url: str) -> Optional[str]:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                img = Image.open(io.BytesIO(response.content))
                # Resize to max 300x300
                img.thumbnail((300, 300), Image.Resampling.LANCZOS)
                buffer = io.BytesIO()
                img.save(buffer, format="PNG")
                return base64.b64encode(buffer.getvalue()).decode("utf-8")
        except Exception as e:
            logger.error(f"Failed to download album art: {e}")
        return None

    async def play_pause(self):
        if not self.sp:
            return
        try:
            playback = self.sp.current_playback()
            if playback and playback.get("is_playing"):
                self.sp.pause_playback()
            else:
                self.sp.start_playback()
        except Exception as e:
            logger.error(f"Spotify play/pause error: {e}")

    async def next_track(self):
        if self.sp:
            try:
                self.sp.next_track()
            except Exception as e:
                logger.error(f"Spotify next error: {e}")

    async def previous_track(self):
        if self.sp:
            try:
                self.sp.previous_track()
            except Exception as e:
                logger.error(f"Spotify previous error: {e}")

    async def set_volume(self, volume: float):
        if self.sp:
            try:
                vol_percent = int(max(0, min(100, volume * 100)))
                self.sp.volume(vol_percent)
            except Exception as e:
                logger.error(f"Spotify volume error: {e}")


class YouTubeMusicController:
    """Handles YouTube Music playback control and status"""

    def __init__(self):
        self.ytm: Optional[YTMusic] = None
        self.current_track: Optional[TrackInfo] = None
        self._initialize()

    def _initialize(self):
        try:
            if YTMUSIC_TOKEN_FILE.exists():
                self.ytm = YTMusic(str(YTMUSIC_TOKEN_FILE))
                logger.info("YouTube Music controller initialized")
            else:
                logger.warning("YouTube Music headers file not found. Run setup_ytmusic.py first")
        except Exception as e:
            logger.error(f"Failed to initialize YouTube Music: {e}")

    def is_authenticated(self) -> bool:
        return self.ytm is not None

    async def update_status(self) -> Optional[TrackInfo]:
        if not self.ytm:
            return None

        try:
            # YTMusic doesn't have direct playback state API
            # We'll use the history/recently played as fallback
            history = self.ytm.get_history()
            if not history:
                return None

            latest = history[0]
            track_id = latest.get("videoId")
            if not track_id:
                return None

            # Get track details
            track_info = self.ytm.get_song(track_id)
            if not track_info:
                return None

            album_art_b64 = None
            if track_info.get("thumbnail"):
                album_art_b64 = await self._download_image_base64(track_info["thumbnail"][-1]["url"])

            self.current_track = TrackInfo(
                track=track_info.get("title", ""),
                artist=track_info.get("artist", ""),
                album=track_info.get("album", {}).get("name", "") if track_info.get("album") else "",
                duration=track_info.get("duration_seconds", 0) * 1000,
                progress=0,  # YTMusic doesn't provide progress
                is_playing=True,  # Assume playing if in history
                volume=1.0,
                album_art=album_art_b64,
                player_type="youtubemusic",
                timestamp=int(time.time() * 1000)
            )
            return self.current_track

        except Exception as e:
            logger.error(f"Error updating YouTube Music status: {e}")
            return None

    async def _download_image_base64(self, url: str) -> Optional[str]:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                img = Image.open(io.BytesIO(response.content))
                img.thumbnail((300, 300), Image.Resampling.LANCZOS)
                buffer = io.BytesIO()
                img.save(buffer, format="PNG")
                return base64.b64encode(buffer.getvalue()).decode("utf-8")
        except Exception as e:
            logger.error(f"Failed to download album art: {e}")
        return None

    async def play_pause(self):
        # YTMusic doesn't have direct playback control via API
        logger.warning("YouTube Music play/pause not supported via API")

    async def next_track(self):
        logger.warning("YouTube Music next track not supported via API")

    async def previous_track(self):
        logger.warning("YouTube Music previous track not supported via API")

    async def set_volume(self, volume: float):
        logger.warning("YouTube Music volume not supported via API")


class ZombifyController:
    """Main controller managing music players and WebSocket connections"""

    def __init__(self):
        self.spotify = SpotifyController()
        self.ytmusic = YouTubeMusicController()
        self.clients: Set[WebSocketServerProtocol] = set()
        self.current_player: str = "none"
        self.current_track: Optional[TrackInfo] = None
        self.running = False
        self.update_interval = 2.0  # seconds

    def set_player(self, player_type: str):
        """Set active music player"""
        self.current_player = player_type.lower()
        logger.info(f"Active player set to: {self.current_player}")

    async def register_client(self, websocket: WebSocketServerProtocol):
        """Register a new WebSocket client"""
        self.clients.add(websocket)
        logger.info(f"Client connected. Total clients: {len(self.clients)}")

        # Send current status immediately
        if self.current_track:
            await self._send_to_client(websocket, {
                "type": "status",
                "data": self.current_track.to_dict()
            })

    async def unregister_client(self, websocket: WebSocketServerProtocol):
        """Unregister a WebSocket client"""
        self.clients.discard(websocket)
        logger.info(f"Client disconnected. Total clients: {len(self.clients)}")

    async def _send_to_client(self, websocket: WebSocketServerProtocol, message: Dict[str, Any]):
        """Send message to a specific client"""
        try:
            await websocket.send(json.dumps(message))
        except Exception as e:
            logger.error(f"Error sending to client: {e}")

    async def broadcast(self, message: Dict[str, Any]):
        """Broadcast message to all connected clients"""
        if not self.clients:
            return

        message_str = json.dumps(message)
        disconnected = set()

        for client in self.clients:
            try:
                await client.send(message_str)
            except Exception:
                disconnected.add(client)

        for client in disconnected:
            self.clients.discard(client)

    async def handle_message(self, websocket: WebSocketServerProtocol, message: str):
        """Handle incoming message from client"""
        try:
            data = json.loads(message)
            cmd = data.get("command")
            params = data.get("params", {})

            if cmd == "play_pause":
                await self.play_pause()
            elif cmd == "next":
                await self.next_track()
            elif cmd == "previous":
                await self.previous_track()
            elif cmd == "volume":
                await self.set_volume(params.get("volume", 1.0))
            elif cmd == "get_status":
                await self._send_to_client(websocket, {
                    "type": "status",
                    "data": self.current_track.to_dict() if self.current_track else None
                })
            elif cmd == "set_player":
                self.set_player(params.get("player_type", "none"))

        except Exception as e:
            logger.error(f"Error handling message: {e}")

    async def play_pause(self):
        if self.current_player == "spotify":
            await self.spotify.play_pause()
        elif self.current_player == "youtubemusic":
            await self.ytmusic.play_pause()

    async def next_track(self):
        if self.current_player == "spotify":
            await self.spotify.next_track()
        elif self.current_player == "youtubemusic":
            await self.ytmusic.next_track()

    async def previous_track(self):
        if self.current_player == "spotify":
            await self.spotify.previous_track()
        elif self.current_player == "youtubemusic":
            await self.ytmusic.previous_track()

    async def set_volume(self, volume: float):
        if self.current_player == "spotify":
            await self.spotify.set_volume(volume)
        elif self.current_player == "youtubemusic":
            await self.ytmusic.set_volume(volume)

    async def update_loop(self):
        """Main update loop - polls player status and broadcasts"""
        while self.running:
            try:
                new_track = None

                if self.current_player == "spotify" and self.spotify.is_authenticated():
                    new_track = await self.spotify.update_status()
                elif self.current_player == "youtubemusic" and self.ytmusic.is_authenticated():
                    new_track = await self.ytmusic.update_status()

                if new_track:
                    # Check if track changed
                    if (not self.current_track or
                        new_track.track != self.current_track.track or
                        new_track.artist != self.current_track.artist):
                        logger.info(f"Track changed: {new_track.track} - {new_track.artist}")

                    self.current_track = new_track
                    await self.broadcast({
                        "type": "status",
                        "data": new_track.to_dict()
                    })

            except Exception as e:
                logger.error(f"Error in update loop: {e}")

            await asyncio.sleep(self.update_interval)

    async def websocket_handler(self, websocket: WebSocketServerProtocol):
        """Handle WebSocket connection"""
        await self.register_client(websocket)
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except websockets.exceptions.ConnectionClosed:
            pass
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
        finally:
            await self.unregister_client(websocket)


# HTTP Server for OAuth callbacks
class HTTPServer:
    def __init__(self, controller: ZombifyController):
        self.controller = controller
        self.app = web.Application()
        self.app.router.add_get("/callback", self.spotify_callback)
        self.app.router.add_get("/auth/spotify", self.spotify_auth)
        self.app.router.add_get("/auth/ytmusic", self.ytmusic_auth)
        self.app.router.add_get("/status", self.status)
        self.runner: Optional[web.AppRunner] = None

    async def spotify_auth(self, request):
        """Redirect to Spotify OAuth"""
        if self.controller.spotify.auth_manager:
            auth_url = self.controller.spotify.get_auth_url()
            raise web.HTTPFound(auth_url)
        return web.Response(text="Spotify not configured", status=500)

    async def spotify_callback(self, request):
        """Handle Spotify OAuth callback"""
        code = request.query.get("code")
        if code and self.controller.spotify.handle_callback(code):
            return web.Response(text="Spotify authentication successful! You can close this window.")
        return web.Response(text="Authentication failed", status=400)

    async def ytmusic_auth(self, request):
        """YouTube Music auth info"""
        return web.Response(text="""
        <html><body>
        <h1>YouTube Music Setup</h1>
        <p>To set up YouTube Music:</p>
        <ol>
            <li>Install <code>ytmusicapi</code>: <code>pip install ytmusicapi</code></li>
            <li>Run: <code>python -c "from ytmusicapi import YTMusic; YTMusic.setup('ytmusic_headers.json')"</code></li>
            <li>Follow the browser instructions to copy request headers</li>
            <li>Restart this controller</li>
        </ol>
        </body></html>
        """, content_type="text/html")

    async def status(self, request):
        """Status endpoint"""
        return web.json_response({
            "running": self.controller.running,
            "current_player": self.controller.current_player,
            "spotify_authenticated": self.controller.spotify.is_authenticated(),
            "ytmusic_authenticated": self.controller.ytmusic.is_authenticated(),
            "connected_clients": len(self.controller.clients),
            "current_track": self.controller.current_track.to_dict() if self.controller.current_track else None
        })

    async def start(self):
        self.runner = web.AppRunner(self.app)
        await self.runner.setup()
        site = web.TCPSite(self.runner, WS_HOST, HTTP_PORT)
        await site.start()
        logger.info(f"HTTP server started on http://{WS_HOST}:{HTTP_PORT}")

    async def stop(self):
        if self.runner:
            await self.runner.cleanup()


async def main():
    """Main entry point"""
    logger.info("Starting Zombify Controller...")

    controller = ZombifyController()
    http_server = HTTPServer(controller)

    # Start HTTP server
    await http_server.start()

    # Start WebSocket server
    ws_server = await websockets.serve(
        controller.websocket_handler,
        WS_HOST,
        WS_PORT,
        ping_interval=20,
        ping_timeout=10
    )
    logger.info(f"WebSocket server started on ws://{WS_HOST}:{WS_PORT}")

    controller.running = True

    # Start update loop
    update_task = asyncio.create_task(controller.update_loop())

    logger.info("Zombify Controller running. Press Ctrl+C to stop.")
    logger.info(f"Spotify auth: http://{WS_HOST}:{HTTP_PORT}/auth/spotify")
    logger.info(f"YTMusic setup: http://{WS_HOST}:{HTTP_PORT}/auth/ytmusic")
    logger.info(f"Status: http://{WS_HOST}:{HTTP_PORT}/status")

    try:
        # Keep running
        await asyncio.Future()  # Run forever
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        controller.running = False
        update_task.cancel()
        ws_server.close()
        await ws_server.wait_closed()
        await http_server.stop()
        logger.info("Zombify Controller stopped")


if __name__ == "__main__":
    asyncio.run(main())