#!/usr/bin/env bash

#--------------------------------------------------------------------
# No requiere nada salvo que sean necesarios flags por el contexto
# en que se ejecuta.
#--------------------------------------------------------------------

echo "Arrancando el entorno mock"
./03_01_start_mock_servers.sh $@ &

#rc=$?
#if [[ $rc -ne 0 ]] ; then
#  echo '--- Error iniciando entorno mock'; exit $rc
#fi

echo "----------------------------------------"
echo " Validando el entorno antes de probar..."
echo "----------------------------------------"
./03_02_check_entonro_mock_ok.sh $@

rc=$?

if [[ $rc -ne 0 ]] ; then
  echo '-----------------------------------------------------------------------'
  echo '--- Error test aceptación - no se ha levantado el entornos';
  echo '-----------------------------------------------------------------------'
  echo "Cerrando el entorno mock"
  ./03_03_stop_mock_servers.sh $@
  exit $rc
else
    echo "----------------------------------------"
    echo " Entorno inicializado, esperamos..."
    echo "----------------------------------------"
    sleep 5

    ./03_03_test_newman.sh $@

    rc=$?
    #Paramos los entornos
    echo "Cerrando el entorno mock"
    ./03_03_stop_mock_servers.sh $@

    if [[ $rc -ne 0 ]] ; then
      echo '--- Error test aceptación'; exit $rc
    else
      echo 'Test aceptacion ok'
    fi
fi
