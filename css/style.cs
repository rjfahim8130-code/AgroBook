:root {
    --bg: #0f0f0f;
    --surface: #1a1a1a;
    --surface2: #242424;
    --gold: #d4af37;
    --gold-dark: #b8962e;
    --text: #ffffff;
    --text2: #aaaaaa;
    --success: #22c55e;
    --danger: #ef4444;
    --radius: 14px;
    --nav-h: 62px;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background: var(--bg);
    color: var(--text);
    height: 100vh;
    height: 100dvh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

.screen {
    display: none;
    flex: 1;
    flex-direction: column;
    overflow: hidden;
    min-height: 0;
}
.screen.active { display: flex; }
.screen.with-nav { padding-bottom: var(--nav-h); }

.header {
    padding: 12px 16px;
    text-align: center;
    font-weight: 700;
    font-size: 16px;
    background: var(--surface);
    border-bottom: 1px solid rgba(255,255,255,0.08);
    color: var(--gold);
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
}
.header-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    object-fit: cover;
    border: 1.5px solid var(--gold);
    background: linear-gradient(135deg, var(--gold), #8a7020);
}
.header-avatar.placeholder {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: 800;
    color: #000;
}

.home-body, .earn-body, .gift-body, .profile-body {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 14px;
    -webkit-overflow-scrolling: touch;
}

.balance-card {
    background: linear-gradient(145deg, #2a2418, #1a1a1a);
    border: 1px solid var(--gold);
    border-radius: 18px;
    padding: 22px 18px;
    text-align: center;
}
.balance-label { font-size: 13px; color: var(--text2); }
.balance-amount {
    font-size: 32px;
    font-weight: 800;
    color: var(--gold);
    margin: 6px 0 4px;
}
.balance-sub { font-size: 12px; color: var(--text2); }

.menu-btn {
    background: var(--surface);
    border: 1px solid rgba(255,255,255,0.07);
    border-radius: var(--radius);
    padding: 16px 18px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    cursor: pointer;
    font-size: 15px;
    font-weight: 500;
}
.menu-btn:active { background: var(--surface2); }
.menu-btn .arrow { color: var(--gold); font-size: 18px; }
.menu-btn.admin-only {
    border-color: var(--gold);
    background: linear-gradient(135deg, #2a2418, #1a1a1a);
}
.menu-btn.hidden { display: none !important; }

.earn-info {
    text-align: center;
    color: var(--text2);
    font-size: 14px;
    line-height: 1.5;
}

.ad-btn {
    width: 100%;
    padding: 16px;
    border: none;
    border-radius: 14px;
    font-size: 15px;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    transition: opacity 0.2s;
}
.ad-btn.primary { background: var(--gold); color: #000; }
.ad-btn.secondary {
    background: var(--surface2);
    color: var(--text);
    border: 1px solid rgba(255,255,255,0.12);
}
.ad-btn .sub { font-size: 12px; font-weight: 500; opacity: 0.8; }
.ad-btn:active:not(:disabled) { opacity: 0.85; }
.ad-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
    filter: grayscale(0.6);
}
.ad-btn .cd-text {
    font-size: 11px;
    font-weight: 600;
    color: var(--danger);
    margin-top: 2px;
}

.limit-box {
    background: var(--surface);
    border-radius: 12px;
    padding: 12px 16px;
    font-size: 13px;
    color: var(--text2);
    text-align: center;
}

.gift-input-wrap {
    background: var(--surface);
    border-radius: 14px;
    padding: 16px;
}
.gift-input-wrap label {
    font-size: 13px;
    color: var(--text2);
    display: block;
    margin-bottom: 8px;
}
.gift-input-wrap input {
    width: 100%;
    background: var(--surface2);
    border: 1px solid #444;
    color: #fff;
    padding: 12px 14px;
    border-radius: 10px;
    font-size: 18px;
    font-weight: 700;
    outline: none;
}
.gift-presets { display: flex; gap: 8px; flex-wrap: wrap; }
.preset-btn {
    flex: 1;
    min-width: 70px;
    padding: 10px;
    background: var(--surface2);
    border: 1px solid rgba(255,255,255,0.1);
    color: var(--text);
    border-radius: 10px;
    font-weight: 600;
    cursor: pointer;
}
.preset-btn:active { border-color: var(--gold); color: var(--gold); }
.gift-submit {
    width: 100%;
    padding: 16px;
    background: var(--gold);
    color: #000;
    border: none;
    border-radius: 14px;
    font-size: 16px;
    font-weight: 700;
    cursor: pointer;
    margin-top: 8px;
}
.gift-submit:active { opacity: 0.9; }

/* CHAT */
#screen-chat { padding-bottom: 0 !important; }
#chat-container {
    flex: 1;
    overflow-y: auto;
    padding: 14px 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    min-height: 0;
    -webkit-overflow-scrolling: touch;
}
.message {
    max-width: 78%;
    padding: 10px 13px;
    border-radius: 14px;
    font-size: 14px;
    line-height: 1.45;
    word-wrap: break-word;
}
.user-msg {
    background: var(--gold);
    color: #000;
    align-self: flex-end;
    border-bottom-right-radius: 4px;
    font-weight: 500;
}
.admin-msg {
    background: var(--surface2);
    color: #fff;
    align-self: flex-start;
    border-bottom-left-radius: 4px;
}
.chat-input-wrap {
    flex-shrink: 0;
    background: var(--surface);
    border-top: 1px solid rgba(255,255,255,0.08);
    padding: 10px 12px;
    padding-bottom: calc(10px + var(--nav-h));
    display: flex;
    gap: 8px;
    align-items: center;
}
.chat-input-wrap input {
    flex: 1;
    padding: 11px 14px;
    background: #2c2c2c;
    border: 1px solid #444;
    color: #fff;
    border-radius: 22px;
    outline: none;
    font-size: 14px;
}
.send-btn {
    background: var(--gold);
    color: #000;
    border: none;
    padding: 11px 18px;
    border-radius: 22px;
    font-weight: 700;
    cursor: pointer;
    font-size: 14px;
    flex-shrink: 0;
}
.empty-chat {
    text-align: center;
    color: var(--text2);
    padding: 40px 20px;
    font-size: 14px;
    line-height: 1.6;
}

/* PROFILE */
.profile-card {
    background: var(--surface);
    border-radius: 16px;
    padding: 24px 18px;
    text-align: center;
    border: 1px solid rgba(255,255,255,0.06);
}
.profile-avatar {
    width: 72px;
    height: 72px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--gold), #8a7020);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
    font-weight: 800;
    color: #000;
    margin: 0 auto 12px;
    object-fit: cover;
    border: 2px solid var(--gold);
}
.profile-avatar img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
}
.profile-name {
    font-size: 18px;
    font-weight: 700;
    color: var(--gold);
    margin-bottom: 4px;
}
.profile-meta {
    font-size: 13px;
    color: var(--text2);
    margin-top: 6px;
}
.stats-row {
    display: flex;
    gap: 10px;
    margin-top: 20px;
}
.stat-box {
    flex: 1;
    background: var(--surface2);
    border-radius: 12px;
    padding: 14px 8px;
    text-align: center;
}
.stat-value {
    font-size: 18px;
    font-weight: 700;
    color: var(--gold);
}
.stat-label {
    font-size: 11px;
    color: var(--text2);
    margin-top: 4px;
}

