import { CheckCircle, FileAudio, FileVideo, FileZip, Stop, Trash, UploadSimple, WarningCircle } from '@phosphor-icons/react';
import { useEffect, useRef, useState } from 'react';

import { createZip } from '../../app/archive';
import { useDownloadCenter } from '../../app/download-center';
import type { Language } from '../../app/i18n';
import { formatFileSize, savingPercent } from '../image/image-types';
import { NativeVideoUnavailableError, VideoEngineMemoryError, videoConversionService, videoOutputName } from './ffmpeg-service';
import { maxVideoWidth, parseTrimRange, parseVideoWidth, videoOutputFormats, type VideoJob, type VideoOutputFormat } from './video-types';

const copy = {
  en: {
    title: 'Video converter', drop: 'Drop media files here',
    audioTitle: 'Video to MP3', audioDrop: 'Drop video files here', audioSupport: 'The soundtrack is saved as MP3',
    browse: 'Choose files', support: 'Video, audio and GIF files', empty: 'No files yet', output: 'Output format', quality: 'Quality',
    maxWidth: 'Maximum width', original: 'Leave empty to keep the original width', audio: 'Keep audio', metadata: 'Remove metadata',
    convert: 'Convert files', downloadAll: 'Download all', preparingZip: 'Preparing ZIP', clear: 'Clear', cancel: 'Cancel', queued: 'Ready', loading: 'Loading engine',
    processing: 'Converting', done: 'Complete', error: 'Failed', cancelled: 'Cancelled', download: 'Download', smaller: 'smaller', larger: 'larger',
    noFiles: 'Add at least one media file to continue.', files: 'files', audioUnavailable: 'Audio is extracted for this format.',
    trim: 'Trim (seconds)', start: 'Start', end: 'End', trimHint: 'Leave empty to use the full duration.', watermark: 'Video watermark', chooseWatermark: 'Choose logo', removeWatermark: 'Remove', watermarkScale: 'Watermark size', watermarkOpacity: 'Opacity', position: 'Position', northwest: 'Top left', northeast: 'Top right', center: 'Center', southwest: 'Bottom left', southeast: 'Bottom right', invalidTrim: 'Enter a valid range; end time must be greater than start time.', invalidWidth: `Maximum width must be an even whole number from 2 to ${maxVideoWidth}.`, memoryError: 'Not enough memory for this video. Try a shorter clip or smaller width.',
  },
  fa: {
    title: 'مبدل ویدیو', drop: 'فایل‌های رسانه را اینجا رها کنید',
    audioTitle: 'ویدیو به MP3', audioDrop: 'فایل‌های ویدیو را اینجا رها کنید', audioSupport: 'صدای ویدیو با فرمت MP3 ذخیره می‌شود',
    browse: 'انتخاب فایل', support: 'ویدیو، صدا و GIF', empty: 'هنوز فایلی اضافه نشده', output: 'فرمت خروجی', quality: 'کیفیت',
    maxWidth: 'حداکثر عرض', original: 'برای حفظ عرض اصلی خالی بگذارید', audio: 'نگه‌داشتن صدا', metadata: 'حذف متادیتا',
    convert: 'تبدیل فایل‌ها', downloadAll: 'دانلود همه', preparingZip: 'در حال ساخت ZIP', clear: 'پاک کردن', cancel: 'لغو', queued: 'آماده', loading: 'بارگذاری موتور',
    processing: 'در حال تبدیل', done: 'تکمیل شد', error: 'ناموفق', cancelled: 'لغو شد', download: 'دانلود', smaller: 'کوچک‌تر', larger: 'بزرگ‌تر',
    noFiles: 'برای ادامه حداقل یک فایل رسانه اضافه کنید.', files: 'فایل', audioUnavailable: 'در این فرمت فقط صدا استخراج می‌شود.',
    trim: 'برش زمانی (ثانیه)', start: 'شروع', end: 'پایان', trimHint: 'برای استفاده از کل زمان، خالی بگذارید.', watermark: 'واترمارک ویدیو', chooseWatermark: 'انتخاب لوگو', removeWatermark: 'حذف', watermarkScale: 'اندازه واترمارک', watermarkOpacity: 'شفافیت', position: 'موقعیت', northwest: 'بالا چپ', northeast: 'بالا راست', center: 'مرکز', southwest: 'پایین چپ', southeast: 'پایین راست', invalidTrim: 'یک بازه معتبر وارد کنید؛ زمان پایان باید از شروع بیشتر باشد.', invalidWidth: `حداکثر عرض باید عدد صحیح زوج بین ۲ تا ${maxVideoWidth} باشد.`, memoryError: 'حافظه برای این ویدیو کافی نیست. ویدیوی کوتاه‌تر یا عرض کوچک‌تر را امتحان کنید.',
  },
} as const;

