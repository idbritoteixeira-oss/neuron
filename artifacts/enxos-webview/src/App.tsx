import { useEffect, useState, type FormEvent, type ReactNode } from 'react';
import { Route, Switch, useLocation, Router as WouterRouter } from 'wouter';
import {
  ArrowLeft,
  CheckCircle2,
  Eye,
  EyeOff,
  Info,
  KeyRound,
  LockKeyhole,
  MoreVertical,
  Send,
  Settings2,
  ShieldCheck,
  Store,
  Sun,
  Moon,
  Tag,
  X,
  BellRing,
  Network,
} from 'lucide-react';

type ModuleKey = 'inasx' | 'pigeon' | 'freemarket';
type ModuleInfo = { key: ModuleKey; title: string; id: string; description: string };
const moduleList: ModuleInfo[] = [
  { key: 'inasx', title: 'Inasx', id: 'id_inx', description: 'Espaço operacional Inasx' },
  { key: 'pigeon', title: 'Pigeon', id: 'id_pru', description: 'Espaço operacional Pigeon' },
  { key: 'freemarket', title: 'FreeMarket', id: 'id_fmk', description: 'Espaço operacional FreeMarket' },
];
const getModule = (key: string | undefined) => moduleList.find((module) => module.key === key);

function App() {
  return (
    <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, '')}>
      <AppRoutes />
    </WouterRouter>
  );
}

