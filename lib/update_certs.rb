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
    @logger = Logger.new('log/update_certs.log')
    @logger.progname = "#{$0}"
    @logger.info("start")
  end
  
  def read_tsv(tsvfile)
    @tsv = CSV.read(tsvfile, col_sep: "\t", headers: true, encoding: "cp932:utf-8")
  end

  def update
    @tsv.each do |row|
      dn = row[3]
      state = nil
      case row[11]
      when "7" then
        state = 33
      end
      serialnumber = row[23]
      expire_at = row[26]
      url_expire_at = row[27]
      certs = Cert.where(dn: dn)
      if certs.count == 1
        cert = certs.first
        Cert.update_by_tsv(id: cert.id, serialnumber: serialnumber, expire_at: expire_at, url_expire_at: url_expire_at, state: state)
#        @logger.info("update cert id: #{cert.id}, serialnumber: #{serialnumber}, expire_at: #{expire_at}, url_expire_at: #{url_expire_at}, state: #{state}")
      else
        @logger.warn("Can't detect target record for dn: #{dn}")
      end
    end
    @logger.info("end")
  end
end

if ARGV.count != 1 
  puts "usage: #{$0} [TSV file]"
  exit 1
end

updator = CertExpireAtUpdator.new()
updator.read_tsv(ARGV[0])
updator.update

