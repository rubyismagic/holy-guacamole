class User
  include Ashikawa::Rails::Model

  attribute :name, String
  attribute :email, String
  attribute :posts, Array[Post], coerce: false

  validates_presence_of :name, :email
end
