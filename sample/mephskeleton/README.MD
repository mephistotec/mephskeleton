find . -type f | grep -v lib | grep -v "org/springframework/boot/loader" > mycontent.txt;find . -type f | grep lib | grep mephskeleton >> mycontent.txt

find . -type f | grep "org/springframework/boot/loader" > othercontent.txt; find . -type f | grep lib | grep -v mephmicto >> othercontent.txt

