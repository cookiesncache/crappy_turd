// This is a standalone build-time console script (not app code shipped to
// players), so printing progress straight to stdout is the intended UX.
// ignore_for_file: avoid_print
/// One-off build tool that procedurally synthesizes Crappy Turd's three
/// sound effects (a comedic fart on flap, a cheerful "ding" on score, and a
/// light "womp" on death) as hand-built 16-bit PCM mono WAV files -- no
/// audio-encoding package, no downloaded/recorded audio, zero licensing
/// risk. Every byte of every file (RIFF header, fmt chunk, data chunk) is
/// assembled directly by this script.
///
/// This is NOT part of the Flutter app -- it's a codegen-style build tool,
/// run once (and re-run by hand whenever the feel-tunable constants below
/// change) to regenerate the committed binary assets under `assets/audio/`.
/// Run it with:
///   dart run tool/generate_audio.dart
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Sample rate (Hz) shared by all three generated WAV files.
const int sampleRate = 22050;

/// Fixed seed for the noise component, so regenerating the assets from
/// scratch always produces byte-identical output.
const int noiseSeed = 20260719;

// ---------------------------------------------------------------------
// Feel-tunable synthesis constants. Retune the sound of any effect by
// editing the numbers in its block below, then re-run this script to
// regenerate the corresponding WAV file(s). Nothing here is a gameplay
// constant -- see lib/game/constants.dart for those.
// ---------------------------------------------------------------------

// --- flap.wav: sawtooth "wet buzz" fart, ~0.35s ---
// Rebuilt after feedback that the original (a symmetric sine-wobble
// vibrato around a fixed pitch) read as "space"/sci-fi rather than a
// fart: that oscillating up-down wobble on an otherwise clean sawtooth is
// exactly the classic synth-lead "UFO"/laser-charge patch. Swapped for a
// genuinely RISING pitch sweep (the classic cartoon-raspberry contour),
// with a much larger noise component to break up the clean tone into
// something grittier/more organic, plus a fast amplitude flutter to
// suggest buzzing lips rather than a steady electronic tone.
const double flapDuration = 0.25;
const double flapStartFreq = 200;
const double flapEndFreq = 400;
const double flapWobbleDepth = 10;
const double flapWobbleRate = 18;
const double flapNoiseMix = 0.4;
const double flapTremoloRate = 30;
const double flapTremoloDepth = 0.3;
const double flapAttackTime = 0.01;
const double flapDecayRate = 12;
const int flapPeakAmplitude = 21000;

// --- score.wav: two square-wave "ding-ding" notes, ~0.15s total ---
const double scoreNoteDuration = 0.075;
const double scoreNote1Freq = 660;
const double scoreNote2Freq = 880;
const double scoreAttackTime = 0.005;
const double scoreDecayRate = 40;
const int scorePeakAmplitude = 16384;

// --- death.wav: triangle-wave downward sweep "womp", ~0.4s ---
const double deathDuration = 0.4;
const double deathStartFreq = 300;
const double deathEndFreq = 80;
const double deathAttackTime = 0.005;
const double deathDecayRate = 3;
const int deathPeakAmplitude = 18022;

void main() {
  final random = math.Random(noiseSeed);

  final dir = Directory('assets/audio');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  _writeWav('assets/audio/flap.wav', _synthFlap(random));
  _writeWav('assets/audio/score.wav', _synthScore());
  _writeWav('assets/audio/death.wav', _synthDeath());

  print(
    'Wrote assets/audio/flap.wav, assets/audio/score.wav, '
    'assets/audio/death.wav',
  );
}

