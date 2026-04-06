# Abaqus Help File Parsing Functions

This document describes the bash functions available for parsing the Abaqus help output file (`abaqus_help.txt`).

## Overview

Two main functions are provided in `parse_abaqus_help.sh`:

1. **`_get_all_abaqus_commands`** - Extract all available Abaqus commands
2. **`_get_suboptions`** - Get all options/parameters for a specific command

## Function 1: `_get_all_abaqus_commands()`

### Purpose
Extracts and lists all top-level Abaqus commands from the help file.

### Syntax
```bash
_get_all_abaqus_commands [help_file_path]
```

### Parameters
- `help_file_path` (optional): Path to the Abaqus help file. Defaults to `./abaqus_help.txt`

### Example Usage
```bash
#!/bin/bash
source ./parse_abaqus_help.sh

# Get all commands
all_commands=$(_get_all_abaqus_commands)
echo "Available commands: $all_commands"

# Or with a custom help file path
all_commands=$(_get_all_abaqus_commands "/custom/path/abaqus_help.txt")

# Use in a loop
for cmd in $(_get_all_abaqus_commands); do
    echo "Processing: $cmd"
done
```

### Output
Returns a space-separated list of all available Abaqus commands, one per line:
```
adams
append
ascfil
cae
cosimulation
cse
...
viewer
```

## Function 2: `_get_suboptions()`

### Purpose
Extracts all available options/parameters for a specific Abaqus command.

### Syntax
```bash
_get_suboptions <command> [help_file_path]
```

### Parameters
- `command` (required): The Abaqus command name to get options for
- `help_file_path` (optional): Path to the Abaqus help file. Defaults to `./abaqus_help.txt`

### Example Usage
```bash
#!/bin/bash
source ./parse_abaqus_help.sh

# Get options for the 'job' command
job_options=$(_get_suboptions "job")
echo "Job options: $job_options"

# Get options for the 'cae' command  
cae_options=$(_get_suboptions "cae")
echo "CAE options: $cae_options"

# Use with custom help file
options=$(_get_suboptions "python" "/opt/abaqus/docs/help.txt")

# Check if a specific option exists
if echo "$(_get_suboptions 'job')" | grep -q "memory"; then
    echo "memory option is available for job command"
fi
```

### Output
Returns a space-separated list of available options/parameters:

Example for `job` command:
```
after convert cpus csedirector domains double fil globalmodel gpus host information input job license_type memory oldjob output_precision parallel port resultsformat scratch ssd_partition ssd_split standard_parallel threads_per_mpi_process timeout unconnected_regions user
```

Example for `cae` command:
```
custom database recover replay script startup
```

## Command Reference

Here are some useful Abaqus commands and their available options:

### `job` - Standard/Explicit simulation execution
**Options:** input, user, cpus, memory, double, scratch, parallel, gpus, batch control, etc.

### `cse` - Co-Simulation Engine director
**Options:** job, configure, listenerport, datacheck, interactive, license_type

### `cosimulation` - Multi-job co-simulation
**Options:** cosimjob, configure, job, cpus, memory, timeout, fmu, input, etc.

### `cae` - Abaqus/CAE interactive environment
**Options:** database, replay, recover, startup, script, custom, noGUI

### `python` - Python script execution  
**Options:** sim, log (optional python_file_name)

### `viewer` - Abaqus/Viewer post-processing
**Options:** database, replay, startup, script, custom, noGUI

## Additional Utility Functions

In addition to the two main functions, additional utility functions are available:

### Function 3: `_command_exists()`

Checks if a given command is available in Abaqus.

**Syntax:**
```bash
_command_exists <command> [help_file_path]
```

**Returns:** 0 (success) if command exists, 1 (failure) otherwise.

**Example:**
```bash
if _command_exists "cae"; then
    echo "CAE command is available"
fi
```

### Function 4: `_find_commands_with_option()`  

Finds all commands that support a specific option.

**Syntax:**
```bash
_find_commands_with_option <option> [help_file_path]
```

**Returns:** Space-separated list of commands supporting the option.

**Example:**
```bash
# Find all commands that support 'memory' option
cmds=$(_find_commands_with_option "memory")
echo "Commands with memory option: $cmds"
# Output: Commands with memory option: cosimulation job optimization
```

### Function 5: `_validate_option()`

Checks if a specific option is valid for a given command.

**Syntax:**
```bash
_validate_option <command> <option> [help_file_path]
```

**Returns:** 0 (success) if option is valid for command, 1 (failure) otherwise.

**Example:**
```bash
if _validate_option "job" "cpus"; then
    echo "cpus is a valid option for job command"
fi
```

### Function 6: `_get_option_descriptions()`

Retrieves and displays the raw syntax/format for all options of a command, including descriptions.

**Syntax:**
```bash
_get_option_descriptions <command> [help_file_path]
```

**Returns:** Raw help text showing command syntax and option descriptions.

**Example:**
```bash
_get_option_descriptions "cae" | head -10
```

Output:
```
  abaqus cae  [database=database-file] [replay=replay-file]
              [recover=journal-file] [startup=startup-file] 
              [script=script-file] [noGUI[=noGUI-file]] [noenvstartup]
              ...
```

## Integration with Bash Completion

These functions are designed to work with bash completion scripts. Example integration:

```bash
_abaqus_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Complete command names
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$(_get_all_abaqus_commands)" -- "$cur") )
        return 0
    fi
    
    # Complete options based on the command
    local cmd="${COMP_WORDS[1]}"
    local options=$(_get_suboptions "$cmd")
    COMPREPLY=( $(compgen -W "$options" -- "$cur") )
}

complete -F _abaqus_completion abaqus
```

## Source Code Location

The parsing functions are defined in:
- **File:** `parse_abaqus_help.sh`  
- **Main Functions:** 
  - `_get_all_abaqus_commands` - Extract all commands
  - `_get_suboptions` - Get options for a specific command
- **Utility Functions:**
  - `_show_command_info` - Display command and its options
  - `_command_exists` - Check if command exists
  - `_find_commands_with_option` - Find commands with specific option
  - `_validate_option` - Validate if option is valid for command
  - `_get_option_descriptions` - Get raw syntax for a command

## Notes

- The help file is expected to follow Abaqus documentation format
- Parameters are identified by the `parameter=value` pattern in the help text
- Each function validates its input and returns error messages if issues are found
- The functions are designed to be sourced into other bash scripts for reuse

## Testing

Run the script directly to see example output:
```bash
bash parse_abaqus_help.sh
```

This will display:
1. All available commands
2. Example suboptions for: job, cse, cosimulation, cae, python
