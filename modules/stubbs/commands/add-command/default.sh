#!/bin/bash
#
# NAME
#
#   archive
#
# DESCRIPTION
#
#   build a self extracting rerun
#

# Source common function library
. $RERUN_MODULES/stubbs/lib/functions.sh

# print an error and exit
die() { echo "ERROR: \$* " ; exit 1 ; }

# Init the handler
rerun_init 

TEMPLATE=$RERUN_MODULES/stubbs/templates/default.sh

# Get the options
while [ "$#" -gt 0 ]; do
    OPT="$1"
    case "$OPT" in
        # options without arguments
	# options with arguments
	-name)
	    rerun_syntax_check "$#"
	    NAME="$2"
	    shift
	    ;;
	-description)
	    rerun_syntax_check "$#"
	    DESC="$2"
	    shift
	    ;;
	-module)
	    rerun_syntax_check "$#"
	    MODULE="$2"
	    shift
	    ;;
	-overwrite)
	    rerun_syntax_check "$#"
	    OVERWRITE="$2"
	    shift
	    ;;
	-template)
	    rerun_syntax_check "$#"
	    TEMPLATE="$2"
	    shift
	    ;;
        # unknown option
	-?)
	    rerun_syntax_error
	    ;;
	  # end of options, just arguments left
	*)
	    break
    esac
    shift
done

# Post processes the options
[ -z "$NAME" ] && {
    echo "Name: "
    read NAME
}

[ -z "$DESC" ] && {
    echo "Description: "
    read DESC
}

[ -z "$MODULE" ] && {
    echo "Module: "
    select MODULE in $(rerun_modules $RERUN_MODULES);
    do
	echo "You picked module $MODULE ($REPLY)"
	break
    done
}

[ ! -r "$TEMPLATE" ] && {
    die "TEMPLATE does not exist: $TEMPLATE"
}

# Create command structure
mkdir -p $RERUN_MODULES/$MODULE/commands/$NAME || die

# Generate a boiler plate implementation
[ ! -f $RERUN_MODULES/$MODULE/commands/$NAME/default.sh -o -n "$OVEWRITE" ] && {
    sed -e "s/@NAME@/$NAME/g" \
	-e "s/@MODULE@/$MODULE/g" \
	-e "s/@DESCRIPTION@/$DESC/g" \
	$TEMPLATE > $RERUN_MODULES/$MODULE/commands/$NAME/default.sh || die
    echo "Wrote command script: $RERUN_MODULES/$MODULE/commands/$NAME/default.sh"
}

# Generate a unit test script
mkdir -p $RERUN_MODULES/$MODULE/tests/$NAME/commands || die "failed creating tests directory"
[ ! -f $RERUN_MODULES/$MODULE/tests/$NAME/commands.sh -o -n "$OVEWRITE" ] && {
    sed -e "s/@NAME@/default/g" \
	-e "s/@MODULE@/$MODULE/g" \
	-e "s/@COMMAND@/$NAME/g" \
	-e "s/@RERUN_MODULES@/$RERUN_MODULES/g" \
	$RERUN_MODULES/stubbs/templates/test.sh > $RERUN_MODULES/$MODULE/tests/$NAME/commands/default.sh || die
    echo "Wrote test script: $RERUN_MODULES/$MODULE/tests/$NAME/commands/default.sh"
}

# Generate command metadata
(
cat <<EOF
# generated by add-command
# $(date)
NAME=$NAME
DESCRIPTION=$DESC

EOF
) > $RERUN_MODULES/$MODULE/commands/$NAME/metadata || die

# Done
