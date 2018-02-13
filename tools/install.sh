#!/bin/sh

: ${REMOTE:=https://github.com/xzhavilla/xzhell.git}
: ${LOCAL:=$HOME/.xzhell}

hash git >/dev/null 2>&1 || {
	echo xzh: git: command not found 2>/dev/null
	exit 127
}

( if test -d $LOCAL; then
	cd $LOCAL &&
	git checkout . &&
	env git pull --rebase --stat origin master
  else
	env git clone --depth=1 $REMOTE $LOCAL
  fi ) &&
sed -i.orig 's,source \${0%/\*}/\.\.,source '$LOCAL',' $LOCAL/bin/realpath &&
mkdir -p $HOME/bin && {
	for file in $LOCAL/bin/*; do
		ln -s $LOCAL/bin/${file##*/} bin/ 2>/dev/null || true
	done
}
