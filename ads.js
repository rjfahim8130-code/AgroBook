window.Ads = (function () {
  const C = () => window.Core;
  const S = () => window.Core.state;
  const set = () => window.Core.state.settings;

  function canWatch(kind) {
    // kind: 'monetag' | 'popup'
    const st = S();
    const se = set();
    const now = Date.now();
    const conf = kind === "popup" ? se.popup : se.rewarded;
    const key = kind === "popup" ? "popup" : "monetag";
    const daily = conf.dailyMax ?? (kind === "popup" ? se.chat.maxAdsPerDay : se.dailyLimit.monetag);
    const count = kind === "popup" ? st.chatAdsToday : st.todayCount.monetag;

    if (count >= daily) return { ok: false, reason: "Daily limit reached" };
    if (st.cooldownUntil[key] > now) {
      return { ok: false, reason: "Wait " + C().formatRemain(st.cooldownUntil[key] - now) };
    }
    return { ok: true };
  }

  function afterWatch(kind) {
    const st = S();
    const se = set();
    const conf = kind === "popup" ? se.popup : se.rewarded;
    const key = kind === "popup" ? "popup" : "monetag";
    const now = Date.now();

    if (kind === "popup") st.chatAdsToday++;
    else st.todayCount.monetag++;

    st.streak[key] = (st.streak[key] || 0) + 1;
    const streakMax = conf.streakMax || 3;
    const betweenMs = (conf.betweenCdMin || 1) * 60 * 1000;
    const streakMs = (conf.streakCdMin || 60) * 60 * 1000;

    if (st.streak[key] >= streakMax) {
      // long cooldown after streak
      st.cooldownUntil[key] = now + streakMs;
      st.streak[key] = 0;
    } else {
      st.cooldownUntil[key] = now + betweenMs;
    }

    // cross-disable other coin ads briefly for monetag
    if (kind === "monetag") {
      const otherEnd = now + (se.cooldown?.others || 60000);
      ["adsterra", "hilltop"].forEach(k => {
        if (st.cooldownUntil[k] < otherEnd) st.cooldownUntil[k] = otherEnd;
      });
    }

    C().saveState();
  }

  function updateAdButtons() {
    const now = Date.now();
    const st = S();
    const se = set();

    // monetag button
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

    ["adsterra", "hilltop"].forEach(key => {
      const btn = document.getElementById("btn-" + key);
      if (!btn) return;
      const cdEl = btn.querySelector(".cd");
      let disabled = false, reason = "";
      if (se.smartlinkEnabled[key] === false) { disabled = true; reason = "Off"; }
      else if (st.todayCount[key] >= (se.dailyLimit[key] || 0)) { disabled = true; reason = "Limit"; }
      else if (st.cooldownUntil[key] > now) { disabled = true; reason = C().formatRemain(st.cooldownUntil[key] - now); }
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
    const se = set();
    const btn = document.getElementById("btn-monetag");
    if (btn) btn.disabled = true;
    c.showMonetag()
      .then(() => {
        afterWatch("monetag");
        const coins = se.rewarded?.coins || se.coinReward.monetag || 15;
        c.addCoins(coins, "monetag");
        if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
        updateAdButtons();
      })
      .catch(() => {
        c.showToast("Ad failed");
        updateAdButtons();
      });
  }

  function openSmartlink(network) {
    const c = C();
    if (c.isAdmin) return;
    const st = S();
    const se = set();
    if (se.smartlinkEnabled[network] === false) return c.showToast("Disabled");
    if (!se.smartlinks[network]) return;
    if (st.todayCount[network] >= se.dailyLimit[network]) return c.showToast("Limit");
    if (Date.now() < st.cooldownUntil[network]) return c.showToast("Cooldown");
    c.applyCooldown(network);
    const url = se.smartlinks[network];
    if (c.tg?.openLink) c.tg.openLink(url);
    else window.open(url, "_blank");
    setTimeout(() => {
      c.addCoins(se.coinReward[network] || 8, network);
      if (window.UserApp?.refreshBalance) window.UserApp.refreshBalance();
    }, 1800);
  }

  function watchChatPopup() {
    const c = C();
    if (c.isAdmin) return;
    const chk = canWatch("popup");
    if (!chk.ok) return c.showToast(chk.reason);
    const se = set();
    c.showMonetag("pop")
      .then(() => {
        afterWatch("popup");
        const msgs = se.popup?.rewardMsgs || se.chat.rewardPerAd || 20;
        S().chatBonus += msgs;
        // keep legacy field in sync
        S().chatAdCooldownUntil = S().cooldownUntil.popup;
        c.saveState();
        c.showToast("+" + msgs + " messages!");
        document.getElementById("chat-limit-modal")?.classList.remove("show");
        if (window.UserApp?.refreshChatLimit) window.UserApp.refreshChatLimit();
        updateAdButtons();
      })
      .catch(() => c.showToast("Ad failed"));
  }

  setInterval(updateAdButtons, 1000);

  return { updateAdButtons, watchMonetag, openSmartlink, watchChatPopup, canWatch };
})();
