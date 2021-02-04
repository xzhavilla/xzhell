#!/bin/sh

_x_namespace node

: ${NODE_GUESTDIR:=.}

NODE_HINT=package.json
NODE_NPM=npm
NODE_YARN=yarn

_node_container() {
	echo Searching for Node container... >&2

	for service in $(_od_services); do
		_od_exec $service test -e $NODE_GUESTDIR/$NODE_HINT 2>/dev/null &&
		echo $service &&
		break
	done
}

_node_exec() {
	_od_exec ${NODE_CONTAINER:-$(_node_container)} "$@"
}

_node_npm() {
	_node_exec $NODE_NPM "$@"
}

_node_yarn() {
	_node_exec $NODE_YARN "$@"
}

node_opts=$(_opts)
_opts() {
	echo N:$node_opts
}

_opt_N() {
	NODE_CONTAINER=$1
}

_cmd_node_shell() {
	_od_shell ${1:-${NODE_CONTAINER:-$(_node_container)}}
}

_alias_node_sh() {
	echo node_shell
}

_opts_node_shell() {
	echo "u:"
}

_opt_node_shell_u() {
	_opt_exec_u "$@"
}

_cmd_node_exec() {
	_node_exec "$@"
}

_alias_node_x() {
	echo node_exec
}

_opts_node_exec() {
	echo "c:du:"
}

_opt_node_exec_c() {
	node_exec_CONTAINER="$@"
}

_opt_node_exec_d() {
	_opt_exec_d "$@"
}

_opt_node_exec_u() {
	_opt_exec_u "$@"
}

_cmd_node_npm() {
	_node_npm "$@"
}

_cmd_node_yarn() {
	_node_yarn "$@"
}

_x_add_opt "-N CONTAINER" \
	"Docker container running Node [${NODE_CONTAINER:-auto}]"

_x_add_cmd "${_x_ns}shell|${_x_ns}sh [-u USER] [CONTAINER]" \
	"Log into a container [${NODE_CONTAINER:-"Node's"}];;\
-u Username or UID"
_x_add_cmd "${_x_ns}execute|${_x_ns}x [-d] [-c CONTAINER] [-u USER] COMMAND [ARGS]" \
	"Execute a command inside a container [${NODE_CONTAINER:-"Node's"}];;\
-c Choose a different container;;\
-d Run command in the background;;\
-u Username or UID"
_x_add_cmd "${_x_ns}npm [COMMAND [ARGS]]" \
	"Run NPM into Node container"
_x_add_cmd "${_x_ns}yarn [COMMAND [ARGS]]" \
	"Run Yarn into Node container"
