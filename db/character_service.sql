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
        ('550e8400-e29b-41d4-a716-446655440201', 'user_123', 'global', 250, 100),
        ('550e8400-e29b-41d4-a716-446655440202', 'user_456', 'global', 100, 20),
        ('550e8400-e29b-41d4-a716-446655440203', 'user_789', 'in-game', 0, 0);

        -- Insert sample assets
        INSERT INTO assets (id, category, name, description, image_url) VALUES
        -- Hair options
        ('blonde_curly', 'hair', 'Blonde Curly Hair', 'Curly blonde hairstyle', '/assets/hair/blonde_curly.png'),
        ('black_straight', 'hair', 'Black Straight Hair', 'Straight black hair', '/assets/hair/black_straight.png'),
        ('brown_wavy', 'hair', 'Brown Wavy Hair', 'Wavy brown hair', '/assets/hair/brown_wavy.png'),
        ('red_short', 'hair', 'Red Short Hair', 'Short red hair', '/assets/hair/red_short.png'),
        ('gray_long', 'hair', 'Gray Long Hair', 'Long gray hair', '/assets/hair/gray_long.png'),
        ('bald', 'hair', 'Bald', 'No hair', '/assets/hair/bald.png'),
        -- Hair accessory/headwear options
        ('baseball_cap', 'hair_accessory', 'Baseball Cap', 'Casual baseball cap', '/assets/hair_accessory/baseball_cap.png'),
        ('beanie', 'hair_accessory', 'Beanie', 'Warm winter beanie', '/assets/hair_accessory/beanie.png'),
        ('fedora', 'hair_accessory', 'Fedora', 'Classic fedora hat', '/assets/hair_accessory/fedora.png'),
        ('cowboy_hat', 'hair_accessory', 'Cowboy Hat', 'Western cowboy hat', '/assets/hair_accessory/cowboy_hat.png'),
        ('top_hat', 'hair_accessory', 'Top Hat', 'Elegant top hat', '/assets/hair_accessory/top_hat.png'),
        ('no_hat', 'hair_accessory', 'No Hat', 'No headwear', '/assets/hair_accessory/no_hat.png'),
        -- Coat options
        ('red_jacket', 'coat', 'Red Leather Jacket', 'Stylish red leather jacket', '/assets/coats/red_jacket.png'),
        ('black_hoodie', 'coat', 'Black Hoodie', 'Casual black hoodie', '/assets/coats/black_hoodie.png'),
        ('blue_blazer', 'coat', 'Blue Blazer', 'Formal blue blazer', '/assets/coats/blue_blazer.png'),
        ('green_jacket', 'coat', 'Green Jacket', 'Military green jacket', '/assets/coats/green_jacket.png'),
        ('leather_vest', 'coat', 'Leather Vest', 'Brown leather vest', '/assets/coats/leather_vest.png'),
        ('no_coat', 'coat', 'No Coat', 'Plain shirt', '/assets/coats/no_coat.png'),
        -- Accessory options
        ('gold_watch', 'accessory', 'Gold Watch', 'Luxury gold wristwatch', '/assets/accessories/gold_watch.png'),
        ('silver_necklace', 'accessory', 'Silver Necklace', 'Silver chain necklace', '/assets/accessories/silver_necklace.png'),
        ('silver_ring', 'accessory', 'Silver Ring', 'Elegant silver ring', '/assets/accessories/silver_ring.png'),
        ('sunglasses', 'accessory', 'Sunglasses', 'Dark sunglasses', '/assets/accessories/sunglasses.png'),
        ('bandana', 'accessory', 'Bandana', 'Red bandana', '/assets/accessories/bandana.png'),
        ('earring', 'accessory', 'Earring', 'Single gold earring', '/assets/accessories/earring.png'),
        ('no_accessory', 'accessory', 'No Accessory', 'No accessory', '/assets/accessories/no_accessory.png'),
        -- Face options
        ('cheerful_smile', 'face', 'Cheerful Smile', 'A bright, cheerful smile', '/assets/faces/cheerful_smile.png'),
        ('serious_frown', 'face', 'Serious Frown', 'Serious expression', '/assets/faces/serious_frown.png'),
        ('smirk', 'face', 'Smirk', 'Sly smirk', '/assets/faces/smirk.png'),
        ('angry_scowl', 'face', 'Angry Scowl', 'Angry expression', '/assets/faces/angry_scowl.png'),
        ('neutral', 'face', 'Neutral', 'Neutral expression', '/assets/faces/neutral.png'),
        ('surprised', 'face', 'Surprised', 'Surprised look', '/assets/faces/surprised.png'),
        -- Pants options
        ('dark_jeans', 'pants', 'Dark Jeans', 'Classic dark denim jeans', '/assets/pants/dark_jeans.png'),
        ('blue_jeans', 'pants', 'Blue Jeans', 'Light blue jeans', '/assets/pants/blue_jeans.png'),
        ('black_slacks', 'pants', 'Black Slacks', 'Formal black pants', '/assets/pants/black_slacks.png'),
        ('cargo_pants', 'pants', 'Cargo Pants', 'Tactical cargo pants', '/assets/pants/cargo_pants.png'),
        ('khaki_shorts', 'pants', 'Khaki Shorts', 'Casual khaki shorts', '/assets/pants/khaki_shorts.png'),
        ('torn_jeans', 'pants', 'Torn Jeans', 'Distressed jeans', '/assets/pants/torn_jeans.png'),
        -- Shoes options
        ('leather_boots', 'shoes', 'Leather Boots', 'Brown leather boots', '/assets/shoes/leather_boots.png'),
        ('sneakers', 'shoes', 'Sneakers', 'Casual sneakers', '/assets/shoes/sneakers.png'),
        ('dress_shoes', 'shoes', 'Dress Shoes', 'Formal dress shoes', '/assets/shoes/dress_shoes.png'),
        ('combat_boots', 'shoes', 'Combat Boots', 'Military combat boots', '/assets/shoes/combat_boots.png'),
        ('sandals', 'shoes', 'Sandals', 'Casual sandals', '/assets/shoes/sandals.png'),
        ('no_shoes', 'shoes', 'No Shoes', 'Barefoot', '/assets/shoes/no_shoes.png');

        -- Insert sample inventory items
        INSERT INTO inventory_items (id, name, type, description, currency_type, purchase_price, expires_next_day) VALUES
        ('body_armor', 'Bulletproof Vest', 'protection', 'Protects against mafia attacks during night phase', 'in-game', 150, true);

        -- Map assets to character
        INSERT INTO character_assets (character_id, asset_id, slot_type) VALUES
        ('550e8400-e29b-41d4-a716-446655440201', 'blonde_curly', 'hair'),
        ('550e8400-e29b-41d4-a716-446655440201', 'red_jacket', 'coat'),
        ('550e8400-e29b-41d4-a716-446655440201', 'gold_watch', 'accessory'),
        ('550e8400-e29b-41d4-a716-446655440201', 'cheerful_smile', 'face'),
        ('550e8400-e29b-41d4-a716-446655440201', 'dark_jeans', 'pants'),
        ('550e8400-e29b-41d4-a716-446655440202', 'red_jacket', 'coat'),
        ('550e8400-e29b-41d4-a716-446655440202', 'gold_watch', 'accessory'),
        ('550e8400-e29b-41d4-a716-446655440203', 'blonde_curly', 'hair'),
        ('550e8400-e29b-41d4-a716-446655440203', 'cheerful_smile', 'face');

        -- Insert inventory items for character
        INSERT INTO character_inventory (character_id, item_id, quantity) VALUES
        ('550e8400-e29b-41d4-a716-446655440201', 'body_armor', 1),
        ('550e8400-e29b-41d4-a716-446655440202', 'body_armor', 2),
        ('550e8400-e29b-41d4-a716-446655440203', 'body_armor', 1);

        RAISE NOTICE 'Sample data inserted successfully';
    END IF;
END $$;