-- Communication service tables
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Chat Rooms
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('global', 'mafia', 'location', 'voting', 'private')),
    game_id UUID NOT NULL,
    location_id UUID,
    active BOOLEAN DEFAULT TRUE,
    max_participants INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_room_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text' CHECK (type IN ('text', 'system', 'action', 'rumor')),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE
);

-- Chat Room Participants
CREATE TABLE IF NOT EXISTS chat_room_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_room_id UUID NOT NULL,
    player_id UUID NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chat_rooms_game_id ON chat_rooms(game_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_room_id ON messages(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Mock game and players (these represent data from other services)
-- Game: 550e8400-e29b-41d4-a716-446655440100
-- Players: 
--   550e8400-e29b-41d4-a716-446655440201 (Townsperson, Alive, Town Square)
--   550e8400-e29b-41d4-a716-446655440202 (Mafia, Alive, Forest)  
--   550e8400-e29b-41d4-a716-446655440203 (Townsperson, Dead, Town Square)

-- Chat rooms
INSERT INTO chat_rooms (id, name, type, game_id, location_id, active) VALUES 
('550e8400-e29b-41d4-a716-446655441001', 'Global Chat', 'global', '550e8400-e29b-41d4-a716-446655440100', NULL, TRUE),
('550e8400-e29b-41d4-a716-446655441002', 'Mafia Chat', 'mafia', '550e8400-e29b-41d4-a716-446655440100', NULL, TRUE),
('550e8400-e29b-41d4-a716-446655441003', 'Town Square Chat', 'location', '550e8400-e29b-41d4-a716-446655440100', '550e8400-e29b-41d4-a716-446655442001', TRUE),
('550e8400-e29b-41d4-a716-446655441004', 'Forest Chat', 'location', '550e8400-e29b-41d4-a716-446655440100', '550e8400-e29b-41d4-a716-446655442002', TRUE),
('550e8400-e29b-41d4-a716-446655441005', 'Voting Discussion', 'voting', '550e8400-e29b-41d4-a716-446655440100', NULL, FALSE);

-- Sample messages
INSERT INTO messages (chat_room_id, sender_id, content, type) VALUES 
('550e8400-e29b-41d4-a716-446655441001', '550e8400-e29b-41d4-a716-446655440201', 'Good morning everyone!', 'text'),
('550e8400-e29b-41d4-a716-446655441001', '550e8400-e29b-41d4-a716-446655440202', 'Hello! Ready for today?', 'text'),
('550e8400-e29b-41d4-a716-446655441002', '550e8400-e29b-41d4-a716-446655440202', 'Tonight we strike...', 'text'),
('550e8400-e29b-41d4-a716-446655441003', '550e8400-e29b-41d4-a716-446655440201', 'Anyone seen anything suspicious?', 'text');

-- Sample participants
INSERT INTO chat_room_participants (chat_room_id, player_id, active) VALUES 
-- Global chat - all alive players
('550e8400-e29b-41d4-a716-446655441001', '550e8400-e29b-41d4-a716-446655440201', TRUE),
('550e8400-e29b-41d4-a716-446655441001', '550e8400-e29b-41d4-a716-446655440202', TRUE),
-- Mafia chat - only mafia members
('550e8400-e29b-41d4-a716-446655441002', '550e8400-e29b-41d4-a716-446655440202', TRUE),
-- Location chats
('550e8400-e29b-41d4-a716-446655441003', '550e8400-e29b-41d4-a716-446655440201', TRUE),
('550e8400-e29b-41d4-a716-446655441004', '550e8400-e29b-41d4-a716-446655440202', TRUE);