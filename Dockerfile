FROM nvidia/cuda:12.8.1-runtime-ubuntu22.04

# ============================================================
# Environment
# ============================================================
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV TZ=Asia/Seoul
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Ollama defaults (overridable via gcube workload env)
ENV OLLAMA_HOST=127.0.0.1:11434
ENV OLLAMA_MAX_LOADED_MODELS=2

# ============================================================
# Base packages
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git nano vim ca-certificates build-essential \
        python3 python3-pip jq zstd unzip ripgrep locales \
    && locale-gen ko_KR.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Node.js 22 (OpenClaude requires >= 22)
# ============================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Ollama (for local model scenarios)
# ============================================================
RUN curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst \
        -o /tmp/ollama.tar.zst \
    && zstd -d /tmp/ollama.tar.zst --stdout | tar x -C /usr \
    && rm /tmp/ollama.tar.zst

# ============================================================
# 캐시 무효화 인자 (build.yml에서 매 빌드마다 다른 값 전달)
# 아래 OpenClaude 관련 RUN은 이 ARG 이후부터 캐시 무효화됨
# ============================================================
ARG CACHEBUST=1

# ============================================================
# OpenClaude (npm 글로벌 설치) - 콘솔 모드용
# CACHEBUST로 매 빌드마다 최신 버전 설치
# ============================================================
RUN echo "Cache bust: ${CACHEBUST}" \
    && npm install -g @gitlawb/openclaude

# ============================================================
# Bun + OpenClaude Source (for gRPC server mode)
# CACHEBUST로 매 빌드마다 최신 소스 클론
# ============================================================
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN echo "Cache bust: ${CACHEBUST}" \
    && git clone https://github.com/Gitlawb/openclaude.git /opt/openclaude \
    && cd /opt/openclaude \
    && /root/.bun/bin/bun install

# gRPC defaults (overridable via gcube workload env)
ENV GRPC_PORT=50051
ENV GRPC_HOST=0.0.0.0

EXPOSE 50051

# ============================================================
# Workspace
# ============================================================
RUN mkdir -p /root/.claude /workspace/shared
WORKDIR /workspace

# ============================================================
# Entrypoint
# ============================================================
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]