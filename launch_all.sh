#!/bin/bash
ls proyecto_generado | while read fichero;
do
    echo "----------- PROCESAMOS $fichero ---------------";
    pushd proyecto_generado/$fichero/build_pipeline;
    ./exec_pipeline.sh;
    popd;
done