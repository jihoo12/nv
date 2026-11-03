# NV

작고 직접 고칠 수 있는 Neovim 배포판. 어두운 남색 바탕에 민트색 포인트를 사용합니다.
편집 기능은 mini.nvim, 도구 설치는 Mason, 파서 관리는 nvim-treesitter를 사용합니다.
언어 기능은 Neovim 내장 LSP로 연결합니다.
시작 화면, 테마, 플러그인 설치기, 언어 서버 설정, 포맷 실행기, 플로팅 터미널과 상태 점검은 이 저장소에서 직접 구현했습니다.

## 바로 실행

macOS/Linux에서 저장소 안에서 실행하세요. Neovim **0.12 이상**을 사용합니다.
유지보수 중인 nvim-treesitter의 현재 지원 버전에 맞췄으며, 지원이 동결된 옛 master 브랜치는 사용하지 않습니다.

```sh
./bin/nv
./bin/nv path/to/file
```

첫 실행 시 고정한 플러그인 커밋을 내려받습니다. **파일을 열면 해당 언어의 LSP·포맷터·파서를
백그라운드에서 설치하고 재시작 없이 연결합니다.** 설치 중에도 편집할 수 있습니다.

Nix가 설치되어 있고 기본 실행 도구가 부족하면 `bin/nv`가 고정된 `runtime/flake.lock`으로
Neovim, C 컴파일러, GNU tar, Node.js/npm, Python, Go 등을 자동 준비합니다.
관리자 권한 없이 Nix 캐시에 설치하며 시스템 패키지를 변경하지 않습니다.
`NV_USE_NIX=1 ./bin/nv`로 강제 사용하거나 `NV_USE_NIX=0 ./bin/nv`로 끌 수 있습니다.
소스 전체 대신 `runtime/`만 Nix 입력으로 사용합니다.

Nix가 없는 환경은 Neovim 0.12+, Git, curl, GNU tar(macOS는 gtar), gzip, unzip,
C 컴파일러(cc/gcc/clang)가 필요합니다. npm 기반 서버는 Node.js/npm, Black은 Python 3/venv,
gopls는 Go가 필요합니다. Tree-sitter CLI는 없거나 버전이 낮으면 Mason이 공식 바이너리로 설치합니다.

`bin/nv`는 `NVIM_APPNAME=nv`를 사용하므로
기존 `~/.config/nvim`과 데이터·캐시·상태 디렉터리를 분리합니다. 이 저장소가 설정 원본이므로
설정 폴더로 복사할 필요가 없습니다. `bin` 디렉터리를 PATH에 추가하면 어디서든 `nv`로 실행할 수 있습니다.
셸 스크립트의 위치를 기준으로 설정을 찾으므로, 실행 파일만 따로 복사하지 마세요.

인터넷 연결이 없는 첫 실행은 `NV_OFFLINE=1 ./bin/nv`로 가능합니다. 이때 기본 편집, 테마,
설치된 LSP, 포맷과 터미널을 사용할 수 있고 미설치 플러그인의 기능은 생략합니다.
이미 설치된 플러그인·서버·파서는 오프라인에서도 로드됩니다. 다운로드, 레지스트리 갱신과
Nix 환경 준비는 생략하므로 Nix 도구가 필요하면 준비된 환경 안에서 오프라인 실행하세요.
설치 실패 시에도 기본 편집은 가능합니다.

## 포함된 기능

- 파일·버퍼·최근 파일·도움말·진단·단축키 퍼지 검색, 프로젝트 본문 검색
- 열 형태의 파일 탐색기: 파일 생성·삭제·이름 변경을 편집하듯 수행하고 `=`로 변경 적용
- LSP 자동완성·시그니처 도움말·정의 이동·이름 변경·코드 액션·진단
- 파일 종류에 따른 LSP·포맷터·Tree-sitter 파서 자동 설치, 설치 완료 후 즉시 연결
- 자동 괄호, 텍스트 오브젝트, surround, 선택 영역 이동, 정렬, 인자 줄바꿈
- 내장 주석 토글(`gcc`, `gc`), Git 변경 줄·diff 오버레이·커밋/변경 검색
- 상태줄·버퍼 탭·단축키 안내·TODO와 색상 코드 강조
- 버퍼 변경을 감지하는 비동기 포맷, 숨겨도 유지되는 플로팅 터미널
- 영구 undo, 마지막 커서 위치 복원, 프로젝트별 검색 범위

