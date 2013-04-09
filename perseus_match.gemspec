# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{perseus_match}
  s.version = "0.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jens Wille"]
  s.date = %q{2011-04-29}
  s.description = %q{Fuzzy string matching based on linguistic analysis}
  s.email = %q{jens.wille@gmail.com}
  s.executables = ["perseus_match"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["lib/perseus_match/token.rb", "lib/perseus_match/token_set.rb", "lib/perseus_match/cluster.rb", "lib/perseus_match/version.rb", "lib/perseus_match/core_ext.rb", "lib/perseus_match/list.rb", "lib/perseus_match.rb", "bin/perseus_match", "README", "ChangeLog", "Rakefile", "COPYING", "example/lingo.cfg", "example/phrases.txt", "example/check.csv", "example/config.yaml", "spec/perseus_match/cluster_spec.rb", "spec/perseus_match/list_spec.rb", "spec/perseus_match/token_spec.rb", "spec/perseus_match/token_set_spec.rb", "spec/perseus_match_spec.rb", "spec/spec.opts", "spec/spec_helper.rb"]
  s.homepage = %q{http://prometheus.rubyforge.org/perseus_match}
  s.rdoc_options = ["--line-numbers", "--main", "README", "--charset", "UTF-8", "--all", "--title", "perseus_match Application documentation (v0.0.8)"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{prometheus}
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Fuzzy string matching based on linguistic analysis}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-backports>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-nuggets>, [">= 0.6.7"])
      s.add_runtime_dependency(%q<unicode>, [">= 0.1.1"])
      s.add_runtime_dependency(%q<open4>, [">= 0"])
    else
      s.add_dependency(%q<ruby-backports>, [">= 0"])
      s.add_dependency(%q<ruby-nuggets>, [">= 0.6.7"])
      s.add_dependency(%q<unicode>, [">= 0.1.1"])
      s.add_dependency(%q<open4>, [">= 0"])
    end
  else
    s.add_dependency(%q<ruby-backports>, [">= 0"])
    s.add_dependency(%q<ruby-nuggets>, [">= 0.6.7"])
    s.add_dependency(%q<unicode>, [">= 0.1.1"])
    s.add_dependency(%q<open4>, [">= 0"])
  end
end
