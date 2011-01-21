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
      :dependencies => ['ruby-backports', ['ruby-nuggets', '>= 0.6.7'], ['unicode', '>= 0.1.1'], 'open4']
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem first. (#{err})"
end

### Place your custom Rake tasks here.
