$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rake'
require 'docker'
require 'rspec/core/rake_task'
require 'cane/rake_task'

task :default => [:spec, :quality]

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

Cane::RakeTask.new(:quality) do |cane|
  cane.canefile = '.cane'
end

desc 'Pull an Ubuntu image'
image 'ubuntu:13.10' do
  puts "Pulling ubuntu:13.10"
  image = Docker::Image.create('fromImage' => 'ubuntu', 'tag' => '13.10')
  puts "Pulled ubuntu:13.10, image id: #{image.id}"
end

task :console do
  exec 'bundle exec pry -r docker -I ./lib'
end

# TODO: Remove this fake task
task :testing do
  require 'docker/testing'
  container = Docker::Container.create({ 'name' => 'The_name', 'Image' => 'ubuntu:trusty', 'Hostname' => 'container-host', 'Cmd' => ['/bin/echo', 'the echo sentence'] })
  require 'pry'; binding.pry
end