export function VideoConverterPage({ uiLanguage, mode = 'video' }: { uiLanguage: Language; mode?: 'video' | 'audio' }) {
  const t = copy[uiLanguage];
  const audioMode = mode === 'audio';
  const { downloadFile } = useDownloadCenter();
  const inputRef = useRef<HTMLInputElement>(null);
  const watermarkRef = useRef<HTMLInputElement>(null);
  const runId = useRef(0);
  const [jobs, setJobs] = useState<VideoJob[]>([]);
  const [format, setFormat] = useState<VideoOutputFormat>(audioMode ? 'mp3' : 'mp4');
  const [quality, setQuality] = useState(70);
  const [maxWidth, setMaxWidth] = useState('');
  const [keepAudio, setKeepAudio] = useState(true);
  const [stripMetadata, setStripMetadata] = useState(true);
  const [trimStart, setTrimStart] = useState('');
  const [trimEnd, setTrimEnd] = useState('');
  const [watermark, setWatermark] = useState<File>();
  const [watermarkScale, setWatermarkScale] = useState(20);
  const [watermarkOpacity, setWatermarkOpacity] = useState(75);
  const [watermarkPosition, setWatermarkPosition] = useState<'northwest' | 'northeast' | 'center' | 'southwest' | 'southeast'>('southeast');
  const [dragging, setDragging] = useState(false);
  const [formError, setFormError] = useState('');
  const [zipping, setZipping] = useState(false);
  const busy = jobs.some((job) => job.status === 'loading' || job.status === 'processing');
  const audioOnly = format === 'mp3' || format === 'wav';

  useEffect(() => () => {
    runId.current += 1;
    videoConversionService.cancel();
  }, []);

  const addFiles = (files: FileList | File[]) => {
    const additions = Array.from(files).map<VideoJob>((file) => ({ id: `${file.name}-${file.size}-${file.lastModified}`, file, status: 'queued', progress: 0 }));
    setJobs((current) => [...current, ...additions.filter((item) => !current.some((job) => job.id === item.id))]);
    setFormError('');
  };

  const convert = async () => {
    if (!jobs.length) { setFormError(t.noFiles); return; }
    const trim = parseTrimRange(trimStart, trimEnd);
    if (!trim) { setFormError(t.invalidTrim); return; }
    const parsedWidth = audioOnly ? undefined : parseVideoWidth(maxWidth);
    if (parsedWidth === null) { setFormError(t.invalidWidth); return; }
    setFormError('');
    const run = ++runId.current;
    for (const job of jobs) {
      if (run !== runId.current) break;
      setJobs((current) => current.map((item) => item.id === job.id ? { ...item, status: 'loading', progress: 0, error: undefined } : item));
      try {
        const output = await videoConversionService.convert(job.file, {
          outputFormat: format, quality,
          maxWidth: parsedWidth,
          keepAudio: !audioOnly && keepAudio,
          stripMetadata,
          trimStart: trim.start,
          trimEnd: trim.end,
          watermark: !audioOnly && watermark ? { scalePercent: watermarkScale, opacity: watermarkOpacity, position: watermarkPosition } : undefined,
        }, (progress) => setJobs((current) => current.map((item) => item.id === job.id ? { ...item, status: 'processing', progress } : item)), !audioOnly ? watermark : undefined);
        if (run !== runId.current) return;
        setJobs((current) => current.map((item) => item.id === job.id ? { ...item, status: 'done', progress: 1, output } : item));
        downloadFile({ name: videoOutputName(job.file.name, output.outputFormat), blob: new Blob([output.bytes as BlobPart], { type: output.mimeType }) });
      } catch (error) {
        if (run !== runId.current) return;
        const message = error instanceof VideoEngineMemoryError ? t.memoryError
          : error instanceof NativeVideoUnavailableError
            ? uiLanguage === 'fa'
              ? 'موتور ویدیوی بومی پیدا نشد. فایل ffmpeg را کنار برنامه قرار دهید یا آن را به PATH اضافه کنید.'
              : error.message
            : error instanceof Error ? error.message : String(error);
        setJobs((current) => current.map((item) => item.id === job.id ? { ...item, status: 'error', error: message } : item));
      }
    }
  };

  const cancel = () => {
    runId.current += 1;
    videoConversionService.cancel();
    setJobs((current) => current.map((item) => item.status === 'loading' || item.status === 'processing' ? { ...item, status: 'cancelled', progress: 0 } : item));
  };

  const downloadAll = async () => {
    const completed = jobs.filter((job) => job.output);
    if (!completed.length) return;
    setZipping(true);
    try {
      const blob = await createZip(completed.map((job) => ({ name: videoOutputName(job.file.name, job.output!.outputFormat), bytes: job.output!.bytes })));
      downloadFile({ name: audioMode ? 'pixora-audio.zip' : 'pixora-videos.zip', blob });
    } catch (error) {
      setFormError(error instanceof Error ? error.message : String(error));
    } finally {
      setZipping(false);
    }
  };

  return <main className="tool-page">
    <header className="tool-heading"><h1>{audioMode ? t.audioTitle : t.title}</h1></header>
    <input ref={inputRef} data-testid="video-input" className="visually-hidden" type="file" accept="video/*,audio/*,.gif,.mkv,.flv,.m4v,.mts,.m2ts" multiple onChange={(event) => { if (event.target.files) addFiles(event.target.files); event.target.value = ''; }} />
    <input ref={watermarkRef} className="visually-hidden" type="file" accept="image/png,image/webp,image/jpeg" onChange={(event) => setWatermark(event.target.files?.[0])} />
    <section className={dragging ? 'drop-zone dragging' : 'drop-zone'} onDragOver={(event) => { event.preventDefault(); setDragging(true); }} onDragLeave={() => setDragging(false)} onDrop={(event) => { event.preventDefault(); setDragging(false); addFiles(event.dataTransfer.files); }}>
      <span className="drop-icon"><UploadSimple size={28} weight="duotone" /></span><div><strong>{audioMode ? t.audioDrop : t.drop}</strong><small>{audioMode ? t.audioSupport : t.support}</small></div><button type="button" onClick={() => inputRef.current?.click()}>{t.browse}</button>
    </section>
    <div className="converter-layout">
      <section className="queue-panel">
        <div className="queue-toolbar"><strong>{jobs.length} {t.files}</strong><div><button type="button" data-testid="download-all-videos" disabled={busy || zipping || !jobs.some((job) => job.output)} onClick={downloadAll}><FileZip size={17} />{zipping ? t.preparingZip : t.downloadAll}</button><button type="button" disabled={busy || !jobs.length} onClick={() => setJobs([])}><Trash size={17} />{t.clear}</button></div></div>
        <div className="queue-list">{jobs.length === 0 ? <div className="queue-empty">{audioMode ? <FileAudio size={34} /> : <FileVideo size={34} />}<span>{t.empty}</span></div> : jobs.map((job) => <article className="queue-item" data-testid="video-job" data-status={job.status} key={job.id}>
          <span className={`job-state ${job.status}`}>{job.status === 'done' ? <CheckCircle size={19} /> : job.status === 'error' ? <WarningCircle size={19} /> : <FileVideo size={19} />}</span>
          <div><strong title={job.file.name}>{job.file.name}</strong><small>{job.file.type || 'media'} / {formatFileSize(job.file.size)}{job.output ? ` → ${formatFileSize(job.output.bytes.byteLength)}` : ''}{job.output?.limitedToWidth ? ` · ≤${job.output.limitedToWidth}px` : ''}</small>{job.error && <em>{job.error}</em>}{(job.status === 'loading' || job.status === 'processing') && <span className="job-progress"><i style={{ width: `${Math.max(4, Math.round(job.progress * 100))}%` }} /></span>}</div>
          <span className="job-result">{job.status === 'processing' ? `${Math.round(job.progress * 100)}%` : job.status === 'done' && job.output ? `${Math.abs(savingPercent(job.file.size, job.output.bytes.byteLength))}% ${savingPercent(job.file.size, job.output.bytes.byteLength) >= 0 ? t.smaller : t.larger}` : t[job.status]}</span>
        </article>)}</div>
      </section>
      <aside className="image-settings">
        {!audioMode && <fieldset className="format-field"><legend>{t.output}</legend><div>{videoOutputFormats.map((item) => <button type="button" data-testid={`video-format-${item}`} className={format === item ? 'active' : ''} key={item} onClick={() => setFormat(item)}>{item.toUpperCase()}</button>)}</div></fieldset>}
        {format !== 'wav' && <fieldset className="range-field quality-field"><legend><span>{t.quality}</span><b>{quality}%</b></legend><input aria-label={t.quality} type="range" min="20" max="100" value={quality} onChange={(event) => setQuality(Number(event.target.value))} /></fieldset>}
        {!audioOnly && <label className="dimension-field single-field"><span>{t.maxWidth}</span><input inputMode="numeric" type="number" min="2" max={maxVideoWidth} step="2" placeholder="px" value={maxWidth} onChange={(event) => setMaxWidth(event.target.value)} /><small>{t.original}</small></label>}
        <fieldset className="dimension-field"><legend>{t.trim}</legend><div><label>{t.start}<input inputMode="decimal" type="number" min="0" step="0.1" placeholder="0" value={trimStart} onChange={(event) => setTrimStart(event.target.value)} /></label><label>{t.end}<input inputMode="decimal" type="number" min="0" step="0.1" placeholder="—" value={trimEnd} onChange={(event) => setTrimEnd(event.target.value)} /></label></div><small>{t.trimHint}</small></fieldset>
        {!audioOnly ? <label className="check-field"><input type="checkbox" checked={keepAudio} onChange={(event) => setKeepAudio(event.target.checked)} /><span>{t.audio}</span></label> : <small className="setting-note">{t.audioUnavailable}</small>}
        <label className="check-field"><input type="checkbox" checked={stripMetadata} onChange={(event) => setStripMetadata(event.target.checked)} /><span>{t.metadata}</span></label>
        {!audioOnly && <fieldset className="watermark-field"><legend>{t.watermark}</legend><div className="watermark-picker"><button type="button" onClick={() => watermarkRef.current?.click()}>{t.chooseWatermark}</button>{watermark && <button type="button" onClick={() => setWatermark(undefined)}>{t.removeWatermark}</button>}</div>{watermark && <><small title={watermark.name}>{watermark.name}</small><label className="range-field"><span>{t.watermarkScale}<b>{watermarkScale}%</b></span><input type="range" min="5" max="60" value={watermarkScale} onChange={(event) => setWatermarkScale(Number(event.target.value))} /></label><label className="range-field"><span>{t.watermarkOpacity}<b>{watermarkOpacity}%</b></span><input type="range" min="10" max="100" value={watermarkOpacity} onChange={(event) => setWatermarkOpacity(Number(event.target.value))} /></label><label className="select-field">{t.position}<select value={watermarkPosition} onChange={(event) => setWatermarkPosition(event.target.value as typeof watermarkPosition)}>{(['northwest', 'northeast', 'center', 'southwest', 'southeast'] as const).map((position) => <option value={position} key={position}>{t[position]}</option>)}</select></label></>}</fieldset>}
        {formError && <p className="form-error" role="alert"><WarningCircle size={17} />{formError}</p>}
        {busy ? <button className="secondary-danger-button" type="button" onClick={cancel}><Stop size={17} weight="fill" />{t.cancel}</button> : <button className="primary-button" data-testid="convert-videos" type="button" onClick={convert}>{t.convert}</button>}
      </aside>
    </div>
  </main>;
}
