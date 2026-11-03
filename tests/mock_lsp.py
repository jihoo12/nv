"""Minimal stdio LSP peer for testing NV's real client attachment."""
import json
import sys


def send(payload):
    body = json.dumps(payload).encode()
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
    sys.stdout.buffer.flush()


while True:
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            sys.exit(0)
        if line == b"\r\n":
            break
        key, value = line.decode().split(":", 1)
        headers[key.lower()] = value.strip()
    message = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
    method = message.get("method")
    if method == "exit":
        break
    if "id" not in message:
        continue
    result = None
    if method == "initialize":
        result = {"capabilities": {"textDocumentSync": 1, "hoverProvider": True,
                                   "definitionProvider": True}}
    elif method == "textDocument/hover":
        result = {"contents": {"kind": "plaintext", "value": "NV test server"}}
    send({"jsonrpc": "2.0", "id": message["id"], "result": result})
