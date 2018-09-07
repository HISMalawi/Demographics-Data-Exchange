#!/bin/bash
ENV=$1

MYSQL_USERNAME=`ruby -ryaml -e "puts YAML::load_file('../config/database.yml')['${ENV}']['username']"`
MYSQL_PASSWORD=`ruby -ryaml -e "puts YAML::load_file('../config/database.yml')['${ENV}']['password']"`
MYSQL_DATABASE=`ruby -ryaml -e "puts YAML::load_file('../config/database.yml')['${ENV}']['database']"`
MYSQL_HOST=`ruby -ryaml -e "puts YAML::load_file('../config/database.yml')['${ENV}']['host']"`

COUCH_USERNAME=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['username']"`
COUCH_PASSWORD=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['password']"`
COUCH_PREFIX=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['prefix']"`
COUCH_SUFFIX=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['suffix']"`
COUCH_HOST=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['host']"`
COUCH_PORT=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['port']"`
COUCH_PROTOCOL=`ruby -ryaml -e "puts YAML::load_file('../config/couchdb.yml')['${ENV}']['protocol']"`
COUCH_DATABASE=${COUCH_PREFIX}_${COUCH_SUFFIX}

# Check if last_sequence.txt file exists
if [ ! -x ../log/last_sequence.txt ] ; then
    touch ../log/last_sequence.txt
    echo "{'last_sequence' : '0'}" > ../log/last_sequence.txt
fi

filename="../log/last_sequence.txt"

while read -r line
do 
  LS="$line"
done < "$filename"

LAST_SEQUENCE=`echo "$LS" | sed -e 's/[{}]/''/g' | awk -v RS=',' -F: '{print $2}'`
LAST_SEQUENCE=`echo ${LAST_SEQUENCE} | xargs`
#LAST_SEQUENCE=sed -i "s/last_sequence/g" ../log/last_sequence.txt;

RESULTS=echo curl "${COUCH_PROTOCOL}://${COUCH_HOST}:${COUCH_PORT}/${COUCH_DATABASE}/_changes?since=${LAST_SEQUENCE}&limit=10000"
LAST_SEQ=`echo "$RESULTS" | sed -e 's/"last_seq":/''/g' | awk -v RS=',' -F: '{print $1}'`

#echo $LAST_SEQ


