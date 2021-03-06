#!/bin/sh

SELF=$(realpath $0)
PATH=$PATH:${SELF%/*}
. ${SELF%/*}/../lib/xzh.sh

_x_extend _od_compose

: ${OD_DOCKERDIR:=.}
: ${OD_SH:=zsh bash}

DOCKER=docker
COMPOSE=docker-compose
K8S=kubectl
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

_od_k8s() {
	test -n "$DRYRUN" &&
	echo $K8S -n "$k8s_NS" "$@" >&2 &&
	return

	$K8S -n "$k8s_NS" "$@"
}

_od_pod() {
	test -z $k8s_POD ||
	return 0

	_x_min_args 1 $#

	local namespace=${1%/*} pod=${1#*/} pods npods
	test "$namespace" = "$pod" && namespace=

	test -n "$DRYRUN" &&
	k8s_NS='$namespace' &&
	k8s_POD='$pod' &&
	return

	: ${k8s_NS:=${namespace:-$(_od_k8s config view --minify | awk '/namespace/ { print $2 }')}}
	printf 'Searching for pod "%s" in namespace "%s"... ' "$pod" "$k8s_NS" >&2
	pods=$(_od_k8s get pods --no-headers | grep "^$pod" | cut -d " " -f 1) >&2
	npods=$(echo "$pods" | grep -c .)

	test $npods -lt 1 &&
	echo >&2 && _x_yell pod not found &&
	return 1

	test "$npods" -gt 1 &&
	echo >&2 && _x_yell too many pods: $(echo $pods) &&
	return 1

	k8s_POD=$pods
	printf "\b\b\b\b: %s\n" "$k8s_POD" >&2
}

_od_exec() {
	_x_min_args 1 $#

	if ! test -z $OD_K8SPOD; then
		_od_kexec "$OD_K8SPOD" "$@"
		return $?
	fi

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

_od_kexec() {
	_x_min_args 2 $#

	local pod=$1 container=$2
	shift 2

	_od_pod $pod || _x_die

	if test $# -eq 0; then
		_od_k8s exec $k8s_POD -it -c $container -- sh -c "$SHELLS"
		return
	fi

	if _x_is_piped_in; then
		_od_k8s exec $k8s_POD -i -c $container -- "$@"
	else
		_od_k8s exec $k8s_POD -it -c $container -- "$@"
	fi
}

_od_shell() {
	_od_exec $1
}

_od_services() {
	if ! test -z $OD_K8SPOD; then
		_od_pod "$OD_K8SPOD" || _x_die
		_od_k8s get pod "$k8s_POD" -o jsonpath="{.spec.containers[*].name}" | awk -v RS=" " '{ print }'
		return $?
	fi

	_od_compose config --services
}

_opts() {
	echo D:K:np:
}

_opt_D() {
	OD_DOCKERDIR="$@"
}

_opt_K() {
	OD_K8SPOD="$@"
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

_opts_shell() {
	echo u:
}

_opt_shell_u() {
	_opt_exec_u "$@"
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
	"Home to docker-compose.yaml [$(realpath $OD_DOCKERDIR)]"
_x_add_opt "-K [NAMESPACE/]K8SPOD" \
	"Optional Kubernetes pod to interact with [${OD_K8SPOD:-none}]"
_x_add_opt "-n" \
	"Show commands without executing them"
_x_add_opt "-p [NAMESPACE:]PLUGIN" \
	"Map commands in file PLUGIN to NAMESPACE (can be used multiple times)"

_x_add_cmd "help" \
	"List Docker Compose commands"
_x_add_cmd "shell|sh [-u USER] CONTAINER" \
	"Log into a running container;;\
-u Username or UID"
_x_add_cmd "exec|x [-d] [-u USER] CONTAINER COMMAND [ARGS]" \
	"Execute a command inside a container;;\
-d Run command in the background;;\
-u Username or UID"
_x_add_cmd "services" \
	"List services"

_x_run_cmd "$@"
