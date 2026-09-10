# At the Table

An offline-first shared-household meal-planning prototype.

## Run locally

```bash
cd /home/nik/.openclaw/workspace
python3 -m http.server 4173 --directory meal-planner
```

Open `http://localhost:4173` in a browser. Data is stored locally in that browser.

## Included now

- Preset meal library and daily random plan by Breakfast, Snack, Lunch, and Dinner
- Reroll a single slot without changing the whole day
- Pantry-based meal ranking
- Editable pregnancy exclusion filter, seeded with dates, papaya, and flax
- Forgiving bulk-paste meal import
- Installable PWA shell

## Next implementation increment

Replace browser-local data with a hosted database plus authentication and household invitations, enabling Nik and Meg to see immediate shared updates across their devices.
