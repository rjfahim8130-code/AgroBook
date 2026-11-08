window.Ads = (function () {
  const C = () => window.Core;
  const S = () => window.Core.state;
  const set = () => window.Core.state.settings;
  const CFG = () => window.APP_CONFIG;

  let interstitialTurn = 0; // 0 = adsgram, 1 = monetag
  let lastInterstitialAt = 0;

  function ensureCounts() {
    const st = S();
    if (!st.todayCount.adsgram) st.todayCount.adsgram = st.todayCount.adsgram || 0;
    if (!st.cooldownUntil.adsgram) st.cooldownUntil.adsgram = st.cooldownUntil.adsgram || 0;
    if (!st.streak) st.streak = { monetag: 0, popup: 0, adsgram: 0 };
    if (st.streak.adsgram == null) st.streak.adsgram = 0;
  }

  function confFor(kind) {
    // kind: adsgram | monetag | popup
    const se = set();
    const cfg = CFG();
    if (kind === "adsgram") {
      return se.adsgramRewarded || cfg.ADSGRAM_REWARDED || {
        dailyMax: 12, streakMax: 3, betweenCdMin: 2, streakCdMin: 60, coins: 15
      };
    }
    if (kind === "popup") {
      return se.popup || cfg.POPUP || {
        dailyMax: 10, streakMax: 3, betweenCdMin: 2, streakCdMin: 60, coins: 12
      };
    }
    return se.rewarded || cfg.REWARDED || {
      dailyMax: 10, streakMax: 3, betweenCdMin: 1, streakCdMin: 60, coins: 15
    };
  }

  function canWatch(kind) {
    ensureCounts();
    const st = S();
    const now = Date.now();
    const conf = confFor(kind);
    const key = kind === "popup" ? "popup" : kind;
    const daily = conf.dailyMax || 10;
    const count = kind === "popup"
      ? st.chatAdsToday
      : (st.todayCount[key] || 0);

    if (count >= daily) return { ok: false, reason: "Daily limit reached" };
    if ((st.cooldownUntil[key] || 0) > now) {
      return { ok: false, reason: "Wait " + C().formatRemain(st.cooldownUntil[key] - now) };
    }
    return { ok: true };
  }

  function afterWatch(kind) {
    ensureCounts();
    const st = S();
    const conf = confFor(kind);
    const key = kind === "popup" ? "popup" : kind;
    const now = Date.now();

    if (kind === "popup") st.chatAdsToday++;
    else st.todayCount[key] = (st.todayCount[key] || 0) + 1;

    st.streak[key] = (st.streak[key] || 0) + 1;
    const streakMax = conf.streakMax || 3;
    const betweenMs = (conf.betweenCdMin || 2) * 60 * 1000;
    const streakMs = (conf.streakCdMin || 60) * 60 * 1000;

    if (st.streak[key] >= streakMax) {
      st.cooldownUntil[key] = now + streakMs;
      st.streak[key] = 0;
    } else {
      st.cooldownUntil[key] = now + betweenMs;
    }

    // brief cross-cd for other coin sources
    if (kind === "adsgram" || kind === "monetag") {
      const otherEnd = now + (set().cooldown?.others || 60000);
      ["adsgram", "monetag", "adsterra", "hilltop"].forEach(k => {
        if (k === key) return;
        if ((st.cooldownUntil[k] || 0) < otherEnd) st.cooldownUntil[k] = otherEnd;
      });
    }

    if (kind === "popup") st.chatAdCooldownUntil = st.cooldownUntil.popup;
    C().saveState();
  }

  function initAdsgram(blockId) {
    try {
      if (!window.Adsgram || typeof window.Adsgram.init !== "function") return null;
      return window.Adsgram.init({ blockId: String(blockId) });
    } catch (e) {
      console.log("Adsgram init error", e);
      return null;
    }
  }

  function updateAdButtons() {
    ensureCounts();
    const now = Date.now();
    const st = S();
    const se = set();

    ["adsgram", "monetag"].forEach(key => {
      const btn = document.getElementById("btn-" + key);
      if (!btn) return;
      const chk = canWatch(key);
      btn.disabled = !chk.ok;
      const cd = btn.querySelector(".cd");
      if (cd) {
        cd.textContent = chk.ok ? "" : chk.reason;
        cd.style.display = chk.ok ? "none" : "block";
      }
    });
    // monetag popup button
    const pbtn = document.getElementById("btn-monetag-popup");
    if (pbtn) {
      const chk = canWatch("popup");
      pbtn.disabled = !chk.ok;
      const cd = pbtn.querySelector(".cd");
      if (cd) {
        cd.textContent = chk.ok ? "" : chk.reason;
        cd.style.display = chk.ok ? "none" : "block";
      }
    }

    ["adsterra", "hilltop"].forEach(key => {
      const btn = document.getElementById("btn-" + key);
      if (!btn) return;
      const cdEl = btn.querySelector(".cd");
      let disabled = false, reason = "";
      if (se.smartlinkEnabled[key] === false) { disabled = true; reason = "Off"; }
      else if ((st.todayCount[key] || 0) >= (se.dailyLimit[key] || 0)) { disabled = true; reason = "Limit"; }
      else if ((st.cooldownUntil[key] || 0) > now) {
        disabled = true; reason = C().formatRemain(st.cooldownUntil[key] - now);
      }
      btn.disabled = disabled;
      if (cdEl) {
        cdEl.textContent = reason;
        cdEl.style.display = reason ? "block" : "none";
      }
    });
  }

  // ===== ADSGRAM REWARDED (coins) =====
  function watchAdsgram() {
    const c = C();
    if (c.isAdmin) return;
    const chk = canWatch("adsgram");
    if (!chk.ok) return c.showToast(chk.reason);

    const blockId = CFG().ADSGRAM?.rewardedBlockId || "58681";
    const ctrl = initAdsgram(blockId);
    if (!ctrl) return c.showToast("Adsgram not loaded");

    const btn = document.getElementById("btn-adsgram");
    if (btn) btn.disabled = true;

    ctrl.show()
      .then(() => {
        afterWatch("adsgram");
        const coins = confFor("adsgram").coins || 15;
        c.addCoins(coins, "adsgram");
        if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
        updateAdButtons();
      })
      .catch(() => {
        c.showToast("Ad failed / closed");
        updateAdButtons();
      });
  }

  // ===== MONETAG REWARDED (coins backup) =====
  function watchMonetag() {
    const c = C();
    if (c.isAdmin) return;
    const chk = canWatch("monetag");
    if (!chk.ok) return c.showToast(chk.reason);
    const btn = document.getElementById("btn-monetag");
    if (btn) btn.disabled = true;
    c.showMonetag()
      .then(() => {
        afterWatch("monetag");
        const coins = confFor("monetag").coins || set().coinReward.monetag || 15;
        c.addCoins(coins, "monetag");
        if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
        updateAdButtons();
      })
      .catch(() => {
        c.showToast("Ad failed");
        updateAdButtons();
      });
  }

  // ===== MONETAG POPUP = coins only =====
  function watchMonetagPopup() {
    const c = C();
    if (c.isAdmin) return;
    const chk = canWatch("popup");
    if (!chk.ok) return c.showToast(chk.reason);
    c.showMonetag("pop")
      .then(() => {
        afterWatch("popup");
        const coins = confFor("popup").coins || 12;
        c.addCoins(coins, "monetag");
        // also count toward popup daily via afterWatch
        c.showToast("+" + coins + " coins!");
        document.getElementById("chat-limit-modal")?.classList.remove("show");
        document.getElementById("need-coins-modal")?.classList.remove("show");
        if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
        if (window.UserApp?.refreshChatLimit) window.UserApp.refreshChatLimit();
        updateAdButtons();
      })
      .catch(() => c.showToast("Ad failed"));
  }

  // keep alias for old HTML
  function watchChatPopup() { return watchMonetagPopup(); }

  function openSmartlink(network) {
    const c = C();
    if (c.isAdmin) return;
    const st = S();
    const se = set();
    if (se.smartlinkEnabled[network] === false) return c.showToast("Disabled");
    if (!se.smartlinks[network]) return;
    if ((st.todayCount[network] || 0) >= (se.dailyLimit[network] || 0)) return c.showToast("Limit");
    if (Date.now() < (st.cooldownUntil[network] || 0)) return c.showToast("Cooldown");
    c.applyCooldown(network);
    const url = se.smartlinks[network];
    if (c.tg?.openLink) c.tg.openLink(url);
    else window.open(url, "_blank");
    setTimeout(() => {
      c.addCoins(se.coinReward[network] || 8, network);
      if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
    }, 1800);
  }

  // ===== INTERSTITIAL ROTATION (Adsgram <-> Monetag), min 8 min =====
  function tryInterstitial() {
    const c = C();
    if (c.isAdmin) return;
    const now = Date.now();
    const gapMs = 8 * 60 * 1000;
    if (now - lastInterstitialAt < gapMs) return;

    const useAdsgram = interstitialTurn % 2 === 0;
    interstitialTurn++;

    if (useAdsgram) {
      const blockId = CFG().ADSGRAM?.interstitialBlockId || "int-58682";
      const ctrl = initAdsgram(blockId);
      if (!ctrl) {
        // fallback monetag
        tryMonetagInterstitial();
        return;
      }
      lastInterstitialAt = now;
      ctrl.show().catch(() => {});
    } else {
      tryMonetagInterstitial();
    }
  }

  function tryMonetagInterstitial() {
    const c = C();
    lastInterstitialAt = Date.now();
    const it = set().interstitial || CFG().INTERSTITIAL || {};
    try {
      c.showMonetag({
        type: "inApp",
        inAppSettings: {
          frequency: it.frequency || 2,
          capping: it.cappingHours || 0.1,
          interval: it.intervalSec || 30,
          timeout: it.timeoutSec || 5,
          everyPage: false
        }
      }).catch(() => {});
    } catch (e) {}
  }

  // ===== TASK (Adsgram native task block) =====
  function showAdsgramTask(containerId) {
    const box = document.getElementById(containerId);
    if (!box) return;
    const blockId = CFG().ADSGRAM?.taskBlockId || "task-58683";
    // Task format often uses data attribute / container — render placeholder button that opens via SDK if available
    box.innerHTML = `
      <div class="task-card">
        <div>
          <div class="t-title">Sponsored Task</div>
          <div class="t-reward">Complete & earn coins</div>
        </div>
        <button class="t-btn" id="btn-adsgram-task">Go</button>
      </div>`;
    const btn = document.getElementById("btn-adsgram-task");
    if (!btn) return;
    btn.onclick = () => {
      const c = C();
      const ctrl = initAdsgram(blockId);
      if (!ctrl) {
        c.showToast("Task ad unavailable");
        return;
      }
      ctrl.show()
        .then(() => {
          c.addCoins(10, "adsgram");
          if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
          c.showToast("+10 coins (task)");
        })
        .catch(() => c.showToast("Task not completed"));
    };
  }

  setInterval(updateAdButtons, 1000);

  return {
    updateAdButtons,
    watchAdsgram,
    watchMonetag,
    watchChatPopup, watchMonetagPopup,
    openSmartlink,
    tryInterstitial,
    showAdsgramTask,
    canWatch
  };
})();
