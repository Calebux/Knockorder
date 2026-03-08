// ── Sound Manager ─────────────────────────────────────────────────────────────
// Plays named game sounds and controls mute state globally.

export type SoundName =
    | "intro"
    | "clash"
    | "click"
    | "gameOver"
    | "roundEnd";

const SOUND_PATHS: Record<SoundName, string> = {
    intro: "/Sounds/intro sound.mp3",
    clash: "/Sounds/slot clash sound.mp3",
    click: "/Sounds/menu clicks.mp3",
    gameOver: "/Sounds/Game over sound.mp3",
    roundEnd: "/Sounds/game end sound.mp3",
};

// Pool of Audio elements so we can overlap the same sound
const pool: Partial<Record<SoundName, HTMLAudioElement>> = {};

let _muted = false;
let _bgAudio: HTMLAudioElement | null = null;

export function isMuted() { return _muted; }

export function setMuted(muted: boolean) {
    _muted = muted;
    if (_bgAudio) _bgAudio.muted = muted;
}

export function playSound(name: SoundName) {
    if (_muted) return;
    try {
        let audio = pool[name];
        if (!audio) {
            audio = new Audio(SOUND_PATHS[name]);
            pool[name] = audio;
        }
        // Clone so we can overlap
        const clone = audio.cloneNode() as HTMLAudioElement;
        clone.volume = name === "clash" ? 0.7 : 0.5;
        clone.play().catch(() => {/* autoplay policy – silently ignore */ });
    } catch (_) { }
}

// Background music (looping)
export function startBgMusic() {
    if (_bgAudio) return; // already started
    try {
        _bgAudio = new Audio("/Sounds/intro sound.mp3");
        _bgAudio.loop = true;
        _bgAudio.volume = 0.3;
        _bgAudio.muted = _muted;
        _bgAudio.play().catch(() => { });
    } catch (_) { }
}

export function stopBgMusic() {
    if (_bgAudio) {
        _bgAudio.pause();
        _bgAudio.currentTime = 0;
        _bgAudio = null;
    }
}
