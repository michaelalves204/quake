# frozen_string_literal: true

require 'rake'
require_relative './lib/quake/requests/start_service'

namespace :quake do
  desc 'start quake'

  task :start_service, [:file_path] do |_t, args|
    file_path = args[:file_path] || './templates/exams/load.json'
    Quake::Requests::StartService.new(file_path: file_path).call
  end
end
