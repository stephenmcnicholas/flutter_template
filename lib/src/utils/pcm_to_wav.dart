import 'dart:typed_data';

/// Wraps raw PCM s16le mono samples in a WAV container (44-byte header).
/// [sampleRate] defaults to 24 kHz per Gemini TTS speech-generation docs.
Uint8List pcm16leMonoToWav(Uint8List pcm, {int sampleRate = 24000}) {
  final dataSize = pcm.length;
  final fileSizeMinus8 = 36 + dataSize;
  final out = ByteData(44 + dataSize);
  var o = 0;
  void writeAscii4(String s) {
    for (var i = 0; i < 4; i++) {
      out.setUint8(o + i, s.codeUnitAt(i));
    }
    o += 4;
  }

  void u32(int v) {
    out.setUint32(o, v, Endian.little);
    o += 4;
  }

  void u16(int v) {
    out.setUint16(o, v, Endian.little);
    o += 2;
  }

  writeAscii4('RIFF');
  u32(fileSizeMinus8);
  writeAscii4('WAVE');
  writeAscii4('fmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  writeAscii4('data');
  u32(dataSize);
  for (var i = 0; i < dataSize; i++) {
    out.setUint8(o + i, pcm[i]);
  }
  return out.buffer.asUint8List();
}

/// Converts Gemini TTS [inlineData] bytes to playable WAV bytes.
/// If [mimeType] indicates WAV, returns [raw] unchanged; otherwise treats [raw] as PCM.
Uint8List geminiInlineAudioToWavBytes(Uint8List raw, {required String mimeType}) {
  final m = mimeType.toLowerCase();
  if (m.contains('wav')) {
    return raw;
  }
  return pcm16leMonoToWav(raw);
}
