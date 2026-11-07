# Fariha Chat v4.1

## Files (root only)
```
index.html
style.css
config.js
app.js
schema.sql
README.md
```

## Referral — how it works
1. User A shares: `https://t.me/BOT/app?startapp=ref_A_ID`
2. User B opens link → saved in `users.referrer_id = A`
3. Every time A opens Invite screen, app counts B's (and other referrals') **user** messages
4. Bonus = floor(total_referral_messages × 25%)
5. Bonus is added to A's chat message quota

Example: referrals sent 200 messages → A gets +50 free messages.

## Tasks
- Admin can **add unlimited tasks** (Telegram / Facebook / TikTok / any URL)
- Each task: title, URL, coin reward, message reward, on/off
- On complete: coins + free messages granted once (stored in `task_completions`)
- Multiple channel/follow tasks supported

## Admin cleanup (one click)
- **7 days**: delete old messages
- **14 days inactive**: delete user + messages + gifts + task_completions

## Setup
1. Run `schema.sql` in Supabase SQL Editor
2. Upload all root files to GitHub Pages
3. Edit `config.js` → `BOT_USERNAME`, `APP_SHORT_NAME`
4. Open mini app as admin → set task URLs → Save
