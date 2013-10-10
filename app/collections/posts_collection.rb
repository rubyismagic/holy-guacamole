class PostsCollection
  include Ashikawa::Rails::Collection

  map do
    embeds :comments
  end
end
