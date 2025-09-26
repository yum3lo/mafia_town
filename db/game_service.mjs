import { createClient } from "redis";

const client = createClient({
  url: `redis://${process.env.REDIS_GAME_HOST}:${process.env.REDIS_GAME_PORT || 6379}`
});

const seed = async () => {
  await client.connect();

  const game = {
    gameId: "game_1",
    gameCode: "AYA4G",
    hostUserId: "user_1",
    gameStatus: "waiting",
    maxPlayers: 15,
    currentPlayers: 1,
    players: [{ userId: "user_1" }]
  };
  await client.set(`game:${game.gameId}`, JSON.stringify(game));

  console.log("Game service database seeded with initial data.");
  await client.quit();
};

seed().catch(console.error);