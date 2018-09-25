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

MASTER_USERNAME=`ruby -ryaml -e "puts YAML::load_file('../config/master_couchdb.yml')['${ENV}']['username']"`
MASTER_PASSWORD=`ruby -ryaml -e "puts YAML::load_file('../config/master_couchdb.yml')['${ENV}']['password']"`
MASTER_DB=`ruby -ryaml -e "puts YAML::load_file('../config/master_couchdb.yml')['${ENV}']['primary']"`
MASTER_HOST=`ruby -ryaml -e "puts YAML::load_file('../config/master_couchdb.yml')['${ENV}']['host']"`
MASTER_PORT=`ruby -ryaml -e "puts YAML::load_file('../config/master_couchdb.yml')['${ENV}']['port']"`
MASTER_PROTOCOL=`ruby -ryaml -e "puts YAML::load_file('../config/master_couchdb.yml')['${ENV}']['protocol']"`

SOURCE_URL="${MASTER_PROTOCOL}://${MASTER_HOST}:${MASTER_PORT}/${MASTER_DB}"
AUTH_SOURCE_URL="${MASTER_PROTOCOL}://${MASTER_USERNAME}:${MASTER_PASSWORD}@${MASTER_HOST}:${MASTER_PORT}"
TARGET_URL="${COUCH_PROTOCOL}://${COUCH_HOST}:${COUCH_PORT}/${COUCH_DATABASE}"
AUTH_TARGET_URL="${COUCH_PROTOCOL}://${COUCH_USERNAME}:${COUCH_PASSWORD}@${COUCH_HOST}:${COUCH_PORT}"

get_mysql_person_id_from_couch_db () {
  SQL_QUERY="SELECT person_id FROM people WHERE couchdb_person_id = '$1'"
  SQL_RESULTS=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  PERSON_ID=`echo $SQL_RESULTS | awk '{split($0,a," "); print a[2]}'`;
}

get_mysql_person_attribute_type_id_from_couch_db () {
  SQL_QUERY="SELECT person_attribute_type_id FROM person_attribute_types WHERE couchdb_person_attribute_type_id = '$1'"
  SQL_RESULTS=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  PERSON_ATTRIBUTE_TYPE_ID=`echo $SQL_RESULTS | awk '{split($0,a," "); print a[2]}'`;
}

