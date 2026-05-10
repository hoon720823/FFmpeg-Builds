# fms-ffmpeg autobuild — `{{DESCRIBE}}`

`hoon720823/ffmpeg-patch` 의 master HEAD 자동 빌드. fms-agent 의 ABR seamless reconfigure (ZMQ enc-bridge) 용 fork.

## 이 빌드 정보

| 항목 | 값 |
|------|------|
| **Source repo** | https://github.com/hoon720823/ffmpeg-patch |
| **Source branch** | `master` |
| **Source describe** | `{{DESCRIBE}}` |
| **Upstream base** | ffmpeg `n8.1.1` (mainline) |
| **Build workflow** | [run #{{RUN_ID}}]({{RUN_URL}}) |
| **Build date (UTC)** | {{BUILD_DATE_UTC}} |
| **Variant** | `gpl-shared 8.1` (DLL split) |

## 들어있는 것 — fms 전용 patch (`abr-zmq-patches`)

mainline ffmpeg 위에 fms 운영용 patch:

| 파일 | 변경 |
|------|------|
| `libavfilter/zmq_enc_cmd.h` | callback 인터페이스 header (신규) |
| `libavfilter/f_zmq.c` | ZMQ filter 가 `@enc_<idx>` prefix 명령 인식 → callback dispatch |
| `libavfilter/Makefile` | build 통합 |
| `fftools/ffmpeg.c` | callback 등록 (`fms_apply_enc_cmd`) — `AVCodecContext->bit_rate / rc_max_rate / rc_min_rate / rc_buffer_size` 직접 mutation |

### 동작

1. agent 가 ZMQ REQ → ffmpeg f_zmq.c REP socket (default `tcp://*:5555`) 에 명령 송신
2. `@enc_<idx>` prefix 검출 시 callback 호출 → stream_idx → AVCodecContext 매핑 + field mutation
3. REP `0 dispatched` 반환
4. 다음 frame 처리 시 인코더 wrapper (libx264 / nvenc / libx265) 가 ctx 변화 자동 감지 → `x264_encoder_reconfig` / `NvEncReconfigureEncoder` 자동 호출 (mainline 동작)

### 명령 형식

```
@enc_<output_stream_idx> <option> <value>

예:
  @enc_0 b 1500k         # AVCodecContext->bit_rate
  @enc_0 maxrate 1800k   # rc_max_rate
  @enc_0 minrate 800k    # rc_min_rate
  @enc_0 bufsize 3600k   # rc_buffer_size
```

기존 ZMQ filter 옵션 명령 (`Parsed_scale_0 width 640` 등) 도 그대로 동작 — 본 patch 는 추가만.

## 빌드된 platform

| platform | 파일 패턴 |
|----------|-----------|
| windows / amd64 | `*-win64-gpl-shared-8.1.zip` |
| windows / arm64 | `*-winarm64-gpl-shared-8.1.zip` (미검증) |
| linux / amd64 | `*-linux64-gpl-shared-8.1.tar.xz` |
| linux / arm64 | `*-linuxarm64-gpl-shared-8.1.tar.xz` |
| macOS / Apple Silicon | `*-macos-arm64-gpl-shared-8.1.tar.xz` |
| 무결성 | `checksums.sha256` |

## 사용 (ffmpeg 교체)

**Windows**

```powershell
Expand-Archive ffmpeg-*-win64-gpl-shared-8.1.zip -DestinationPath C:\
Rename-Item C:\ffmpeg-*-win64-gpl-shared-8.1 C:\ffmpeg
$env:Path += ";C:\ffmpeg\bin"
ffmpeg -version  # → "ffmpeg version {{DESCRIBE}}-..." 확인
```

**Linux**

```bash
tar -xJf ffmpeg-*-linux64-gpl-shared-8.1.tar.xz -C /opt
sudo ln -sf /opt/ffmpeg-*-linux64-gpl-shared-8.1/bin/ffmpeg /usr/local/bin/ffmpeg
ffmpeg -version
```

**macOS** (unsigned binary — Gatekeeper 우회 필요)

```bash
tar -xJf ffmpeg-*-macos-$(uname -m)-gpl-shared-8.1.tar.xz -C /opt
sudo ln -sf /opt/ffmpeg-*-macos-*-gpl-shared-8.1/bin/ffmpeg /usr/local/bin/ffmpeg
sudo xattr -dr com.apple.quarantine /opt/ffmpeg-*-macos-*-gpl-shared-8.1
ffmpeg -version
```

## 무결성

```
sha256sum -c checksums.sha256        # linux/macOS
Get-FileHash *.zip -Algorithm SHA256  # windows
```

## Source / 관련

- ffmpeg source: [hoon720823/ffmpeg-patch](https://github.com/hoon720823/ffmpeg-patch) @ `master`
- builder: [hoon720823/FFmpeg-Builds](https://github.com/hoon720823/FFmpeg-Builds)
- 사용처: [funzun-media-server fms-agent](https://github.com/hoon720823/funzun-media-server)
