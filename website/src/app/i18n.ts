export type Language = 'fa' | 'en';

const messages = {
  en: {
    appName: 'Pixora',
    home: 'Home',
    image: 'Image',
    video: 'Video',
    developer: 'Developer',
    allTools: 'All tools',
    headline: 'Pixora. Your media toolkit.',
    imageConverter: 'Image converter',
    imageConverterDescription: 'Convert, resize, watermark.',
    videoConverter: 'Video converter',
    videoConverterDescription: 'Convert video, audio and GIF.',
    audioExtractor: 'Video to MP3',
    audioExtractorDescription: 'Extract the soundtrack as MP3.',
    backgroundRemover: 'Background remover',
    backgroundRemoverDescription: 'Transparent PNG, offline.',
    lorem: 'Lorem generator',
    loremDescription: 'Persian and English sample text.',
    backHome: 'Back to tools',
    language: 'Language',
    theme: 'Theme',
  },
  fa: {
    appName: 'پیکسورا',
    home: 'خانه',
    image: 'تصویر',
    video: 'ویدیو',
    developer: 'توسعه‌دهنده',
    allTools: 'همه ابزارها',
    headline: 'پیکسورا؛ جعبه‌ابزار تصویر و ویدیو.',
    imageConverter: 'مبدل تصویر',
    imageConverterDescription: 'تبدیل، تغییر اندازه و واترمارک.',
    videoConverter: 'مبدل ویدیو',
    videoConverterDescription: 'تبدیل ویدیو، صدا و GIF.',
    audioExtractor: 'ویدیو به MP3',
    audioExtractorDescription: 'استخراج صدای ویدیو با فرمت MP3.',
    backgroundRemover: 'حذف پس‌زمینه',
    backgroundRemoverDescription: 'PNG شفاف، کاملاً آفلاین.',
    lorem: 'لورم‌ساز',
    loremDescription: 'متن آزمایشی فارسی و انگلیسی.',
    backHome: 'بازگشت به ابزارها',
    language: 'زبان',
    theme: 'پوسته',
  },
} as const;

export type MessageKey = keyof (typeof messages)['en'];

export function translate(language: Language, key: MessageKey): string {
  return messages[language][key];
}
