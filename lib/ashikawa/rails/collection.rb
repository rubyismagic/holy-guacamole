require 'active_support/concern'

module Ashikawa
  module Rails
    class SimpleQuery
      attr_reader :query
      attr_accessor :example

      include Enumerable

      def initialize(collection, mapper)
        @query = collection.collection.query
        @mapper = mapper
      end

      def each
        return to_enum(__callee__) unless block_given?

        iterator = ->(document) { yield @mapper.document_to_model(document) }

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
          @mapper.document_to_model(query.first_example(example))
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

        def mapper
          @mapper ||= DocumentModelMapper.new(model_class)
        end

        def all
          SimpleQuery.new(self, mapper)
        end

        # TODO: Refactor duplication
        def save(model)
          return false unless model.valid?
          stamp = Time.now
          model.created_at = stamp
          model.updated_at = stamp
          document = collection.create_document(mapper.model_to_document(model))
          model.key = document.key
          model.rev = document.revision
          model
        end

        def replace(model)
          return false unless model.valid?
          model.updated_at = Time.now
          document = collection.replace(model.key, mapper.model_to_document(model).except(:key, :rev))
          model.rev = document["_rev"]
          model
        end

        # TODO: Translate Exception
        def by_key(key)
          mapper.document_to_model(collection.fetch(key))
        end

        def by_example(example)
          query = SimpleQuery.new(self, mapper)
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

        # TODO: Rename map to something more distinct
        def map(&block)
          mapper.instance_eval(&block)
        end
      end
    end

    class DocumentModelMapper
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
        @embeds = []
        @references = {}
      end

      def embeds(attribute_name)
        @embeds << attribute_name
      end

      def references(model_name)
        attribute_name = "#{model_name}_id"
        model_class = model_name.to_s.camelize.constantize
        collection_class = "#{model_name.to_s.pluralize.camelize}Collection".constantize

        @references[attribute_name] = {
          model_class: model_class,
          collection_class: collection_class
        }
      end

      def model_to_document(model)
        document = model.attributes
        @references.each do |attribute_name, reference_info|
          referenced_model = document.delete(reference_info[:model_class].name.underscore.to_sym)
          document[attribute_name] = referenced_model.key
        end

        @embeds.each do |attribute_name|
          embedded_attribute = document[attribute_name]

          document[attribute_name] = if embedded_attribute.is_a? Array
                                       embedded_attribute.map { |embedded_model| clean_embedded_model(embedded_model) }
                                     else
                                       clean_embedded_model embedded_attribute
                                     end
        end
        document
      end

      def clean_embedded_model(model)
        document = model.attributes
        document.delete(:rev)
        document.delete(:key)
        document[:created_at] ||= Time.now
        document[:updated_at] = Time.now
        document
      end

      def document_to_model(document)
        document_hash = document.hash.dup
        @references.each do |attribute_name, reference_info|
          referenced_model_key = document_hash.delete(attribute_name)
          referenced_model = reference_info[:collection_class].by_key(referenced_model_key)
          document_hash[reference_info[:model_class].name.underscore] = referenced_model
        end

        model = model_class.new(document_hash)
        model.key = document.key
        model.rev = document.revision
        model
      end
    end
  end
end
