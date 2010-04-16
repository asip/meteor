#!bin ruby
# -* coding: UTF-8 -*-

#require 'rubygems'
#require 'meteor'
require '../lib/meteor'

pf = Meteor::ParserFactory.new
pf.parser(Meteor::Parser::XHTML,"sample_x.html", "UTF-8")

ps = pf.parser('sample_x')

startTime = Time.new.to_f

elm_hello = ps.element("id","hello")
ps.attr(elm_hello,"color","red")
#elm_hello.remove_attr('color')

elm_hello2 = ps.element("id","hello2")
ps.content(elm_hello2,"Hello,Tester")
#elm_hello2.remove
#elm_hello3 = ps.cxtag("hello3")
#ps.content(elm_hello3,"Hello,Hello\ntt")
#puts elm_hello3.content
#puts elm_hello3.mixed_content

#elm_text1 = ps.element("id","text1")
#ps.attr(elm_text1,"value","めも")
#ps.attr(elm_text1,"disabled",true)
#map = elm_text1.attr_map
#map.names.each { |item| 
#  puts item
#  puts map.fetch(item)
#}

#elm_radio1 = ps.element("input","id","radio1","type","radio")
#ps.attribute(elm_radio1,"checked","true")

#elm_select1 = ps.element("select","id","select1")
#elm_select1 = ps.element("select")
#ps.attr(elm_select1,"multiple",true)
#puts ps.attr(elm_select1,"multiple")
#elm_option1 = ps.element("option","id","option1")
#ps.attr(elm_option1,"selected","true")
#puts ps.attr(elm_option1,"selected")
#puts ps.attr(elm_text1,"readonly")

#elm_select2 = ps.element("select","id","select2")
#elm_select2["multiple"] = "true"
#elm_option2 = ps.element("option","id","option2")
#co_ps = ps.child(elm_option2)
#10.times { |i|
#  if i == 1 then
#    co_ps.attr("selected","true")
#  else
#    co_ps.attr("selected","false")
#  end
#  co_ps.attr("value",i.to_s)
#  co_ps.remove_attr("id")
#  co_ps.content(i.to_s)
#  co_ps.flush
#}

elm_tr1 = ps.element('tr','id','loop')
elm_ = ps.element(elm_tr1)
elm_dt1_ = elm_.child('id','aa')
elm_dt2_ = elm_.child('id','bb')
elm_dt3_ = elm_.child('id','cc')
10.times { |i|
  elm_['loop'] = i.to_s
  elm_dt1 = elm_dt1_.clone
  elm_dt2 = elm_dt2_.clone
  elm_dt3 = elm_dt3_.clone
  #elm_dt1.content("<>\"' \n" << i.to_s)
  elm_dt1.content=i.to_s
  elm_dt2.content=i.to_s
  elm_dt3.content=i.to_s
  elm_.flush
}

ps.flush

endTime = Time.new.to_f

puts ps.document

puts '' + (endTime - startTime).to_s + ' sec'