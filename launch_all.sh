#!/bin/bash
ls built_project | while read fichero;
do
    echo "----------- PROCESAMOS $fichero ---------------";
    pushd built_project/$fichero/build_pipeline;
    ./exec_pipeline.sh;
    popd;
done