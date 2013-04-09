require File.expand_path(%q{../lib/perseus_match/version}, __FILE__)

begin
  require 'hen'

  Hen.lay! {{
    :gem => {
      :name          => %q{perseus_match},
      :version       => PerseusMatch::VERSION,
      :summary       => %q{Fuzzy string matching based on linguistic analysis},
      :author        => %q{Jens Wille},
      :email         => %q{jens.wille@gmail.com},
      :homepage      => :blackwinter,
      :exclude_files => FileList[%w[LINGO_BASE]].to_a,
      :dependencies  => ['ruby-backports', ['ruby-nuggets', '>= 0.6.7'], ['unicode', '>= 0.1.1'], 'open4']
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem first. (#{err})"
end
