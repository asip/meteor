#!bin ruby
# -* coding: UTF-8 -*-

#require 'rubygems'
require 'meteor'

Meteor::ElementFactory.link(:xhtml5,'ml/sample_x5.html', 'UTF-8')
root = Meteor::ElementFactory.element('ml/sample_x5')

startTime = Time.new.to_f

elm_hello = root.element(id: 'hello')
#elm_hello.attr(color: "red")
elm_hello['color'] = 'red'
#elm_hello.remove_attr('color')
#elm_hello['color'] = nil
#elm_hello.attr(color: nil)

elm_hello2 = root.element(id: 'hello2')
#elm_hello2.content("Hello,Tester")
elm_hello2.content = "Hello,Tester"

#elm_hello2.remove
#elm_hello3 = root.cxtag("hello3")
##elm_hello3.content("Hello,Hello\ntt")
#elm_hello3.content = "Hello,Hello\ntt"
#puts elm_hello3.content
#puts elm_hello3.mixed_content

elm_text1 = root.element(id: 'text1')
#elm_text1.attr(value: 'めも')
elm_text1['value'] = 'めも'
#elm_text1.attr(disabled: true)
elm_text1['disabled'] = true
#elm_text1.attr(required: true)
elm_text1['required'] = true
#map = elm_text1.attr_map
#map.names.each { |item| 
#  puts item
#  puts map.fetch(item)
#}

#elm_radio1 = root.element("input",id: "radio1", type: "radio")
##elm_radio1.attr(checked: "true")
#elm_radio1['checked'] = true

#elm_select1 = root.element("select",id: "select1")
#elm_select1 = root.element("select")
##elm_select1.attr(multiple: true)
#elm_select1['multiple'] = true
##puts elm_select1.attr("multiple")
#puts elm_select1['multiple']
#elm_option1 = root.element("option",id: "option1")
##elm_option1.attr(selected: "true")
#elm_option1['selected'] = true
##puts elm_option1.attr("selected")
#puts elm_option1['selected']
##puts elm_text1.attr("readonly")
#puts elm_text1['readonly']

elm_select2 = root.element("select",id: "select2")
elm_select2["multiple"] = "true"
elm_option2 = elm_select2.element("option",id: "option2")
co_elm = elm_option2.element()
10.times { |i|
  if i == 1 then
    #co_elm.attr(selected: "true")
    co_elm['selected'] = true
  else
    #co_elm.attr(selected: "false")
    co_elm['selected'] = false
  end
  #co_elm.attr(value: i)
  co_elm['value'] = i
  #co_elm.remove_attr("id")
  co_elm['id'] = nil
  #co_elm.content(i)
  co_elm.content = i
  co_elm.flush
}

elm_tr1 = root.element('tr',id: 'loop')
elm_ = elm_tr1.element
elm_dt1_ = elm_.element(id: 'aa')
elm_dt2_ = elm_.element(id: 'bb')
elm_dt3_ = elm_.element(id: 'cc')
10.times { |i|
  elm_['loop'] = i
  elm_dt1 = elm_dt1_.clone
  elm_dt2 = elm_dt2_.clone
  elm_dt3 = elm_dt3_.clone
  #elm_dt1.content("<>\"' \n" << i.to_s)
  elm_dt1.content=i
  elm_dt2.content=i
  elm_dt3.content=i
  elm_.flush
}

root.flush

endTime = Time.new.to_f

puts root.document

puts '' + (endTime - startTime).to_s + ' sec'
