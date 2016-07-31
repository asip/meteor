#!bin ruby
# -* coding: UTF-8 -*-

#require 'rubygems'
require 'meteor'

#pf = Meteor::ParserFactory.new
#pf.bind(:html,"ml/sample_x.html", "UTF-8")

#root = pf.element('ml/sample_x')

Meteor::ElementFactory.bind(:xhtml4,'ml/sample_x.html', 'UTF-8')
root = Meteor::ElementFactory.element('ml/sample_x')

startTime = Time.new.to_f

elm_hello = root.element("id","hello")
#elm_hello.attr(color: "red")
elm_hello['color'] = 'red'
#elm_hello.remove_attr('color')
#elm_hello['color'] = nil

elm_hello2 = root.element(id: "hello2")
#elm_hello2.content("Hello,Tester")
elm_hello2.content = "Hello,Tester"
#elm_hello2.remove
#elm_hello3 = root.cxtag("hello3")
##elm_hello3.content("Hello,Hello\ntt")
#elm_hello3.content = "Hello,Hello\ntt"
#puts elm_hello3.content
#puts elm_hello3.mixed_content

#elm_text1 = root.element(id: "text1")
##elm_text1.attr("value","めも")
#elm_text1['value'] = 'めも'
##elm_text1.attr(disabled: true)
#elm_text1['disabled'] = true
#map = elm_text1.attr_map
#map.names.each { |item| 
#  puts item
#  puts map.fetch(item)
#}

elm_radio1 = root.element("input", id: "radio1", type: "radio")
##elm_radio1.attribute(checked: "true")
elm_radio1['checked'] = true

#elm_select1 = root.element("select",id: "select1")
#elm_select1 = root.element("select")
##elm_select1.attr(multiple: true)
#elm_select1('multiple') = true
##puts elm_select1.attr("multiple")
#puts elm_select1['multiple']
#elm_option1 = root.element("option",id: "option1")
##elm_option1.attr(selected: "true")
#elm_option1['selected'] = true
#puts elm_option1.attr("selected")
#puts elm_text1.attr("readonly")

#elm_select2 = root.element("select",id: "select2")
#elm_select2["multiple"] = "true"
#elm_option2 = root.element("option",id: "option2")
#co_ps = elm_option2.child()
#10.times { |i|
#  if i == 1 then
#    #co_ps.attr(selected: true)
#    co_ps['selected'] = true
#  else
#    #co_ps.attr(selected: false)
#    co_ps['selected'] = false
#  end
#  #co_ps.attr("value"=>i.to_s)
#  co_ps['value'] = i.to_s
#  co_ps.remove_attr("id")
#  #co_ps.content(i.to_s)
#  co_ps.content = i.to_s
#  co_ps.flush
#}

elm_tr1 = root.element('tr',id: 'loop')
elm_ = elm_tr1.element
elm_dt1_ = elm_.element(id: 'aa')
elm_dt2_ = elm_.element(id: 'bb')
elm_dt3_ = elm_.element(id: 'cc')
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

root.flush

endTime = Time.new.to_f

puts root.document

puts '' + (endTime - startTime).to_s + ' sec'