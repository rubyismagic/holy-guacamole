require 'active_support/concern'

module Ashikawa
  module Rails
    module Collection
      extend ActiveSupport::Concern

      module ClassMethods
        # TODO: Memoize this
        def database
          Ashikawa::Core::Database.new do |config|
            config.url = 'http://localhost:8529'
          end
        end

        def collection
          database[collection_name]
        end

        def all
          collection.query.all.to_a
        end

        def save(model)
          collection.create_document(model.attributes)
        end

        def collection_name
          self.name.gsub(/Collection\z/,'').underscore
        end
      end
    end
  end
end

class UsersCollection
  include Ashikawa::Rails::Collection
end
