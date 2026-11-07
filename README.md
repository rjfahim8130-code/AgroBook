# ফারিহার সাথে চ্যাট — v3

## অ্যাড ফরম্যাট (৩টা)

| # | ফরম্যাট | কাজ |
|---|--------|-----|
| 1 | Monetag Rewarded Interstitial (`type: end`) | কয়েন (+15) |
| 2 | Monetag Rewarded Popup (`type: pop`) | চ্যাট মেসেজ লিমিট বাড়ানো (+20) |
| 3 | অটো Interstitial | প্রতি ~৫ মিনিট (কয়েন নেই) |

## চ্যাট লিমিট (ডিফল্ট)

- ফ্রি: **১০ মেসেজ/দিন**
- অ্যাড দেখলে: **+২০ মেসেজ**
- অ্যাডগুলোর মধ্যে গ্যাপ: **১৫ মিনিট**
- দিনে সর্বোচ্চ চ্যাট-অ্যাড: **৫বার**
- মোট সম্ভাব্য: ১০ + ১০০ = **১১০ মেসেজ/দিন**
- অ্যাডমিন: আনলিমিটেড

অ্যাডমিন প্যানেল থেকে সব মান পরিবর্তন করা যায়।

## অ্যাডমিন কন্ট্রোল

অ্যাডমিন প্যানেলে:
- Adsterra / Hilltop **অন-অফ**
- লিংক, কয়েন, দৈনিক লিমিট
- কুলডাউন টাইম
- চ্যাট ফ্রি/রিওয়ার্ড/কুলডাউন/ম্যাক্স অ্যাড

## Supabase টেবিল (সেটিংস সিঙ্কের জন্য)

```sql
create table if not exists app_settings (
  key text primary key,
  value jsonb,
  updated_at timestamptz default now()
);

-- RLS: anon read + write (বা শুধু admin policy)
alter table app_settings enable row level security;
create policy "allow all" on app_settings for all using (true) with check (true);
```

টেবিল না থাকলেও অ্যাডমিনের লোকাল সেশন কাজ করবে; অন্য ইউজার ডিফল্ট কনফিগ পাবে।

## Postback

GitHub Pages-এ সার্ভার নেই, তাই পুরো সার্ভার-সাইড postback আলাদা backend ছাড়া সম্ভব না।

বর্তমানে:
- Monetag SDK Promise resolve হলে কয়েন/মেসেজ দেওয়া হয়
- `ymid` পাস করা হয় (`coin_USERID_TIMESTAMP` / `chat_USERID_TIMESTAMP`)

পরে Cloudflare Worker / Vercel দিয়ে postback URL বসালে আরও সিকিউর হবে।

## Monetag ড্যাশবোর্ড

1. Rewarded Interstitial → Activate
2. Rewarded Popup → Activate  
3. In-app Interstitial → Activate (অটোর জন্য)

## ফাইল

```
index.html
admin.html
css/style.css
js/config.js
js/app.js
```
