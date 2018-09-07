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



Updatecouchdbrole () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_ROLE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['role']"`;
  CURR_DOC_DESC=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  SELECT_QUERY="SELECT * FROM roles WHERE couchdb_role_id = '${CURR_DOC_ID}';";
  
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SELECT_QUERY"`; 
  echo $RESULT
  if [[ $RESULT = *"role_id"* ]] ; then
    echo "Update"
  else
    echo "Insert"
  fi
}

# Check if last_sequence.txt file exists
if [ ! -x ../log/last_sequence.txt ] ; then
    touch ../log/last_sequence.txt
    echo "last_seq: 0" > ../log/last_sequence.txt
fi

LAST_SEQ=`ruby -ryaml -e "puts YAML::load_file('../log/last_sequence.txt')['last_seq']"`;

RESULTS=`curl "${COUCH_PROTOCOL}://${COUCH_HOST}:${COUCH_PORT}/${COUCH_DATABASE}/_changes?since=${LAST_SEQ}&limit=10000"`;

RECORDS=`echo $RESULTS | awk '{split($0,a,"last_seq:"); print a[3]; print a[2]; print a[1]}'`;

LAST_SEQ=`echo $RECORDS | sed 's/.*,//'`;
LAST_SEQ=`echo "${LAST_SEQ//\}}"`;

LAST_SEQ_NUM=`echo $LAST_SEQ | tr -dc '0-9'`;

echo "$RESULTS" > ../log/latest_coucdb_docs.txt
RECORDS=`ruby -ryaml -e "puts YAML::load_file('../log/latest_coucdb_docs.txt')['results']"`;


for i in $RECORDS
do
  if [[ $i = *"id"* ]] ; then
    DOC_ID=`echo $i | awk '{split($0,a,"=>"); print a[2]}'`;
    DOC_ID=`echo "${DOC_ID//,}"`;
    DOC_ID=`echo "${DOC_ID//\"}"`;
    DOC=`curl "${COUCH_PROTOCOL}://${COUCH_HOST}:${COUCH_PORT}/${COUCH_DATABASE}/${DOC_ID}"`;

    if [[ $DOC = *"CouchdbRole"* ]] ; then
      Updatecouchdbrole "$DOC"
    fi
    exit;
  fi
done




exit;