별도 폰트 없이 동작합니다. 구문 색상은 Tree-sitter와 LSP semantic tokens를 사용하고,
파서를 설치하기 전에는 기본 syntax를 사용합니다. 디버거와 AI 도구는 포함하지 않습니다.

## 주요 단축키

리더 키는 **Space**입니다. 누른 후 잠시 기다리면 이어지는 키 안내가 표시됩니다.

| 키 | 기능 |
| --- | --- |
| `Space ff` / `Space fg` | 프로젝트 파일 / 본문 검색 |
| `Space fb` / `Space fr` | 열린 버퍼 / 최근 파일 |
| `Space fh` / `Space fk` | 도움말 / 모든 단축키 검색 |
| `Space fd` | 진단 검색 |
| `Space e` | 파일 탐색기 |
| `Space w` / `Space q` | 저장 / 창 닫기(미저장 변경 확인) |
| `Space bn` / `Space bp` / `Space bd` | 다음 / 이전 / 현재 버퍼 닫기 |
| `Space cf` | 포맷 실행(결과를 확인한 후 저장) |
| `Space cr` / `Space ca` / `Space cs` | 심볼 이름 변경 / 코드 액션 / 심볼 목록 |
| `Space cd` / `Space cq` | 현재 줄 진단 / 전체 진단 quickfix |
| `Space ch` | LSP 인레이 힌트 토글 |
| `gd` / `gr` / `gi` / `K` | 정의 / 참조 / 구현 / 문서 |
| `[d` / `]d` | 이전 / 다음 진단 |
| `Space gg` / `Space gl` | Git 상태 / 커밋 검색 |
| `Space gf` / `Space gh` / `Space gd` | Git 파일 / 변경 검색 / diff 오버레이 |
| `[h` / `]h` | 이전 / 다음 Git 변경 |
| `Space t` / `Ctrl-\` (Normal 모드) | 플로팅 터미널 토글 |
| 터미널에서 `Ctrl-\ Ctrl-\` | 터미널 숨기기 |
| 터미널에서 `Ctrl-\ Ctrl-n` | 터미널의 Normal 모드 |
| `Ctrl-h/j/k/l` | 창 사이 이동 |
| `Space y` / `Space p` | 시스템 클립보드 복사 / 붙여넣기 |
| `Space un` / `Space uw` / `Space uh` | 상대 줄 번호 / 줄바꿈 / 상태 점검 |
| `sa` / `sd` / `sr` | surround 추가 / 삭제 / 변경 |
| `Alt-h/j/k/l` | 현재 줄 또는 선택 영역 이동 |
| `gS` / `ga` | 인자 줄바꿈 토글 / 정렬 |

LSP 관련 키는 서버가 연결된 버퍼에서 사용할 수 있습니다. 검색 창에서는 입력으로 필터링하고
`Ctrl-n/p`로 선택, `Enter`로 열기, `Esc`로 닫기, `Tab`으로 미리보기를 전환합니다.
파일 탐색기에서는 `g?`, 편집 기능은 `:help mini.surround` 등에서 더 볼 수 있습니다.

## 언어 도구

별도 `npm install -g`나 `:TSInstall` 없이 해당 언어 파일을 열면 됩니다.
기존 PATH에서 실행 가능한 서버·포맷터가 있으면 재사용하고, 없으면 NV 전용 Mason 디렉터리에 설치합니다.
서버가 준비되면 이미 열린 버퍼에도 연결하며 파서가 준비되면 구문 강조를 시작합니다.
같은 도구를 여러 버퍼에서 요청해도 설치는 한 번만 실행합니다.

| 언어 | 자동 준비하는 서버 | 포맷터 |
| --- | --- | --- |
| Lua | `lua-language-server` | `stylua` |
| Python | `pyright-langserver` | `black` |
| JavaScript / TypeScript / JSX / TSX | `typescript-language-server` | `prettier` |
| Go | `gopls` | Go 런타임의 `gofmt` |
| Rust | `rust-analyzer` | Rust 툴체인의 `rustfmt`가 있으면 사용, 없으면 LSP 포맷 지원 시 사용 |
| C / C++ | `clangd` | 서버 포맷 사용 |
| Shell | `bash-language-server` | 서버 포맷 사용(지원 시) |
| JSON / HTML / CSS / YAML / Markdown | 사용자 서버 추가 가능 | `prettier` |

파서는 현재 파일타입을 Neovim의 언어 매핑으로 변환해 설치합니다. 예를 들어 `.tsx`는 `tsx`,
`.py`는 `python`입니다. 파서가 요구하는 다른 파서도 함께 설치하며, upstream에서
unmaintained/unsupported로 분류한 파서는 자동 설치하지 않습니다. 파서와 query는
nvim-treesitter 커밋별 디렉터리에 저장해 플러그인 업데이트 시 이전 문법 정의와 섞이지 않게 합니다.

설치 상태와 실패 원인:

```vim
:NvHealth         " 실행 환경, 서버, 파서 상태
:Mason            " 도구 설치 UI
:MasonLog         " 도구 설치 로그
:TSLog            " 파서 설치 로그
:NvToolsInstall   " 열린 파일과 사전 지정 도구의 설치/실패 재시도
```

네트워크나 실행 환경 문제로 실패한 설치를 파일 전환 때마다 반복하지 않습니다.
문제를 해결한 후 `:NvToolsInstall`로 다시 시도하세요. 이미 설치된 도구의 업데이트는
`:Mason`에서 명시적으로 수행합니다.

본문 검색은 **ripgrep**(`rg`)이 필요합니다. 파일 검색은 `rg`, `fd`, Git 또는 내장 탐색을 사용합니다.
시스템 클립보드는 환경에 맞는 provider가 필요하며 `:checkhealth vim.provider`로 확인합니다.

포맷터가 없으면 연결된 LSP 중 포맷을 지원하는 서버 하나를 사용합니다. 외부 포맷터는
표준입출력으로 버퍼만 변경하며 자동 저장하지 않습니다. 포맷 실행 중 편집하면 오래된 결과를
버려 입력을 보존합니다. Rust 포맷 기본 edition은 2021이며 2024 프로젝트는 아래 사용자 설정에서 바꾸세요.

## 내 설정 추가

```sh
cp lua/user.example.lua lua/user.lua
```

`lua/user.lua`는 Git에서 제외됩니다. 예시:

```lua
return {
  icons = true, -- Nerd Font를 쓸 때
  tools = {
    auto_install = true,
    formatters = true,
    ensure_installed = { 'lua-language-server', 'stylua' }, -- 파일을 열기 전에도 준비
  },
  treesitter = {
    auto_install = true,
    ensure_installed = { 'lua', 'python' },
  },
  servers = {
    pyright = false,
    lua_ls = { settings = { Lua = { diagnostics = { globals = { 'vim', 'describe', 'it' } } } } },
  },
  setup = function()
    vim.opt.relativenumber = false
    require('nv.actions').formatters.rust = { 'rustfmt', '--emit', 'stdout', '--edition', '2024' }
  end,
}
```

서버는 `servers`에 `cmd`, `filetypes`, `root_markers`를 지정해 추가합니다.
사용자 서버를 자동 설치하려면 `tools.servers = { custom = 'mason-package-name' }`을 추가하세요.
기본 서버의 명령을 사용자 명령으로 바꾼 경우 관련 없는 기본 패키지를 자동 설치하지 않습니다.
`servers.pyright = false`는 해당 서버의 설치·활성화를 끕니다.
`tools.auto_install = false`, `treesitter.auto_install = false`는 자동 다운로드를 끄고
이미 설치된 도구를 사용합니다. `enabled = false`는 해당 관리 플러그인의 로드까지 끕니다.
포맷터는 `require('nv.actions').formatters[파일타입]`에 명령 배열을 지정합니다.
`$FILE` 항목은 현재 파일 경로로 치환되고 버퍼 내용은 stdin으로 전달됩니다.

## 의존성 정책과 업데이트

외부 플러그인은 다음 셋이며 `plugins-lock.json`에 정확한 커밋을 고정합니다.
2026-11-03 공식 GitHub API와 실제 소스를 확인했습니다.

| 플러그인 | 고정 버전 / 커밋 | 확인한 최근 push |
| --- | --- | --- |
| [mini.nvim](https://github.com/nvim-mini/mini.nvim) | v0.18.0 / `1345d191` (stable) | 2026-10-30 |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | v2.3.1 / `2a6940af` | 2026-06-19 |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | main / `0195cd62` | 2026-11-02 |

모두 보관되지 않은 저장소입니다. nvim-treesitter는 현재 main API를 사용하며 옛 `configs.setup` API는 사용하지 않습니다.
언어 서버 연결은 [Neovim의 `vim.lsp.config` / `vim.lsp.enable`](https://neovim.io/doc/user/lsp.html)을 사용합니다.

플러그인은 시작할 때 자동 업데이트하지 않습니다. `plugins-lock.json`의 정확한 커밋을 내려받고,
커밋별로 다른 데이터 경로를 사용합니다. 업데이트하려면 공식 변경 기록과 유지보수 상태를 확인한 뒤
`git ls-remote https://github.com/nvim-mini/mini.nvim.git refs/heads/stable`로 새 커밋을 확인하고
lockfile의 `commit`, `version`을 함께 수정하세요. 다시 실행하면 새 버전이 설치됩니다.
이전 lockfile로 돌리면 기존 캐시의 이전 커밋으로 복귀합니다.
Mason 패키지는 첫 설치 시 레지스트리의 버전을 사용하며 설치 영수증을 Mason이 보관합니다.
플러그인 커밋 고정은 외부 언어 도구 버전 고정을 의미하지 않습니다.

