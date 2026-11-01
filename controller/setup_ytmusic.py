#!/usr/bin/env python3
"""
YouTube Music Setup Script
Helps generate the headers file needed for ytmusicapi authentication.

Run this script and follow the instructions to authenticate with YouTube Music.
"""

import json
import sys
from pathlib import Path

def setup_ytmusic():
    """Interactive setup for YouTube Music"""
    print("=" * 60)
    print("YouTube Music Setup for Zombify Controller")
    print("=" * 60)
    print()
    print("This script will help you create the authentication headers file")
    print("needed for ytmusicapi to access your YouTube Music account.")
    print()
    print("Steps:")
    print("1. Open your browser and go to https://music.youtube.com")
    print("2. Log in to your YouTube Music account")
    print("3. Open Developer Tools (F12)")
    print("4. Go to the Network tab")
    print("5. Refresh the page")
    print("6. Find a request to 'browse' or 'next' in the filter")
    print("7. Right-click the request -> Copy -> Copy as cURL")
    print("8. Paste the cURL command below")
    print()
    print("Alternatively, you can manually copy these headers:")
    print("  - cookie")
    print("  - x-goog-authuser")
    print("  - x-goog-visitor-id")
    print("  - x-origin")
    print()

    curl_command = input("Paste cURL command (or press Enter to skip): ").strip()

    if not curl_command:
        print("\nSkipping automated setup. You can manually create the headers file.")
        print(f"Create a file at: {Path(__file__).parent / 'ytmusic_headers.json'}")
        print("With this format:")
        print(json.dumps({
            "cookie": "YOUR_COOKIE_HERE",
            "x-goog-authuser": "0",
            "x-goog-visitor-id": "YOUR_VISITOR_ID",
            "x-origin": "https://music.youtube.com"
        }, indent=2))
        return

    # Parse cURL command to extract headers
    headers = parse_curl(curl_command)

    if not headers:
        print("Failed to parse cURL command. Please try manual setup.")
        return

    # Save headers
    output_file = Path(__file__).parent / "ytmusic_headers.json"
    with open(output_file, "w") as f:
        json.dump(headers, f, indent=2)

    print(f"\nHeaders saved to: {output_file}")
    print("You can now run the Zombify controller!")

def parse_curl(curl: str) -> dict:
    """Parse cURL command to extract headers"""
    headers = {}

    # Remove 'curl' and URL
    parts = curl.split(" -H ")
    if len(parts) < 2:
        return {}

    for part in parts[1:]:
        # Extract header name and value
        header_part = part.split("'")[0].strip()
        if ": " in header_part:
            name, value = header_part.split(": ", 1)
            headers[name.strip()] = value.strip()

    # Filter to required headers
    required = ["cookie", "x-goog-authuser", "x-goog-visitor-id", "x-origin"]
    filtered = {k: v for k, v in headers.items() if k.lower() in required}

    return filtered

if __name__ == "__main__":
    setup_ytmusic()