/* BOTTOM NAV */
.bottom-nav {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: var(--nav-h);
    background: var(--surface);
    border-top: 1px solid rgba(255,255,255,0.08);
    display: flex;
    justify-content: space-around;
    align-items: center;
    z-index: 100;
    padding-bottom: env(safe-area-inset-bottom, 0);
}
.nav-item {
    flex: 1;
    text-align: center;
    color: var(--text2);
    font-size: 11px;
    cursor: pointer;
    padding: 6px 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
}
.nav-item .icon { font-size: 20px; line-height: 1; }
.nav-item.active {
    color: var(--gold);
    font-weight: 700;
}

/* TOAST */
.toast {
    position: fixed;
    top: 18px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--surface2);
    color: #fff;
    padding: 12px 22px;
    border-radius: 30px;
    font-size: 14px;
    font-weight: 600;
    z-index: 999;
    opacity: 0;
    transition: opacity 0.3s;
    pointer-events: none;
    border: 1px solid var(--gold);
    white-space: nowrap;
    max-width: 90vw;
}
.toast.show { opacity: 1; }

/* Admin badge */
.admin-badge {
    display: inline-block;
    background: var(--gold);
    color: #000;
    font-size: 10px;
    font-weight: 800;
    padding: 2px 8px;
    border-radius: 10px;
    margin-left: 6px;
    vertical-align: middle;
}
