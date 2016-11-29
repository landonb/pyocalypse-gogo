#!/bin/bash
# One developer's take on a project switcher.
#  vim:tw=0:ts=4:sw=4:et:ft=sh:

# USAGE:
#
#  In your .bashrc (or before you use this script), set
#
#    GOGO_CLIENT_DIR="/some/company/clients"
#
#  and then from Bash,
#
#    gogo client-name task-name
#
# or some variant thereof. Use <Tab>s to make Life Easier.

# -------------------------------------------------------------------------

# Walk up the path looking for a file with the matching name.
invursive_find () {

    FILEPATH=$1

    if [[ -z ${FILEPATH} ]]; then
        echo "ERROR: Please specify a file."
        return 1
    fi

    FILENAME=$(basename ${FILEPATH})
    DIRPATH=$(dirname ${FILEPATH})

    # Deal only in full paths.
    # Symlinks okay (hence not pwd -P or readlink -f).
    pushd ${DIRPATH} &> /dev/null
    DIRPATH=$(pwd)
    popd &> /dev/null

    INVURSIVE_PATH=""
    # We don't return things from file system root. Because safer?
    while [[ ${DIRPATH} != '/' ]]; do
        if [[ -f ${DIRPATH}/${FILENAME} ]]; then
            #echo "DIRPATH: ${DIRPATH}"
            #echo "FILENAME: ${FILENAME}"
            INVURSIVE_PATH="${DIRPATH}/${FILENAME}"
            break
        fi
        DIRPATH=$(dirname ${DIRPATH})
    done

    #echo "INVURSIVE_PATH: ${INVURSIVE_PATH}"
}

# HOW IT WORKS:
#
#   Suppose you have client code for a task under the directory,
#
#       /company/clients/partner/partner-76
#
#   Run the command
#
#       gogo partner 76
#
#   to pushd to the task directory.
#
#   The function will also symlink ~/.exoline if it
#     finds one there, or in the parent directory.
#
#   And it'll source any .bashrc-partner it finds.
#
# HINT:
#
#   Use tab completion to make this simple. E.g.,
#
#       gog<TAB>par<TAB>76
#
#   Will resolve (for the author) to
#
#       gogo partner partner-76
#
#   Tab completion uses the directory names found under
#
#       /company/clients
#
#   and for tasks, tab completion use any directory under
#
#       /company/clients/<client>/
#
#   that starts with <client>-.

gogo () {
    CLIENT=$1
    SUBDIR=$2

    if [[ -z ${CLIENT} ]]; then
        >&2 echo "USAGE: gogo client subdir"
        return 1
    fi

    CLIENT_DIR="${GOGO_CLIENT_DIR}/${CLIENT}"

    if [[ -n ${SUBDIR} ]]; then
        # You can either specify the subdir name completely, or, if
        # it shares a prefix with the client name, you can skip the
        # prefix. E.g., for "task/task-76", "76" or "task-76" works.
        TARGET_DIR="${CLIENT_DIR}/${CLIENT}-${SUBDIR}"
        if [[ ! -d ${TARGET_DIR} ]]; then
            TARGET_DIR="${CLIENT_DIR}/${SUBDIR}"
            if [[ ! -d ${TARGET_DIR} ]]; then
                >&2 echo "ERROR: Could not find ticket dir under: ${CLIENT_DIR}"
                return 1
            fi
        fi
        CLIENT_DIR=$(dirname ${TARGET_DIR})
    else
        TARGET_DIR="${CLIENT_DIR}"
    fi

    if [[ ! -d ${CLIENT_DIR} ]]; then
        >&2 echo "ERROR: Could not find client dir at: ${CLIENT_DIR}"
        return 1
    fi

    # Load a bashrc, maybe.
    invursive_find "${CLIENT_DIR}/.bashrc-${CLIENT}"
    if [[ -f ${INVURSIVE_PATH} ]]; then
        source ${INVURSIVE_PATH}
        echo "Sourced ${INVURSIVE_PATH}"
    else
        : # Meh.
        #echo "No .bashrc under: "${CLIENT_DIR}/.bashrc-${CLIENT}""
        #echo "or at: ${INVURSIVE_PATH}"
    fi

    # Rewire ~/.exoline for the project, maybe.
    invursive_find "${CLIENT_DIR}/.exoline"
    if [[ -f ${INVURSIVE_PATH} ]]; then
        if [[ ! -h ${HOME}/.exoline ]]; then
            >&2 echo "OOPS: Your ~/.exoline is not a symlink. Not replacing."
        else
            /bin/ln -sf ${INVURSIVE_PATH} ${HOME}/.exoline
            >&2 echo "Symlinked ~/.exoline"
        fi
    else
        >&2 echo "Skipping ~/.exoline symlink: no replacement found."
    fi

    pushd ${TARGET_DIR} &> /dev/null

    echo "Entered ${TARGET_DIR}"
}

if [[ "$0" == "$BASH_SOURCE" ]]; then
    # Only call gogo if this script is being run and not sourced.
    # Ideally, you'll want to source the script and run gogo as
    # a function so that the `source` command above sticks.
    gogo $*
fi

