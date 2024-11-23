require 'rake/testtask'

task default: :test

desc "Run all tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Run cli creator tests only"
Rake::TestTask.new(:test_cli) do |t|
  t.pattern = "test/vehicle_creator_test.rb"
end

desc "Run data validation tests only"
Rake::TestTask.new(:test_data) do |t|
  t.pattern = "test/validators/ev_data_test.rb"
end

desc "List all available tasks"
task :list do
  puts "\nAvailable tasks:"
  puts "rake test         # Run all tests"
  puts "rake test_cli     # Run CLI tests only"
  puts "rake test_data    # Run data validation tests only"
  puts "rake list         # Show this list"
end 