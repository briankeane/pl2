# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application

# REMOVE IF ACTIVERECORD CONNECTION TIMEOUTS STILL OCCUR
use ActiveRecord::ConnectionAdapters::ConnectionManagement
