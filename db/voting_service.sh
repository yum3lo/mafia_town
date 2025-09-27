set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "Running migrations for voting_service..."
python manage.py migrate --noinput

echo "Attempting to run management command seed_votes..."
if python - <<'PY'
from django.core.management import find_commands
print("commands:", find_commands('voting.management.commands'))
PY
then
  if python - <<'PY'
from django.core.management import call_command
try:
    call_command("seed_votes")
    print("seed_votes command ran")
except Exception as e:
    print("seed_votes failed:", e)
    raise SystemExit(1)
PY
  then
    echo "Seed done via seed_votes command."
    exit 0
  fi
fi

echo "Falling back to inline shell seeding..."
python manage.py shell <<'PY'
from voting.models import Round, Vote
from django.utils import timezone

if Round.objects.exists():
    print("Rounds exist, skipping fallback seed.")
else:
    r1 = Round.objects.create(game_id="game-AAA", name="Day 1 Vote", starts_at=timezone.now())
    r2 = Round.objects.create(game_id="game-AAA", name="Day 2 Vote", starts_at=timezone.now())
    Vote.objects.create(round=r1, user_id=1, voted_user_id=3)
    Vote.objects.create(round=r1, user_id=2, voted_user_id=1)
    Vote.objects.create(round=r2, user_id=3, voted_user_id=1)
    print("Seeded rounds and votes via fallback.")
PY

echo "voting_service DB population complete."
