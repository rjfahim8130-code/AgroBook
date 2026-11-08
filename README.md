# Fariha Chat v5 — Split User / Admin

## Root files (no subfolders)
```
index.html
style.css
config.js
core.js
ads.js
user.js
admin.js
main.js
schema.sql
README.md
```

## Entry logic
- On load, Telegram ID is checked.
- **Admin ID** → only Admin UI (3 tabs)
- **Anyone else** → only User UI (3 tabs)
- No cross access. No admin button on user side.

## User tabs
1. **Chat** (default) — Fariha header, messages, gift icon beside input, message limits
2. **Balance** — coins + 3 ad options + tasks (only if admin added tasks)
3. **Profile** — info, referral link & stats

## Admin tabs
1. **Chat** (default) — user list, unread preferred on top, room + profile
2. **Control** — Ad settings · Tasks · Cleanup (7d messages + 14d inactive)
3. **History** — totals · Gift history (today + weekly top)

## Setup
1. Run `schema.sql` in Supabase
2. Upload all root files to GitHub Pages
3. Set `BOT_USERNAME` / `APP_SHORT_NAME` in `config.js`
