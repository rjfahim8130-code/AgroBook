window.Ads = (function () {
  const C = () => window.Core;
  const S = () => window.Core.state;
  const set = () => window.Core.state.settings;

  function updateAdButtons() {
    const now = Date.now();
    const st = S();
    const se = set();
    ["monetag", "adsterra", "hilltop"].forEach(key => {
      const btn = document.getElementById("btn-" + key);
      if (!btn) return;
      const cdEl = btn.querySelector(".cd");
      let disabled = false, reason = "";
      if (key !== "monetag" && se.smartlinkEnabled[key] === false) {
        disabled = true; reason = "Off";
      } else if (st.todayCount[key] >= (se.dailyLimit[key] || 0)) {
        disabled = true; reason = "Limit";
      } else if (st.cooldownUntil[key] > now) {
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
    const st = S();
    const se = set();
    if (st.todayCount.monetag >= se.dailyLimit.monetag) return c.showToast("Daily limit");
    if (Date.now() < st.cooldownUntil.monetag) return c.showToast("Cooldown");
    const btn = document.getElementById("btn-monetag");
    if (btn) btn.disabled = true;
    c.showMonetag()
      .then(() => {
        c.applyCooldown("monetag");
        c.addCoins(se.coinReward.monetag, "monetag");
        if (window.UserApp && window.UserApp.refreshBalance) window.UserApp.refreshBalance();
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
      if (window.UserApp && window.UserApp.refreshBalance) window.UserApp.refreshBalance();
    }, 1800);
  }

  function watchChatPopup() {
    const c = C();
    if (c.isAdmin) return;
    const st = S();
    const se = set();
    if (st.chatAdsToday >= se.chat.maxAdsPerDay) return c.showToast("Chat ad limit today");
    if (Date.now() < st.chatAdCooldownUntil) {
      return c.showToast("Wait " + c.formatRemain(st.chatAdCooldownUntil - Date.now()));
    }
    c.showMonetag("pop")
      .then(() => {
        st.chatBonus += se.chat.rewardPerAd;
        st.chatAdsToday++;
        st.chatAdCooldownUntil = Date.now() + se.chat.adCooldownMs;
        c.saveState();
        c.showToast("+" + se.chat.rewardPerAd + " messages!");
        document.getElementById("chat-limit-modal")?.classList.remove("show");
        if (window.UserApp && window.UserApp.refreshChatLimit) window.UserApp.refreshChatLimit();
      })
      .catch(() => c.showToast("Ad failed"));
  }

  setInterval(updateAdButtons, 1000);

  return { updateAdButtons, watchMonetag, openSmartlink, watchChatPopup };
})();
