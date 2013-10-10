require 'active_support/concern'

module Ashikawa
  module Rails
    class SimpleQuery
      attr_reader :query
      attr_accessor :example

      include Enumerable

      def initialize(collection)
        @query = collection.collection.query
        @mapper = collection.method(:document_to_model)
      end

      def each
        return to_enum(__callee__) unless block_given?

        iterator = ->(document) { yield @mapper.call(document) }

        if example
          query.by_example(example, options).each(&iterator)
        else
          query.all(options).each(&iterator)
        end
      end

      def first
        if limit or skip or example.blank?
          to_a.first
        else
          @mapper.call(query.first_example(example))
        end
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

      private

      def options
        options = {}
        options[:limit] = limit if limit.present?
        options[:skip] = skip if skip.present?
        options
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
          SimpleQuery.new(self)
        end

        # TODO: Refactor duplication
        def save(model)
          return false unless model.valid?
          stamp = Time.now
          model.created_at = stamp
          model.updated_at = stamp
          document = collection.create_document(model.attributes)
          model.key = document.key
          model.rev = document.revision
          model
        end

        def replace(model)
          return false unless model.valid?
          model.updated_at = Time.now
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

        # TODO: Exception Translation
        def delete(key)
          collection.fetch(key).delete
          key
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
