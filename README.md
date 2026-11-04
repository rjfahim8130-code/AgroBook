# ফারিহার সাথে চ্যাট — Telegram Mini App (Fixed)

## ফাইল

| ফাইল | কাজ |
|------|-----|
| `index.html` | মূল মিনি অ্যাপ (ইউজার) |
| `admin.html` | অ্যাডমিন প্যানেল (রিপ্লাই + গিফট দেখা) |

## লাইভ লিংক (আপলোডের পর)

- মিনি অ্যাপ: `https://rjfahim8130-code.github.io/AgroBook/`
- অ্যাডমিন: `https://rjfahim8130-code.github.io/AgroBook/admin.html`

## অ্যাডমিন পিন

ডিফল্ট পিন: **`1234`**

`admin.html` ফাইলে এই লাইন পরিবর্তন করুন:
```js
const ADMIN_PIN = "1234";
```

## স্মার্টলিংক (সেট করা আছে)

- Adsterra: `https://asiafilm.org/4/e3dcb84609e924772d39878b3dcaad11`
- HilltopAds: `https://motionless-bus.com/HXrkS6`

## ঠিক করা সমস্যা

1. চ্যাট ইনপুট বক্স বটম নেভবারের নিচে চাপা পড়ছিল → ঠিক করা হয়েছে
2. অ্যাডমিন রিপ্লাই দেওয়ার কোনো উপায় ছিল না → `admin.html` যোগ করা হয়েছে
3. খালি চ্যাট স্টেট দেখানো হয়
4. Optimistic UI (মেসেজ পাঠানোর সাথে সাথে দেখায়)

## Monetag

এখনো SDK যোগ করা হয়নি। পরে Zone ID দিলে যোগ করা যাবে।

## Supabase টেবিল

### messages
```sql
user_id (bigint)
user_name (text)
message (text)
sender_type (text)  -- 'user' বা 'admin'
created_at (timestamptz)
```

### gifts (ঐচ্ছিক)
```sql
user_id (bigint)
user_name (text)
amount (int)
created_at (timestamptz)
```
