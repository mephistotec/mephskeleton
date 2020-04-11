echo "Join jars init"
currentPath=$(pwd)
cd /data
mkdir -p ./decomp

ls *.jar | while read fichero;
do
    echo "Processing $fichero"
    mv $fichero ./decomp/$fichero
    cd decomp
        unzip -q $fichero
        rm $fichero
    cd ..        
done;
cd decomp
    echo "Zip of $FINAL_JAR"
    zip  -q $FINAL_JAR -m -n .jar -r *
    mv $FINAL_JAR ..
cd ..
rm -R decomp
cd $currentPath