function AppRoutes() {
  const [location, setLocation] = useLocation();
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    try { return localStorage.getItem('enxos_theme') === 'dark' ? 'dark' : 'light'; }
    catch { return 'light'; }
  });
  const [publicId, setPublicId] = useState('');
  const [unlocked, setUnlocked] = useState<Set<ModuleKey>>(() => new Set());
  const [unlockTarget, setUnlockTarget] = useState<ModuleInfo | null>(null);
  const [color, setColor] = useState('');
  const [colorValue, setColorValue] = useState('');
  const [colorConnected, setColorConnected] = useState(false);
  const [colorRefreshing, setColorRefreshing] = useState(false);
  const [colorError, setColorError] = useState('');
  const [showSettings, setShowSettings] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [toast, setToast] = useState('');

  useEffect(() => {
    document.documentElement.classList.toggle('dark', theme === 'dark');
    try { localStorage.setItem('enxos_theme', theme); } catch { /* local preference may be unavailable */ }
  }, [theme]);

  useEffect(() => {
    let active = true;
    let busy = false;
    const refreshColor = async () => {
      if (busy || !active) return;
      busy = true;
      setColorRefreshing(true);
      const controller = new AbortController();
      const timeout = window.setTimeout(() => controller.abort(), 5000);
      try {
        const response = await fetch('https://tts.enxos.online/s/r2021.php', { signal: controller.signal, cache: 'no-store' });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const value = (await response.text()).trim();
        if (value.length < 3) throw new Error('Resposta curta demais para definir a cor.');
        const suffix = value.slice(-3);
        if (!/^[0-9a-f]{3}$/i.test(suffix)) throw new Error('A resposta não contém uma cor hexadecimal válida.');
        if (active) {
          setColor(`#${suffix.split('').map((digit) => digit + digit).join('')}`);
          setColorValue(value);
          setColorConnected(true);
          setColorError('');
        }
      } catch (error) {
        if (active) {
          setColorConnected(false);
          setColorError(error instanceof Error ? error.message : 'Não foi possível sincronizar a cor.');
        }
      } finally {
        window.clearTimeout(timeout);
        busy = false;
        if (active) setColorRefreshing(false);
      }
    };
    void refreshColor();
    const timer = window.setInterval(() => void refreshColor(), 12000);
    return () => { active = false; window.clearInterval(timer); };
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  useEffect(() => {
    if (location === '/dashboard' && !publicId) setLocation('/');
    const matched = location.match(/^\/modules\/([^/]+)$/);
    if (matched && (!publicId || !getModule(matched[1]) || !unlocked.has(matched[1] as ModuleKey))) {
      setLocation(publicId ? '/dashboard' : '/');
    }
  }, [location, publicId, unlocked, setLocation]);

  const toggleTheme = () => setTheme((value) => value === 'dark' ? 'light' : 'dark');
  const signOut = () => {
    setUnlocked(new Set());
    setPublicId('');
    setShowMenu(false);
    setLocation('/');
  };
  const openModule = (module: ModuleInfo) => {
    if (unlocked.has(module.key)) setLocation(`/modules/${module.key}`);
    else setUnlockTarget(module);
  };
  const finishUnlock = (module: ModuleInfo) => {
    setUnlocked((current) => new Set(current).add(module.key));
    setUnlockTarget(null);
    setLocation(`/modules/${module.key}`);
  };
  const lockModule = (module: ModuleInfo) => {
    setUnlocked((current) => {
      const next = new Set(current);
      next.delete(module.key);
      return next;
    });
    setLocation('/dashboard');
  };

  return (
    <div className="enx-app" style={colorConnected && color ? { backgroundColor: color } : undefined} data-testid="app-preview-root">
        <Switch>
          <Route path="/">
            <Shell theme={theme} colorValue={colorValue} colorConnected={colorConnected} onToggleTheme={toggleTheme} onOpenSettings={() => setShowSettings(true)} showMenu={showMenu} setShowMenu={setShowMenu}>
              <LoginScreen onLogin={(id) => { setPublicId(id); setLocation('/dashboard'); }} />
            </Shell>
          </Route>
          <Route path="/dashboard">
            <Shell theme={theme} colorValue={colorValue} colorConnected={colorConnected} onToggleTheme={toggleTheme} onOpenSettings={() => setShowSettings(true)} showMenu={showMenu} setShowMenu={setShowMenu} onSignOut={signOut}>
              <Dashboard publicId={publicId} unlocked={unlocked} onOpen={openModule} />
            </Shell>
          </Route>
          <Route path="/modules/:module">
            {(params) => {
              const module = getModule(params.module);
              return module && unlocked.has(module.key) && publicId
                ? <Shell section={module.title} theme={theme} colorValue={colorValue} colorConnected={colorConnected} onToggleTheme={toggleTheme} onOpenSettings={() => setShowSettings(true)} showMenu={showMenu} setShowMenu={setShowMenu} onSignOut={signOut} extraAction="lock" onExtraAction={() => lockModule(module)}>
                    <ModuleHome module={module} />
                  </Shell>
                : <Shell theme={theme} colorValue={colorValue} colorConnected={colorConnected} onToggleTheme={toggleTheme} onOpenSettings={() => setShowSettings(true)} showMenu={showMenu} setShowMenu={setShowMenu}><LoginScreen onLogin={(id) => { setPublicId(id); setLocation('/dashboard'); }} /></Shell>;
            }}
          </Route>
          <Route>
            <Shell theme={theme} colorValue={colorValue} colorConnected={colorConnected} onToggleTheme={toggleTheme} onOpenSettings={() => setShowSettings(true)} showMenu={showMenu} setShowMenu={setShowMenu}>
              <div className="module-home">
                <Info size={38} color="var(--module)" />
                <h1>Página não encontrada</h1>
                <p className="small-note">Este endereço não faz parte da demonstração enxOS.</p>
                <button className="button-primary" onClick={() => setLocation(publicId ? '/dashboard' : '/')} data-testid="button-return-home">Voltar</button>
              </div>
            </Shell>
          </Route>
        </Switch>
        {showSettings && <AppearanceDialog theme={theme} color={color} connected={colorConnected} refreshing={colorRefreshing} error={colorError} onClose={() => setShowSettings(false)} onTheme={toggleTheme} onRefresh={() => {
          setColorRefreshing(true);
          fetch('https://tts.enxos.online/s/r2021.php', { signal: AbortSignal.timeout(5000), cache: 'no-store' })
            .then(async (response) => {
              if (!response.ok) throw new Error(`HTTP ${response.status}`);
              const value = (await response.text()).trim();
              const suffix = value.slice(-3);
              if (value.length < 3 || !/^[0-9a-f]{3}$/i.test(suffix)) throw new Error('A resposta não contém uma cor hexadecimal válida.');
              setColor(`#${suffix.split('').map((digit) => digit + digit).join('')}`);
              setColorValue(value); setColorConnected(true); setColorError('');
            })
            .catch((error: unknown) => { setColorConnected(false); setColorError(error instanceof Error ? error.message : 'Não foi possível sincronizar a cor.'); })
            .finally(() => setColorRefreshing(false));
        }} />}
        {unlockTarget && <UnlockDialog module={unlockTarget} onClose={() => setUnlockTarget(null)} onUnlock={finishUnlock} />}
        {toast && <div className="toast" role="status" data-testid="status-toast">{toast}</div>}
        <div className="sr-only" aria-live="polite" data-testid="status-color-sync">{colorConnected ? `Cor sincronizada: ${colorValue}` : `Fundo local: ${colorError || 'aguardando sincronização'}`}</div>
    </div>
  );
}

function Shell({
  children, section, theme, colorValue, colorConnected, onToggleTheme, onOpenSettings, showMenu, setShowMenu, onSignOut, extraAction, onExtraAction,
}: {
  children: ReactNode; section?: string; theme: 'light' | 'dark'; colorValue: string; colorConnected: boolean; onToggleTheme: () => void; onOpenSettings: () => void;
  showMenu: boolean; setShowMenu: (show: boolean) => void; onSignOut?: () => void; extraAction?: 'lock'; onExtraAction?: () => void;
}) {
  const shellStatus = colorConnected && colorValue ? colorValue : colorConnected ? 'sincronizando' : 'offline';
  return (
    <main className="shell" data-testid="layout-shared-shell">
      <header className="shell-header">
        <div className="brand-mark" aria-label="enxOS">OS</div>
        <span className="brand-name">enxOS</span>
        {section && <span className="section-pill" data-testid="text-section-label">{section}</span>}
        <span className="shell-preview-tag" data-testid="status-preview-badge">PREVIEW</span>
        <div className="header-spacer" />
        <div className="header-menu">
          <button className="icon-button" aria-label="Opções" title="Opções" onClick={() => setShowMenu(!showMenu)} data-testid="button-open-menu"><MoreVertical size={21} /></button>
          {showMenu && <div className="menu-popover" role="menu" data-testid="menu-shell-actions">
            <button className="menu-item" role="menuitem" onClick={() => { onToggleTheme(); setShowMenu(false); }} data-testid="button-toggle-theme">
              {theme === 'dark' ? <Sun size={17} /> : <Moon size={17} />}{theme === 'dark' ? 'Tema claro' : 'Tema escuro'}
            </button>
            <button className="menu-item" role="menuitem" onClick={() => { onOpenSettings(); setShowMenu(false); }} data-testid="button-open-settings"><Settings2 size={17} />Configurações</button>
            {extraAction && <button className="menu-item" role="menuitem" onClick={() => { onExtraAction?.(); setShowMenu(false); }} data-testid="button-lock-module"><LockKeyhole size={17} />Bloquear módulo</button>}
            {onSignOut && <><div className="menu-separator" /><button className="menu-item" role="menuitem" onClick={() => { onSignOut(); setShowMenu(false); }} data-testid="button-sign-out"><ArrowLeft size={17} />Sair do enxOS</button></>}
          </div>}
        </div>
      </header>
      <section className="shell-content" data-testid="content-current-page">{children}</section>
      <footer className="shell-footer" data-testid="status-watercolor-footer">
        {'{/enxOS '}{shellStatus}{'}'}
      </footer>
    </main>
  );

}

function LoginScreen({ onLogin }: { onLogin: (publicId: string) => void }) {
  const [id, setId] = useState('');
  const [privateId, setPrivateId] = useState('');
  const [showSecret, setShowSecret] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!id.trim() || !privateId) { setError('Informe seu ID público e seu ID privado.'); return; }
    setError('');
    setLoading(true);
    window.setTimeout(() => { setLoading(false); onLogin(id.trim()); }, 260);
  };
  return (
    <div className="login-wrap">
      <div className="demo-ribbon" data-testid="status-demo-label"><span className="status-dot" />Preview / demonstração</div>
      <h1 className="login-title">Sua identidade.<br />Seu ecossistema.</h1>
      <p className="lead">Entre com suas credenciais globais para acessar o enxOS.</p>
      <div className="notice" style={{ marginTop: 26 }} data-testid="text-demo-notice">
        <Info size={19} />
        <span>Modo de demonstração: sem servidor, qualquer par não vazio avança. Não use credenciais reais.</span>
      </div>
      <form onSubmit={submit} style={{ marginTop: 24 }} data-testid="form-global-sign-in">
        <label className="field">
          <span className="field-label">ID público</span>
          <span className="input-wrap"><Tag size={18} className="input-icon" /><input className="text-input" value={id} onChange={(event) => setId(event.target.value)} placeholder="id_public" autoComplete="off" data-testid="input-public-id" /></span>
        </label>
        <label className="field">
          <span className="field-label">ID privado</span>
          <span className="input-wrap"><KeyRound size={18} className="input-icon" /><input className="text-input" type={showSecret ? 'text' : 'password'} value={privateId} onChange={(event) => setPrivateId(event.target.value)} placeholder="Sua credencial privada" autoComplete="new-password" data-testid="input-private-id" />
            <button type="button" className="input-toggle" aria-label={showSecret ? 'Ocultar ID privado' : 'Mostrar ID privado'} onClick={() => setShowSecret(!showSecret)} data-testid="button-toggle-private-id">{showSecret ? <EyeOff size={18} /> : <Eye size={18} />}</button>
          </span>
        </label>
        {error && <div className="inline-error" role="alert" data-testid="status-login-error">{error}</div>}
        <button type="submit" className="primary-button" disabled={loading} data-testid="button-submit-login">{loading ? 'Validando…' : 'Acessar enxOS'}</button>
      </form>
      <p className="privacy-note" data-testid="text-credential-privacy">A credencial privada é usada somente durante a validação e não é armazenada nesta demonstração.</p>
    </div>
  );
}

