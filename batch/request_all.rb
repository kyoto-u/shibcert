#require 'date'

class RequestAll
  def self.execute
    tsv = RaReq.requestAll();
    num = 0
    tsv.each { |line|
      num += 1
      puts "[" << num.to_s << "] " << line["発行・更新申請-申請ID"] << ", " << line["主体者DN"]
    }
    puts "Total Count = " << num.to_s
  end
end

RequestAll.execute
