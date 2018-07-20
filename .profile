#!/bin/bash
# Please note the .profile is supposed to loaded by all shells (bash, zsh,...) don't use fancy syntax
# This file should add private environment variables, do not add it to SCM
[ -s "$HOME/.extra" ] && {
  # shellcheck source=.extra
  . "$HOME/.extra"
}

export VISUAL=mcedit
export EDITOR=mcedit
export DIFFTOOL=bcomp
export CDPATH=.:~:~/redhat:~/os
export DISABLE_AUTO_TITLE="true"

export PYTHONSTARTUP=~/bin/pythonstartup.py
#set -x

# adding PATHs to the begining of the PATH
# "${HOME}/dev/jira/jira-libs.hg/sdk/apache-maven/bin"
# KEEP ~/bin the last one so it will be the first one to look into, that's essential
for MYPATH in \
  "$M2_HOME/bin" \
  "/usr/local/sbin" \
  /usr/local/opt/gettext/bin \
  /usr/local/opt/nss/bin \
  /usr/local/opt/python/libexec/bin \
  "${HOME}/bin" \
  "${HOME}/redhat/work" \
  "${HOME}/redhat/rhos-qe-jenkins/bin"
do
  if [[ ! ":$PATH:" == *":$MYPATH:"* ]] && [ -d "$MYPATH" ]; then
      export PATH=${MYPATH}:$PATH
  fi
done
unset MYPATH

# --- COMPILATION ---
export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/openssl/lib -L/usr/local/opt/nss/lib  -L/usr/local/opt/libarchive/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/openssl/include -I/usr/local/opt/nss/include  -I/usr/local/opt/libarchive/include -I/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7/"
export CFLAGS="-I/usr/local/include -L/usr/local/lib -I$(brew --prefix openssl)/include"
export LDFLAGS="-L$(brew --prefix openssl)/lib"

export C_INCLUDE_PATH=/System/Library/Frameworks/Python.framework/Headers
export PKG_CONFIG_PATH="/usr/local/opt/nss/lib/pkgconfig:/usr/local/opt/libarchive/lib/pkgconfig:/usr/local/opt/zlib/lib/pkgconfig"
export QA_RPATHS=$(( 0x0001|0x0010 ))

# workaround for the infamous "Binary file (standard input) matches" message when trying to grep on some files.
alias e='mcedit'
alias ge='atom'
alias grep='grep -a --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias ww='fc -ln -1 >> ~/history.sh'
# https://github.com/ggreer/the_silver_searcher/blob/master/doc/ag.1.md
alias ag='ag --hidden --ignore-dir=.git --ignore-dir=.tox --ignore-dir=.pyenv -m 200 --nofollow -C 2'
#alias grr="git rebase origin/master && git review"
alias gr="git review"
alias grd="git review -D"
alias grr="git stash save --include-untracked && git review && git stash pop"
alias gp="git push --force-with-lease"
alias gt="gittower ."
alias dqs='/Applications/Docker/Docker\ Quickstart\ Terminal.app/Contents/Resources/Scripts/start.sh' # Open Docker Terminal
alias git-get-tags='git tag -l | xargs git tag -d && git fetch --tags'
#alias jjb="jenkins-jobs"
alias pep8="pycodestyle"

alias mvnvu='mvn versions:display-plugin-updates'
# used to build jenkins plugins and skip the very expensive testing
alias mvni='mvn install -DskipTests=true'

alias jenkins-build='pushd ~/os/jenkins && mvn install -DskipTests=true'
alias jenkins-test='pushd ~/os/jenkins && mvn install -DskipTests=true'
alias jenkins-run='pushd ~/os/jenkins && mvn install -DskipTests=true && (echo "sleep 15; open http://localhost:8080/" | at now) && java -jar war/target/jenkins.war'

# we want to be able to search in dotfiles
# see http://ptspts.blogspot.co.uk/2010/01/how-to-make-midnight-commander-exit-to.html
if [ -f /usr/local/libexec/mc/mc-wrapper.sh ]; then
  alias mc=". /usr/local/libexec/mc/mc-wrapper.sh"
fi
alias waf='$PWD/waf'

