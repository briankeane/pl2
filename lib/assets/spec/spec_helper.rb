ENV['RAILS_ENV'] = 'test'

require './lib/pl.rb'
require 'rspec'
require 'vcr'
require_relative 'shared/shared_database.rb'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
end


RSpec.configure do |config|
  # Configure each test to always use a new singleton instance
  config.before(:each) do
    PL::Database.instance_variable_set(:@__db_instance, nil)
    PL.db.clear_everything
  end
end

RSpec.configure do |config|
 # Use color in STDOUT
   # config.color = true

 # Use color not only in STDOUT but also in pagers and files
   config.tty = true

 # Use the specified formatter
   config.formatter = :documentation # :progress, :html, :textmate

   config.filter_run focus: true
   config.run_all_when_everything_filtered = true
   config.filter_run_excluding :slow unless ENV['SLOW_SPECS']
end