window.AdminApp = (function () {
  const C = () => window.Core;
  let currentUid = null, currentUname = "";
  let viewStack = ["a-chat"];
  let chatListTimer = null;

  function mount(root) {
    root.innerHTML = `
      <div id="toast" class="toast"></div>

      <!-- CHAT LIST -->
      <div id="a-chat" class="screen with-nav active">
        <div class="app-header">
          <div class="title-wrap"><div class="title">💬 Chats</div><div class="subtitle">Unread on top</div></div>
          <button class="back-btn" title="Refresh" onclick="AdminApp.loadChatList()" style="font-size:16px">↻</button>
        </div>
        <div class="scroll-body" id="a-user-list"><div class="empty-state">Loading...</div></div>
      </div>

      <!-- CHAT ROOM (overlay style screen) -->
      <div id="a-room" class="screen">
        <div class="app-header">
          <button class="back-btn" onclick="AdminApp.back()">←</button>
          <div class="title-wrap" onclick="AdminApp.viewUserProfile()">
            <div class="title" id="a-room-title">User</div>
            <div class="subtitle">Tap for profile</div>
          </div>
        </div>
        <div class="chat-messages" id="a-room-msgs"></div>
        <div class="chat-input-bar admin-reply-bar">
          <input type="text" id="a-reply" placeholder="Type reply..." autocomplete="off">
          <button class="btn-send" onclick="AdminApp.sendReply()">Send</button>
        </div>
      </div>

      <!-- USER PROFILE VIEW -->
      <div id="a-user-profile" class="screen with-nav">
        <div class="app-header">
          <button class="back-btn" onclick="AdminApp.back()">←</button>
          <div class="title-wrap"><div class="title">User Profile</div></div>
        </div>
        <div class="scroll-body" id="a-user-profile-body"></div>
      </div>

      <!-- CONTROL -->
      <div id="a-control" class="screen with-nav">
        <div class="app-header"><div class="title-wrap"><div class="title">⚙️ Control</div></div></div>
        <div class="scroll-body">
          <button class="ctrl-btn" onclick="AdminApp.openSub('a-ads-settings')">
            <span>⭐ Ad & Coin Settings</span><span class="arrow">→</span>
          </button>
          <button class="ctrl-btn" onclick="AdminApp.openSub('a-tasks-settings')">
            <span>📋 Manage Tasks</span><span class="arrow">→</span>
          </button>
          <button class="ctrl-btn danger" onclick="AdminApp.cleanup()">
            <span>🧹 Cleanup (7d msgs + 14d inactive)</span><span class="arrow">→</span>
          </button>
        </div>
      </div>

      <!-- ADS SETTINGS SUB -->
      <div id="a-ads-settings" class="screen with-nav">
        <div class="app-header">
          <button class="back-btn" onclick="AdminApp.back()">←</button>
          <div class="title-wrap"><div class="title">Ad Settings</div></div>
        </div>
        <div class="scroll-body" id="a-ads-form"></div>
      </div>

      <!-- TASKS SETTINGS SUB -->
      <div id="a-tasks-settings" class="screen with-nav">
        <div class="app-header">
          <button class="back-btn" onclick="AdminApp.back()">←</button>
          <div class="title-wrap"><div class="title">Tasks</div></div>
        </div>
        <div class="scroll-body">
          <div id="a-task-list"></div>
          <button class="btn-gold" style="margin-top:8px" onclick="AdminApp.addTask()">+ Add Task</button>
          <button class="btn-gold" style="margin-top:8px;background:var(--surface2);color:var(--gold);border:1px solid var(--gold)" onclick="AdminApp.saveSettings()">Save Tasks</button>
        </div>
      </div>

      <!-- HISTORY -->
      <div id="a-history" class="screen with-nav">
        <div class="app-header"><div class="title-wrap"><div class="title">📊 History</div></div></div>
        <div class="scroll-body">
          <div class="hist-grid">
            <div class="hist-card"><div class="n" id="h-users">0</div><div class="l">Users</div></div>
            <div class="hist-card"><div class="n" id="h-active">0</div><div class="l">Active today</div></div>
            <div class="hist-card"><div class="n" id="h-online">0</div><div class="l">Recent 1h</div></div>
          </div>
          <button class="ctrl-btn" onclick="AdminApp.openSub('a-gifts-view')">
            <span>🎁 Gift History</span><span class="arrow">→</span>
          </button>
        </div>
      </div>

      <!-- GIFTS VIEW SUB -->
      <div id="a-gifts-view" class="screen with-nav">
        <div class="app-header">
          <button class="back-btn" onclick="AdminApp.back()">←</button>
          <div class="title-wrap"><div class="title">Gifts</div></div>
        </div>
        <div class="scroll-body">
          <div class="section-title">Today</div>
          <div id="a-gifts-today"><div class="empty-state">—</div></div>
          <div class="section-title">Top this week</div>
          <div id="a-gifts-week"><div class="empty-state">—</div></div>
        </div>
      </div>

      <div class="bottom-nav">
        <div class="nav-item active" data-tab="a-chat" onclick="AdminApp.tab('a-chat')"><span class="icon">💬</span><span>Chat</span></div>
        <div class="nav-item" data-tab="a-control" onclick="AdminApp.tab('a-control')"><span class="icon">⚙️</span><span>Control</span></div>
        <div class="nav-item" data-tab="a-history" onclick="AdminApp.tab('a-history')"><span class="icon">📊</span><span>History</span></div>
      </div>
    `;

    loadChatList();
    bindReply();
    chatListTimer = setInterval(() => {
      if (viewStack[viewStack.length - 1] === "a-chat") loadChatList();
    }, 12000);
  }

  function showScreen(id) {
    document.querySelectorAll("#app .screen").forEach(s => s.classList.remove("active"));
    document.getElementById(id)?.classList.add("active");
    const nav = document.querySelector(".bottom-nav");
    const hideNav = ["a-room", "a-user-profile", "a-ads-settings", "a-tasks-settings", "a-gifts-view"].includes(id);
    if (nav) nav.style.display = hideNav ? "none" : "flex";
  }

  function tab(id) {
    viewStack = [id];
    showScreen(id);
    document.querySelectorAll(".bottom-nav .nav-item").forEach(n => n.classList.remove("active"));
    document.querySelector(`.nav-item[data-tab="${id}"]`)?.classList.add("active");
    if (chatListTimer) { clearInterval(chatListTimer); chatListTimer = null; }
    if (id === "a-chat") {
      loadChatList();
      chatListTimer = setInterval(() => {
        if (viewStack[viewStack.length - 1] === "a-chat") loadChatList();
      }, 12000);
    }
    if (id === "a-history") loadHistory();
  }

  function openSub(id) {
    viewStack.push(id);
    showScreen(id);
    if (id === "a-ads-settings") renderAdsForm();
    if (id === "a-tasks-settings") renderTaskEditor();
    if (id === "a-gifts-view") loadGifts();
  }

  function back() {
    if (viewStack.length > 1) {
      viewStack.pop();
      showScreen(viewStack[viewStack.length - 1]);
      if (viewStack[viewStack.length - 1] === "a-chat") loadChatList();
    } else {
      tab("a-chat");
    }
  }

  async function loadChatList() {
    const box = document.getElementById("a-user-list");
    if (!box) return;
    box.innerHTML = '<div class="empty-state">Loading...</div>';
    const c = C();
    try {
      const { data } = await c.db.from("messages")
        .select("user_id, user_name, message, sender_type, created_at")
        .order("created_at", { ascending: false })
        .limit(800);
      const { data: userRows } = await c.db.from("users").select("user_id, photo_url");
      const photoMap = {};
      (userRows || []).forEach(u => { photoMap[u.user_id] = u.photo_url; });

      const map = {};
      // messages are newest-first; walk until we hit an admin reply for each user
      (data || []).forEach(m => {
        if (!map[m.user_id]) {
          map[m.user_id] = {
            user_id: m.user_id,
            user_name: m.user_name || "User",
            last_at: m.created_at,
            last_sender: m.sender_type,
            unread: 0,
            _counting: true
          };
        }
        // only count consecutive newest user msgs before any admin reply
        if (map[m.user_id]._counting) {
          if (m.sender_type === "user") map[m.user_id].unread++;
          else map[m.user_id]._counting = false; // hit admin reply
        }
      });

      const users = Object.values(map).sort((a, b) => {
        if ((a.unread > 0) && !(b.unread > 0)) return -1;
        if (!(a.unread > 0) && (b.unread > 0)) return 1;
        return new Date(b.last_at) - new Date(a.last_at);
      });

      if (!users.length) {
        box.innerHTML = '<div class="empty-state">No chats yet</div>';
        return;
      }

      box.innerHTML = users.map(u => {
        const ph = photoMap[u.user_id];
        const av = ph
          ? `<img src="${c.esc(ph)}" style="width:40px;height:40px;border-radius:50%;object-fit:cover;border:1.5px solid var(--gold);flex-shrink:0">`
          : `<div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,var(--gold),#8a7020);display:flex;align-items:center;justify-content:center;font-weight:800;color:#000;flex-shrink:0">${c.esc((u.user_name || "?")[0])}</div>`;
        const badge = (u.unread > 0) ? `<div class="u-badge">${u.unread}</div>` : "";
        return `<div class="user-row ${u.unread ? "unread" : ""}" onclick="AdminApp.openRoom(${u.user_id}, '${c.esc(u.user_name).replace(/'/g, "\\'")}')">
          <div style="display:flex;gap:10px;align-items:center;min-width:0">
            ${av}
            <div style="min-width:0">
              <div class="u-name">${c.esc(u.user_name)}</div>
              <div class="u-meta">ID ${u.user_id}</div>
            </div>
          </div>
          ${badge}
        </div>`;
      }).join("");
    } catch (e) {
      box.innerHTML = '<div class="empty-state">Error loading</div>';
    }
  }

  async function openRoom(uid, uname) {
    currentUid = uid;
    currentUname = uname;
    document.getElementById("a-room-title").textContent = uname;
    viewStack.push("a-room");
    showScreen("a-room");
    const box = document.getElementById("a-room-msgs");
    box.innerHTML = '<div class="empty-state">Loading...</div>';
    const c = C();
    const { data } = await c.db.from("messages")
      .select("*").eq("user_id", uid).order("created_at", { ascending: true });
    box.innerHTML = (data || []).map(m =>
      `<div class="msg ${m.sender_type === "admin" ? "user" : "admin"}">${c.esc(m.message)}</div>`
    ).join("") || '<div class="empty-state">Empty</div>';
    box.scrollTop = box.scrollHeight;
  }

  async function sendReply() {
    const input = document.getElementById("a-reply");
    const text = input?.value.trim();
    if (!text || !currentUid) return;
    input.value = "";
    const c = C();
    const { error } = await c.db.from("messages").insert([{
      user_id: currentUid, user_name: currentUname, message: text, sender_type: "admin"
    }]);
    if (error) c.showToast("Failed");
    else openRoom(currentUid, currentUname);
  }

  function bindReply() {
    document.getElementById("a-reply")?.addEventListener("keydown", e => {
      if (e.key === "Enter") { e.preventDefault(); sendReply(); }
    });
  }

  async function viewUserProfile() {
    if (!currentUid) return;
    viewStack.push("a-user-profile");
    showScreen("a-user-profile");
    const body = document.getElementById("a-user-profile-body");
    body.innerHTML = '<div class="empty-state">Loading...</div>';
    const c = C();
    const { data: u } = await c.db.from("users").select("*").eq("user_id", currentUid).maybeSingle();
    const { count: msgCount } = await c.db.from("messages").select("*", { count: "exact", head: true }).eq("user_id", currentUid);
    const { data: gifts } = await c.db.from("gifts").select("amount").eq("user_id", currentUid);
    const giftTotal = (gifts || []).reduce((s, g) => s + (g.amount || 0), 0);
    body.innerHTML = `
      <div class="profile-card">
        <div class="p-name">${c.esc(currentUname)}</div>
        <div class="p-meta">ID: ${currentUid}</div>
        <div class="p-meta">Username: ${c.esc(u?.username || "—")}</div>
        <div class="p-meta">Referrer: ${u?.referrer_id || "—"}</div>
        <div class="p-meta">Last active: ${u?.last_active ? new Date(u.last_active).toLocaleString() : "—"}</div>
        <div class="stats-grid">
          <div class="stat-box"><div class="v">${msgCount || 0}</div><div class="l">Messages</div></div>
          <div class="stat-box"><div class="v">${giftTotal}</div><div class="l">Gifted coins</div></div>
        </div>
      </div>`;
  }

  function renderAdsForm() {
    const s = C().state.settings;
    const rw = s.rewarded || {};
    const pop = s.popup || {};
    const it = s.interstitial || {};
    const box = document.getElementById("a-ads-form");
    box.innerHTML = `
      <div class="section-title">⭐ Monetag Rewarded (coins)</div>
      <div class="set-row inline"><label>Coins/ad</label><input type="number" id="rw-coins" value="${rw.coins ?? s.coinReward.monetag}" style="width:70px"></div>
      <div class="set-row inline"><label>Daily max</label><input type="number" id="rw-daily" value="${rw.dailyMax ?? s.dailyLimit.monetag}" style="width:70px"></div>
      <div class="set-row inline"><label>Streak max</label><input type="number" id="rw-streak" value="${rw.streakMax ?? 3}" style="width:70px"></div>
      <div class="set-row inline"><label>Between CD (min)</label><input type="number" id="rw-between" value="${rw.betweenCdMin ?? 1}" style="width:70px"></div>
      <div class="set-row inline"><label>After streak CD (min)</label><input type="number" id="rw-streakcd" value="${rw.streakCdMin ?? 60}" style="width:70px"></div>
      <p style="font-size:11px;color:var(--text2);margin:4px 0 12px">e.g. daily 15, streak 3, between 1 min, after 3 ads wait 60 min</p>

      <div class="section-title">📺 In-App Interstitial</div>
      <div class="set-row inline"><label>Frequency</label><input type="number" id="it-freq" value="${it.frequency ?? 2}" style="width:70px"></div>
      <div class="set-row inline"><label>Capping (hours)</label><input type="number" id="it-cap" value="${it.cappingHours ?? 0.1}" step="0.1" style="width:70px"></div>
      <div class="set-row inline"><label>Interval (sec)</label><input type="number" id="it-int" value="${it.intervalSec ?? 30}" style="width:70px"></div>
      <div class="set-row inline"><label>Timeout (sec)</label><input type="number" id="it-to" value="${it.timeoutSec ?? 5}" style="width:70px"></div>

      <hr style="border:none;border-top:1px solid #333;margin:14px 0">
      <div class="section-title">🔗 Smartlinks</div>
      <div class="toggle-row"><input type="checkbox" id="set-adsterra-on" ${s.smartlinkEnabled.adsterra !== false ? "checked" : ""}> Adsterra ON</div>
      <div class="set-row"><label>Adsterra URL</label><input type="text" id="set-adsterra-url" value="${C().esc(s.smartlinks.adsterra || "")}"></div>
      <div class="set-row inline"><label>Coins</label><input type="number" id="set-adsterra-coin" value="${s.coinReward.adsterra}" style="width:70px">
        <label>Daily</label><input type="number" id="set-adsterra-limit" value="${s.dailyLimit.adsterra}" style="width:70px"></div>
      <div class="toggle-row"><input type="checkbox" id="set-hilltop-on" ${s.smartlinkEnabled.hilltop !== false ? "checked" : ""}> Hilltop ON</div>
      <div class="set-row"><label>Hilltop URL</label><input type="text" id="set-hilltop-url" value="${C().esc(s.smartlinks.hilltop || "")}"></div>
      <div class="set-row inline"><label>Coins</label><input type="number" id="set-hilltop-coin" value="${s.coinReward.hilltop}" style="width:70px">
        <label>Daily</label><input type="number" id="set-hilltop-limit" value="${s.dailyLimit.hilltop}" style="width:70px"></div>
      <div class="set-row inline"><label>Smartlink CD self (min)</label><input type="number" id="set-cd-self" value="${Math.round(s.cooldown.self/60000)}" style="width:60px">
        <label>Others</label><input type="number" id="set-cd-others" value="${Math.round(s.cooldown.others/60000)}" style="width:60px"></div>

      <div class="section-title">💬 Chat coin cost</div>
      <div class="set-row inline"><label>Free msgs/day</label><input type="number" id="set-chat-free" value="${s.chat.freePerDay ?? 5}" style="width:70px"></div>
      <div class="set-row inline"><label>Coins per message</label><input type="number" id="set-coins-per-msg" value="${s.chat.coinsPerMessage ?? 1}" style="width:70px"></div>
      <p style="font-size:11px;color:var(--text2);margin:4px 0 12px">After free quota, each message costs coins. User earns coins from ads.</p>

      <div class="section-title">Monetag Popup (coins)</div>
      <div class="set-row inline"><label>Coins/popup</label><input type="number" id="pop-coins" value="${(s.popup&&s.popup.coins) || 12}" style="width:70px"></div>
      <div class="set-row inline"><label>Daily max</label><input type="number" id="pop-daily" value="${(s.popup&&s.popup.dailyMax) || 10}" style="width:70px"></div>
      <div class="set-row inline"><label>Streak max</label><input type="number" id="pop-streak" value="${(s.popup&&s.popup.streakMax) || 3}" style="width:70px"></div>
      <div class="set-row inline"><label>Between CD (min)</label><input type="number" id="pop-between" value="${(s.popup&&s.popup.betweenCdMin) || 2}" style="width:70px"></div>
      <div class="set-row inline"><label>After streak CD (min)</label><input type="number" id="pop-streakcd" value="${(s.popup&&s.popup.streakCdMin) || 60}" style="width:70px"></div>

      <button class="btn-gold" style="margin-top:14px" onclick="AdminApp.saveSettings()">Save Settings</button>
    `;
  }

  function renderTaskEditor() {
    const box = document.getElementById("a-task-list");
    const tasks = C().state.settings.tasks || [];
    box.innerHTML = tasks.map((t, i) => `
      <div class="task-card" style="flex-direction:column;align-items:stretch;gap:8px;margin-bottom:10px">
        <div class="set-row"><label>Title</label><input type="text" data-i="${i}" data-f="title" value="${C().esc(t.title)}" onchange="AdminApp.editTask(this)"></div>
        <div class="set-row"><label>URL</label><input type="text" data-i="${i}" data-f="url" value="${C().esc(t.url||"")}" onchange="AdminApp.editTask(this)"></div>
        <div class="set-row inline">
          <label>Coins</label><input type="number" data-i="${i}" data-f="rewardCoins" value="${t.rewardCoins||0}" style="width:70px" onchange="AdminApp.editTask(this)">
          <label>Msgs</label><input type="number" data-i="${i}" data-f="rewardMsgs" value="${t.rewardMsgs||0}" style="width:70px" onchange="AdminApp.editTask(this)">
          <label>ON</label><input type="checkbox" data-i="${i}" data-f="enabled" ${t.enabled!==false?"checked":""} onchange="AdminApp.editTask(this)">
        </div>
        <button class="btn-outline" style="color:var(--danger);border-color:var(--danger)" onclick="AdminApp.removeTask(${i})">Remove</button>
      </div>
    `).join("") || '<div class="empty-state">No tasks — add one</div>';
  }

  function editTask(el) {
    const i = +el.dataset.i, f = el.dataset.f;
    const t = C().state.settings.tasks[i];
    if (!t) return;
    if (f === "enabled") t.enabled = el.checked;
    else if (f === "rewardCoins" || f === "rewardMsgs") t[f] = parseInt(el.value, 10) || 0;
    else t[f] = el.value;
  }

  function removeTask(i) {
    C().state.settings.tasks.splice(i, 1);
    renderTaskEditor();
  }

  function addTask() {
    C().state.settings.tasks.push({
      id: "task_" + Date.now(),
      type: "custom",
      title: "New Task",
      url: "https://",
      rewardCoins: 10,
      rewardMsgs: 2,
      enabled: true
    });
    renderTaskEditor();
  }

  async function saveSettings() {
    const c = C();
    const s = c.state.settings;
    // read ads form if present
    if (document.getElementById("rw-daily")) {
      s.rewarded = {
        coins: +document.getElementById("rw-coins").value || 15,
        dailyMax: +document.getElementById("rw-daily").value || 15,
        streakMax: +document.getElementById("rw-streak").value || 3,
        betweenCdMin: +document.getElementById("rw-between").value || 1,
        streakCdMin: +document.getElementById("rw-streakcd").value || 60
      };
      s.popup = {
        coins: +document.getElementById("pop-coins").value || 12,
        dailyMax: +document.getElementById("pop-daily").value || 10,
        streakMax: +document.getElementById("pop-streak").value || 3,
        betweenCdMin: +document.getElementById("pop-between").value || 2,
        streakCdMin: +document.getElementById("pop-streakcd").value || 60
      };
      s.interstitial = {
        frequency: +document.getElementById("it-freq").value || 2,
        cappingHours: +document.getElementById("it-cap").value || 0.1,
        intervalSec: +document.getElementById("it-int").value || 30,
        timeoutSec: +document.getElementById("it-to").value || 5
      };
      s.coinReward.monetag = s.rewarded.coins;
      s.dailyLimit.monetag = s.rewarded.dailyMax;
      s.chat.rewardPerAd = s.popup.rewardMsgs;
      s.chat.maxAdsPerDay = s.popup.dailyMax;
      s.smartlinks.adsterra = document.getElementById("set-adsterra-url").value.trim();
      s.smartlinks.hilltop = document.getElementById("set-hilltop-url").value.trim();
      s.smartlinkEnabled.adsterra = document.getElementById("set-adsterra-on").checked;
      s.smartlinkEnabled.hilltop = document.getElementById("set-hilltop-on").checked;
      s.coinReward.adsterra = +document.getElementById("set-adsterra-coin").value || 8;
      s.coinReward.hilltop = +document.getElementById("set-hilltop-coin").value || 8;
      s.dailyLimit.adsterra = +document.getElementById("set-adsterra-limit").value || 6;
      s.dailyLimit.hilltop = +document.getElementById("set-hilltop-limit").value || 6;
      s.cooldown.self = (+document.getElementById("set-cd-self").value || 45) * 60000;
      s.cooldown.others = (+document.getElementById("set-cd-others").value || 1) * 60000;
      s.chat.freePerDay = +document.getElementById("set-chat-free").value || 5;
      if (document.getElementById("set-coins-per-msg")) {
        s.chat.coinsPerMessage = +document.getElementById("set-coins-per-msg").value || 1;
      }
      if (document.getElementById("pop-coins")) {
        s.popup = {
          coins: +document.getElementById("pop-coins").value || 12,
          dailyMax: +document.getElementById("pop-daily").value || 10,
          streakMax: +document.getElementById("pop-streak").value || 3,
          betweenCdMin: +document.getElementById("pop-between").value || 2,
          streakCdMin: +document.getElementById("pop-streakcd").value || 60
        };
      }
    }
    const payload = {
      smartlinks: s.smartlinks,
      smartlinkEnabled: s.smartlinkEnabled,
      coinReward: s.coinReward,
      dailyLimit: s.dailyLimit,
      cooldown: { selfMin: Math.round(s.cooldown.self/60000), othersMin: Math.round(s.cooldown.others/60000) },
      rewarded: s.rewarded,
      popup: s.popup,
      interstitial: s.interstitial,
      chat: {
        freePerDay: s.chat.freePerDay,
        coinsPerMessage: s.chat.coinsPerMessage ?? 1
      },
      popup: s.popup,
      tasks: s.tasks,
      referPercent: 25
    };
    try {
      const { error } = await c.db.from("app_settings").upsert({
        key: "main", value: payload, updated_at: new Date().toISOString()
      });
      c.showToast(error ? "Saved locally" : "Saved ✓");
    } catch (e) {
      c.showToast("Saved locally");
    }
  }

  async function cleanup() {
    if (!confirm("Delete messages older than 7 days AND users inactive 14+ days with all their data?")) return;
    const c = C();
    const msgCutoff = new Date(Date.now() - 7 * 86400000).toISOString();
    const userCutoff = new Date(Date.now() - 14 * 86400000).toISOString();
    try {
      await c.db.from("messages").delete().lt("created_at", msgCutoff);
      const { data: inactive } = await c.db.from("users").select("user_id").lt("last_active", userCutoff);
      if (inactive?.length) {
        const ids = inactive.map(u => u.user_id);
        await c.db.from("messages").delete().in("user_id", ids);
        await c.db.from("gifts").delete().in("user_id", ids);
        await c.db.from("task_completions").delete().in("user_id", ids);
        await c.db.from("users").delete().in("user_id", ids);
        c.showToast("Cleanup done (" + ids.length + " users)");
      } else {
        c.showToast("Old messages cleared");
      }
      loadChatList();
    } catch (e) {
      c.showToast("Cleanup failed");
    }
  }

  async function loadHistory() {
    const c = C();
    try {
      const { count: users } = await c.db.from("users").select("*", { count: "exact", head: true });
      const dayStart = new Date(); dayStart.setHours(0,0,0,0);
      const { count: active } = await c.db.from("users").select("*", { count: "exact", head: true })
        .gte("last_active", dayStart.toISOString());
      const hourAgo = new Date(Date.now() - 3600000).toISOString();
      const { count: online } = await c.db.from("users").select("*", { count: "exact", head: true })
        .gte("last_active", hourAgo);
      document.getElementById("h-users").textContent = users || 0;
      document.getElementById("h-active").textContent = active || 0;
      document.getElementById("h-online").textContent = online || 0;
    } catch (e) {}
  }

  async function loadGifts() {
    const c = C();
    const dayStart = new Date(); dayStart.setHours(0,0,0,0);
    const weekAgo = new Date(Date.now() - 7 * 86400000).toISOString();
    try {
      const { data: today } = await c.db.from("gifts").select("*")
        .gte("created_at", dayStart.toISOString())
        .order("created_at", { ascending: false }).limit(30);
      const tBox = document.getElementById("a-gifts-today");
      tBox.innerHTML = (today || []).map(g =>
        `<div class="gift-row"><span>${c.esc(g.user_name)}</span><span class="amt">+${g.amount}</span></div>`
      ).join("") || '<div class="empty-state">No gifts today</div>';

      const { data: week } = await c.db.from("gifts").select("user_id, user_name, amount")
        .gte("created_at", weekAgo);
      const map = {};
      (week || []).forEach(g => {
        if (!map[g.user_id]) map[g.user_id] = { name: g.user_name, total: 0 };
        map[g.user_id].total += g.amount || 0;
      });
      const top = Object.values(map).sort((a, b) => b.total - a.total).slice(0, 20);
      const wBox = document.getElementById("a-gifts-week");
      wBox.innerHTML = top.map(g =>
        `<div class="gift-row"><span>${c.esc(g.name)}</span><span class="amt">${g.total}</span></div>`
      ).join("") || '<div class="empty-state">No gifts this week</div>';
    } catch (e) {}
  }

  return {
    mount, tab, openSub, back, openRoom, sendReply, viewUserProfile, loadChatList,
    renderAdsForm, renderTaskEditor, editTask, removeTask, addTask,
    saveSettings, cleanup, loadHistory, loadGifts
  };
})();
