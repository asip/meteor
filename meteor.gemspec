# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{meteor}
  s.version = "0.9.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["asip"]
  s.autorequire = %q{meteor}
  s.date = %q{2010-05-12}
  s.description = %q{A lightweight (X)HTML & XML parser}
  s.email = %q{ys.ashida@gmail.com}
  s.extra_rdoc_files = ["README", "ChangeLog"]
  s.files = ["README", "ChangeLog", "Rakefile", "test/meteor_test.rb", "test/test_helper.rb", "lib/meteor.rb"]
  s.has_rdoc = false
  s.homepage = %q{http://meteor.rubyforge.org}
  s.rdoc_options = ["--title", "meteor documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{meteor}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A lightweight (X)HTML & XML parser}
  s.test_files = ["test/meteor_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
