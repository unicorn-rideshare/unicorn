# MONKEYPATCH
# Reset and fix defect in Teaspoon task
# SEE: https://github.com/modeset/teaspoon/commit/80bd0d346f5b7a8c2830312a99f8baff0dd1c673#diff-183fef1f8293a17b26353fbe5ed235adR8
task(:teaspoon).clear

desc 'Run the javascript specs'
task teaspoon: :environment do
  require 'teaspoon/console'

  options = {
    files: ENV['files'].nil? ? [] : ENV['files'].split(','),
    suite: ENV['suite'],
    use_coverage: ENV['coverage'],
    driver_options: ENV['driver_options'],
  }

  abort('rake teaspoon failed') if Teaspoon::Console.new(options).failures?
end

namespace :teaspoon do
  desc 'Run the javascript specs with coverage analysis'
  task run: :environment do
    sh('env JS_COVERAGE=istanbul bundle exec teaspoon --coverage=default')
  end
end
