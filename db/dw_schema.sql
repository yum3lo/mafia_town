-- DIMENSION: Users
CREATE TABLE IF NOT EXISTS dim_users (
  user_key SERIAL PRIMARY KEY,  --if a user deletes their account
  original_user_id VARCHAR(50) UNIQUE,
  username VARCHAR(100),
  created_at TIMESTAMP,
  last_synced_at TIMESTAMP DEFAULT NOW()
);

--DIMENSION: Time (for queries like "Games played on weekends")
CREATE TABLE IF NOT EXISTS dim_time (
  time_key SERIAL PRIMARY KEY,
  full_date DATE,
  day_of_week VARCHAR(10),
  hour INT
);

-- FACT: Game sessions (metrics)
CREATE TABLE IF NOT EXISTS fact_game_sessions (
  fact_id SERIAL PRIMARY KEY,
  game_id VARCHAR(50) UNIQUE,
  host_user_key INT REFERENCES dim_users(user_key),
  total_players INT,
  winner_team VARCHAR(50),
  duration_seconds INT,
  created_at TIMESTAMP
);