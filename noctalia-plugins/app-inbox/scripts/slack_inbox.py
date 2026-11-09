#!/usr/bin/env python3

import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from time import time


CLIENT_ID = "2281819148.11598464320407"


def output(payload):
    print(json.dumps(payload, ensure_ascii=False))


def keyring_token():
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "service", "slack-agents", "account", "user-token"],
            capture_output=True,
            text=True,
            timeout=8,
            check=False,
        )
    except FileNotFoundError:
        return "", "", "secret-tool is not installed"
    except subprocess.TimeoutExpired:
        return "", "", "Keyring lookup timed out"
    token = result.stdout.strip()
    if token:
        if token.startswith("xoxp-") or token.startswith("xoxe.xoxp-"):
            return token, "user", ""
        if not token.startswith("xoxb-"):
            return "", "", "Expected a Slack user token starting with xoxp-"

    result = subprocess.run(
        ["secret-tool", "lookup", "service", "slack-agents", "account", "bot-token"],
        capture_output=True,
        text=True,
        timeout=8,
        check=False,
    )
    token = result.stdout.strip()
    if not token:
        return "", "", "Slack user or bot token not found in keyring"
    if not token.startswith("xoxb-"):
        return "", "", "Expected a Slack bot token starting with xoxb-"
    return token, "bot", ""


def keyring_secret(account):
    result = subprocess.run(
        ["secret-tool", "lookup", "service", "slack-agents", "account", account],
        capture_output=True,
        text=True,
        timeout=8,
        check=False,
    )
    return result.stdout.strip()


def store_secret(account, label, value):
    result = subprocess.run(
        ["secret-tool", "store", "--label", label, "service", "slack-agents", "account", account],
        input=value,
        text=True,
        capture_output=True,
        timeout=8,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "Could not update Slack token in keyring")


def refresh_user_token():
    refresh_token = keyring_secret("user-refresh-token")
    if not refresh_token:
        raise RuntimeError("Slack user token expired; authorize the widget again")
    body = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": CLIENT_ID,
    }).encode()
    request = urllib.request.Request("https://slack.com/api/oauth.v2.access", data=body)
    with urllib.request.urlopen(request, timeout=15) as response:
        payload = json.load(response)
    if not payload.get("ok"):
        raise RuntimeError(payload.get("error", "Slack token refresh failed"))
    access_token = payload.get("access_token", "")
    next_refresh_token = payload.get("refresh_token", "")
    if not access_token:
        raise RuntimeError("Slack token refresh returned no access token")
    store_secret("user-token", "Slack User Token", access_token)
    if next_refresh_token:
        store_secret("user-refresh-token", "Slack User Refresh Token", next_refresh_token)
    return access_token


def slack_get(method, token, parameters=None):
    url = "https://slack.com/api/" + method
    if parameters:
        url += "?" + urllib.parse.urlencode(parameters)
    request = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
    with urllib.request.urlopen(request, timeout=15) as response:
        payload = json.load(response)
    if not payload.get("ok"):
        raise RuntimeError(payload.get("error", method + " failed"))
    return payload


def conversations(token):
    rows = []
    cursor = ""
    while True:
        payload = slack_get("users.conversations", token, {
            "types": "public_channel,private_channel,im,mpim",
            "exclude_archived": "true",
            "limit": 200,
            "cursor": cursor,
        })
        rows.extend(payload.get("channels", []))
        cursor = payload.get("response_metadata", {}).get("next_cursor", "")
        if not cursor or len(rows) >= 400:
            return rows


def conversation_info(channel, token):
    try:
        return slack_get("conversations.info", token, {"channel": channel["id"]}).get("channel", channel)
    except (KeyError, RuntimeError, urllib.error.URLError):
        return channel


def user_name(user_id, token, cache):
    if not user_id:
        return "Unknown user"
    if user_id in cache:
        return cache[user_id]
    try:
        user = slack_get("users.info", token, {"user": user_id}).get("user", {})
        profile = user.get("profile", {})
        name = profile.get("display_name") or profile.get("real_name") or user.get("real_name") or user.get("name") or user_id
    except (RuntimeError, urllib.error.URLError):
        name = user_id
    cache[user_id] = name
    return name


def clean_text(text):
    return " ".join((text or "").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&").split())


def fetch():
    token, token_mode, token_error = keyring_token()
    if token_error:
        output({"configured": False, "authenticated": False, "rows": [], "total": 0, "error": token_error})
        return

    try:
        try:
            auth = slack_get("auth.test", token)
        except RuntimeError as error:
            if token_mode != "user" or str(error) != "token_expired":
                raise
            token = refresh_user_token()
            auth = slack_get("auth.test", token)
        channels = conversations(token)
        with ThreadPoolExecutor(max_workers=8) as executor:
            futures = [executor.submit(conversation_info, channel, token) for channel in channels]
            detailed = [future.result() for future in as_completed(futures)]

        visible_channels = detailed
        user_cache = {}
        rows = []
        recent_cutoff = str(time() - 7 * 86400)
        for channel in visible_channels[:80]:
            channel_id = channel.get("id", "")
            is_dm = channel.get("is_im") is True
            is_group_dm = channel.get("is_mpim") is True
            if is_dm:
                name = user_name(channel.get("user", ""), token, user_cache)
                kind = "Direct message"
            elif is_group_dm:
                name = channel.get("name") or "Group message"
                kind = "Group message"
            else:
                name = channel.get("name") or channel_id
                kind = "Private channel" if channel.get("is_private") else "Channel"

            latest_read = channel.get("latest_read", "0") or "0"
            oldest = recent_cutoff
            messages = []
            try:
                history = slack_get("conversations.history", token, {
                    "channel": channel_id,
                    "oldest": oldest,
                    "inclusive": "false",
                    "limit": 10,
                })
                for message in reversed(history.get("messages", [])):
                    sender = user_name(message.get("user", ""), token, user_cache) if message.get("user") else message.get("username", "Slack")
                    text = clean_text(message.get("text", ""))
                    if text:
                        messages.append({"sender": sender, "text": text, "timestamp": message.get("ts", "0")})
            except (RuntimeError, urllib.error.URLError):
                pass

            if not messages:
                continue

            rows.append({
                "id": channel_id,
                "name": name,
                "kind": kind,
                "isDm": is_dm or is_group_dm,
                "unread": int(channel.get("unread_count", 0) or 0),
                "activity": len(messages),
                "messages": messages,
                "latest": messages[-1]["timestamp"] if messages else channel.get("latest", {}).get("ts", "0"),
                "url": "slack://channel?" + urllib.parse.urlencode({
                    "team": auth.get("team_id", ""),
                    "id": channel_id,
                }),
            })
        rows.sort(key=lambda row: (row["latest"], row["unread"]), reverse=True)
        output({
            "configured": True,
            "authenticated": True,
            "workspace": auth.get("team", ""),
            "user": auth.get("user", ""),
            "mode": token_mode,
            "rows": rows,
            "total": len(rows),
            "error": "",
        })
    except urllib.error.HTTPError as error:
        output({"configured": True, "authenticated": False, "rows": [], "total": 0, "error": "Slack request failed: HTTP " + str(error.code)})
    except (urllib.error.URLError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        output({"configured": True, "authenticated": False, "rows": [], "total": 0, "error": "Slack request failed: " + str(error)})


if __name__ == "__main__":
    if len(sys.argv) != 1:
        raise SystemExit("usage: slack_inbox.py")
    fetch()
