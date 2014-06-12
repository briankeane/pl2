require './lib/pl.rb'
require 'rspec'
#require_relative 'shared/shared_database.rb'

# RSpec.configure do |config|
#   # Configure each test to always use a new singleton instance
#   config.before(:each) do
#     PL::Database.instance_variable_set(:@__db_instance, nil)
#   end
# end

RSpec.configure do |config|
 # Use color in STDOUT
   # config.color = true

 # Use color not only in STDOUT but also in pagers and files
   config.tty = true

 # Use the specified formatter
   config.formatter = :documentation # :progress, :html, :textmate
end