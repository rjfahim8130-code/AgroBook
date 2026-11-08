window.AdminApp = (function () {
  const C = () => window.Core;
  let currentUid = null, currentUname = "";
  let viewStack = ["a-chat"];

  function mount(root) {
    root.innerHTML = `
      <div id="toast" class="toast"></div>

      <!-- CHAT LIST -->
      <div id="a-chat" class="screen with-nav active">
        <div class="app-header">
          <div class="title-wrap"><div class="title">💬 Chats</div><div class="subtitle">Unread on top</div></div>
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
        <div class="chat-input-bar" style="padding-bottom:10px">
          <input type="text" id="a-reply" placeholder="Reply..." autocomplete="off">
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
  }

  function showScreen(id) {
    document.querySelectorAll("#app .screen").forEach(s => s.classList.remove("active"));
    document.getElementById(id)?.classList.add("active");
  }

  function tab(id) {
    viewStack = [id];
    showScreen(id);
    document.querySelectorAll(".bottom-nav .nav-item").forEach(n => n.classList.remove("active"));
    document.querySelector(`.nav-item[data-tab="${id}"]`)?.classList.add("active");
    if (id === "a-chat") loadChatList();
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

      const map = {};
      (data || []).forEach(m => {
        if (!map[m.user_id]) {
          map[m.user_id] = {
            user_id: m.user_id,
            user_name: m.user_name || "User",
            count: 0,
            last_at: m.created_at,
            last_msg: m.message,
            last_sender: m.sender_type,
            unread: 0
          };
        }
        map[m.user_id].count++;
        // unread = trailing user messages after last admin reply (approx from recent stream)
        if (!map[m.user_id]._seenAdmin && m.sender_type === "user") map[m.user_id].unread++;
        if (m.sender_type === "admin") map[m.user_id]._seenAdmin = true;
      });

      // Fix unread: recount properly would need per-user query; use last_sender heuristic
      Object.values(map).forEach(u => {
        if (u.last_sender === "admin") u.unread = 0;
        else if (u.unread === 0 && u.last_sender === "user") u.unread = 1;
      });

      const users = Object.values(map).sort((a, b) => {
        if (a.unread && !b.unread) return -1;
        if (!a.unread && b.unread) return 1;
        return new Date(b.last_at) - new Date(a.last_at);
      });

      if (!users.length) {
        box.innerHTML = '<div class="empty-state">No chats yet</div>';
        return;
      }

      box.innerHTML = users.map(u => `
        <div class="user-row ${u.unread ? "unread" : ""}" onclick="AdminApp.openRoom(${u.user_id}, '${c.esc(u.user_name).replace(/'/g, "\\'")}')">
          <div>
            <div class="u-name">${c.esc(u.user_name)}</div>
            <div class="u-meta">ID ${u.user_id} · ${u.count} msgs</div>
          </div>
          <div class="u-badge">${u.unread ? "● " + u.unread : u.count}</div>
        </div>
      `).join("");
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
    const box = document.getElementById("a-ads-form");
    box.innerHTML = `
      <div class="toggle-row"><input type="checkbox" id="set-adsterra-on" ${s.smartlinkEnabled.adsterra !== false ? "checked" : ""}> Adsterra ON</div>
      <div class="set-row"><label>Adsterra URL</label><input type="text" id="set-adsterra-url" value="${C().esc(s.smartlinks.adsterra || "")}"></div>
      <div class="set-row inline"><label>Coins</label><input type="number" id="set-adsterra-coin" value="${s.coinReward.adsterra}" style="width:70px">
        <label>Daily</label><input type="number" id="set-adsterra-limit" value="${s.dailyLimit.adsterra}" style="width:70px"></div>
      <hr style="border:none;border-top:1px solid #333;margin:12px 0">
      <div class="toggle-row"><input type="checkbox" id="set-hilltop-on" ${s.smartlinkEnabled.hilltop !== false ? "checked" : ""}> Hilltop ON</div>
      <div class="set-row"><label>Hilltop URL</label><input type="text" id="set-hilltop-url" value="${C().esc(s.smartlinks.hilltop || "")}"></div>
      <div class="set-row inline"><label>Coins</label><input type="number" id="set-hilltop-coin" value="${s.coinReward.hilltop}" style="width:70px">
        <label>Daily</label><input type="number" id="set-hilltop-limit" value="${s.dailyLimit.hilltop}" style="width:70px"></div>
      <hr style="border:none;border-top:1px solid #333;margin:12px 0">
      <div class="set-row inline"><label>CD self (min)</label><input type="number" id="set-cd-self" value="${Math.round(s.cooldown.self/60000)}" style="width:60px">
        <label>Others</label><input type="number" id="set-cd-others" value="${Math.round(s.cooldown.others/60000)}" style="width:60px"></div>
      <div class="section-title">Chat limits</div>
      <div class="set-row inline"><label>Free msgs</label><input type="number" id="set-chat-free" value="${s.chat.freePerDay}" style="width:70px"></div>
      <div class="set-row inline"><label>+msgs/ad</label><input type="number" id="set-chat-reward" value="${s.chat.rewardPerAd}" style="width:70px"></div>
      <div class="set-row inline"><label>Ad CD min</label><input type="number" id="set-chat-cd" value="${Math.round(s.chat.adCooldownMs/60000)}" style="width:70px"></div>
      <div class="set-row inline"><label>Max ads/day</label><input type="number" id="set-chat-max" value="${s.chat.maxAdsPerDay}" style="width:70px"></div>
      <button class="btn-gold" style="margin-top:12px" onclick="AdminApp.saveSettings()">Save Settings</button>
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
    if (document.getElementById("set-adsterra-url")) {
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
      s.chat.freePerDay = +document.getElementById("set-chat-free").value || 10;
      s.chat.rewardPerAd = +document.getElementById("set-chat-reward").value || 20;
      s.chat.adCooldownMs = (+document.getElementById("set-chat-cd").value || 15) * 60000;
      s.chat.maxAdsPerDay = +document.getElementById("set-chat-max").value || 5;
    }
    const payload = {
      smartlinks: s.smartlinks,
      smartlinkEnabled: s.smartlinkEnabled,
      coinReward: s.coinReward,
      dailyLimit: s.dailyLimit,
      cooldown: { selfMin: Math.round(s.cooldown.self/60000), othersMin: Math.round(s.cooldown.others/60000) },
      chat: {
        freePerDay: s.chat.freePerDay,
        rewardPerAd: s.chat.rewardPerAd,
        adCooldownMin: Math.round(s.chat.adCooldownMs/60000),
        maxAdsPerDay: s.chat.maxAdsPerDay
      },
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
    mount, tab, openSub, back, openRoom, sendReply, viewUserProfile,
    renderAdsForm, renderTaskEditor, editTask, removeTask, addTask,
    saveSettings, cleanup, loadHistory, loadGifts
  };
})();
