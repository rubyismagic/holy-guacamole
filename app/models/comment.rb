class Comment
  include Ashikawa::Rails::Model

  attribute :body, String
  attribute :user_name, String
end
