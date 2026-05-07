# gcube-openclaude

## 패키지 스펙

| 항목 | 버전 |
|------|------|
| Base Image | `nvidia/cuda:12.8.1-runtime-ubuntu22.04` |
| OS | Ubuntu 22.04 |
| CUDA | 12.8.1 |
| Node.js | 22.x (NodeSource) |
| OpenClaude | 0.9.2 |
| Ollama | latest |
| Timezone | Asia/Seoul |

## 포트

- OpenClaude는 별도 서버 포트를 노출하지 않음
- 콘솔(SSH 또는 VS Code gcube extension) 진입 후 `openclaude` 명령으로 대화형 세션 시작

## 마운트

| 외부 저장소 | 컨테이너 경로 | 용도 |
|------------|--------------|------|
| Dropbox | `/root/.claude` | OpenClaude 설정·세션·메모리 |
| Dropbox | `/workspace` | 사용자 git repo·작업물 |

## 프로젝트 구조

```
.
├── .github/
│   └── workflows/
│       └── build.yml               # ghcr.io 자동 빌드/push 워크플로우
├── Dockerfile                      # CUDA + Node.js + Ollama + OpenClaude 이미지
├── entrypoint.sh                   # 컨테이너 자동 설정·기동
└── README.md
```

## 환경변수

워크로드 배포 시 사용자가 지정하는 변수만 정리. 이미지 내부 고정값(`OLLAMA_HOST`, `OLLAMA_MAX_LOADED_MODELS`, `LANG` 등)은 `Dockerfile` 참조.

### 필수 — LLM Provider

OpenAI 호환 API 또는 Anthropic 호환 API를 사용하는 모든 provider를 환경변수로 지정 가능. 호출 시점에 `OPENAI_BASE_URL` 또는 `ANTHROPIC_BASE_URL`로 endpoint 결정.

#### Z.ai GLM
```
CLAUDE_CODE_USE_OPENAI=1
OPENAI_API_KEY=<Z.ai API key>
OPENAI_BASE_URL=https://api.z.ai/api/paas/v4
OPENAI_MODEL=glm-5.1
```
- 사용 가능 모델: `glm-5.1`, `glm-5-turbo`, `glm-4.7`, `glm-4.5-air`

#### Moonshot Kimi
```
CLAUDE_CODE_USE_OPENAI=1
OPENAI_API_KEY=<Moonshot API key>
OPENAI_BASE_URL=https://api.moonshot.ai/v1
OPENAI_MODEL=kimi-k2.6
```
- 사용 가능 모델: `kimi-k2.6`, `kimi-k2.5`, `kimi-k2-thinking`

#### Anthropic
```
ANTHROPIC_API_KEY=<Anthropic API key>
ANTHROPIC_MODEL=claude-sonnet-4-5
```
- 사용 가능 모델: Anthropic API에서 제공하는 모든 Claude 모델

#### Ollama 로컬
```
CLAUDE_CODE_USE_OPENAI=1
OPENAI_API_KEY=ollama
OPENAI_BASE_URL=http://localhost:11434/v1
OPENAI_MODEL=qwen3:14b
```
- 사용 가능 모델: Ollama Library에 등록된 모든 모델 (예: `qwen3:14b`, `glm-4.7-flash:q4_K_M`, `gemma4:26b`)
- 외부 API 모델과 달리 GPU VRAM 필요

> 외부 API 모델은 호출 시 비용 발생. 본 이미지는 RTX 5090 환경에서 Z.ai GLM-5.1 조합으로 테스트 완료. 다른 provider는 OpenClaude가 표준적으로 지원하지만 본 이미지에서 별도 테스트를 거치지 않음.

### 선택 — Git 자동 설정

세 변수 모두 제공되면 컨테이너 시작 시 자동으로 git 설정 완료. 하나라도 비어있으면 git 설정 없이 컨테이너만 기동.

| 변수 | 설명 |
|------|------|
| `GIT_USER_NAME` | git 사용자 이름 (GitHub username) |
| `GIT_USER_EMAIL` | git 사용자 이메일 |
| `GIT_TOKEN` | Personal Access Token (private repo 접근용) |

- 설정 후 컨테이너 안에서 바로 `git clone`·`git push` 가능

## 시작 흐름

```
컨테이너 시작
  │
  ├─ 1. Git 설정 (선택)
  │     · GIT_USER_NAME, GIT_USER_EMAIL, GIT_TOKEN 셋 다 있을 때만
  │     · git config --global + credential.helper store
  │     · ~/.git-credentials 등록 (chmod 600)
  │     · init.defaultBranch=main 설정
  │
  ├─ 2. Ollama 기동
  │     · ollama serve (background)
  │     · /api/tags 응답 대기
  │
  └─ 3. 안내 메시지 출력
        · Provider, Model, Git user, Workspace 경로
        · openclaude 시작 안내
```

- OpenClaude는 사용자가 콘솔에서 `openclaude` 명령을 직접 실행해 시작하는 대화형 도구
- 컨테이너는 OpenClaude를 자동 실행하지 않음

## 핵심 동작

OpenClaude의 동작 방식·도구 시스템·sub-agent·메모리·슬래시 명령 등 상세 내용은 OpenClaude 공식 저장소 참조.

- 공식 저장소: https://github.com/Gitlawb/openclaude
- 문서: https://github.com/Gitlawb/openclaude/blob/main/docs/advanced-setup.md

## 빌드 & 배포

GitHub Actions(`.github/workflows/build.yml`)가 `main` 브랜치 push 시 자동으로 ghcr.io에 이미지를 빌드·push.

```
브랜치    →  이미지 태그
main     →  ghcr.io/data-alliance/openclaude-baseimage:latest
```