"use client";

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import { Globe } from "lucide-react";

export type SupportedLanguage = "kk" | "en";

export const translations = {
  kk: {
    // Navigation & Sidebar
    "nav.dashboard": "Басты бет",
    "nav.templates": "Үлгілер",
    "nav.smart": "Смарт дизайн",
    "nav.community": "Қоғамдастық",
    "nav.settings": "Баптаулар",
    "nav.new_presentation": "Жаңа презентация",
    "nav.new": "Жаңа",
    "nav.back": "АРТҚА",

    // Dashboard
    "dashboard.title": "Басты бет",
    "dashboard.actions": "Әрекеттер",
    "dashboard.create_presentation": "Жаңа презентация жасау",
    "dashboard.blank_presentation": "Бос презентация",
    "dashboard.creating": "Жасалуда...",
    "dashboard.decks": "Презентациялар",
    "dashboard.grid_view": "Тор көрінісі",
    "dashboard.list_view": "Тізім көрінісі",
    "dashboard.no_presentations": "Әзірге презентациялар жоқ.",
    "dashboard.get_started": "Қазір бастау",
    "dashboard.duplicate": "Көшірмесін жасау",
    "dashboard.duplicating": "Көшірілуде...",
    "dashboard.delete": "Жою",
    "dashboard.delete_confirm_title": "Презентацияны жою керек пе?",
    "dashboard.delete_confirm_desc":
      "Бұл презентацияны шынымен жойғыңыз келе ме? Бұл әрекетті қайтару мүмкін емес.",
    "dashboard.cancel": "Бас тарту",
    "dashboard.settings": "Баптаулар",
    "dashboard.join_discord": "Discord-қа қосылу",

    // Generation / Upload
    "upload.title": "Жаңа презентация жасау",
    "upload.hero_title": "Презентация жасау",
    "upload.hero_subtitle":
      "Сұраныстар мен құжаттарды AI көмегімен презентацияға айналдырыңыз",
    "upload.write_prompt": "Сұраныс жазу",
    "upload.prompt_placeholder":
      "Ойыңызды немесе тақырыпты жазыңыз... қалғанын AI жасайды",
    "upload.community_placeholder":
      "Дизайнды таңдап, AI-ға презентация жасауды тапсырыңыз.",
    "upload.create_from_community": "Қоғамдастықтан жасау",
    "upload.slides": "слайд",
    "upload.slides_count": "Слайдтар саны",
    "upload.auto_slides": "Авто слайдтар",
    "upload.language": "Тіл",
    "upload.select_language": "Тілді таңдау",
    "upload.search_language": "Тілді іздеу...",
    "upload.no_language_found": "Тіл табылмады.",
    "upload.top_languages": "Таңдаулы тілдер",
    "upload.other_languages": "Барлық тілдер",
    "upload.advanced_settings": "Қосымша баптаулар",
    "upload.advanced_settings_title": "Қосымша баптаулар",
    "upload.adjust_behavior": "Презентация параметрлерін реттеу",
    "upload.write_instructions": "Нұсқаулық жазу",
    "upload.instructions_placeholder":
      "AI-ға бағыт беріңіз: аудитория, стиль, басты ойлар немесе шектеулер.",
    "upload.select_tone": "Стильді таңдау",
    "upload.select_verbosity": "Көлемді таңдау",
    "upload.include_toc": "Мазмұнын қосу (Жоспар)",
    "upload.title_slide": "Мұқаба слайды",
    "upload.tone": "Стиль (Тон)",
    "upload.verbosity": "Мәтін көлемі",
    "upload.generate": "Презентация жасау",
    "upload.generating": "Дайындалуда...",
    "upload.supporting_docs": "Қосымша құжаттар",
    "upload.drag_files": "Файлдарды осында сүйреңіз",
    "upload.or_browse": "немесе файл таңдаңыз",
    "upload.attach_files": "Файлдарды тіркеу",
    "upload.attach_more": "Тағы тіркеу",

    // Generation Mode
    "mode.select_title": "Режимді таңдау",
    "mode.standard": "Standard",
    "mode.standard_tag": "Бекітілген макет",
    "mode.standard_desc": "Қатаң белгіленген дайын шаблондар мен құрылым. Тұрақты әрі болжамды классикалық нәтиже.",
    "mode.select_standard": "Standard таңдау",
    "mode.smart": "Smart",
    "mode.smart_tag": "Бейімделгіш макет (Ұсынылады)",
    "mode.smart_desc": "Мазмұнға сай өздігінен бейімделетін икемді құрылым. AI нақты уақытта тікелей слайдтарды жасайды және чатпен өңдеуді қолдайды.",
    "mode.select_smart": "Smart таңдау",

    "common.save": "Сақтау",
    "common.cancel": "Бас тарту",
    "editor.export": "Экспорттау",
    "editor.export_as": "Экспорттау пішімі",
    "editor.exporting": "Экспортталуда...",
    "editor.present": "Көрсету",
    "editor.undo": "Қайтару",
    "editor.redo": "Қайта қолдану",
    "editor.regenerate": "Қайта құрастыру",
    "editor.regenerate_confirm_title": "Презентацияны қайта құрастыру керек пе?",
    "editor.regenerate_confirm_desc":
      "Бұл ағымдағы слайдтарды жаңадан жасалған нұсқамен алмастырады және болдырмау тарихын тазартады. Ағымдағы өзгерістеріңіз жоғалуы мүмкін.",
    "editor.save": "Сақтау",
    "editor.cancel": "Бас тарту",
    "editor.rename": "Атауын өзгерту",
    "editor.title_placeholder": "Презентация атауы",
    "editor.select_to_edit": "Таңдап өңдеу",
    "editor.element_selection_on": "Элементті таңдау қосулы",
    "editor.element_select_tooltip_off": "Слайд элементін басып, оны AI чатқа қосыңыз",
    "editor.shortcuts": "Пернелер тіркесімі",
    "editor.keyboard_shortcuts_tooltip": "Пернелер тіркесімі (?)",
    "editor.theme": "Тақырып / Стиль",
    "editor.blocks": "Блоктар",
    "editor.search_blocks": "Блоктарды іздеу",
    "editor.blocks_require_template": "Блоктар презентация үлгісін қажет етеді",
    "editor.texts": "Мәтіндер",
    "editor.charts": "Диаграммалар",
    "editor.infographics": "Инфографика",
    "editor.tables": "Кестелер",
    "editor.images": "Суреттер",
    "editor.elements": "Элементтер",
    "editor.new_slide": "Жаңа слайд",
    "editor.add_slides": "Слайд қосу",
    "editor.chat_title": "AI Көмекші",
    "editor.chat_placeholder": "AI-дан слайдты өзгертуді сұраңыз...",
  },
  en: {
    // Navigation & Sidebar
    "nav.dashboard": "Dashboard",
    "nav.templates": "Templates",
    "nav.smart": "Smart",
    "nav.community": "Community",
    "nav.settings": "Settings",
    "nav.new_presentation": "New presentation",
    "nav.new": "New",
    "nav.back": "BACK",

    // Dashboard
    "dashboard.title": "Dashboard",
    "dashboard.actions": "Actions",
    "dashboard.create_presentation": "Create new Presentation",
    "dashboard.blank_presentation": "Blank Presentation",
    "dashboard.creating": "Creating...",
    "dashboard.decks": "Decks",
    "dashboard.grid_view": "Grid view",
    "dashboard.list_view": "List view",
    "dashboard.no_presentations": "No presentations yet.",
    "dashboard.get_started": "Get started now",
    "dashboard.duplicate": "Duplicate",
    "dashboard.duplicating": "Duplicating...",
    "dashboard.delete": "Delete",
    "dashboard.delete_confirm_title": "Delete presentation?",
    "dashboard.delete_confirm_desc":
      "Are you sure you want to delete this presentation? This action cannot be undone.",
    "dashboard.cancel": "Cancel",
    "dashboard.settings": "Settings",
    "dashboard.join_discord": "Join Discord",

    // Generation / Upload
    "upload.title": "Create new Presentation",
    "upload.hero_title": "Generate",
    "upload.hero_subtitle":
      "Turn prompts or documents into presentations with AI",
    "upload.write_prompt": "Write prompt",
    "upload.prompt_placeholder":
      "Start with your idea... we'll handle the slides",
    "upload.community_placeholder":
      "Choose a design, then tell AI how to turn it into your deck.",
    "upload.create_from_community": "Create from community",
    "upload.slides": "slides",
    "upload.slides_count": "Slides",
    "upload.auto_slides": "Auto slides",
    "upload.language": "Language",
    "upload.select_language": "Select language",
    "upload.search_language": "Search language...",
    "upload.no_language_found": "No language found.",
    "upload.top_languages": "Top languages",
    "upload.other_languages": "All languages",
    "upload.advanced_settings": "Advanced Settings",
    "upload.advanced_settings_title": "Advanced Settings",
    "upload.adjust_behavior": "Adjust Presentation Behavior",
    "upload.write_instructions": "Write instructions",
    "upload.instructions_placeholder":
      "Guide the AI: define audience, tone, key points, or constraints.",
    "upload.select_tone": "Select tone",
    "upload.select_verbosity": "Select verbosity",
    "upload.include_toc": "Include Table of Content",
    "upload.title_slide": "Title Slide",
    "upload.tone": "Tone",
    "upload.verbosity": "Verbosity",
    "upload.generate": "Generate",
    "upload.generating": "Generating...",
    "upload.supporting_docs": "Supporting documents",
    "upload.drag_files": "Drag files here",
    "upload.or_browse": "or browse from device",
    "upload.attach_files": "Attach files",
    "upload.attach_more": "Attach more",

    // Generation Mode
    "mode.select_title": "Select Mode",
    "mode.standard": "Standard",
    "mode.standard_tag": "Fixed layout",
    "mode.standard_desc": "A rigid, predefined layout with fixed structure, ensuring consistency, clarity, and predictable results.",
    "mode.select_standard": "Select Standard",
    "mode.smart": "Smart",
    "mode.smart_tag": "Flexible layout (Recommended)",
    "mode.smart_desc": "A smart adaptive layout with flexible structure, balancing consistency and content with real-time AI streaming.",
    "mode.select_smart": "Select Smart",

    "common.save": "Save",
    "common.cancel": "Cancel",
    "editor.export": "Export",
    "editor.export_as": "Export as",
    "editor.exporting": "Exporting...",
    "editor.present": "Present",
    "editor.undo": "Undo",
    "editor.redo": "Redo",
    "editor.regenerate": "Regenerate Presentation",
    "editor.regenerate_confirm_title": "Regenerate Presentation?",
    "editor.regenerate_confirm_desc":
      "This will replace the current slides with a newly generated version and clear undo history. Your current edits may be lost.",
    "editor.save": "Save",
    "editor.cancel": "Cancel",
    "editor.rename": "Rename presentation",
    "editor.title_placeholder": "Presentation title",
    "editor.select_to_edit": "Select to edit",
    "editor.element_selection_on": "Element selection is on",
    "editor.element_select_tooltip_off": "Click a slide element to add it to AI chat",
    "editor.shortcuts": "Keyboard shortcuts",
    "editor.keyboard_shortcuts_tooltip": "Keyboard shortcuts (?)",
    "editor.theme": "Theme",
    "editor.blocks": "Blocks",
    "editor.search_blocks": "Search blocks",
    "editor.blocks_require_template": "Blocks require a presentation template",
    "editor.texts": "Texts",
    "editor.charts": "Charts",
    "editor.infographics": "Infographics",
    "editor.tables": "Tables",
    "editor.images": "Images",
    "editor.elements": "Elements",
    "editor.new_slide": "New slide",
    "editor.add_slides": "Add Slides",
    "editor.chat_title": "AI Chat",
    "editor.chat_placeholder": "Ask AI to edit this slide...",
  },
} as const;

