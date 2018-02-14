#!/bin/sh

SELF=$(realpath $0)
PATH=$PATH:${SELF%/*}
source ${SELF%/*}/../lib/xzh.sh

_cmd_update() {
	${SELF%/*}/../tools/update.sh
}

_x_add_cmd "update" \
	"Update xzhell"

_x_run_cmd "$@"