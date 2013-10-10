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

class User
  include Ashikawa::Rails::Model

  attribute :name, String
  attribute :email, String

  validates_presence_of :name, :email
end