get_mysql_location_from_couchdb () {
  SQL_QUERY="SELECT location_id FROM locations WHERE couchdb_location_id = '$1'"
  SQL_RESULTS=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  LOCATION_ID=`echo $SQL_RESULTS | awk '{split($0,a," "); print a[2]}'`;
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
  
  SQL_QUERY="SELECT * FROM users WHERE couchdb_user_id = '${CURR_DOC_ID}';";
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 

  if [[ ! -z "$LOCATION_ID" ]] ; then
    if [[ ! -z "$RESULT" ]] ; then
      SQL_QUERY="UPDATE users SET username=\"${CURR_DOC_USERNAME}\", email=\"${CURR_DOC_EMAIL}\", password_digest=\"${CURR_DOC_PASSWORD}\", couchdb_location_id=\"${CURR_DOC_LOCATION_ID}\", location_id=\"${LOCATION_ID}\",voided=\"${CURR_DOC_VOIDED}\", void_reason=\"${CURR_DOC_VOID_REASON}\" WHERE couchdb_user_id = \"${CURR_DOC_ID}\";"
      echo "UPDATING: ${CURR_DOC_ID}" 
    else
      SQL_QUERY="INSERT INTO users (couchdb_user_id, username, email, password_digest, couchdb_location_id, location_id)VALUES(\"${CURR_DOC_ID}\",\"${CURR_DOC_USERNAME}\",\"${CURR_DOC_EMAIL}\",\"${CURR_DOC_PASSWORD}\",\"${CURR_DOC_LOCATION_ID}\",\"${LOCATION_ID}\");"
      echo "CREATING: ${CURR_DOC_ID}" 
    fi

    `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
  fi
}

UpdatecouchdbPerson () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_GIVEN_NAME=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['given_name']"`;
  CURR_DOC_MIDDLE_NAME=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['middle_name']"`;
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
  CURR_DOC_UPDATED_AT=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['updated_at']"`;

  if [[ -z "${CURR_DOC_DEATHDATE}" ]] ; then
    CURR_DOC_DEATHDATE="NULL"
  else
    CURR_DOC_DEATHDATE="\"${CURR_DOC_DEATHDATE}\""
  fi
    
  if [[ -z "${CURR_DOC_DATE_VOIDED}" ]] ; then
    CURR_DOC_DATE_VOIDED="NULL"
  else
    CURR_DOC_DATE_VOIDED="\"${CURR_DOC_DATE_VOIDED}\""
  fi
  
  if [[ -z "${CURR_DOC_DEATHDATE}" ]] ; then
    CURR_DOC_DEATHDATE="NULL"
  else
    CURR_DOC_DEATHDATE="\"${CURR_DOC_DEATHDATE}\""
  fi

  get_mysql_location_from_couchdb "${CURR_DOC_LOCATION_CREATED}";
  get_mysql_user_id_from_couchdb "${CURR_DOC_CREATOR}"

  SQL_QUERY="SELECT * FROM people WHERE couchdb_person_id = '${CURR_DOC_ID}';";
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 

  if [[ ! -z "${LOCATION_ID}" ]] ; then
    if [[ ! -z "${RESULT}" ]] ; then
      SQL_QUERY="UPDATE people SET given_name=\"${CURR_DOC_GIVEN_NAME}\", middle_name=\"${CURR_DOC_MIDDLE_NAME}\","
      SQL_QUERY="$SQL_QUERY family_name=\"${CURR_DOC_FAMILY_NAME}\", gender=\"${CURR_DOC_GENDER}\","
      SQL_QUERY="$SQL_QUERY birthdate=${CURR_DOC_BIRTHDATE}, birthdate_estimated=${CURR_DOC_BIRTHDATE_EST},"
      SQL_QUERY="$SQL_QUERY died=${CURR_DOC_DIED}, deathdate=${CURR_DOC_DEATHDATE}, deathdate_estimated=${CURR_DOC_DEATHDATE_EST},"
      SQL_QUERY="$SQL_QUERY voided=${CURR_DOC_VOIDED}, date_voided=${CURR_DOC_DATE_VOIDED}, void_reason=\"${CURR_DOC_VOID_REASON}\","
      SQL_QUERY="$SQL_QUERY npid=\"${CURR_DOC_NPID}\", location_created_at=\"${CURR_DOC_LOCATION_CREATED}\","
      SQL_QUERY="$SQL_QUERY creator=\"${USER_ID}\", created_at=\"${CURR_DOC_CREATED_AT}\", updated_at=\"${CURR_DOC_UPDATED_AT}\""
      SQL_QUERY="$SQL_QUERY WHERE couchdb_person_id = \"${CURR_DOC_ID}\";"
    
      echo "UPDATING PERSON: ${CURR_DOC_ID}" 
    else
      SQL_QUERY="INSERT INTO people (couchdb_person_id, given_name, middle_name, family_name, gender, birthdate,"
      SQL_QUERY="$SQL_QUERY birthdate_estimated, died, deathdate, deathdate_estimated,npid, location_created_at,"
      SQL_QUERY="$SQL_QUERY created_at, updated_at, voided, void_reason, date_voided) "
      SQL_QUERY="$SQL_QUERY VALUES(\"${CURR_DOC_ID}\",\"${CURR_DOC_GIVEN_NAME}\", \"${CURR_DOC_MIDDLE_NAME}\","
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_FAMILY_NAME}\", \"${CURR_DOC_GENDER}\", \"${CURR_DOC_BIRTHDATE}\", "
      SQL_QUERY="$SQL_QUERY ${CURR_DOC_BIRTHDATE_EST}, ${CURR_DOC_DIED}, \"${CURR_DOC_DEATHDATE}\","
      SQL_QUERY="$SQL_QUERY ${CURR_DOC_DEATHDATE_EST},\"${CURR_DOC_NPID}\", \"${CURR_DOC_LOCATION_CREATED}\","
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_CREATED_AT}\", \"${CURR_DOC_UPDATED_AT}\", ${CURR_DOC_VOIDED},"
      SQL_QUERY="$SQL_QUERY \"${CURR_DOC_VOID_REASON}\", \"${CURR_DOC_DATE_VOIDED}\")";

      echo "CREATING PERSON: ${CURR_DOC_ID}" 
    fi
    `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
  fi
  
}

UpdatecouchdbPersonAttribute () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_PERSON_ATTR_TYPE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['person_attribute_type_id']"`;
  CURR_DOC_PERSON=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['person_id']"`;
  CURR_DOC_VALUE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['value']"`;
  CURR_DOC_VOIDED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['voided']"`;
  CURR_DOC_VOID_REASON=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['void_reason']"`;

  get_mysql_person_attribute_type_id_from_couch_db "${CURR_DOC_PERSON_ATTR_TYPE}"
  get_mysql_person_id_from_couch_db "${CURR_DOC_PERSON}"

  SQL_QUERY="SELECT * FROM person_attributes WHERE person_id = '${PERSON_ID}' and person_attribute_type_id = '${PERSON_ATTRIBUTE_TYPE_ID}';";
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 

  if [[ ! -z "${PERSON_ID}" ]] ; then
    if [[ ! -z "${RESULT}" ]] ; then
      SQL_QUERY="UPDATE person_attributes SET value=\"${CURR_DOC_VALUE}\", voided=\"${CURR_DOC_VOIDED}\", void_reason=\"${CURR_VOID_REASON}\";"
      
      echo "UPDATING PERSON ATTRIBUTE: ${CURR_DOC_ID}" 
    else
      SQL_QUERY="INSERT INTO person_attributes (person_id, couchdb_person_id, couchdb_person_attribute_type_id,"
      SQL_QUERY="${SQL_QUERY} couchdb_person_attribute_id, voided, void_reason, person_attribute_type_id, value) "
      SQL_QUERY="${SQL_QUERY} VALUES(\"${PERSON_ID}\", \"${CURR_DOC_PERSON}\", \"${CURR_DOC_PERSON_ATTR_TYPE}\","
      SQL_QUERY="${SQL_QUERY} \"${CURR_DOC_ID}\", \"${CURR_DOC_VOIDED}\", \"${CURR_DOC_VOID_REASON}\","
      SQL_QUERY="${SQL_QUERY} \"${PERSON_ATTRIBUTE_TYPE_ID}\",\"${CURR_DOC_VALUE}\");"
      
      echo "INSERTING PERSON ATTRIBUTE: ${CURR_DOC_ID}" 
    fi
    `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
  fi  
}

UpdatecouchdbLocationNpid () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_NPID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['npid']"`;
  CURR_DOC_ASSIGNED=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['assigned']"`;
  CURR_DOC_LOCATION=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['location_id']"`;
  
  get_mysql_location_from_couchdb "${CURR_DOC_LOCATION}"
  
  SQL_QUERY="SELECT * FROM location_npids WHERE couchdb_location_npid_id = '${CURR_DOC_ID}';";
  RESULT=`mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`; 
  echo $RESULT 
  if [[ ! -z "${LOCATION_ID}" ]] ; then
    if [[ ! -z "${RESULT}" ]] ; then
      SQL_QUERY="UPDATE location_npids SET npid=\"${CURR_DOC_NPID}\", couchdb_location_id=\"${CURR_DOC_LOCATION}\","
      SQL_QUERY="${SQL_QUERY} location_id=\"${LOCATION_ID}\", assigned=\"${CURR_DOC_ASSIGNED}\";"
      
      echo "UPDATING LOCATION NPID: ${CURR_DOC_ID}" 
    else
      SQL_QUERY="INSERT INTO location_npids (npid, couchdb_location_id, location_id, couchdb_location_npid_id)"
      SQL_QUERY="${SQL_QUERY} VALUES(\"${CURR_DOC_NPID}\", \"${CURR_DOC_LOCATION}\", \"${LOCATION_ID}\","
      SQL_QUERY="${SQL_QUERY} \"${CURR_DOC_ID}\");"

      echo "CREATING LOCATION NPID: ${CURR_DOC_ID}" 
    fi
    `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;
  fi

}

UpdatecouchdbFootPrint () {
  echo "$1" > ../log/current_doc.txt
  CURR_DOC_ID=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['_id']"`;
  CURR_DOC_USER=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['user_id']"`;
  CURR_DOC_PERSON=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['person_id']"`;

  get_mysql_person_id_from_couch_db "${CURR_DOC_PERSON}"
  get_mysql_user_id_from_couchdb "${CURR_DOC_USER}"

  SQL_QUERY="INSERT INTO footprints (couchdb_foot_print_id, user_id, couchdb_user_id, person_id, couchdb_person_id)"
  SQL_QUERY="${SQL_QUERY} VALUE(\"${CURR_DOC_ID}\", \"${USER_ID}\", \"${CURR_DOC_USER}\", \"${PERSON_ID}\", \"${CURR_DOC_PERSON}\");"
    
  `mysql --host=$MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_QUERY"`;

}























