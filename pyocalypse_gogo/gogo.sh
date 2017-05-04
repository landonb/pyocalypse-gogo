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
# or some variant thereof.
#
# FEATURES:
#
#  Use <Tab>s to make Life Easier.
#
#    Pressing <Tab> will suggest client and task names.
#
#  Bash script sourcing.
#
#    gogo sources .bashrc-{{client-name}}, if found invursively;
#
#    gogo wires the first {{.exoline}} if finds invursively;

# -------------------------------------------------------------------------

# Walk up the path looking for a file with the matching name.
invursive_find () {

    local filepath=$1

    if [[ -z ${filepath} ]]; then
        echo "ERROR: Please specify a file."
        return 1
    fi

    local filename=$(basename ${filepath})
    local dirpath=$(dirname ${filepath})

    # Deal only in full paths.
    # Symlinks okay (hence not pwd -P or readlink -f).
    pushd ${dirpath} &> /dev/null
    dirpath=$(pwd)
    popd &> /dev/null

    INVURSIVE_PATH=""
    # We don't return things from file system root. Because safer?
    while [[ ${dirpath} != '/' ]]; do
        if [[ -f ${dirpath}/${filename} ]]; then
            #echo "dirpath: ${dirpath}"
            #echo "filename: ${filename}"
            INVURSIVE_PATH="${dirpath}/${filename}"
            break
        fi
        dirpath=$(dirname ${dirpath})
    done

    # Here's how chruby/auto.sh does the same:
    #   local dir="$PWD/"
    #   until [[ -z "$dir" ]]; do
    #       dir="${dir%/*}"
    #       if ... fi
    #   done

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
    local client=$1
    local subdir=$2

    if [[ -z ${client} ]]; then
        >&2 echo "USAGE: gogo client subdir"
        return 1
    fi

    local client_dir="${GOGO_CLIENT_DIR}/${client}"

    local target_dir=""
    if [[ -n ${subdir} ]]; then
        # You can either specify the subdir name completely, or, if
        # it shares a prefix with the client name, you can skip the
        # prefix. E.g., for "task/task-76", "76" or "task-76" works.
        target_dir="${client_dir}/${client}-${subdir}"
        if [[ ! -d ${target_dir} ]]; then
            target_dir="${client_dir}/${subdir}"
            if [[ ! -d ${target_dir} ]]; then
                >&2 echo "ERROR: Could not find ticket dir (${target_dir}) under: ${client_dir}"
                return 1
            fi
        fi
        client_dir=$(dirname ${target_dir})
    else
        target_dir="${client_dir}"
    fi

    if [[ ! -d ${client_dir} ]]; then
        >&2 echo "ERROR: Could not find client dir at: ${client_dir}"
        return 1
    fi

    # Load a bashrc, maybe.
    invursive_find "${target_dir}/.bashrc-${client}"
    if [[ -f ${INVURSIVE_PATH} ]]; then
        source ${INVURSIVE_PATH}
        echo "Sourced ${INVURSIVE_PATH}"
    else
        : # Meh.
        #echo "No .bashrc under: "${client_dir}/.bashrc-${client}""
        #echo "or at: ${INVURSIVE_PATH}"
    fi
    unset INVURSIVE_PATH

    # Rewire ~/.exoline for the project, maybe.
    invursive_find "${target_dir}/.exoline"
    if [[ -f ${INVURSIVE_PATH} ]]; then
        if [[ ! -h ${HOME}/.exoline ]]; then
            >&2 echo "WHOA: Your ~/.exoline is not a symlink. Not replacing."
        else
            /bin/ln -sf ${INVURSIVE_PATH} ${HOME}/.exoline
            >&2 echo -e "- ${HOTPINK}Symlnkd${font_normal_bash} ~/.exoline"
        fi
    #else
    #    >&2 echo "Skipping ~/.exoline symlink: no replacement found."
    fi
    unset INVURSIVE_PATH

    # 2017-05-03: Party all the time.
    # E.g.,
    #   echo "ruby-2.3" > .ruby-version
    invursive_find "${target_dir}/.ruby-version"
    if [[ -f ${INVURSIVE_PATH} ]]; then
        local ruby_vers=""
        if { read -r ruby_vers < "${INVURSIVE_PATH}"; } 2>/dev/null; then
            if [[ -n "${ruby_vers}" ]]; then
                chruby "${ruby_vers}"
                >&2 echo -e "- ${HOTPINK}Patched${font_normal_bash} ${ruby_vers}"
            else
                >&2 echo "WARNING: .ruby-version specified but empty"
            fi
        fi
    fi
    unset INVURSIVE_PATH

    pushd ${target_dir} &> /dev/null

    echo "Entered ${TARGET_DIR}"
}

if [[ "$0" == "$BASH_SOURCE" ]]; then
    # Only call gogo if this script is being run and not sourced.
    # Ideally, you'll want to source the script and run gogo as
    # a function so that the `source` command above sticks.
    gogo $*
fi

