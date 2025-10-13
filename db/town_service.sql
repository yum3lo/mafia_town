CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Locations table
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    max_capacity INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Movement History table
CREATE TABLE IF NOT EXISTS movement_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id VARCHAR(100) NOT NULL,
    from_location_id UUID,
    to_location_id UUID NOT NULL,
    movement_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    game_id UUID NOT NULL,
    FOREIGN KEY (to_location_id) REFERENCES locations(id) ON DELETE CASCADE,
    FOREIGN KEY (from_location_id) REFERENCES locations(id) ON DELETE CASCADE
);

-- Location Connections table
CREATE TABLE IF NOT EXISTS location_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_location_id UUID NOT NULL,
    to_location_id UUID NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_location_id) REFERENCES locations(id) ON DELETE CASCADE,
    FOREIGN KEY (to_location_id) REFERENCES locations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS current_player_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id VARCHAR(100) NOT NULL,
    location_id UUID NOT NULL,
    game_id UUID NOT NULL,
    arrived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    game_day INTEGER DEFAULT 1,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
    UNIQUE(player_id, game_id)
);

CREATE INDEX IF NOT EXISTS idx_movement_character_id ON movement_history(character_id);
CREATE INDEX IF NOT EXISTS idx_movement_game_id ON movement_history(game_id);
CREATE INDEX IF NOT EXISTS idx_location_connections ON location_connections(from_location_id, to_location_id);
CREATE INDEX IF NOT EXISTS idx_current_player_location ON current_player_locations(location_id);
CREATE INDEX IF NOT EXISTS idx_current_player_game ON current_player_locations(player_id, game_id);

DO $$
DECLARE
    loc_count INTEGER;
    mov_count INTEGER;
    conn_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO loc_count FROM locations;
    
    IF loc_count > 0 THEN
        RAISE NOTICE 'Database already contains data:';
        RAISE NOTICE '- Locations: % rows', loc_count;
        RAISE NOTICE '- Movements: % rows', (SELECT COUNT(*) FROM movement_history);
        RAISE NOTICE '- Connections: % rows', (SELECT COUNT(*) FROM location_connections);
        RETURN;
    END IF;

    INSERT INTO locations (id, name, type, description, max_capacity) VALUES
    ('550e8400-e29b-41d4-a716-446655442001', 'Town Square', 'public', 'Central meeting place', 50),
    ('550e8400-e29b-41d4-a716-446655442002', 'Dark Alley', 'restricted', 'Perfect for secret meetings', 10),
    ('550e8400-e29b-41d4-a716-446655442003', 'Tavern', 'public', 'Local gathering spot', 30),
    ('550e8400-e29b-41d4-a716-446655442004', 'Church', 'public', 'Place of worship', 40),
    ('550e8400-e29b-41d4-a716-446655442005', 'Graveyard', 'restricted', 'Spooky and quiet', 20);

    INSERT INTO location_connections (from_location_id, to_location_id) VALUES
    ('550e8400-e29b-41d4-a716-446655442001', '550e8400-e29b-41d4-a716-446655442002'),
    ('550e8400-e29b-41d4-a716-446655442001', '550e8400-e29b-41d4-a716-446655442003'),
    ('550e8400-e29b-41d4-a716-446655442003', '550e8400-e29b-41d4-a716-446655442004'),
    ('550e8400-e29b-41d4-a716-446655442004', '550e8400-e29b-41d4-a716-446655442005');


    INSERT INTO movement_history (character_id, from_location_id, to_location_id, game_id) VALUES
    ('550e8400-e29b-41d4-a716-446655440201', '550e8400-e29b-41d4-a716-446655442001', '550e8400-e29b-41d4-a716-446655442003', '550e8400-e29b-41d4-a716-446655440100');

    SELECT COUNT(*) INTO loc_count FROM locations;
    SELECT COUNT(*) INTO mov_count FROM movement_history;
    SELECT COUNT(*) INTO conn_count FROM location_connections;

    RAISE NOTICE 'Database initialized successfully:';
    RAISE NOTICE '- Locations: % rows', loc_count;
    RAISE NOTICE '- Movements: % rows', mov_count;
    RAISE NOTICE '- Connections: % rows', conn_count;
END $$;