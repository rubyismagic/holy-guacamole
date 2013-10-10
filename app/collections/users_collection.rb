require 'active_support/concern'

module Ashikawa
  module Rails
    class SimpleQuery
      attr_reader :collection
      attr_accessor :example

      include Enumerable

      def initialize(collection)
        @collection = collection.collection
        @mapper = collection.method(:document_to_model)
      end

      def each
        return to_enum(__callee__) unless block_given?

        options = {}
        options[:limit] = limit if limit.present?
        options[:skip] = skip if skip.present?

        collection.query.by_example(example, options).each do |document|
          yield @mapper.call(document)
        end
      end

      def first
        @mapper.call(collection.query.first_example(example))
      end

      def limit(limit = nil)
        return @limit if limit.nil?
        @limit = limit
        self
      end

      def skip(skip = nil)
        return @skip if skip.nil?
        @skip = skip
        self
      end
    end

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
          model = model_class.new(document.hash)
          model.key = document.key
          model.rev = document.revision
          model
        end

        def all
          collection.query.all.map do |document|
            document_to_model(document)
          end
        end

        # TODO: Refactor duplication
        def save(model)
          return false unless model.valid?
          document = collection.create_document(model.attributes)
          model.key = document.key
          model.rev = document.revision
          model
        end

        def replace(model)
          return false unless model.valid?
          document = collection.replace(model.key, model.attributes.except(:key, :rev))
          model.rev = document["_rev"]
          model
        end

        # TODO: Translate Exception
        def by_key(key)
          document_to_model(collection.fetch(key))
        end

        def by_example(example)
          query = SimpleQuery.new(self)
          query.example = example
          query
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
