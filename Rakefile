require 'rake/testtask'

task default: :test

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

namespace :test do
  desc "Run data validation tests only"
  Rake::TestTask.new(:data) do |t|
    t.pattern = "test/validators/ev_data_test.rb"
  end

  desc "Run charging validation tests only"
  Rake::TestTask.new(:charging) do |t|
    t.pattern = "test/validators/charging_validator_test.rb"
  end

  desc "Run vehicle creator tests only"
  Rake::TestTask.new(:vehicle) do |t|
    t.pattern = "test/vehicle_creator_test.rb"
  end
end 