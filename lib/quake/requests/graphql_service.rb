# frozen_string_literal: true

require_relative 'connection'
require_relative '../log'

module Quake
  module Requests
    # Class responsible for graphql request.
    class GraphqlService
      def initialize(file_path:, template:)
        @file_path = file_path
        @template = template
      end

      def call
        Quake::Log.new(response.body).info

        object_response
      rescue StandardError => e
        Quake::Log.new(e).error
      end

      def object_response
        {
          status: response.status,
          body: response.body,
          request_duration_time: Time.now - @duration_time
        }
      end

      private

      def response
        @response ||=
          @duration_time = Time.now

        graphql_request
      end

      def graphql_request
        @graphql_request ||= connection.post(@template['endpoint'], body.to_json)
      end

      def body
        {
          query: query,
          variables: @template['body']['variables']
        }
      end

      def query
        @query ||= begin
          graphql_query_path = "#{File.dirname(@file_path)}/query.graphql"

          File.open(graphql_query_path, 'r', &:read)
        end
      end

      def authorization
        @template['headers']['Authorization']
      rescue StandardError
        nil
      end

      def connection
        Quake::Requests::Connection.new(
          base_url: @template['base_url'],
          authorization: authorization
        ).start
      end
    end
  end
end
