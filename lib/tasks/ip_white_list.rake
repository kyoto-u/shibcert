namespace :ip_white_list do
  desc "autodelete expired IpWhiteList"
  task autodelete: :environment do
    IpWhiteList.where(protected: false, expires_at: ...Time.now).delete_all
  end

  desc "show IpWhiteList"
  task show: :environment do
    IpWhiteList.all.each{|elm|
      if elm.protected
        puts "#{elm.ip}"
      else
        printf("%-18s\t%s\n", elm.ip, elm.expires_at)
      end
    }
  end

  desc "add IpWhiteList"
  task :add, ['ip', 'expires_at', 'memo'] => :environment do |task, args|
    pp IpWhiteList.all
    pp IpWhiteList.create(ip:args.ip, expires_at:args.expires_at, memo:args.memo)
    pp IpWhiteList.all
  end
end
