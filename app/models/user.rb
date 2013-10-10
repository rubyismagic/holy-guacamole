class User
  include ActiveModel::Validations
  include ActiveModel::Naming
  include Virtus.model

  attribute :name, String
  attribute :email, String

  validates_presence_of :name, :email
end
