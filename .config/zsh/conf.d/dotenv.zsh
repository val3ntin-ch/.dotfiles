# Auto-source .env when entering a directory — only directories you allowed.
# Never prompts: a prompt on `cd` blocks whatever was typed after it (herdr's
# hdev types `cd <repo> && nvim .` into new panes and nvim never started).
# A new .env gets one quiet hint; `dotenv allow` sources it now and from then
# on, `dotenv deny` silences it, `dotenv` sources it once.
# Allow/deny lists live in $XDG_CACHE_HOME/zsh/ (proper XDG paths).

_dotenv_allowed="$XDG_CACHE_HOME/zsh/dotenv-allowed.list"
_dotenv_denied="$XDG_CACHE_HOME/zsh/dotenv-disallowed.list"

_dotenv_source() { set -a; source "$PWD/.env"; set +a; }

_dotenv_hook() {
  [[ -f "$PWD/.env" ]] || return
  local dirpath="${PWD:A}"
  grep -qFx "$dirpath" "$_dotenv_denied" 2>/dev/null && return
  if grep -qFx "$dirpath" "$_dotenv_allowed" 2>/dev/null; then
    _dotenv_source
  else
    print -P "%F{#6c7086}dotenv: .env here not loaded — 'dotenv allow' to always load, 'dotenv deny' to hide this%f"
  fi
}

# dotenv [allow|deny] — load ./.env once, or remember the choice for this dir
dotenv() {
  [[ -f "$PWD/.env" ]] || { echo "dotenv: no .env in $PWD"; return 1; }
  local dirpath="${PWD:A}"
  mkdir -p "${_dotenv_allowed:h}"
  case "${1:-}" in
    allow) grep -qFx "$dirpath" "$_dotenv_allowed" 2>/dev/null || echo "$dirpath" >>"$_dotenv_allowed"
           _dotenv_source; echo "dotenv: loaded, and will load on every cd here" ;;
    deny)  grep -qFx "$dirpath" "$_dotenv_denied" 2>/dev/null || echo "$dirpath" >>"$_dotenv_denied"
           echo "dotenv: will stay quiet here" ;;
    "")    _dotenv_source; echo "dotenv: loaded once" ;;
    *)     echo "usage: dotenv [allow|deny]"; return 1 ;;
  esac
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _dotenv_hook
