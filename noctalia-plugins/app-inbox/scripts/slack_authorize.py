#!/usr/bin/env python3

import base64
import hashlib
import json
import secrets
import subprocess
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer


CLIENT_ID = "2281819148.11598464320407"
TEAM_ID = "T0289Q34C"
REDIRECT_URI = "http://localhost:8765/slack/callback"
USER_SCOPES = [
    "channels:read",
    "channels:history",
    "groups:read",
    "groups:history",
    "im:read",
    "im:history",
    "mpim:read",
    "mpim:history",
    "users:read",
]


def store_secret(account, label, value):
    result = subprocess.run(
        ["secret-tool", "store", "--label", label, "service", "slack-agents", "account", account],
        input=value,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "Could not store token in the keyring")


def exchange_code(code, verifier):
    body = urllib.parse.urlencode({
        "client_id": CLIENT_ID,
        "code": code,
        "code_verifier": verifier,
        "redirect_uri": REDIRECT_URI,
    }).encode()
    request = urllib.request.Request("https://slack.com/api/oauth.v2.access", data=body)
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
    if not payload.get("ok"):
        raise RuntimeError(payload.get("error", "Slack token exchange failed"))

    user = payload.get("authed_user", {})
    access_token = user.get("access_token") or payload.get("access_token", "")
    refresh_token = user.get("refresh_token") or payload.get("refresh_token", "")
    if not (access_token.startswith("xoxp-") or access_token.startswith("xoxe.xoxp-")):
        raise RuntimeError("Slack did not return a user access token")

    store_secret("user-token", "Slack User Token", access_token)
    if refresh_token:
        store_secret("user-refresh-token", "Slack User Refresh Token", refresh_token)


def main():
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    state = secrets.token_urlsafe(32)
    result = {"done": False, "error": ""}

    class CallbackHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            query = urllib.parse.parse_qs(parsed.query)
            try:
                if parsed.path != "/slack/callback":
                    raise RuntimeError("Unexpected callback path")
                if query.get("state", [""])[0] != state:
                    raise RuntimeError("OAuth state verification failed")
                if query.get("error"):
                    raise RuntimeError(query["error"][0])
                code = query.get("code", [""])[0]
                if not code:
                    raise RuntimeError("Slack did not return an authorization code")
                exchange_code(code, verifier)
                message = "Slack authorization complete. You can close this tab and refresh App Inbox."
            except Exception as error:
                result["error"] = str(error)
                message = "Slack authorization failed: " + result["error"]
            result["done"] = True
            body = ("<!doctype html><meta charset=utf-8><title>Slack authorization</title>"
                    "<body style='font:18px sans-serif;padding:3rem;background:#181825;color:#cdd6f4'>"
                    + message + "</body>").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, _format, *_args):
            pass

    params = {
        "client_id": CLIENT_ID,
        "team": TEAM_ID,
        "redirect_uri": REDIRECT_URI,
        "user_scope": ",".join(USER_SCOPES),
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    }
    authorize_url = "https://slack.com/oauth/v2/authorize?" + urllib.parse.urlencode(params)
    server = HTTPServer(("127.0.0.1", 8765), CallbackHandler)
    server.timeout = 300
    print("Opening Slack authorization in your browser. Waiting up to five minutes...")
    subprocess.run(["xdg-open", authorize_url], check=False)
    while not result["done"]:
        server.handle_request()
    server.server_close()
    if result["error"]:
        raise SystemExit(result["error"])
    print("Slack user token stored securely in the keyring.")


if __name__ == "__main__":
    main()
