# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

puts("User.count=#{User.count}")
puts("Identity.count=#{Identity.count}")
puts("Cert.count=#{Cert.count}")

puts("...")

5.times do |n|
  Identity.create(uid: "identity#{n}", name: "identity #{n}", password: "password", email: "identity#{n}@example.com")
end

5.times do |n|
  User.create(uid: "test#{n}", name: "test #{n}", provider: 'saml', email: "test#{n}@example.com")
end

3.times do |n|
  User.create(uid: "identity#{n}", name: "identity #{n}", provider: 'identity', email: "identity#{n}@example.com")
end

users = User.all

20.times do |n|
  u = users[rand(users.size)]
  req_seq = u[:cert_serial_max] + 1
  type = [5, 7].shuffle[0]
  dn = case type
       when 5
         "CN=#{u[:uid]},OU=No #{req_seq},OU=Kyoto University Integrated Information Network System,O=Kyoto University,ST=Kyoto,C=JP"
       when 7
         "CN=#{u[:email]},OU=No #{req_seq},OU=Kyoto University Integrated Information Network System,O=Kyoto University,ST=Kyoto,C=JP"
       else
         "unknown type '#{type}'"
       end
  now = DateTime.now()
  dummy_datetime = now - rand(100)
  pin = [*'A'..'Z', *'0'..'9'].shuffle[0] * 4
  Cert.create(user_id: u[:id],
              dn: dn,
              created_at:dummy_datetime,
              get_at:dummy_datetime,
              pin_get_at: dummy_datetime+Rational(1, 24 * 60),
              pin:pin,
              req_seq: req_seq,
              state: 15,
              purpose_type: type,
              serialnumber: rand(100000000),
             )
  u[:cert_serial_max] = req_seq
  u.save
end

puts("User.count=#{User.count}")
puts("Identity.count=#{Identity.count}")
puts("Cert.count=#{Cert.count}")
