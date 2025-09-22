CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    device_fingerprint VARCHAR(255),
    game_id VARCHAR(50),
    global_currency INT DEFAULT 0,
    in_game_currency INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO users (email, username, password, game_id, global_currency)
SELECT 'player@example.com', 'player1', 'hashedPassword', 'game_3', 100
WHERE NOT EXISTS (SELECT 1 FROM users);