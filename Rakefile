require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "solr_wrapper/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Run only solr specs'
RSpec::Core::RakeTask.new(:solr_specs) do |task|
  file_list = FileList['solr_spec/**/*_spec.rb']
  task.pattern = file_list
end

task :solr_stuff => [:solr_specs]
