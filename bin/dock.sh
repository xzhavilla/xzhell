#!/bin/sh

SELF=$(realpath $0)
PATH=$PATH:${SELF%/*}
. ${SELF%/*}/../lib/xzh.sh

: ${PG_SH:=zsh bash}

DOCKER=docker
SHELLS=$(echo $PG_SH | awk -v RS=" " -v ORS="" '{ print "if which", $1, ">/dev/null 2>&1; then", $1 "; el" } END { print "se sh; fi" }')

_docker() {
	test -n "$DRYRUN" &&
	echo $DOCKER "$@" >&2 &&
	return

	$DOCKER "$@"
}

_opts() {
	echo Cnv:
}

_opt_C() {
	NOCLEAN=1
}

_opt_n() {
	DRYRUN=1
}

_opt_v() {
	OPTS="$OPTS -v $@"
}

_cmd() {
	_x_min_args 1 $#

	IMAGE=${1%/}
	shift

	test -d "$IMAGE" &&
	TAG=${IMAGE##*/}:$(date +%s) ||
	TAG=$IMAGE

	if [ -d "$IMAGE" ]; then
		_docker build -t $TAG --rm $IMAGE || _x_die
	fi

	CMD=${@:-$SHELLS}

	_docker run -it $OPTS --rm $TAG sh -c "$CMD"
	test -n "$NOCLEAN" || _docker rmi -f $TAG
}

_usage() {
	echo usage: $(_x_self) [OPTIONS] IMAGE [COMMAND [ARGS]]
}

_x_add_opt "-C" \
	"Do not remove the image"
_x_add_opt "-n" \
	"Show commands without executing them"
_x_add_opt "-v [SOURCE:]TARGET[:OPTIONS]" \
	"Bind mount a volume (can be used multiple times)"

_x_run "$@"
