# frozen_string_literal: true

require 'faraday'

module Quake
  module Requests
    # Class responsible for http connection using faraday.
    class Connection
      def initialize(base_url:, authorization:)
        @base_url = base_url
        @authorization = authorization
      end

      def start
        @start ||=
          Faraday.new(url: @base_url) do |http|
            http.headers['Content-Type'] = 'application/json'
            http.headers['Authorization'] = @authorization
            http.adapter Faraday.default_adapter
          end
      end
    end
  end
end
