import {
  BracketsCurly,
  FileAudio,
  FileImage,
  FileVideo,
  MagicWand,
  TextT,
} from '@phosphor-icons/react';
import type { MessageKey } from './i18n';

export type ToolId =
  | 'home'
  | 'image-converter'
  | 'video-converter'
  | 'audio-extractor'
  | 'background-remover'
  | 'lorem';

export const tools = [
  { id: 'image-converter' as const, icon: FileImage, group: 'image' },
  { id: 'video-converter' as const, icon: FileVideo, group: 'video' },
  { id: 'audio-extractor' as const, icon: FileAudio, group: 'video' },
  { id: 'background-remover' as const, icon: MagicWand, group: 'image' },
  { id: 'lorem' as const, icon: TextT, group: 'developer' },
];

export const toolText: Record<Exclude<ToolId, 'home'>, [MessageKey, MessageKey]> = {
  'image-converter': ['imageConverter', 'imageConverterDescription'],
  'video-converter': ['videoConverter', 'videoConverterDescription'],
  'audio-extractor': ['audioExtractor', 'audioExtractorDescription'],
  'background-remover': ['backgroundRemover', 'backgroundRemoverDescription'],
  lorem: ['lorem', 'loremDescription'],
};

export const groupIcons = {
  image: FileImage,
  video: FileVideo,
  developer: BracketsCurly,
};
