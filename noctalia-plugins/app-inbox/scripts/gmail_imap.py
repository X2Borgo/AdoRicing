#!/usr/bin/env python3

import email
import html
import imaplib
import json
import re
import ssl
import sys
from datetime import timezone
from email.header import decode_header
from email.utils import parseaddr, parsedate_to_datetime
from pathlib import Path
from urllib.parse import quote


def output(payload):
    print(json.dumps(payload, ensure_ascii=False))


def secret(path, remove_spaces=False):
    value = Path(path).read_text(encoding="utf-8").strip()
    return "".join(value.split()) if remove_spaces else value


def decoded_header(value):
    parts = []
    for text, encoding in decode_header(value or ""):
        if isinstance(text, bytes):
            parts.append(text.decode(encoding or "utf-8", errors="replace"))
        else:
            parts.append(text)
    return "".join(parts)


def message_text(message):
    candidates = []
    parts = message.walk() if message.is_multipart() else [message]
    for part in parts:
        if part.get_content_maintype() == "multipart" or part.get_filename():
            continue
        content_type = part.get_content_type()
        if content_type not in ("text/plain", "text/html"):
            continue
        payload = part.get_payload(decode=True) or b""
        text = payload.decode(part.get_content_charset() or "utf-8", errors="replace")
        if content_type == "text/html":
            text = re.sub(r"<[^>]+>", " ", html.unescape(text))
        text = re.sub(r"\s+", " ", text).strip()
        if text:
            candidates.append((content_type != "text/plain", text))
    if not candidates:
        return ""
    candidates.sort(key=lambda item: item[0])
    return candidates[0][1][:500]


def fetch(address_path, password_path):
    if not Path(address_path).is_file() or not Path(password_path).is_file():
        output({"configured": False, "authenticated": False, "rows": [], "error": ""})
        return
    address = secret(address_path)
    password = secret(password_path, remove_spaces=True)
    if not address or not password:
        output({"configured": False, "authenticated": False, "rows": [], "error": ""})
        return

    mailbox = None
    try:
        mailbox = imaplib.IMAP4_SSL("imap.gmail.com", 993, ssl_context=ssl.create_default_context(), timeout=20)
        mailbox.login(address, password)
        mailbox.select("INBOX", readonly=True)
        status, data = mailbox.uid("search", None, "ALL")
        if status != "OK":
            raise RuntimeError("Gmail search failed")

        uids = (data[0] or b"").split()[-50:]
        rows = []
        for uid in reversed(uids):
            status, parts = mailbox.uid("fetch", uid, "(BODY.PEEK[]<0.8192> X-GM-LABELS FLAGS)")
            if status != "OK":
                continue
            raw_message = next((part[1] for part in parts if isinstance(part, tuple) and isinstance(part[1], bytes)), b"")
            metadata = b" ".join(part[0] for part in parts if isinstance(part, tuple) and isinstance(part[0], bytes))
            if not raw_message:
                continue
            message = email.message_from_bytes(raw_message)
            sender_name, sender_address = parseaddr(decoded_header(message.get("From", "")))
            try:
                received = int(parsedate_to_datetime(message.get("Date")).astimezone(timezone.utc).timestamp() * 1000)
            except (TypeError, ValueError, OverflowError):
                received = 0
            labels = metadata.decode(errors="replace").lower()
            message_id = (message.get("Message-ID") or "").strip()
            url = "https://mail.google.com/mail/u/0/#inbox"
            if message_id:
                url = "https://mail.google.com/mail/u/0/#search/" + quote("rfc822msgid:" + message_id, safe="")
            rows.append({
                "id": uid.decode(),
                "sender": sender_name or sender_address or "Unknown sender",
                "senderAddress": sender_address,
                "subject": decoded_header(message.get("Subject", "")) or "No subject",
                "snippet": message_text(message),
                "received": received,
                "unread": "\\seen" not in labels,
                "important": "\\important" in labels,
                "starred": "\\starred" in labels,
                "url": url,
            })
        rows.sort(key=lambda row: row["received"], reverse=True)
        output({"configured": True, "authenticated": True, "rows": rows, "error": ""})
    except imaplib.IMAP4.error as error:
        message = error.args[0].decode(errors="replace") if error.args and isinstance(error.args[0], bytes) else str(error)
        output({"configured": True, "authenticated": False, "rows": [], "error": "Gmail IMAP login failed: " + message})
    except (OSError, RuntimeError, ssl.SSLError) as error:
        output({"configured": True, "authenticated": False, "rows": [], "error": "Gmail IMAP request failed: " + str(error)})
    finally:
        if mailbox is not None:
            try:
                mailbox.logout()
            except (imaplib.IMAP4.error, OSError):
                pass


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: gmail_imap.py ADDRESS_FILE APP_PASSWORD_FILE")
    fetch(sys.argv[1], sys.argv[2])


if __name__ == "__main__":
    main()
