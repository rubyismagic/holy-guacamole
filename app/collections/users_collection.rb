class UsersCollection
  include Ashikawa::Rails::Collection

  map do
    referenced_by :posts
  end
end
