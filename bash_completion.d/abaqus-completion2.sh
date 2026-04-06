# shellcheck shell=bash
# bash completion for abaqus

# Remove already‑used options from the list
_remove_used_params() {
    local used
    used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^([a-z]|-|--)' | tr '\n' ' ')
    COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
}


_QUEUE_LIST_CACHE=""

_get_queue_list() {
    local queues
    queues=""

    if [[ -n "$_QUEUE_LIST_CACHE" ]]; then
        echo "$_QUEUE_LIST_CACHE"
        return
    fi

    command -v scontrol > /dev/null && queues="$(scontrol -o show partitions | grep -Po 'PartitionName=\S+' | cut -d'=' -f2 | tr '\n' ' ')"
    [[ -z "$queues" ]] && queues="small short big"
    
    _QUEUE_LIST_CACHE=$queue

    COMPREPLY=( $(compgen -W "help hold $queues" -- "$cur") )
}


# Global cache for abaqus help output
_ABAQUS_HELP_CACHE=""

# Helper: Convert multi-line help file or abaqus help command output into single-line command blocks
# Removes section headers and collapses continuation lines
# If no file argument is provided, uses cached output from 'abaqus help' command
_clean_help_file() {

    local help_content

    # Check if we have cached help content
    if [[ -z "$_ABAQUS_HELP_CACHE" ]]; then
        # Cache is empty, fetch from abaqus help command
        _ABAQUS_HELP_CACHE=$(abaqus help 2>/dev/null)
        if [[ $? -ne 0 || -z "$_ABAQUS_HELP_CACHE" ]]; then
            echo "Error: Could not get help from 'abaqus help' command" >&2
            return 1
        fi
    fi
    help_content="$_ABAQUS_HELP_CACHE"

    
    # Strategy:
    # 1. Find each "abaqus command" block
    # 2. Collapse multi-line block into single line
    # 3. Preserve all structure (brackets, pipes, equals, braces)
    # 4. Handle special curly brace format: {cmd1 | cmd2=... | cmd3}
    echo "$help_content" | \
    grep -v -E '^[[:space:]]{0,2}[A-Z]' | \
    tr '\n' ' ' | \
    sed 's/[[:space:]]*\[=/\[=/g' | \
    sed 's/ abaqus /\nabaqus /g' | \
    # Handle special curly brace format {help | information={...} | whereami}
    # Converts to separate "abaqus command" lines for each option
    sed 's/abaqus[[:space:]]\+{[[:space:]]*\([a-z]*\)[[:space:]]*|[[:space:]]*\([a-z_]*\)=[{][^}]*[}][^|]*|[[:space:]]*\([a-z]*\)[[:space:]]*}/abaqus \1\nabaqus \2=\nabaqus \3/g' | \
    tr -s ' ' # Trim and normalize
}

# Function 1: Get all top-level Abaqus commands
# Returns a list of all available Abaqus command names
_get_all_abaqus_commands() {

    # Extract command names from cleaned help file
    # Get the first token after "abaqus", handling "command=parameter" and "command[=parameter]" formats
    _clean_help_file | \
    sed 's/^abaqus\s\+//' | \
    awk '{
        # Extract first token (word characters and underscores)
        match($0, /[a-zA-Z_][a-zA-Z0-9_]*/)
        if (RSTART > 0) {
            cmd = substr($0, RSTART, RLENGTH)
            next_char_pos = RSTART + RLENGTH
            next_char = substr($0, next_char_pos, 1)
            next_two = substr($0, next_char_pos, 2)
            
            # Check if followed by = or [=
            if (next_char == "=" || next_two == "[=") {
                cmd = cmd "="
            }
            if (cmd != "") print cmd
        }
    }' | \
    sort -u
}

# Function 1b: Get all Abaqus commands with = sign prefixed by dash
# Returns command names, where commands accepting parameters are prefixed with '-'
# Example: job= becomes -job, cae stays cae
_get_all_abaqus_commands_with_dashes() {
    
    _get_all_abaqus_commands | while read -r cmd; do
        if [[ "$cmd" == *"=" ]]; then
            # Remove trailing = and add dash prefix
            echo "-${cmd%=}"
        else
            # Keep command as is
            echo "$cmd"
        fi
    done
}