/// A sawtooth wave whose INSTANTANEOUS frequency RISES from [flapStartFreq]
/// to [flapEndFreq] over the sound's duration (the classic cartoon-
/// raspberry contour), with a small, fast wobble layered on top for
/// texture, mixed with a substantial amount of white noise to keep it
/// grainy/organic rather than a clean electronic tone, and a fast
/// amplitude flutter (tremolo) suggesting buzzing lips -- all under a
/// fast-attack/exponential-decay envelope.
///
/// The rise (`flapStartFreq + (flapEndFreq-flapStartFreq)*progress`) and
/// the wobble LFO (`sin(2*pi*flapWobbleRate*t)`) are both smooth,
/// continuous functions of wall-clock time `t`, so they can be evaluated
/// directly each sample with no accumulation needed on their own. The
/// sawtooth CARRIER can't be evaluated that way, though: a sawtooth is
/// built by wrapping a phase value, and if the frequency feeding it
/// changes from sample to sample, naively recomputing `freq(t) * t` each
/// sample would make the phase jump discontinuously whenever `freq`
/// changes -- an audible click every sample. Instead the carrier phase is
/// integrated: each sample advances phase by `freq(t) / sampleRate` (i.e.
/// `freq(t) * dt`), accumulating smoothly frame-to-frame no matter how
/// `freq` rises or wobbles.
Int16List _synthFlap(math.Random random) {
  final sampleCount = (flapDuration * sampleRate).round();
  final samples = Float64List(sampleCount);
  var phase = 0.0;

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = t / flapDuration;
    final risingFreq = flapStartFreq + (flapEndFreq - flapStartFreq) * progress;
    final instantFreq =
        risingFreq +
        flapWobbleDepth * math.sin(2 * math.pi * flapWobbleRate * t);
    phase += instantFreq / sampleRate;
    phase -= phase.floorToDouble();

    final saw = 2 * phase - 1;
    final noise = random.nextDouble() * 2 - 1;
    final wave = (1 - flapNoiseMix) * saw + flapNoiseMix * noise;

    // Ranges within [1 - flapTremoloDepth, 1.0] -- always positive, so
    // this only ever attenuates (never inverts/boosts) the signal.
    final tremolo =
        1 -
        flapTremoloDepth *
            (0.5 + 0.5 * math.sin(2 * math.pi * flapTremoloRate * t));

    final envelope = _attackDecayEnvelope(
      t: t,
      attackTime: flapAttackTime,
      decayRate: flapDecayRate,
    );

    samples[i] = envelope * tremolo * wave;
  }

  _applyReleaseFade(samples);
  return _toInt16(samples, flapPeakAmplitude);
}

/// Two short square-wave notes back to back -- a cheerful ascending
/// "ding-ding" -- each with its own quick percussive attack/decay envelope.
///
/// A square wave's frequency is constant within each note, so unlike
/// [_synthFlap] no continuous phase integration across a changing
/// frequency is needed here; each note simply gets its own fresh phase
/// starting at 0.
Int16List _synthScore() {
  final note1 = _squareNote(scoreNote1Freq);
  final note2 = _squareNote(scoreNote2Freq);
  final combined = Float64List(note1.length + note2.length)
    ..setAll(0, note1)
    ..setAll(note1.length, note2);
  return _toInt16(combined, scorePeakAmplitude);
}

/// A single percussive square-wave note at [freq], [scoreNoteDuration]
/// seconds long, returned as raw (unscaled, roughly -1..1) samples.
Float64List _squareNote(double freq) {
  final sampleCount = (scoreNoteDuration * sampleRate).round();
  final samples = Float64List(sampleCount);
  var phase = 0.0;

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    phase += freq / sampleRate;
    phase -= phase.floorToDouble();

    final square = phase < 0.5 ? 1.0 : -1.0;
    final envelope = _attackDecayEnvelope(
      t: t,
      attackTime: scoreAttackTime,
      decayRate: scoreDecayRate,
    );

    samples[i] = envelope * square;
  }

  // Applied per-note (not just once on the combined buffer) so the seam
  // between note1 and note2 is also click-free, not just the very end.
  _applyReleaseFade(samples);
  return samples;
}

