import { useEffect, useState } from "react";

type Screen = "inicio" | "plano" | "evolucao" | "perfil";
type IconName =
  | "activity"
  | "arrow"
  | "bell"
  | "calendar"
  | "check"
  | "chevron"
  | "clock"
  | "eye"
  | "home"
  | "lock"
  | "logout"
  | "mail"
  | "message"
  | "pause"
  | "play"
  | "route"
  | "run"
  | "send"
  | "settings"
  | "shield"
  | "spark"
  | "stop"
  | "target"
  | "trend"
  | "user"
  | "zap";

function Icon({
  name,
  size = 22,
  strokeWidth = 1.8,
  className = "",
}: {
  name: IconName;
  size?: number;
  strokeWidth?: number;
  className?: string;
}) {
  const paths: Record<IconName, React.ReactNode> = {
    activity: <path d="M3 12h4l2.2-7 4.2 14 2.1-7H21" />,
    arrow: <path d="m15 18-6-6 6-6" />,
    bell: (
      <>
        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
        <path d="M10 21h4" />
      </>
    ),
    calendar: (
      <>
        <rect x="3" y="5" width="18" height="16" rx="3" />
        <path d="M16 3v4M8 3v4M3 10h18" />
      </>
    ),
    check: <path d="m5 12 4 4L19 6" />,
    chevron: <path d="m9 18 6-6-6-6" />,
    clock: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M12 7v5l3 2" />
      </>
    ),
    eye: (
      <>
        <path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12" />
        <circle cx="12" cy="12" r="2.5" />
      </>
    ),
    home: (
      <>
        <path d="m3 11 9-8 9 8" />
        <path d="M5 10v11h14V10M9 21v-6h6v6" />
      </>
    ),
    lock: (
      <>
        <rect x="4" y="10" width="16" height="11" rx="3" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3" />
      </>
    ),
    logout: (
      <>
        <path d="M10 17l5-5-5-5M15 12H3" />
        <path d="M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5" />
      </>
    ),
    mail: (
      <>
        <rect x="3" y="5" width="18" height="14" rx="3" />
        <path d="m3 7 9 6 9-6" />
      </>
    ),
    message: (
      <>
        <path d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z" />
        <path d="M8 9h8M8 13h5" />
      </>
    ),
    pause: (
      <>
        <path d="M9 5v14" />
        <path d="M15 5v14" />
      </>
    ),
    play: <path d="m8 5 11 7-11 7z" />,
    route: (
      <>
        <circle cx="6" cy="19" r="2" />
        <circle cx="18" cy="5" r="2" />
        <path d="M8 19h3a3 3 0 0 0 3-3V8a3 3 0 0 1 3-3" />
      </>
    ),
    run: (
      <>
        <circle cx="14.5" cy="4.5" r="2" />
        <path d="m10 22 2-6-3-3 2-5 4 3 4 1M6 12l3-4 2-1M13 16l4 5" />
      </>
    ),
    send: <path d="m22 2-7 20-4-9-9-4zM22 2 11 13" />,
    settings: (
      <>
        <circle cx="12" cy="12" r="3" />
        <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6v.2h-4V21a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H2.8v-4H3a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1a1.7 1.7 0 0 0 1.9.3A1.7 1.7 0 0 0 10 3V2.8h4V3a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.6 1h.2v4H21a1.7 1.7 0 0 0-1.6 1Z" />
      </>
    ),
    shield: (
      <>
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
        <path d="M12 8v4M12 16h.01" />
      </>
    ),
    spark: <path d="m12 3 1.4 4.6L18 9l-4.6 1.4L12 15l-1.4-4.6L6 9l4.6-1.4zM19 16l.7 2.3L22 19l-2.3.7L19 22l-.7-2.3L16 19l2.3-.7zM5 2l.7 2.3L8 5l-2.3.7L5 8l-.7-2.3L2 5l2.3-.7z" />,
    stop: <rect x="7" y="7" width="10" height="10" rx="1" />,
    target: (
      <>
        <circle cx="12" cy="12" r="9" />
        <circle cx="12" cy="12" r="5" />
        <circle cx="12" cy="12" r="1" />
      </>
    ),
    trend: (
      <>
        <path d="m3 17 6-6 4 4 8-9" />
        <path d="M15 6h6v6" />
      </>
    ),
    user: (
      <>
        <circle cx="12" cy="8" r="4" />
        <path d="M4 21a8 8 0 0 1 16 0" />
      </>
    ),
    zap: <path d="M13 2 4 14h7l-1 8 9-12h-7z" />,
  };

  return (
    <svg
      aria-hidden="true"
      className={className}
      fill="none"
      height={size}
      viewBox="0 0 24 24"
      width={size}
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={strokeWidth}
    >
      {paths[name]}
    </svg>
  );
}

const heroImage =
  "https://images.unsplash.com/photo-1744060204728-f68e434a3edf?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=1200";

const week = [
  { day: "S", date: "12", done: true },
  { day: "T", date: "13", done: true },
  { day: "Q", date: "14", active: true },
  { day: "Q", date: "15" },
  { day: "S", date: "16" },
  { day: "S", date: "17" },
  { day: "D", date: "18" },
];

function LoginScreen({ onLogin }: { onLogin: () => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState(false);

  function submit(event: React.FormEvent) {
    event.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError(true);
      return;
    }
    onLogin();
  }

  return (
    <div className="relative flex h-full flex-col overflow-y-auto bg-[#f8faf8] px-6 pb-8 pt-8 screen-enter scrollbar-hide">
      <div className="absolute -right-24 -top-20 h-64 w-64 rounded-full border-[42px] border-[#c6ff32]/25" />
      <div className="relative">
        <div className="grid h-14 w-14 place-items-center rounded-[18px] bg-[#171b19] text-[#c6ff32] shadow-[0_12px_30px_rgba(20,25,22,.18)]">
          <Icon name="run" size={29} strokeWidth={2} />
        </div>
        <p className="mt-8 text-[11px] font-extrabold uppercase tracking-[0.18em] text-[#7b817d]">Seu ritmo, sua evolução</p>
        <h1 className="mt-2 max-w-[320px] text-[38px] font-extrabold leading-[1.04] tracking-[-0.055em]">
          Bem-vindo de volta.
        </h1>
        <p className="mt-3 max-w-xs text-sm font-medium leading-relaxed text-[#6f7571]">
          Entre para acompanhar seus treinos, falar com seu treinador e continuar evoluindo.
        </p>
      </div>

      <form className="relative mt-9 space-y-4" onSubmit={submit}>
        <label className="block">
          <span className="mb-2 block text-xs font-extrabold text-[#4f5551]">E-mail</span>
          <span className={`flex items-center gap-3 rounded-2xl border bg-white px-4 transition focus-within:border-[#8db719] ${
            error && !email ? "border-[#e84032]" : "border-[#dfe4df]"
          }`}>
            <Icon className="text-[#838985]" name="mail" size={19} />
            <input
              autoComplete="email"
              className="h-14 min-w-0 flex-1 bg-transparent text-sm font-semibold outline-none"
              placeholder="seu@email.com"
              type="email"
              value={email}
              onChange={(event) => { setEmail(event.target.value); setError(false); }}
            />
          </span>
        </label>
        <label className="block">
          <span className="mb-2 block text-xs font-extrabold text-[#4f5551]">Senha</span>
          <span className={`flex items-center gap-3 rounded-2xl border bg-white px-4 transition focus-within:border-[#8db719] ${
            error && !password ? "border-[#e84032]" : "border-[#dfe4df]"
          }`}>
            <Icon className="text-[#838985]" name="lock" size={19} />
            <input
              autoComplete="current-password"
              className="h-14 min-w-0 flex-1 bg-transparent text-sm font-semibold outline-none"
              placeholder="Digite sua senha"
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={(event) => { setPassword(event.target.value); setError(false); }}
            />
            <button
              aria-label={showPassword ? "Ocultar senha" : "Exibir senha"}
              className="text-[#747a76]"
              type="button"
              onClick={() => setShowPassword((value) => !value)}
            >
              <Icon name="eye" size={19} />
            </button>
          </span>
        </label>
        <div className="flex items-center justify-between">
          <label className="flex items-center gap-2 text-xs font-bold text-[#676d69]">
            <input className="h-4 w-4 accent-[#171b19]" type="checkbox" />
            Lembrar de mim
          </label>
          <button className="text-xs font-extrabold underline decoration-[#c6ff32] decoration-2 underline-offset-4" type="button">
            Esqueci minha senha
          </button>
        </div>
        {error && <p className="text-xs font-bold text-[#c83328]">Preencha seu e-mail e sua senha para continuar.</p>}
        <button className="mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#171b19] py-4 text-sm font-extrabold text-white shadow-[0_14px_32px_rgba(20,25,22,.16)] transition hover:bg-[#252b27] active:scale-[0.99]" type="submit">
          Entrar
          <Icon name="chevron" size={17} />
        </button>
      </form>

      <div className="my-6 flex items-center gap-3">
        <span className="h-px flex-1 bg-[#dfe4df]" />
        <span className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#929793]">ou continue com</span>
        <span className="h-px flex-1 bg-[#dfe4df]" />
      </div>
      <button
        className="flex w-full items-center justify-center gap-3 rounded-2xl border border-[#dce1dc] bg-white py-3.5 text-sm font-extrabold transition hover:border-[#b7bdb8]"
        onClick={onLogin}
      >
        <span className="grid h-6 w-6 place-items-center rounded-full bg-[#f2f4f2] text-xs font-extrabold">G</span>
        Entrar com Google
      </button>
      <p className="mt-7 text-center text-xs font-medium text-[#747a76]">
        Ainda não tem uma conta? <button className="font-extrabold text-[#171b19]">Criar conta grátis</button>
      </p>
    </div>
  );
}

