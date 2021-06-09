#!/usr/bin/env /usr/home/rails/shibcert/bin/rails runner
# coding: utf-8
# Local Variables:
# mode: ruby
# End:

# usage:
# cd shibcert/
# bundle exec rails runner -e production lib/revoke_certs_of_deactive_users.rb <people-yyyymmdd-HHMMSS.tsv>
#

require 'rubygems'
require 'csv'
require 'logger'

certs = Cert.where(state: 15).where('expire_at > ?', Date.today)
certs_of = Hash.new{|hash, key| hash[key] = []}
certs.each do |cert|
    certs_of[cert.user.uid] << [cert.dn, cert.serialnumber]
end

CSV.foreach(ARGV[2], col_sep: "\t", headers: true) do |user|
    if certs_of.has_key?(user['uid'])
         certs_of.delete(user['uid'])
    end
end

certs_of.each do |user, certs|
    certs.each do |cert|
        puts [cert[0], "", "", cert[1], 5,
              "deactive", "", "", "", "",
              "", "", "", "", ""].join("\t")
    end
end
