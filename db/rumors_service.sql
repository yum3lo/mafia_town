-- Create the rumors table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.rumors (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    category VARCHAR(255),
    "isActive" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add unique constraint if it does not exist
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

-- No initial mock data
-- Task rumors are auto-generated from the task service based on completed mafia tasks

