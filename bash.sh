# loop over content of a file
while read l; do
  echo $l
done <fileToReadFrom.txt

for l in $(cat filetoReadFrom.txt); do
  echo $l
done
