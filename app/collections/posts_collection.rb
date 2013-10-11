class PostsCollection
  include Ashikawa::Rails::Collection

  map do
    embeds :comments
    references :user
  end
end
