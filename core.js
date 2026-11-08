window.Core = (function () {
  const CFG = window.APP_CONFIG;
  const tg = window.Telegram?.WebApp;
  if (tg) {
    tg.ready();
    tg.expand();
    try {
      tg.setHeaderColor("#16161a");
      tg.setBackgroundColor("#0c0c0e");
    } catch (e) {}
  }

  const user = tg?.initDataUnsafe?.user || null;
  const userId = user ? Number(user.id) : 0;
  const userName = user
    ? user.first_name + (user.last_name ? " " + user.last_name : "")
    : "Guest";
  const userHandle = user?.username ? "@" + user.username : "—";
  const userPhoto = user?.photo_url || null;
  const isAdmin = CFG.ADMIN_IDS.includes(userId);

  let referrerId = null;
  try {
    const sp = tg?.initDataUnsafe?.start_param
      || new URLSearchParams(location.search).get("tgWebAppStartParam")
      || "";
    if (sp && String(sp).startsWith("ref_")) {
      referrerId = parseInt(String(sp).replace("ref_", ""), 10) || null;
      if (referrerId === userId) referrerId = null;
    }
  } catch (e) {}

  const db = supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY);

  const state = {
    settings: {
      smartlinks: { ...CFG.SMARTLINKS },
      smartlinkEnabled: { adsterra: true, hilltop: true },
      coinReward: { ...CFG.COIN_REWARD },
      dailyLimit: { ...CFG.DAILY_LIMIT },
      cooldown: { ...CFG.COOLDOWN },
      chat: { ...CFG.CHAT },
      tasks: JSON.parse(JSON.stringify(CFG.DEFAULT_TASKS || [])),
      referPercent: CFG.REFER_PERCENT
    },
    coins: 0,
    totalEarned: 0,
    totalGifted: 0,
    todayCount: { monetag: 0, adsterra: 0, hilltop: 0 },
    cooldownUntil: { monetag: 0, adsterra: 0, hilltop: 0 },
    chatUsed: 0,
    chatBonus: 0,
    chatAdsToday: 0,
    chatAdCooldownUntil: 0,
    referBonusMsgs: 0,
    completedTasks: {},
    myReferrals: 0,
    refMsgTotal: 0
  };

  const LS = "fj_v5_" + userId;
  const today = () => new Date().toDateString();

  function loadState() {
    try {
      const d = JSON.parse(localStorage.getItem(LS) || "{}");
      state.coins = d.coins || 0;
      state.totalEarned = d.totalEarned || 0;
      state.totalGifted = d.totalGifted || 0;
      state.completedTasks = d.completedTasks || {};
      state.referBonusMsgs = d.referBonusMsgs || 0;
      if (d.date === today()) {
        state.todayCount = d.todayCount || state.todayCount;
        state.chatUsed = d.chatUsed || 0;
        state.chatBonus = d.chatBonus || 0;
        state.chatAdsToday = d.chatAdsToday || 0;
      }
      if (d.cooldownUntil) {
        const now = Date.now();
        Object.keys(d.cooldownUntil).forEach(k => {
          if (d.cooldownUntil[k] > now) state.cooldownUntil[k] = d.cooldownUntil[k];
        });
      }
      if (d.chatAdCooldownUntil > Date.now()) state.chatAdCooldownUntil = d.chatAdCooldownUntil;
    } catch (e) {}
  }

  function saveState() {
    localStorage.setItem(LS, JSON.stringify({
      coins: state.coins,
      totalEarned: state.totalEarned,
      totalGifted: state.totalGifted,
      todayCount: state.todayCount,
      cooldownUntil: state.cooldownUntil,
      chatUsed: state.chatUsed,
      chatBonus: state.chatBonus,
      chatAdsToday: state.chatAdsToday,
      chatAdCooldownUntil: state.chatAdCooldownUntil,
      completedTasks: state.completedTasks,
      referBonusMsgs: state.referBonusMsgs,
      date: today()
    }));
  }

  function chatRemaining() {
    if (isAdmin) return 99999;
    const s = state.settings.chat;
    return Math.max(0, s.freePerDay + state.chatBonus + state.referBonusMsgs - state.chatUsed);
  }

  function showToast(msg) {
    const t = document.getElementById("toast");
    if (!t) return;
    t.textContent = msg;
    t.classList.add("show");
    setTimeout(() => t.classList.remove("show"), 2800);
  }

  function esc(s) {
    return String(s || "")
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }

  function formatRemain(ms) {
    if (ms <= 0) return "";
    const s = Math.ceil(ms / 1000);
    return s < 60 ? s + "s" : Math.ceil(s / 60) + "m";
  }

  function showMonetag(opts) {
    const fn = window[CFG.MONETAG_SHOW_FN];
    if (typeof fn !== "function") return Promise.reject(new Error("SDK missing"));
    return fn(opts);
  }

  function applyCooldown(clicked) {
    const now = Date.now();
    const cd = state.settings.cooldown;
    ["monetag", "adsterra", "hilltop"].forEach(k => {
      if (k === clicked) state.cooldownUntil[k] = now + cd.self;
      else {
        const o = now + cd.others;
        if (state.cooldownUntil[k] < o) state.cooldownUntil[k] = o;
      }
    });
    saveState();
  }

  function addCoins(amount, source) {
    state.coins += amount;
    state.totalEarned += amount;
    if (state.todayCount[source] !== undefined) state.todayCount[source]++;
    saveState();
    showToast("+" + amount + " coins!");
  }

  async function loadRemoteSettings() {
    try {
      const { data } = await db.from("app_settings")
        .select("value").eq("key", "main").maybeSingle();
      if (!data?.value) return;
      const v = data.value;
      const s = state.settings;
      if (v.smartlinks) Object.assign(s.smartlinks, v.smartlinks);
      if (v.smartlinkEnabled) Object.assign(s.smartlinkEnabled, v.smartlinkEnabled);
      if (v.coinReward) Object.assign(s.coinReward, v.coinReward);
      if (v.dailyLimit) Object.assign(s.dailyLimit, v.dailyLimit);
      if (v.cooldown) {
        s.cooldown.self = (v.cooldown.selfMin || 45) * 60000;
        s.cooldown.others = (v.cooldown.othersMin || 1) * 60000;
      }
      if (v.chat) {
        s.chat.freePerDay = v.chat.freePerDay ?? s.chat.freePerDay;
        s.chat.rewardPerAd = v.chat.rewardPerAd ?? s.chat.rewardPerAd;
        s.chat.adCooldownMs = (v.chat.adCooldownMin || 15) * 60000;
        s.chat.maxAdsPerDay = v.chat.maxAdsPerDay ?? s.chat.maxAdsPerDay;
      }
      if (Array.isArray(v.tasks)) s.tasks = v.tasks;
      if (v.referPercent != null) s.referPercent = v.referPercent;
    } catch (e) {}
  }

  async function registerUser() {
    if (!userId) return;
    try {
      const { data: existing } = await db.from("users")
        .select("user_id, referrer_id").eq("user_id", userId).maybeSingle();
      if (!existing) {
        await db.from("users").insert([{
          user_id: userId,
          user_name: userName,
          username: user?.username || null,
          referrer_id: referrerId,
          last_active: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }]);
      } else {
        await db.from("users").update({
          user_name: userName,
          username: user?.username || null,
          last_active: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }).eq("user_id", userId);
      }
    } catch (e) {}
  }

  async function loadCompletedTasks() {
    try {
      const { data } = await db.from("task_completions")
        .select("task_id").eq("user_id", userId);
      (data || []).forEach(r => { state.completedTasks[r.task_id] = true; });
      saveState();
    } catch (e) {}
  }

  function getReferLink() {
    return `https://t.me/${CFG.BOT_USERNAME}/${CFG.APP_SHORT_NAME}?startapp=ref_${userId}`;
  }

  async function refreshReferStats() {
    try {
      const { data: refs } = await db.from("users").select("user_id").eq("referrer_id", userId);
      state.myReferrals = (refs || []).length;
      if (!state.myReferrals) {
        state.refMsgTotal = 0;
        return;
      }
      const ids = refs.map(r => r.user_id);
      const { count } = await db.from("messages")
        .select("*", { count: "exact", head: true })
        .in("user_id", ids)
        .eq("sender_type", "user");
      state.refMsgTotal = count || 0;
      const earned = Math.floor(state.refMsgTotal * (state.settings.referPercent || 25) / 100);
      if (earned !== state.referBonusMsgs) {
        state.referBonusMsgs = earned;
        saveState();
      }
    } catch (e) {}
  }

  function ownerAvatarHtml() {
    if (CFG.OWNER_PHOTO_URL) {
      return `<img class="avatar" src="${CFG.OWNER_PHOTO_URL}" alt="">`;
    }
    return `<div class="avatar ph">F</div>`;
  }

  function startAutoInterstitial() {
    if (isAdmin) return;
    try {
      showMonetag({
        type: "inApp",
        inAppSettings: { frequency: 2, capping: 0.1, interval: 30, timeout: 5, everyPage: false }
      }).catch(() => {});
    } catch (e) {}
  }

  return {
    CFG, tg, db, user, userId, userName, userHandle, userPhoto, isAdmin, referrerId,
    state, loadState, saveState, chatRemaining, showToast, esc, formatRemain,
    showMonetag, applyCooldown, addCoins, loadRemoteSettings, registerUser,
    loadCompletedTasks, getReferLink, refreshReferStats, ownerAvatarHtml,
    startAutoInterstitial
  };
})();
