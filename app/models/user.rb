class User
  include Ashikawa::Rails::Model

  attribute :name, String
  attribute :email, String

  validates_presence_of :name, :email
end
