#!/bin/bash

# Copyright (c) 2013 Takashi Oguma
# You may use tizen_bash_completion project under the terms of the MIT License.

# This file defines a compspec for 'sdb' command in _tizen_sdb() function

_sdb_options='-d -e -s'
_sdb_subcommands='devices connect disconnect push pull shell dlog install \
    uninstall forward help version start-server kill-server get-state \
    get-serialno status-window root'

function _sdb_get_subcommand()
{
    local subcmd
    if [[ ${COMP_WORDS[1]} == '-d' ]] || [[ ${COMP_WORDS[1]} == '-e' ]]; then
        subcmd=${COMP_WORDS[2]}
    elif [[ ${COMP_WORDS[1]} == '-s' ]]; then
        subcmd=${COMP_WORDS[3]}
    else
        subcmd=${COMP_WORDS[1]}
    fi

    printf -- "${subcmd}"
}

function _sdb_get_option()
{
    local option
    if [[ ${COMP_WORDS[1]} == -* ]]; then
        option=${COMP_WORDS[1]}
    fi

    printf -- "${option}"
}

function _sdb_get_serial()
{
    local serial
    if [[ ${COMP_WORDS[1]} == '-s' ]]; then
        serial="${COMP_WORDS[2]}"
    fi

    printf -- "${serial}"
}

function _sdb_get_target()
{
    local target
    if [[ ${COMP_WORDS[1]} == '-d' ]] || [[ ${COMP_WORDS[1]} == '-e' ]]; then
        target=${COMP_WORDS[1]}
    elif [[ ${COMP_WORDS[1]} == '-s' ]]; then
        target="${COMP_WORDS[1]} ${COMP_WORDS[2]}"
    fi

    printf -- "${target}"
}

function _sdb_source_specified()
{
    local option subcommand crr src

    option=${COMP_WORDS[1]}
    subcmd=`_sdb_get_subcommand`
    curr=`_get_cword`

    if [[ ${subcmd} == 'push' ]] || [[ ${subcmd} == 'pull' ]]; then
        if [[ ${option} == '-d' ]] || [[ ${option} == '-e' ]]; then
            src=${COMP_WORDS[3]}
        elif [[ ${option} == '-s' ]]; then
            src=${COMP_WORDS[4]}
        else
            src=${COMP_WORDS[2]}
        fi
    fi

    if [[ -n "${src}" ]] && [[ "${src}" != "${curr}" ]]; then
        return 0
    else
        return 1
    fi
}

function _sdb_get_target_file_list()
{
    local curr target cmd list

    curr=`_get_cword`
    target=`_sdb_get_target`
    cmd="ls -aF1dL ${curr}* | tr '\n' ' '"
    list=$(sdb ${target} shell "${cmd}" 2>&1 )

    printf -- "${list}"
}

function _tizen_sdb()
{
    local curr prev subcmd option serial target apps
    COMPREPLY=()
    curr=`_get_cword`
    prev=$3
    subcmd=`_sdb_get_subcommand`
    option=`_sdb_get_option`
    serial=`_sdb_get_serial`
    target=`_sdb_get_target`

    case "${subcmd}" in
        root)
            if [[ ${prev} != on ]] && [[ ${prev} != off ]]; then
                COMPREPLY=( $( compgen -W 'on off' -- ${curr} ) )
            fi
            ;;

        install)
            COMPREPLY=( $( compgen -f ? ${curr} ) )
            ;;

        uninstall)
            apps=$( sdb ${target} shell "ls -1 /opt/apps | tr '\n' ' '" 2>&1 )
            if [[ ${apps} == 'error: device not found' ]]; then
                COMPREPLY=()
            else 
                COMPREPLY=( $( compgen -W "${apps}" -- ${curr} ) )
            fi
            ;;

        push)
            if ! _sdb_source_specified; then
                COMPREPLY=( $( compgen -f ? ${curr} ) )
            else
                compopt -o nospace
                COMPREPLY=( $( compgen -W "$( _sdb_get_target_file_list )" -- ${curr} ) )
            fi
            ;;

        pull)
            if ! _sdb_source_specified; then
                compopt -o nospace
                COMPREPLY=( $( compgen -W "$( _sdb_get_target_file_list )" -- ${curr} ) )
            else
                COMPREPLY=( $( compgen -f ? ${curr} ) )
            fi
            ;;

        dlog)
            COMPREPLY=( $( compgen -W "-c -d" -- $curr ) )
            ;;
        *)
            if [[ "${curr}" == -* ]]; then
                COMPREPLY=( $( compgen -W "${_sdb_options}" -- "${curr}" ) )
            elif [[ "${option}" == -s* ]]; then
                if [[ "${serial}" == '' ]] || [[ "${serial}" == ${curr} ]]; then
                    COMPREPLY=( $( compgen -W "$( sdb devices | awk 'NR > 1 { print $1 }' )" -- $curr ) )
                else
                    COMPREPLY=( $( compgen -W "${_sdb_subcommands}" -- $curr ))
                fi
            elif [[ "${target}" == '' ]] && [[ "${subcmd}" == '' ]]; then
                COMPREPLY=( $( compgen -W "${_sdb_options} ${_sdb_subcommands}" -- $curr ))
            else
                COMPREPLY=( $( compgen -W "${_sdb_subcommands}" -- $curr ))
            fi
            ;;
    esac

    return 0
}

complete -F _tizen_sdb -o default sdb

