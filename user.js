window.UserApp = (function () {
  const C = () => window.Core;
  let chatBox = null;

  function mount(root) {
    root.innerHTML = `
      <div id="toast" class="toast"></div>
      <div class="modal-overlay" id="need-coins-modal">
        <div class="modal-box">
          <h3>Not enough coins</h3>
          <p id="modal-coins-info">Watch an ad to earn coins, then send messages.</p>
          <button class="ad-card primary" onclick="Ads.watchAdsgram()">
            <span>▶ Adsgram Reward</span>
            <span class="sub">Earn coins</span>
          </button>
          <button class="ad-card secondary" style="margin-top:8px" onclick="Ads.watchMonetagPopup()">
            <span>▶ Monetag Popup</span>
            <span class="sub">Earn coins</span>
          </button>
          <button class="btn-outline" style="margin-top:10px" onclick="document.getElementById('need-coins-modal').classList.remove('show')">Later</button>
        </div>
      </div>
      <div class="modal-overlay" id="gift-modal">
        <div class="modal-box">
          <h3>🎁 Gift Coins</h3>
          <p>Balance: <b id="gift-bal" style="color:var(--gold)">0</b></p>
          <div class="set-row"><input type="number" id="gift-amount" placeholder="Amount" min="10" inputmode="numeric"></div>
          <div class="gift-presets">
            <button onclick="document.getElementById('gift-amount').value=20">20</button>
            <button onclick="document.getElementById('gift-amount').value=50">50</button>
            <button onclick="document.getElementById('gift-amount').value=100">100</button>
            <button onclick="document.getElementById('gift-amount').value=200">200</button>
          </div>
          <button class="btn-gold" onclick="UserApp.sendGift()">Send Gift</button>
          <button class="btn-outline" style="margin-top:8px" onclick="document.getElementById('gift-modal').classList.remove('show')">Cancel</button>
        </div>
      </div>

      <!-- CHAT (default) -->
      <div id="u-chat" class="screen active">
        <div class="app-header">
          <span id="u-header-av"></span>
          <div class="title-wrap">
            <div class="title">Fariha Jannat</div>
            <div class="subtitle" id="u-chat-limit">Messages left: —</div>
          </div>
          <span class="badge" id="u-msg-badge" style="display:none">0</span>
        </div>
        <div class="chat-messages" id="u-messages">
          <div class="empty-state">No messages yet.<br>Say hello to Fariha!</div>
        </div>
        <div class="chat-input-bar">
          <button class="btn-gift" onclick="UserApp.openGift()" title="Gift">🎁</button>
          <input type="text" id="u-msg-input" placeholder="Type a message..." autocomplete="off">
          <button class="btn-send" onclick="UserApp.sendMessage()">Send</button>
        </div>
      </div>

      <!-- BALANCE -->
      <div id="u-balance" class="screen with-nav">
        <div class="app-header"><div class="title-wrap"><div class="title">Balance</div></div></div>
        <div class="scroll-body">
          <div class="balance-hero">
            <div class="label">Your coins</div>
            <div class="amount" id="u-coins">0</div>
          </div>
          <div class="section-title">Earn coins</div>
          <button class="ad-card primary" id="btn-monetag" onclick="Ads.watchMonetag()">
            <span>▶ Watch Ad (+15)</span>
            <span class="sub">Monetag Rewarded</span>
            <span class="cd" style="display:none"></span>
          </button>
          <button class="ad-card secondary" id="btn-monetag-popup" onclick="Ads.watchMonetagPopup()">
            <span>▶ Popup Ad (+12)</span>
            <span class="sub">Monetag Popup → coins</span>
            <span class="cd" style="display:none"></span>
          </button>
          <button class="ad-card secondary" id="btn-adsterra" onclick="Ads.openSmartlink('adsterra')">
            <span>🔗 Extra Offer (+8)</span>
            <span class="sub">Adsterra</span>
            <span class="cd" style="display:none"></span>
          </button>
          <button class="ad-card secondary" id="btn-hilltop" onclick="Ads.openSmartlink('hilltop')">
            <span>🔗 Other Offer (+8)</span>
            <span class="sub">HilltopAds</span>
            <span class="cd" style="display:none"></span>
          </button>
          <div id="u-tasks-wrap" style="display:none">
            <div class="section-title">Tasks</div>
            <div id="u-tasks"></div>
          </div>
        </div>
      </div>

      <!-- PROFILE -->
      <div id="u-profile" class="screen with-nav">
        <div class="app-header"><div class="title-wrap"><div class="title">Profile</div></div></div>
        <div class="scroll-body">
          <div class="profile-card">
            <div class="p-av" id="u-pav">?</div>
            <div class="p-name" id="u-pname">—</div>
            <div class="p-meta" id="u-phandle">—</div>
            <div class="p-meta" id="u-pid">—</div>
            <div class="stats-grid">
              <div class="stat-box"><div class="v" id="u-s-coins">0</div><div class="l">Coins</div></div>
              <div class="stat-box"><div class="v" id="u-s-earned">0</div><div class="l">Earned</div></div>
              <div class="stat-box"><div class="v" id="u-s-gifted">0</div><div class="l">Gifted</div></div>
              <div class="stat-box"><div class="v" id="u-s-refs">0</div><div class="l">Referrals</div></div>
            </div>
            <div class="refer-box">
              <div style="font-size:13px;color:var(--text2)">Invite friends — get <b style="color:var(--gold)">25%</b> of their messages as free chat</div>
              <div class="ref-link" id="u-ref-link">—</div>
              <button class="btn-gold" onclick="UserApp.copyRef()">Copy Invite Link</button>
              <div id="u-ref-stats" style="margin-top:10px;font-size:12px;color:var(--text2)"></div>
            </div>
          </div>
        </div>
      </div>

      <div class="bottom-nav">
        <div class="nav-item active" data-tab="u-chat" onclick="UserApp.tab('u-chat')"><span class="icon">💬</span><span>Chat</span></div>
        <div class="nav-item" data-tab="u-balance" onclick="UserApp.tab('u-balance')"><span class="icon">⭐</span><span>Balance</span></div>
        <div class="nav-item" data-tab="u-profile" onclick="UserApp.tab('u-profile')"><span class="icon">👤</span><span>Profile</span></div>
      </div>
    `;

    document.getElementById("u-header-av").innerHTML = C().ownerAvatarHtml();
    initProfile();
    refreshAll();
    loadMessages();
    bindChat();
    /* interstitial on tab change */
  }

  function tab(id) {
    document.querySelectorAll("#app .screen").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
    document.getElementById(id)?.classList.add("active");
    document.querySelector(`.nav-item[data-tab="${id}"]`)?.classList.add("active");
    if (id === "u-balance") {
      refreshBalance();
      renderTasks();
      Ads.updateAdButtons();
      if (window.Ads?.tryInterstitial) Ads.tryInterstitial();
    }
    if (id === "u-profile") {
      refreshProfile();
      C().refreshReferStats().then(refreshProfile);
      if (window.Ads?.tryInterstitial) Ads.tryInterstitial();
    }
    if (id === "u-chat") {
      refreshChatLimit();
      setTimeout(scrollBottom, 100);
    }
  }

  function initProfile() {
    const c = C();
    const pav = document.getElementById("u-pav");
    if (c.userPhoto) pav.innerHTML = `<img src="${c.userPhoto}" alt="">`;
    else pav.textContent = (c.userName[0] || "?").toUpperCase();
    document.getElementById("u-pname").textContent = c.userName;
    document.getElementById("u-phandle").textContent = c.userHandle;
    document.getElementById("u-pid").textContent = "ID: " + c.userId;
  }

  function refreshAll() {
    refreshBalance();
    refreshChatLimit();
    refreshProfile();
  }

  function refreshBalance() {
    const st = C().state;
    const el = document.getElementById("u-coins");
    if (el) el.textContent = st.coins;
    const gb = document.getElementById("gift-bal");
    if (gb) gb.textContent = st.coins;
  }

  function refreshChatLimit() {
    const sub = document.getElementById("u-chat-limit");
    const badge = document.getElementById("u-msg-badge");
    if (sub) sub.textContent = "Chat is free";
    if (badge) badge.style.display = "none";
  }

  function refreshProfile() {
    const st = C().state;
    const c = C();
    if (document.getElementById("u-s-coins")) document.getElementById("u-s-coins").textContent = st.coins;
    if (document.getElementById("u-s-earned")) document.getElementById("u-s-earned").textContent = st.totalEarned;
    if (document.getElementById("u-s-gifted")) document.getElementById("u-s-gifted").textContent = st.totalGifted;
    if (document.getElementById("u-s-refs")) document.getElementById("u-s-refs").textContent = st.myReferrals;
    if (document.getElementById("u-ref-link")) document.getElementById("u-ref-link").textContent = c.getReferLink();
    if (document.getElementById("u-ref-stats")) {
      document.getElementById("u-ref-stats").innerHTML =
        `Their messages: <b>${st.refMsgTotal}</b> · Your bonus: <b style="color:var(--gold)">${st.referBonusMsgs}</b>`;
    }
  }

  function renderTasks() {
    const tasks = (C().state.settings.tasks || []).filter(t => t.enabled !== false);
    const wrap = document.getElementById("u-tasks-wrap");
    const box = document.getElementById("u-tasks");
    if (!wrap || !box) return;
    if (!tasks.length) {
      wrap.style.display = "none";
      return;
    }
    wrap.style.display = "block";
    box.innerHTML = tasks.map(t => {
      const done = !!C().state.completedTasks[t.id];
      return `<div class="task-card ${done ? "done" : ""}">
        <div><div class="t-title">${C().esc(t.title)}</div>
        <div class="t-reward">+${t.rewardCoins || 0} coins · +${t.rewardMsgs || 0} msgs</div></div>
        <button class="t-btn" ${done ? "disabled" : ""} onclick="UserApp.doTask('${C().esc(t.id)}')">${done ? "Done ✓" : "Go"}</button>
      </div>`;
    }).join("");
  }

  async function doTask(taskId) {
    const c = C();
    if (c.state.completedTasks[taskId]) return;
    const t = (c.state.settings.tasks || []).find(x => x.id === taskId);
    if (!t) return;
    if (t.url && t.url.length > 8) {
      if (c.tg?.openLink) c.tg.openLink(t.url);
      else window.open(t.url, "_blank");
    }
    setTimeout(async () => {
      if (c.state.completedTasks[taskId]) return;
      c.state.completedTasks[taskId] = true;
      if (t.rewardCoins) {
        c.state.coins += t.rewardCoins;
        c.state.totalEarned += t.rewardCoins;
      }
      if (t.rewardMsgs) c.state.chatBonus += t.rewardMsgs;
      c.saveState();
      c.showToast("Task reward claimed!");
      refreshAll();
      renderTasks();
      try {
        await c.db.from("task_completions").upsert({
          user_id: c.userId, task_id: taskId, completed_at: new Date().toISOString()
        }, { onConflict: "user_id,task_id" });
      } catch (e) {}
    }, 2500);
  }

  function openGift() {
    document.getElementById("gift-bal").textContent = C().state.coins;
    document.getElementById("gift-modal").classList.add("show");
  }

  async function sendGift() {
    const c = C();
    const amount = parseInt(document.getElementById("gift-amount")?.value, 10);
    if (!amount || amount < c.CFG.MIN_GIFT) return c.showToast("Min " + c.CFG.MIN_GIFT);
    if (amount > c.state.coins) return c.showToast("Not enough coins");
    c.state.coins -= amount;
    c.state.totalGifted += amount;
    c.saveState();
    document.getElementById("gift-amount").value = "";
    document.getElementById("gift-modal").classList.remove("show");
    c.showToast(amount + " gifted!");
    refreshAll();
    try {
      await c.db.from("gifts").insert([{ user_id: c.userId, user_name: c.userName, amount }]);
    } catch (e) {}
  }

  function copyRef() {
    const link = C().getReferLink();
    if (navigator.clipboard) navigator.clipboard.writeText(link).then(() => C().showToast("Copied!"));
    else C().showToast(link);
  }

  async function loadMessages() {
    const c = C();
    const box = document.getElementById("u-messages");
    chatBox = box;
    try {
      const { data } = await c.db.from("messages")
        .select("*").eq("user_id", c.userId).order("created_at", { ascending: true });
      box.innerHTML = "";
      seenIds.clear();
      if (!data?.length) {
        box.innerHTML = '<div class="empty-state">No messages yet.<br>Say hello to Fariha!</div>';
      } else data.forEach(appendMsg);
      scrollBottom();
    } catch (e) {}
  }

  const seenIds = new Set();
  let replyTo = null; // { id, text, sender_type }
  let menuEl = null;
  let longPressTimer = null;

  function ensureMenu() {
    if (menuEl) return menuEl;
    menuEl = document.createElement("div");
    menuEl.className = "msg-menu";
    menuEl.id = "u-msg-menu";
    document.body.appendChild(menuEl);
    document.addEventListener("click", () => hideMenu());
    return menuEl;
  }

  function hideMenu() {
    if (menuEl) menuEl.classList.remove("show");
  }

  function showMenu(x, y, msg) {
    const menu = ensureMenu();
    const canDelete = msg.sender_type === "user" || true; // user can delete own; allow both for flexibility
    menu.innerHTML = `
      <button type="button" data-act="reply">↩ Reply</button>
      ${msg.sender_type === "user" ? '<button type="button" class="danger" data-act="delete">🗑 Delete</button>' : ''}
    `;
    menu.classList.add("show");
    const pad = 8;
    const rect = { w: 160, h: 100 };
    let left = x;
    let top = y;
    if (left + rect.w > window.innerWidth - pad) left = window.innerWidth - rect.w - pad;
    if (top + rect.h > window.innerHeight - pad) top = y - rect.h;
    menu.style.left = Math.max(pad, left) + "px";
    menu.style.top = Math.max(pad, top) + "px";
    menu.onclick = (e) => {
      e.stopPropagation();
      const act = e.target.getAttribute("data-act");
      hideMenu();
      if (act === "reply") setReplyTo(msg);
      if (act === "delete") deleteMessage(msg);
    };
  }

  function setReplyTo(msg) {
    if (!msg || msg.deleted_at) return;
    replyTo = { id: msg.id, text: msg.message, sender_type: msg.sender_type };
    const bar = document.getElementById("u-reply-bar");
    if (bar) {
      bar.classList.add("show");
      bar.querySelector(".rb-label").textContent = msg.sender_type === "user" ? "Replying to yourself" : "Replying to Fariha";
      bar.querySelector(".rb-text").textContent = msg.message || "";
    }
    document.getElementById("u-msg-input")?.focus();
  }

  function clearReplyTo() {
    replyTo = null;
    document.getElementById("u-reply-bar")?.classList.remove("show");
  }

  function ticksHtml(msg) {
    if (msg.sender_type !== "user") return "";
    if (msg._pending) return `<span class="msg-ticks sent">◌</span>`;
    if (msg.is_read) return `<span class="msg-ticks read">✓✓</span>`;
    return `<span class="msg-ticks sent">✓</span>`;
  }

  function timeStr(msg) {
    try {
      const d = new Date(msg.created_at || Date.now());
      return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    } catch (e) { return ""; }
  }

  function appendMsg(msg) {
    const box = document.getElementById("u-messages");
    if (!box) return;
    if (msg.id && seenIds.has(String(msg.id)) && !msg._force) {
      // update existing bubble (read / delete)
      const el = box.querySelector(`[data-id="${msg.id}"]`);
      if (el && msg.deleted_at) {
        el.classList.add("deleted");
        const tx = el.querySelector(".msg-text");
        if (tx) tx.textContent = "This message was deleted";
        el.querySelector(".msg-reply-quote")?.remove();
        return;
      }
      if (el && msg.is_read) {
        const tk = el.querySelector(".msg-ticks");
        if (tk) { tk.className = "msg-ticks read"; tk.textContent = "✓✓"; }
        return;
      }
      return;
    }
    if (msg.id) seenIds.add(String(msg.id));
    const empty = box.querySelector(".empty-state");
    if (empty) empty.remove();

    const div = document.createElement("div");
    div.className = "msg " + (msg.sender_type === "user" ? "user" : "admin") + (msg.deleted_at ? " deleted" : "");
    if (msg.id) div.dataset.id = msg.id;

    let html = "";
    if (msg.reply_to_id && msg._reply_preview) {
      html += `<div class="msg-reply-quote">${esc(msg._reply_preview)}</div>`;
    } else if (msg.reply_to_id) {
      html += `<div class="msg-reply-quote">Replying to a message</div>`;
    }
    if (msg.deleted_at) {
      html += `<div class="msg-text">This message was deleted</div>`;
    } else {
      html += `<div class="msg-text">${esc(msg.message || "")}</div>`;
    }
    html += `<div class="msg-meta"><span>${timeStr(msg)}</span>${ticksHtml(msg)}</div>`;
    div.innerHTML = html;

    // long-press / context
    if (!msg.deleted_at) {
      const open = (clientX, clientY) => showMenu(clientX, clientY, msg);
      div.addEventListener("contextmenu", e => { e.preventDefault(); open(e.clientX, e.clientY); });
      div.addEventListener("touchstart", e => {
        const t = e.touches[0];
        longPressTimer = setTimeout(() => open(t.clientX, t.clientY), 450);
      }, { passive: true });
      div.addEventListener("touchend", () => clearTimeout(longPressTimer));
      div.addEventListener("touchmove", () => clearTimeout(longPressTimer));
    }

    box.appendChild(div);
  }

  function esc(s) {
    return C().esc(String(s || ""));
  }

  function scrollBottom() {
    const box = document.getElementById("u-messages");
    if (box) requestAnimationFrame(() => { box.scrollTop = box.scrollHeight; });
  }

  async function resolveReplyPreviews(list) {
    const ids = [...new Set(list.filter(m => m.reply_to_id).map(m => m.reply_to_id))];
    if (!ids.length) return {};
    const map = {};
    list.forEach(m => { if (m.id) map[m.id] = m.message; });
    const missing = ids.filter(id => !map[id]);
    if (missing.length) {
      try {
        const { data } = await C().db.from("messages").select("id,message,deleted_at").in("id", missing);
        (data || []).forEach(r => { map[r.id] = r.deleted_at ? "Deleted message" : r.message; });
      } catch (e) {}
    }
    return map;
  }

  async function loadMessages() {
    const c = C();
    const box = document.getElementById("u-messages");
    chatBox = box;
    try {
      const { data } = await c.db.from("messages")
        .select("*").eq("user_id", c.userId).order("created_at", { ascending: true });
      box.innerHTML = "";
      seenIds.clear();
      const list = data || [];
      const previews = await resolveReplyPreviews(list);
      if (!list.length) {
        box.innerHTML = '<div class="empty-state">No messages yet.<br>Say hello to Fariha!</div>';
      } else {
        list.forEach(m => {
          if (m.reply_to_id) m._reply_preview = previews[m.reply_to_id] || "";
          appendMsg(m);
        });
      }
      scrollBottom();
    } catch (e) {}
  }

  async function sendMessage() {
    const c = C();
    const input = document.getElementById("u-msg-input");
    const text = input?.value.trim();
    if (!text) return;
    input.value = "";
    const tmpId = "tmp-" + Date.now();
    const local = {
      id: tmpId,
      message: text,
      sender_type: "user",
      created_at: new Date().toISOString(),
      is_read: false,
      _pending: true,
      reply_to_id: replyTo?.id || null,
      _reply_preview: replyTo?.text || null
    };
    appendMsg(local);
    scrollBottom();
    const replyId = replyTo?.id || null;
    clearReplyTo();
    try {
      await c.db.from("users").update({ last_active: new Date().toISOString() }).eq("user_id", c.userId);
    } catch (e) {}
    const row = {
      user_id: c.userId,
      user_name: c.userName,
      message: text,
      sender_type: "user",
      is_read: false
    };
    if (replyId) row.reply_to_id = replyId;
    const { data, error } = await c.db.from("messages").insert([row]).select().maybeSingle();
    if (error) {
      c.showToast("Send failed");
      return;
    }
    // replace tmp bubble id
    const el = document.querySelector(`#u-messages [data-id="${tmpId}"]`);
    if (el && data?.id) {
      seenIds.delete(tmpId);
      seenIds.add(String(data.id));
      el.dataset.id = data.id;
      const tk = el.querySelector(".msg-ticks");
      if (tk) { tk.className = "msg-ticks sent"; tk.textContent = "✓"; }
    } else if (data?.id) seenIds.add(String(data.id));
  }

  async function deleteMessage(msg) {
    if (!msg?.id || String(msg.id).startsWith("tmp")) return;
    const c = C();
    const { error } = await c.db.from("messages")
      .update({ deleted_at: new Date().toISOString(), message: "" })
      .eq("id", msg.id)
      .eq("user_id", c.userId);
    if (error) {
      c.showToast("Delete failed");
      return;
    }
    appendMsg({ ...msg, deleted_at: new Date().toISOString(), message: "", _force: true });
  }

  function bindChat() {
    // inject reply bar if missing
    const inputRow = document.querySelector("#u-chat .input-bar") || document.getElementById("u-msg-input")?.parentElement;
    if (inputRow && !document.getElementById("u-reply-bar")) {
      const bar = document.createElement("div");
      bar.className = "reply-bar";
      bar.id = "u-reply-bar";
      bar.innerHTML = `
        <div class="rb-body">
          <div class="rb-label">Reply</div>
          <div class="rb-text"></div>
        </div>
        <button type="button" class="rb-close" id="u-reply-close">✕</button>`;
      inputRow.parentElement.insertBefore(bar, inputRow);
      document.getElementById("u-reply-close").onclick = clearReplyTo;
    }

    document.getElementById("u-msg-input")?.addEventListener("keydown", e => {
      if (e.key === "Enter") { e.preventDefault(); sendMessage(); }
    });
    const c = C();
    c.db.channel("umsg:" + c.userId)
      .on("postgres_changes", {
        event: "INSERT", schema: "public", table: "messages",
        filter: "user_id=eq." + c.userId
      }, async payload => {
        const m = payload.new;
        if (!m) return;
        if (m.sender_type === "admin") {
          if (m.reply_to_id) {
            try {
              const { data: r } = await c.db.from("messages").select("message,deleted_at").eq("id", m.reply_to_id).maybeSingle();
              m._reply_preview = r?.deleted_at ? "Deleted message" : (r?.message || "");
            } catch (e) {}
          }
          appendMsg(m);
          scrollBottom();
          try { c.tg?.HapticFeedback?.impactOccurred?.("light"); } catch (e) {}
        } else if (m.id) {
          seenIds.add(String(m.id));
        }
      })
      .on("postgres_changes", {
        event: "UPDATE", schema: "public", table: "messages",
        filter: "user_id=eq." + c.userId
      }, payload => {
        const m = payload.new;
        if (!m) return;
        appendMsg({ ...m, _force: true });
      })
      .subscribe((status) => {
        if (status === "SUBSCRIBED") console.log("user chat realtime on");
      });
  }

  return {
    mount, tab, refreshBalance, refreshChatLimit, refreshAll,
    doTask, openGift, sendGift, copyRef, sendMessage
  };
})();
