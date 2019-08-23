
touch outfile
cat /dev/null > llh${1}_fixedv
cat /dev/null > llh${1}_optimv

for i in $(seq -w 01 $2)
do
    echo "dm$1_$i.phy
R
U
L
C
2
3
4
Y
t$1_$i.nwk
124516255" > phylip_command
    cat phylip_command | contml
    grep "Ln Likelihood" outfile | sed 's/Ln Likelihood = //g' >> llh${1}_fixedv

    echo "dm$1_$i.phy
R
U
C
2
3
4
Y
t$1_$i.nwk
124516255" > phylip_command
    cat phylip_command | contml
    grep "Ln Likelihood" outfile | sed 's/Ln Likelihood = //g' >> llh${1}_optimv
done

rm outfile
rm phylip_command