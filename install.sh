
set -e

APP="apptokit"
LIB_DIR="/usr/local/lib/$APP"
BIN_DIR="/usr/local/bin"

function install {
  command -v ruby >/dev/null 2>&1 || {
    echo >&2 "apptokit requires ruby but it's not installed.  Aborting."
    echo >&2 "Check out https://www.ruby-lang.org/en/documentation/installation/ for ways to get it!"
    exit 1
  }

  command -v brew >/dev/null 2>&1 || { 
    command -v git >/dev/null 2>&1 || {
      echo >&2 "apptokit requires git but it's not installed, and brew is not installed to install it.  Aborting."
      echo >&2 "For help installing homebrew, visit https://brew.sh"
      exit 1
    }
  }

  command -v git >/dev/null 2>&1 || {
    echo >&2 "apptokit requires git, install it using Homebrew?"
    read -p "Continue (y/n)?" choice
    case "$choice" in 
      y|Y )
        brew install git
      ;;
      * )
        echo >&2 "apptokit installer cannot proceed without git, try again once it's available."
        exit 2
      ;;
    esac
  }

  PROJECT_GIT_URL="https://github.com/jakewilkins/apptokit.git"
  TAG="master"
  LIB_MOVES=("completions" "libexec" "share" "LICENSE")
  CLONE_DIR=$(mktemp -d)

  git clone $PROJECT_GIT_URL $CLONE_DIR

  mkdir -pv $LIB_DIR
  mkdir -pv $BIN_DIR
  mkdir -pv $LIB_DIR/bin

  pushd $CLONE_DIR
  git checkout $TAG

  for move in "${LIB_MOVES[@]}"; do
    mv -v $move $LIB_DIR/$move
  done

  popd

  rm -r "$CLONE_DIR" 1>/dev/null

  ln -vs $LIB_DIR/libexec/$APP $BIN_DIR/$APP
  # FIXME - this link is kind of gross - but I'm leaving it so that
  # apptokit shell-setup works without changes.
  ln -vs $LIB_DIR/libexec/$APP $LIB_DIR/bin/$APP

  echo "Generating global config file unless you have one..."
  $BIN_DIR/$APP init initial-setup
  echo
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "Installer complete!"
  echo
  echo 'If /usr/bin is not in your $PATH or you\'d like tab completions, follow instructions below.
  echo


  $BIN_DIR/$APP shell-setup
}

function uninstall {
  echo "This uninstaller will remove"
  echo " - the lib files in /usr/local/lib"
  echo " - the linked executable in /usr/local/bin"
  echo " - any keycache files generated"
  echo
  echo "Your global config and any project specific configs will remain, as well as shell-setup commands added to your $(basename $SHELL)rc"
  echo "to fully complete uninstallation please remove the shell-setup commands from your $(basename $SHELL)rc"
  echo

  
  [ -d "$LIB_DIR" ] && { echo "removing $LIB_DIR"; rm -r "$LIB_DIR" > /dev/null; }
  [ -L "$BIN_DIR/$APP" ] && { echo "removing $BIN_DIR/$APP"; rm "$BIN_DIR/$APP" > /dev/null; }
  set +e
  db_glob="$(ls ~/.config/.apptokit_*_keycache.db 2>/dev/null)"
  set -e
  [ ! -z "$db_glob" ] && { echo "removing key caches $db_glob"; rm $db_glob; }
  echo "uninstall complete."
}

case "$1" in
  "install" )
    install
  ;;
  "uninstall" )
    uninstall
  ;;
  * )
    echo >&2 "Please specifiy one of install or uninstall"
    exit 3
  ;;
esac

#// vim: set ft=bash: