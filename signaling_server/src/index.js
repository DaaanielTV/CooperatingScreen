import express from 'express';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import cors from 'cors';
import { v4 as uuidv4 } from 'uuid';
import pino from 'pino';
import dotenv from 'dotenv';
import RateLimiter from './rate_limiter.js';

dotenv.config();

const logger = pino();
const app = express();
const port = process.env.PORT || 3000;

// Rate limiting configuration
const httpLimiter = new RateLimiter({
  windowMs: 60000, // 1 minute
  maxRequests: 100,
});

const wsLimiter = new RateLimiter({
  windowMs: 60000,
  maxRequests: 30, // More strict for WebSocket connections
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(RateLimiter.middleware(httpLimiter));

// Create HTTP server
const server = createServer(app);

// Create WebSocket server with perMessageDeflate disabled for better performance
const wss = new WebSocketServer({
  server,
  perMessageDeflate: false,
  clientTracking: true,
});

// Store active connections
const clients = new Map(); // Map<deviceSerial, WebSocket>
const sessionMap = new Map(); // Map<sessionId, { device1, device2 }>

// WebSocket connection handler
wss.on('connection', (ws, req) => {
  const connectionId = uuidv4();
  const clientIp = req.socket.remoteAddress || 'unknown';
  
  logger.info(`New connection: ${connectionId} from ${clientIp}`);

  let deviceSerial = null;

  ws.on('message', async (message) => {
    try {
      // Rate limit WebSocket messages per device
      if (deviceSerial && !wsLimiter.isAllowed(deviceSerial)) {
        logger.warn(`Rate limit exceeded for device: ${deviceSerial}`);
        ws.send(JSON.stringify({
          type: 'error',
          data: {
            error: 'Too many messages',
            retryAfter: wsLimiter.getResetTime(deviceSerial),
          },
        }));
        return;
      }

      const parsedMessage = JSON.parse(message);
      await handleSignalingMessage(ws, parsedMessage, (serial) => {
        deviceSerial = serial;
      });
    } catch (error) {
      logger.error(`Error parsing message: ${error.message}`);
      ws.send(JSON.stringify({
        type: 'error',
        data: { error: 'Invalid message format' },
      }));
    }
  });

  ws.on('close', () => {
    if (deviceSerial) {
      clients.delete(deviceSerial);
      logger.info(`Device ${deviceSerial} disconnected`);
    }
  });

  ws.on('error', (error) => {
    logger.error(`WebSocket error: ${error.message}`);
  });
});

/**
 * Handle signaling messages from clients
 */
async function handleSignalingMessage(ws, message, setDeviceSerial) {
  const { type, data, timestamp } = message;

  switch (type) {
    case 'device_registration':
      handleDeviceRegistration(ws, data, setDeviceSerial);
      break;

    case 'pairing_request':
      handlePairingRequest(ws, data);
      break;

    case 'offer':
      handleOffer(ws, data);
      break;

    case 'answer':
      handleAnswer(ws, data);
      break;

    case 'ice_candidate':
      handleIceCandidate(ws, data);
      break;

    case 'connection_state':
      handleConnectionState(ws, data);
      break;

    default:
      logger.warn(`Unknown message type: ${type}`);
  }
}

/**
 * Handle device registration
 */
function handleDeviceRegistration(ws, data, setDeviceSerial) {
  const { device_serial } = data;

  if (!device_serial) {
    ws.send(JSON.stringify({
      type: 'error',
      data: { error: 'Missing device_serial' },
    }));
    return;
  }

  // Register device
  clients.set(device_serial, ws);
  setDeviceSerial(device_serial);

  logger.info(`Device registered: ${device_serial}`);

  ws.send(JSON.stringify({
    type: 'registration_success',
    data: {
      device_serial,
      server_timestamp: new Date().toISOString(),
    },
  }));
}

/**
 * Handle pairing requests
 */
function handlePairingRequest(ws, data) {
  const { target_device, password_hash } = data;

  if (!target_device) {
    ws.send(JSON.stringify({
      type: 'error',
      data: { error: 'Missing target_device' },
    }));
    return;
  }

  const targetWs = clients.get(target_device);

  if (!targetWs) {
    ws.send(JSON.stringify({
      type: 'pairing_failed',
      data: { error: 'Target device not found' },
    }));
    return;
  }

  const pairing_code = Math.floor(Math.random() * 1000000)
    .toString()
    .padStart(6, '0');

  // Send pairing request to target
  targetWs.send(JSON.stringify({
    type: 'pairing_request_received',
    data: {
      initiator_device: data.device_serial,
      pairing_code,
      timestamp: new Date().toISOString(),
    },
  }));

  logger.info(`Pairing request: ${data.device_serial} -> ${target_device}`);
}

/**
 * Handle WebRTC offer
 */
function handleOffer(ws, data) {
  const { target_device, sdp } = data;

  const targetWs = clients.get(target_device);

  if (!targetWs) {
    ws.send(JSON.stringify({
      type: 'error',
      data: { error: 'Target device not available' },
    }));
    return;
  }

  targetWs.send(JSON.stringify({
    type: 'offer',
    data: { sdp },
  }));

  logger.info(`WebRTC offer relayed to ${target_device}`);
}

/**
 * Handle WebRTC answer
 */
function handleAnswer(ws, data) {
  const { target_device, sdp } = data;

  const targetWs = clients.get(target_device);

  if (!targetWs) {
    ws.send(JSON.stringify({
      type: 'error',
      data: { error: 'Target device not available' },
    }));
    return;
  }

  targetWs.send(JSON.stringify({
    type: 'answer',
    data: { sdp },
  }));

  logger.info(`WebRTC answer relayed to ${target_device}`);
}

/**
 * Handle ICE candidates
 */
function handleIceCandidate(ws, data) {
  const { target_device, candidate } = data;

  const targetWs = clients.get(target_device);

  if (targetWs) {
    targetWs.send(JSON.stringify({
      type: 'ice_candidate',
      data: { candidate },
    }));
  }
}

/**
 * Handle connection state updates
 */
function handleConnectionState(ws, data) {
  const { state, target_device } = data;

  logger.info(`Connection state update: ${state}`);

  if (target_device) {
    const targetWs = clients.get(target_device);
    if (targetWs) {
      targetWs.send(JSON.stringify({
        type: 'connection_state',
        data: { state },
      }));
    }
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    clients: clients.size,
  });
});

// Server stats endpoint
app.get('/stats', (req, res) => {
  res.json({
    connected_clients: clients.size,
    active_sessions: sessionMap.size,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// Start server
server.listen(port, () => {
  logger.info(`Signaling server listening on port ${port}`);
  logger.info(`WebSocket server ready at ws://localhost:${port}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});
