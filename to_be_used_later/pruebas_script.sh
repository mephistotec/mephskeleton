#!/usr/bin/env bash

# Ecritura en canal de error
echoerr() { (>&2 echo "$@"); }

# Aceptamos -f / --flags para inicializar opciones de generacion definidas en fichero environment_scripts/opt_<opcion>.sh
# Aceptamos -e / --env para inicializar variables en fichero environment_scripts/env_<opcion>.sh
# Aceptamos -v / --verison para seleccionar la versiónque queremos generar
echoerr "PARAMETROS ENV $@"

OPTS=$(getopt "-o f:e: -l flags:env:" -- $@)

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

echoerr "--- Inicializamos opciones y entornos con params $OPTS"

while true; do
  case "$1" in
    --batch )
        echo "Añadimos batch con [$2]"
        shift;shift ;;
    --engine )
        echo "Añadimos engine con [$2]"
        shift;shift ;;
    -g | --groupid )
        echo "Groupid [$2]"
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done

echo "Ademas los parámetros son $1 $2 $3"