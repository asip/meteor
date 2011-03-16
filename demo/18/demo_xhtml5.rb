#!bin ruby
# -* coding: UTF-8 -*-

require 'rubygems'
require 'meteor'
#require '../lib/meteor'

pf = Meteor::ParserFactory.new
pf.parser(Meteor::Parser::XHTML5,"sample_x5.html", "UTF-8")

ps = pf.parser('sample_x5')

startTime = Time.new.to_f

elm_hello = ps.element("id","hello")
#elm_hello.attr("color","red")
elm_hello['color'] = 'red'
#elm_hello.remove_attr('color')

elm_hello2 = ps.element("id","hello2")
#elm_hello2.content("Hello,Tester")
elm_hello2.content = "Hello,Tester"

#elm_hello2.remove
#elm_hello3 = ps.cxtag("hello3")
##elm_hello3.content("Hello,Hello\ntt")
#elm_hello3.content = "Hello,Hello\ntt"
#puts elm_hello3.content
#puts elm_hello3.mixed_content

elm_text1 = ps.element("id","text1")
#elm_text1.attr("value","めも")
elm_text1['value'] = 'めも'
#elm_text1.attr("disabled",true)
elm_text1['disabled'] = true
#elm_text1.attr('required',true)
elm_text1['required'] = true
#map = elm_text1.attr_map
#map.names.each { |item| 
#  puts item
#  puts map.fetch(item)
#}

#elm_radio1 = ps.element("input","id","radio1","type","radio")
##elm_radio1.attribute("checked","true")
#elm_radio1['checked'] = true

#elm_select1 = ps.element("select","id","select1")
#elm_select1 = ps.element("select")
##elm_select1.attr("multiple",true)
#elm_select1['multiple'] = true
##puts elm_select1.attr("multiple")
#puts elm_select1['multiple']
#elm_option1 = ps.element("option","id","option1")
##elm_option1.attr("selected","true")
#elm_option1['selected'] = true
##puts elm_option1.attr("selected")
#puts elm_option1['selected']
##puts elm_text1.attr("readonly")
#puts elm_text1['readonly']

#elm_select2 = ps.element("select","id","select2")
#elm_select2["multiple"] = "true"
#elm_option2 = ps.element("option","id","option2")
#co_ps = elm_option2.child()
#10.times { |i|
#  if i == 1 then
#    #co_ps.attr("selected","true")
#    co_ps['selected'] = true
#  else
#    #co_ps.attr("selected","false")
#    co_ps['selected'] = false
#  end
#  #co_ps.attr("value",i.to_s)
#  co_ps['value'] = i.to_s
#  co_ps.remove_attr("id")
#  #co_ps.content(i.to_s)
#  co_ps.content = i.to_s
#  co_ps.flush
#}

elm_tr1 = ps.element('tr','id','loop')
elm_ = ps.shadow(elm_tr1)
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