// ===================== APP CONFIG =====================
// শুধু এই ফাইল এডিট করলেই বেশিরভাগ সেটিংস পরিবর্তন হবে

window.APP_CONFIG = {
    // অ্যাডমিন টেলিগ্রাম আইডি (শুধু এই আইডি অ্যাডমিন অপশন দেখবে)
    ADMIN_IDS: [8251893998],

    // অ্যাপ নাম / ব্র্যান্ডিং
    APP_NAME: "ফারিহা জান্নাত",
    APP_SUBTITLE: "ফারিহার সাথে চ্যাট",

    // অ্যাডমিন/ওনার প্রোফাইল ছবি (ঐচ্ছিক — লিংক দিলে সবাই দেখবে)
    // খালি রাখলে অ্যাডমিন লগইন করলে তার টেলিগ্রাম ছবি ব্যবহার হবে
    OWNER_PHOTO_URL: "https://i.postimg.cc/wT0ZfTSB/file-00000000fcfc8211b04c6079c124233a.png",

    // Smartlinks (ব্যাকআপ রিওয়ার্ড)
    SMARTLINKS: {
        adsterra: "https://asiafilm.org/4/e3dcb84609e924772d39878b3dcaad11",
        hilltop:  "https://motionless-bus.com/HXrkS6"
    },

    // Monetag Zone (পরে যোগ করবেন)
    MONETAG_REWARDED_ZONE: "YOUR_REWARDED_ZONE_ID",
    MONETAG_INTERSTITIAL_ZONE: "YOUR_INTERSTITIAL_ZONE_ID",

    // কয়েন রেট
    COIN_REWARD: {
        monetag: 15,
        adsterra: 5,
        hilltop: 5
    },

    // দৈনিক লিমিট
    DAILY_LIMIT: {
        monetag: 10,
        adsterra: 3,
        hilltop: 3
    },

    // কুলডাউন (মিলিসেকেন্ড)
    COOLDOWN: {
        others: 60 * 1000,        // অন্যগুলো ১ মিনিট ডিজেবল
        self: 45 * 60 * 1000      // যেটা দেখল সেটা ৪৫ মিনিট ডিজেবল
    },

    // গিফট মিনিমাম
    MIN_GIFT: 10,

    // Supabase
    SUPABASE_URL: "https://bagscbfokioflnuyxcuz.supabase.co",
    SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhZ3NjYmZva2lvZmxudXl4Y3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0MjAxOTEsImV4cCI6MjEwODk5NjE5MX0.9iU1vhruNSO54Van2GIBM1OrofuUfplWtPC7O7cV60s"
};
