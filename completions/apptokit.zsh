if [[ ! -o interactive ]]; then
    return
fi

compctl -K _shoctokit shoctokit

_shoctokit() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(shoctokit commands)"
  else
    completions="$(shoctokit completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
