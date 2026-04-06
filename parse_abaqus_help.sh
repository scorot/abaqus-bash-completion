#!/bin/bash

#
# Functions to parse and extract Abaqus command options
# from abaqus_help.txt or abaqus help command output
#
# Strategy: Clean the help file first by removing section headers and descriptions,
# then collapse multi-line command blocks into single lines, preserving all structure.
# This captures options with/without '=', alternatives with '|', and values in brackets.
#
# Caching: The output from 'abaqus help' is cached to avoid repeated command execution.
#

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
    echo "$help_content" | \
    tail -n +8 | \
    grep -v -E '^[[:space:]]{0,2}[A-Z]' | \
    tr '\n' ' ' | \
    sed 's/[[:space:]]*\[=/\[=/g' | \
    sed 's/ abaqus /\nabaqus /g' | \
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
    local params=$(echo "$cmd_block" | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*\[?=' | sed 's/\[=/=/g' | sort -u)
    
    # Extract keyword options from bracket patterns
    # Part 1: alternatives with pipes like [opt1 | opt2], can include nested brackets
    local keywords=$(
        # Extract bracket groups containing pipes
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

# Function 2c: Get proposed values for a specific suboption of a command
# Accepts command name and suboption name, returns available values as space-separated string
# Handles: {option1|option2}, [option1|option2], file type indicators, keyword options
_get_suboption_values() {
    local command="$1"
    local suboption="$2"
    
    if [[ -z "$command" || -z "$suboption" ]]; then
        return 1
    fi
    
    # Remove trailing = sign and leading dash from suboption if present
    suboption="${suboption#-}"
    suboption="${suboption%=}"
    
    # Remove leading dash and trailing = from command if present
    command="${command#-}"
    command="${command%=}"
    
   
    # Get the command block from cleaned help file (single line) 
    local cmd_block=$(_clean_help_file | \
        grep -E "^abaqus\s+${command}(\s|=|\{|\[)" | \
        head -1)
    if [[ -z "$cmd_block" ]]; then
        return 1
    fi
    echo "Debug: Command block for '${command}': $cmd_block" >&2
    
    # Look for the suboption in the help content and extract its values
    # Pattern 1: option={value1|value2|...} - can span multiple lines
    # local values=$(echo "$cmd_block" | grep -oE "${suboption}=\{[^}]*\}" | sed "s/${suboption}={\(.*\)}/\1/")
    # echo  "Debug: Found values $values for pattern option={...} for suboption '${suboption}'" >&2
    # if [[ -n "$values" ]]; then
    #     # Convert pipe-separated values to space-separated and clean up
    #     echo "$values" | tr '|' ' ' | sed 's/[[:space:]]\+/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//'
    #     echo "Debug: Found values for pattern option={...} for suboption '${suboption}': $values" >&2
    #     return 0
    # fi
    # echo "Debug: No values found for pattern option={...} for suboption '${suboption}'" >&2
    
    # Pattern 2: option=[value1|value2|...] - alternatives in brackets with pipes, can span multiple lines
    values=$(echo "$cmd_block" | grep -oE "\[${suboption}[^\]]*\|[^\]]*\]" | sed 's/\[//g; s/\]//g; s/={[^}]*}//g')
    if [[ -n "$values" ]]; then
        # Extract values, remove option name, convert pipes to spaces
        echo "$values" | sed "s/${suboption}//g" | tr '|' ' ' | sed 's/[[:space:]]\+/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//'
        echo "Debug: Found values for pattern 2 option=[...] for suboption '${suboption}': $values" >&2
        return 0
    fi
    echo "Debug: No values found for pattern 2 option=[...] for suboption '${suboption}'" >&2
    
    # Pattern 3: Detect file type keywords and special indicators
    # Look for patterns like "input-file", "odb-file", "directory", etc.
    if echo "$cmd_block" | grep -qE "${suboption}.*input.?name"; then
        echo "input-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*input.?file"; then
        echo "input-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*odb.?file"; then
        echo "odb-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*odb.?name"; then
        echo "odb-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*directory"; then
        echo "directory"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*output.?file"; then
        echo "output-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*python.?file"; then
        echo "python-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*journal.?file"; then
        echo "journal-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*sim.?file"; then
        echo "sim-file"
        return 0
    fi
    if echo "$cmd_block" | grep -qE "${suboption}.*op2.?file"; then
        echo "op2-file"
        return 0
    fi
    
    # Pattern 4: Standalone bracket keywords like [uniquelibs]
    values=$(echo "$cmd_block" | grep -oE "\[${suboption}\]" | sed 's/\[//g; s/\]//g')
    if [[ -n "$values" ]]; then
        echo "$values"
        return 0
    fi
    
    # No values found
    return 1
}

# Helper function to clear the abaqus help cache
_clear_help_cache() {
    _ABAQUS_HELP_CACHE=""
}

# Helper function to display command info
_show_command_info() {
    local command="$1"
    local help_file="${2:-}"
    
    echo "Command: $command"
    echo "Options: $(_get_suboptions "$command" "$help_file")"
}

# Function 3: Check if a command exists
_command_exists() {
    local command="$1"
    
    # Remove leading dash and trailing = if present
    command="${command#-}"
    command="${command%=}"
    
    _get_all_abaqus_commands | grep -q "^${command}$"
}

# Function 4: List all commands that contain a specific option
_find_commands_with_option() {
    local option="$1"
    
    if [[ -z "$option" ]]; then
        echo "Error: Option name required" >&2
        return 1
    fi
    
    local commands_with_option=""
    while read -r cmd; do
        if _validate_option "$cmd" "$option" "$help_file"; then
            commands_with_option="$commands_with_option $cmd"
        fi
    done < <(_get_all_abaqus_commands)
    
    echo "$commands_with_option" | xargs
}

# Function 5: Validate if an option is valid for a command
_validate_option() {
    local command="$1"
    local option="$2"
    
    # Remove leading dash and trailing = if present
    command="${command#-}"
    command="${command%=}"
    
    if [[ -z "$command" ]] || [[ -z "$option" ]]; then
        return 1
    fi
    
    local valid_options=$(_get_suboptions "$command")
    echo "$valid_options" | grep -qw "$option"
}

# Function 6: Get all options with their descriptions (if parseable)
_get_option_descriptions() {
    local command="$1"
    
    # Remove leading dash and trailing = if present
    command="${command#-}"
    command="${command%=}"
    
    if [[ -z "$command" ]]; then
        echo "Error: Command name required" >&2
        return 1
    fi
    
    # Get help content from file or cache
    local help_content
    if [[ -z "$_ABAQUS_HELP_CACHE" ]]; then
        _ABAQUS_HELP_CACHE=$(abaqus help 2>/dev/null)
        if [[ $? -ne 0 || -z "$_ABAQUS_HELP_CACHE" ]]; then
            echo "Error: Could not get help from 'abaqus help' command" >&2
            return 1
        fi
    fi
    help_content="$_ABAQUS_HELP_CACHE"
    
    # Find the command section and extract parameter=description patterns
    local pattern="^\s*abaqus\s+(${command}(\s|=)|${command}$)"
    local start_line=$(echo "$help_content" | grep -En "$pattern" | head -1 | cut -d: -f1)
    
    if [[ -z "$start_line" ]]; then
        return 1
    fi
    
    local total_lines=$(echo "$help_content" | wc -l)
    local line_num=$((start_line))
    
    while [[ $line_num -le $total_lines ]]; do
        local current_line=$(echo "$help_content" | sed -n "${line_num}p")
        
        if [[ $line_num -gt $start_line ]] && [[ "$current_line" =~ ^[^[:space:]] ]] && [[ -n "$(echo "$current_line" | grep -v '^$')" ]]; then
            break
        fi
        
        if [[ $line_num -eq $start_line ]] || [[ "$current_line" =~ ^[[:space:]] ]]; then
            echo "$current_line"
        fi
        
        ((line_num++))
    done
}

# Example usage and testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== All Abaqus Commands ==="
    _get_all_abaqus_commands
    
    echo -e "\n=== Suboptions Examples ==="
    echo -e "\nCommand: job"
    _get_suboptions "job"
    
    echo -e "\nCommand: cse"
    _get_suboptions "cse"
    
    echo -e "\nCommand: cosimulation"
    _get_suboptions "cosimulation"
    
    echo -e "\nCommand: cae" 
    _get_suboptions "cae"
    
    echo -e "\nCommand: python"
    _get_suboptions "python"
    
    echo -e "\n=== Utility Function Examples ==="
    
    echo -e "\nCheck if 'cae' command exists:"
    if _command_exists "cae"; then
        echo "  ✓ Command 'cae' exists"
    fi
    
    echo -e "\nCheck if 'nonexistent' command exists:"
    if _command_exists "nonexistent"; then
        echo "  ✓ Command 'nonexistent' exists"
    else
        echo "  ✗ Command 'nonexistent' does not exist"
    fi
    
    echo -e "\nValidate option: Does 'job' command have 'memory' option?"
    if _validate_option "job" "memory"; then
        echo "  ✓ Yes, 'memory' is a valid option for 'job'"
    else
        echo "  ✗ No, 'memory' is not a valid option"
    fi
    
    echo -e "\nFind commands with 'memory' option:"
    commands=$(_find_commands_with_option "memory")
    if [[ -n "$commands" ]]; then
        echo "  Commands: $commands"
    fi
    
    echo -e "\nRaw option descriptions for 'job' command (first 20 lines):"
    _get_option_descriptions "job" | head -20
fi
