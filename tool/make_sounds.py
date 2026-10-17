"""Sintesis efek suara Jaringan Sibuk → assets/audio/*.wav.

    python tool/make_sounds.py

Hanya pustaka standar Python. Hasilnya deterministik (tanpa acak), WAV
16-bit mono 22,05 kHz. Nama berkas = `Cue.sound` di
lib/feedback/game_feedback.dart.
"""

import math
import os
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')


def note(freq, dur, *, amp=0.5, decay=6.0, wave_='sine', bend=0.0,
         vibrato=0.0, attack=0.004):
    """Satu nada: [freq] Hz selama [dur] detik, meluruh eksponensial.

    [bend] = perubahan frekuensi relatif sampai akhir nada (mis. -0.5 =
    turun ke separuh). [vibrato] = kedalaman relatif getaran 6 Hz.
    """
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq * (1 + bend * t / dur)
        f *= 1 + vibrato * math.sin(2 * math.pi * 6 * t)
        phase += 2 * math.pi * f / RATE
        if wave_ == 'sine':
            s = math.sin(phase)
        elif wave_ == 'bell':
            s = (math.sin(phase) + 0.35 * math.sin(2 * phase)
                 + 0.15 * math.sin(3 * phase)) / 1.5
        elif wave_ == 'soft-square':
            # Gelombang kotak yang dihaluskan (harmonik ganjil 1, 3, 5).
            s = (math.sin(phase) + math.sin(3 * phase) / 3
                 + math.sin(5 * phase) / 5) / 1.2
        else:
            raise ValueError(wave_)
        env = math.exp(-decay * t)
        env *= min(1.0, t / attack) if attack else 1.0
        # Ekor 8 ms dipudarkan supaya tidak berbunyi klik.
        env *= min(1.0, (n - i) / (RATE * 0.008))
        out.append(amp * env * s)
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def seq(*parts):
    return [s for part in parts for s in part]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    frames = b''.join(
        struct.pack('<h', int(max(-1, min(1, s * scale)) * 32767))
        for s in samples)
    path = os.path.join(OUT, f'{name}.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f'{path}: {len(samples) / RATE:.2f} s')


C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0

SOUNDS = {
    # Ketukan tombol: "pop" pendek yang sedikit turun.
    'tap': note(740, 0.05, amp=0.35, decay=60, bend=-0.3),
    # Kabel terpasang: dua nada naik "plin-plun".
    'connect': seq(
        note(C6, 0.07, amp=0.45, decay=25, wave_='bell'),
        note(G6, 0.16, amp=0.45, decay=18, wave_='bell'),
    ),
    # Anggaran kurang: dua nada rendah turun, sedikit kasar.
    'refuse': seq(
        note(330, 0.11, amp=0.35, decay=10, wave_='soft-square'),
        silence(0.02),
        note(262, 0.16, amp=0.35, decay=10, wave_='soft-square'),
    ),
    # Kabel dibongkar: sapuan turun "fwip".
    'remove': note(900, 0.14, amp=0.4, decay=14, bend=-0.6),
    # Komplain: notifikasi "ding-dong".
    'complaint': seq(
        note(E6, 0.16, amp=0.45, decay=9, wave_='bell'),
        note(C6, 0.34, amp=0.45, decay=7, wave_='bell'),
    ),
    # Hari lulus: arpeggio naik, nada akhir panjang.
    'win': seq(
        note(C5, 0.09, amp=0.4, decay=8, wave_='bell'),
        note(E5, 0.09, amp=0.4, decay=8, wave_='bell'),
        note(G5, 0.09, amp=0.4, decay=8, wave_='bell'),
        mix(
            note(C6, 0.55, amp=0.4, decay=4, wave_='bell'),
            note(E6, 0.55, amp=0.2, decay=5, wave_='bell'),
        ),
    ),
    # Hari gagal: "wah-wah" turun, nada akhir bergetar.
    'fail': seq(
        note(392, 0.18, amp=0.35, decay=4, wave_='soft-square'),
        note(370, 0.18, amp=0.35, decay=4, wave_='soft-square'),
        note(349, 0.18, amp=0.35, decay=4, wave_='soft-square'),
        note(330, 0.55, amp=0.35, decay=3, wave_='soft-square',
             vibrato=0.02),
    ),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, samples in SOUNDS.items():
        write(name, samples)