## 검증

```sh
sh tests/run.sh
# 이미 받은 정확한 커밋의 체크아웃으로 네트워크 없이 검사:
NV_OFFLINE=1 \
NV_TEST_MINI_SOURCE=/path/to/mini.nvim \
NV_TEST_MASON_SOURCE=/path/to/mason.nvim \
NV_TEST_TREESITTER_SOURCE=/path/to/nvim-treesitter sh tests/run.sh
# 실제 Lua/Python/TypeScript/TSX 도구와 파서를 다운로드·빌드하는 검사:
sh tests/auto-install.sh
```

Python 3와 Git이 테스트에 필요합니다. 임시 XDG 디렉터리에서 실제 플러그인 로드,
테스트 LSP 서버 연결/요청, 포맷 성공·실패·동시 편집 보호, 터미널 재사용, 시작 화면,
health 보고서, 로컬 Git 원격을 이용한 첫 설치·실패 정리와 플러그인 없는 오프라인 실행을 검사합니다.
설치 요청 중복 방지, 레지스트리 갱신 공유, 설치 직후 서버 활성화, 사용자 명령·서버 끄기,
오프라인 처리와 실패 재시도도 네트워크 없이 검사합니다. 별도 자동 설치 검사는 실제 다운로드 후
Lua/Python/TypeScript/TSX의 LSP 연결과 구문 강조 및 Mason의 Tree-sitter CLI 설치를 확인하고,
같은 데이터로 오프라인 재실행합니다.
실제 사용자 데이터는 사용하지 않습니다.
CI는 Neovim 0.12.0과 최신 stable에서 통합 검사를 실행합니다.

구성 진입점은 `init.lua`, 기능 구현은 `lua/nv/`, 테마는 `colors/nv.lua`입니다.
