# godot-xvfb — 사람 화면 없이 Godot 을 "그리면서" 돌리는 리눅스 이미지. xvfb_run.sh 가 만들고 쓴다.
#   Xvfb 가상 디스플레이 + Mesa 소프트웨어 렌더러(OpenGL llvmpipe · Vulkan lavapipe) + 공식 Godot 리눅스 빌드
#   🛑 GPU 가 없는 소프트웨어 렌더링이다 — 그림이 맞는지만 보고, 프레임 시간은 재지 않는다.
ARG BASE=ubuntu:22.04
FROM ${BASE}
ENV DEBIAN_FRONTEND=noninteractive

# 이 층은 버전 인자보다 앞에 둔다 — Godot 버전만 바꿔 다시 만들 때 apt 층을 캐시에서 재사용한다
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip xvfb xauth \
      libgl1 libglx-mesa0 libgl1-mesa-dri libegl1 libegl-mesa0 libvulkan1 mesa-vulkan-drivers \
      libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 libxrender1 libxkbcommon0 \
      libfontconfig1 libdbus-1-3 libasound2 libpulse0 libudev1 \
    && rm -rf /var/lib/apt/lists/*

# 호스트 `godot --version` 과 같은 버전이어야 사본의 .godot 임포트 캐시를 그대로 쓴다
ARG GODOT_VERSION=4.7.2-stable
ARG GODOT_ARCH=arm64
RUN curl -fsSL -o /tmp/g.zip "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.${GODOT_ARCH}.zip" \
    && unzip -q /tmp/g.zip -d /tmp/g \
    && mv "/tmp/g/Godot_v${GODOT_VERSION}_linux.${GODOT_ARCH}" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -rf /tmp/g /tmp/g.zip

WORKDIR /work/proj