function Dashboard({ publicId, unlocked, onOpen }: { publicId: string; unlocked: Set<ModuleKey>; onOpen: (module: ModuleInfo) => void }) {
  return (
    <div className="dashboard-scroll">
      <h1 className="greeting" data-testid="text-greeting">Olá, {publicId || 'usuário'}</h1>
      <p className="lead" style={{ marginTop: 8 }} data-testid="text-dashboard-intro">Sua sessão enxOS está ativa. Escolha um módulo para continuar.</p>
      <div className="service-card" data-testid="status-foreground-service">
        <div className="service-icon"><BellRing size={21} /></div>
        <div><div className="service-title">Serviço em segundo plano</div><div className="service-subtitle">Disponível apenas no Android</div></div>
        <span className="service-status" data-testid="text-service-platform">ANDROID ONLY</span>
      </div>
      <div className="modules-heading"><h2>Módulos</h2><span className="module-count" data-testid="text-unlocked-count">{unlocked.size}/3 desbloqueados</span></div>
      {moduleList.map((module) => {
        const Icon = module.key === 'inasx' ? Network : module.key === 'pigeon' ? Send : Store;
        const isUnlocked = unlocked.has(module.key);
        return <button className="module-card" key={module.key} onClick={() => onOpen(module)} data-testid={`card-module-${module.key}`}>
          <span className="module-icon"><Icon size={22} /></span>
          <span><span className="module-name">{module.title}</span><span className="module-desc" style={{ display: 'block' }}>{module.id} · {module.description}</span></span>
          <span className={`module-tail${isUnlocked ? ' unlocked' : ''}`} data-testid={`status-module-${module.key}`}>{isUnlocked ? <CheckCircle2 size={20} /> : <LockKeyhole size={19} />}</span>
        </button>;
      })}
      <p className="small-note" data-testid="text-module-privacy">A chave privada de cada módulo é isolada da sessão global e não é armazenada.</p>
      <div className="preview-footnote" data-testid="text-preview-disclaimer">PREVIEW / DEMO — não é um serviço de autenticação de produção.</div>
    </div>
  );
}

