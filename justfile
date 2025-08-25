test:
   cat ./messages.ndjson | websocat --text ws://localhost:4000/socket/websocket?vsn=2.0.0
