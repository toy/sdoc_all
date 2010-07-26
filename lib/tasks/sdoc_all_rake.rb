require 'sdoc_all'

task :default => :run

def run_options
  dry_run = ENV['DRY_RUN'] && %w[1 t T].include?(ENV['DRY_RUN'][0, 1])
  verbose_level = ENV['VERBOSE_LEVEL'].to_i
  {
    :dry_run => dry_run,
    :verbose_level => dry_run ? 2 : verbose_level
  }
end

desc "Build/update documentation (DRY_RUN=true to skip execution of commands (sets VERBOSE_LEVEL to 2), VERBOSE_LEVEL: 0 (default) - only progress and explanations, 1 - output commands to be executed, 2 - output result of command execution)"
task :run do
  SdocAll.run(run_options)
end

desc "Clobber documentation"
task :clobber do
  rm_rf 'docs' rescue nil
  rm_rf 'public' rescue nil
end

namespace :run do
  desc "Force update sources, before building/updating"
  task :update do
    SdocAll.run(run_options.merge(:update => true))
  end
end