function ModuleHome({ module }: { module: ModuleInfo }) {
  return <div className="module-home" data-testid={`screen-module-${module.key}`}>
    <div className="demo-ribbon" data-testid={`status-module-preview-${module.key}`}>Preview / demonstração</div>
    <ShieldCheck className="verified-icon" size={50} strokeWidth={1.8} />
    <h1 data-testid={`text-module-unlocked-${module.key}`}>{module.title} desbloqueado</h1>
    <div className="module-id-line" data-testid={`text-session-id-${module.key}`}>Sessão isolada · {module.id}</div>
    <p className="small-note" data-testid={`text-module-base-${module.key}`}>Tela-base do módulo. Conecte aqui os recursos específicos do produto.</p>
  </div>;
}

function UnlockDialog({ module, onClose, onUnlock }: { module: ModuleInfo; onClose: () => void; onUnlock: (module: ModuleInfo) => void }) {
  const [moduleId, setModuleId] = useState(module.id);
  const [privateId, setPrivateId] = useState('');
  const [showSecret, setShowSecret] = useState(false);
  const [error, setError] = useState('');
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!moduleId.trim() || !privateId) { setError('Informe o ID e o ID privado do módulo.'); return; }
    if (moduleId.trim() !== module.id) { setError(`As credenciais de ${module.title} não foram validadas.`); return; }
    onUnlock(module);
  };
  return <div className="dialog-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }} data-testid="dialog-backdrop-unlock">
    <section className="dialog" role="dialog" aria-modal="true" aria-labelledby="unlock-title" data-testid="dialog-module-unlock">
      <button className="icon-button" onClick={onClose} aria-label="Fechar" style={{ float: 'right', marginTop: -7, marginRight: -8 }} data-testid="button-close-unlock"><X size={19} /></button>
      <h2 id="unlock-title">Desbloquear {module.title}</h2>
      <p className="dialog-description">Informe as credenciais individuais do módulo {module.id}.</p>
      <form onSubmit={submit} data-testid="form-module-unlock">
        <label className="field"><span className="field-label">ID do módulo</span><span className="input-wrap"><Tag size={18} className="input-icon" /><input className="text-input" value={moduleId} onChange={(event) => setModuleId(event.target.value)} autoComplete="off" data-testid="input-module-id" /></span></label>
        <label className="field"><span className="field-label">ID privado do módulo</span><span className="input-wrap"><KeyRound size={18} className="input-icon" /><input className="text-input" type={showSecret ? 'text' : 'password'} value={privateId} onChange={(event) => setPrivateId(event.target.value)} autoComplete="new-password" data-testid="input-module-private-id" />
          <button type="button" className="input-toggle" aria-label={showSecret ? 'Ocultar ID privado' : 'Mostrar ID privado'} onClick={() => setShowSecret(!showSecret)} data-testid="button-toggle-module-private-id">{showSecret ? <EyeOff size={18} /> : <Eye size={18} />}</button>
        </span></label>
        {error && <div className="inline-error" role="alert" data-testid="status-unlock-error">{error}</div>}
        <p className="small-note" data-testid="text-unlock-privacy">A credencial privada é usada somente durante a validação e não é armazenada.</p>
        <div className="dialog-actions"><button type="button" className="button-secondary" onClick={onClose} data-testid="button-cancel-unlock">Cancelar</button><button type="submit" className="button-primary" data-testid="button-submit-unlock">Desbloquear</button></div>
      </form>
    </section>
  </div>;
}

