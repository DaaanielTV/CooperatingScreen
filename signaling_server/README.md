# CooperatingScreen Signaling Server

WebSocket signaling server for WebRTC P2P connections and device pairing.

## Prerequisites

- Node.js 18 LTS or higher
- npm or yarn
- Docker (optional, for containerized deployment)

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the server:**
   ```bash
   npm start           # Production
   npm run dev        # Development (with nodemon)
   ```

The server will listen on `ws://localhost:3000` by default.

## API Endpoints

### WebSocket Messages

#### Device Registration
```json
{
  "type": "device_registration",
  "data": {
    "device_serial": "ABC1234567"
  }
}
```

#### Pairing Request
```json
{
  "type": "pairing_request",
  "data": {
    "target_device": "XYZ9876543",
    "password_hash": "hash_of_password"
  }
}
```

#### WebRTC Offer
```json
{
  "type": "offer",
  "data": {
    "target_device": "XYZ9876543",
    "sdp": { /* SDP object */ }
  }
}
```

#### WebRTC Answer
```json
{
  "type": "answer",
  "data": {
    "target_device": "ABC1234567",
    "sdp": { /* SDP object */ }
  }
}
```

#### ICE Candidate
```json
{
  "type": "ice_candidate",
  "data": {
    "target_device": "XYZ9876543",
    "candidate": { /* ICE candidate */ }
  }
}
```

### HTTP Endpoints

- `GET /health` - Health check
- `GET /stats` - Server statistics

## Docker Deployment

```bash
# Build image
docker build -t cosc-signaling-server .

# Run container
docker run -p 3000:3000 cosc-signaling-server
```

Or use docker-compose:
```bash
docker-compose up signaling-server
```

## Features

- ✅ Device registration and lookup
- ✅ Pairing request relaying
- ✅ WebRTC SDP/ICE exchange
- ✅ Connection state tracking
- ✅ Health check and monitoring
- ✅ Automatic cleanup of disconnected clients

## Development

```bash
# Watch mode with nodemon
npm run dev

# Check logs
tail -f logs/signaling-server.log
```

## Monitoring

The server provides statistics at:
```
GET http://localhost:3000/stats
```

Example response:
```json
{
  "connected_clients": 2,
  "active_sessions": 1,
  "uptime": 3600,
  "timestamp": "2026-01-15T10:30:00.000Z"
}
```

## Deployment

See [../Readme.md](../Readme.md) for production deployment instructions.
