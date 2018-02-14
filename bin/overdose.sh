#!/bin/sh

SELF=$(realpath $0)
PATH=$PATH:${SELF%/*}
source ${SELF%/*}/../lib/xzh.sh

_x_extend _od_compose

: ${OD_DOCKERDIR:=.}
: ${OD_SH:=zsh bash}

DOCKER=docker
COMPOSE=docker-compose
SHELLS=$(echo $OD_SH | awk -v RS=" " -v ORS="" '{ print "if which", $1, ">/dev/null 2>&1; then", $1 "; el" } END { print "se sh; fi" }')

_od_docker() {
	test -n "$DRYRUN" &&
	echo $DOCKER "$@" >&2 &&
	return

	$DOCKER "$@"
}

_od_compose() {
	test -n "$DRYRUN" &&
	( echo "cd $OD_DOCKERDIR &&"
	  echo $COMPOSE "$@" ) >&2 &&
	return

	cd $OD_DOCKERDIR &&
	$COMPOSE "$@"
	status=$?
	cd - >/dev/null
	return $status
}

_od_exec() {
	_x_min_args 1 $#

	local container=$1
	shift

	if test $# -eq 0; then
		_od_compose exec $exec_USER $container sh -c "$SHELLS"
		return
	fi

	if _x_is_piped_in; then
		container=$(_od_compose ps -q $container | head -1)
		_od_docker exec $exec_DETACHED $exec_USER -i $container "$@"
	else
		_od_compose exec $exec_DETACHED $exec_USER $container "$@"
	fi
}

_od_shell() {
	_od_exec $1
}

_od_services() {
	_od_compose config --services
}

_opts() {
	echo D:np:
}

_opt_D() {
	OD_DOCKERDIR="$@"
}

_opt_n() {
	DRYRUN=1
}

_opt_p() {
	_x_use "$@"
}

_cmd_shell() {
	_od_shell $1
}

_alias_sh() {
	echo shell
}

_cmd_exec() {
	_x_min_args 2 $#
	_od_exec "$@"
}

_alias_x() {
	echo exec
}

_opts_exec() {
	echo du:
}

_opt_exec_d() {
	exec_DETACHED=-d
}

_opt_exec_u() {
	exec_USER="--user $@"
}

_cmd_services() {
	_od_services
}

_x_add_opt "-D DOCKERDIR" \
	"Home to docker-compose.yml [$(realpath $OD_DOCKERDIR)]"
_x_add_opt "-n" \
	"Show commands without executing them"
_x_add_opt "-p NAMESPACE:PLUGIN" \
	"Map commands in file PLUGIN to NAMESPACE (can be used multiple times)"

_x_add_cmd "help" \
	"List docker-compose(1) commands"
_x_add_cmd "shell|sh CONTAINER" \
	"Log into a running container"
_x_add_cmd "exec|x [-d] [-u USER] CONTAINER COMMAND [ARGS]" \
	"Execute a command inside a container;;\
-d Run command in the background;;\
-u Username or UID"
_x_add_cmd "services" \
	"List services"

_x_run_cmd "$@"
