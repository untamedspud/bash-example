# $FreeBSD: releng/8.2/etc/csh.cshrc 50472 1999-08-27 23:37:10Z peter $
#
# System-wide .cshrc file for csh(1).
# $FreeBSD: releng/8.2/etc/csh.login 208313 2010-05-19 20:53:21Z jilles $
#
# System-wide .login file for csh(1).
# Uncomment this to give you the default 4.2 behavior, where disk
# information is shown in K-Blocks
# setenv BLOCKSIZE      K
#
# For the setting of languages and character sets please see
# login.conf(5) and in particular the charset and lang options.
# For full locales list check /usr/share/locale/*
#
# Check system messages
# msgs -q
# Allow terminal messages
# mesg y

alias ruf       '/bin/ls -lat | head -33'
alias l         '/bin/ls -l'
alias lsofnet   '/usr/local/sbin/lsof -i -n -P'
alias showdev   "/usr/bin/egrep 'ad[0-9]|cd[0-9]' /var/run/dmesg.boot"
alias sudo      '/usr/local/bin/sudo -i'
alias mylocate='if [ $((`date +%s`-`eval $(stat -s /var/db/locate.database); echo $st_mtime`)) -gt 3600 ]; then echo "locate: db is too old!">/dev/stderr; sudo /usr/libexec/locate.updatedb; fi; locate -i'

if ($?prompt) then
        #set promptchars = "%#"
        if ( `/usr/bin/id -g` != 0 ) then
                set promptchars = ">"
        else
                set promptchars = "#"
        endif

        if ($?tcsh) then
                # set prompt in csh
                #   will look like this-->    Sat Jun 08 9:36:42 [ray@media]~>
                set prompt="%d %w %D %P [%n@%m]%U%c%u${promptchars} "
        else
                $ set prompt in tcsh
                set prompt = "[%m:%c3] `/usr/bin/id -nu`RAY${promptchars} "
        endif
else
        # this is a batch process, do not write anything to the terminal.
endif
