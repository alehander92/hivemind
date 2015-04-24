require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "hivemind"
  gem.homepage = "http://github.com/hivemind-fmi/hivemind"
  gem.license = "MIT"
  gem.summary = %Q{A compiler for the hivemind language}
  gem.description = %Q{A compiler for the hivemind languages with pluggable syntaxes}
  gem.email = "alehander42@gmail.com"
  gem.authors = ["Alexander Ivanov"]
  # dependencies defined in Gemfile
  gem.files.exclude 'spec/**/*.rb'
  gem.files.exclude 'tmp'
end

task :default => :spec
