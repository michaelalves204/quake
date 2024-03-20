# frozen_string_literal: true

require_relative 'connection'

module Quake
  module Requests
    # Class responsible for http request
    class HttpService
      POST = 'POST'
      GET = 'GET'

      def initialize(file_path:, template:)
        @file_path = file_path
        @template = template
      end

      def call
        Quake::Log.new("body: #{response.body}").info

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

        case @template['method_http'].upcase
        when POST
          post_request
        when GET
          getter_request
        else
          Quake::Log.new('http method not supported').error
        end
      end

      def getter_request
        @getter_request ||= connection.get(@template['endpoint'])
      end

      def post_request
        @post_request ||= connection.post(@template['endpoint'],
                                          @template['body'].to_json)
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
