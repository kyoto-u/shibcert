#!/bin/sh

PATH=/opt/rbenv/bin/:$PATH
eval "$(rbenv init -)"

echo `dirname $0`/../../
cd `dirname $0`/../../
bundle exec rails runner -e production lib/mail_processor.rb
