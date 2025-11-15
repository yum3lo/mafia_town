CREATE TABLE IF NOT EXISTS public.rumors (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    category VARCHAR(255),
    "isActive" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.player_rumors (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    "playerId" TEXT NOT NULL,
    "rumorId" TEXT NOT NULL,
    "gameId" TEXT NOT NULL,
    "purchasedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "spentCurrency" INTEGER NOT NULL,
    CONSTRAINT fk_rumor FOREIGN KEY ("rumorId") REFERENCES public.rumors(id) ON DELETE CASCADE,
    CONSTRAINT player_rumor_unique UNIQUE ("playerId", "rumorId", "gameId")
);

CREATE INDEX IF NOT EXISTS idx_player_rumors_playerId ON public.player_rumors("playerId");
CREATE INDEX IF NOT EXISTS idx_player_rumors_gameId ON public.player_rumors("gameId");
CREATE INDEX IF NOT EXISTS idx_player_rumors_rumorId ON public.player_rumors("rumorId");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'rumors_content_unique'
    ) THEN
        ALTER TABLE public.rumors
        ADD CONSTRAINT rumors_content_unique UNIQUE (content);
    END IF;
END
$$;

-- No initial mock data, populated by: 
-- Task rumors are auto-generated from the task service based on completed mafia tasks
-- Appearance rumors based of still open tasks\
-- Location rumors based on movements

