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

source_deps () {
    source 'fries-findup' || \
        ( \
            echo "Missing dependency: github.com/landonb/fries-findup" \
            && return 1 \
        )
}

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
        client_dir=$(dirname -- "${target_dir}")
    else
        target_dir="${client_dir}"
    fi

    if [[ ! -d ${client_dir} ]]; then
        >&2 echo "ERROR: Could not find client dir at: ${client_dir}"
        return 1
    fi

    # 2017-05-03: Silly.
    local FONT_NORMAL="\033[0m"
    local FONT_BOLD="\033[1m"
    local FG_HOTPINK="\033[38;5;198m"
    local BG_FOREST="\\033[48;5;22m"
    local FG_LIME="\033[38;5;154m"

    echo -e "${FG_LIME}Preparing${FONT_NORMAL} ${target_dir}..."

    # Load a bashrc, maybe.
    local invursive_path=$(fries-findup "${target_dir}/.bashrc-${client}")
    if [[ -f ${invursive_path} ]]; then
        source ${invursive_path}
        echo -e "- ${FG_HOTPINK}Sourced${FONT_NORMAL} ${invursive_path}"
    else
        : # Meh.
        #echo "No .bashrc under: "${client_dir}/.bashrc-${client}""
        #echo "or at: ${invursive_path}"
    fi
    unset invursive_path

    # FIXME/2018-05-16: (lb): Remove this unrelated business logic!
    # Rewire ~/.exoline for the project, maybe.
    local invursive_path=$(fries-findup "${target_dir}/.exoline")
    if [[ -f ${invursive_path} ]]; then
        if [[ ! -h ${HOME}/.exoline ]]; then
            >&2 echo "WHOA: Your ~/.exoline is not a symlink. Not replacing."
        else
            /bin/ln -sf ${invursive_path} ${HOME}/.exoline
            >&2 echo -e "- ${FG_HOTPINK}Symlnkd${FONT_NORMAL} ~/.exoline"
        fi
    #else
    #    >&2 echo "Skipping ~/.exoline symlink: no replacement found."
    fi
    unset invursive_path

    # 2017-05-03: Party all the time.
    # E.g.,
    #   echo "ruby-2.3" > .ruby-version
    local invursive_path=$(fries-findup "${target_dir}/.ruby-version")
    if [[ -f ${invursive_path} ]]; then
        local ruby_vers=""
        if { read -r ruby_vers < "${invursive_path}"; } 2>/dev/null; then
            if [[ -n "${ruby_vers}" ]]; then
                chruby "${ruby_vers}"
                >&2 echo -e "- ${FG_HOTPINK}Patched${FONT_NORMAL} ${ruby_vers} [$(basename -- "${RUBY_ROOT}")]"
            else
                >&2 echo "WARNING: .ruby-version specified but empty"
            fi
        fi
    fi
    unset invursive_path

    # Exclude rvm errors, which are >&6 redirected, for some reason;
    #   rvm monkey patches both cd and pushd.
    # 2018-05-16: (lb): That first `&` is meaningless, isn't it?
    #pushd ${target_dir} &> /dev/null 6>&1
    pushd ${target_dir} > /dev/null 6>&1
    # MAYBE/2018-02-15: Resolve symlinks in path.
    # NOTE/2018-02-15: This resolves the final symlink, but not
    # earlier ones in path... weird.
    #cd -P ${target_dir} &> /dev/null
    #cd -P ${target_dir} &> /dev/null 6>&1
    # Maybe show errors, eh?
    cd -P ${target_dir}

    # Make an easy way to get back home!
    eval "
        ogog() {
            pushd ${target_dir} > /dev/null 6>&1
        }
    "
    export -f ogog

    echo -e "          ${FONT_BOLD}${target_dir}${FONT_NORMAL} ${FONT_BOLD}${BG_FOREST}is ready!${FONT_NORMAL}"
}

if [[ "$0" == "$BASH_SOURCE" ]]; then
    source_deps || exit
    # Only call gogo if this script is being run and not sourced.
    # Ideally, you'll want to source the script and run gogo as
    # a function so that the `source` command above sticks.
    gogo $*
else
    source_deps || return
fi

