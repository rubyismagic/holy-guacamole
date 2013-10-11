require 'active_support/concern'

module Ashikawa
  module Rails
    module Model

      class Proxy < SimpleDelegator

        def initialize(obj, finder)
          super(obj)
          @loaded = false
          @finder = finder
        end

        def method_missing(meth, *args, &blk)
          unless @loaded
            puts "[DEBUG] Loading real object (due to: #{meth})"
            @loaded = true
            __setobj__(@finder.call)
          end
          super
        end

        def inspect
          if @loaded
            __getobj__.inspect
          else
            "<Proxy>"
          end
        end

      end

      extend ActiveSupport::Concern

      included do
        include ActiveModel::Validations
        include ActiveModel::Naming
        include ActiveModel::Conversion
        include Virtus.model

        attribute :key, String
        attribute :rev, String
        attribute :created_at, DateTime
        attribute :updated_at, DateTime
      end

      def id
        key
      end

      def persisted?
        key.present?
      end
    end
  end
end