/// A single triangle-wave tone sweeping from [deathStartFreq] down to
/// [deathEndFreq] over [deathDuration], under a moderate decay envelope --
/// a light, comedic "womp" rather than anything somber.
///
/// As with [_synthFlap], the sweeping frequency is integrated into a
/// continuously-accumulating phase (rather than evaluated as `freq(t) * t`)
/// so the waveform stays click-free as the pitch slides down.
Int16List _synthDeath() {
  final sampleCount = (deathDuration * sampleRate).round();
  final samples = Float64List(sampleCount);
  var phase = 0.0;

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = t / deathDuration;
    final instantFreq =
        deathStartFreq + (deathEndFreq - deathStartFreq) * progress;
    phase += instantFreq / sampleRate;
    phase -= phase.floorToDouble();

    final triangle = phase < 0.5 ? (4 * phase - 1) : (3 - 4 * phase);
    final envelope = _attackDecayEnvelope(
      t: t,
      attackTime: deathAttackTime,
      decayRate: deathDecayRate,
    );

    samples[i] = envelope * triangle;
  }

  _applyReleaseFade(samples);
  return _toInt16(samples, deathPeakAmplitude);
}

/// Forces the final [fadeSeconds] of [samples] down to exactly silence via
/// a linear multiplicative fade, regardless of where each sound's own
/// exponential decay envelope happened to land by the end of the buffer.
/// A decay envelope alone doesn't guarantee it has reached zero by a fixed
/// buffer length -- e.g. `death`'s decayRate=3 over its 0.4s duration is
/// still at ~31% of peak amplitude at the very last sample without this --
/// and truncating a waveform abruptly mid-cycle is an audible click/pop.
/// Mutates [samples] in place.
void _applyReleaseFade(Float64List samples, {double fadeSeconds = 0.005}) {
  final fadeSampleCount = math.min(
    (fadeSeconds * sampleRate).round(),
    samples.length,
  );
  final start = samples.length - fadeSampleCount;
  for (var i = 0; i < fadeSampleCount; i++) {
    final ramp = 1 - (i + 1) / fadeSampleCount;
    samples[start + i] *= ramp;
  }
}

/// A fast linear attack up to peak (0..[attackTime]s), followed by an
/// exponential decay for the remainder of the sound -- shared shape across
/// all three effects, just with different [attackTime]/[decayRate] knobs.
/// Continuous at the attack/decay boundary (both sides equal 1 there), so
/// there's no seam/click where the two halves meet.
double _attackDecayEnvelope({
  required double t,
  required double attackTime,
  required double decayRate,
}) {
  if (t < attackTime) {
    return t / attackTime;
  }
  return math.exp(-decayRate * (t - attackTime));
}

/// Scales raw (roughly -1..1) [samples] by [peakAmplitude] and rounds/clamps
/// each into the 16-bit signed PCM range.
Int16List _toInt16(Float64List samples, int peakAmplitude) {
  final out = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final scaled = (samples[i] * peakAmplitude).round();
    out[i] = scaled.clamp(-32768, 32767);
  }
  return out;
}

/// Wraps [samples] (mono, 16-bit PCM) in a standard 44-byte RIFF/WAVE
/// header and writes the result to [path].
void _writeWav(String path, Int16List samples) {
  const channels = 1;
  const bitsPerSample = 16;
  const byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  const blockAlign = channels * bitsPerSample ~/ 8;
  final dataSize = samples.length * 2;

  final bytes = ByteData(44 + dataSize);
  var offset = 0;

  void writeString(String s) {
    for (final char in s.codeUnits) {
      bytes.setUint8(offset, char);
      offset++;
    }
  }

  void writeUint32(int value) {
    bytes.setUint32(offset, value, Endian.little);
    offset += 4;
  }

  void writeUint16(int value) {
    bytes.setUint16(offset, value, Endian.little);
    offset += 2;
  }

  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');

  writeString('fmt ');
  writeUint32(16); // fmt chunk size
  writeUint16(1); // audio format: 1 = PCM
  writeUint16(channels);
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(blockAlign);
  writeUint16(bitsPerSample);

  writeString('data');
  writeUint32(dataSize);
  for (final sample in samples) {
    bytes.setInt16(offset, sample, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}
