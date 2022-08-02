namespace :ip_white_list do
  desc "autodelete expired IpWhiteList"
  task autodelete: :environment do
    IpWhiteList.where(protect: false, expired_at: ...Time.now).delete_all
  end

  desc "show IpWhiteList"
  task show: :environment do
    IpWhiteList.all.each{|elm|
      if elm.protect
        puts "#{elm.ip}"
      else
        printf("%-18s\t%s\n", elm.ip, elm.expired_at)
      end
    }
  end

  desc "add IpWhiteList"
  task :add, ['ip', 'expired_at', 'memo'] => :environment do |task, args|
    pp IpWhiteList.all
    pp IpWhiteList.create(ip:args.ip, expired_at:args.expired_at, memo:args.memo)
    pp IpWhiteList.all
  end
end
