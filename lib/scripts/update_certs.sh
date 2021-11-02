#!/bin/sh

echo `dirname $0`/../../
cd `dirname $0`/../../

echo "rake db:data:dump ..."
bundle exec rake db:data:dump
mv db/data.yml db/data-`date '+%Y%m%d-%H%M%S'`.yml

echo "lib/update_certs.rb ..."
bundle exec rails runner -e production lib/update_certs.rb $1 
