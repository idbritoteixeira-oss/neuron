/**
 * /assets/js/enxos-core.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Core obrigatório do ecossistema enxOS.
 * Responsabilidades:
 *   1. Tema claro/escuro — aplica imediatamente (sem flash)
 *   2. Sincronismo hexcor — lê r2021.php e aplica cor de fundo dinâmica
 *   3. Atualiza o rodapé {/enxOS <timestamp>}
 *
 * API pública:
 *   EnxCore.toggleTema()         — alterna e persiste o tema
 *   EnxCore.getTema()            → 'light' | 'dark'
 *   EnxCore.buscarDadoCron()     — força atualização do cron
 * ─────────────────────────────────────────────────────────────────────────────
 */

const EnxCore = (() => {
    const CRON_URL      = 'https://tts.enxos.online/s/r2021.php';
    const CRON_INTERVAL = 12000;
    const THEME_KEY      = 'enxos_theme'; // localStorage key

    // ── Tema ──────────────────────────────────────────────────────────────────

    /**
     * Aplica o tema no <html> via data-theme="light"|"dark".
     * O CSS reage via [data-theme="dark"] — sem flash porque roda
     * antes do primeiro render (script síncrono no <head>).
     */
    function _actionTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem(THEME_KEY, theme);

        // Atualiza ícone do botão de toggle se existir na página
        const btn   = document.getElementById('theme-toggle-btn');
        const icon  = document.getElementById('theme-toggle-icon');
        const label = document.getElementById('theme-toggle-label');
        if (icon)  icon.textContent  = theme === 'dark' ? '🌝' : '🌚';
        if (label) label.textContent = theme === 'dark' ? 'light' : 'dark';
        if (btn)   btn.title         = theme === 'dark' ? 'Mudar para Claro' : 'Mudar para Escuro';
    }

    function getTheme() {
        return localStorage.getItem(THEME_KEY) || 'light';
    }

    function toggleTheme() {
        const news = getTheme() === 'dark' ? 'light' : 'dark';
        _actionTheme(news);
        return news;
    }

    // Aplica imediatamente ao carregar — evita flash de tema errado
    _actionTheme(getTheme());

    // ── Cron hexcor ───────────────────────────────────────────────────────────

    function hexcor() {
        fetch(CRON_URL)
            .then(r => r.text())
            .then(raw => {
                const dtts = raw.trim();

                const el = document.getElementById('watercolor');
                if (el) el.innerText = `{/enxOS ${dtts}`;

                if (dtts.length >= 3) {
                    const tres = dtts.slice(-3);
                    const cor  = `#${tres}${tres}`;
                    // No dark mode aplica a cor só no fundo do body (não no card)
                    document.documentElement.style.backgroundColor = cor;
                    document.body.style.backgroundColor            = cor;
                }
            })
            .catch(() => {});
    }

    hexcor();
    setInterval(hexcor, CRON_INTERVAL);

    return { toggleTheme, getTheme, hexcor };
})();