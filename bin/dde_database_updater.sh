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

get_mysql_location_from_couchdb () {
  SQL_QUERY="SELECT location_id FROM locations WHERE couchdb_location_id = '$1'"
  SQL_RESULTS=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  LOCATION_ID=`echo $SQL_RESULTS | awk '{split($0,a," "); print a[2]}'`;

  # echo ${SQL_RESULTS}
}
get_mysql_user_id_from_couchdb () {
  SQL_QUERY="SELECT user_id FROM users WHERE couchdb_user_id = '$1'"
  SQL_RESULTS=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  USER_ID=`echo $SQL_RESULTS | awk '{split($0,a," "); print a[2]}'`;
}

Updatecouchdbrole () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_ROLE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['role']"`;
  CURR_DOC_DESC=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['description']"`;
  SQL_QUERY="SELECT * FROM roles WHERE couchdb_role_id = '${CURR_DOC_ID}';";
  
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  echo $RESULT
  if [[ $RESULT = *"role_id"* ]] ; then
    SQL_QUERY="UPDATE roles SET role=\"${CURR_DOC_ROLE}\", description=\"${CURR_DOC_DESC}\" WHERE couchdb_role_id = \"${CURR_DOC_ID}\""; 
  else
    SQL_QUERY="INSERT INTO roles (role_id, couchdb_role_id, role, description, created_at, updated_at) VALUES(NULL, \"${CURR_DOC_ID}\",\"${CURR_DOC_ROLE}\",\"${CURR_DOC_DESC}\",\"$(echo date)\",\"$(echo date)\")";
  fi

  `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
  echo "UPDATED: ${CURR_DOC_ID} ...${SQL_QUERY}" 
}

Updatecouchdbuser () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_USERNAME=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['username']"`;
  CURR_DOC_EMAIL=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['email']"`;
  CURR_DOC_PASSWORD=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['password_digest']"`;
  CURR_DOC_LOCATION_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['location_id']"`;
  CURR_DOC_VOIDED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['voided']"`;
  CURR_DOC_VOID_REASON=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['void_reason']"`;
  CURR_DOC_UPDATED_AT=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['updated_at']"`;
  CURR_DOC_CREATED_AT=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['created_at']"`;
  
  get_mysql_location_from_couchdb "${CURR_DOC_LOCATION_ID}";
  #MYSQL_LOCATION_ID=$?
  
  SQL_QUERY="SELECT * FROM users WHERE couchdb_user_id = '${CURR_DOC_ID}';";
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  if [[ ! -z "$LOCATION_ID" ]] ; then
    if [[ ! -z "$RESULT" ]] ; then
      SQL_QUERY="UPDATE users SET username=\"${CURR_DOC_USERNAME}\", email=\"${CURR_DOC_EMAIL}\", password_digest=\"${CURR_DOC_PASSWORD}\", couchdb_location_id=\"${CURR_DOC_LOCATION_ID}\", location_id=\"${LOCATION_ID}\",voided=\"${CURR_DOC_VOIDED}\", void_reason=\"${CURR_DOC_VOID_REASON}\" WHERE couchdb_user_id = \"${CURR_DOC_ID}\";"
      echo "UPDATING: ${CURR_DOC_ID}" 
    else
      SQL_QUERY="INSERT INTO users (couchdb_user_id, username, email, password_digest, couch_location_id, location_id)VALUES(\"${CURR_DOC_ID}\",\"${CURR_DOC_USERNAME}\",\"${CURR_DOC_EMAIL}\",\"${CURR_DOC_PASSWORD}\",\"${CURR_DOC_LOCATION_ID}\",\"${LOCATION_ID}\");"
      echo "CREATING: ${CURR_DOC_ID}" 
    fi

    `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
  fi
}

UpdatecouchdbPerson () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_GIVEN_NAME=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['given_name']"`;
  CURR_DOC_FAMILY_NAME=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['family_name']"`;
  CURR_DOC_GENDER=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['gender']"`;
  CURR_DOC_BIRTHDATE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['birthdate']"`;
  CURR_DOC_BIRTHDATE_EST=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['birthdate_estimated']"`;
  CURR_DOC_DIED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['died']"`;
  CURR_DOC_DEATHDATE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['deathdate']"`;
  CURR_DOC_DEATHDATE_EST=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['deathdate_estimated']"`;
  CURR_DOC_VOIDED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['voided']"`;
  CURR_DOC_VOID_REASON=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['void_reason']"`;
  CURR_DOC_DATE_VOIDED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['date_voided']"`;
  CURR_DOC_NPID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['npid']"`;
  CURR_DOC_LOCATION_CREATED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['location_created_at']"`;
  CURR_DOC_CREATOR=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['creator']"`;
  CURR_DOC_CREATED_AT=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['created_at']"`;
  echo $CURR_DOC_FAMILY_NAME
    
  get_mysql_location_from_couchdb "${CURR_DOC_LOCATION_ID}";
  get_mysql_user_id_from_couchdb "${CURR_DOC_CREATOR}"

  SQL_QUERY="SELECT * FROM people WHERE couchdb_person_id = '${CURR_DOC_ID}';";
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  if [[ ! -z "${LOCATION_ID}" ]] ; then
    if [[ ! -z "${RESULT}" ]] ; then
      SQL_QUERY="UPDATE people SET given_name=\"${CURR_GIVEN_NAME}\", middle_name=\"${CURR_DOC_MIDDLE_NAME}\","
      SQL_QUERY="$SQL_QUERY family_name=\"${CURR_DOC_FAMILY_NAME}\", gender=\"${CURR_DOC_GENDER}\","
      SQL_QUERY="$SQL_QUERY birthdate=\"${CURR_DOC_BIRTHDATE}\", birthdate_estimated=\"${CURR_DOC_BIRTHDATE_EST}\","
      SQL_QUERY="$SQL_QUERY died=\"${CURR_DOC_DIED}\", deathdate=\"${CURR_DOC_DEATHDATE}\", deathdate_estimated=\"${CURR_DOC_DEATHDATE_EST}\","
      SQL_QUERY="$SQL_QUERY voided=\"${CURR_DOC_VOIDED}\", date_voided=\"${CURR_DOC_DATE_VOIDED}\", void_reason=\"${CURR_DOC_VOID_REASON}\","
      SQL_QUERY="$SQL_QUERY npid=\"${CURR_DOC_NPID}\", location_created_at=\"${CURR_DOC_LOCATION_CREATED}\","
      SQL_QUERY="$SQL_QUERY creator=\"${USER_ID}\", created_at=\"${CURR_DOC_CREATED_AT}\", updated_at=\"$(echo date)\");"
      echo $SQL_QUERY
    
      echo "UPDATING: ${CURR_DOC_ID}" 
    else
      SQL_QUERY="INSERT INTO people (couchdb_person_id, given_name, middle_name, family_name, gender, birthdate,"
      SQL_QUERY="$SQL_QUERY birthdate_estimated, died, deathdate, deathdate_estimated,npid, location_created_at,"
      SQL_QUERY="$SQL_QUERY created_at, updated_at, voided, void_reason, date_voided) "
      SQL_QUERY="$SQL_QUERY VALUES(\"${CURR_DOC_ID}\",\"${CURR_DOC_GIVEN_NAME}\", \"${CURR_DOC_MIDDLE_NAME}\","
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_FAMILY_NAME}\", \"${CURR_DOC_GENDER}\", \"${CURR_DOC_BIRTHDATE}\", "
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_BIRTHDATE_EST}\", \"${CURR_DOC_DIED}\", \"${CURR_DOC_DEATHDATE}\","
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_DEATHDATE_EST}\",\"${CURR_DOC_NPID}\", \"${CURR_DOC_LOCATION_CREATED}\","
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_CREATED_AT}\", \"${CURR_DOC_UPDATED_AT}\", \"${CURR_DOC_VOIDED}\","
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_VOID_REASON}\", \"${CURR_DOC_DATE_VOIDED}\")";
      echo "CREATING: ${CURR_DOC_ID}" 
    fi
    `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
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
    if [[ $DOC = *"CouchdbUser"* ]] ; then
      Updatecouchdbuser "$DOC"
    fi
    if [[ $DOC = "CouchdbPerson" ]] ; then
      echo $DOC
      UpdatecouchdbPerson "$DOC"
      exit
    fi
    #exit;
  fi
done




exit;

