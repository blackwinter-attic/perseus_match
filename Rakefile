require %q{lib/perseus_match/version}

begin
  require 'hen'

  Hen.lay! {{
    :rubyforge => {
      :project => %q{prometheus},
      :package => %q{perseus_match}
    },

    :gem => {
      :version      => PerseusMatch::VERSION,
      :summary      => %q{Fuzzy string matching based on linguistic analysis},
      :files        => FileList['lib/**/*.rb', 'bin/*'].to_a,
      :extra_files  => FileList['[A-Z]*', 'spec/**/*.rb', 'sample/**/*'].to_a - %w[LINGO_BASE],
      :dependencies => ['ruby-backports', ['ruby-nuggets', '>= 0.4.0'], ['unicode', '>= 0.1.1']]
    }
  }}
rescue LoadError
  abort "Please install the 'hen' gem first."
end

### Place your custom Rake tasks here.
