(function () {
    const CFG = window.APP_CONFIG;
    const tg = window.Telegram?.WebApp;

    if (tg) {
        tg.ready();
        tg.expand();
        try {
            tg.setHeaderColor("#1a1a1a");
            tg.setBackgroundColor("#0f0f0f");
        } catch (e) {}
    }

    const user = tg?.initDataUnsafe?.user || null;
    const userId = user ? user.id : 99999999;
    const userName = user
        ? user.first_name + (user.last_name ? " " + user.last_name : "")
        : "অতিথি";
    const userHandle = user?.username ? "@" + user.username : "নেই";
    const userPhoto = user?.photo_url || null;

    // ===== ADMIN CHECK =====
    const isAdmin = CFG.ADMIN_IDS.includes(Number(userId));

    // ===== SUPABASE =====
    const _supabase = supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY);

    // ===== STATE =====
    let coins = 0;
    let totalEarned = 0;
    let totalGifted = 0;
    let todayCount = { monetag: 0, adsterra: 0, hilltop: 0 };
    // cooldown end timestamps
    let cooldownUntil = { monetag: 0, adsterra: 0, hilltop: 0 };

    const LS_KEY = `fariha_v2_${userId}`;

    function loadState() {
        try {
            const raw = localStorage.getItem(LS_KEY);
            if (!raw) return;
            const d = JSON.parse(raw);
            const today = new Date().toDateString();
            coins = d.coins || 0;
            totalEarned = d.totalEarned || 0;
            totalGifted = d.totalGifted || 0;
            if (d.date === today) {
                todayCount = d.todayCount || todayCount;
            }
            // restore cooldowns if still in future
            if (d.cooldownUntil) {
                const now = Date.now();
                Object.keys(d.cooldownUntil).forEach(k => {
                    if (d.cooldownUntil[k] > now) cooldownUntil[k] = d.cooldownUntil[k];
                });
            }
        } catch (e) {}
    }

    function saveState() {
        localStorage.setItem(LS_KEY, JSON.stringify({
            coins,
            totalEarned,
            totalGifted,
            todayCount,
            cooldownUntil,
            date: new Date().toDateString()
        }));
    }

    function showToast(msg) {
        const t = document.getElementById("toast");
        if (!t) return;
        t.textContent = msg;
        t.classList.add("show");
        setTimeout(() => t.classList.remove("show"), 2500);
    }

    function updateUI() {
        const el = (id) => document.getElementById(id);
        if (el("coin-balance")) el("coin-balance").textContent = coins;
        if (el("gift-balance")) el("gift-balance").textContent = coins;
        if (el("stat-balance")) el("stat-balance").textContent = coins;
        if (el("stat-earned")) el("stat-earned").textContent = totalEarned;
        if (el("stat-gifted")) el("stat-gifted").textContent = totalGifted;

        if (el("limit-info")) {
            el("limit-info").textContent =
                `আজকের লিমিট: Monetag ${todayCount.monetag}/${CFG.DAILY_LIMIT.monetag} • ` +
                `Adsterra ${todayCount.adsterra}/${CFG.DAILY_LIMIT.adsterra} • ` +
                `Hilltop ${todayCount.hilltop}/${CFG.DAILY_LIMIT.hilltop}`;
        }
        updateAdButtons();
    }

    // ===== COOLDOWN + LIMIT LOGIC =====
    function formatRemain(ms) {
        if (ms <= 0) return "";
        const s = Math.ceil(ms / 1000);
        if (s < 60) return s + " সেকেন্ড";
        const m = Math.ceil(s / 60);
        return m + " মিনিট";
    }

    function updateAdButtons() {
        const now = Date.now();
        const keys = ["monetag", "adsterra", "hilltop"];

        keys.forEach(key => {
            const btn = document.getElementById("btn-" + key);
            if (!btn) return;

            const cdEl = btn.querySelector(".cd-text");
            let disabled = false;
            let reason = "";

            // daily limit
            if (todayCount[key] >= CFG.DAILY_LIMIT[key]) {
                disabled = true;
                reason = "আজকের লিমিট শেষ";
            }
            // cooldown
            else if (cooldownUntil[key] > now) {
                disabled = true;
                reason = formatRemain(cooldownUntil[key] - now) + " পর আবার";
            }

            btn.disabled = disabled;
            if (cdEl) {
                cdEl.textContent = reason;
                cdEl.style.display = reason ? "block" : "none";
            }
        });
    }

    // tick every second to update cooldown labels
    setInterval(updateAdButtons, 1000);

    function applyCooldown(clickedKey) {
        const now = Date.now();
        const keys = ["monetag", "adsterra", "hilltop"];

        keys.forEach(key => {
            if (key === clickedKey) {
                // clicked one → 45 min
                cooldownUntil[key] = now + CFG.COOLDOWN.self;
            } else {
                // others → 1 min (only if their current cooldown is shorter)
                const otherEnd = now + CFG.COOLDOWN.others;
                if (cooldownUntil[key] < otherEnd) {
                    cooldownUntil[key] = otherEnd;
                }
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
        showToast(`+${amount} কয়েন যোগ হয়েছে!`);
    }

    // ===== REWARD ACTIONS =====
    window.watchMonetagRewarded = function () {
        if (isAdmin) return;
        if (todayCount.monetag >= CFG.DAILY_LIMIT.monetag) {
            showToast("আজকের Monetag লিমিট শেষ");
            return;
        }
        if (Date.now() < cooldownUntil.monetag) {
            showToast("কুলডাউন চলছে");
            return;
        }

        // Monetag SDK পরে যোগ হবে — এখন ডেমো
        if (confirm("Monetag Rewarded অ্যাড দেখবেন? (ডেমো)")) {
            applyCooldown("monetag");
            addCoins(CFG.COIN_REWARD.monetag, "monetag");
        }
    };

    window.openSmartlink = function (network) {
        if (isAdmin) return;
        if (!CFG.SMARTLINKS[network]) return;

        if (todayCount[network] >= CFG.DAILY_LIMIT[network]) {
            showToast("আজকের লিমিট শেষ");
            return;
        }
        if (Date.now() < cooldownUntil[network]) {
            showToast("কুলডাউন চলছে");
            return;
        }

        const url = CFG.SMARTLINKS[network];
        applyCooldown(network);

        if (tg?.openLink) {
            tg.openLink(url);
        } else {
            window.open(url, "_blank");
        }

        setTimeout(() => {
            addCoins(CFG.COIN_REWARD[network] || 8, network);
        }, 1800);
    };

    // ===== GIFT =====
    window.setGiftAmount = function (val) {
        const inp = document.getElementById("gift-amount");
        if (inp) inp.value = val;
    };

    window.sendGift = async function () {
        const amount = parseInt(document.getElementById("gift-amount")?.value, 10);
        if (!amount || amount < CFG.MIN_GIFT) {
            showToast("কমপক্ষে " + CFG.MIN_GIFT + " কয়েন দিন");
            return;
        }
        if (amount > coins) {
            showToast("পর্যাপ্ত কয়েন নেই");
            return;
        }

        coins -= amount;
        totalGifted += amount;
        saveState();
        updateUI();
        document.getElementById("gift-amount").value = "";
        showToast(amount + " কয়েন ফারিহাকে পাঠানো হয়েছে 🎁");

        try {
            await _supabase.from("gifts").insert([{
                user_id: userId,
                user_name: userName,
                amount: amount
            }]);
        } catch (e) {}
    };

    // ===== NAVIGATION =====
    window.switchScreen = function (id) {
        document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
        document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
        const screen = document.getElementById(id);
        if (screen) screen.classList.add("active");

        const map = {
            "screen-home": "nav-home",
            "screen-earn": "nav-earn",
            "screen-chat": "nav-chat",
            "screen-profile": "nav-profile",
            "screen-gift": "nav-home",
            "screen-admin": "nav-home"
        };
        if (map[id]) document.getElementById(map[id])?.classList.add("active");

        if (id === "screen-chat") {
            loadMessages();
            setTimeout(() => {
                scrollToBottom();
                document.getElementById("message-input")?.focus();
            }, 150);
        }
        if (id === "screen-gift") {
            const gb = document.getElementById("gift-balance");
            if (gb) gb.textContent = coins;
        }
        if (id === "screen-admin" && isAdmin) {
            loadAdminPanel();
        }
    };

    // ===== PROFILE + HEADER AVATAR =====
    function initProfile() {
        const nameEl = document.getElementById("profile-name");
        const userEl = document.getElementById("profile-username");
        const idEl = document.getElementById("profile-id");
        const avatarEl = document.getElementById("profile-avatar");

        if (nameEl) {
            nameEl.innerHTML = userName + (isAdmin ? ' <span class="admin-badge">ADMIN</span>' : "");
        }
        if (userEl) userEl.textContent = "ইউজারনেম: " + userHandle;
        if (idEl) idEl.textContent = "টেলিগ্রাম আইডি: " + userId;

        if (avatarEl) {
            if (userPhoto) {
                avatarEl.innerHTML = `<img src="${userPhoto}" alt="">`;
            } else if (userName && userName !== "অতিথি") {
                avatarEl.textContent = userName.charAt(0).toUpperCase();
            }
        }

        // Header branding — Fariha name + owner photo
        updateHeaderAvatars();
    }

    function updateHeaderAvatars() {
        // Prefer OWNER_PHOTO_URL, else if current user is admin use their photo
        const photo = CFG.OWNER_PHOTO_URL || (isAdmin && userPhoto ? userPhoto : null);
        document.querySelectorAll(".header-avatar-slot").forEach(slot => {
            if (photo) {
                slot.innerHTML = `<img class="header-avatar" src="${photo}" alt="Fariha">`;
            } else {
                slot.innerHTML = `<div class="header-avatar placeholder">ফ</div>`;
            }
        });
    }

    // ===== ADMIN UI TOGGLE =====
    function applyAdminMode() {
        // Hide earn section ads for admin
        const earnScreen = document.getElementById("screen-earn");
        if (isAdmin && earnScreen) {
            const body = earnScreen.querySelector(".earn-body");
            if (body) {
                body.innerHTML = `
                    <div class="earn-info" style="margin-top:40px;">
                        আপনি অ্যাডমিন।<br>
                        বিজ্ঞাপন আপনার জন্য বন্ধ আছে।
                    </div>
                `;
            }
        }

        // Show admin menu button only for admin
        document.querySelectorAll(".admin-only").forEach(el => {
            if (isAdmin) {
                el.classList.remove("hidden");
            } else {
                el.classList.add("hidden");
            }
        });

        // Hide earn nav emphasis for admin optional — keep nav but content different
    }

    // ===== CHAT =====
    const chatContainer = () => document.getElementById("chat-container");
    const messageInput = () => document.getElementById("message-input");

    async function loadMessages() {
        const box = chatContainer();
        if (!box) return;
        try {
            const { data, error } = await _supabase
                .from("messages")
                .select("*")
                .eq("user_id", userId)
                .order("created_at", { ascending: true });

            if (error) {
                console.error(error);
                return;
            }
            box.innerHTML = "";
            if (!data || data.length === 0) {
                box.innerHTML = `<div class="empty-chat" id="empty-chat">এখনো কোনো মেসেজ নেই।<br>নিচে লিখে পাঠান!</div>`;
            } else {
                data.forEach(msg => appendMessageUI(msg));
                scrollToBottom();
            }
        } catch (e) {
            console.error(e);
        }
    }

    window.sendMessage = async function () {
        const input = messageInput();
        const text = input?.value.trim();
        if (!text) return;
        input.value = "";

        const empty = document.getElementById("empty-chat");
        if (empty) empty.remove();

        appendMessageUI({
            message: text,
            sender_type: "user"
        });
        scrollToBottom();

        const { error } = await _supabase.from("messages").insert([{
            user_id: userId,
            user_name: userName,
            message: text,
            sender_type: "user"
        }]);

        if (error) {
            showToast("মেসেজ পাঠাতে সমস্যা হয়েছে");
            console.error(error);
        }
    };

    function appendMessageUI(msg) {
        const box = chatContainer();
        if (!box) return;
        const div = document.createElement("div");
        div.classList.add("message");
        div.classList.add(msg.sender_type === "user" ? "user-msg" : "admin-msg");
        div.textContent = msg.message;
        box.appendChild(div);
    }

    function scrollToBottom() {
        const box = chatContainer();
        if (!box) return;
        requestAnimationFrame(() => {
            box.scrollTop = box.scrollHeight;
        });
    }

    // Realtime
    _supabase
        .channel("public:messages:" + userId)
        .on("postgres_changes", {
            event: "INSERT",
            schema: "public",
            table: "messages",
            filter: `user_id=eq.${userId}`
        }, payload => {
            if (payload.new.sender_type === "admin") {
                const empty = document.getElementById("empty-chat");
                if (empty) empty.remove();
                appendMessageUI(payload.new);
                scrollToBottom();
            }
        })
        .subscribe();

    // Enter to send
    document.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && document.activeElement?.id === "message-input") {
            e.preventDefault();
            window.sendMessage();
        }
    });

    // ===== INLINE ADMIN PANEL (for admin inside mini app) =====
    let adminCurrentUserId = null;
    let adminCurrentUserName = "";

    async function loadAdminPanel() {
        const list = document.getElementById("admin-user-list");
        if (!list) return;
        list.innerHTML = `<div class="empty-chat">লোড হচ্ছে...</div>`;

        const { data, error } = await _supabase
            .from("messages")
            .select("user_id, user_name, created_at, message")
            .order("created_at", { ascending: false });

        if (error) {
            list.innerHTML = `<div class="empty-chat">এরর: ${error.message}</div>`;
            return;
        }

        const map = {};
        (data || []).forEach(m => {
            if (!map[m.user_id]) {
                map[m.user_id] = {
                    user_id: m.user_id,
                    user_name: m.user_name || "Unknown",
                    last_msg: m.message,
                    last_at: m.created_at,
                    count: 0
                };
            }
            map[m.user_id].count++;
        });

        const users = Object.values(map).sort((a, b) => new Date(b.last_at) - new Date(a.last_at));

        if (users.length === 0) {
            list.innerHTML = `<div class="empty-chat">এখনো কোনো মেসেজ নেই</div>`;
            return;
        }

        list.innerHTML = users.map(u => `
            <div class="menu-btn" style="margin-bottom:8px;" onclick="openAdminChat(${u.user_id}, '${String(u.user_name).replace(/'/g, "\\'")}')">
                <div>
                    <div style="font-weight:600;">${escapeHtml(u.user_name)}</div>
                    <div style="font-size:11px;color:var(--text2);">ID: ${u.user_id} • ${u.count} মেসেজ</div>
                </div>
                <span class="arrow">→</span>
            </div>
        `).join("");
    }

    window.openAdminChat = async function (uid, uname) {
        adminCurrentUserId = uid;
        adminCurrentUserName = uname;
        document.getElementById("admin-chat-title").textContent = uname + " (" + uid + ")";
        document.getElementById("admin-chat-panel").style.display = "flex";
        document.getElementById("admin-user-list").style.display = "none";

        const box = document.getElementById("admin-chat-messages");
        const { data } = await _supabase
            .from("messages")
            .select("*")
            .eq("user_id", uid)
            .order("created_at", { ascending: true });

        box.innerHTML = (data || []).map(m => `
            <div class="message ${m.sender_type === 'admin' ? 'user-msg' : 'admin-msg'}" style="align-self:${m.sender_type === 'admin' ? 'flex-end' : 'flex-start'}">
                ${escapeHtml(m.message)}
            </div>
        `).join("") || `<div class="empty-chat">মেসেজ নেই</div>`;
        box.scrollTop = box.scrollHeight;
    };

    window.closeAdminChat = function () {
        document.getElementById("admin-chat-panel").style.display = "none";
        document.getElementById("admin-user-list").style.display = "flex";
        adminCurrentUserId = null;
        loadAdminPanel();
    };

    window.sendAdminReply = async function () {
        const input = document.getElementById("admin-reply-input");
        const text = input?.value.trim();
        if (!text || !adminCurrentUserId) return;
        input.value = "";

        const { error } = await _supabase.from("messages").insert([{
            user_id: adminCurrentUserId,
            user_name: adminCurrentUserName,
            message: text,
            sender_type: "admin"
        }]);

        if (error) {
            showToast("রিপ্লাই ব্যর্থ");
            return;
        }
        openAdminChat(adminCurrentUserId, adminCurrentUserName);
        showToast("রিপ্লাই পাঠানো হয়েছে");
    };

    function escapeHtml(str) {
        if (!str) return "";
        return String(str)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    // ===== INIT =====
    loadState();
    initProfile();
    applyAdminMode();
    updateUI();

    // Expose for debugging
    window.__isAdmin = isAdmin;
    window.__userId = userId;
})();
