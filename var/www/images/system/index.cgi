#!/bin/sh

echo "Content-type: text/html";
echo
for n in `ls`;do
echo "<img src=$n>$n<br>";
done
