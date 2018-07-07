if [[ ! -o interactive ]]; then
    return
fi

compctl -K _apptokit apptokit

_apptokit() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(apptokit commands)"
  else
    completions="$(apptokit completions "${words[2]}" "${words[3,-1]}")"
  fi

  reply=("${(ps:\n:)completions}")
}
