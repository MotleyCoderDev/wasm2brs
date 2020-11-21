: ${DUKTAPE?"Need to set DUKTAPE to the downloaded duktape directory, such as ~/duktape-2.6.0"}
rm -rf duktape
DIR=$(pwd)
cd $DUKTAPE
python tools/configure.py \
    --source-directory src-input \
    --output-directory "$DIR/duktape" \
    --config-metadata config \
    --option-file "$DIR/duktape.yaml"
