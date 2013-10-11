class Post
  include Ashikawa::Rails::Model

  attribute :title, String
  attribute :body, String
  attribute :comments, Array[Comment]
  attribute :user, User
end
