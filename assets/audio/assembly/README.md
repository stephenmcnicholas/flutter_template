# Assembly gap clip

`silence_175ms.mp3` is a short silent MP3 (~175 ms) inserted between segments when building the rest-end notification file.

Regenerate if needed (requires `ffmpeg` on your machine — not a runtime app dependency):

```bash
ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=mono -t 0.175 -c:a libmp3lame -q:a 4 silence_175ms.mp3
```
