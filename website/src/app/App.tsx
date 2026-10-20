import { ArrowLeft, ArrowRight, Globe, House, Moon, Sun } from '@phosphor-icons/react';
import { motion } from 'motion/react';
import { useEffect, useMemo, useState } from 'react';

import { LoremPage } from '../features/lorem/LoremPage';
import { ImageConverterPage } from '../features/image/ImageConverterPage';
import { VideoConverterPage } from '../features/video/VideoConverterPage';
import { BackgroundRemoverPage } from '../features/background/BackgroundRemoverPage';
import { tools, toolText, type ToolId } from './catalog';
import { syncDesktopTheme } from './desktop-bridge';
import { DownloadCenterButton, DownloadCenterProvider } from './download-center';
import { HomePage } from './HomePage';
import { translate, type Language, type MessageKey } from './i18n';

type Theme = 'light' | 'dark';

export function App() {
  return <DownloadCenterProvider><Workspace /></DownloadCenterProvider>;
}

function Workspace() {
  const [language, setLanguage] = useState<Language>(() => localStorage.getItem('pixora-language') === 'fa' ? 'fa' : 'en');
  const [theme, setTheme] = useState<Theme>(() => localStorage.getItem('pixora-theme') === 'light' ? 'light' : 'dark');
  const [activeTool, setActiveTool] = useState<ToolId>('home');
  const t = useMemo(() => (key: MessageKey) => translate(language, key), [language]);
  const Back = language === 'fa' ? ArrowRight : ArrowLeft;

  useEffect(() => {
    document.documentElement.lang = language;
    document.documentElement.dir = language === 'fa' ? 'rtl' : 'ltr';
    localStorage.setItem('pixora-language', language);
  }, [language]);
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem('pixora-theme', theme);
    syncDesktopTheme(theme);
  }, [theme]);

  const content = activeTool === 'image-converter'
    ? <ImageConverterPage uiLanguage={language} />
    : activeTool === 'video-converter'
    ? <VideoConverterPage uiLanguage={language} />
    : activeTool === 'audio-extractor'
    ? <VideoConverterPage uiLanguage={language} mode="audio" />
    : activeTool === 'background-remover'
    ? <BackgroundRemoverPage uiLanguage={language} />
    : activeTool === 'lorem'
    ? <LoremPage uiLanguage={language} />
    : activeTool === 'home'
      ? <HomePage language={language} onOpen={setActiveTool} />
      : null;

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <button className="brand" onClick={() => setActiveTool('home')} aria-label={t('home')}>
          <img src="./pixora-mark.svg" alt="" /><strong>{t('appName')}</strong>
        </button>
        <nav aria-label={t('allTools')}>
          <button className={activeTool === 'home' ? 'nav-item active' : 'nav-item'} onClick={() => setActiveTool('home')}><House size={20} /><span>{t('home')}</span></button>
          {tools.map((tool) => {
            const Icon = tool.icon;
            return <button key={tool.id} className={activeTool === tool.id ? 'nav-item active' : 'nav-item'} onClick={() => setActiveTool(tool.id)}><Icon size={20} /><span>{t(toolText[tool.id][0])}</span></button>;
          })}
        </nav>
        <div className="sidebar-footer">
          <button onClick={() => setLanguage((value) => value === 'fa' ? 'en' : 'fa')} aria-label={t('language')}><Globe size={19} /><span>{language === 'fa' ? 'EN' : 'فا'}</span></button>
          <button onClick={() => setTheme((value) => value === 'light' ? 'dark' : 'light')} aria-label={t('theme')}>{theme === 'light' ? <Moon size={19} /> : <Sun size={19} />}</button>
          <DownloadCenterButton uiLanguage={language} placement="sidebar" />
        </div>
      </aside>
      <section className="workspace">
        <div className="mobile-toolbar"><button onClick={() => setLanguage((value) => value === 'fa' ? 'en' : 'fa')} aria-label={t('language')}><Globe size={19} /><span>{language === 'fa' ? 'EN' : 'فا'}</span></button><button onClick={() => setTheme((value) => value === 'light' ? 'dark' : 'light')} aria-label={t('theme')}>{theme === 'light' ? <Moon size={19} /> : <Sun size={19} />}</button><DownloadCenterButton uiLanguage={language} placement="mobile" /></div>
        {activeTool !== 'home' && <button className="mobile-back" onClick={() => setActiveTool('home')}><Back size={18} />{t('backHome')}</button>}
        <motion.div key={activeTool} className="page-frame" initial={false} animate={{ opacity: 1 }} transition={{ duration: 0.16 }}>{content}</motion.div>
      </section>
    </div>
  );
}
