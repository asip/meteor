#!bin ruby
# -* coding: UTF-8 -*-

#require 'rubygems'
require 'meteor'
#require '../lib/meteor'

#pf = Meteor::ParserFactory.new
#pf.bind(Meteor::Parser::HTML5,'sample_5.html', 'UTF-8')

#root = pf.element('sample_5')

Meteor::ElementFactory.bind(Meteor::Parser::HTML5,"sample_5.html", 'UTF-8')
root = Meteor::ElementFactory.element('sample_5')

start_time = Time.new.to_f

elm_hello = root.element('id','hello')
#elm_hello.attr('color'=>'red')
elm_hello['color'] = 'red'
#elm_hello.remove_attribute('color')

elm_hello2 = root.element('id'=>'hello2')
#elm_hello2.content('Hello,Tester')
elm_hello2.content = 'Hello,Tester'

elm_text1 = root.element('id','text1')
#elm_text1.attr('value','めも')
elm_text1['value'] = 'めも'
#elm_text1.attr('disabled'=>true)
elm_text1['disabled'] = true
#elm_text1.attr('required'=>true)
elm_text1['required'] = true

#elm_text1.remove_attr('disabled')
#map = elm_text1.attr_map
#map.names.each { |item| 
#  puts item
#  puts map.fetch(item)
#}

#elm_radio1 = root.element('input','id'=>'radio1','type'=>'radio')
##elm_radio1.attr(,'checked'=>'true')
#elm_radio1['checked'] = true
#puts elm_radio1.document

#elm_select1 = root.element('select','id'=>'select1')
#elm_select1 = root.element('select')
##elm_select1.attr('multiple'=>'true')
#elm_select1['multiple'] = true
##puts elm_select1.attr('multiple')
#puts elm_select1['multiple']

#elm_option1 = root.element('option','id'=>'option1')
##elm_option1.attr('selected'=>'true')
#elm_option1['selected'] = true
#elm_option1.remove_attr('selected')
##puts elm_option1.attr('selected')
#puts elm_option1['selected']
##puts elm_text1.attr('readonly')
#puts elm_text1['readonly']

#elm_select2 = ps.element('select','id'=>'select2')
#elm_select2['multiple'] = 'true'
#elm_option2 = ps.element('option','id'=>'option2')
#co_ps = elm_option2.element()
#10.times { |i|
#  co_ps.attr('value',i.to_s)
#  #'<' +
#  if i == 1 then
#    co_ps.attr('selected'=>'true')
#  else
#    #co_ps.attr('selected'=>'false')
#  end
#  co_ps.content(i.to_s)
#  co_ps.remove_attr('id')
#  co_ps.flush
#}

elm_tr1 = root.element('tr','id'=>'loop')
elm_ = root.element(elm_tr1)
elm_dt1_ = elm_.element('id'=>'aa')
elm_dt2_ = elm_.element('id'=>'bb')
elm_dt3_ = elm_.element('id'=>'cc')
10.times do |i|
  elm_['loop'] = i.to_s
  elm_dt1 = elm_dt1_.clone
  elm_dt2 = elm_dt2_.clone
  elm_dt3 = elm_dt3_.clone
  elm_dt1.content=i.to_s
  elm_dt2.content=i.to_s
  elm_dt3.content=i.to_s
  #"< \n" +
  elm_.flush
end

root.flush

end_time = Time.new.to_f

puts root.document

puts '' + (end_time - start_time).to_s + ' sec'