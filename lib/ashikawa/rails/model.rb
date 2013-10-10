require 'active_support/concern'

module Ashikawa
  module Rails
    module Model
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
