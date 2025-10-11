CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    device_fingerprint VARCHAR(255),
    location_ip VARCHAR(50),
    location_city VARCHAR(100),
    location_country VARCHAR(100),
    location_org VARCHAR(255),
    game_id VARCHAR(50),
    global_currency INT DEFAULT 0,
    in_game_currency INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO users (email, username, password, device_fingerprint, location_ip, location_city, location_country, location_org, game_id, global_currency, in_game_currency)
SELECT 'player@example.com', 'player1', 'hashedPassword', '65849e4a6e13decd23e9b773158c1cd947e0b84454de867421aea6652c54f8ab', '127.0.0.1', 'Chisinau', 'Moldova', 'Moldtelecom', 'game_1', 100, 0
WHERE NOT EXISTS (SELECT 1 FROM users);