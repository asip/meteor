# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{meteor}
  s.version = "0.9.3.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["asip"]
  s.autorequire = %q{meteor}
  s.date = %q{2010-04-21}
  s.description = %q{A lightweight (X)HTML & XML parser}
  s.email = %q{ys.ashida@gmail.com}
  s.extra_rdoc_files = ["README", "ChangeLog"]
  s.files = ["README", "ChangeLog", "Rakefile", "doc/_index.html", "doc/class_list.html", "doc/css", "doc/css/common.css", "doc/css/full_list.css", "doc/css/style.css", "doc/file.README.html", "doc/file_list.html", "doc/frames.html", "doc/index.html", "doc/js", "doc/js/app.js", "doc/js/full_list.js", "doc/js/jquery.js", "doc/Meteor", "doc/Meteor/Attribute.html", "doc/Meteor/AttributeMap.html", "doc/Meteor/Core", "doc/Meteor/Core/Html", "doc/Meteor/Core/Html/ParserImpl.html", "doc/Meteor/Core/Html.html", "doc/Meteor/Core/Kernel.html", "doc/Meteor/Core/Util", "doc/Meteor/Core/Util/PatternCache.html", "doc/Meteor/Core/Util.html", "doc/Meteor/Core/Xhtml", "doc/Meteor/Core/Xhtml/ParserImpl.html", "doc/Meteor/Core/Xhtml.html", "doc/Meteor/Core/Xml", "doc/Meteor/Core/Xml/ParserImpl.html", "doc/Meteor/Core/Xml.html", "doc/Meteor/Core.html", "doc/Meteor/Element.html", "doc/Meteor/Hook", "doc/Meteor/Hook/Hooker.html", "doc/Meteor/Hook/Looper.html", "doc/Meteor/Hook.html", "doc/Meteor/Parser.html", "doc/Meteor/ParserFactory.html", "doc/Meteor/RootElement.html", "doc/Meteor.html", "doc/method_list.html", "doc/top-level-namespace.html", "test/meteor_test.rb", "test/test_helper.rb", "lib/meteor.rb"]
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
