pushd /data
    mkdir -p decomp

    ls *.jar | while read fichero;
    do
        cp $fichero ./decomp/$fichero
        pushd decomp
            unzip $fichero
        popd        
    done;
    pushd decomp
        zip  $FINAL_JAR -m -n .jar -r *
        mv $FINAL_JAR ..
    popd
    rm -R decomp
popd
ls -la /data