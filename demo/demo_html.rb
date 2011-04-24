#!bin ruby
# -* coding: UTF-8 -*-

require 'rubygems'
require 'meteor'
#require '../lib/meteor'

pf = Meteor::ParserFactory.new
pf.parser(Meteor::Parser::HTML,'sample.html', 'UTF-8')

ps = pf.parser('sample')

start_time = Time.new.to_f

#elm_hello = ps.element('id'=>'hello')
elm_hello = ps.find('[id=hello]')
#elm_hello.attr('color'=>'red')
elm_hello['color'] = 'red'

#elm_hello.remove_attribute('color')

elm_hello2 = ps.element('id','hello2')
#elm_hello2.content('Hello,Tester')
elm_hello2.content = 'Hello,Tester'

#elm_hello3 = ps.cxtag('hello3')
#elm_hello3.content = "Hello,Hello\ntt"
#elm_hello3.content = "Hello,Hello"
#puts elm_hello3.pattern
#puts elm_hello3.mixed_content
#puts elm_hello3.document
#puts elm_hello3.content
#puts elm_hello3.mixed_content

elm_text1 = ps.element('input','id'=>'text1')
#elm_text1.attr('value'=>'めも')
elm_text1['value'] = 'めも'
#ps.attr(elm_text1,'disabled'=>true)
elm_text1['disabled'] = true

#elm_text1.remove_attr('disabled')
#map = elm_text1.attr_map
#map.names.each { |item| 
#  puts item
#  puts map.fetch(item)
#}

#elm_radio1 = ps.element('input','id'=>'radio1','type'=>'radio')
#elm_radio1 = ps.find('input[id=radio1][type=radio]')
#elm_radio1 = ps.find('#radio1')
#elm_radio1 = ps.find('.test')
#elm_radio1 = ps.find('[id=radio1][type=radio]')
##elm_radio1.attr('checked','true')
#elm_radio1['checked'] = 'true'
#puts elm_radio1.document

#elm_select1 = ps.element('select','id'=>'select1')
#elm_select1 = ps.element('select')
##elm_select1 = ps.find('select')
#elm_select1.attr('multiple','true')
#elm_select1['multiple'] = true
##puts elm_select1.attr('multiple')
#puts elm_select1['multiple']

#elm_option1 = ps.element('option','id'=>'option1')
##elm_option1.attr('selected'=>'true')
#elm_option1['selected'] = true
#ps.remove_attr(elm_option1,'selected')
#elm_option1.remove_attr('selected')
##puts elm_option1.attr('selected')
#puts elm_option1['selected']
#puts ps.attr(elm_text1,'readonly')

#elm_select2 = ps.element('select','id'=>'select2')
#elm_select2['multiple'] = 'true'
#elm_option2 = ps.element('option','id'=>'option2')
#co_ps = elm_option2.child()
#10.times { |i|
#  co_ps.attr('value'=>i.to_s)
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

elm_tr1 = ps.element('tr','id'=>'loop')
#elm_tr1 = ps.find('tr[id=loop]')
elm_ = ps.element(elm_tr1)
elm_dt1_ = elm_.child('id'=>'aa')
elm_dt2_ = elm_.child('id'=>'bb')
elm_dt3_ = elm_.child('id'=>'cc')
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

ps.flush

end_time = Time.new.to_f

puts ps.document

puts '' + (end_time - start_time).to_s + ' sec'