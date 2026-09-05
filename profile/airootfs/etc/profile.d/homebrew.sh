# EasyArch Homebrew environment
# Homebrew's supported Linux prefix is /home/linuxbrew/.linuxbrew.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
