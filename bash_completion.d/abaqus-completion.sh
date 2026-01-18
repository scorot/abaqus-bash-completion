# shellcheck shell=bash
# bash completion for abaqus

_abaqus_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Main subcommands
    local subcommands="
    help
	-information
    -job
	cse
	cosimulation
	fmu
	cae
	viewver
	optimization
	python
	-script
	doc
	licensing
	ascfil
	append
	findkeyword
	fetch
	make
	redistadb
	upgrade
	sim_version
	odb2sim
	odbreport
	restartjoin
	substructurecombine
	substructurerecover
	odbcombine
	emloads
	mtxasm
	fromnastran
	tonastran
	fromansys
	frompamcrash
	fromradioss
	toOutput2
	fromdyna
	tozaero
	adams
	tosimpack
	fromsimpack
	toexcite
	moldflow
	encrypt
	decrypt
	sysVerify
    "

    # Options principales
    local _job_opts="
        analysis
        datacheck
        parametercheck
        continue
        -convert
        recover
        syntaxcheck
        -information
        -input
        -user
        -oldjob
        -fil
        -globalmodel
        -cpus
        -parallel
        -domains
        -dynamic_load_balancing
        -mp_mode
        -standard_parallel
        -gpus
        -memory
        -queue
        -double
        -scratch
        -output_precision
        -resultsformat
        -field
        -history
        -port
        -host
        -csedirector
        -timeout
        -unconnected_regions
    "

    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$subcommands" -- "$cur") )
        return 0
    fi


    ###############################################
    # information
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" -information "* ]]; then
        local information_opts="environment
                                local
                                memory
                                release 
                                support
                                system
                                all"

        COMPREPLY=( $(compgen -W "$information_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^([a-z]|-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi

    ###############################################
    # cae and viewer
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" cae "* ]] || [[ " ${COMP_WORDS[*]} " == *" viewer "* ]] ; then
        local cae_opts="-database
                        -replay
                        -recover
                        -script
                        -noGUI
                        noenvstartup
                        noSavedOptions
                        noSavedGuiPrefs
                        noStartupDialog
                        -custom
                        -guiTester
                        guiRecord
                        guiNoRecord
                        "

        if [[ "$prev" == "cae" ]] || [[ "$prev" == "viewer" ]]; then
            COMPREPLY=( $(compgen -W "$cae_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -database)
                COMPREPLY=( $( compgen -f -- "$cur") )
                return 0
                ;;
            -replay)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -recover)
                COMPREPLY=( $(compgen -f -X '!*.jnl' -- "$cur") )
                return 0
                ;;
            -script)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -noGUI)
                COMPREPLY=( $(compgen -f -X '!*.py' -- "$cur") )
                return 0
                ;;
            -custom)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -guiTester)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$cae_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # optimization
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" optimization "* ]]; then
        local optimization_opts="-task
                                 -job
                                 -cpus
                                 -gpus
                                 -memory
                                 interactive
                                 -globalmodel
                                 -scratch
                                 "

        if [[ "$prev" == "upgrade" ]]; then
            COMPREPLY=( $(compgen -W "$optimization_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job)
                COMPREPLY=( $(compgen -d -- "$cur") )
                return 0
                ;;
            -cpus)
                COMPREPLY=( $(compgen -W "4 8 16 24 32 48" -- "$cur") )
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
            -globalmodel)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
            -scratch)
                COMPREPLY=( $(compgen -d -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$optimization_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # python
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" python "* ]]; then

        local python_opts="-sim -log"

        if [[ "$prev" == "python" ]]; then
            COMPREPLY=( $(compgen -f -X '!*.py' -- "$cur") )
            return 0
        fi

        case "$prev" in
            -sim)
                COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
                return 0
                ;;
            -log)
                COMPREPLY=()
                return 0
            ;;
        esac
        COMPREPLY=( $(compgen -W "$python_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
       return 0
    fi


    ###############################################
    # script
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" -script "* ]]; then

        local script_opts="-startup novenstartup"

        if [[ "$prev" == "-script" ]]; then
            COMPREPLY=( $(compgen -f -X '!*.psf' -- "$cur") )
            return 0
        fi

        case "$prev" in
            -startup)
              COMPREPLY=( $(compgen -f -- "$cur") )
              return 0
            ;;
        esac
        COMPREPLY=( $(compgen -W "$script_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^([a-z|-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # licensing
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" licensing "* ]]; then

        local lincensing_opts="lmstat lmdiag lmpath lmtools dslsstat reporttool"

        COMPREPLY=( $(compgen -W "$lincensing_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
       return 0
    fi


    ###############################################
    # ascfil
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" ascfil "* ]]; then
        local ascfil_opts="-job -oldjob -input"

        if [[ "$prev" == "ascfil" ]]; then
            COMPREPLY=( $(compgen -W "$ascfil_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job)
                COMPREPLY=( $(compgen -f -X '!*.fil' -- "$cur") )
                return 0
                ;;
            -oldjob)
                COMPREPLY=( $(compgen -f -X '!*.fil' -- "$cur") )
                return 0
                ;;
            -input)
                COMPREPLY=( $(compgen -f -X '!*.inp' -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$ascfil_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi



    ###############################################
    # findkeyword
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" ascfil "* ]]; then
        local findkeyword_opts="-job -maximum"

        if [[ "$prev" == "ascfil" ]]; then
            COMPREPLY=( $(compgen -W "$findkeyword_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -maximum)
                COMPREPLY=( $(compgen -W "10 20 40" -- "$cur") )
                return 0
                ;;

        esac

        COMPREPLY=( $(compgen -W "$findkeyword_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # fetch
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" ascfil "* ]]; then
        local fetch_opts="-job -input"

        if [[ "$prev" == "ascfil" ]]; then
            COMPREPLY=( $(compgen -W "$fetch_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -maximum)
                COMPREPLY=( $(compgen -W "10 20 40" -- "$cur") )
                return 0
                ;;

        esac

        COMPREPLY=( $(compgen -W "$fetch_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # make
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" make "* ]]; then
        local make_opts="-job
                         -library
                         -user
                         -directory
                         -object_type
                         uniquelibs"

        if [[ "$prev" == "make" ]]; then
            COMPREPLY=( $(compgen -W "$make_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -library)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -user)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -directory)
                COMPREPLY=( $(compgen -d -- "$cur") )
                return 0
                ;;
            -object_type)
                COMPREPLY=( $(compgen -W "fortran c cpp" -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$make_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # redistadb
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" redistadb "* ]]; then
        local redistadb_opts="-oldjob
                              -newjob
                              -input
                              -step
                              -increment
                              -outdir
                              -copyfiles
                              -list
                              help-yes
                              "

        if [[ "$prev" == "redistadb" ]]; then
            COMPREPLY=( $(compgen -W "$redistadb_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -oldjob)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
            -newjob)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
            -input)
                COMPREPLY=( $(compgen -f -X '!*.inp' -- "$cur") )
                return 0
                ;;
            -increment)
                COMPREPLY=( $(compgen -W "1 2 3" -- "$cur") )
                return 0
                ;;
            -outdir)
                COMPREPLY=( $(compgen -d -- "$cur") )
                return 0
                ;;
            -copyfiles)
                COMPREPLY=( $(compgen -W "yes" -- "$cur") )
                return 0
                ;;
            -list)
                COMPREPLY=( $(compgen -W "yes" -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$redistadb_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # upgrade
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" upgrade "* ]]; then
        local upgrade_opts="-job -odb"

        if [[ "$prev" == "upgrade" ]]; then
            COMPREPLY=( $(compgen -W "$upgrade_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job|-odb)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$upgrade_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


   ###############################################
    # odb2sim
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" odb2sim "* ]]; then

        local odb2sim_opts="-odb
                            -sim
                            -log 
                            -o2sdebug"

        if [[ "$prev" == "odb2sim" ]]; then
            COMPREPLY=( $(compgen -W "$odb2sim_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job|-sim|-log)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -odb)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
            -o2sdebug)
                COMPREPLY=( $(compgen -W "0 1 2" -- "$cur") )
                return 0
            ;;
        esac
        COMPREPLY=( $(compgen -W "$odb2sim_opts" -- "$cur") )
 
        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
      return 0
    fi

    ###############################################
    # sim_version
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" sim_version "* ]]; then
        local sim_version_opts="-convert
                                -query
                                current
                                -out
                                -level
                                help
                                "

        if [[ "$prev" == "sim_version" ]]; then
            COMPREPLY=( $(compgen -W "$sim_version_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -convert)
                COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
                return 0
                ;;
            -query)
                COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
                return 0
                ;;
            -out)
                COMPREPLY=( $(compgen -f -X '!*.sim' -- "$cur") )
                return 0
                ;;
            -level)
                COMPREPLY=( $(compgen -W 'V6R2022x V6R2023 xV6R2024x' -- "$cur") )
                return 0
                ;;
        esac

        COMPREPLY=( $(compgen -W "$sim_version_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    ###############################################
    # odb2sim
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" odb2sim "* ]]; then

        local odb2sim_opts="-odb
                            -sim
                            -log 
                            -o2sdebug"

        if [[ "$prev" == "odb2sim" ]]; then
            COMPREPLY=( $(compgen -W "$odb2sim_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job|-sim|-log)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -odb)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
            -o2sdebug)
                COMPREPLY=( $(compgen -W "0 1 2" -- "$cur") )
                return 0
            ;;
        esac
        COMPREPLY=( $(compgen -W "$odb2sim_opts" -- "$cur") )
 
        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
      return 0
    fi


    ###############################################
    #   restartjoin
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" restartjoin "* ]]; then
        local restartjoin_opts="-originalodb
                                -restartodb
                                copyoriginal
                                history
                                compressresult"

        if [[ "$prev" == "upgrade" ]]; then
            COMPREPLY=( $(compgen -W "$restartjoin_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -originalodb|-restartodb)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
        esac
        COMPREPLY=( $(compgen -W "$restartjoin_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
       return 0
    fi


    ###############################################
    # substructurecombine
    ###############################################
    # TBD


    ###############################################
    # substructurerecover
    ###############################################
    # TBD


    ###############################################
    # odbcombine
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" odbcombine "* ]]; then

        local odbcombine_opts="-job -input -verbose"

        if [[ "$prev" == "upgrade" ]]; then
            COMPREPLY=( $(compgen -W "$odbcombine_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job|-input)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -verbose)
                COMPREPLY=( $(compgen -W "1 2" -- "$cur") )
                return 0
            ;;
        esac
        COMPREPLY=( $(compgen -W "$odbcombine_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi

    ###############################################
    # odbreport
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" odbreport "* ]]; then

        local odbreport_opts="-job
                                -odb
                                -mode
                                all
                                mesh
                                sets
                                results
                                -step
                                -frame
                                -framevalue
                                -field
                                components"

        if [[ "$prev" == "odbreport" ]]; then
            COMPREPLY=( $(compgen -W "$odbreport_opts" -- "$cur") )
            return 0
        fi

        case "$prev" in
            -job)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;          
            --odb)
                COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
                return 0
                ;;
            -step)
                COMPREPLY=( $(compgen -W "__LAST__" -- "$cur") )
                return 0
                ;;
            -frame)
                COMPREPLY=( $(compgen -W "__LAST__" -- "$cur") )
                return 0
                ;;
        esac
        COMPREPLY=( $(compgen -W "$odbreport_opts" -- "$cur") )

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^([a-z]-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
       return 0
    fi


    ###############################################
    # tonastran
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" tonastran "* ]]; then

        local tonastran_opts="-job
                            -input
                            -bdf_format
                            sim2dmig
                            -complex"

        if [[ "$prev" == "-script" ]]; then
           COMPREPLY=( $(compgen -f -X '!*.psf' -- "$cur") )
           return 0
        fi

        case "$prev" in
           -job)
              COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
              return 0
              ;;
            -input)
                COMPREPLY=( $(compgen -f -X '!*.inp' -- "$cur") )
                return 0
                ;;
            -bdf_format)
                COMPREPLY=( $(compgen -W "DOUBLE FREE" -- "$cur") )
                return 0
                ;;
            -complex)
                COMPREPLY=( $(compgen -X "YES NO" -- "$cur") )
                return 0
                ;;
        esac
        COMPREPLY=($(compgen -W "${tonastran_opts}" -- "$cur"))
 
        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi

    ###############################################
    # fromnastran
    ###############################################
    if [[ " ${COMP_WORDS[*]} " == *" fromnastran "* ]]; then

       local fromnastran_opts="-job
                               -input
                               -wtmass_fixup
                               -loadcases
                               -pbar_zero_reset
                               -surface_based_coupling
                               -beam_offset_coupling
                               -beam_orientation_vector
                               -cbar
                               -cquad4
                               -chexa
                               -ctetra
                               -cpyram
                               -cshear
                               -plotel
                               -cdh_weld
                               -dmig2sim
                               -op2file1
                               -op2file2
                               -op2target
                               "

       if [[ "$prev" == "-script" ]]; then
           COMPREPLY=( $(compgen -f -X '!*.psf' -- "$cur") )
           return 0
       fi

       case "$prev" in
           -job)
              COMPREPLY=( )
              return 0
              ;;
            -input)
                COMPREPLY=( $(compgen -f -- "$cur") )
                return 0
                ;;
            -loadcases)
                COMPREPLY=( $(compgen -W "ON OFF" -- "$cur") )
                return 0
                ;;
            -pbar_zero_reset)
                COMPREPLY=( )
                return 0
                ;;
            -surface_based_coupling)
                COMPREPLY=( $(compgen -W "ON OFF" -- "$cur") )
                return 0
                ;;
            -beam_offset_coupling)
                COMPREPLY=( $(compgen -W "ON OFF" -- "$cur") )
                return 0
                ;;
            -beam_orientation_vector)
                COMPREPLY=( $(compgen -W "ON OFF" -- "$cur") )
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
            -plotel)
                COMPREPLY=( $(compgen -W "ON OFF" -- "$cur") )
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
            -op2file1)
                COMPREPLY=( $(compgen -f -X "!*.op2" -- "$cur") )
                return 0
                ;;
            -op2file2)
                COMPREPLY=( $(compgen -W -X "!*.op2" -- "$cur") )
                return 0
                ;;
            -op2target)
                COMPREPLY=( $(compgen -W "INPUT GENERIC SUBSTRUCTURE" -- "$cur") )
                return 0
                ;;
        esac
        COMPREPLY=($(compgen -W "${fromnastran_opts}" -- "$cur"))

        # Remove already‑used options from the list
        used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^(-|--)' | tr '\n' ' ')
        COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))
        return 0
    fi


    case "$prev" in
        -job|-input)
            COMPREPLY=( $(compgen -f -X '!*.inp' -- "$cur") )
            return 0
            ;;

	    -oldjob)
            COMPREPLY=( $(compgen -f -X '!*.odb' -- "$cur") )
            return 0
            ;;	
        -user)
            COMPREPLY=( $(compgen -W "source-file object-file" -- "$cur") )
            return 0
            ;;

        -fil)
            COMPREPLY=( $(compgen -W "append new" -- "$cur") )
            return 0
            ;;

        -globalmodel)
            COMPREPLY=( $(compgen -W "results ODB SIM" -- "$cur") )
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

        -information)
            COMPREPLY=( $(compgen -W "environment local memory release support system all" -- "$cur") )
            return 0
            ;;

        -queue)
            local queues
            queues="$(scontrol -o show partitions | grep -Po 'PartitionName=\S+' | cut -d'=' -f2 | tr '\n' ' ')"
            [[ -z "$queues" ]] && queues="small short big"

			COMPREPLY=( $(compgen -W "$queues" -- "$cur") )
			return 0

            ;;
    esac

    COMPREPLY=( $(compgen -W "$_job_opts" -- "$cur") )

    # Remove already‑used options from the list
    used=$(printf '%s\n' "${COMP_WORDS[@]:1}" | grep -E '^([a-z]|-|--)' | tr '\n' ' ')
    COMPREPLY=($(printf '%s\n' "${COMPREPLY[@]}" | grep -vxF -f <(printf '%s\n' $used)))

}

complete -F _abaqus_completion abq2024 abq2023 abq2022 abaqus

