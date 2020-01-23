echo "Join jars init"
currentPath=$(pwd)
cd /data
mkdir -p ./decomp
echo "----------------------------------------------"
ls *.jar
echo "----------------------------------------------"
ls *.jar | while read fichero;
do
    echo "Procesando $fichero"
    mv $fichero ./decomp/$fichero
    cd decomp
        unzip $fichero
        rm $fichero
    cd ..        
done;
cd decomp
    echo "Zipando $FINAL_JAR"
    zip  $FINAL_JAR -m -n .jar -r *
    mv $FINAL_JAR ..
cd ..
rm -R decomp
cd $currentPath