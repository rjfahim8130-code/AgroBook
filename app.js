(function () {
  const CFG = window.APP_CONFIG;
  const tg = window.Telegram?.WebApp;
  if (tg) {
    tg.ready();
    tg.expand();
    try { tg.setHeaderColor("#1a1a1a"); tg.setBackgroundColor("#0f0f0f"); } catch (e) {}
  }

  const user = tg?.initDataUnsafe?.user || null;
  const userId = user ? Number(user.id) : 99999999;
  const userName = user ? (user.first_name + (user.last_name ? " " + user.last_name : "")) : "Guest";
  const userHandle = user?.username ? "@" + user.username : "—";
  const userPhoto = user?.photo_url || null;
  const isAdmin = CFG.ADMIN_IDS.includes(userId);

  // Referral from startapp=ref_123
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

  let settings = {
    smartlinks: { ...CFG.SMARTLINKS },
    smartlinkEnabled: { adsterra: true, hilltop: true },
    coinReward: { ...CFG.COIN_REWARD },
    dailyLimit: { ...CFG.DAILY_LIMIT },
    cooldown: { ...CFG.COOLDOWN },
    chat: { ...CFG.CHAT },
    tasks: JSON.parse(JSON.stringify(CFG.DEFAULT_TASKS)),
    referPercent: CFG.REFER_PERCENT
  };

  let coins = 0, totalEarned = 0, totalGifted = 0;
  let todayCount = { monetag: 0, adsterra: 0, hilltop: 0 };
  let cooldownUntil = { monetag: 0, adsterra: 0, hilltop: 0 };
  let chatUsed = 0, chatBonus = 0, chatAdsToday = 0, chatAdCooldownUntil = 0;
  let referBonusMsgs = 0;
  let completedTasks = {};
  let myReferrals = 0;
  let refMsgTotal = 0;

  const LS = `fj_v4_${userId}`;
  const today = () => new Date().toDateString();
  const $ = (id) => document.getElementById(id);

  function loadState() {
    try {
      const d = JSON.parse(localStorage.getItem(LS) || "{}");
      coins = d.coins || 0;
      totalEarned = d.totalEarned || 0;
      totalGifted = d.totalGifted || 0;
      completedTasks = d.completedTasks || {};
      referBonusMsgs = d.referBonusMsgs || 0;
      if (d.date === today()) {
        todayCount = d.todayCount || todayCount;
        chatUsed = d.chatUsed || 0;
        chatBonus = d.chatBonus || 0;
        chatAdsToday = d.chatAdsToday || 0;
      }
      if (d.cooldownUntil) {
        const now = Date.now();
        Object.keys(d.cooldownUntil).forEach(k => {
          if (d.cooldownUntil[k] > now) cooldownUntil[k] = d.cooldownUntil[k];
        });
      }
      if (d.chatAdCooldownUntil > Date.now()) chatAdCooldownUntil = d.chatAdCooldownUntil;
    } catch (e) {}
  }

  function saveState() {
    localStorage.setItem(LS, JSON.stringify({
      coins, totalEarned, totalGifted, todayCount, cooldownUntil,
      chatUsed, chatBonus, chatAdsToday, chatAdCooldownUntil,
      completedTasks, referBonusMsgs, date: today()
    }));
  }

  function chatRemaining() {
    if (isAdmin) return 99999;
    return Math.max(0, settings.chat.freePerDay + chatBonus + referBonusMsgs - chatUsed);
  }

  function showToast(msg) {
    const t = $("toast");
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

  function updateUI() {
    if ($("coin-balance")) $("coin-balance").textContent = coins;
    if ($("gift-balance")) $("gift-balance").textContent = coins;
    if ($("stat-balance")) $("stat-balance").textContent = coins;
    if ($("stat-earned")) $("stat-earned").textContent = totalEarned;
    if ($("stat-gifted")) $("stat-gifted").textContent = totalGifted;
    if ($("stat-refer")) $("stat-refer").textContent = myReferrals;
    if ($("stat-refer-msgs")) $("stat-refer-msgs").textContent = referBonusMsgs;

    const rem = chatRemaining();
    document.querySelectorAll(".chat-limit-badge").forEach(el => {
      el.textContent = isAdmin ? "∞" : String(rem);
    });
    if ($("chat-limit-info")) {
      $("chat-limit-info").textContent = isAdmin
        ? "Admin — unlimited"
        : `Left: ${rem} (free ${settings.chat.freePerDay} + bonus ${chatBonus} + refer ${referBonusMsgs})`;
    }
    if ($("limit-info")) {
      $("limit-info").textContent =
        `Ads today: M ${todayCount.monetag}/${settings.dailyLimit.monetag} · A ${todayCount.adsterra}/${settings.dailyLimit.adsterra} · H ${todayCount.hilltop}/${settings.dailyLimit.hilltop}`;
    }
    updateAdButtons();
    updateChatModalInfo();
    renderTasks();
    renderReferBox();
  }

  function formatRemain(ms) {
    if (ms <= 0) return "";
    const s = Math.ceil(ms / 1000);
    return s < 60 ? s + "s" : Math.ceil(s / 60) + "m";
  }

  function updateAdButtons() {
    const now = Date.now();
    ["monetag", "adsterra", "hilltop"].forEach(key => {
      const btn = $("btn-" + key);
      if (!btn) return;
      const cdEl = btn.querySelector(".cd-text");
      let disabled = false, reason = "";
      if (key !== "monetag" && settings.smartlinkEnabled[key] === false) {
        disabled = true; reason = "Off";
      } else if (todayCount[key] >= (settings.dailyLimit[key] || 0)) {
        disabled = true; reason = "Limit";
      } else if (cooldownUntil[key] > now) {
        disabled = true; reason = formatRemain(cooldownUntil[key] - now);
      }
      btn.disabled = disabled;
      if (cdEl) {
        cdEl.textContent = reason;
        cdEl.style.display = reason ? "block" : "none";
      }
    });
  }
  setInterval(updateAdButtons, 1000);

  function applyCooldown(clicked) {
    const now = Date.now();
    ["monetag", "adsterra", "hilltop"].forEach(k => {
      if (k === clicked) cooldownUntil[k] = now + settings.cooldown.self;
      else {
        const o = now + settings.cooldown.others;
        if (cooldownUntil[k] < o) cooldownUntil[k] = o;
      }
    });
    saveState();
    updateAdButtons();
  }

  function addCoins(amount, source) {
    coins += amount;
    totalEarned += amount;
    if (todayCount[source] !== undefined) todayCount[source]++;
    saveState();
    updateUI();
    showToast("+" + amount + " coins!");
  }

  // ===== MONETAG =====
  function showMonetag(opts) {
    const fn = window[CFG.MONETAG_SHOW_FN];
    if (typeof fn !== "function") return Promise.reject(new Error("SDK missing"));
    return fn(opts);
  }

  window.watchMonetagRewarded = function () {
    if (isAdmin) return;
    if (todayCount.monetag >= settings.dailyLimit.monetag) return showToast("Daily limit");
    if (Date.now() < cooldownUntil.monetag) return showToast("Cooldown");
    const btn = $("btn-monetag");
    if (btn) btn.disabled = true;
    showMonetag()
      .then(() => {
        applyCooldown("monetag");
        addCoins(settings.coinReward.monetag, "monetag");
      })
      .catch(() => {
        showToast("Ad failed");
        updateAdButtons();
      });
  };

  window.watchChatLimitAd = function () {
    if (isAdmin) return;
    if (chatAdsToday >= settings.chat.maxAdsPerDay) return showToast("Chat ad limit today");
    if (Date.now() < chatAdCooldownUntil) return showToast("Wait " + formatRemain(chatAdCooldownUntil - Date.now()));
    showMonetag("pop")
      .then(() => {
        chatBonus += settings.chat.rewardPerAd;
        chatAdsToday++;
        chatAdCooldownUntil = Date.now() + settings.chat.adCooldownMs;
        saveState();
        updateUI();
        hideChatLimitModal();
        showToast("+" + settings.chat.rewardPerAd + " messages!");
      })
      .catch(() => showToast("Ad failed"));
  };

  window.openSmartlink = function (network) {
    if (isAdmin) return;
    if (settings.smartlinkEnabled[network] === false) return showToast("Disabled");
    if (!settings.smartlinks[network]) return;
    if (todayCount[network] >= settings.dailyLimit[network]) return showToast("Limit");
    if (Date.now() < cooldownUntil[network]) return showToast("Cooldown");
    applyCooldown(network);
    const url = settings.smartlinks[network];
    if (tg?.openLink) tg.openLink(url);
    else window.open(url, "_blank");
    setTimeout(() => addCoins(settings.coinReward[network] || 8, network), 1800);
  };

  function startAutoInterstitial() {
    if (isAdmin) return;
    try {
      showMonetag({
        type: "inApp",
        inAppSettings: { frequency: 2, capping: 0.1, interval: 30, timeout: 5, everyPage: false }
      }).catch(() => {});
    } catch (e) {}
  }

  // ===== MODAL =====
  function showChatLimitModal() { $("chat-limit-modal")?.classList.add("show"); }
  function hideChatLimitModal() { $("chat-limit-modal")?.classList.remove("show"); }
  window.hideChatLimitModal = hideChatLimitModal;

  function updateChatModalInfo() {
    const el = $("modal-chat-info");
    if (!el) return;
    const left = settings.chat.maxAdsPerDay - chatAdsToday;
    const cd = chatAdCooldownUntil > Date.now()
      ? "Next in " + formatRemain(chatAdCooldownUntil - Date.now())
      : "Available now";
    el.innerHTML = `+${settings.chat.rewardPerAd} msgs/ad · Left today: <b>${left}</b> · ${cd}`;
  }

  // ===== GIFT =====
  window.setGiftAmount = function (v) { if ($("gift-amount")) $("gift-amount").value = v; };
  window.sendGift = async function () {
    const amount = parseInt($("gift-amount")?.value, 10);
    if (!amount || amount < CFG.MIN_GIFT) return showToast("Min " + CFG.MIN_GIFT);
    if (amount > coins) return showToast("Not enough coins");
    coins -= amount;
    totalGifted += amount;
    saveState();
    updateUI();
    $("gift-amount").value = "";
    showToast(amount + " gifted!");
    try {
      await db.from("gifts").insert([{ user_id: userId, user_name: userName, amount }]);
    } catch (e) {}
  };

  // ===== TASKS (dynamic list) =====
  function renderTasks() {
    const box = $("tasks-list");
    if (!box) return;
    const tasks = (settings.tasks || []).filter(t => t.enabled !== false);
    if (!tasks.length) {
      box.innerHTML = '<div class="empty-chat">No tasks right now</div>';
      return;
    }
    box.innerHTML = tasks.map(t => {
      const done = !!completedTasks[t.id];
      return `<div class="task-card ${done ? "done" : ""}">
        <div class="task-info">
          <div class="task-title">${esc(t.title)}</div>
          <div class="task-reward">+${t.rewardCoins || 0} coins · +${t.rewardMsgs || 0} msgs</div>
        </div>
        <button class="task-btn" ${done ? "disabled" : ""} onclick="doTask('${esc(t.id)}')">${done ? "Done ✓" : "Go"}</button>
      </div>`;
    }).join("");
  }

  window.doTask = async function (taskId) {
    if (completedTasks[taskId]) return;
    const t = (settings.tasks || []).find(x => x.id === taskId);
    if (!t) return;
    if (t.url && t.url.length > 8) {
      if (tg?.openLink) tg.openLink(t.url);
      else window.open(t.url, "_blank");
    }
    setTimeout(async () => {
      if (completedTasks[taskId]) return;
      completedTasks[taskId] = true;
      if (t.rewardCoins) {
        coins += t.rewardCoins;
        totalEarned += t.rewardCoins;
      }
      if (t.rewardMsgs) chatBonus += t.rewardMsgs;
      saveState();
      updateUI();
      showToast("Task reward claimed!");
      try {
        await db.from("task_completions").upsert({
          user_id: userId,
          task_id: taskId,
          completed_at: new Date().toISOString()
        }, { onConflict: "user_id,task_id" });
      } catch (e) {}
    }, 2500);
  };

  // Load completed tasks from server (sync across devices)
  async function loadCompletedTasks() {
    try {
      const { data } = await db.from("task_completions")
        .select("task_id")
        .eq("user_id", userId);
      (data || []).forEach(r => { completedTasks[r.task_id] = true; });
      saveState();
    } catch (e) {}
  }

  // ===== REFER =====
  function getReferLink() {
    const bot = CFG.BOT_USERNAME || "farihajnnat_bot";
    const app = CFG.APP_SHORT_NAME || "app";
    return `https://t.me/${bot}/${app}?startapp=ref_${userId}`;
  }

  function renderReferBox() {
    if ($("refer-link-text")) $("refer-link-text").textContent = getReferLink();
    if ($("refer-stats")) {
      $("refer-stats").innerHTML =
        `Referrals: <b>${myReferrals}</b> · Their messages: <b>${refMsgTotal}</b><br>` +
        `Your bonus msgs (25%): <b style="color:var(--gold)">${referBonusMsgs}</b>`;
    }
  }

  window.copyReferLink = function () {
    const link = getReferLink();
    if (navigator.clipboard) navigator.clipboard.writeText(link).then(() => showToast("Copied!"));
    else showToast(link);
  };

  async function registerUser() {
    try {
      // Only set referrer_id if user is new (don't overwrite existing)
      const { data: existing } = await db.from("users")
        .select("user_id, referrer_id")
        .eq("user_id", userId)
        .maybeSingle();

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
    } catch (e) {
      console.log("registerUser", e);
    }
  }

  async function refreshReferStats() {
    try {
      const { data: refs } = await db.from("users")
        .select("user_id")
        .eq("referrer_id", userId);

      myReferrals = (refs || []).length;
      if (!myReferrals) {
        refMsgTotal = 0;
        updateUI();
        return;
      }

      const ids = refs.map(r => r.user_id);
      // Count user messages from all referrals
      const { count } = await db.from("messages")
        .select("*", { count: "exact", head: true })
        .in("user_id", ids)
        .eq("sender_type", "user");

      refMsgTotal = count || 0;
      const earned = Math.floor(refMsgTotal * (settings.referPercent || 25) / 100);
      // Store the computed bonus (can grow as referrals chat more)
      if (earned !== referBonusMsgs) {
        referBonusMsgs = earned;
        saveState();
      }
      updateUI();
    } catch (e) {
      console.log("refer stats", e);
    }
  }

  // ===== NAV =====
  window.switchScreen = function (id) {
    document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
    $(id)?.classList.add("active");
    const map = {
      "screen-home": "nav-home",
      "screen-earn": "nav-earn",
      "screen-chat": "nav-chat",
      "screen-profile": "nav-profile",
      "screen-tasks": "nav-earn",
      "screen-gift": "nav-home",
      "screen-admin": "nav-home",
      "screen-refer": "nav-profile"
    };
    if (map[id]) $(map[id])?.classList.add("active");
    if (id === "screen-chat") {
      loadMessages();
      setTimeout(scrollToBottom, 120);
      updateUI();
    }
    if (id === "screen-gift" && $("gift-balance")) $("gift-balance").textContent = coins;
    if (id === "screen-tasks") renderTasks();
    if (id === "screen-refer") {
      renderReferBox();
      refreshReferStats();
    }
    if (id === "screen-admin" && isAdmin) {
      loadAdminPanel();
      loadAdminSettingsForm();
      renderAdminTaskEditor();
    }
  };

  // ===== PROFILE =====
  function initProfile() {
    if ($("profile-name")) {
      $("profile-name").innerHTML = userName + (isAdmin ? ' <span class="admin-badge">ADMIN</span>' : "");
    }
    if ($("profile-username")) $("profile-username").textContent = "Username: " + userHandle;
    if ($("profile-id")) $("profile-id").textContent = "ID: " + userId;
    const av = $("profile-avatar");
    if (av) {
      if (userPhoto) av.innerHTML = `<img src="${userPhoto}" alt="">`;
      else av.textContent = (userName[0] || "?").toUpperCase();
    }
    const photo = CFG.OWNER_PHOTO_URL || (isAdmin && userPhoto ? userPhoto : null);
    document.querySelectorAll(".header-avatar-slot").forEach(slot => {
      slot.innerHTML = photo
        ? `<img class="header-avatar" src="${photo}" alt="">`
        : `<div class="header-avatar placeholder">F</div>`;
    });
  }

  function applyAdminMode() {
    document.querySelectorAll(".admin-only").forEach(el => {
      if (isAdmin) el.classList.remove("hidden");
      else el.classList.add("hidden");
    });
    if (isAdmin) {
      const body = $("screen-earn")?.querySelector(".earn-body");
      if (body) {
        body.innerHTML = '<div class="earn-info" style="margin-top:40px;">Admin — ads disabled.</div>';
      }
    }
  }

  // ===== CHAT =====
  async function loadMessages() {
    const box = $("chat-container");
    if (!box) return;
    try {
      const { data } = await db.from("messages")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: true });
      box.innerHTML = "";
      if (!data?.length) {
        box.innerHTML = '<div class="empty-chat" id="empty-chat">No messages yet.<br>Say hello!</div>';
      } else {
        data.forEach(appendMessageUI);
      }
      scrollToBottom();
    } catch (e) {}
  }

  window.sendMessage = async function () {
    const input = $("message-input");
    const text = input?.value.trim();
    if (!text) return;
    if (!isAdmin && chatRemaining() <= 0) {
      showChatLimitModal();
      return;
    }
    input.value = "";
    $("empty-chat")?.remove();
    appendMessageUI({ message: text, sender_type: "user" });
    scrollToBottom();
    if (!isAdmin) {
      chatUsed++;
      saveState();
      updateUI();
    }
    // touch last_active
    try {
      await db.from("users").update({ last_active: new Date().toISOString() }).eq("user_id", userId);
    } catch (e) {}

    const { error } = await db.from("messages").insert([{
      user_id: userId,
      user_name: userName,
      message: text,
      sender_type: "user"
    }]);
    if (error) showToast("Send failed");
  };

  function appendMessageUI(msg) {
    const box = $("chat-container");
    if (!box) return;
    const div = document.createElement("div");
    div.className = "message " + (msg.sender_type === "user" ? "user-msg" : "admin-msg");
    div.textContent = msg.message;
    box.appendChild(div);
  }

  function scrollToBottom() {
    const box = $("chat-container");
    if (box) requestAnimationFrame(() => { box.scrollTop = box.scrollHeight; });
  }

  document.addEventListener("keydown", e => {
    if (e.key === "Enter" && document.activeElement?.id === "message-input") {
      e.preventDefault();
      window.sendMessage();
    }
  });

  db.channel("msg:" + userId).on("postgres_changes", {
    event: "INSERT", schema: "public", table: "messages",
    filter: `user_id=eq.${userId}`
  }, payload => {
    if (payload.new.sender_type === "admin") {
      $("empty-chat")?.remove();
      appendMessageUI(payload.new);
      scrollToBottom();
    }
  }).subscribe();

  // ===== ADMIN CHAT LIST =====
  let adminUid = null, adminUname = "";

  async function loadAdminPanel() {
    const list = $("admin-user-list");
    if (!list) return;
    list.innerHTML = '<div class="empty-chat">Loading...</div>';
    const { data, error } = await db.from("messages")
      .select("user_id, user_name, created_at")
      .order("created_at", { ascending: false })
      .limit(500);
    if (error) {
      list.innerHTML = '<div class="empty-chat">' + esc(error.message) + '</div>';
      return;
    }
    const map = {};
    (data || []).forEach(m => {
      if (!map[m.user_id]) {
        map[m.user_id] = {
          user_id: m.user_id,
          user_name: m.user_name || "?",
          count: 0,
          last_at: m.created_at
        };
      }
      map[m.user_id].count++;
    });
    const users = Object.values(map).sort((a, b) => new Date(b.last_at) - new Date(a.last_at));
    if (!users.length) {
      list.innerHTML = '<div class="empty-chat">No chats</div>';
      return;
    }
    list.innerHTML = users.map(u => `
      <div class="menu-btn" style="margin-bottom:8px" onclick="openAdminChat(${u.user_id}, '${esc(u.user_name).replace(/'/g, "\\'")}')">
        <div>
          <div style="font-weight:600">${esc(u.user_name)}</div>
          <div style="font-size:11px;color:var(--text2)">ID ${u.user_id} · ${u.count} msgs</div>
        </div>
        <span class="arrow">→</span>
      </div>`).join("");
  }

  window.openAdminChat = async function (uid, uname) {
    adminUid = uid;
    adminUname = uname;
    $("admin-chat-title").textContent = uname + " (" + uid + ")";
    $("admin-chat-panel").style.display = "flex";
    $("admin-user-list").style.display = "none";
    $("admin-settings-box")?.classList.add("hidden");
    $("admin-cleanup-box")?.classList.add("hidden");
    $("admin-task-editor")?.classList.add("hidden");
    const { data } = await db.from("messages")
      .select("*")
      .eq("user_id", uid)
      .order("created_at", { ascending: true });
    const box = $("admin-chat-messages");
    box.innerHTML = (data || []).map(m =>
      `<div class="message ${m.sender_type === "admin" ? "user-msg" : "admin-msg"}" style="align-self:${m.sender_type === "admin" ? "flex-end" : "flex-start"}">${esc(m.message)}</div>`
    ).join("") || '<div class="empty-chat">Empty</div>';
    box.scrollTop = box.scrollHeight;
  };

  window.closeAdminChat = function () {
    $("admin-chat-panel").style.display = "none";
    $("admin-user-list").style.display = "flex";
    $("admin-settings-box")?.classList.remove("hidden");
    $("admin-cleanup-box")?.classList.remove("hidden");
    $("admin-task-editor")?.classList.remove("hidden");
    adminUid = null;
    loadAdminPanel();
  };

  window.sendAdminReply = async function () {
    const input = $("admin-reply-input");
    const text = input?.value.trim();
    if (!text || !adminUid) return;
    input.value = "";
    const { error } = await db.from("messages").insert([{
      user_id: adminUid,
      user_name: adminUname,
      message: text,
      sender_type: "admin"
    }]);
    if (error) showToast("Failed");
    else {
      openAdminChat(adminUid, adminUname);
      showToast("Sent");
    }
  };

  // ===== ADMIN CLEANUP =====
  window.cleanupOldMessages = async function () {
    if (!isAdmin) return;
    if (!confirm("Delete ALL messages older than 7 days?")) return;
    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    try {
      const { error, count } = await db.from("messages")
        .delete({ count: "exact" })
        .lt("created_at", cutoff);
      if (error) showToast("Error: " + error.message);
      else {
        showToast("Old messages deleted");
        loadAdminPanel();
      }
    } catch (e) {
      showToast("Cleanup failed");
    }
  };

  window.cleanupInactiveUsers = async function () {
    if (!isAdmin) return;
    if (!confirm("Delete users inactive for 14+ days AND all their messages, gifts, tasks?")) return;
    const cutoff = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
    try {
      const { data: inactive } = await db.from("users")
        .select("user_id")
        .lt("last_active", cutoff);

      if (!inactive || !inactive.length) {
        showToast("No inactive users");
        return;
      }
      const ids = inactive.map(u => u.user_id);
      // delete related data
      await db.from("messages").delete().in("user_id", ids);
      await db.from("gifts").delete().in("user_id", ids);
      await db.from("task_completions").delete().in("user_id", ids);
      await db.from("users").delete().in("user_id", ids);
      showToast("Deleted " + ids.length + " inactive users + data");
      loadAdminPanel();
    } catch (e) {
      console.error(e);
      showToast("Cleanup failed — check RLS/policies");
    }
  };

  // ===== SETTINGS + DYNAMIC TASKS =====
  async function loadRemoteSettings() {
    try {
      const { data } = await db.from("app_settings")
        .select("value")
        .eq("key", "main")
        .maybeSingle();
      if (!data?.value) return;
      const v = data.value;
      if (v.smartlinks) Object.assign(settings.smartlinks, v.smartlinks);
      if (v.smartlinkEnabled) Object.assign(settings.smartlinkEnabled, v.smartlinkEnabled);
      if (v.coinReward) Object.assign(settings.coinReward, v.coinReward);
      if (v.dailyLimit) Object.assign(settings.dailyLimit, v.dailyLimit);
      if (v.cooldown) {
        settings.cooldown.self = (v.cooldown.selfMin || 45) * 60000;
        settings.cooldown.others = (v.cooldown.othersMin || 1) * 60000;
      }
      if (v.chat) {
        settings.chat.freePerDay = v.chat.freePerDay ?? settings.chat.freePerDay;
        settings.chat.rewardPerAd = v.chat.rewardPerAd ?? settings.chat.rewardPerAd;
        settings.chat.adCooldownMs = (v.chat.adCooldownMin || 15) * 60000;
        settings.chat.maxAdsPerDay = v.chat.maxAdsPerDay ?? settings.chat.maxAdsPerDay;
      }
      if (Array.isArray(v.tasks)) settings.tasks = v.tasks;
      if (v.referPercent != null) settings.referPercent = v.referPercent;
    } catch (e) {}
  }

  function loadAdminSettingsForm() {
    if (!isAdmin) return;
    if (!$("set-adsterra-url")) return;
    $("set-adsterra-url").value = settings.smartlinks.adsterra || "";
    $("set-hilltop-url").value = settings.smartlinks.hilltop || "";
    $("set-adsterra-on").checked = settings.smartlinkEnabled.adsterra !== false;
    $("set-hilltop-on").checked = settings.smartlinkEnabled.hilltop !== false;
    $("set-adsterra-coin").value = settings.coinReward.adsterra;
    $("set-hilltop-coin").value = settings.coinReward.hilltop;
    $("set-adsterra-limit").value = settings.dailyLimit.adsterra;
    $("set-hilltop-limit").value = settings.dailyLimit.hilltop;
    $("set-cd-self").value = Math.round(settings.cooldown.self / 60000);
    $("set-cd-others").value = Math.round(settings.cooldown.others / 60000);
    $("set-chat-free").value = settings.chat.freePerDay;
    $("set-chat-reward").value = settings.chat.rewardPerAd;
    $("set-chat-cd").value = Math.round(settings.chat.adCooldownMs / 60000);
    $("set-chat-max").value = settings.chat.maxAdsPerDay;
  }

  function renderAdminTaskEditor() {
    const box = $("admin-task-list");
    if (!box) return;
    const tasks = settings.tasks || [];
    box.innerHTML = tasks.map((t, i) => `
      <div class="task-card" style="flex-direction:column;align-items:stretch;gap:8px;margin-bottom:10px">
        <div class="set-row"><label>Title</label>
          <input type="text" data-i="${i}" data-f="title" value="${esc(t.title)}" onchange="editTaskField(this)"></div>
        <div class="set-row"><label>URL</label>
          <input type="text" data-i="${i}" data-f="url" value="${esc(t.url || "")}" onchange="editTaskField(this)"></div>
        <div class="set-row inline">
          <label>Coins</label>
          <input type="number" data-i="${i}" data-f="rewardCoins" value="${t.rewardCoins || 0}" style="width:70px" onchange="editTaskField(this)">
          <label>Msgs</label>
          <input type="number" data-i="${i}" data-f="rewardMsgs" value="${t.rewardMsgs || 0}" style="width:70px" onchange="editTaskField(this)">
          <label>ON</label>
          <input type="checkbox" data-i="${i}" data-f="enabled" ${t.enabled !== false ? "checked" : ""} onchange="editTaskField(this)">
        </div>
        <button class="modal-close" style="color:var(--danger);border-color:var(--danger)" onclick="removeTask(${i})">Remove task</button>
      </div>
    `).join("") || '<div class="empty-chat">No tasks — add one below</div>';
  }

  window.editTaskField = function (el) {
    const i = +el.dataset.i;
    const f = el.dataset.f;
    if (!settings.tasks[i]) return;
    if (f === "enabled") settings.tasks[i].enabled = el.checked;
    else if (f === "rewardCoins" || f === "rewardMsgs") settings.tasks[i][f] = parseInt(el.value, 10) || 0;
    else settings.tasks[i][f] = el.value;
  };

  window.removeTask = function (i) {
    settings.tasks.splice(i, 1);
    renderAdminTaskEditor();
  };

  window.addNewTask = function () {
    const id = "task_" + Date.now();
    settings.tasks.push({
      id,
      type: "custom",
      title: "New Task",
      url: "https://",
      rewardCoins: 10,
      rewardMsgs: 2,
      enabled: true
    });
    renderAdminTaskEditor();
    showToast("Task added — edit & Save");
  };

  window.saveAdminSettings = async function () {
    if (!isAdmin) return;
    const payload = {
      smartlinks: {
        adsterra: $("set-adsterra-url").value.trim(),
        hilltop: $("set-hilltop-url").value.trim()
      },
      smartlinkEnabled: {
        adsterra: $("set-adsterra-on").checked,
        hilltop: $("set-hilltop-on").checked
      },
      coinReward: {
        monetag: settings.coinReward.monetag,
        adsterra: +$("set-adsterra-coin").value || 8,
        hilltop: +$("set-hilltop-coin").value || 8
      },
      dailyLimit: {
        monetag: settings.dailyLimit.monetag,
        adsterra: +$("set-adsterra-limit").value || 6,
        hilltop: +$("set-hilltop-limit").value || 6
      },
      cooldown: {
        selfMin: +$("set-cd-self").value || 45,
        othersMin: +$("set-cd-others").value || 1
      },
      chat: {
        freePerDay: +$("set-chat-free").value || 10,
        rewardPerAd: +$("set-chat-reward").value || 20,
        adCooldownMin: +$("set-chat-cd").value || 15,
        maxAdsPerDay: +$("set-chat-max").value || 5
      },
      tasks: settings.tasks,
      referPercent: 25
    };

    settings.smartlinks = payload.smartlinks;
    settings.smartlinkEnabled = payload.smartlinkEnabled;
    settings.coinReward = payload.coinReward;
    settings.dailyLimit = payload.dailyLimit;
    settings.cooldown = {
      self: payload.cooldown.selfMin * 60000,
      others: payload.cooldown.othersMin * 60000
    };
    settings.chat = {
      freePerDay: payload.chat.freePerDay,
      rewardPerAd: payload.chat.rewardPerAd,
      adCooldownMs: payload.chat.adCooldownMin * 60000,
      maxAdsPerDay: payload.chat.maxAdsPerDay
    };

    try {
      const { error } = await db.from("app_settings").upsert({
        key: "main",
        value: payload,
        updated_at: new Date().toISOString()
      });
      showToast(error ? "Saved locally" : "Settings saved ✓");
    } catch (e) {
      showToast("Saved locally");
    }
    updateUI();
  };

  // ===== INIT =====
  async function init() {
    loadState();
    await loadRemoteSettings();
    await loadCompletedTasks();
    initProfile();
    applyAdminMode();
    await registerUser();
    updateUI();
    refreshReferStats();
    startAutoInterstitial();
  }
  init();

  window.__isAdmin = isAdmin;
  window.__userId = userId;
})();
