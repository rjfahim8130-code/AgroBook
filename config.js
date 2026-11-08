window.APP_CONFIG = {
  ADMIN_IDS: [8251893998],
  APP_NAME: "Fariha Jannat",
  BOT_USERNAME: "farihajnnat_bot",
  APP_SHORT_NAME: "app",
  OWNER_PHOTO_URL: "",

  SMARTLINKS: {
    adsterra: "https://asiafilm.org/4/e3dcb84609e924772d39878b3dcaad11",
    hilltop: "https://motionless-bus.com/HXrkS6"
  },

  MONETAG_SHOW_FN: "show_12212096",

  ADSGRAM: {
    rewardedBlockId: "58681",
    interstitialBlockId: "int-58682",
    taskBlockId: "task-58683"
  },

  COIN_REWARD: { adsgram: 15, monetag: 15, adsterra: 8, hilltop: 8 },
  DAILY_LIMIT: { adsgram: 12, monetag: 10, adsterra: 6, hilltop: 6 },
  COOLDOWN: { others: 60 * 1000, self: 45 * 60 * 1000 },

  // Adsgram Rewarded (coins primary)
  ADSGRAM_REWARDED: {
    dailyMax: 12,
    streakMax: 3,
    betweenCdMin: 2,
    streakCdMin: 60,
    coins: 15
  },

  // Monetag Rewarded Interstitial (coins backup)
  REWARDED: {
    dailyMax: 15,
    streakMax: 3,
    betweenCdMin: 1,
    streakCdMin: 60,
    coins: 15
  },

  // Monetag Popup = coins only
  POPUP: {
    dailyMax: 10,
    streakMax: 3,
    betweenCdMin: 2,
    streakCdMin: 60,
    coins: 12
  },

  // In-app Interstitial
  INTERSTITIAL: {
    frequency: 2,
    cappingHours: 0.1,
    intervalSec: 30,
    timeoutSec: 5
  },

  CHAT: {
    freePerDay: 999999,     // chat fully free
    coinsPerMessage: 0,
    minCoinsToChat: 0
  },

  REFER_PERCENT: 25,
  DEFAULT_TASKS: [],
  MIN_GIFT: 10,
  COINS_PER_MESSAGE: 1,  // admin can change

  SUPABASE_URL: "https://bagscbfokioflnuyxcuz.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhZ3NjYmZva2lvZmxudXl4Y3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0MjAxOTEsImV4cCI6MjEwODk5NjE5MX0.9iU1vhruNSO54Van2GIBM1OrofuUfplWtPC7O7cV60s"
};
