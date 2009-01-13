# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{perseus_match}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jens Wille"]
  s.date = %q{2009-01-13}
  s.default_executable = %q{perseus_match}
  s.description = %q{Fuzzy string matching based on linguistic analysis}
  s.email = %q{jens.wille@uni-koeln.de}
  s.executables = ["perseus_match"]
  s.extra_rdoc_files = ["COPYING", "ChangeLog", "README"]
  s.files = ["lib/perseus_match/list.rb", "lib/perseus_match/version.rb", "lib/perseus_match/token_set.rb", "lib/perseus_match/cluster.rb", "lib/perseus_match.rb", "bin/perseus_match", "Rakefile", "COPYING", "ChangeLog", "README", "spec/spec_helper.rb", "spec/perseus_match/list_spec.rb", "spec/perseus_match/cluster_spec.rb", "spec/perseus_match/token_set_spec.rb", "spec/perseus_match_spec.rb", "sample/config.yaml", "sample/lingo.cfg", "sample/phrases.txt", "sample/check.csv"]
  s.has_rdoc = true
  s.homepage = %q{http://prometheus.rubyforge.org/perseus_match}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "perseus_match Application documentation", "--main", "README", "--charset", "UTF-8", "--all"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{prometheus}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Fuzzy string matching based on linguistic analysis}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-backports>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-nuggets>, [">= 0.4.0"])
    else
      s.add_dependency(%q<ruby-backports>, [">= 0"])
      s.add_dependency(%q<ruby-nuggets>, [">= 0.4.0"])
    end
  else
    s.add_dependency(%q<ruby-backports>, [">= 0"])
    s.add_dependency(%q<ruby-nuggets>, [">= 0.4.0"])
  end
end
