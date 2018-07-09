#!/usr/bin/env /usr/home/rails/shibcert/bin/rails runner
# coding: utf-8
# Local Variables:
# mode: ruby
# End:

require 'rubygems'
require 'csv'
require 'logger'

class CertExpireAtUpdator
  @tsv = nil
  def initialize()
    @logger = Logger.new('log/update_expire_at.log')
    @logger.progname = "#{$0}"
    @logger.info("start")
  end
  
  def read_tsv(tsvfile)
    @tsv = CSV.read(tsvfile, col_sep: "\t", headers: true, encoding: "shift_jis:utf-8")
  end

  def update
    @tsv.each do |row|
      dn = row[3]
      created_at = row[5]
      serialnumber = row[23]
      expire_at = row[26]
      url_expire_at = row[27]
      pre_created_at = created_at
      if created_at.present?
        created_at = DateTime.parse(created_at + '+09:00').getutc
      end
      certs = Cert.where(dn: dn)
      if certs.count == 1
        cert = certs.first
        Cert.update_expire_at(id: cert.id, serialnumber: serialnumber, expire_at: expire_at, url_expire_at: url_expire_at)
        @logger.info("update cert id: #{cert.id}, serialnumber: #{serialnumber}, expire_at: #{expire_at}, url_expire_at: #{url_expire_at}")
      else
        @logger.warn("Can't detect target record for dn: #{dn} created_at: #{created_at}")
      end
    end
    @logger.info("end")
  end
end

if ARGV.count != 3 
  puts "usage: #{$0} [TSV file]"
  exit 1
end

updator = CertExpireAtUpdator.new()
updator.read_tsv(ARGV[2])
updator.update

