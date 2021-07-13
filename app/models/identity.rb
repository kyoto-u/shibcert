class Identity < OmniAuth::Identity::Models::ActiveRecord
  validates_uniqueness_of :uid
  validates_uniqueness_of :email
  validates_format_of :email, :with => /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i
  has_secure_password

  auth_key :uid

  scope :by_email_like, lambda {|email|
    where('email LIKE :value', { value: "#{sanitize_sql_like(email)}%"})
  }
end
