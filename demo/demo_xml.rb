#!bin ruby
# -* coding: UTF-8 -*-

#require 'rubygems'
require 'meteor'

Meteor::ElementFactory.link(Meteor::XML,'ml/sample.xml', 'UTF-8')
root = Meteor::ElementFactory.element('ml/sample')

start_time = Time.new.to_f

#elm_ =  root.element('kobe')
#puts elm_.name
#puts elm_.attributes
#puts elm_.mixed_content
#puts elm_.text

#elm_ =  root.element('test')
#puts elm_.name
#puts elm_.attributes
#puts elm_.mixed_content

elm1 = root.element('test', manbo: 'manbo')  #elm1 = root.element(manbo: "manbo")
#elm2 = root.element(id: "aa", id2: "bb")    #elm2 = root.element("id"=>"aa")
#elm3 = root.element("potato", id: "aa")
#elm4 = root.element("potato", id: "aa", id2: "bb")  #elm4 = root.element("potato", id2: "bb")

elm7 = root.element("kobe")
#elm7 = root.element(momo: "mono")
#elm8 = root.element(manbo: "mango")
#elm8 = root.element(momo: "momo")

#elm9 = root.element("hamachi",id: "aa",id2: 'bb')
#elm_c1 = root.cxtag("cs")

#puts elm8.name
#puts elm8.attributes
#puts elm8.mixed_content

#elm1.attr(id2: "cc")
#elm1["id2"] = "cc"

#elm8['mango'] = "mangoo"  #elm8.attr(manbo: "mangoo")
#elm9.content = "\\1"      #elm9.content("\\1")

#elm2.attr(id3: 'cc')

#elm3['id3'] = 'cc'  #elm3.attr(id3: 'cc')
#elm3['id3'] = 'cc'  #elm4.attr(id3: 'cc')
#elm9['id3'] = 'cc'  #elm9.attr(id3: 'cc')

#co_elm = elm1.element()
#map = co_elm.attr_map
#map.names.each { |item|
#  puts item
#  puts map.fetch(item)
#}

elm_ = root.element(elm1)
elm5_ = elm_.element('tech')
10.times do |i|
  elm_['manbo'] = i.to_s
  elm5 = elm5_.clone
  elm5['mono'] = i.to_s
  elm5.content = i.to_s
  elm_.flush
end

#am3 = elm3.attr_map
#am3.names.each { |item|
#  puts item
#  puts am3.fetch(item)
#}

elm_ = root.element(elm7)

10.times { |i|
  elm_["momo"]= i
  elm_["eco"] = "えま"
  elm_.content = i  #elm_["content"] = i.to_s
  elm_.flush
}

#co_elm = root.element(elm_c1)
#
#10.times { |i|
#  #co_elm.content(i)
#  co_elm.content =i
#  co_elm.flush
#}

root.flush

#elm3.attr(id3: 'dd')

end_time = Time.new.to_f

puts root.document

#elms = root.elements("potato2")
##elms = root.elements("kobe")
#elms = root.elements("potato")

elms = root.elements("test")
elms.each{|elm|
  puts elm.document
  puts elm.attributes
  puts elm.mixed_content
}

puts '' + (end_time - start_time).to_s + ' sec'

#start_time = Time.new.to_f
#obj = eval("\"#{elm3.name}\"")
#end_time = Time.new.to_f
#puts '' + (end_time - start_time).to_s + ' sec'
#puts obj

#start_time = Time.new.to_f
#obj = elm3.name
#end_time = Time.new.to_f
#puts '' + (end_time - start_time).to_s + ' sec'
#puts obj