function TopBar({
  onProfile,
  onNotify,
}: {
  onProfile: () => void;
  onNotify: () => void;
}) {
  return (
    <header className="flex items-center justify-between px-5 pb-4 pt-5">
      <div>
        <p className="text-[12px] font-extrabold uppercase tracking-[0.2em] text-[#587000]">
          Runner
        </p>
        <h1 className="mt-1 text-[25px] font-extrabold tracking-[-0.04em] text-[#141816]">
          Olá, José
        </h1>
      </div>
      <div className="flex items-center gap-2">
        <button
          aria-label="Notificações"
          className="relative grid h-11 w-11 place-items-center rounded-full border border-[#e1e5e2] bg-white transition hover:bg-[#f4f6f4]"
          onClick={onNotify}
        >
          <Icon name="bell" size={20} />
          <span className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full border-2 border-white bg-[#c6ff32]" />
        </button>
        <button
          aria-label="Abrir perfil"
          className="grid h-11 w-11 place-items-center rounded-full bg-[#171b19] text-white transition hover:scale-[1.03]"
          onClick={onProfile}
        >
          <Icon name="user" size={19} />
        </button>
      </div>
    </header>
  );
}

function HomeScreen({
  onNavigate,
  onStart,
  onCoach,
  onEmergency,
  onRoutes,
  onNotify,
}: {
  onNavigate: (screen: Screen) => void;
  onStart: () => void;
  onCoach: () => void;
  onEmergency: () => void;
  onRoutes: () => void;
  onNotify: () => void;
}) {
  return (
    <div className="screen-enter pb-28">
      <TopBar onNotify={onNotify} onProfile={() => onNavigate("perfil")} />

      <main className="space-y-5 px-5">
        <section className="relative min-h-[238px] overflow-hidden rounded-[30px] bg-[#171b19] p-6 text-white shadow-[0_20px_50px_rgba(20,24,22,0.16)]">
          <img
            alt="Corredor treinando em uma pista"
            className="absolute inset-0 h-full w-full object-cover object-[center_42%] opacity-55"
            src={heroImage}
          />
          <div className="absolute inset-0 bg-gradient-to-r from-[#111512] via-[#111512]/80 to-transparent" />
          <div className="relative z-10 flex h-full min-h-[190px] max-w-[72%] flex-col justify-between">
            <div>
              <span className="inline-flex items-center gap-1.5 rounded-full bg-[#c6ff32] px-3 py-1 text-[11px] font-extrabold uppercase tracking-[0.12em] text-[#18200c]">
                <Icon name="zap" size={12} strokeWidth={2.4} />
                Treino de hoje
              </span>
              <h2 className="mt-4 text-[28px] font-extrabold leading-[1.02] tracking-[-0.045em]">
                Ritmo progressivo
              </h2>
              <p className="mt-2 text-sm font-medium text-white/70">6,5 km · 42 min</p>
            </div>
            <button
              className="mt-5 flex w-fit items-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-extrabold text-[#171b19] transition hover:bg-[#c6ff32] active:scale-95"
              onClick={onStart}
            >
              <span className="grid h-6 w-6 place-items-center rounded-full bg-[#c6ff32]">
                <Icon name="play" size={13} strokeWidth={2.5} />
              </span>
              Começar treino
            </button>
          </div>
        </section>

        <section>
          <div className="mb-3 flex items-end justify-between">
            <div>
              <p className="eyebrow">Sua semana</p>
              <h2 className="section-title">Consistência é o ritmo</h2>
            </div>
            <p className="text-sm font-extrabold text-[#5d625f]">2 de 4</p>
          </div>
          <div className="rounded-[24px] border border-[#e5e8e5] bg-white p-4 shadow-[0_8px_30px_rgba(21,28,23,0.05)]">
            <div className="grid grid-cols-7 gap-1.5">
              {week.map((item) => (
                <div className="text-center" key={`${item.day}-${item.date}`}>
                  <span className="text-[10px] font-extrabold text-[#929793]">{item.day}</span>
                  <div
                    className={`mt-2 grid aspect-square place-items-center rounded-full text-[12px] font-extrabold ${
                      item.active
                        ? "bg-[#171b19] text-white ring-4 ring-[#c6ff32]/50"
                        : item.done
                          ? "bg-[#c6ff32] text-[#18200c]"
                          : "bg-[#f3f5f3] text-[#757a77]"
                    }`}
                  >
                    {item.done ? <Icon name="check" size={14} strokeWidth={2.6} /> : item.date}
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 flex items-center justify-between border-t border-[#edf0ed] pt-4">
              <div className="flex items-center gap-3">
                <div className="grid h-10 w-10 place-items-center rounded-xl bg-[#efffc6] text-[#273800]">
                  <Icon name="trend" size={19} strokeWidth={2.2} />
                </div>
                <div>
                  <p className="text-[15px] font-extrabold">18,4 km percorridos</p>
                  <p className="text-xs font-medium text-[#777d79]">Meta semanal: 28 km</p>
                </div>
              </div>
              <span className="text-sm font-extrabold">66%</span>
            </div>
            <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-[#edf0ed]">
              <div className="h-full w-2/3 rounded-full bg-[#c6ff32]" />
            </div>
          </div>
        </section>

        <section>
          <div className="mb-3 flex items-center justify-between">
            <h2 className="section-title">Próximos treinos</h2>
            <button className="text-xs font-extrabold underline-offset-4 hover:underline" onClick={() => onNavigate("plano")}>
              Ver plano
            </button>
          </div>
          <button
            className="group flex w-full items-center gap-4 rounded-[22px] border border-[#e2e6e2] bg-white p-3 text-left transition hover:border-[#c6ff32] hover:shadow-lg"
            onClick={() => onNavigate("plano")}
          >
            <div className="grid h-[66px] w-[66px] shrink-0 place-items-center rounded-[18px] bg-[#202522] text-[#c6ff32]">
              <Icon name="run" size={30} strokeWidth={1.7} />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <span className="text-[10px] font-extrabold uppercase tracking-[0.13em] text-[#777d79]">Sexta · 06:30</span>
                <span className="h-1 w-1 rounded-full bg-[#c6ff32]" />
                <span className="text-[10px] font-extrabold uppercase tracking-[0.13em] text-[#777d79]">Leve</span>
              </div>
              <h3 className="mt-1 text-[17px] font-extrabold tracking-[-0.02em]">Rodagem regenerativa</h3>
              <p className="mt-1 text-xs font-medium text-[#7b807d]">5 km · Zona 2 · 35 min</p>
            </div>
            <Icon className="transition group-hover:translate-x-1" name="chevron" size={18} />
          </button>
        </section>

        <button
          className="group relative w-full overflow-hidden rounded-[26px] bg-[#171b19] p-5 text-left text-white shadow-[0_14px_35px_rgba(20,25,22,.12)]"
          onClick={onRoutes}
        >
          <svg className="absolute right-0 top-0 h-full w-[48%] opacity-35" viewBox="0 0 180 150" fill="none">
            <path d="M-8 124 35 87l31 18 31-64 37 35 55-58M18 6l26 33 44-18 22 30 72 11M48 151l6-34 43-13 22 47" stroke="#fff" strokeWidth="1" opacity=".4" />
            <path d="m30 113 34-22 28 15 38-47 37 23" stroke="#c6ff32" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
            <circle cx="30" cy="113" r="6" fill="#c6ff32" />
            <circle cx="167" cy="82" r="7" fill="#171b19" stroke="#c6ff32" strokeWidth="4" />
          </svg>
          <div className="relative max-w-[62%]">
            <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#c6ff32] text-[#172000]">
              <Icon name="route" size={20} />
            </span>
            <p className="mt-5 text-[10px] font-extrabold uppercase tracking-[0.15em] text-[#c6ff32]">Explore sua cidade</p>
            <h3 className="mt-1 text-[20px] font-extrabold tracking-[-0.035em]">Rotas e descobertas</h3>
            <p className="mt-2 text-xs font-medium leading-relaxed text-white/55">Escolha onde correr ou siga sem rota definida.</p>
          </div>
          <span className="absolute bottom-5 right-5 grid h-9 w-9 place-items-center rounded-full bg-white text-[#171b19] transition group-hover:translate-x-1">
            <Icon name="chevron" size={17} />
          </span>
        </button>

        <section className="overflow-hidden rounded-[26px] bg-[#e9efeb] p-5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="relative grid h-12 w-12 place-items-center rounded-full bg-[#171b19] text-white">
                <span className="text-sm font-extrabold">RM</span>
                <span className="absolute -bottom-0.5 -right-0.5 h-3.5 w-3.5 rounded-full border-[3px] border-[#e9efeb] bg-[#c6ff32]" />
              </div>
              <div>
                <p className="text-xs font-bold text-[#737975]">Seu treinador</p>
                <h3 className="text-[16px] font-extrabold">Rafael Martins</h3>
              </div>
            </div>
            <span className="rounded-full bg-white px-3 py-1 text-[10px] font-extrabold uppercase tracking-[0.12em]">
              Online
            </span>
          </div>
          <blockquote className="mt-4 text-[15px] font-semibold leading-relaxed text-[#454b47]">
            “Ótima evolução no pace. Hoje, segure nos primeiros 2 km e termine forte.”
          </blockquote>
          <button
            className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#171b19] py-3 text-sm font-extrabold text-white transition hover:bg-[#2a302c] active:scale-[0.98]"
            onClick={onCoach}
          >
            <Icon name="message" size={17} />
            Falar com o treinador
          </button>
        </section>

        <button
          className="flex w-full items-center gap-4 rounded-[24px] border border-[#ffd7d3] bg-[#fff7f6] p-4 text-left transition hover:border-[#e84032] active:scale-[0.99]"
          onClick={onEmergency}
        >
          <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-[#e84032] text-white">
            <Icon name="shield" size={23} />
          </span>
          <span className="flex-1">
            <span className="block text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#c52c21]">Segurança</span>
            <span className="mt-1 block text-[16px] font-extrabold">Botão de emergência</span>
            <span className="mt-0.5 block text-xs font-medium text-[#7a6765]">Envie sua localização ao contato de confiança</span>
          </span>
          <Icon name="chevron" size={18} />
        </button>
      </main>
    </div>
  );
}

function PlanScreen({ onStart }: { onStart: () => void }) {
  const [level, setLevel] = useState<"iniciante" | "intermediario">("iniciante");
  const workouts = [
    { day: "HOJE", title: "Ritmo progressivo", detail: "6,5 km · 42 min", icon: "trend" as IconName, active: true },
    { day: "SEX, 16", title: "Rodagem regenerativa", detail: "5 km · Zona 2", icon: "run" as IconName },
    { day: "DOM, 18", title: "Longão confortável", detail: "12 km · 1h15", icon: "route" as IconName },
  ];
  const freeWorkouts = {
    iniciante: [
      { title: "Primeiros passos", detail: "20 min · Caminhada e corrida", icon: "run" as IconName },
      { title: "Corrida básica", detail: "25 min · Ritmo confortável", icon: "activity" as IconName },
      { title: "Desafio 3 km", detail: "30 min · Sem pressão por tempo", icon: "target" as IconName },
    ],
    intermediario: [
      { title: "Tempo run", detail: "35 min · Ritmo sustentado", icon: "zap" as IconName },
      { title: "Intervalado 6 × 400 m", detail: "42 min · Pausa de 90 s", icon: "trend" as IconName },
      { title: "Longão de 10 km", detail: "60 min · Zona aeróbica", icon: "route" as IconName },
    ],
  };
  return (
    <div className="screen-enter pb-28">
      <header className="px-5 pb-4 pt-6">
        <p className="eyebrow">Plano personalizado</p>
        <h1 className="mt-1 text-[29px] font-extrabold tracking-[-0.045em]">Semana 6 de 12</h1>
        <p className="mt-2 max-w-xs text-sm font-medium leading-relaxed text-[#727874]">
          Preparação para sua primeira prova de 10 km.
        </p>
      </header>
      <main className="space-y-5 px-5">
        <section className="relative overflow-hidden rounded-[28px] bg-[#c6ff32] p-5 text-[#172000]">
          <div className="absolute -right-8 -top-12 h-36 w-36 rounded-full border-[28px] border-[#172000]/[0.06]" />
          <div className="relative flex items-end justify-between">
            <div>
              <span className="text-[11px] font-extrabold uppercase tracking-[0.14em]">Objetivo semanal</span>
              <p className="mt-2 text-[35px] font-extrabold leading-none tracking-[-0.06em]">28 km</p>
              <p className="mt-2 text-xs font-bold opacity-65">Faltam 9,6 km para concluir</p>
            </div>
            <div className="relative grid h-20 w-20 place-items-center rounded-full bg-[#172000] text-white">
              <span className="text-lg font-extrabold">66%</span>
            </div>
          </div>
        </section>

        <section>
          <div className="mb-3">
            <p className="eyebrow">Treine no seu ritmo</p>
            <h2 className="mt-1 section-title">Treinos predefinidos grátis</h2>
            <p className="mt-1 text-xs font-medium text-[#737975]">Escolha seu nível e comece quando quiser.</p>
          </div>
          <div className="mb-3 grid grid-cols-2 rounded-2xl bg-[#e9ede9] p-1">
            {(["iniciante", "intermediario"] as const).map((item) => (
              <button
                className={`rounded-xl px-3 py-2.5 text-xs font-extrabold transition ${
                  level === item ? "bg-[#171b19] text-white shadow-sm" : "text-[#6e746f]"
                }`}
                key={item}
                onClick={() => setLevel(item)}
              >
                {item === "iniciante" ? "Iniciante" : "Intermediário"}
              </button>
            ))}
          </div>
          <div className="space-y-2.5">
            {freeWorkouts[level].map((workout, index) => (
              <button
                className="group flex w-full items-center gap-3 rounded-[20px] border border-[#e2e6e2] bg-white p-3 text-left transition hover:border-[#c6ff32]"
                key={workout.title}
                onClick={onStart}
              >
                <span className="grid h-11 w-11 shrink-0 place-items-center rounded-[14px] bg-[#efffc6] text-[#263700]">
                  <Icon name={workout.icon} size={20} />
                </span>
                <span className="flex-1">
                  <span className="flex items-center gap-2">
                    <span className="text-[15px] font-extrabold">{workout.title}</span>
                    {index === 0 && (
                      <span className="rounded-full bg-[#f0f3f0] px-2 py-0.5 text-[8px] font-extrabold uppercase tracking-[0.1em]">
                        Recomendado
                      </span>
                    )}
                  </span>
                  <span className="mt-0.5 block text-[11px] font-medium text-[#777d79]">{workout.detail}</span>
                </span>
                <span className="grid h-8 w-8 place-items-center rounded-full bg-[#171b19] text-[#c6ff32]">
                  <Icon name="play" size={13} strokeWidth={2.4} />
                </span>
              </button>
            ))}
          </div>
        </section>

        <section>
          <div className="mb-3 flex items-center justify-between">
            <h2 className="section-title">Agenda de treinos</h2>
            <button className="grid h-9 w-9 place-items-center rounded-full border border-[#dfe3df] bg-white">
              <Icon name="calendar" size={17} />
            </button>
          </div>
          <div className="space-y-3">
            {workouts.map((workout, index) => (
              <button
                className={`flex w-full items-center gap-4 rounded-[22px] p-4 text-left transition active:scale-[0.99] ${
                  workout.active
                    ? "bg-[#171b19] text-white shadow-[0_14px_35px_rgba(20,25,22,.16)]"
                    : "border border-[#e2e6e2] bg-white hover:border-[#c6ff32]"
                }`}
                key={workout.title}
                onClick={index === 0 ? onStart : undefined}
              >
                <div
                  className={`grid h-12 w-12 shrink-0 place-items-center rounded-2xl ${
                    workout.active ? "bg-[#c6ff32] text-[#172000]" : "bg-[#f0f3f0]"
                  }`}
                >
                  <Icon name={workout.icon} size={23} />
                </div>
                <div className="flex-1">
                  <p className={`text-[10px] font-extrabold tracking-[0.14em] ${workout.active ? "text-[#c6ff32]" : "text-[#8a908c]"}`}>
                    {workout.day}
                  </p>
                  <h3 className="mt-1 text-[16px] font-extrabold">{workout.title}</h3>
                  <p className={`mt-1 text-xs font-medium ${workout.active ? "text-white/55" : "text-[#777d79]"}`}>
                    {workout.detail}
                  </p>
                </div>
                <Icon name={workout.active ? "play" : "chevron"} size={18} />
              </button>
            ))}
          </div>
        </section>

        <section className="rounded-[24px] border border-[#dfe4df] bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-xl bg-[#efffc6]">
              <Icon name="spark" size={19} />
            </div>
            <div>
              <p className="text-xs font-bold text-[#777d79]">Ajustado pelo treinador</p>
              <h3 className="text-[15px] font-extrabold">Carga ideal para sua evolução</h3>
            </div>
          </div>
          <p className="mt-4 text-sm font-medium leading-relaxed text-[#666c68]">
            Seu plano considera seu histórico, disponibilidade e percepção de esforço.
          </p>
        </section>
      </main>
    </div>
  );
}

function EvolutionScreen() {
  const bars = [38, 55, 46, 72, 61, 90, 76];
  return (
    <div className="screen-enter pb-28">
      <header className="px-5 pb-5 pt-6">
        <p className="eyebrow">Seu desempenho</p>
        <h1 className="mt-1 text-[29px] font-extrabold tracking-[-0.045em]">Evolução</h1>
      </header>
      <main className="space-y-5 px-5">
        <section className="grid grid-cols-2 gap-3">
          <div className="rounded-[22px] bg-[#171b19] p-4 text-white">
            <Icon className="text-[#c6ff32]" name="route" size={20} />
            <p className="mt-6 text-[28px] font-extrabold tracking-[-0.05em]">84,2</p>
            <p className="text-xs font-bold text-white/55">km nos últimos 30 dias</p>
          </div>
          <div className="rounded-[22px] bg-[#c6ff32] p-4 text-[#182000]">
            <Icon name="trend" size={20} />
            <p className="mt-6 text-[28px] font-extrabold tracking-[-0.05em]">+12%</p>
            <p className="text-xs font-bold opacity-60">volume em relação a abril</p>
          </div>
        </section>

        <section className="rounded-[26px] border border-[#e2e6e2] bg-white p-5">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-xs font-bold text-[#7b807d]">Volume semanal</p>
              <h2 className="mt-1 text-[22px] font-extrabold tracking-[-0.04em]">Últimas 7 semanas</h2>
            </div>
            <span className="rounded-full bg-[#efffc6] px-3 py-1 text-xs font-extrabold">+4,2 km</span>
          </div>
          <div className="mt-7 flex h-40 items-end justify-between gap-2 border-b border-[#dfe4df]">
            {bars.map((height, index) => (
              <div className="flex h-full flex-1 items-end" key={height}>
                <div
                  className={`w-full rounded-t-lg transition-all ${index === bars.length - 2 ? "bg-[#c6ff32]" : "bg-[#e9ede9]"}`}
                  style={{ height: `${height}%` }}
                />
              </div>
            ))}
          </div>
          <div className="mt-3 flex justify-between text-[10px] font-extrabold text-[#9ba09c]">
            <span>01 ABR</span>
            <span>14 MAI</span>
          </div>
        </section>

        <section>
          <h2 className="mb-3 section-title">Melhores marcas</h2>
          <div className="divide-y divide-[#e7eae7] overflow-hidden rounded-[24px] border border-[#e1e5e1] bg-white">
            {[
              ["5 km", "24:18", "4:51 /km"],
              ["10 km", "52:04", "5:12 /km"],
              ["Maior distância", "15,6 km", "1h 28min"],
            ].map(([title, value, sub]) => (
              <div className="flex items-center justify-between p-4" key={title}>
                <div>
                  <p className="text-xs font-bold text-[#7b807d]">{title}</p>
                  <p className="mt-1 text-[18px] font-extrabold">{value}</p>
                </div>
                <span className="text-xs font-extrabold text-[#4f5551]">{sub}</span>
              </div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}

function ProfileScreen({
  onCoach,
  onCoachMode,
  onSettings,
}: {
  onCoach: () => void;
  onCoachMode: () => void;
  onSettings: () => void;
}) {
  return (
    <div className="screen-enter pb-28">
      <header className="px-5 pb-5 pt-6">
        <div className="flex items-center justify-between">
          <p className="eyebrow">Sua conta</p>
          <button
            aria-label="Abrir configurações"
            className="grid h-10 w-10 place-items-center rounded-full border border-[#dfe4df] bg-white"
            onClick={onSettings}
          >
            <Icon name="settings" size={19} />
          </button>
        </div>
        <div className="mt-5 flex items-center gap-4">
          <div className="grid h-20 w-20 place-items-center rounded-[26px] bg-[#171b19] text-2xl font-extrabold text-[#c6ff32]">
            JA
          </div>
          <div>
            <h1 className="text-[26px] font-extrabold tracking-[-0.045em]">José Anderson</h1>
            <p className="mt-1 text-sm font-medium text-[#767c78]">Corredor intermediário</p>
            <span className="mt-2 inline-flex rounded-full bg-[#efffc6] px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-[0.1em]">
              Plano ativo
            </span>
          </div>
        </div>
      </header>
      <main className="space-y-5 px-5">
        <section className="grid grid-cols-3 gap-2 rounded-[24px] bg-[#171b19] p-4 text-white">
          {[["18", "Semanas"], ["42", "Treinos"], ["284", "km total"]].map(([value, label]) => (
            <div className="text-center" key={label}>
              <p className="text-xl font-extrabold">{value}</p>
              <p className="mt-1 text-[10px] font-bold text-white/50">{label}</p>
            </div>
          ))}
        </section>
        <button
          className="flex w-full items-center gap-4 rounded-[24px] bg-[#c6ff32] p-4 text-left text-[#172000] transition active:scale-[0.99]"
          onClick={onCoachMode}
        >
          <span className="grid h-12 w-12 place-items-center rounded-2xl bg-[#172000] text-[#c6ff32]">
            <Icon name="activity" size={23} />
          </span>
          <span className="flex-1">
            <span className="block text-[10px] font-extrabold uppercase tracking-[0.14em] opacity-60">Área profissional</span>
            <span className="mt-1 block text-[16px] font-extrabold">Acessar painel do treinador</span>
          </span>
          <Icon name="chevron" size={19} />
        </button>
        <section className="rounded-[24px] bg-[#e9efeb] p-5">
          <p className="eyebrow">Acompanhamento</p>
          <h2 className="mt-1 text-xl font-extrabold">Rafael está com você</h2>
          <p className="mt-2 text-sm font-medium leading-relaxed text-[#656b67]">
            Seu treinador revisou o plano ontem e deixou uma orientação para o treino de hoje.
          </p>
          <button className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#171b19] py-3 text-sm font-extrabold text-white" onClick={onCoach}>
            <Icon name="message" size={17} />
            Abrir conversa
          </button>
        </section>
        <section className="overflow-hidden rounded-[24px] border border-[#e1e5e1] bg-white">
          {[
            ["target", "Objetivos e preferências"],
            ["activity", "Saúde e condicionamento"],
            ["bell", "Notificações"],
            ["user", "Dados pessoais"],
          ].map(([icon, label]) => (
            <button className="flex w-full items-center gap-3 border-b border-[#edf0ed] p-4 text-left last:border-0" key={label}>
              <span className="grid h-9 w-9 place-items-center rounded-xl bg-[#f0f3f0]">
                <Icon name={icon as IconName} size={18} />
              </span>
              <span className="flex-1 text-sm font-extrabold">{label}</span>
              <Icon name="chevron" size={17} />
            </button>
          ))}
        </section>
      </main>
    </div>
  );
}

function BottomNav({ active, onChange }: { active: Screen; onChange: (screen: Screen) => void }) {
  const items: { id: Screen; label: string; icon: IconName }[] = [
    { id: "inicio", label: "Início", icon: "home" },
    { id: "plano", label: "Plano", icon: "calendar" },
    { id: "evolucao", label: "Evolução", icon: "trend" },
    { id: "perfil", label: "Perfil", icon: "user" },
  ];
  return (
    <nav className="absolute bottom-0 left-0 right-0 z-30 border-t border-[#e3e6e3] bg-white/95 px-3 pb-[max(12px,env(safe-area-inset-bottom))] pt-2 backdrop-blur-xl">
      <div className="grid grid-cols-4">
        {items.map((item) => {
          const isActive = active === item.id;
          return (
            <button
              className={`relative flex flex-col items-center gap-1.5 rounded-2xl py-2 text-[10px] font-extrabold transition ${
                isActive ? "text-[#151917]" : "text-[#929793] hover:text-[#454b47]"
              }`}
              key={item.id}
              onClick={() => onChange(item.id)}
            >
              {isActive && <span className="absolute top-0 h-1 w-5 rounded-full bg-[#c6ff32]" />}
              <Icon name={item.icon} size={21} strokeWidth={isActive ? 2.3 : 1.8} />
              {item.label}
            </button>
          );
        })}
      </div>
    </nav>
  );
}

function RoutesScreen({
  onClose,
  onStart,
}: {
  onClose: () => void;
  onStart: () => void;
}) {
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<"todas" | "leve" | "moderada">("todas");
  const [selected, setSelected] = useState<string | null>(null);
  const routes = [
    { name: "Centro Histórico", city: "Vitória de Santo Antão · PE", distance: "6,1 km", level: "Leve", elevation: "32 m", time: "38 min" },
    { name: "Avenida Mariana Amália", city: "Vitória de Santo Antão · PE", distance: "5,3 km", level: "Moderada", elevation: "84 m", time: "34 min" },
    { name: "Bairro do Livramento", city: "Vitória de Santo Antão · PE", distance: "8,4 km", level: "Leve", elevation: "18 m", time: "52 min" },
    { name: "Alto José Leal", city: "Vitória de Santo Antão · PE", distance: "4,7 km", level: "Leve", elevation: "24 m", time: "29 min" },
  ];
  const filteredRoutes = routes.filter((route) => {
    const matchesQuery = route.name.toLowerCase().includes(query.toLowerCase());
    const matchesFilter = filter === "todas" || route.level.toLowerCase() === filter;
    return matchesQuery && matchesFilter;
  });
  const chosenRoute = routes.find((route) => route.name === selected);

  return (
    <div className="absolute inset-0 z-50 bg-[#f7f9f7] screen-enter">
      <div className="h-full overflow-y-auto pb-8 scrollbar-hide">
        <header className="sticky top-0 z-20 border-b border-[#e5e9e5] bg-[#f7f9f7]/95 px-5 pb-4 pt-4 backdrop-blur-xl">
          <div className="flex items-center">
            <button
              aria-label="Voltar"
              className="grid h-11 w-11 place-items-center rounded-full border border-[#dce1dc] bg-white"
              onClick={onClose}
            >
              <Icon name="arrow" size={20} />
            </button>
            <div className="flex-1 pr-11 text-center">
              <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#858b87]">Explore e escolha</p>
              <h1 className="text-[17px] font-extrabold">Rotas e descobertas</h1>
            </div>
          </div>
          <label className="mt-4 flex h-12 items-center gap-3 rounded-2xl border border-[#dfe4df] bg-white px-4 focus-within:border-[#9bc91c]">
            <Icon className="text-[#7e847f]" name="target" size={18} />
            <input
              className="min-w-0 flex-1 bg-transparent text-sm font-semibold outline-none"
              placeholder="Buscar rota ou lugar"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
            />
          </label>
        </header>

        <main className="space-y-5 px-5 py-5">
          <section className="relative h-52 overflow-hidden rounded-[28px] bg-[#dfe5df]">
            <div className="absolute inset-0 opacity-55" style={{ backgroundImage: "linear-gradient(30deg, transparent 48%, #fff 49%, #fff 52%, transparent 53%), linear-gradient(120deg, transparent 44%, #fff 45%, #fff 48%, transparent 49%)", backgroundSize: "62px 70px" }} />
            <svg className="absolute inset-0 h-full w-full" viewBox="0 0 400 210" fill="none">
              <path d="M-20 176 63 126l52 25 73-100 66 49 62-27 105 59" stroke="#171b19" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M-20 176 63 126l52 25 73-100 66 49 62-27 105 59" stroke="#c6ff32" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
              <circle cx="64" cy="126" r="11" fill="#fff" stroke="#171b19" strokeWidth="5" />
              <circle cx="316" cy="73" r="15" fill="#c6ff32" stroke="#171b19" strokeWidth="5" />
            </svg>
            <div className="absolute bottom-3 left-3 rounded-xl bg-[#171b19] px-3 py-2 text-white shadow-lg">
              <p className="text-[9px] font-bold text-white/50">ROTA EM DESTAQUE</p>
              <p className="mt-0.5 text-xs font-extrabold">Circuito Centro e Livramento · 7,2 km</p>
            </div>
          </section>

          <section>
            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
              {(["todas", "leve", "moderada"] as const).map((item) => (
                <button
                  className={`shrink-0 rounded-full px-4 py-2 text-xs font-extrabold transition ${
                    filter === item ? "bg-[#171b19] text-white" : "border border-[#dfe4df] bg-white text-[#737975]"
                  }`}
                  key={item}
                  onClick={() => setFilter(item)}
                >
                  {item === "todas" ? "Todas as rotas" : item === "leve" ? "Leves" : "Moderadas"}
                </button>
              ))}
            </div>
          </section>

          <section>
            <div className="mb-3 flex items-center justify-between">
              <div>
                <p className="eyebrow">Perto de você</p>
                <h2 className="mt-1 section-title">{filteredRoutes.length} rotas encontradas</h2>
              </div>
              <span className="text-[10px] font-bold text-[#858b87]">Até 8 km</span>
            </div>
            <div className="space-y-2.5">
              {filteredRoutes.map((route, index) => {
                const isSelected = selected === route.name;
                return (
                  <button
                    className={`flex w-full items-center gap-3 rounded-[21px] border p-3 text-left transition ${
                      isSelected ? "border-[#171b19] bg-[#171b19] text-white" : "border-[#e1e5e1] bg-white hover:border-[#c6ff32]"
                    }`}
                    key={route.name}
                    onClick={() => setSelected(isSelected ? null : route.name)}
                  >
                    <span className={`relative grid h-15 w-15 shrink-0 place-items-center overflow-hidden rounded-2xl ${isSelected ? "bg-[#c6ff32] text-[#172000]" : "bg-[#e9ede9]"}`}>
                      <svg className="absolute inset-0 h-full w-full opacity-30" viewBox="0 0 60 60">
                        <path d={index % 2 ? "M-5 50 18 26l14 7L65 5" : "M-4 14 20 24l12-9 33 31"} fill="none" stroke="currentColor" strokeWidth="2" />
                      </svg>
                      <Icon className="relative" name="route" size={22} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-[15px] font-extrabold">{route.name}</span>
                      <span className={`mt-0.5 block text-[10px] font-medium ${isSelected ? "text-white/55" : "text-[#858b87]"}`}>{route.city}</span>
                      <span className="mt-2 flex items-center gap-2 text-[10px] font-extrabold">
                        <span>{route.distance}</span>
                        <span className={isSelected ? "text-white/25" : "text-[#d1d5d1]"}>•</span>
                        <span>{route.level}</span>
                        <span className={isSelected ? "text-white/25" : "text-[#d1d5d1]"}>•</span>
                        <span>{route.elevation}</span>
                      </span>
                    </span>
                    <span className={`grid h-7 w-7 place-items-center rounded-full ${isSelected ? "bg-[#c6ff32] text-[#172000]" : "border border-[#dfe4df]"}`}>
                      {isSelected ? <Icon name="check" size={14} strokeWidth={2.5} /> : <Icon name="chevron" size={14} />}
                    </span>
                  </button>
                );
              })}
            </div>
          </section>

          {chosenRoute && (
            <section className="sticky bottom-4 rounded-[24px] bg-[#c6ff32] p-4 text-[#172000] shadow-[0_16px_40px_rgba(20,25,22,.2)] screen-up">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-[10px] font-extrabold uppercase tracking-[0.13em] opacity-60">Rota selecionada</p>
                  <p className="mt-1 text-[16px] font-extrabold">{chosenRoute.name}</p>
                  <p className="mt-0.5 text-[11px] font-bold opacity-60">{chosenRoute.distance} · cerca de {chosenRoute.time}</p>
                </div>
                <button className="flex items-center gap-2 rounded-2xl bg-[#171b19] px-4 py-3 text-xs font-extrabold text-white" onClick={onStart}>
                  <Icon name="play" size={14} />
                  Usar rota
                </button>
              </div>
            </section>
          )}

          <button
            className="w-full rounded-2xl border border-[#dce1dc] bg-white py-3.5 text-xs font-extrabold text-[#656b67]"
            onClick={onStart}
          >
            Correr sem escolher uma rota
          </button>
        </main>
      </div>
    </div>
  );
}

function LiveLocationScreen({ onClose }: { onClose: () => void }) {
  const [sharing, setSharing] = useState(false);
  const [copied, setCopied] = useState(false);
  const [contacts, setContacts] = useState({ marina: true, rafael: true });

  function copyLink() {
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1800);
  }

  return (
    <div className="absolute inset-0 z-[60] bg-[#f7f9f7] screen-enter">
      <div className="h-full overflow-y-auto pb-6 scrollbar-hide">
        <header className="sticky top-0 z-20 flex items-center border-b border-[#e4e8e4] bg-[#f7f9f7]/95 px-5 py-4 backdrop-blur-xl">
          <button
            aria-label="Voltar ao treino"
            className="grid h-11 w-11 place-items-center rounded-full border border-[#dce1dc] bg-white"
            onClick={onClose}
          >
            <Icon name="arrow" size={20} />
          </button>
          <div className="flex-1 pr-11 text-center">
            <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#858b87]">Segurança durante o treino</p>
            <h1 className="text-[17px] font-extrabold">Localização em tempo real</h1>
          </div>
        </header>

        <main className="space-y-5 px-5 py-5">
          <section className="relative h-[280px] overflow-hidden rounded-[28px] bg-[#dfe5df]">
            <div
              className="absolute inset-0 opacity-70"
              style={{
                backgroundImage:
                  "linear-gradient(25deg, transparent 46%, #fff 47%, #fff 51%, transparent 52%), linear-gradient(115deg, transparent 43%, #fff 44%, #fff 48%, transparent 49%)",
                backgroundSize: "68px 76px",
              }}
            />
            <svg className="absolute inset-0 h-full w-full" viewBox="0 0 400 280" fill="none">
              <path d="M-20 235 65 191l47 17 76-115 69 45 55-59 111 38" stroke="#171b19" strokeWidth="7" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M-20 235 65 191l47 17 76-115 69 45" stroke="#c6ff32" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
              <circle cx="257" cy="138" r="23" fill="#c6ff32" opacity=".25" />
              <circle cx="257" cy="138" r="12" fill="#171b19" stroke="#c6ff32" strokeWidth="5" />
            </svg>
            <div className="absolute left-3 top-3 flex items-center gap-2 rounded-xl bg-white/95 px-3 py-2 shadow-lg">
              <span className={`h-2.5 w-2.5 rounded-full ${sharing ? "animate-pulse bg-[#3ba55c]" : "bg-[#9da29e]"}`} />
              <span className="text-[10px] font-extrabold">{sharing ? "Compartilhando ao vivo" : "Compartilhamento pausado"}</span>
            </div>
            <button className="absolute right-3 top-3 grid h-10 w-10 place-items-center rounded-xl bg-white shadow-lg">
              <Icon name="target" size={19} />
            </button>
            <div className="absolute bottom-3 left-3 right-3 rounded-2xl bg-[#171b19] p-3 text-white shadow-xl">
              <p className="text-[9px] font-bold uppercase tracking-[0.12em] text-white/45">Localização atual</p>
              <p className="mt-1 text-xs font-extrabold">Av. Mariana Amália · Vitória de Santo Antão</p>
              <p className="mt-0.5 text-[10px] font-medium text-white/45">Atualizada agora · precisão de 8 m</p>
            </div>
          </section>

          {!sharing ? (
            <section className="rounded-[24px] border border-[#e1e5e1] bg-white p-5">
              <div className="flex items-start gap-3">
                <span className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-[#efffc6] text-[#273800]">
                  <Icon name="shield" size={21} />
                </span>
                <div>
                  <h2 className="text-[17px] font-extrabold">Corra com mais segurança</h2>
                  <p className="mt-1 text-xs font-medium leading-relaxed text-[#747a76]">
                    Seus contatos poderão acompanhar seu trajeto até você encerrar o treino.
                  </p>
                </div>
              </div>
              <button
                className="mt-5 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#171b19] py-4 text-sm font-extrabold text-white"
                onClick={() => setSharing(true)}
              >
                <Icon name="send" size={17} />
                Compartilhar localização
              </button>
            </section>
          ) : (
            <section className="rounded-[24px] bg-[#c6ff32] p-5 text-[#172000] screen-up">
              <div className="flex items-center gap-3">
                <span className="grid h-11 w-11 place-items-center rounded-full bg-[#172000] text-[#c6ff32]">
                  <Icon name="check" size={22} strokeWidth={2.5} />
                </span>
                <div>
                  <h2 className="text-[17px] font-extrabold">Localização compartilhada</h2>
                  <p className="mt-0.5 text-xs font-bold opacity-60">2 pessoas estão acompanhando você</p>
                </div>
              </div>
              <div className="mt-4 grid grid-cols-3 divide-x divide-[#172000]/15 rounded-2xl bg-white/45 p-3 text-center">
                <div><strong className="block text-sm">Agora</strong><span className="text-[9px] font-bold opacity-55">atualização</span></div>
                <div><strong className="block text-sm">8 m</strong><span className="text-[9px] font-bold opacity-55">precisão</span></div>
                <div><strong className="block text-sm">2</strong><span className="text-[9px] font-bold opacity-55">visualizando</span></div>
              </div>
            </section>
          )}

          <section>
            <div className="mb-3">
              <p className="eyebrow">Compartilhar com</p>
              <h2 className="mt-1 section-title">Contatos de confiança</h2>
            </div>
            <div className="divide-y divide-[#edf0ed] overflow-hidden rounded-[22px] border border-[#e1e5e1] bg-white">
              {[
                { key: "marina" as const, initials: "MS", name: "Marina Silva", relation: "Contato de emergência" },
                { key: "rafael" as const, initials: "RM", name: "Rafael Martins", relation: "Seu treinador" },
              ].map((contact) => (
                <button
                  className="flex w-full items-center gap-3 p-4 text-left"
                  key={contact.key}
                  onClick={() => setContacts((current) => ({ ...current, [contact.key]: !current[contact.key] }))}
                >
                  <span className="grid h-11 w-11 place-items-center rounded-full bg-[#171b19] text-xs font-extrabold text-white">{contact.initials}</span>
                  <span className="flex-1">
                    <span className="block text-sm font-extrabold">{contact.name}</span>
                    <span className="block text-[10px] font-medium text-[#858b87]">{contact.relation}</span>
                  </span>
                  <span className={`grid h-6 w-6 place-items-center rounded-full border-2 ${
                    contacts[contact.key] ? "border-[#171b19] bg-[#c6ff32] text-[#172000]" : "border-[#cdd2cd]"
                  }`}>
                    {contacts[contact.key] && <Icon name="check" size={13} strokeWidth={2.7} />}
                  </span>
                </button>
              ))}
            </div>
          </section>

          <section className="rounded-[22px] border border-[#e1e5e1] bg-white p-4">
            <p className="text-[10px] font-extrabold uppercase tracking-[0.13em] text-[#858b87]">Link de acompanhamento</p>
            <div className="mt-2 flex items-center gap-2">
              <span className="min-w-0 flex-1 truncate rounded-xl bg-[#f0f3f0] px-3 py-3 text-xs font-bold text-[#5e645f]">
                runner.app/live/jose-anderson
              </span>
              <button
                className={`rounded-xl px-4 py-3 text-xs font-extrabold transition ${copied ? "bg-[#c6ff32] text-[#172000]" : "bg-[#171b19] text-white"}`}
                onClick={copyLink}
              >
                {copied ? "Copiado" : "Copiar"}
              </button>
            </div>
          </section>

          {sharing && (
            <button
              className="w-full rounded-2xl border border-[#f0d1ce] bg-[#fff5f4] py-4 text-sm font-extrabold text-[#c83328]"
              onClick={() => setSharing(false)}
            >
              Parar de compartilhar
            </button>
          )}
          <p className="px-3 text-center text-[10px] font-medium leading-relaxed text-[#969b97]">
            Sua localização é protegida e deixa de ser compartilhada automaticamente ao encerrar o treino.
          </p>
        </main>
      </div>
    </div>
  );
}

function WorkoutScreen({ onClose }: { onClose: () => void }) {
  const [running, setRunning] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [finished, setFinished] = useState(false);
  const [liveLocationOpen, setLiveLocationOpen] = useState(false);

  useEffect(() => {
    if (!running) return;
    const timer = window.setInterval(() => setSeconds((value) => value + 1), 1000);
    return () => window.clearInterval(timer);
  }, [running]);

  const formatted = new Date(seconds * 1000).toISOString().slice(11, 19);
  if (finished) {
    return (
      <div className="absolute inset-0 z-50 flex flex-col justify-between bg-[#151a17] p-6 text-white screen-enter">
        <div className="flex justify-end">
          <button className="grid h-11 w-11 place-items-center rounded-full border border-white/15" onClick={onClose}>
            <span className="rotate-45 text-2xl font-light">+</span>
          </button>
        </div>
        <div className="text-center">
          <div className="mx-auto grid h-24 w-24 place-items-center rounded-full bg-[#c6ff32] text-[#172000] shadow-[0_0_70px_rgba(198,255,50,.18)]">
            <Icon name="check" size={43} strokeWidth={2.4} />
          </div>
          <p className="mt-8 text-xs font-extrabold uppercase tracking-[0.17em] text-[#c6ff32]">Treino concluído</p>
          <h2 className="mt-3 text-[36px] font-extrabold leading-tight tracking-[-0.05em]">Você foi mais longe hoje.</h2>
          <p className="mx-auto mt-3 max-w-xs text-sm font-medium leading-relaxed text-white/55">
            Treino registrado. Rafael já pode acompanhar sua evolução.
          </p>
          <div className="mt-8 grid grid-cols-3 divide-x divide-white/10 rounded-2xl border border-white/10 p-4">
            <div><strong className="block text-lg">6,5</strong><span className="text-[10px] text-white/45">km</span></div>
            <div><strong className="block text-lg">{seconds ? formatted.slice(3) : "42:10"}</strong><span className="text-[10px] text-white/45">tempo</span></div>
            <div><strong className="block text-lg">6:29</strong><span className="text-[10px] text-white/45">pace</span></div>
          </div>
        </div>
        <button className="rounded-2xl bg-[#c6ff32] py-4 text-sm font-extrabold text-[#172000]" onClick={onClose}>
          Voltar para o início
        </button>
      </div>
    );
  }

  return (
    <div className="absolute inset-0 z-50 flex flex-col bg-[#f7f9f7] screen-enter">
      <header className="flex items-center justify-between px-5 py-5">
        <button className="grid h-11 w-11 place-items-center rounded-full border border-[#dde2dd] bg-white" onClick={onClose}>
          <Icon name="arrow" size={20} />
        </button>
        <div className="text-center">
          <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#838985]">Treino de hoje</p>
          <h2 className="text-[15px] font-extrabold">Ritmo progressivo</h2>
        </div>
        <button
          aria-label="Compartilhar localização"
          className="grid h-11 w-11 place-items-center rounded-full border border-[#dde2dd] bg-white"
          onClick={() => setLiveLocationOpen(true)}
        >
          <Icon name="route" size={19} />
        </button>
      </header>
      <main className="flex flex-1 flex-col justify-between px-5 pb-7 pt-5">
        <div>
          <div className="relative mx-auto grid h-64 w-64 place-items-center rounded-full border border-[#dde2dd]">
            <div className={`absolute inset-3 rounded-full border-[7px] border-[#c6ff32] border-r-transparent ${running ? "animate-[spin_3s_linear_infinite]" : ""}`} />
            <div className="text-center">
              <p className="text-[11px] font-extrabold uppercase tracking-[0.15em] text-[#8a908c]">Tempo</p>
              <p className="mt-2 text-[46px] font-extrabold tracking-[-0.065em]">{formatted}</p>
              <p className={`mt-2 text-xs font-extrabold ${running ? "text-[#4a6500]" : "text-[#8c928e]"}`}>
                {running ? "Treino em andamento" : seconds ? "Treino pausado" : "Pronto para começar"}
              </p>
            </div>
          </div>
          <div className="mt-8 grid grid-cols-3 divide-x divide-[#e0e4e0] rounded-[22px] bg-white p-4 shadow-[0_10px_30px_rgba(20,28,23,.06)]">
            <div className="text-center">
              <p className="text-[10px] font-bold text-[#8b918d]">DISTÂNCIA</p>
              <p className="mt-1 text-lg font-extrabold">{(seconds * 0.0026).toFixed(2)}</p>
              <p className="text-[10px] text-[#8b918d]">km</p>
            </div>
            <div className="text-center">
              <p className="text-[10px] font-bold text-[#8b918d]">PACE</p>
              <p className="mt-1 text-lg font-extrabold">6:29</p>
              <p className="text-[10px] text-[#8b918d]">/km</p>
            </div>
            <div className="text-center">
              <p className="text-[10px] font-bold text-[#8b918d]">BATIMENTOS</p>
              <p className="mt-1 text-lg font-extrabold">{running ? "148" : "--"}</p>
              <p className="text-[10px] text-[#8b918d]">bpm</p>
            </div>
          </div>
          <button
            className="mt-3 flex w-full items-center gap-3 rounded-[18px] border border-[#dfe4df] bg-white p-3 text-left transition hover:border-[#c6ff32]"
            onClick={() => setLiveLocationOpen(true)}
          >
            <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#efffc6] text-[#273800]">
              <Icon name="route" size={19} />
            </span>
            <span className="flex-1">
              <span className="block text-xs font-extrabold">Localização em tempo real</span>
              <span className="block text-[10px] font-medium text-[#858b87]">Compartilhe seu trajeto com quem confia</span>
            </span>
            <Icon name="chevron" size={16} />
          </button>
        </div>
        <div className="flex items-center justify-center gap-7">
          <button
            className="grid h-14 w-14 place-items-center rounded-full border border-[#d8ddd8] bg-white text-[#242a26] disabled:opacity-30"
            disabled={!seconds}
            onClick={() => { setRunning(false); setFinished(true); }}
          >
            <Icon name="stop" size={20} />
          </button>
          <button
            className="grid h-24 w-24 place-items-center rounded-full bg-[#171b19] text-[#c6ff32] shadow-[0_14px_35px_rgba(20,25,22,.24)] transition active:scale-95"
            onClick={() => setRunning((value) => !value)}
          >
            <Icon name={running ? "pause" : "play"} size={34} strokeWidth={2} />
          </button>
          <button className="grid h-14 w-14 place-items-center rounded-full border border-[#d8ddd8] bg-white">
            <Icon name="zap" size={20} />
          </button>
        </div>
      </main>
      {liveLocationOpen && <LiveLocationScreen onClose={() => setLiveLocationOpen(false)} />}
    </div>
  );
}

function EmergencyPanel({ onClose }: { onClose: () => void }) {
  const [alertSent, setAlertSent] = useState(false);

  return (
    <div className="absolute inset-0 z-50 flex flex-col bg-[#fff9f8] p-5 screen-enter">
      <header className="flex items-center justify-between">
        <button
          aria-label="Fechar emergência"
          className="grid h-11 w-11 place-items-center rounded-full border border-[#eddeda] bg-white"
          onClick={onClose}
        >
          <Icon name="arrow" size={20} />
        </button>
        <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-[#bc3127]">Segurança do corredor</span>
        <div className="h-11 w-11" />
      </header>

      <main className="flex flex-1 flex-col justify-center">
        {alertSent ? (
          <div className="text-center screen-enter">
            <div className="mx-auto grid h-28 w-28 place-items-center rounded-full bg-[#e84032] text-white shadow-[0_18px_60px_rgba(232,64,50,.24)]">
              <Icon name="check" size={48} strokeWidth={2.3} />
            </div>
            <h2 className="mt-8 text-[30px] font-extrabold tracking-[-0.045em]">Alerta enviado</h2>
            <p className="mx-auto mt-3 max-w-xs text-sm font-medium leading-relaxed text-[#756663]">
              Sua localização em tempo real foi compartilhada com Marina e o treinador Rafael.
            </p>
            <div className="mt-8 rounded-2xl border border-[#f0d7d3] bg-white p-4 text-left">
              <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#a95a53]">Localização compartilhada</p>
              <p className="mt-1 text-sm font-extrabold">Av. Mariana Amália, Centro · Vitória de Santo Antão</p>
            </div>
            <button className="mt-6 w-full rounded-2xl bg-[#171b19] py-4 text-sm font-extrabold text-white" onClick={onClose}>
              Encerrar alerta
            </button>
          </div>
        ) : (
          <div className="text-center">
            <div className="mx-auto grid h-36 w-36 place-items-center rounded-full border border-[#f0c9c5] bg-white">
              <div className="grid h-28 w-28 place-items-center rounded-full bg-[#fff0ee] text-[#e84032]">
                <Icon name="shield" size={56} strokeWidth={1.6} />
              </div>
            </div>
            <h2 className="mt-7 text-[30px] font-extrabold tracking-[-0.045em]">Precisa de ajuda?</h2>
            <p className="mx-auto mt-2 max-w-xs text-sm font-medium leading-relaxed text-[#756663]">
              Ao ativar, enviaremos sua localização para seus contatos de emergência.
            </p>
            <button
              className="mt-8 w-full rounded-[22px] bg-[#e84032] py-5 text-base font-extrabold text-white shadow-[0_14px_35px_rgba(232,64,50,.22)] transition active:scale-[0.98]"
              onClick={() => setAlertSent(true)}
            >
              Ativar alerta de emergência
            </button>
            <div className="mt-4 flex items-center gap-3 rounded-2xl border border-[#eddfdc] bg-white p-4 text-left">
              <div className="grid h-10 w-10 place-items-center rounded-full bg-[#f1f3f1]">
                <Icon name="user" size={18} />
              </div>
              <div className="flex-1">
                <p className="text-[10px] font-bold text-[#8c817e]">CONTATO DE EMERGÊNCIA</p>
                <p className="mt-0.5 text-sm font-extrabold">Marina Silva · irmã</p>
              </div>
              <Icon name="chevron" size={17} />
            </div>
            <button className="mt-5 text-xs font-extrabold text-[#736966] underline underline-offset-4">
              Ligar para o serviço de emergência
            </button>
          </div>
        )}
      </main>
    </div>
  );
}

function CoachPanel({ onClose }: { onClose: () => void }) {
  const [sent, setSent] = useState(false);
  return (
    <div className="absolute inset-0 z-40 flex items-end bg-[#101310]/45 backdrop-blur-[2px]" onClick={onClose}>
      <div className="w-full rounded-t-[32px] bg-[#f8faf8] p-5 pb-8 shadow-2xl screen-up" onClick={(event) => event.stopPropagation()}>
        <div className="mx-auto mb-5 h-1 w-12 rounded-full bg-[#d6dbd7]" />
        <div className="flex items-center gap-3">
          <div className="relative grid h-12 w-12 place-items-center rounded-full bg-[#171b19] font-extrabold text-white">
            RM
            <span className="absolute -bottom-0.5 -right-0.5 h-3.5 w-3.5 rounded-full border-[3px] border-[#f8faf8] bg-[#c6ff32]" />
          </div>
          <div className="flex-1">
            <h3 className="text-[17px] font-extrabold">Rafael Martins</h3>
            <p className="text-xs font-bold text-[#6e746f]">Treinador · responde em minutos</p>
          </div>
          <button className="grid h-10 w-10 place-items-center rounded-full bg-white text-xl" onClick={onClose}>×</button>
        </div>
        <div className="my-5 rounded-2xl bg-[#e8ede9] p-4 text-sm font-medium leading-relaxed text-[#4f5551]">
          Oi, José. Como você se sentiu depois do último treino?
        </div>
        {sent ? (
          <div className="rounded-2xl bg-[#c6ff32] p-4 text-center text-sm font-extrabold text-[#172000]">
            Mensagem enviada. Rafael responderá em breve.
          </div>
        ) : (
          <div className="flex gap-2">
            <input
              aria-label="Mensagem para o treinador"
              className="min-w-0 flex-1 rounded-2xl border border-[#dfe4df] bg-white px-4 text-sm font-medium outline-none transition focus:border-[#9bc91c]"
              placeholder="Escreva uma mensagem..."
            />
            <button
              aria-label="Enviar mensagem"
              className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-[#171b19] text-[#c6ff32]"
              onClick={() => setSent(true)}
            >
              <Icon name="send" size={19} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function Toggle({
  active,
  onChange,
  label,
}: {
  active: boolean;
  onChange: () => void;
  label: string;
}) {
  return (
    <button
      aria-label={label}
      aria-pressed={active}
      className={`relative h-7 w-12 shrink-0 rounded-full transition ${active ? "bg-[#171b19]" : "bg-[#d9ded9]"}`}
      onClick={onChange}
    >
      <span className={`absolute top-1 h-5 w-5 rounded-full transition-all ${active ? "left-6 bg-[#c6ff32]" : "left-1 bg-white"}`} />
    </button>
  );
}

function SettingsScreen({ onClose, onLogout }: { onClose: () => void; onLogout: () => void }) {
  const [workoutAlerts, setWorkoutAlerts] = useState(true);
  const [coachMessages, setCoachMessages] = useState(true);
  const [liveLocation, setLiveLocation] = useState(true);
  const [privateProfile, setPrivateProfile] = useState(false);
  const [unit, setUnit] = useState<"km" | "mi">("km");

  return (
    <div className="absolute inset-0 z-50 bg-[#f7f9f7] screen-enter">
      <div className="h-full overflow-y-auto pb-8 scrollbar-hide">
        <header className="sticky top-0 z-20 flex items-center border-b border-[#e4e8e4] bg-[#f7f9f7]/95 px-5 py-4 backdrop-blur-xl">
          <button
            aria-label="Voltar"
            className="grid h-11 w-11 place-items-center rounded-full border border-[#dce1dc] bg-white"
            onClick={onClose}
          >
            <Icon name="arrow" size={20} />
          </button>
          <h1 className="flex-1 pr-11 text-center text-[17px] font-extrabold">Configurações</h1>
        </header>

        <main className="space-y-6 px-5 py-5">
          <section>
            <p className="mb-2 px-1 text-[10px] font-extrabold uppercase tracking-[0.15em] text-[#818783]">Conta</p>
            <div className="overflow-hidden rounded-[22px] border border-[#e1e5e1] bg-white">
              <button className="flex w-full items-center gap-3 border-b border-[#edf0ed] p-4 text-left">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#eff2ef]"><Icon name="user" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Dados pessoais</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Nome, e-mail e telefone</span>
                </span>
                <Icon name="chevron" size={17} />
              </button>
              <button className="flex w-full items-center gap-3 p-4 text-left">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#eff2ef]"><Icon name="lock" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Senha e segurança</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Senha e acessos ativos</span>
                </span>
                <Icon name="chevron" size={17} />
              </button>
            </div>
          </section>

          <section>
            <p className="mb-2 px-1 text-[10px] font-extrabold uppercase tracking-[0.15em] text-[#818783]">Notificações</p>
            <div className="divide-y divide-[#edf0ed] overflow-hidden rounded-[22px] border border-[#e1e5e1] bg-white">
              <div className="flex items-center gap-3 p-4">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#efffc6]"><Icon name="calendar" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Lembretes de treino</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Avisos antes de cada atividade</span>
                </span>
                <Toggle active={workoutAlerts} label="Lembretes de treino" onChange={() => setWorkoutAlerts((value) => !value)} />
              </div>
              <div className="flex items-center gap-3 p-4">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#efffc6]"><Icon name="message" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Mensagens do treinador</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Orientações e ajustes no plano</span>
                </span>
                <Toggle active={coachMessages} label="Mensagens do treinador" onChange={() => setCoachMessages((value) => !value)} />
              </div>
            </div>
          </section>

          <section>
            <p className="mb-2 px-1 text-[10px] font-extrabold uppercase tracking-[0.15em] text-[#818783]">Treinos</p>
            <div className="rounded-[22px] border border-[#e1e5e1] bg-white p-4">
              <p className="text-sm font-extrabold">Unidade de distância</p>
              <p className="mt-0.5 text-[11px] font-medium text-[#858b87]">Usada nos treinos e relatórios</p>
              <div className="mt-3 grid grid-cols-2 rounded-xl bg-[#eff2ef] p-1">
                {(["km", "mi"] as const).map((item) => (
                  <button
                    className={`rounded-lg py-2 text-xs font-extrabold transition ${unit === item ? "bg-white shadow-sm" : "text-[#7d837f]"}`}
                    key={item}
                    onClick={() => setUnit(item)}
                  >
                    {item === "km" ? "Quilômetros" : "Milhas"}
                  </button>
                ))}
              </div>
            </div>
          </section>

          <section>
            <p className="mb-2 px-1 text-[10px] font-extrabold uppercase tracking-[0.15em] text-[#818783]">Privacidade e segurança</p>
            <div className="divide-y divide-[#edf0ed] overflow-hidden rounded-[22px] border border-[#e1e5e1] bg-white">
              <div className="flex items-center gap-3 p-4">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#fff0ee] text-[#d33a2f]"><Icon name="shield" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Localização de emergência</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Compartilhar durante alertas</span>
                </span>
                <Toggle active={liveLocation} label="Localização de emergência" onChange={() => setLiveLocation((value) => !value)} />
              </div>
              <div className="flex items-center gap-3 p-4">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#eff2ef]"><Icon name="eye" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Perfil privado</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Somente seu treinador pode ver</span>
                </span>
                <Toggle active={privateProfile} label="Perfil privado" onChange={() => setPrivateProfile((value) => !value)} />
              </div>
              <button className="flex w-full items-center gap-3 p-4 text-left">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#eff2ef]"><Icon name="user" size={18} /></span>
                <span className="flex-1">
                  <span className="block text-sm font-extrabold">Contato de emergência</span>
                  <span className="block text-[11px] font-medium text-[#858b87]">Marina Silva · irmã</span>
                </span>
                <Icon name="chevron" size={17} />
              </button>
            </div>
          </section>

          <button
            className="flex w-full items-center justify-center gap-2 rounded-2xl border border-[#f0d1ce] bg-[#fff5f4] py-4 text-sm font-extrabold text-[#c83328]"
            onClick={onLogout}
          >
            <Icon name="logout" size={18} />
            Sair da conta
          </button>
          <p className="text-center text-[10px] font-bold text-[#a0a5a1]">Versão 1.0.0</p>
        </main>
      </div>
    </div>
  );
}

type CoachScreen = "painel" | "treinos" | "conversa";

function CoachMode({ onExit }: { onExit: () => void }) {
  const [screen, setScreen] = useState<CoachScreen>("painel");
  const [selectedWorkout, setSelectedWorkout] = useState("Ritmo progressivo");
  const [assigned, setAssigned] = useState(false);
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState([
    { from: "runner", text: "Bom dia, professor. Senti um pouco as pernas no fim do treino de ontem." },
    { from: "coach", text: "Bom dia, José. Vamos reduzir a intensidade hoje. Como está a recuperação agora?" },
    { from: "runner", text: "Bem melhor. Acho que consigo fazer um treino leve." },
  ]);

  const library = [
    { title: "Rodagem regenerativa", detail: "5 km · Zona 2 · 35 min", level: "Leve", icon: "run" as IconName },
    { title: "Ritmo progressivo", detail: "6,5 km · 42 min", level: "Moderado", icon: "trend" as IconName },
    { title: "Intervalado 6 × 400 m", detail: "8 km · 48 min", level: "Intenso", icon: "zap" as IconName },
    { title: "Longão confortável", detail: "12 km · 1h15", level: "Moderado", icon: "route" as IconName },
  ];

  function sendMessage() {
    if (!message.trim()) return;
    setMessages((current) => [...current, { from: "coach", text: message.trim() }]);
    setMessage("");
  }

  return (
    <div className="absolute inset-0 z-50 bg-[#f7f9f7] screen-enter">
      <div className="h-full overflow-y-auto pb-28 scrollbar-hide">
        <header className="sticky top-0 z-20 flex items-center justify-between border-b border-[#e6e9e6] bg-[#f7f9f7]/95 px-5 py-4 backdrop-blur-xl">
          <div className="flex items-center gap-3">
            <div className="grid h-11 w-11 place-items-center rounded-2xl bg-[#171b19] text-sm font-extrabold text-[#c6ff32]">RM</div>
            <div>
              <p className="text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#7c827e]">Modo treinador</p>
              <h1 className="text-[16px] font-extrabold">Rafael Martins</h1>
            </div>
          </div>
          <button
            className="rounded-full border border-[#dce1dc] bg-white px-3 py-2 text-[10px] font-extrabold uppercase tracking-[0.08em]"
            onClick={onExit}
          >
            Sair
          </button>
        </header>

        {screen === "painel" && (
          <main className="space-y-5 px-5 py-5 screen-enter">
            <section>
              <p className="eyebrow">Visão geral</p>
              <h2 className="mt-1 text-[28px] font-extrabold tracking-[-0.045em]">Seus alunos</h2>
              <p className="mt-1 text-sm font-medium text-[#737975]">Acompanhe o treino e mantenha todos em movimento.</p>
            </section>

            <section className="grid grid-cols-3 gap-2">
              {[
                ["08", "alunos ativos"],
                ["05", "treinos hoje"],
                ["03", "mensagens"],
              ].map(([value, label], index) => (
                <div className={`rounded-[20px] p-3 ${index === 1 ? "bg-[#c6ff32]" : "bg-[#171b19] text-white"}`} key={label}>
                  <p className="text-[22px] font-extrabold tracking-[-0.04em]">{value}</p>
                  <p className={`mt-1 text-[9px] font-bold leading-tight ${index === 1 ? "text-[#3b4b10]" : "text-white/50"}`}>{label}</p>
                </div>
              ))}
            </section>

            <section>
              <div className="mb-3 flex items-center justify-between">
                <h3 className="section-title">Precisa de atenção</h3>
                <span className="rounded-full bg-[#fff0ee] px-2.5 py-1 text-[10px] font-extrabold text-[#c83328]">1 aluno</span>
              </div>
              <button
                className="w-full rounded-[26px] border border-[#e1e5e1] bg-white p-4 text-left shadow-[0_8px_25px_rgba(20,27,22,.05)]"
                onClick={() => setScreen("conversa")}
              >
                <div className="flex items-center gap-3">
                  <div className="relative grid h-13 w-13 place-items-center rounded-2xl bg-[#202522] text-base font-extrabold text-white">
                    JA
                    <span className="absolute -right-1 -top-1 grid h-5 w-5 place-items-center rounded-full border-2 border-white bg-[#e84032] text-[9px]">1</span>
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <h4 className="text-[16px] font-extrabold">José Anderson</h4>
                      <span className="text-[10px] font-bold text-[#929793]">08:42</span>
                    </div>
                    <p className="mt-0.5 text-xs font-medium text-[#737975]">Relatou pernas cansadas após o último treino.</p>
                  </div>
                </div>
                <div className="mt-4 grid grid-cols-3 divide-x divide-[#e4e8e4] rounded-2xl bg-[#f1f4f1] p-3">
                  <div>
                    <p className="text-[9px] font-bold text-[#929793]">SEMANA</p>
                    <p className="mt-1 text-sm font-extrabold">18,4 km</p>
                  </div>
                  <div className="pl-3">
                    <p className="text-[9px] font-bold text-[#929793]">ADESÃO</p>
                    <p className="mt-1 text-sm font-extrabold">92%</p>
                  </div>
                  <div className="pl-3">
                    <p className="text-[9px] font-bold text-[#929793]">ESFORÇO</p>
                    <p className="mt-1 text-sm font-extrabold">7/10</p>
                  </div>
                </div>
              </button>
            </section>

            <section>
              <div className="mb-3 flex items-center justify-between">
                <h3 className="section-title">Agenda de hoje</h3>
                <button className="text-xs font-extrabold" onClick={() => setScreen("treinos")}>Ver treinos</button>
              </div>
              <div className="space-y-2.5">
                {[
                  ["06:30", "José Anderson", "Ritmo progressivo", true],
                  ["07:15", "Marina Alves", "Rodagem de 5 km", true],
                  ["18:30", "Lucas Rocha", "Intervalado 6 × 400 m", false],
                ].map(([time, name, workout, done]) => (
                  <div className="flex items-center gap-3 rounded-[18px] border border-[#e3e7e3] bg-white p-3" key={name as string}>
                    <span className="w-10 text-xs font-extrabold text-[#747a76]">{time}</span>
                    <span className={`h-8 w-1 rounded-full ${done ? "bg-[#c6ff32]" : "bg-[#dfe3df]"}`} />
                    <span className="flex-1">
                      <span className="block text-sm font-extrabold">{name}</span>
                      <span className="block text-[10px] font-medium text-[#858b87]">{workout}</span>
                    </span>
                    {done && <Icon className="text-[#759900]" name="check" size={17} strokeWidth={2.5} />}
                  </div>
                ))}
              </div>
            </section>
          </main>
        )}

        {screen === "treinos" && (
          <main className="space-y-5 px-5 py-5 screen-enter">
            <section>
              <p className="eyebrow">Biblioteca de treinos</p>
              <h2 className="mt-1 text-[28px] font-extrabold tracking-[-0.045em]">Escolha para José</h2>
              <p className="mt-1 text-sm font-medium text-[#737975]">Selecione um treino e envie para a agenda do aluno.</p>
            </section>

            <div className="flex items-center gap-3 rounded-[22px] bg-[#e9efeb] p-4">
              <div className="grid h-12 w-12 place-items-center rounded-2xl bg-[#171b19] font-extrabold text-white">JA</div>
              <div className="flex-1">
                <p className="text-[15px] font-extrabold">José Anderson</p>
                <p className="text-xs font-medium text-[#737975]">Intermediário · Meta 10 km</p>
              </div>
              <Icon name="chevron" size={17} />
            </div>

            <section className="space-y-2.5">
              {library.map((workout) => {
                const selected = selectedWorkout === workout.title;
                return (
                  <button
                    className={`flex w-full items-center gap-3 rounded-[21px] border p-3 text-left transition ${
                      selected ? "border-[#171b19] bg-[#171b19] text-white" : "border-[#e1e5e1] bg-white"
                    }`}
                    key={workout.title}
                    onClick={() => { setSelectedWorkout(workout.title); setAssigned(false); }}
                  >
                    <span className={`grid h-12 w-12 shrink-0 place-items-center rounded-2xl ${selected ? "bg-[#c6ff32] text-[#172000]" : "bg-[#eff2ef]"}`}>
                      <Icon name={workout.icon} size={22} />
                    </span>
                    <span className="flex-1">
                      <span className="block text-[15px] font-extrabold">{workout.title}</span>
                      <span className={`mt-0.5 block text-[11px] font-medium ${selected ? "text-white/55" : "text-[#777d79]"}`}>{workout.detail}</span>
                    </span>
                    <span className={`rounded-full px-2 py-1 text-[9px] font-extrabold ${selected ? "bg-white/10" : "bg-[#f0f3f0]"}`}>{workout.level}</span>
                  </button>
                );
              })}
            </section>

            <section className="rounded-[22px] border border-[#e1e5e1] bg-white p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-[10px] font-bold text-[#818783]">AGENDAR PARA</p>
                  <p className="mt-1 text-sm font-extrabold">Hoje · 18:30</p>
                </div>
                <button className="grid h-10 w-10 place-items-center rounded-xl bg-[#eff2ef]"><Icon name="calendar" size={18} /></button>
              </div>
              <textarea
                className="mt-3 h-20 w-full resize-none rounded-xl bg-[#f3f5f3] p-3 text-xs font-medium outline-none focus:ring-1 focus:ring-[#9bc91c]"
                defaultValue="Faça em ritmo confortável e me avise se sentir qualquer incômodo."
              />
            </section>

            <button
              className={`flex w-full items-center justify-center gap-2 rounded-2xl py-4 text-sm font-extrabold transition ${
                assigned ? "bg-[#c6ff32] text-[#172000]" : "bg-[#171b19] text-white"
              }`}
              onClick={() => setAssigned(true)}
            >
              <Icon name={assigned ? "check" : "send"} size={18} />
              {assigned ? "Treino enviado para José" : `Enviar “${selectedWorkout}”`}
            </button>
          </main>
        )}

        {screen === "conversa" && (
          <main className="flex min-h-[calc(100%-76px)] flex-col screen-enter">
            <div className="flex items-center gap-3 border-b border-[#e4e8e4] bg-white px-5 py-4">
              <div className="relative grid h-12 w-12 place-items-center rounded-2xl bg-[#202522] font-extrabold text-white">
                JA
                <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-[3px] border-white bg-[#c6ff32]" />
              </div>
              <div className="flex-1">
                <h2 className="text-[16px] font-extrabold">José Anderson</h2>
                <p className="text-[11px] font-bold text-[#7b817d]">Online agora</p>
              </div>
              <button className="grid h-10 w-10 place-items-center rounded-xl bg-[#eff2ef]" onClick={() => setScreen("treinos")}>
                <Icon name="calendar" size={18} />
              </button>
            </div>
            <div className="flex-1 space-y-3 px-5 py-5">
              <p className="text-center text-[9px] font-extrabold uppercase tracking-[0.14em] text-[#999e9a]">Hoje</p>
              {messages.map((item, index) => (
                <div
                  className={`max-w-[84%] rounded-[20px] px-4 py-3 text-sm font-medium leading-relaxed ${
                    item.from === "coach"
                      ? "ml-auto rounded-br-md bg-[#171b19] text-white"
                      : "rounded-bl-md border border-[#e0e4e0] bg-white text-[#464c48]"
                  }`}
                  key={`${item.text}-${index}`}
                >
                  {item.text}
                </div>
              ))}
            </div>
            <div className="sticky bottom-20 flex gap-2 border-t border-[#e1e5e1] bg-[#f7f9f7] px-5 py-3">
              <input
                className="min-w-0 flex-1 rounded-2xl border border-[#dfe4df] bg-white px-4 text-sm font-medium outline-none focus:border-[#9bc91c]"
                placeholder="Fale com José..."
                value={message}
                onChange={(event) => setMessage(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") sendMessage();
                }}
              />
              <button className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-[#171b19] text-[#c6ff32]" onClick={sendMessage}>
                <Icon name="send" size={19} />
              </button>
            </div>
          </main>
        )}
      </div>

      <nav className="absolute bottom-0 left-0 right-0 z-30 border-t border-[#e3e6e3] bg-white/95 px-5 pb-[max(12px,env(safe-area-inset-bottom))] pt-2 backdrop-blur-xl">
        <div className="grid grid-cols-3">
          {[
            { id: "painel" as CoachScreen, label: "Alunos", icon: "user" as IconName },
            { id: "treinos" as CoachScreen, label: "Treinos", icon: "calendar" as IconName },
            { id: "conversa" as CoachScreen, label: "Conversa", icon: "message" as IconName },
          ].map((item) => (
            <button
              className={`relative flex flex-col items-center gap-1.5 rounded-2xl py-2 text-[10px] font-extrabold ${
                screen === item.id ? "text-[#171b19]" : "text-[#929793]"
              }`}
              key={item.id}
              onClick={() => setScreen(item.id)}
            >
              {screen === item.id && <span className="absolute top-0 h-1 w-5 rounded-full bg-[#c6ff32]" />}
              <Icon name={item.icon} size={21} strokeWidth={screen === item.id ? 2.3 : 1.8} />
              {item.label}
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
}

export default function App() {
  const [authenticated, setAuthenticated] = useState(false);
  const [screen, setScreen] = useState<Screen>("inicio");
  const [workoutOpen, setWorkoutOpen] = useState(false);
  const [coachOpen, setCoachOpen] = useState(false);
  const [coachMode, setCoachMode] = useState(false);
  const [emergencyOpen, setEmergencyOpen] = useState(false);
  const [routesOpen, setRoutesOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [notice, setNotice] = useState(false);

  function logout() {
    setSettingsOpen(false);
    setCoachMode(false);
    setScreen("inicio");
    setAuthenticated(false);
  }

  return (
    <div className="min-h-screen bg-[#e9ede9] text-[#171b19] md:grid md:place-items-center md:p-6">
      <div className="relative mx-auto h-[100dvh] w-full max-w-[460px] overflow-hidden bg-[#f8faf8] md:h-[min(900px,94vh)] md:rounded-[38px] md:border-[7px] md:border-[#171b19] md:shadow-[0_35px_90px_rgba(20,27,22,.2)]">
        {!authenticated ? (
          <LoginScreen onLogin={() => setAuthenticated(true)} />
        ) : (
          <>
            <div className="h-full overflow-y-auto overscroll-contain scrollbar-hide">
              {screen === "inicio" && (
                <HomeScreen
                  onCoach={() => setCoachOpen(true)}
                  onEmergency={() => setEmergencyOpen(true)}
                  onNavigate={setScreen}
                  onNotify={() => setNotice(true)}
                  onRoutes={() => setRoutesOpen(true)}
                  onStart={() => setWorkoutOpen(true)}
                />
              )}
              {screen === "plano" && <PlanScreen onStart={() => setWorkoutOpen(true)} />}
              {screen === "evolucao" && <EvolutionScreen />}
              {screen === "perfil" && (
                <ProfileScreen
                  onCoach={() => setCoachOpen(true)}
                  onCoachMode={() => setCoachMode(true)}
                  onSettings={() => setSettingsOpen(true)}
                />
              )}
            </div>
            <BottomNav active={screen} onChange={setScreen} />
            {workoutOpen && <WorkoutScreen onClose={() => setWorkoutOpen(false)} />}
            {coachOpen && <CoachPanel onClose={() => setCoachOpen(false)} />}
            {emergencyOpen && <EmergencyPanel onClose={() => setEmergencyOpen(false)} />}
            {routesOpen && (
              <RoutesScreen
                onClose={() => setRoutesOpen(false)}
                onStart={() => {
                  setRoutesOpen(false);
                  setWorkoutOpen(true);
                }}
              />
            )}
            {coachMode && <CoachMode onExit={() => setCoachMode(false)} />}
            {settingsOpen && <SettingsScreen onClose={() => setSettingsOpen(false)} onLogout={logout} />}
            {notice && (
              <div className="absolute left-5 right-5 top-5 z-50 flex items-center gap-3 rounded-2xl bg-[#171b19] p-4 text-white shadow-2xl screen-up">
                <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-[#c6ff32] text-[#172000]">
                  <Icon name="bell" size={18} />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-extrabold">Treino atualizado</p>
                  <p className="text-xs font-medium text-white/55">Rafael ajustou o ritmo de hoje.</p>
                </div>
                <button className="text-xl text-white/60" onClick={() => setNotice(false)}>×</button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
