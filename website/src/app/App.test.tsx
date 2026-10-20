import { fireEvent, render, screen, within } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from './App';

describe('Pixora workspace navigation', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.removeAttribute('dir');
    document.documentElement.removeAttribute('lang');
  });

  afterEach(() => {
    Reflect.deleteProperty(window, 'chrome');
  });

  it('opens every shipped tool without placeholder destinations', () => {
    render(<App />);
    expect(screen.queryByText('Image to SVG')).not.toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Choose what to work on' })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'About Pixora' })).toBeInTheDocument();
    expect(screen.getByText('1.0.0')).toBeInTheDocument();
    expect(screen.getByText('GitHub project')).toBeInTheDocument();
    expect(screen.getByText('Telegram channel')).toBeInTheDocument();
    expect(screen.getByText('Support')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Open image tools' }));
    expect(screen.getByRole('heading', { name: 'Image converter' })).toBeInTheDocument();
    fireEvent.click(screen.getAllByRole('button', { name: 'Home' })[0]);

    fireEvent.click(within(screen.getByRole('main')).getByRole('button', { name: 'Video converter' }));
    expect(screen.getByRole('heading', { name: 'Video converter' })).toBeInTheDocument();
    expect(screen.getByTestId('video-input')).toBeInTheDocument();
    expect(screen.getByTestId('video-format-mp4')).toBeInTheDocument();

    fireEvent.click(within(screen.getByRole('navigation', { name: 'All tools' })).getByRole('button', { name: 'Video to MP3' }));
    expect(screen.getByRole('heading', { name: 'Video to MP3' })).toBeInTheDocument();
    expect(screen.getByTestId('video-input')).toBeInTheDocument();
    expect(screen.queryByTestId('video-format-mp4')).not.toBeInTheDocument();
    expect(screen.queryByText('Video watermark')).not.toBeInTheDocument();

    fireEvent.click(within(screen.getByRole('navigation', { name: 'All tools' })).getByRole('button', { name: 'Background remover' }));
    expect(screen.getByRole('heading', { name: 'Background remover' })).toBeInTheDocument();
    expect(screen.getByTestId('background-input')).toBeInTheDocument();

    fireEvent.click(within(screen.getByRole('navigation', { name: 'All tools' })).getByRole('button', { name: 'Lorem generator' }));
    expect(screen.getByRole('heading', { name: 'Lorem generator' })).toBeInTheDocument();
  });

  it('switches the entire document to Persian RTL and persists it', () => {
    render(<App />);
    fireEvent.click(screen.getAllByLabelText('Language')[0]);

    expect(document.documentElement.lang).toBe('fa');
    expect(document.documentElement.dir).toBe('rtl');
    expect(localStorage.getItem('pixora-language')).toBe('fa');
    expect(screen.getByText('پیکسورا؛ جعبه‌ابزار تصویر و ویدیو.')).toBeInTheDocument();
  });

  it('uses percentage resize and practical quality defaults', () => {
    render(<App />);
    fireEvent.click(within(screen.getByRole('main')).getByRole('button', { name: 'Image converter' }));

    expect(screen.getByTestId('image-scale-percent')).toHaveValue(100);
    expect(screen.getByRole('checkbox', { name: 'Set exact pixel dimensions' })).not.toBeChecked();
    expect(screen.getByRole('slider', { name: 'Quality' })).toHaveValue('80');
    expect(screen.getByTestId('download-all-images')).toBeDisabled();
  });

  it('starts lorem in Persian and updates output immediately', () => {
    render(<App />);
    fireEvent.click(within(screen.getByRole('main')).getByRole('button', { name: 'Lorem generator' }));
    const output = screen.getByRole('textbox', { name: 'Generated text' });
    const initialText = (output as HTMLTextAreaElement).value;

    expect(output).toHaveAttribute('dir', 'rtl');
    expect(initialText).toMatch(/[\u0600-\u06ff]/);
    expect(screen.queryByRole('button', { name: 'Generate text' })).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Words' }));
    expect((output as HTMLTextAreaElement).value).not.toBe(initialText);
  });

  it('starts dark, syncs the title bar, and preserves a selected light theme', () => {
    const postMessage = vi.fn();
    Object.defineProperty(window, 'chrome', {
      configurable: true,
      value: { webview: { postMessage } },
    });

    render(<App />);
    expect(postMessage).toHaveBeenCalledWith({ source: 'pixora', type: 'theme', value: 'dark' });
    expect(document.documentElement.dataset.theme).toBe('dark');
    fireEvent.click(screen.getAllByRole('button', { name: 'Theme' })[0]);
    expect(postMessage).toHaveBeenCalledWith({ source: 'pixora', type: 'theme', value: 'light' });
    expect(document.documentElement.dataset.theme).toBe('light');
    expect(localStorage.getItem('pixora-theme')).toBe('light');
  });

  it('restores a previously selected light theme', () => {
    localStorage.setItem('pixora-theme', 'light');
    render(<App />);
    expect(document.documentElement.dataset.theme).toBe('light');
    expect(localStorage.getItem('pixora-theme')).toBe('light');
  });
});
