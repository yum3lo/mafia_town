set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT"

echo "Running migrations for task_service..."
python manage.py migrate --noinput

echo "Attempting to run management command seed_tasks..."
if python -c "import importlib, pkgutil, sys; print('ok')" 2>/dev/null; then
  if python - <<PY 2>/dev/null
import sys
from django.core.management import find_commands, load_command_class
commands = find_commands('tasks.management.commands')
print('commands', commands)
PY
  then
    if python - <<'PY'
import sys
from django.core.management import call_command
try:
    call_command("seed_tasks")
    print("seed_tasks command ran")
except Exception as e:
    print("seed_tasks failed:", e)
    raise SystemExit(1)
PY
    then
      echo "Seed done via seed_tasks command."
      exit 0
    fi
  fi
fi

echo "Falling back to inline shell seeding..."
python manage.py shell <<'PY'
from tasks.models import Task
samples = [
    {"role": "cop", "task_description": "Perform a routine checkup on locations x, y and z."},
    {"role": "doctor", "task_description": "Perform a physical on player 12."},
    {"role": "investigator", "task_description": "Interview witness at location 7."},
    {"role": "cop", "task_description": "Patrol sector 5 between 20:00-22:00."}
]
if Task.objects.exists():
    print("Tasks exist, skipping fallback seed.")
else:
    for s in samples:
        Task.objects.create(**s)
    print("Seeded tasks via fallback.")
PY

echo "task_service DB population complete."
