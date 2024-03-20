# frozen_string_literal: true

require_relative '../templates/read'
require_relative '../templates/result/create'
require_relative 'http_service'
require_relative 'graphql_service'
require_relative '../log'
require 'json'

module Quake
  module Requests
    # class responsible for starting stress testing in apis.
    class StartService
      REST = 'REST'
      GRAPHQL = 'GRAPHQL'
      FIFTY_MILLISECONDS = 0.05
      TWO_HUNDRED_MILLISECONDS = 0.2
      FIVE_HUNDRED_MILLISECONDS = 0.5
      ONE_SECOND = 1

      def initialize(file_path:)
        @file_path = file_path
        reset_counters
        request_metric
        @start_at = Time.now
      end

      def call
        stress_test

        Quake::Log.new(result_stress_test).info

        create_result_file(result_stress_test)
      rescue StandardError => e
        Quake::Log.new(e).error
      end

      private

      def create_result_file(result_stress_test)
        Quake::Templates::Result::Create.new(
          file_path: @file_path,
          content: result_stress_test
        ).call
      end

      def result_stress_test
        {
          result: {
            average_time_of_requests: (@sum_of_request_times / number_of_requests),
            slower_request: @slower_request,
            faster_request: @faster_request,
            test: {
              start_at: @start_at,
              end_at: Time.now
            },
            status: status_response_count,
            requests_time: request_time_response_count
          }
        }
      end

      def stress_test
        request_count = number_of_requests

        threads = []

        request_count.times do
          threads << Thread.new do
            request_report
          end

          if threads.size >= threads_count
            threads.first.join
            threads.shift
          end
        end

        threads.each(&:join)
      end

      def request_report
        @status, @request_duration_time = request.values_at(:status, :request_duration_time)

        status_count_report(@status)
        request_duration_time_report(@request_duration_time)
        sum_of_request_times
        request_speed

        Quake::Log.new("status: #{@status}").info
      end

      def sum_of_request_times
        @sum_of_request_times += @request_duration_time
      end

      def request_speed
        @faster_request = @request_duration_time if @faster_request == 0.0
        @faster_request = @request_duration_time if @request_duration_time < @faster_request
        @slower_request = @request_duration_time if @request_duration_time > @slower_request
      end

      def status_response_count
        {
          "1xx": @continue_status,
          "2xx": @success_status,
          "3xx": @redirect_status,
          "4xx": @client_error_status,
          "5xx": @server_error_status
        }
      end

      def request_time_response_count
        {
          "< 50ms": @lowest_fifty_milliseconds_count,
          "> 50ms < 200ms": @greater_than_fifty_and_lowest_two_hundred_milliseconds_count,
          "> 200ms < 500ms": @greater_than_two_hundred_and_lowest_five_hundred_milliseconds_count,
          "> 500 < 1 second": @greater_than_five_hundred_milliseconds_and_lowest_one_second,
          ">= 1 second": @greater_than_or_equal_to_one_second_count
        }
      end

      def request_duration_time_report(request_duration_time)
        case request_duration_time
        when ->(value) { value < FIFTY_MILLISECONDS }
          @lowest_fifty_milliseconds_count += 1
        when ->(value) { value < TWO_HUNDRED_MILLISECONDS }
          @greater_than_fifty_and_lowest_two_hundred_milliseconds_count += 1
        when ->(value) { value < FIVE_HUNDRED_MILLISECONDS }
          @greater_than_two_hundred_and_lowest_five_hundred_milliseconds_count += 1
        when ->(value) { value < ONE_SECOND }
          @greater_than_five_hundred_milliseconds_and_lowest_one_second += 1
        else
          @greater_than_or_equal_to_one_second_count += 1
        end
      end

      def status_count_report(status)
        type_status = status.to_s[0].to_i

        case type_status
        when 1 then @continue_status += 1
        when 2 then @success_status += 1
        when 3 then @redirect_status += 1
        when 4 then @client_error_status += 1
        when 5 then @server_error_status += 1
        else
          Quake::Log.new('invalid request').error
        end
      end

      def number_of_requests
        @request_count ||= template.dig('config', 'number_of_requests').to_i
        @request_count.zero? ? 1 : @request_count
      end

      def request
        case template['type'].upcase
        when REST then http_service.call
        when GRAPHQL then graphql_service.call
        else
          Quake::Log.new('invalid type').error
        end
      end

      def http_service
        Quake::Requests::HttpService.new(file_path: @file_path, template: @template)
      end

      def graphql_service
        Quake::Requests::GraphqlService.new(file_path: @file_path, template: @template)
      end

      def threads_count
        max_thread_number = template.dig('config', 'max_threads_number').to_i

        return 3 if max_thread_number.zero? || max_thread_number < 1 || max_thread_number.nil?
        return 10 if max_thread_number > 10

        max_thread_number
      end

      def template
        @template ||= Quake::Templates::Read.new(file_path: @file_path).call
      end

      def request_metric
        @sum_of_request_times = 0.0
        @faster_request = 0.0
        @slower_request = 0.0
      end

      def reset_counters
        @continue_status = 0
        @success_status = 0
        @redirect_status = 0
        @client_error_status = 0
        @server_error_status = 0
        @lowest_fifty_milliseconds_count = 0
        @greater_than_fifty_and_lowest_two_hundred_milliseconds_count = 0
        @greater_than_two_hundred_and_lowest_five_hundred_milliseconds_count = 0
        @greater_than_five_hundred_milliseconds_and_lowest_one_second = 0
        @greater_than_or_equal_to_one_second_count = 0
      end
    end
  end
end
