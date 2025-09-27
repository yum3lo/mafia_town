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

-- Insert initial rumors only if table is empty
INSERT INTO public.rumors (content, category)
SELECT val.content, val.category
FROM (VALUES
    ('The Doctor has been visiting the Mafia boss at night', 'role'),
    ('The Detective was seen talking to known criminals', 'role'),
    ('The Sheriff has been acting suspiciously around certain players', 'role'),
    ('A Mafia member was overheard planning their next move', 'role'),
    ('The Vigilante was seen sharpening their weapon', 'role'),
    ('Someone was spotted burying something in the park last night', 'task'),
    ('A player was seen cleaning blood off their hands', 'task'),
    ('Strange digging sounds were heard from the cemetery', 'task'),
    ('A player was caught disposing of suspicious evidence', 'task'),
    ('Someone was seen entering a house they don''t own', 'task'),
    ('Strange activities reported near the old warehouse', 'location'),
    ('Multiple people seen entering the abandoned building', 'location'),
    ('Unusual gatherings spotted at the town square', 'location'),
    ('Secret meetings observed behind the church', 'location'),
    ('Suspicious activity near the mayor''s office', 'location'),
    ('A player was seen wearing a bloody shirt yesterday', 'appearance'),
    ('Someone has been walking with a suspicious limp', 'appearance'),
    ('A player''s clothes smell strongly of chemicals', 'appearance'),
    ('Someone has unexplained scratches on their arms', 'appearance'),
    ('A player keeps nervously checking their pockets', 'appearance')
) AS val(content, category)
WHERE NOT EXISTS (SELECT 1 FROM public.rumors);
