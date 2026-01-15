# Plan: COSC - CooperatingScreen Technical Development Strategy

**TL;DR:** A comprehensive architecture for a long-term Flutter-based cross-device screen sharing app with self-hosted Supabase backend. The project spans frontend (Flutter), real-time communication (WebRTC/WebSockets), backend infrastructure (Node.js/Python), and DevOps. We'll structure this as a scalable, maintainable system with clear separation of concerns, prioritizing MVP functionality first, then expanding to advanced features.

## Architecture Overview

```
┌─────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│  Flutter App    │◄────────►│  Signaling Server│◄────────►│ Supabase Backend │
│  (Android/iOS)  │  WebRTC  │  (WebSocket)     │  REST    │  (PostgreSQL +   │
└─────────────────┘          │  (Node.js)       │          │   Auth, Storage) │
       ▲                      └──────────────────┘          └──────────────────┘
       │                                                              │
       │ P2P Direct Connection (STUN/TURN)                          │
       └──────────────────────────────────────────────────────────────┘
```

## Implementation Steps (Phased Approach)

### Phase 1: Foundation & Infrastructure (Weeks 1-4)

#### Step 1: Initialize Flutter Project & Core Architecture
- Create Flutter project: `flutter create cosc`
- Set up folder structure: `lib/models`, `lib/screens`, `lib/services`, `lib/utils`, `lib/widgets`
- Choose state management: Provider or BLoC (recommend Provider for this scale)
- Configure Android/iOS platform-specific settings (permissions, capabilities)
- Initialize git repository with main/develop/feature branching strategy
- Create `.gitignore` and environment configuration files

**Deliverable:** Clean Flutter project skeleton with proper architecture

#### Step 2: Set Up Self-Hosted Supabase Infrastructure
- Deploy Supabase on Debian 11 VM using Docker
- Configure PostgreSQL database schema:
  ```sql
  - users (id, email, device_serial, created_at)
  - devices (id, serial_number, device_name, device_type, owner_id, public_key)
  - pairing_sessions (id, device_1_id, device_2_id, pairing_code, password_hash, status, expires_at)
  - screen_transfers (id, from_device_id, to_device_id, transfer_data, timestamp)
  ```
- Set up JWT authentication
- Configure Row-Level Security (RLS) policies
- Enable Supabase real-time features
- Set up PostgREST API
- Configure storage buckets for potential screen recordings/exports

**Deliverable:** Production-ready Supabase instance with schemas and authentication

#### Step 3: Build Signaling Server (WebSocket Layer)
- Create Node.js/Express project
- Implement WebSocket server (Socket.io or ws library)
- Create signaling message types:
  - `device_registration`: register device with serial
  - `pairing_request`: initiate pairing with target device
  - `offer`: send WebRTC offer (SDP)
  - `answer`: send WebRTC answer (SDP)
  - `ice_candidate`: send ICE candidates
  - `connection_state`: update connection status
