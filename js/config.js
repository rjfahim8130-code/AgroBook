// ===================== APP CONFIG =====================
window.APP_CONFIG = {
    ADMIN_IDS: [8251893998],

    APP_NAME: "ফারিহা জান্নাত",
    APP_SUBTITLE: "ফারিহার সাথে চ্যাট",
    OWNER_PHOTO_URL: "",

    // ডিফল্ট Smartlinks (অ্যাডমিন প্যানেল থেকে ওভাররাইড করা যাবে)
    SMARTLINKS: {
        adsterra: "https://asiafilm.org/4/e3dcb84609e924772d39878b3dcaad11",
        hilltop:  "https://motionless-bus.com/HXrkS6"
    },

    // Monetag
    MONETAG_ZONE: "12212096",
    MONETAG_SHOW_FN: "show_12212096",

    // কয়েন রিওয়ার্ড (Monetag Rewarded Interstitial)
    COIN_REWARD: {
        monetag: 15,
        adsterra: 8,
        hilltop: 8
    },

    // কয়েন অ্যাড দৈনিক লিমিট
    DAILY_LIMIT: {
        monetag: 10,
        adsterra: 6,
        hilltop: 6
    },

    // কয়েন অ্যাড কুলডাউন
    COOLDOWN: {
        others: 60 * 1000,
        self: 45 * 60 * 1000
    },

    // ===== চ্যাট লিমিট সিস্টেম =====
    // ফ্রি মেসেজ/দিন → শেষ হলে Rewarded Popup
    // প্রতি অ্যাডে +২০ মেসেজ, ১৫ মিনিট গ্যাপ, দিনে সর্বোচ্চ ৫বার
    // মোট সম্ভাব্য: ১০ + (২০×৫) = ১১০ মেসেজ/দিন
    CHAT: {
        freePerDay: 10,
        rewardPerAd: 20,
        adCooldownMs: 15 * 60 * 1000,
        maxAdsPerDay: 5
    },

    // অটো ইন্টারস্টিশিয়াল (মিনিট) — রিওয়ার্ড নেই
    AUTO_INTERSTITIAL_MINUTES: 5,

    MIN_GIFT: 10,

    SUPABASE_URL: "https://bagscbfokioflnuyxcuz.supabase.co",
    SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhZ3NjYmZva2lvZmxudXl4Y3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0MjAxOTEsImV4cCI6MjEwODk5NjE5MX0.9iU1vhruNSO54Van2GIBM1OrofuUfplWtPC7O7cV60s"
};
