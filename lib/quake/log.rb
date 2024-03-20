# frozen_string_literal: true

require 'logger'

module Quake
  # Class for logging Quake related logs.
  class Log
    def initialize(message)
      @logger = Logger.new($stdout)
      @message = message
    end

    def error
      @logger.level = Logger::ERROR

      @logger.error(@message)
    end

    def info
      @logger.info(@message)
    end
  end
end
