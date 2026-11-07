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
    const isAdmin = CFG.ADMIN_IDS.includes(Number(userId));

    const _supabase = supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY);

    // Runtime settings (can be overridden from Supabase by admin)
    let settings = {
        smartlinks: { ...CFG.SMARTLINKS },
        smartlinkEnabled: { adsterra: true, hilltop: true },
        coinReward: { ...CFG.COIN_REWARD },
        dailyLimit: { ...CFG.DAILY_LIMIT },
        cooldown: { ...CFG.COOLDOWN },
        chat: { ...CFG.CHAT }
    };

    // ===== STATE =====
    let coins = 0;
    let totalEarned = 0;
    let totalGifted = 0;
    let todayCount = { monetag: 0, adsterra: 0, hilltop: 0 };
    let cooldownUntil = { monetag: 0, adsterra: 0, hilltop: 0 };

    // Chat limit state
    let chatUsed = 0;
    let chatBonus = 0;
    let chatAdsToday = 0;
    let chatAdCooldownUntil = 0;

    const LS_KEY = `fariha_v3_${userId}`;
    const todayStr = () => new Date().toDateString();

    function loadState() {
        try {
            const raw = localStorage.getItem(LS_KEY);
            if (!raw) return;
            const d = JSON.parse(raw);
            coins = d.coins || 0;
            totalEarned = d.totalEarned || 0;
            totalGifted = d.totalGifted || 0;
            if (d.date === todayStr()) {
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
            if (d.chatAdCooldownUntil && d.chatAdCooldownUntil > Date.now()) {
                chatAdCooldownUntil = d.chatAdCooldownUntil;
            }
        } catch (e) {}
    }

    function saveState() {
        localStorage.setItem(LS_KEY, JSON.stringify({
            coins, totalEarned, totalGifted, todayCount, cooldownUntil,
            chatUsed, chatBonus, chatAdsToday, chatAdCooldownUntil,
            date: todayStr()
        }));
    }

    function chatRemaining() {
        if (isAdmin) return 9999;
        return Math.max(0, settings.chat.freePerDay + chatBonus - chatUsed);
    }

    function showToast(msg) {
        const t = document.getElementById("toast");
        if (!t) return;
        t.textContent = msg;
        t.classList.add("show");
        setTimeout(() => t.classList.remove("show"), 2800);
    }

    function updateUI() {
        const el = (id) => document.getElementById(id);
        if (el("coin-balance")) el("coin-balance").textContent = coins;
        if (el("gift-balance")) el("gift-balance").textContent = coins;
        if (el("stat-balance")) el("stat-balance").textContent = coins;
        if (el("stat-earned")) el("stat-earned").textContent = totalEarned;
        if (el("stat-gifted")) el("stat-gifted").textContent = totalGifted;

        const rem = chatRemaining();
        if (el("chat-limit-info")) {
            el("chat-limit-info").textContent = isAdmin
                ? "অ্যাডমিন — আনলিমিটেড চ্যাট"
                : `বাকি মেসেজ: ${rem} (ফ্রি ${settings.chat.freePerDay} + বোনাস ${chatBonus})`;
        }
        if (el("chat-limit-badge")) {
            el("chat-limit-badge").textContent = isAdmin ? "∞" : String(rem);
        }

        if (el("limit-info")) {
            el("limit-info").textContent =
                `কয়েন লিমিট: M ${todayCount.monetag}/${settings.dailyLimit.monetag} • ` +
                `A ${todayCount.adsterra}/${settings.dailyLimit.adsterra} • ` +
                `H ${todayCount.hilltop}/${settings.dailyLimit.hilltop}`;
        }
        updateAdButtons();
        updateChatLimitModal();
    }

    function formatRemain(ms) {
        if (ms <= 0) return "";
        const s = Math.ceil(ms / 1000);
        if (s < 60) return s + " সেকেন্ড";
        return Math.ceil(s / 60) + " মিনিট";
    }

    function updateAdButtons() {
        const now = Date.now();
        ["monetag", "adsterra", "hilltop"].forEach(key => {
            const btn = document.getElementById("btn-" + key);
            if (!btn) return;
            const cdEl = btn.querySelector(".cd-text");
            let disabled = false;
            let reason = "";

            if (key !== "monetag" && settings.smartlinkEnabled[key] === false) {
                disabled = true;
                reason = "বন্ধ আছে";
            } else if (todayCount[key] >= (settings.dailyLimit[key] || 0)) {
                disabled = true;
                reason = "আজকের লিমিট শেষ";
            } else if (cooldownUntil[key] > now) {
                disabled = true;
                reason = formatRemain(cooldownUntil[key] - now) + " পর";
            }

            btn.disabled = disabled;
            if (cdEl) {
                cdEl.textContent = reason;
                cdEl.style.display = reason ? "block" : "none";
            }
        });
    }
    setInterval(updateAdButtons, 1000);

    function applyCooldown(clickedKey) {
        const now = Date.now();
        ["monetag", "adsterra", "hilltop"].forEach(key => {
            if (key === clickedKey) {
                cooldownUntil[key] = now + settings.cooldown.self;
            } else {
                const otherEnd = now + settings.cooldown.others;
                if (cooldownUntil[key] < otherEnd) cooldownUntil[key] = otherEnd;
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

    // ===== MONETAG SDK =====
    function callMonetag(opts) {
        const fnName = CFG.MONETAG_SHOW_FN || "show_12212096";
        const fn = window[fnName];
        if (typeof fn !== "function") {
            return Promise.reject(new Error("Monetag SDK not loaded"));
        }
        // opts: { type: 'end' | 'pop' | 'start', ymid: '...' }
        return fn(opts || {});
    }

    // 1) কয়েন — Rewarded Interstitial
    window.watchMonetagRewarded = function () {
        if (isAdmin) return;
        if (todayCount.monetag >= settings.dailyLimit.monetag) {
            showToast("আজকের Monetag লিমিট শেষ");
            return;
        }
        if (Date.now() < cooldownUntil.monetag) {
            showToast("কুলডাউন চলছে");
            return;
        }

        const btn = document.getElementById("btn-monetag");
        if (btn) btn.disabled = true;

        const ymid = `coin_${userId}_${Date.now()}`;
        callMonetag({ type: "end", ymid: ymid })
            .then(() => {
                applyCooldown("monetag");
                addCoins(settings.coinReward.monetag, "monetag");
            })
            .catch((err) => {
                console.error("Monetag coin error:", err);
                showToast("অ্যাড লোড হয়নি, আবার চেষ্টা করুন");
                updateAdButtons();
            });
    };

    // 2) চ্যাট লিমিট — Rewarded Popup
    window.watchChatLimitAd = function () {
        if (isAdmin) return;
        if (chatAdsToday >= settings.chat.maxAdsPerDay) {
            showToast("আজকের চ্যাট অ্যাড লিমিট শেষ");
            return;
        }
        if (Date.now() < chatAdCooldownUntil) {
            showToast(formatRemain(chatAdCooldownUntil - Date.now()) + " পর আবার চেষ্টা করুন");
            return;
        }

        const ymid = `chat_${userId}_${Date.now()}`;
        callMonetag({ type: "pop", ymid: ymid })
            .then(() => {
                chatBonus += settings.chat.rewardPerAd;
                chatAdsToday++;
                chatAdCooldownUntil = Date.now() + settings.chat.adCooldownMs;
                saveState();
                updateUI();
                hideChatLimitModal();
                showToast(`+${settings.chat.rewardPerAd} মেসেজ যোগ হয়েছে!`);
            })
            .catch((err) => {
                console.error("Monetag chat popup error:", err);
                showToast("অ্যাড লোড হয়নি");
            });
    };

    // Smartlinks
    window.openSmartlink = function (network) {
        if (isAdmin) return;
        if (settings.smartlinkEnabled[network] === false) {
            showToast("এই অফার এখন বন্ধ");
            return;
        }
        if (!settings.smartlinks[network]) return;
        if (todayCount[network] >= settings.dailyLimit[network]) {
            showToast("আজকের লিমিট শেষ");
            return;
        }
        if (Date.now() < cooldownUntil[network]) {
            showToast("কুলডাউন চলছে");
            return;
        }

        const url = settings.smartlinks[network];
        applyCooldown(network);

        if (tg?.openLink) tg.openLink(url);
        else window.open(url, "_blank");

        setTimeout(() => {
            addCoins(settings.coinReward[network] || 8, network);
        }, 1800);
    };

    // ===== CHAT LIMIT MODAL =====
    function showChatLimitModal() {
        const m = document.getElementById("chat-limit-modal");
        if (m) m.classList.add("show");
    }
    function hideChatLimitModal() {
        const m = document.getElementById("chat-limit-modal");
        if (m) m.classList.remove("show");
    }
    function updateChatLimitModal() {
        const el = document.getElementById("modal-chat-info");
        if (!el) return;
        const left = settings.chat.maxAdsPerDay - chatAdsToday;
        const cd = chatAdCooldownUntil > Date.now()
            ? formatRemain(chatAdCooldownUntil - Date.now()) + " পর আবার পারবেন"
            : "এখনই দেখতে পারবেন";
        el.innerHTML = `প্রতি অ্যাডে <b>+${settings.chat.rewardPerAd}</b> মেসেজ<br>` +
            `আজ বাকি অ্যাড: <b>${left}</b> • ${cd}`;
    }
    window.hideChatLimitModal = hideChatLimitModal;

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
                user_id: userId, user_name: userName, amount: amount
            }]);
        } catch (e) {}
    };

    // ===== NAV =====
    window.switchScreen = function (id) {
        document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
        document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
        document.getElementById(id)?.classList.add("active");

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
            updateUI();
        }
        if (id === "screen-gift") {
            const gb = document.getElementById("gift-balance");
            if (gb) gb.textContent = coins;
        }
        if (id === "screen-admin" && isAdmin) {
            loadAdminPanel();
            loadAdminSettingsForm();
        }
    };

    // ===== PROFILE =====
    function initProfile() {
        const nameEl = document.getElementById("profile-name");
        const userEl = document.getElementById("profile-username");
        const idEl = document.getElementById("profile-id");
        const avatarEl = document.getElementById("profile-avatar");

        if (nameEl) nameEl.innerHTML = userName + (isAdmin ? ' <span class="admin-badge">ADMIN</span>' : "");
        if (userEl) userEl.textContent = "ইউজারনেম: " + userHandle;
        if (idEl) idEl.textContent = "টেলিগ্রাম আইডি: " + userId;

        if (avatarEl) {
            if (userPhoto) avatarEl.innerHTML = `<img src="${userPhoto}" alt="">`;
            else if (userName && userName !== "অতিথি") avatarEl.textContent = userName.charAt(0).toUpperCase();
        }

        const photo = CFG.OWNER_PHOTO_URL || (isAdmin && userPhoto ? userPhoto : null);
        document.querySelectorAll(".header-avatar-slot").forEach(slot => {
            if (photo) slot.innerHTML = `<img class="header-avatar" src="${photo}" alt="Fariha">`;
            else slot.innerHTML = `<div class="header-avatar placeholder">ফ</div>`;
        });
    }

    function applyAdminMode() {
        if (isAdmin) {
            const earnScreen = document.getElementById("screen-earn");
            const body = earnScreen?.querySelector(".earn-body");
            if (body) {
                body.innerHTML = `<div class="earn-info" style="margin-top:40px;">আপনি অ্যাডমিন।<br>বিজ্ঞাপন আপনার জন্য বন্ধ।</div>`;
            }
        }
        document.querySelectorAll(".admin-only").forEach(el => {
            if (isAdmin) el.classList.remove("hidden");
            else el.classList.add("hidden");
        });
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
            if (error) return;
            box.innerHTML = "";
            if (!data || data.length === 0) {
                box.innerHTML = `<div class="empty-chat" id="empty-chat">এখনো কোনো মেসেজ নেই।<br>নিচে লিখে পাঠান!</div>`;
            } else {
                data.forEach(msg => appendMessageUI(msg));
                scrollToBottom();
            }
        } catch (e) {}
    }

    window.sendMessage = async function () {
        const input = messageInput();
        const text = input?.value.trim();
        if (!text) return;

        // Chat limit check
        if (!isAdmin && chatRemaining() <= 0) {
            showChatLimitModal();
            return;
        }

        input.value = "";
        const empty = document.getElementById("empty-chat");
        if (empty) empty.remove();

        appendMessageUI({ message: text, sender_type: "user" });
        scrollToBottom();

        if (!isAdmin) {
            chatUsed++;
            saveState();
            updateUI();
        }

        const { error } = await _supabase.from("messages").insert([{
            user_id: userId,
            user_name: userName,
            message: text,
            sender_type: "user"
        }]);
        if (error) showToast("মেসেজ পাঠাতে সমস্যা হয়েছে");
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
        requestAnimationFrame(() => { box.scrollTop = box.scrollHeight; });
    }

    document.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && document.activeElement?.id === "message-input") {
            e.preventDefault();
            window.sendMessage();
        }
    });

    _supabase
        .channel("public:messages:" + userId)
        .on("postgres_changes", {
            event: "INSERT", schema: "public", table: "messages",
            filter: `user_id=eq.${userId}`
        }, payload => {
            if (payload.new.sender_type === "admin") {
                document.getElementById("empty-chat")?.remove();
                appendMessageUI(payload.new);
                scrollToBottom();
            }
        })
        .subscribe();

    // ===== ADMIN PANEL =====
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
                    last_at: m.created_at,
                    count: 0
                };
            }
            map[m.user_id].count++;
        });
        const users = Object.values(map).sort((a, b) => new Date(b.last_at) - new Date(a.last_at));

        if (!users.length) {
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
        document.getElementById("admin-settings-box")?.classList.add("hidden");

        const box = document.getElementById("admin-chat-messages");
        const { data } = await _supabase
            .from("messages").select("*").eq("user_id", uid).order("created_at", { ascending: true });

        box.innerHTML = (data || []).map(m => `
            <div class="message ${m.sender_type === 'admin' ? 'user-msg' : 'admin-msg'}"
                 style="align-self:${m.sender_type === 'admin' ? 'flex-end' : 'flex-start'}">
                ${escapeHtml(m.message)}
            </div>
        `).join("") || `<div class="empty-chat">মেসেজ নেই</div>`;
        box.scrollTop = box.scrollHeight;
    };

    window.closeAdminChat = function () {
        document.getElementById("admin-chat-panel").style.display = "none";
        document.getElementById("admin-user-list").style.display = "flex";
        document.getElementById("admin-settings-box")?.classList.remove("hidden");
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
        if (error) showToast("রিপ্লাই ব্যর্থ");
        else {
            openAdminChat(adminCurrentUserId, adminCurrentUserName);
            showToast("রিপ্লাই পাঠানো হয়েছে");
        }
    };

    // ===== ADMIN SETTINGS (Smartlink control) =====
    async function loadRemoteSettings() {
        try {
            const { data } = await _supabase
                .from("app_settings")
                .select("value")
                .eq("key", "main")
                .maybeSingle();
            if (data?.value) {
                const v = data.value;
                if (v.smartlinks) settings.smartlinks = { ...settings.smartlinks, ...v.smartlinks };
                if (v.smartlinkEnabled) settings.smartlinkEnabled = { ...settings.smartlinkEnabled, ...v.smartlinkEnabled };
                if (v.coinReward) settings.coinReward = { ...settings.coinReward, ...v.coinReward };
                if (v.dailyLimit) settings.dailyLimit = { ...settings.dailyLimit, ...v.dailyLimit };
                if (v.cooldown) {
                    settings.cooldown = {
                        others: (v.cooldown.othersMin || 1) * 60 * 1000,
                        self: (v.cooldown.selfMin || 45) * 60 * 1000
                    };
                }
                if (v.chat) {
                    settings.chat = {
                        freePerDay: v.chat.freePerDay ?? settings.chat.freePerDay,
                        rewardPerAd: v.chat.rewardPerAd ?? settings.chat.rewardPerAd,
                        adCooldownMs: (v.chat.adCooldownMin || 15) * 60 * 1000,
                        maxAdsPerDay: v.chat.maxAdsPerDay ?? settings.chat.maxAdsPerDay
                    };
                }
            }
        } catch (e) {
            console.log("settings load skip", e);
        }
    }

    function loadAdminSettingsForm() {
        const box = document.getElementById("admin-settings-box");
        if (!box || !isAdmin) return;

        const s = settings;
        document.getElementById("set-adsterra-url").value = s.smartlinks.adsterra || "";
        document.getElementById("set-hilltop-url").value = s.smartlinks.hilltop || "";
        document.getElementById("set-adsterra-on").checked = s.smartlinkEnabled.adsterra !== false;
        document.getElementById("set-hilltop-on").checked = s.smartlinkEnabled.hilltop !== false;
        document.getElementById("set-adsterra-coin").value = s.coinReward.adsterra;
        document.getElementById("set-hilltop-coin").value = s.coinReward.hilltop;
        document.getElementById("set-adsterra-limit").value = s.dailyLimit.adsterra;
        document.getElementById("set-hilltop-limit").value = s.dailyLimit.hilltop;
        document.getElementById("set-cd-self").value = Math.round(s.cooldown.self / 60000);
        document.getElementById("set-cd-others").value = Math.round(s.cooldown.others / 60000);
        document.getElementById("set-chat-free").value = s.chat.freePerDay;
        document.getElementById("set-chat-reward").value = s.chat.rewardPerAd;
        document.getElementById("set-chat-cd").value = Math.round(s.chat.adCooldownMs / 60000);
        document.getElementById("set-chat-max").value = s.chat.maxAdsPerDay;
    }

    window.saveAdminSettings = async function () {
        if (!isAdmin) return;

        const payload = {
            smartlinks: {
                adsterra: document.getElementById("set-adsterra-url").value.trim(),
                hilltop: document.getElementById("set-hilltop-url").value.trim()
            },
            smartlinkEnabled: {
                adsterra: document.getElementById("set-adsterra-on").checked,
                hilltop: document.getElementById("set-hilltop-on").checked
            },
            coinReward: {
                monetag: settings.coinReward.monetag,
                adsterra: parseInt(document.getElementById("set-adsterra-coin").value, 10) || 8,
                hilltop: parseInt(document.getElementById("set-hilltop-coin").value, 10) || 8
            },
            dailyLimit: {
                monetag: settings.dailyLimit.monetag,
                adsterra: parseInt(document.getElementById("set-adsterra-limit").value, 10) || 6,
                hilltop: parseInt(document.getElementById("set-hilltop-limit").value, 10) || 6
            },
            cooldown: {
                selfMin: parseInt(document.getElementById("set-cd-self").value, 10) || 45,
                othersMin: parseInt(document.getElementById("set-cd-others").value, 10) || 1
            },
            chat: {
                freePerDay: parseInt(document.getElementById("set-chat-free").value, 10) || 10,
                rewardPerAd: parseInt(document.getElementById("set-chat-reward").value, 10) || 20,
                adCooldownMin: parseInt(document.getElementById("set-chat-cd").value, 10) || 15,
                maxAdsPerDay: parseInt(document.getElementById("set-chat-max").value, 10) || 5
            }
        };

        // Apply locally
        settings.smartlinks = payload.smartlinks;
        settings.smartlinkEnabled = payload.smartlinkEnabled;
        settings.coinReward = payload.coinReward;
        settings.dailyLimit = payload.dailyLimit;
        settings.cooldown = {
            self: payload.cooldown.selfMin * 60 * 1000,
            others: payload.cooldown.othersMin * 60 * 1000
        };
        settings.chat = {
            freePerDay: payload.chat.freePerDay,
            rewardPerAd: payload.chat.rewardPerAd,
            adCooldownMs: payload.chat.adCooldownMin * 60 * 1000,
            maxAdsPerDay: payload.chat.maxAdsPerDay
        };

        try {
            const { error } = await _supabase.from("app_settings").upsert({
                key: "main",
                value: payload,
                updated_at: new Date().toISOString()
            });
            if (error) {
                // table may not exist — still works locally for this session
                console.warn(error);
                showToast("লোকাল সেভ হয়েছে (Supabase টেবিল চেক করুন)");
            } else {
                showToast("সেটিংস সেভ হয়েছে ✓");
            }
        } catch (e) {
            showToast("লোকাল সেভ হয়েছে");
        }
        updateUI();
    };

    function escapeHtml(str) {
        if (!str) return "";
        return String(str)
            .replace(/&/g, "&amp;").replace(/</g, "&lt;")
            .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    // ===== AUTO INTERSTITIAL =====
    function showAutoInterstitial() {
        if (isAdmin) return;
        // In-app style — use default/end without granting coins
        callMonetag({ type: "end", ymid: `auto_${userId}_${Date.now()}` }).catch(() => {});
    }

    // ===== INIT =====
    async function init() {
        loadState();
        await loadRemoteSettings();
        initProfile();
        applyAdminMode();
        updateUI();

        if (!isAdmin && CFG.AUTO_INTERSTITIAL_MINUTES > 0) {
            setInterval(showAutoInterstitial, CFG.AUTO_INTERSTITIAL_MINUTES * 60 * 1000);
            setTimeout(showAutoInterstitial, 45 * 1000);
        }
    }

    init();

    window.__isAdmin = isAdmin;
    window.__userId = userId;
})();