- Implement session management and validation
- Add error handling and automatic cleanup
- Deploy on VM with reverse proxy (Nginx) and SSL (Let's Encrypt)

**Deliverable:** Functional WebSocket signaling server accessible over HTTPS

### Phase 2: Device Pairing & Authentication (Weeks 5-8)

#### Step 4: Implement Device Pairing System
- Generate unique 8-12 character serial numbers (alphanumeric, URL-safe)
- Create secure pairing flow:
  - Display device serial on first launch
  - Allow user to set custom pairing password (min 8 chars, mixed case + numbers)
  - Store pairing code in secure storage (Keychain/Keystore)
- Build UI screens:
  - Device setup/registration screen
  - Pairing request screen (enter remote serial + password)
  - Pairing confirmation screen
  - Device list screen
- Implement local SQLite database (Hive) for paired devices
- Add pairing request timeout (30 seconds)
- Handle failed pairing attempts with user feedback

**Technical Details:**
- Use `get_storage` for secure key-value storage
- Use `hive` for local SQLite database
- Implement bcrypt hashing for passwords (never store plain text)
- Add replay attack prevention with nonces

**Deliverable:** Complete pairing flow with working UI and local persistence

#### Step 5: Integrate Supabase with Flutter App
- Add `supabase_flutter` dependency
- Implement Supabase initialization in app
- Create authentication service:
  - Device serial registration
  - Anonymous auth with device identifier
- Sync paired devices to Supabase
- Implement offline-first approach with local caching
- Handle network connectivity status
- Create data models for serialization

**Deliverable:** Flutter app connected to Supabase with working authentication

### Phase 3: WebRTC P2P Connection (Weeks 9-14)

#### Step 6: Implement WebRTC P2P Connection
- Add `flutter_webrtc` dependency
- Create WebRTC service:
  - Initialize local media stream (audio/video initially for testing)
  - Create RTCPeerConnection with STUN/TURN servers
  - Handle session descriptions (offer/answer)
  - Manage ICE candidates
- Configure STUN servers:
  - Use public STUN servers initially (Google, Mozilla)
  - Plan TURN server deployment later (coturn)
- Implement connection state handlers:
  - `signaling_state_change`
  - `connection_state_change`
  - `ice_connection_state_change`
  - `ice_gathering_state_change`
- Add error handling and automatic reconnection

**Technical Details:**
- Use WebSocket signaling server for SDP/ICE exchange
- Implement timeout mechanisms (connection must establish within 30s)
- Handle network interruption gracefully
- Test on real devices and various network conditions (4G, WiFi, poor connectivity)

**Deliverable:** Working P2P connection between two devices with audio/video test stream

#### Step 7: Implement Screen Transfer & Display UI
- Create local screen capture mechanism:
  - Use platform channels for native screen capture (Android: MediaProjection, iOS: ReplayKit)
  - Encode to H.264 video codec
  - Adapt quality based on network conditions
- Build remote screen display widget:
  - Render RTCVideoView for received stream
  - Handle orientation changes
  - Implement fullscreen mode
- Create gesture recognition:
  - Detect touch events on remote screen
  - Prepare infrastructure for drag-and-drop (for Phase 4)
- Build simple transfer controls (start/stop)

**Deliverable:** One-way screen sharing working between two devices with video rendering

### Phase 4: Advanced Features & Polish (Weeks 15-20)

#### Step 8: Add Drag-and-Drop & Bidirectional Transfer
- Implement gesture detection for drag operations
- Create data channel for file/clipboard transfer
- Build drag-and-drop UI overlay
- Handle file transfers:
  - Small files (< 50MB) via WebRTC data channel
  - Large files via Supabase storage with chunked upload
- Implement clipboard sync
- Add visual feedback for drop zones

#### Step 9: Settings & Configuration UI
- Build preference screens:
  - Device name customization
  - Screen position (left/right orientation)
  - Video quality settings (auto/HD/SD)
  - Audio options
  - Display timeout settings
- Implement theme support (light/dark)
- Create user profile screen
- Add app settings persistence to Hive

#### Step 10: Security & Encryption Implementation
- Add TLS/SSL for all Supabase/server communications (automatic with HTTPS)
- Implement end-to-end encryption for WebRTC streams:
  - Use DTLS-SRTP (built-in with WebRTC standard)
  - Optional: add application-level encryption
- Secure serial number generation (cryptographically random)
- Implement password hashing with bcrypt
- Add rate limiting on signaling server
- Implement device fingerprinting for additional security

### Phase 5: Testing & Optimization (Weeks 21-24)

#### Step 11: Comprehensive Testing
- Unit tests for business logic (state management, database operations)
- Integration tests for WebRTC flows
- End-to-end testing on real devices (at least 2 Android, 2 iOS devices)
- Performance profiling:
  - CPU/memory usage during screen sharing
  - Network bandwidth consumption
  - Latency measurements
  - Battery drain analysis
- Load testing on signaling server
- Security audit

#### Step 12: Optimization & Deployment Preparation
- Optimize video codec settings for mobile networks
- Implement adaptive bitrate adjustment
- Reduce app bundle size (ProGuard/R8 for Android)
- Prepare app store submissions (icons, screenshots, descriptions)
- Create user documentation and FAQs
- Plan CI/CD pipeline with GitHub Actions or similar

## Technical Stack (Detailed)

### Frontend (Flutter)
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  provider: ^6.0.0
  
  # WebRTC & Networking
  flutter_webrtc: ^0.9.0
  web_socket_channel: ^2.4.0
  
  # Backend Integration
  supabase_flutter: ^1.10.0
  
  # Storage & Persistence
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  get_storage: ^2.1.1
  
  # Security
  flutter_secure_storage: ^9.0.0
  
  # UI Components
  cupertino_icons: ^1.0.0
  
  # Utilities
  intl: ^0.19.0
```

### Backend (Signaling Server)
- **Runtime:** Node.js 18+ LTS
- **Framework:** Express.js
- **WebSocket:** Socket.io or ws (raw WebSocket)
- **Database:** PostgreSQL (via Supabase)
- **Containerization:** Docker

### Infrastructure
- **VM Hosting:** Debian 11 (8GB RAM, 4 vCores, 75GB NVMe)
- **Database:** Supabase (PostgreSQL)
- **Reverse Proxy:** Nginx
- **SSL/TLS:** Let's Encrypt
- **Monitoring:** Simple logging (ELK stack optional for future)
- **STUN/TURN:** coturn (self-hosted for Phase 2+)

## Database Schema (PostgreSQL)

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_serial VARCHAR(12) UNIQUE NOT NULL,
  device_name VARCHAR(255),
  device_type VARCHAR(50), -- 'android' or 'ios'
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Devices table
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  serial_number VARCHAR(12) UNIQUE NOT NULL,
  device_name VARCHAR(255),
  device_type VARCHAR(50),
  public_key TEXT,
  last_seen TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Pairing sessions table
CREATE TABLE pairing_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_1_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  device_2_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  pairing_code VARCHAR(6), -- PIN code for pairing confirmation
  password_hash VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending', -- pending, active, expired, rejected
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(device_1_id, device_2_id)
);

-- Screen transfers table (for logging/analytics)
CREATE TABLE screen_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_device_id UUID REFERENCES devices(id),
  to_device_id UUID REFERENCES devices(id),
  duration_seconds INTEGER,
  data_transferred_mb DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairing_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE screen_transfers ENABLE ROW LEVEL SECURITY;
```

## Critical Design Decisions

### 1. P2P vs Server Relay
- **Decision:** P2P-first with server relay fallback (Phase 2+)
- **Rationale:** Lower latency, reduced server costs, better privacy
- **Fallback:** If P2P fails after 30s, connection attempt times out with user notification

### 2. Screen Capture Approach
- **Decision:** Native platform channels for screen capture (not accessibility service)
- **Rationale:** Better performance, no accessibility service warnings, simpler UX
- **Trade-off:** Requires more platform-specific code

### 3. Authentication Model
- **Decision:** Device-based authentication (serial + password), anonymous per-session
- **Rationale:** Simpler for users, no account creation friction
- **Future:** Can add optional user accounts for cross-device persistence

### 4. Storage Strategy
- **Decision:** Local SQLite (Hive) for cache + Supabase for sync
- **Rationale:** Works offline, syncs when online, single source of truth on server
- **Conflict Resolution:** Client-side last-write-wins, server-side canonical

### 5. Real-Time Communication
- **Decision:** WebSockets for signaling, WebRTC data channels for P2P
- **Rationale:** WebSockets for reliability, WebRTC data channels for low-latency peer communication
- **Fallback:** Can add Supabase real-time subscriptions for additional reliability

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| NAT Traversal Failure | Use public STUN + deploy TURN server, implement connection timeout with user feedback |
| Data Synchronization Conflicts | Implement clock-sync mechanisms, prefer server-side canonical state |
| Security Breaches | Use bcrypt for passwords, enable RLS in Supabase, regular security audits |
| Performance Issues | Adaptive bitrate adjustment, quality profiles (auto/HD/SD), lazy loading |
| Scalability | Stateless signaling server, load balancer for multiple server instances (Phase 2+) |
| User Retention | Excellent UX, clear error messages, tutorial/onboarding flow |

## Success Metrics (MVP)

- ✅ Devices successfully pair with serial + password
- ✅ Screen sharing initiates and displays within 5 seconds
- ✅ Video plays smoothly at 30fps minimum on 4G network
- ✅ Connection remains stable for 10+ minute sessions
- ✅ App uses < 150MB RAM during screen sharing
- ✅ Graceful handling of network disconnections with reconnect capability

## Future Enhancements (Post-MVP)

1. **Drag-and-Drop Files:** Full implementation with folder support
2. **Gesture Recording:** Record and replay user interactions
3. **Multi-Device:** Support 3+ device connections simultaneously
4. **Clipboard Sync:** Automatic clipboard content sharing
5. **Screen Recording:** Record shared sessions locally
6. **Gesture Recognition:** Swipe commands, multi-touch support
7. **Analytics Dashboard:** Self-hosted analytics for app performance
8. **Public App Store Release:** Google Play Store and Apple App Store
9. **Desktop Clients:** Windows/Mac/Linux applications using Flutter Desktop
10. **Team/Organization Features:** Shared sessions, permission management

## Questions for Clarification

1. **TURN Server Strategy:** Should we use public TURN servers initially (cheaper, easier) or self-host from the start?
2. **Authentication Complexity:** Do you want optional email-based accounts for future features, or pure device-based forever?
3. **Feature Scope:** Is drag-and-drop the final feature, or do you have ideas for clipboard, file transfer, etc.?
4. **Platform Priority:** Launch on Android first, then iOS? Or simultaneous?
5. **Monetization Model:** Free app, ads, premium features, or just free open-source?
6. **Hosting Budget:** What's the max monthly cost for Supabase + server infrastructure?

## Timeline Estimate (Aggressive vs Realistic)

| Phase | Aggressive | Realistic | With 1 Dev |
|-------|-----------|-----------|-----------|
| Phase 1 | 2 weeks | 4 weeks | 4 weeks |
| Phase 2 | 2 weeks | 4 weeks | 6 weeks |
| Phase 3 | 3 weeks | 6 weeks | 10 weeks |
| Phase 4 | 2 weeks | 4 weeks | 6 weeks |
| Phase 5 | 2 weeks | 4 weeks | 6 weeks |
| **TOTAL** | **11 weeks** | **22 weeks** | **32 weeks** |

Realistic timeline assumes code review, testing, and debugging overhead. With one developer, add 30-50% more time for context switching and learning new technologies.

## Next Actions

1. Review and approve this plan
2. Create Flutter project and Supabase instance
3. Set up development environment (Android Studio, Xcode, VS Code)
4. Create project structure and git repository
5. Begin Phase 1 implementation