# getting current script directory in a cross-platform compatibe way by resolving symlinks
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
if [ "$SHELL" = "/bin/bash" ]; then
    echo "xxx"
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
      DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
      SOURCE="$(readlink "$SOURCE")"
      [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done

    if [ "$OS" = 'darwin' ]; then
      if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
        # shellcheck source=/dev/null
        . "$(brew --prefix)/etc/bash_completion"
      fi
    fi

else
    SOURCE=$0
fi

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=$(lowercase "`uname`")
KERNEL=`uname -r`
MACH=`uname -m`
export OS
export KERNEL
export MACH

#[ -s "$HOME/.rvm/scripts/rvm" ] && {
#  export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
#  # shellcheck source=/dev/null
#}

#which complete && {
#  if [ -f '/usr/local/bin/aws_completer' ]; then
#      complete -C '/usr/local/bin/aws_completer' aws
#  fi
#}

if [ -f /usr/libexec/java_home ]; then
    JAVA_HOME="$(/usr/libexec/java_home -v 9)"
    export JAVA_HOME
fi

# http://stackoverflow.com/questions/71069/can-maven-be-made-less-verbose
export MAVEN_OPTS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cl‌​i.transfer.Slf4jMave‌​nTransferListener=wa‌​rn"
# --- END COMPILATION ---

export PATH="${HOME}/.pyenv:$PATH"
eval "$(pyenv init -)"

#export PYENV_ROOT=/usr/local/var/pyenv
#if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

#echo "INFO: os=$OS login took $(($SECONDS - $START_TIME))s"

# === load ssh keys if they are not already loaded ==
#SSH_AGENT_CONFIG="$HOME/.ssh/.agent-$(uname)"
#
#if [ -f "$SSH_AGENT_CONFIG" ]; then
#    # shellcheck source=/dev/null
#    source "$SSH_AGENT_CONFIG"
#fi

function start_agent {
    echo "INFO: Initialising new SSH agent..."
    #/usr/bin/ssh-agent | sed 's/^echo/#echo/' > "$SSH_AGENT_CONFIG"
    /usr/bin/ssh-agent > "$SSH_AGENT_CONFIG"
    #echo succeeded
    if [ -e "$SSH_AUTH_SOCK" ]; then
      chmod 600 "${SSH_ENV}"
      # shellcheck source=/dev/null
      . "${SSH_ENV}"
    fi
    #/usr/bin/ssh-add;
    # -K is essential on mac in order to add the key to the keychain
    find ~/.ssh -maxdepth 1 -name "*rsa*" \
      ! -name "*.pub" \
      ! -name '*.ppk' -print0 | \
      xargs -0 /usr/bin/ssh-add -K
}

if [[ ! -e "$SSH_AUTH_SOCK" || $(ssh-add -l | wc -l) -lt 1 ]]; then
    start_agent
fi

unset start_agent
# load default key in the agent
ssh-add -l >/dev/null || {
   ssh-add
}


if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    source /usr/local/bin/virtualenvwrapper.sh
fi

#if [ -f ~/.venv/rh/bin/activate ]; then
#    source ~/.venv/rh/bin/activate
#fi


function style_term() {
# this would colorize tab of the iTerm2 based on the hostname
if [[ $- == *i* ]] # only in interactive mode
then
  #set | grep ITERM
  #if [ -z "$ITERM_SESSION_ID" ]; then
  if [ "$1" != 'localhost' ]; then

    #echo ">>> $($1)"
    MD5="md5sum"
    if [[ $OS == 'darwin' ]]; then MD5="md5" ; fi
    #HASH=`hostname -s | ${MD5}`
    HASH=`echo $1 | ${MD5}`
    # it is better to use the first localhost IP that is not 127.0.0.1 because this will be more
    #HASH=`/sbin/ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | ${MD5}`
    #HASH=$(echo "$1" | ${MD5})
    echo -n -e "\033]6;1;bg;red;brightness;$((0x${HASH:0:2}))\a\033]6;1;bg;green;brightness;$((0x${HASH:2:2}))\a\033]6;1;bg;blue;brightness;$((0x${HASH:4:2}))\a"
    echo -e "\033];$(hostname)``\007"
    unset MD5
    unset HASH
  else
    echo -e "\033]6;1;bg;red;brightness;128\a\033]6;1;bg;green;brightness;128\a\033]6;1;bg;blue;brightness;128\a\033];$(hostname)``\007"
  fi
fi
}

# this will use screen to provide persistency when you call ssh with only the server name
function ssh2() {
  if [ "$#" == "1" ]; then
    #echo "ssh wrapper"
    if [ "${1:0:1}" != "-" ]; then
      #echo "..."
      style_term "$1"
      #echo "Using SSH wrapper..."
      eval last_arg=\$$#
      #screen -t "$last_arg" /usr/bin/ssh "$@";
      /usr/bin/ssh "$@";
      #echo "Ending SSH wrapper"
      style_term localhost
    else
    /usr/bin/ssh "$@";
    fi
  else
    /usr/bin/ssh "$@";
  fi
}


function fingerprint() {
    pubkeypath="$1"
    ssh-keygen -E md5 -lf "$pubkeypath" | awk '{ print $2 }' | cut -c 5-
}

ineed() {
echo -en $(echo \
    $(curl -s "https://packages.debian.org/search?suite=default&section=all&arch=any&searchon=contents&keywords=$1") \
       | sed 's%</*tr>%\\n%g') \
    | grep 'class="file"' \
    | sed 's/<[^>]*>//g' \
    | column -t \
    | grep --color -i -w "$1"
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/ssbarnea/.sdkman"
[[ -s "/Users/ssbarnea/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/ssbarnea/.sdkman/bin/sdkman-init.sh"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
#export PATH="$PATH:$HOME/.rvm/bin"

#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

#eval "$(pyenv virtualenv-init -)"