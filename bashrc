#!/bin/bash
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.
#
# It attempts to keep all settings completely generic so that any
# user can install this without fear of any unusual aliases or
# preferences being forced upon them.
#
# In order to allow for customization (and to allow the authors to
# use this file along with some private aliases), this file will
# source other sub-files if they exist, in the following order:
#
# ~/.bashrc.d/*
#   A place to store extra configuration in order to keep this master .bashrc
#   file as clean and generic as possible.  All files here will be included
#   unless they are "location" files as described below.
#
# ~/.bashrc.d/"$LOCATION".loc
#   This is intended for separating "home" and "work" settings.  $LOCATION is
#   the main domain "word" for this host, i.e. example.loc for example.com.
#
# ~/.bashrc_custom
#   This behaves like the files in ~/.bashrc.d, but is intended for custom
#   settings specific to an individual host and as such will never be copied
#   or overwritten by host-setup routines.
#

###############################################################################
# Test for an interactive shell.  There is no need to set anything past this
# point for scp and rcp, and it's important to refrain from outputting anything
# in those cases.  However, we should add a couple of extra paths in case this
# is rsync (in case rsync itself is stored somewhere like /usr/local/bin).

  if [[ "$-" != *i* ]]; then
    for dir in /usr/*/bin/ /opt/*/bin/; do
      export PATH="$PATH:$dir"
    done
    return
  fi

