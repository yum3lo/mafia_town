CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Characters table
CREATE TABLE IF NOT EXISTS characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(100) NOT NULL,
    currency_type VARCHAR(50) NOT NULL DEFAULT 'global',
    global_currency INTEGER DEFAULT 0,
    in_game_currency INTEGER DEFAULT 0,
    currency_spent INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Assets table
CREATE TABLE IF NOT EXISTS assets (
    id VARCHAR(100) PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Character Assets table (for mapping characters to their equipped assets)
CREATE TABLE IF NOT EXISTS character_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID NOT NULL,
    asset_id VARCHAR(100) NOT NULL,
    slot_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

-- Inventory Items table
CREATE TABLE IF NOT EXISTS inventory_items (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    currency_type VARCHAR(50) NOT NULL,
    purchase_price INTEGER NOT NULL,
    expires_next_day BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Character Inventory table
CREATE TABLE IF NOT EXISTS character_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID NOT NULL,
    item_id VARCHAR(100) NOT NULL,
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_characters_user_id ON characters(user_id);
CREATE INDEX IF NOT EXISTS idx_assets_category ON assets(category);
CREATE INDEX IF NOT EXISTS idx_character_assets_character_id ON character_assets(character_id);
CREATE INDEX IF NOT EXISTS idx_character_inventory_character_id ON character_inventory(character_id);

-- Populate with sample data if tables are empty
DO $$
BEGIN
    -- Insert sample character
    IF NOT EXISTS (SELECT 1 FROM characters) THEN
        INSERT INTO characters (id, user_id, currency_type, global_currency, currency_spent) VALUES
        ('550e8400-e29b-41d4-a716-446655440201', 'user_123', 'global', 250, 100);

        -- Insert sample assets
        INSERT INTO assets (id, category, name, description, image_url) VALUES
        ('blonde_curly', 'hair', 'Blonde Curly Hair', 'Curly blonde hairstyle', '/assets/hair/blonde_curly.png'),
        ('red_jacket', 'coat', 'Red Leather Jacket', 'Stylish red leather jacket', '/assets/coats/red_jacket.png'),
        ('gold_watch', 'accessory', 'Gold Watch', 'Luxury gold wristwatch', '/assets/accessories/gold_watch.png'),
        ('cheerful_smile', 'face', 'Cheerful Smile', 'A bright, cheerful smile', '/assets/faces/cheerful_smile.png'),
        ('dark_jeans', 'pants', 'Dark Jeans', 'Classic dark denim jeans', '/assets/pants/dark_jeans.png');

        -- Insert sample inventory items
        INSERT INTO inventory_items (id, name, type, description, currency_type, purchase_price, expires_next_day) VALUES
        ('body_armor', 'Bulletproof Vest', 'protection', 'Protects against mafia attacks during night phase', 'in-game', 150, true);

        -- Map assets to character
        INSERT INTO character_assets (character_id, asset_id, slot_type) VALUES
        ('550e8400-e29b-41d4-a716-446655440201', 'blonde_curly', 'hair'),
        ('550e8400-e29b-41d4-a716-446655440201', 'red_jacket', 'coat'),
        ('550e8400-e29b-41d4-a716-446655440201', 'gold_watch', 'accessory'),
        ('550e8400-e29b-41d4-a716-446655440201', 'cheerful_smile', 'face'),
        ('550e8400-e29b-41d4-a716-446655440201', 'dark_jeans', 'pants');

        -- Insert inventory items for character
        INSERT INTO character_inventory (character_id, item_id, quantity) VALUES
        ('550e8400-e29b-41d4-a716-446655440201', 'body_armor', 1);

        RAISE NOTICE 'Sample data inserted successfully';
    END IF;
END $$;