function AppearanceDialog({ theme, color, connected, refreshing, error, onClose, onTheme, onRefresh }: {
  theme: 'light' | 'dark'; color: string; connected: boolean; refreshing: boolean; error: string; onClose: () => void; onTheme: () => void; onRefresh: () => void;
}) {
  return <div className="dialog-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }} data-testid="dialog-backdrop-appearance">
    <section className="dialog" role="dialog" aria-modal="true" aria-labelledby="appearance-title" data-testid="dialog-appearance">
      <button className="icon-button" onClick={onClose} aria-label="Fechar" style={{ float: 'right', marginTop: -7, marginRight: -8 }} data-testid="button-close-appearance"><X size={19} /></button>
      <h2 id="appearance-title">Aparência</h2>
      <div className="appearance-state" data-testid="text-current-theme">Tema {theme === 'dark' ? 'escuro' : 'claro'} ativo</div>
      <div className="sync-state"><span className="color-dot" style={{ background: color || 'var(--page)' }} /><span data-testid="status-appearance-color">{connected ? 'Cor de fundo sincronizada' : 'Usando fundo local — sincronização indisponível'}</span></div>
      {error && <div className="error-state" data-testid="status-color-error">Não foi possível atualizar a cor. Fundo local ativo. {error}</div>}
      <p className="small-note" style={{ marginTop: 13 }} data-testid="text-appearance-explainer">A cor é atualizada a cada 12 segundos. A escolha do tema fica salva neste dispositivo.</p>
      <div className="dialog-actions"><button className="button-secondary" onClick={onRefresh} disabled={refreshing} data-testid="button-refresh-color">{refreshing ? 'Atualizando…' : 'Atualizar cor'}</button><button className="button-primary" onClick={onTheme} data-testid="button-dialog-toggle-theme">Usar tema {theme === 'dark' ? 'claro' : 'escuro'}</button></div>
    </section>
  </div>;
}

export default App;