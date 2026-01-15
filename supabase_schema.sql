-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_serial VARCHAR(12) UNIQUE NOT NULL,
  device_name VARCHAR(255),
  device_type VARCHAR(50), -- 'android' or 'ios'
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Devices table (for tracking multiple devices per user)
CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  serial_number VARCHAR(12) UNIQUE NOT NULL,
  device_name VARCHAR(255),
  device_type VARCHAR(50),
  public_key TEXT,
  last_seen TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Pairing sessions table
CREATE TABLE IF NOT EXISTS pairing_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_1_id VARCHAR(12) NOT NULL,
  device_2_id VARCHAR(12) NOT NULL,
  pairing_code VARCHAR(6),
  password_hash VARCHAR(255),
  nonce VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending', -- pending, active, expired, rejected
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  UNIQUE(device_1_id, device_2_id)
);

-- Screen transfers table (for logging/analytics)
CREATE TABLE IF NOT EXISTS screen_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
  to_device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
  duration_seconds INTEGER,
  data_transferred_mb DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT now()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_users_device_serial ON users(device_serial);
CREATE INDEX IF NOT EXISTS idx_devices_serial ON devices(serial_number);
CREATE INDEX IF NOT EXISTS idx_pairing_sessions_status ON pairing_sessions(status);
CREATE INDEX IF NOT EXISTS idx_pairing_sessions_expires ON pairing_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_screen_transfers_from ON screen_transfers(from_device_id);
CREATE INDEX IF NOT EXISTS idx_screen_transfers_to ON screen_transfers(to_device_id);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairing_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE screen_transfers ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Allow users to read their own data
CREATE POLICY "Users can read own user data" ON users
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own user data" ON users
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own user data" ON users
  FOR UPDATE USING (true) WITH CHECK (true);

-- Allow public read for pairing (to find devices)
CREATE POLICY "Pairing sessions are readable" ON pairing_sessions
  FOR SELECT USING (true);

CREATE POLICY "Pairing sessions are insertable" ON pairing_sessions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Pairing sessions are updatable" ON pairing_sessions
  FOR UPDATE USING (true) WITH CHECK (true);

-- Create function to clean up expired pairing sessions
CREATE OR REPLACE FUNCTION cleanup_expired_pairings()
RETURNS void AS $$
BEGIN
  UPDATE pairing_sessions
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at
  BEFORE UPDATE ON devices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pairing_sessions_updated_at
  BEFORE UPDATE ON pairing_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