# Function 2: Get all suboptions for a specific command
# Accepts a command name and returns all available parameters/options
# Extracts both parameter=value and keyword-only options
_get_suboptions() {
    local command="$1"
    
    if [[ -z "$command" ]]; then
        echo "Error: Command name required" >&2
        return 1
    fi
    
    # Remove trailing = sign and leading dash if present (since commands may now include them)
    command="${command#-}"
    command="${command%=}"
    
    # Get the command block from cleaned help file (single line) 
    local cmd_block=$(_clean_help_file | \
        grep -E "^abaqus\s+${command}(\s|=|\{|\[)" | \
        head -1)
    
    if [[ -z "$cmd_block" ]]; then
        return 1
    fi
    
    # Extract parameter names followed by '=' or '[='
    # Handles: word=value and word[=optional-value]
    local params=$(echo "$cmd_block" | sed 's/\[=/=/g; s/ = /=/g' | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*\[?=' )
    
    # Extract keyword options from bracket patterns
    # Part 1: alternatives with pipes like [opt1 | opt2], can include nested brackets
    local keywords=$(
        # Extract alternative options in brackets
        echo "$cmd_block" | \
        grep -oE '\[[^]]*\|[^]]*\]' | \
        sed 's/\[//g; s/\]//g; s/={[^}]*}//g; s/\[=[^]]*\]//g' | \
        tr '|' '\n' | \
        sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
        grep -E '^[a-zA-Z_][a-zA-Z0-9_]*$'
        
        # Part 2: standalone bracket keywords like [uniquelibs] or [noFlexBody]
        echo "$cmd_block" | \
        grep -oE '\[[a-zA-Z_][a-zA-Z0-9_]*\]' | \
        sed 's/\[//g; s/\]//g' | \
        grep -E '^[a-zA-Z_]'
    )

    # Filter out keywords that match parameter base names (to avoid duplicates like convert and convert=)
    # Using comm to cleanly remove keywords whose base name appears in params
    local param_bases=$(echo "$params" | sed 's/=//g' | tr ' ' '\n' | sort -u)
    keywords=$(comm -13 <(echo "$param_bases") <(echo "$keywords" | sort -u))

    # Combine and deduplicate
    {
        echo "$params"
        echo "$keywords"
    } | \
    sort -u | \
    grep -vE '^(all|off|on|both|yes|no|the|a|of|in|or|after|time)$' | \
    xargs
}


# Function 2b: Get all suboptions for a specific command with = sign prefixed by dash
# Returns suboptions where options accepting parameters are prefixed with '-'
# Example: memory= becomes -memory, background stays background
_get_suboptions_with_dashes() {
    local command="$1"
    
    local options=$(_get_suboptions "$command")

    if [[ -z "$options" ]]; then
        return 1
    fi
    
    # Convert each option: if it ends with =, remove = and add dash prefix
    echo "$options" | tr ' ' '\n' | while read -r opt; do
        if [[ "$opt" == *"=" ]]; then
            # Remove trailing = and add dash prefix
            echo "-${opt%=}"
        else
            # Keep option as is
            echo "$opt"
        fi
    done | xargs
}


_abaqus_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Main subcommands
    local subcommands
    subcommands=$( _get_all_abaqus_commands_with_dashes )


    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$subcommands" -- "$cur") )
        return 0
    fi

    local _sub_opts=$(_get_suboptions_with_dashes "${COMP_WORDS[1]}")
    #echo "Debug: prev='$prev', sub_opts='$_sub_opts', cur='$cur', cword=$cword, ${COMP_WORDS[1]}" >&2

    case "$prev" in
        -job|-input)
            COMPREPLY=( $(compgen -f -X '!*.inp' -- "$cur") )
            return 0
            ;; 
        -user)
            COMPREPLY=( $(compgen -f -- "$cur" | grep -E "\.f$|\.c$|\.o$" ) )
            return 0
            ;;
        -fil)
            COMPREPLY=( $(compgen -W "append new" -- "$cur") )
            return 0
            ;;
        -globalmodel)
            COMPREPLY=( $(compgen -f -- "$cur" | grep -E "\.odb$|\.sim$" ) )
            return 0
            ;;
        -cpus)
            COMPREPLY=( $(compgen -W "4 8 16 24 32 48" -- "$cur") )
            return 0
            ;;
        -domains|-port|-timeout)
            COMPREPLY=( $(compgen -W "1 2 4 8 16 32 64" -- "$cur") )
            return 0
            ;;
        -gpus)
            COMPREPLY=( $(compgen -W "1 2" -- "$cur") )
            return 0
            ;;
        -memory)
            COMPREPLY=( $(compgen -W "16000mb 32000mb 64000mb 128000mb" -- "$cur") )
            return 0
            ;;
        -parallel)
            COMPREPLY=( $(compgen -W "domain loop" -- "$cur") )
            return 0
            ;;
        -mp_mode)
            COMPREPLY=( $(compgen -W "mpi threads" -- "$cur") )
            return 0
            ;;
        -standard_parallel)
            COMPREPLY=( $(compgen -W "all solver" -- "$cur") )
            return 0
            ;;
        -double)
            COMPREPLY=( $(compgen -W "explicit both off constraint" -- "$cur") )
            return 0
            ;;
        -output_precision)
            COMPREPLY=( $(compgen -W "single full" -- "$cur") )
            return 0
            ;;
        -resultsformat)
            COMPREPLY=( $(compgen -W "odb sim both" -- "$cur") )
            return 0
            ;;
        -field)
            COMPREPLY=( $(compgen -W "odb sim" -- "$cur") )
            return 0
            ;;
        -history)
            COMPREPLY=( $(compgen -W "odb sim csv" -- "$cur") )
            return 0
            ;;
        -unconnected_regions)
            COMPREPLY=( $(compgen -W "yes no" -- "$cur") )
            return 0
            ;;
        -convert)
            COMPREPLY=( $(compgen -W "select odb state all" -- "$cur") )
            return 0
            ;;
        -queue)
            _get_queue_list
            return 0
            ;;
 
        -database|-odb|-restartodb|-newjob|-originalodb|-oldjob)
            COMPREPLY=( $( compgen -f -X '!*.odb' -- "$cur") )
            return 0
            ;;

        # cae and viewer options
        -recover)
            COMPREPLY=( $(compgen -f -X '!*.jnl' -- "$cur") )
            return 0
            ;;
        -replay|-startup|-script|-custom|-guiTester)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0
            ;;
        -noGUI)
            COMPREPLY=( $(compgen -f -X '!*.py' -- "$cur") )
            return 0
            ;;

        # optimization options
        -task)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0
            ;;
        -job)
            COMPREPLY=( $(compgen -d -- "$cur") )
            return 0
            ;;
        -scratch|-directory|-outdir)
            COMPREPLY=( $(compgen -d -- "$cur") )
            return 0
            ;;
 
        # Python options
        -sim)
            COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
            return 0
            ;;

        # ascfil and append options
        -job|-oldjob)
            COMPREPLY=( $(compgen -f -X '!*.fil' -- "$cur") )
            return 0
            ;;

        # findkeyword and fetch options
        -maximum)
            COMPREPLY=( $(compgen -W "10 20 40" -- "$cur") )
            return 0
            ;;

        # make or job options
        -library|-user)
            COMPREPLY=( $(compgen -f -- "$cur" | grep -E "\.f$|\.f90$|\.c$|\.cpp$|\.o$" ) )
            return 0
            ;;
        -object_type)
            COMPREPLY=( $(compgen -W "fortran c cpp" -- "$cur") )
            return 0
            ;;

        # redistadb options
        -increment)
            COMPREPLY=( $(compgen -W "1 2 3" -- "$cur") )
            return 0
            ;;
        -copyfiles|-list)
            COMPREPLY=( $(compgen -W "yes" -- "$cur") )
            return 0
            ;;

        # odb2sim options
        -o2sdebug)
            COMPREPLY=( $(compgen -W "0 1 2" -- "$cur") )
            return 0
            ;;
        
        # sim_version options
        -convert)
            COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
            return 0
            ;;
        -query|-out)
            COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
            return 0
            ;;
        -level)
            COMPREPLY=( $(compgen -W 'V6R2022x V6R2023 xV6R2024x' -- "$cur") )
            return 0
            ;;

        # odbreport options
        -step)
            COMPREPLY=( $(compgen -W "__LAST__" -- "$cur") )
            return 0
            ;;
        -frame)
            COMPREPLY=( $(compgen -W "__LAST__" -- "$cur") )
            return 0
            ;;

        # fromnastran options
        -input)
            COMPREPLY=( $(compgen -f -- "$cur" | grep -E "\.bdf$|\.nas$|\.dat$" ) )
            return 0
            ;;
        -wtmass_fixup|-loadcases|-surface_based_coupling|-beam_offset_coupling|-beam_orientation_vector|-plotel)
            COMPREPLY=( $(compgen -W "ON OFF" -- "$cur") )
            return 0
            ;;
        -pbar_zero_reset)
            COMPREPLY=( )
            return 0
            ;;
        -cbar)
            COMPREPLY=( $(compgen -W "B31 B33" -- "$cur") )
            return 0
            ;;
        -cquad4)
            COMPREPLY=( $(compgen -W "S4R S4 S4R5" -- "$cur") )
            return 0
            ;;
        -chexa)
            COMPREPLY=( $(compgen -W "C3D8I C3D8R" -- "$cur") )
            return 0
            ;;
        -ctetra)
            COMPREPLY=( $(compgen -W "C3D10 C3D10M" -- "$cur") )
            return 0
            ;;
        -cpyram)
            COMPREPLY=( $(compgen -W "C3D5" -- "$cur") )
            return 0
            ;;
        -cshear)
            COMPREPLY=( $(compgen -W "UEL SHEAR4" -- "$cur") )
            return 0
            ;;
        -cdh_weld)
            COMPREPLY=( $(compgen -W "OFF RIGID COMPLIANT" -- "$cur") )
            return 0
            ;;
        -dmig2sim)
            COMPREPLY=( $(compgen -W "GENERIC SUBSTRUCTURE" -- "$cur") )
            return 0
            ;;
        -op2file1|-op2file2)
            COMPREPLY=( $(compgen -f -X "!*.op2" -- "$cur") )
            return 0
            ;;
        -op2target)
            COMPREPLY=( $(compgen -W "INPUT GENERIC SUBSTRUCTURE" -- "$cur") )
            return 0
            ;;
    esac

    #local _sub_opts=$(_get_suboptions_with_dashes "$prev")
    COMPREPLY=( $(compgen -W "$_sub_opts" -- "$cur") )
    _remove_used_params
}

complete -F _abaqus_completion abq2024 abq2023 abq2022 abaqus
