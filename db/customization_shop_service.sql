CREATE TABLE IF NOT EXISTS clothing_items (
      item_id BIGSERIAL PRIMARY KEY,
      name VARCHAR(99),
      description TEXT,
      type VARCHAR(50),
      price INTEGER
);

INSERT INTO clothing_items (item_id, name, price, type, description)
SELECT * FROM (
      SELECT 1 AS item_id, 'Blonde Hair' AS name, 200 AS price, 'HAIR' AS type, 'You look I-legally blonde!' AS description
      UNION ALL
      SELECT 2, 'Baseball Cap', 300, 'HAT', 'Winning with a home run!'
      UNION ALL
      SELECT 3, 'Golden Necklace', 350, 'JEWELRY', 'Some people say it is fake. Does not taste like it.'
      UNION ALL
      SELECT 4, 'Mafia Town T-shirt', 150, 'SHIRT', 'Show your support for Mafia Town!'
      UNION ALL
      SELECT 5, 'Mafia Coat', 300, 'COAT', 'Now everyone will suspect you are the mafia!'
      UNION ALL
      SELECT 6, 'Blue Jeans', 200, 'PANTS', 'Denim 4 life!'
      UNION ALL
      SELECT 7, 'Hunter Coat', 250, 'COAT', 'Gotta hunt these mafia.'
      UNION ALL
      SELECT 8, 'White Shirt with Black Tie', 250, 'SHIRT', 'Getting down to business.'
      UNION ALL
      SELECT 9, 'Black shoes', 250, 'SHOES', 'As basic as ever.'
      UNION ALL
      SELECT 10,'Black sneakers', 250, 'SHOES', 'You can run but you cannot hide!'
  ) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM clothing_items);