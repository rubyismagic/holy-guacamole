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

        # FIXME: Find a better name
        def collection
          database[collection_name]
        end

        def model_class
          self.name.gsub(/Collection\z/,'').singularize.constantize
        end

        def document_to_model(document)
          model_class.new(document.hash)
        end

        def all
          collection.query.all.map do |document|
            document_to_model(document)
          end
        end

        def save(model)
          collection.create_document(model.attributes)
          model
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