export type TranslationKey = keyof typeof translations.en;

interface I18nContextType {
  language: SupportedLanguage;
  setLanguage: (lang: SupportedLanguage) => void;
  toggleLanguage: () => void;
  t: (key: TranslationKey, fallback?: string) => string;
}

const I18nContext = createContext<I18nContextType>({
  language: "kk",
  setLanguage: () => {},
  toggleLanguage: () => {},
  t: (key, fallback) => (translations.kk as Record<string, string>)[key] || fallback || key,
});

const STORAGE_KEY = "presenton_ui_language";

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguageState] = useState<SupportedLanguage>("kk");

  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY) as SupportedLanguage | null;
      if (saved === "en" || saved === "kk") {
        setLanguageState(saved);
      } else {
        localStorage.setItem(STORAGE_KEY, "kk");
        setLanguageState("kk");
      }
    } catch {
      // Ignore localStorage errors
    }
  }, []);

  const setLanguage = useCallback((lang: SupportedLanguage) => {
    setLanguageState(lang);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
      document.documentElement.lang = lang;
    } catch {
      // Ignore localStorage errors
    }
  }, []);

  const toggleLanguage = useCallback(() => {
    setLanguage(language === "kk" ? "en" : "kk");
  }, [language, setLanguage]);

  const t = useCallback(
    (key: TranslationKey, fallback?: string): string => {
      const dict = translations[language] as Record<string, string>;
      if (dict && dict[key]) {
        return dict[key];
      }
      const fallbackDict = translations.en as Record<string, string>;
      return fallbackDict[key] || fallback || key;
    },
    [language],
  );

  return (
    <I18nContext.Provider value={{ language, setLanguage, toggleLanguage, t }}>
      {children}
    </I18nContext.Provider>
  );
}

export function useTranslation() {
  return useContext(I18nContext);
}

export function LanguageToggle({ className = "" }: { className?: string }) {
  const { language, toggleLanguage } = useTranslation();

  return (
    <button
      type="button"
      onClick={toggleLanguage}
      title={language === "kk" ? "Ағылшын тіліне ауыстыру (English)" : "Қазақ тіліне ауыстыру (Қазақша)"}
      aria-label="Тілді ауыстыру / Switch language"
      className={`inline-flex items-center gap-1.5 rounded-full border border-[#EDEEEF] bg-white px-3 py-1 font-syne text-xs font-semibold text-[#191919] shadow-sm transition-all hover:bg-[#F6F6F9] hover:border-[#D5CAFC] active:scale-95 ${className}`}
    >
      <Globe className="h-3.5 w-3.5 text-[#5146E5]" />
      <span>{language === "kk" ? "🇰🇿 ҚАЗ" : "🇬🇧 ENG"}</span>
    </button>
  );
}
