rm *.glob *.vo* .*.aux
cd Zap
rm *.glob *.vo* .*.aux
cd ..

COQPATH=$(pwd) coqc -R Zap Zap Zap/Maz.v
COQPATH=$(pwd) coqc -R Zap Zap Zap/Zam.v
COQPATH=$(pwd) coqc -R Zap Zap Bonk.v
COQPATH=$(pwd) coqc Main.v
