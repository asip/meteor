#!bin ruby
# -* coding: UTF-8 -*-

require 'rubygems'
require 'meteor'
#require '../lib/meteor'

pf = Meteor::ParserFactory.new
#pf.parser(Meteor::Parser::XML,'sample.xml', 'UTF-8')
pf.parser(Meteor::Parser::XML,'sample.xml')

ps = pf.parser('sample')

start_time = Time.new.to_f

elm1 = ps.element('test','manbo','manbo')
#elm1 = ps.element("manbo","manbo")
#elm2 = ps.element("potato","id","aa","id2","bb")
elm3 = ps.element("potato","id","aa")
#elm4 = ps.element("potato2","id","aa","id2","bb")
elm7 = ps.element("kobe")
#elm8 = ps.element("manbo","mango")

#elm9 = ps.element("hamachi","id","aa",'id2','bb')
#elm_c1 = ps.cxtag("cs")

#elm8.attr("manbo","mangoo")

#puts elm7.attributes

#ps.attr(elm1,"id2","cc")
#elm1["id2"]="cc"

#ps.attr(elm8,"manbo","mangoo")
##elm9.content("¥¥1")
#elm9.content = "¥¥1"

#elm2.attr('id3','cc')
#elm3.attr('id3','cc')
elm3['id3'] = 'cc'
#elm4.attr('id3','cc')
#elm9.attr('id3','cc')

#co_ps = elm1.child()
##map = co_ps.attr_map
##map.names.each { |item| 
##  puts item
##  puts map.fetch(item)
##}

elm_ = ps.element(elm1)
elm5_ = elm_.child('tech')
10.times do |i|
  elm_['manbo'] = i.to_s
  elm5 = elm5_.clone
  elm5['mono'] = i.to_s
  elm5.content = i.to_s
  elm_.flush
end

#am3 = ps.attr_map(elm3)
#am3.names.each { |item| 
#  puts item
#  puts am3.fetch(item)
#}

elm_ = ps.element(elm7)

10.times { |i|
  elm_["momo"]= i.to_s
  elm_["eco"] = "縺医∪"
  elm_.content = i.to_s
  #elm_["content"] = i.to_s
  elm_.flush
}

#co_ps = ps.child(elm_c1)
#
#10.times { |i|
#  #co_ps.content(i.to_s)
#  co_ps[":content"]=i.to_s
#  co_ps.flush
#}

ps.flush

#elm3.attr('id3','dd')

end_time = Time.new.to_f

puts ps.document

puts '' + (end_time - start_time).to_s + ' sec'

#start_time = Time.new.to_f
#obj = eval("¥"#{elm3.name}¥"")
#end_time = Time.new.to_f
#puts '' + (end_time - start_time).to_s + ' sec'
#puts obj

#start_time = Time.new.to_f
#obj = elm3.name
#end_time = Time.new.to_f
#puts '' + (end_time - start_time).to_s + ' sec'
#puts obj