# Check if last_sequence.txt file exists
if [ ! -e ../log/last_sequence.txt ] ; then
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
    echo "$DOC" > ../log/current_doc.txt
    TYPE=`ruby -ryaml -e "puts YAML::load_file('../log/current_doc.txt')['type']"`;

    if [[ $TYPE = "CouchdbRole" ]] ; then
      Updatecouchdbrole "$DOC"
    fi
    
    if [[ $TYPE = "CouchdbUser" ]] ; then
      Updatecouchdbuser "$DOC"
    fi
    
    if [[ $TYPE = "CouchdbPerson" ]] ; then
      UpdatecouchdbPerson "$DOC"
    fi
    
    if [[ $TYPE = "CouchdbPersonAttribute" ]] ; then
      UpdatecouchdbPersonAttribute "$DOC"
    fi
    
    if [[ $TYPE = "CouchdbLocationNpid" ]] ; then
      UpdatecouchdbLocationNpid "$DOC"
    fi
    
    if [[ $TYPE = "CouchdbFootPrint" ]] ; then
      UpdatecouchdbFootPrint "$DOC"
    fi
    echo "Updated record:  ${DOC_ID}";
  fi
done

LAST_SEQ=`ruby -ryaml -e "puts YAML::load_file('../log/latest_coucdb_docs.txt')['last_seq']"`;
echo "last_seq: ${LAST_SEQ}" > ../log/last_sequence.txt

#REP_STATUS=`curl "${COUCH_PROTOCOL}://${COUCH_USERNAME}:${COUCH_PASSWORD}@${COUCH_HOST}:${COUCH_PORT}/_active_tasks"`
#echo ${REP_STATUS} > ../log/replication_status.txt
#REP_SIZE=`ruby -ryaml -e "puts YAML::load_file('../log/replication_status.txt')['size']"`;

#if $REP_SIZE == 0 ; then
SYNC_FROM_MASTER=`eval curl -s -k -H \"Content-Type: application/json\" -X POST -d \'{\"source\": \"${SOURCE_URL}\", \"target\": \"${TARGET_URL}\", \"continuous\": true }\' \"${AUTH_TARGET_URL}/_replicate\"`
echo $SYNC_FROM_MASTER > ../log/replication_results.txt
REP_ID=`ruby -ryaml -e "puts YAML::load_file('../log/replication_results.txt')['_local_id']"`;

SYNC_TO_MASTER=`eval curl -s -k -H \"Content-Type: application/json\" -X POST -d \'{\"source\": \"${TARGET_URL}\", \"target\": \"${SOURCE_URL}\", \"continuous\": true }\' \"${AUTH_SOURCE_URL}/_replicate\"`
#else
#fi

exit;

