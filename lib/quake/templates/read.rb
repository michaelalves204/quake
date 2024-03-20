# frozen_string_literal: true

require 'json'

module Quake
  module Templates
    EXTENSIONS = ['JSON'].freeze
    # class responsible for reading files.
    class Read
      def initialize(file_path:)
        @file_path = file_path
      end

      def call
        JSON.parse(file)
      end

      private

      def extension
        @file_path.split('.').last.upcase
      end

      def file
        return unless EXTENSIONS.include?(extension)

        @file ||= File.open(@file_path, 'r', &:read)
      end
    end
  end
end
