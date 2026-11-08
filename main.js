(async function () {
  const C = window.Core;
  const root = document.getElementById("app");

  C.loadState();
  await C.loadRemoteSettings();
  await C.loadCompletedTasks();
  await C.registerUser();

  if (!C.userId) {
    root.innerHTML = '<div class="empty-state">Open this app from Telegram.</div>';
    return;
  }

  // STRICT split: admin never sees user UI, user never sees admin UI
  if (C.isAdmin) {
    window.AdminApp.mount(root);
  } else {
    window.UserApp.mount(root);
    await C.refreshReferStats();
    if (window.UserApp.refreshAll) window.UserApp.refreshAll();
  }
})();