###############################################################################
# Source any global definitions that exist
#
  for file in \
    /etc/*bashrc /etc/profile /etc/bash/bashrc \
    /etc/bash_completion ~/.bash_aliases \
    /sw/bin/init.sh
  do
    [[ -f "$file" ]] && source "$file"
  done

###############################################################################
# Setup some global information about the environment
#

# Figure out what os/distro we are on
  IS_MAC=
  IS_LINUX=
  IS_SUN=
  DISTRO=
  OS=
  VERSION=

  if which uname &> /dev/null; then
    OS=`uname`
  fi

  if [[ "$OS" == 'Darwin' ]]; then
    DISTRO='OSX'
    IS_MAC=1
  elif [[ "$OS" == 'SunOS' ]]; then
    DISTRO='SunOS'
    IS_SUN=1
  elif [[ "$OS" == 'Linux' ]]; then
    IS_LINUX=1
    if [[ -f /etc/gentoo-release ]]; then
      DISTRO='Gentoo'
    elif [[ -f /etc/redhat-release ]]; then
      DISTRO=`awk '{ print $1 }' /etc/redhat-release`
    elif [[ -f /etc/debian_version ]]; then
      DISTRO='Debian'
    elif [[ -f /etc/lsb*release ]]; then
      eval `cat /etc/lsb*release`
      DISTRO=$DISTRIB_ID
    fi
  fi

# In a root-capable group?
  ROOTGROUP=
  if [[ $IS_LINUX ]]; then
    groups | grep 'root\|wheel' &> /dev/null
    if [[ "$?" == 0 ]]; then
      ROOTGROUP=1
    fi
  elif [[ $IS_MAC ]]; then
    groups | grep 'root\|admin' &> /dev/null
    if [[ "$?" == 0 ]]; then
      ROOTGROUP=1
    fi
  fi

# Local X server?
  LOCAL_X=
  if [[ $IS_LINUX ]]; then
    if [[ ':' == "${DISPLAY:0:1}" ]]; then
      LOCAL_X=1
    fi
  elif [[ $IS_MAC ]]; then
    if [[ '/tmp/launch' == "${DISPLAY:0:11}" ]]; then
      LOCAL_X=1
    fi
  fi

# Get the primary domain for this host (minus any subdomains)
  if [[ $IS_LINUX || $IS_MAC ]]; then
    DOMAIN=`echo \`hostname -d\` | sed -e 's/^.\+\.\([^\.]\+\?\.[^\.]\+\)$/\1/'`
  else
    DOMAIN=
  fi

# Use gnu grep if it's available
  if [[ $IS_SUN ]]; then
    if which ggrep &> /dev/null; then
      alias grep=ggrep
    fi
  fi

###############################################################################
# Define useful functions that things below depend on
#

# Return the absolute/expanded pathname to the requested file or directory
  abspath() {
    dir="$1"
    file=""
    if [[ -f "$dir" ]]; then
      file=/`basename "$dir"`
      dir=`dirname "$dir"`
    fi
    echo `cd "$dir" && pwd -P`"$file"
  }

#
# Nice path functions with slight modifications from:
#
#   http://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
#
  append_path()  { NEW=${1/%\//}; [[ -d $NEW ]] || return; remove_path $NEW; export PATH="$PATH:$NEW"; }
  prepend_path() { NEW=${1/%\//}; [[ -d $NEW ]] || return; remove_path $NEW; export PATH="$NEW:$PATH"; }
  remove_path()  {
    # New format not supported by some old versions of awk
    # PATH=`echo -n "$PATH" | awk -v RS=: -v ORS=: '$0 != "'$1'"'`
    PATH=`echo -n "$PATH" | awk  'BEGIN { RS=":"; ORS=":" } $0 != "'$1'" '`
    export PATH=${PATH/%:/}
  }


# Return the first program from the argument list that exists in the execution path
  find_program() {
    for file in $*; do
      if which "$file" &>/dev/null; then
        echo "$file"
        return
      fi
    done
  }

###############################################################################
# Basic environmental settings/changes that should go everywhere
#

#
# Commandline setup
#

# Colorize and customize the sudo prompt
  alias sudo='sudo -p "`echo -e '\''\033[33msudo \033[1;31m%U\033[0;33m password for \033[0;34m%u\033[36m@\033[34m%h\033[0m: \033[0m'\''` "'

# Change PROMPT_COMMAND so that it will update window/tab titles automatically
  if [[ $IS_LINUX || $IS_SUN ]]; then
    case "$TERM" in
      xterm*|rxvt|Eterm|eterm|linux)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
        ;;
      screen)
        PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\033\\"'
        ;;
    esac
  fi

# Redraw the prompt to a better look.  Red for Root (EUID zero)
  if [[ $EUID == 0 ]]; then
    PS1='\[\033[1;31m\]\u\[\033[22m\]@\[\033[1m\]\h\[\033[0m\]: \[\033[32m\]\w\[\033[0m\] # '
  else
    PS1='\[\033[0;34m\]\u\[\033[36m\]@\[\033[34m\]\h\[\033[0m\]: \[\033[32m\]\w\[\033[0m\] > '
  fi

# Allow control-D to log out
  unset ignoreeof

# History length
  export HISTSIZE=2500

# Ignore duplicate history entries and those starting with whitespace
  export HISTCONTROL=ignoreboth

# Prevent certain commands from cluttering the history
  export HISTIGNORE="&:l:ls:ll:[bf]g:clear:exit:history:history *:history|*:cd:cd -:df"

# Enable spellchecking/guessing for cd commands (useful for typo'd pathnames)
  shopt -s cdspell

# Store multi-line commands as one line in the history
  shopt -s cmdhist

# Turn on checkwinsize so we get $LINES and $COLUMNS
  shopt -s checkwinsize

#
# Update the search path with some more directories
#

  if [[ $ROOTGROUP ]]; then
    for dir in \
        /usr/*/sbin/           \
        /opt/*/sbin/           \
        /usr/lib/courier/*sbin \
        ; do
      prepend_path "$dir"
    done
    prepend_path /usr/sbin
    prepend_path /sbin
  fi

  append_path ~/bin
  append_path ~/scripts
  for dir in \
      /usr/*/bin/           \
      /opt/*/bin/           \
      /usr/java/*/bin/      \
      /usr/lib/courier/*bin \
      ; do
    append_path "$dir"
  done

#
# Setup Grep
#
  export GREP_OPTIONS=

# Ignore certain directory patterns
  if grep --help | grep -- --exclude-dir= &> /dev/null; then
    export GREP_OPTIONS="--exclude-dir=.svn $GREP_OPTIONS"
    export GREP_OPTIONS="--exclude-dir=.git $GREP_OPTIONS"
    export GREP_OPTIONS="--exclude-dir=CVS $GREP_OPTIONS"
  elif grep --help | grep -- --exclude= &> /dev/null; then
    export GREP_OPTIONS="--exclude=\*.svn\* $GREP_OPTIONS"
    export GREP_OPTIONS="--exclude=\*.git\* $GREP_OPTIONS"
    # would like to exclude CVS here, but it's too generic without slashes
  fi

# Turn on grep colorization
  if echo hello | grep --color=auto l &>/dev/null 2>&1; then
    export GREP_OPTIONS="--color=auto $GREP_OPTIONS"
    export GREP_COLOR='0;32'
  fi
# Prepare the ls color options
  if [[ $IS_MAC ]]; then
    export CLICOLOR=1
  fi
  for file in /etc/DIR_COLORS ~/.dir_colors; do
    if [[ -f "$file" ]]; then
      eval `dircolors -b $file`
    fi
  done
  if [[ $IS_MAC ]]; then
      LS_OPTIONS='-G -v'
  elif [[ $IS_LINUX ]]; then
      LS_OPTIONS='-v --color=auto --show-control-chars'
  else
      LS_OPTIONS=
  fi

#
# Other settings specific to the OS
#

# Linux and Solaris settings
  if [[ $IS_LINUX || $IS_SUN ]]; then

  # Update JAVA_HOME, too
    JAVA_HOME="`dirname \`dirname \\\`which java2 2>/dev/null\\\` 2>/dev/null\` 2>/dev/null`"

  #Export proper case-sensitive language sorting
    export LC_COLLATE=C

  # Preferred editor settings
    export EDITOR=`find_program vim vi nano`

  # Preferred pager
    export PAGER=`find_program less more cat`

  # Python-preferred browser
    export BROWSER=`find_program firefox mozilla iceweasel elinks lynx`

# Mac settings
  elif [[ $IS_MAC ]]; then

  # Preferred editor settings
    export EDITOR=vim

  # Preferred pager
    export PAGER=less

  fi

# Make OpenOffice display things in its own UI widgets rather than trying to
# use gnome or kde (work around a bug that makes OO hide cell background
# colors if the "input field" background color is too dark for some unknown
# threshhold).
  export SAL_USE_VCLPLUGIN=gen

#
# Handy aliases
#

# Add some aliases to prevent accidental overwriting/deleting
  alias rm='/bin/rm -i'
  alias cp='/bin/cp -i'
  alias mv='/bin/mv -i'

# Add some ls-related aliases
  alias ls="ls -F $LS_OPTIONS"
  alias l="ls -F $LS_OPTIONS"
  alias ll="clear;ls -laF $LS_OPTIONS"
  alias llh="clear;ls -laFh $LS_OPTIONS"
  unset LS_OPTIONS

# And some program-related shortcuts
  alias edit="$EDITOR"
  alias less='less -R'
  alias more='less -R'
  alias p='nano -czw'
  alias vi='vim'
  alias v='vim -N'
  alias vim='vim -N'
  alias jedit='jedit -reuseview'

# Helpful shortcuts
  alias ff='find -type f | grep '
  alias fd='find -type d | grep '
  alias ffi='find -type f | grep -i '
  alias fdi='find -type d | grep -i '

# Programs I don't want to accidentally type
  alias mf="echo 'You meant mv, right?    '"

###############################################################################
# Things very specific to MacOS
#

if [[ $IS_MAC ]]; then

# Turn on bash-completion for macs
  [[ -f /opt/local/etc/bash_completion ]] && source /opt/local/etc/bash_completion

# Fink installed?
  if [[ -d /sw ]]; then
    export CFLAGS="-I/sw/include"
    export LDFLAGS="-L/sw/lib"
    export CXXFLAGS=$CFLAGS
    export CPPFLAGS=$CXXFLAGS
    export ACLOCAL_FLAGS="-I /sw/share/aclocal"
    export PKG_CONFIG_PATH="/sw/lib/pkgconfig"
    export MACOSX_DEPLOYMENT_TARGET=10.4
    prepend_path PATH /sw/bin
    if [[ $ROOTGROUP ]]; then
      prepend_path PATH /sw/sbin
    fi
  fi

# Mac Ports?
  if [[ -d /opt/local ]]; then
    prepend_path PATH /opt/local/bin
    if [[ $ROOTGROUP ]]; then
      prepend_path PATH /opt/local/sbin
    fi
    prepend_path /opt/local/sbin
    MANPATH="/opt/local/share/man:$MANPATH"
    export QTDIR=/opt/local/lib/qt3
  fi
  append_path PATH /usr/libexec

  if [[ -e /usr/bin/open-x11 ]]; then
    /usr/bin/open-x11
    if [[ ! $DISPLAY ]]; then
      export DISPLAY=':0.0'
      LOCAL_X=1
    fi
  fi

fi

###############################################################################
# Execute any environment-specific bashrc files
#

# Load any custom extensions
  if [[ -d ~/.bashrc.d ]]; then
    for file in ~/.bashrc.d/*; do
      if [[ ${file:$((${#file}-4)):4} != '.loc' ]]; then
        source "$file"
      fi
    done
  fi

# And location (useful for home vs. work separation)
  LOCATION=`echo "$DOMAIN" | awk -F. '{ print $1 }'`
  [[ -f ~/.bashrc.d/"$LOCATION".loc ]] && source ~/.bashrc.d/"$LOCATION".loc

# And finally even more
  [[ -f ~/.bashrc_custom ]] && source ~/.bashrc_custom

