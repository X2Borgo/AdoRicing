#!/usr/bin/env python3

import argparse
import base64
import hashlib
import json
import os
import secrets
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from email.header import decode_header
from email.utils import parseaddr
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


SCOPE = "https://www.googleapis.com/auth/gmail.readonly"
QUERY = "is:unread (is:important OR is:starred) newer_than:30d"


def output(payload):
    print(json.dumps(payload, ensure_ascii=False))


def read_json(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write_secret(path, payload):
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(payload, handle)
    os.chmod(target, 0o600)


def client_config(path):
    payload = read_json(path)
    config = payload.get("installed") or payload.get("web")
    if not config or not config.get("client_id") or not config.get("client_secret"):
        raise ValueError("Invalid Gmail OAuth client file")
    return config


def post_form(url, values):
    request = urllib.request.Request(
        url,
        data=urllib.parse.urlencode(values).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def access_token(client_path, token_path):
    client = client_config(client_path)
    token = read_json(token_path)
    if token.get("access_token") and token.get("expires_at", 0) > time.time() + 60:
        return token["access_token"]
    if not token.get("refresh_token"):
        raise ValueError("Gmail authorization required")
    refreshed = post_form(client.get("token_uri", "https://oauth2.googleapis.com/token"), {
        "client_id": client["client_id"],
        "client_secret": client["client_secret"],
        "refresh_token": token["refresh_token"],
        "grant_type": "refresh_token",
    })
    token.update(refreshed)
    token["expires_at"] = time.time() + refreshed.get("expires_in", 3600)
    write_secret(token_path, token)
    return token["access_token"]


def api_get(path, token, parameters=None):
    url = "https://gmail.googleapis.com/gmail/v1/users/me/" + path
    if parameters:
        url += "?" + urllib.parse.urlencode(parameters, doseq=True)
    request = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def decoded_header(value):
    parts = []
    for text, encoding in decode_header(value or ""):
        if isinstance(text, bytes):
            parts.append(text.decode(encoding or "utf-8", errors="replace"))
        else:
            parts.append(text)
    return "".join(parts)


def fetch(client_path, token_path):
    if not Path(client_path).is_file() or Path(client_path).stat().st_size == 0:
        output({"configured": False, "authenticated": False, "rows": [], "error": ""})
        return
    if not Path(token_path).is_file() or Path(token_path).stat().st_size == 0:
        output({"configured": True, "authenticated": False, "rows": [], "error": "Gmail authorization required"})
        return

    try:
        token = access_token(client_path, token_path)
        listing = api_get("messages", token, {"q": QUERY, "maxResults": 30})
        rows = []
        for reference in listing.get("messages", []):
            message = api_get("messages/" + reference["id"], token, {
                "format": "metadata",
                "metadataHeaders": ["From", "Subject", "Date"],
            })
            headers = {
                item.get("name", "").lower(): decoded_header(item.get("value", ""))
                for item in message.get("payload", {}).get("headers", [])
            }
            sender_name, sender_address = parseaddr(headers.get("from", ""))
            labels = message.get("labelIds", [])
            rows.append({
                "id": message.get("id", ""),
                "threadId": message.get("threadId", ""),
                "sender": sender_name or sender_address or "Unknown sender",
                "senderAddress": sender_address,
                "subject": headers.get("subject") or "No subject",
                "snippet": message.get("snippet", ""),
                "received": int(message.get("internalDate", "0")),
                "important": "IMPORTANT" in labels,
                "starred": "STARRED" in labels,
                "url": "https://mail.google.com/mail/u/0/#inbox/" + message.get("threadId", ""),
            })
        rows.sort(key=lambda row: row["received"], reverse=True)
        output({"configured": True, "authenticated": True, "rows": rows, "error": ""})
    except urllib.error.HTTPError as error:
        try:
            details = json.load(error)
            message = details.get("error", {}).get("message", str(error))
        except (json.JSONDecodeError, AttributeError):
            message = str(error)
        output({"configured": True, "authenticated": False, "rows": [], "error": "Gmail request failed: " + message})
    except (OSError, ValueError, KeyError, json.JSONDecodeError, urllib.error.URLError) as error:
        message = error.reason if isinstance(error, urllib.error.URLError) else str(error)
        output({"configured": True, "authenticated": False, "rows": [], "error": "Gmail request failed: " + str(message)})


def authorize(client_path, token_path):
    client = client_config(client_path)
    state = secrets.token_urlsafe(24)
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    result = {}

    class Callback(BaseHTTPRequestHandler):
        def do_GET(self):
            values = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            result.update({key: value[0] for key, value in values.items()})
            body = b"<html><body><h2>Gmail connected.</h2><p>You can close this window.</p></body></html>"
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, _format, *_args):
            return

    server = HTTPServer(("127.0.0.1", 0), Callback)
    redirect_uri = "http://127.0.0.1:" + str(server.server_port)
    auth_uri = client.get("auth_uri", "https://accounts.google.com/o/oauth2/v2/auth")
    url = auth_uri + "?" + urllib.parse.urlencode({
        "client_id": client["client_id"],
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": SCOPE,
        "access_type": "offline",
        "prompt": "consent",
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    })
    subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("Waiting for Gmail authorization in your browser...", flush=True)
    server.timeout = 180
    server.handle_request()
    server.server_close()
    if result.get("state") != state or not result.get("code"):
        raise RuntimeError(result.get("error", "Gmail authorization timed out"))
    token = post_form(client.get("token_uri", "https://oauth2.googleapis.com/token"), {
        "client_id": client["client_id"],
        "client_secret": client["client_secret"],
        "code": result["code"],
        "code_verifier": verifier,
        "grant_type": "authorization_code",
        "redirect_uri": redirect_uri,
    })
    token["expires_at"] = time.time() + token.get("expires_in", 3600)
    write_secret(token_path, token)
    print("Gmail authorization saved.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("client_path")
    parser.add_argument("token_path")
    parser.add_argument("--authorize", action="store_true")
    arguments = parser.parse_args()
    if arguments.authorize:
        authorize(arguments.client_path, arguments.token_path)
    else:
        fetch(arguments.client_path, arguments.token_path)


if __name__ == "__main__":
    main()
