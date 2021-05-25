#!/bin/bash -ex

url='localhost:5984'

#check if couchdb is running
service=couchdb
if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
then
    curl $url || service couchdb restart
fi

if [ $? -eq 0 ]; then
  echo "Couchdb is Responsive"
else
    if [ $? -eq 7 ]  
    then 
        service couchdb restart
        if [ $? -eq 0 ]; then
            echo "couchdb restarted successfully"
        else
            echo "Something went wrong"
        fi
    else
        service couchdb restart
        if [ $? -eq 0 ]; then
            echo "couchdb restarted successfully"
        else
            echo "Something went wrong"
        fi    
    fi
fi
