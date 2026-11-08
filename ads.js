window.Ads = (function () {
  const C = () => window.Core;
  const S = () => window.Core.state;
  const set = () => window.Core.state.settings;
  const CFG = () => window.APP_CONFIG;

  let lastInterstitialAt = 0;

  function ensureCounts() {
    const st = S();
    if (!st.todayCount) st.todayCount = {};
    ["monetag", "adsterra", "hilltop", "popup"].forEach(k => {
      if (st.todayCount[k] == null) st.todayCount[k] = 0;
      if (st.cooldownUntil[k] == null) st.cooldownUntil[k] = 0;
    });
    if (!st.streak) st.streak = { monetag: 0, popup: 0 };
  }

  function confFor(kind) {
    const se = set();
    const cfg = CFG();
    if (kind === "popup") {
      return se.popup || cfg.POPUP || {
        dailyMax: 10, streakMax: 3, betweenCdMin: 2, streakCdMin: 60, coins: 12
      };
    }
    return se.rewarded || cfg.REWARDED || {
      dailyMax: 15, streakMax: 3, betweenCdMin: 1, streakCdMin: 60, coins: 15
    };
  }

  function canWatch(kind) {
    ensureCounts();
    const st = S();
    const now = Date.now();
    const conf = confFor(kind);
    const key = kind === "popup" ? "popup" : "monetag";
    const daily = conf.dailyMax || 10;
    const count = kind === "popup" ? (st.chatAdsToday || 0) : (st.todayCount.monetag || 0);
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
    const key = kind === "popup" ? "popup" : "monetag";
    const now = Date.now();
    if (kind === "popup") st.chatAdsToday = (st.chatAdsToday || 0) + 1;
    else st.todayCount.monetag = (st.todayCount.monetag || 0) + 1;
    st.streak[key] = (st.streak[key] || 0) + 1;
    const streakMax = conf.streakMax || 3;
    const betweenMs = (conf.betweenCdMin || 1) * 60 * 1000;
    const streakMs = (conf.streakCdMin || 60) * 60 * 1000;
    if (st.streak[key] >= streakMax) {
      st.cooldownUntil[key] = now + streakMs;
      st.streak[key] = 0;
    } else {
      st.cooldownUntil[key] = now + betweenMs;
    }
    if (kind === "monetag") {
      const otherEnd = now + (set().cooldown?.others || 60000);
      ["adsterra", "hilltop"].forEach(k => {
        if ((st.cooldownUntil[k] || 0) < otherEnd) st.cooldownUntil[k] = otherEnd;
      });
    }
    C().saveState();
  }

  function updateAdButtons() {
    ensureCounts();
    const now = Date.now();
    const st = S();
    const se = set();

    const mBtn = document.getElementById("btn-monetag");
    if (mBtn) {
      const chk = canWatch("monetag");
      mBtn.disabled = !chk.ok;
      const cd = mBtn.querySelector(".cd");
      if (cd) {
        cd.textContent = chk.ok ? "" : chk.reason;
        cd.style.display = chk.ok ? "none" : "block";
      }
    }
    const pBtn = document.getElementById("btn-monetag-popup");
    if (pBtn) {
      const chk = canWatch("popup");
      pBtn.disabled = !chk.ok;
      const cd = pBtn.querySelector(".cd");
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
        c.showToast("+" + coins + " coins!");
        document.getElementById("need-coins-modal")?.classList.remove("show");
        if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
        updateAdButtons();
      })
      .catch(() => c.showToast("Ad failed"));
  }

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

  function tryInterstitial() {
    const c = C();
    if (c.isAdmin) return;
    const now = Date.now();
    if (now - lastInterstitialAt < 8 * 60 * 1000) return;
    lastInterstitialAt = now;
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

  // no-ops kept so old calls don't break
  function watchAdsgram() { C().showToast("Adsgram disabled"); }
  function showAdsgramTask() {}

  setInterval(updateAdButtons, 1000);

  return {
    updateAdButtons,
    watchMonetag,
    watchMonetagPopup,
    watchChatPopup,
    openSmartlink,
    tryInterstitial,
    watchAdsgram,
    showAdsgramTask,
    canWatch
  };
})();
