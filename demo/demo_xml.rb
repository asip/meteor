#!bin ruby
# -* coding: UTF-8 -*-

#require 'rubygems'
#require 'meteor'
require '../lib/meteor'

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
#elm7 = ps.element("kobe")
#elm8 = ps.element("manbo","mango")

#elm9 = ps.element("hamachi","id","aa",'id2','bb')
#elm_c1 = ps.cxtag("cs")

#elm8.attribute("manbo","mangoo")

#puts elm7.attributes

#ps.attribute(elm1,"id2","cc")
#elm1["id2"]="cc"

#ps.attribute(elm8,"manbo","mangoo")
#ps.content(elm9,"\\1")

#elm2.attribute('id3','cc')
elm3.attribute('id3','cc')
#elm4.attribute('id3','cc')
#elm9.attribute('id3','cc')

#co_ps = ps.child(elm1)
##map = co_ps.attributeMap
##map.names.each { |item| 
##  puts item
##  puts map.fetch(item)
##}
#elm5_ = co_ps.element('tech')
##p elm5_.clone_id
##elm5_ = co_ps.element('tech','mono','mono')
#10.times do |i|
#  co_ps['manbo'] = i.to_s
#  #co_ps["momo"] = "\\" + i.to_s
#  #puts co_ps["manbo"]
#  #elm5 = Meteor::Element.new(elm5_)
#  elm5 = Meteor::Element.new!(elm5_)
#  #p elm5.clone_id
#  #elm5 = co_ps.element('tech')
#  #co_ps.attribute(elm5,"eco","ema")
#  #elm5.attribute("eco","ema")
#  #if i % 2 == 0 then
#  elm5['mono'] = i.to_s
#  #end
#  #elm5['momo'] = '\\' + i.to_s
#  #elm5['mooo'] = i.to_s
#  #elm5['eco']="ema"
#  #co_ps.content(elm5,i.to_s)
#  #elm5[':content'] = '<>"' << i.to_s
#  #elm5[':content'] = i.to_s
#  elm5.content = i.to_s
#  #puts elm5[':content']
#  #puts co_ps.rootElement.mutableElement.pattern
#  co_ps.print
#end
#co_ps.flush

elm_ = ps.element(elm1)
elm5_ = elm_.child('tech')
10.times do |i|
  elm_['manbo'] = i.to_s
  elm5 = elm5_.clone
  elm5['mono'] = i.to_s
  elm5.content = i.to_s
  elm_.flush
end
#elm_.flush

#am3 = ps.attributeMap(elm3)
#am3.names.each { |item| 
#  puts item
#  puts am3.fetch(item)
#}

#elm_ = ps.element(elm7)
#
#10.times { |i|
#  elm_["momo"]= i.to_s
#  elm_["eco"] = "えま"
#  #elm_.content = i.to_s
#  elm_[":content"] = i.to_s
#  elm_.print
#}
#elm_.flush

#co_ps = ps.child(elm_c1)
#
#10.times { |i|
#  #co_ps.content(i.to_s)
#  co_ps[":content"]=i.to_s
#  co_ps.print
#}
#co_ps.flush

ps.flush

#elm3.attribute('id3','dd')

end_time = Time.new.to_f

#ps.flush

puts ps.document

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