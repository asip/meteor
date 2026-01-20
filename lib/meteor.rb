# -* coding: UTF-8 -*-
# frozen_string_literal: true

# Meteor -  A lightweight (X)HTML(5) & XML parser
#
# Copyright (C) 2008-2021 Yasumasa Ashida.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# @author Yasumasa Ashida
# @version 0.9.12
#

module Meteor

  VERSION = '0.9.12'

  #require 'fileutils'

  ZERO = 0
  ONE = 1
  TWO = 2
  THREE = 3
  FOUR = 4
  FIVE = 5
  SIX = 6
  SEVEN = 7

  HTML = ZERO
  XHTML = ONE
  HTML4 = TWO
  XHTML4 = THREE
  XML = FOUR

  #
  # Element Class (要素クラス)
  #
  # @!attribute [rw] name
  #  @return [String] tag name (要素名)
  # @!attribute [rw] attributes
  #  @return [String] attributes (属性群)
  # @!attribute [rw] mixed_content
  #  @return [String] content (内容)
  # @!attribute [rw] raw_content
  #  @return [false,true] entity ref flag of content (内容のエンティティ参照フラグ)
  # @!attribute [rw] pattern
  #  @return [String] pattern (パターン)
  # @!attribute [rw] document_sync
  #  @return [true,false] document update flag (ドキュメント更新フラグ)
  # @!attribute [rw] empty
  #  @return [true,false] content empty flag (内容存在フラグ)
  # @!attribute [rw] cx
  #  @return [true,false] comment extension tag flag (コメント拡張タグフラグ)
  # @!attribute [rw] mono
  #  @return [true,false] child element existance flag (子要素存在フラグ)
  # @!attribute [rw] parser
  #  @return [Meteor::Parser] parser(パーサ)
  # @!attribute [rw] type_value
  #  @return [String] type (タイプ属性)
  # @!attribute [rw] usable
  #  @return [true,false] usable flag (有効・無効フラグ)
  # @!attribute [rw] origin
  #  @return [Meteor::Element] original pointer (原本ポインタ)
  # @!attribute [rw] copy
  #  @return [Meteor::Element] copy pointer (複製ポインタ)
  # @!attribute [rw] removed
  #  @return [true,false] delete flag (削除フラグ)
  #
  class Element

    attr_accessor :name
    attr_accessor :attributes
    attr_accessor :mixed_content
    attr_accessor :raw_content
    attr_accessor :pattern
    attr_accessor :document_sync
    attr_accessor :empty
    attr_accessor :cx
    attr_accessor :mono
    attr_accessor :parser
    attr_accessor :type_value
    attr_accessor :usable
    attr_accessor :origin
    attr_accessor :copy
    attr_accessor :removed

    alias :tag :name
    alias :tag= :name=

    #
    # initializer (イニシャライザ)
    # @overload initialize(name)
    #  @param [String,Symbol] name tag name (タグ名)
    # @overload initialize(elm)
    #  @param [Meteor::Element] elm element (要素)
    # @overload initialize(elm,ps)
    #  @param [Meteor::Element] elm element (要素)
    #  @param [Meteor::Parser] ps parser (パーサ)
    #
    def initialize(*args)
      case args.length
        when ONE
          if args[0].kind_of?(String)
            initialize_s(args[0])
          elsif args[0].kind_of?(Meteor::Element)
            initialize_e(args[0])
          else
            raise ArgumentError
          end
        when TWO
          @name = args[0].name
          @attributes = String.new(args[0].attributes)
          @mixed_content = String.new(args[0].mixed_content)
          #@pattern = String.new(args[0].pattern)
          @pattern = args[0].pattern
          @document = String.new(args[0].document)
          @empty = args[0].empty
          @cx = args[0].cx
          @mono = args[0].mono
          @parser = args[1]
          #@usable = false
          @origin = args[0]
          args[0].copy = self
        when ZERO
        else
          raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    # @param [String] name tag name (タグ名)
    #
    def initialize_s(name)
      @name = name
      #@attributes = nil
      #@mixed_content = nil
      #@pattern = nil
      #@document = nil
      #@parser=nil
      #@empty = false
      #@cx = false
      #@mono = false
      #@parent = false
      @usable = true
    end

    private :initialize_s

    #
    # initializer (イニシャライザ)
    # @param [Meteor::Element] elm element (要素)
    #
    def initialize_e(elm)
      @name = elm.name
      @attributes = String.new(elm.attributes)
      #@pattern = String.new(elm.pattern)
      @pattern = elm.pattern
      @document = String.new(elm.document)
      @empty = elm.empty
      @cx = elm.cx
      @mono = elm.mono
      @origin = elm
      @parser = elm.parser
      @usable = true
    end

    private :initialize_e

    #
    # make copy (コピーを作成する)
    # @overload new!(elm,ps)
    #  @param [Meteor::Element] elm element (要素)
    #  @param [Meteor::Parser] ps parser (パーサ)
    #  @return [Meteor::Element] element (要素)
    #
    def self.new!(*args)
      case args.length
        when TWO
          @obj = args[1].element_hook
          if @obj
            @obj.attributes = String.new(args[0].attributes)
            @obj.mixed_content = String.new(args[0].mixed_content)
            #@obj.pattern = String.new(args[0].pattern)
            @obj.document = String.new(args[0].document)
            @obj
          else
            @obj = self.new(args[0], args[1])
            args[1].element_hook = @obj
            @obj
          end
        else
          raise ArgumentError
      end
    end

    #
    # clone (複製する)
    # @return [Meteor::Element] element (要素)
    #
    def clone
      obj = self.parser.element_cache[self.object_id]
      if obj
        obj.attributes = String.new(self.attributes)
        obj.mixed_content = String.new(self.mixed_content)
        #obj.pattern = String.new(self.pattern)
        obj.document = String.new(self.document)
        obj.usable = true
        obj
      else
        obj = self.new(self)
        self.parser.element_cache[self.object_id] = obj
        obj
      end
    end

    #
    # set document (ドキュメントをセットする)
    # @param [String] doc document (ドキュメント)
    #
    def document=(doc)
      @document_sync = false
      @document = doc
    end

    #
    # get document (ドキュメントを取得する)
    # @return [String] document (ドキュメント)
    #
    def document
      if @document_sync
        @document_sync = false
        case @parser.doc_type
          when Parser::HTML, Parser::HTML4
            if @cx
              #@pattern_cc = String.new('') << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty
                #@pattern_cc = String.new('') << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = String.new('') << Meteor::Core::Kernel::TAG_OPEN << @name << @attributes << Meteor::Core::Kernel::TAG_CLOSE
                #@document = "<#{@name}#{@attributes}>"
              end
            end
          when Parser::XHTML, Parser::XHTML4, Parser::XML
            if @cx
              #@pattern_cc = String.new('') << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty
                #@pattern_cc = String.new('') << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = String.new('') << Meteor::Core::Kernel::TAG_OPEN << @name << @attributes << Meteor::Core::Kernel::TAG_CLOSE3
                #@document = "<#{@name}#{@attributes}/>"
              end
            end
        end
      else
        @document
      end
    end

    #
    # get element (要素を取得する)
    # @overload element()
    #  get element (要素を取得する)
    #  @return [Meteor::Element] element (要素)
    # @overload element(name)
    #  get element using tag name (要素のタグ名で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @return [Meteor::Element] element (要素)
    # @overload element(name,attrs)
    #  get element using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attrs)
    #  get element using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Meteor::Element] element(要素)
    # @overload element(name,attr_name,attr_value)
    #  get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attr_name,attr_value)
    #  get element using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name 属性名
    #  @param [String] attr_value 属性値
    #  @return [Meteor::Element] element (要素)
    # @overload element(name,attr_name1,attr_value1,attr_name2,attr_value2)
    #  get element using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attr_name1,attr_value1,attr_name2,attr_value2)
    #  get element using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name1 属性名1
    #  @param [String] attr_value1 属性値1
    #  @param [String,Symbol] attr_name2 属性名2
    #  @param [String] attr_value2 属性値2
    #  @return [Meteor::Element] element(要素)
    # @overload element(elm)
    #  mirror element (要素を射影する)
    #  @param [Meteor::Element] elm element(要素)
    #  @return [Meteor::Element] element(要素)
    #
    def element(elm = nil, attrs = nil,*args)
      #case args.length
      #when ZERO
      if !elm && !attrs
        @parser.element(self)
      else
        @parser.element(elm, attrs,*args)
      end
    end

    alias :child :element

    #
    # get elements (要素を取得する)
    # @overload elements(name)
    #  get elements using tag name (要素のタグ名で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @return [Array<Meteor::Element>] element array(要素配列)
    # @overload elements(name,attrs)
    #  get elements using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(attrs)
    #  get elements using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(name,attr_name,attr_value)
    #  get elements using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(attr_name,attr_value)
    #  get elements using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(name,attr_name1,attr_value1,attr_name2,attr_value2)
    #  get elements using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(attr_name1,attr_value1,attr_name2,attr_value2)
    #  get elements using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    #
    def elements(*args)
      @parser.elements(*args)
    end

    #
    # get (child) elements using selector like css3(CSS3のようにセレクタを用いて(子)要素を取得する)
    # CSS3 selector partial support (CSS3セレクタの部分的サポート)
    # @param selector [String] selector (セレクタ)
    # @return [Array<Meteor::Element>] element (要素)
    #
    def find(selector)
      @parser.find(selector)
    end

    alias :css :find

    #
    # get cx(comment extension) tag (CX(コメント拡張)タグを取得する)
    # @overload cxtag(name,id)
    #  get cx(comment extension) tag using tag name and id attribute (タグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String] id id attribute value (ID属性値)
    #  @return [Meteor::Element] element(要素)
    # @overload cxtag(id)
    #  get cx(comment extension) tag using id attribute (ID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
    #  @param [String] id id attribute value (ID属性値)
    #  @return [Meteor::Element] element (要素)
    #
    def cxtag(*args)
      @parser.cxtag(*args)
    end

    #
    # @overload attr(attr)
    #  set attribute of element (要素の属性をセットする)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attr attribute (属性)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload attr(attr_name,attr_value)
    #  set attribute of element (要素の属性をセットする)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String,true,false] attr_value attribute value (属性値)
    #  @return [Meteor::Element] element (要素)
    # @overload attr(attr_name)
    #  get attribute value of element (要素の属性値を取得する)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @return [String] attribute value (属性値)
    #
    def attr(attrs,*args)
      @parser.attr(self, attrs,*args)
    end

    #
    # set attribute of element (要素の属性をセットする)
    # @param [Hash<String,String>,Hash<Symbol,String>] attr attribute (属性)
    # @return [Meteor::Element] element (要素)
    #
    def attr=(attr)
      @parser.attr(self,attr)
    end

    #
    # set attribute map (要素マップをセットする)
    # @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    # @return [Meteor::Element] element (要素)
    def attrs=(attrs)
      @parser.attrs(self,attrs)
    end

    #
    # get attribute map (属性マップを取得する)
    # @return [Hash<String,String>,Hash<Symbol,String>] attribute map (属性マップ)
    #
    def attrs
      @parser.attrs(self)
    end

    #
    # @overload attr_map(attr_map)
    #  set attribute map (属性マップをセットする)
    #  @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload attr_map()
    #  get attribute map (属性マップを取得する)
    #  @return [Meteor::AttributeMap] attribute map (属性マップ)
    #
    def attr_map(*args)
      @parser.attr_map(self, *args)
    end

    #
    # set attribute map (属性マップをセットする)
    # @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    # @return [Meteor::Element] element (要素)
    #
    def attr_map=(attr_map)
      @parser.attr_map(self,attr_map)
    end

    #
    # @overload content(content,entity_ref=true)
    #  set content of element (要素の内容をセットする)
    #  @param [String] content content of element (要素の内容)
    #  @param [true,false] entity_ref entity reference flag (エンティティ参照フラグ)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload content(content)
    #  set content of element (要素の内容をセットする)
    #  @param [String] content content of element (要素の内容)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload content()
    #  get content of element (要素の内容を取得する)
    #  @return [String] content (内容)
    #
    def content(*args)
      @parser.content(self, *args)
    end

    alias :text :content

    #
    # set content of element (要素の内容をセットする)
    # @param [String] value content (要素の内容)
    # @return [Meteor::Element] element (要素)
    #
    def content=(value)
      @parser.content(self, value)
    end

    alias :text= :content=

    #
    # set attribute (属性をセットする)
    # @param [String,Symbol] name attribute name (属性の名前)
    # @param [String] value attribute value (属性の値)
    # @return [Meteor::Element] element (要素)
    #
    def []=(name, value)
      if value != nil
        @parser.attr(self, name, value)
      else
        @parser.remove_attr(self, name)
      end
    end

    #
    # get attribute value (属性の値を取得する)
    # @param [String,Symbol] name attribute name (属性の名前)
    # @return [String] attribute value (属性の値)
    #
    def [](name)
      @parser.attr(self, name)
    end

    #
    # remove attribute of element (要素の属性を消す)
    # @param [String,Symbol] attr_name attribute name (属性名)
    # @return [Meteor::Element] element (要素)
    #
    def remove_attr(attr_name)
      @parser.remove_attr(self, attr_name)
    end

    #
    # remove element (要素を削除する)
    #
    def remove
      @parser.remove_element(self)
    end

    #
    # reflect (反映する)
    #
    def flash
      @parser.flash
    end

    alias :flush :flash

    #
    # @overload execute(hook)
    #  run action of Hooker (Hookerクラスの処理を実行する)
    #  @param [Meteor::Hook::Hooker] hook Hooker object (Hookerオブジェクト)
    # @overload execute(loop,list)
    #  run action of Looper (Looperクラスの処理を実行する)
    #  @param [Meteor::Hook::Looper] loop Looper object (Looperオブジェクト)
    #  @param [Array] list 配列
    #
    def execute(*args)
      @parser.execute(self, *args)
    end

  end

  #
  # root element class (ルート要素クラス)
  #
  # @!attribute [rw] content_type
  #  @return [String] content type (コンテントタイプ)
  # @!attribute [rw] kaigyo_code
  #  @return [String] newline (改行コード)
  # @!attribute [rw] charset
  #  @return [String] charset (文字コード)
  # @!attribute [rw] character_encoding
  #  @return [String] character encoding (文字エンコーディング)
  #
  class RootElement < Element

    EMPTY = ''

    attr_accessor :content_type
    attr_accessor :kaigyo_code
    attr_accessor :charset
    attr_accessor :character_encoding
    #attr_accessor :document #[String] document (ドキュメント)

  end

  #
  # Attribute Map Class (属性マップクラス)
  #
  class AttributeMap

    #
    # initializer (イニシャライザ)
    # @overload initialize
    # @overload initialize(attr_map)
    #  @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    #
    def initialize(*args)
      case args.length
        when ZERO
          initialize_0
        when ONE
          initialize_1(args[0])
        else
          raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    #
    def initialize_0
      @map = Hash.new
      @recordable = false
    end

    private :initialize_0

    #
    # initializer (イニシャライザ)
    # @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    #
    def initialize_1(attr_map)
      #@map = Marshal.load(Marshal.dump(attr_map.map))
      @map = attr_map.map.dup
      @recordable = attr_map.recordable
    end

    private :initialize_1

    #
    # set a couple of attribute name and attribute value (属性名と属性値を対としてセットする)
    # @param [String,Symbol] name attribute name (属性名)
    # @param [String] value attribute value (属性値)
    #
    def store(name, value)

      if !@map[name]
        attr = Attribute.new
        attr.name = name
        attr.value = value
        if @recordable
          attr.changed = true
          attr.removed = false
        end
        @map[name] = attr
      else
        attr = @map[name]
        if @recordable && attr.value != value
          attr.changed = true
          attr.removed = false
        end
        attr.value = value
      end
    end

    #
    # get attribute name array (属性名配列を取得する)
    # @return [Array] attribute name array (属性名配列)
    #
    def names
      @map.keys
    end

    #
    # get attribute value using attribute name (属性名で属性値を取得する)
    # @param [String,Symbol] name attribute name (属性名)
    # @return [String] attribute value (属性値)
    #
    def fetch(name)
      if @map[name] && !@map[name].removed
        @map[name].value
      end
    end

    #
    # delete attribute using attribute name (属性名に対応した属性を削除する)
    # @param name attribute name (属性名)
    #
    def delete(name)
      if @recordable && @map[name]
        @map[name].removed = true
        @map[name].changed = false
      end
    end

    #
    # get update flag of attribute using attribute name (属性名で属性の変更フラグを取得する)
    # @return [true,false] update flag of attribute (属性の変更状況)
    #
    def changed(name)
      if @map[name]
        @map[name].changed
      end
    end

    #
    # get delete flag of attribute using attribute name (属性名で属性の削除状況を取得する)
    # @return [true,false] delete flag of attribute (属性の削除状況)
    #
    def removed(name)
      if @map[name]
        @map[name].removed
      end
    end

    attr_accessor :map
    attr_accessor :recordable

    #
    # set a couple of attribute name and attribute value (属性名と属性値を対としてセットする)
    #
    # @param [String,Symbol] name attribute name (属性名)
    # @param [String] value attribute value (属性値)
    #
    def []=(name, value)
      store(name, value)
    end

    #
    # get attribute value using attribute name (属性名で属性値を取得する)
    #
    # @param [String,Symbol] name attribute name (属性名)
    # @return [String] attribute value (属性値)
    #
    def [](name)
      fetch(name)
    end
  end

  #
  # Attribute class (属性クラス)
  #
  # @!attribute [rw] name
  #  @return [String,Symbol] attribute name (名前)
  # @!attribute [rw] value
  #  @return [String] attribute value (値)
  # @!attribute [rw] changed
  #  @return [true,false] update flag (更新フラグ)
  # @!attribute [rw] removed
  #  @return [true,false] delete flag (削除フラグ)
  #
  class Attribute

    attr_accessor :name
    attr_accessor :value
    attr_accessor :changed
    attr_accessor :removed

    ##
    ## initializer (イニシャライザ)
    ##
    #def initialize
    #  #@name = nil
    #  #@value = nil
    #  #@changed = false
    #  #@removed = false
    #end

  end

  #
  # Parser Class (パーサ共通クラス)
  #
  class Parser
    HTML = ZERO
    XHTML = ONE
    HTML4 = TWO
    XHTML4 = THREE
    XML = FOUR
  end

  #
  # Parser Factory Class (パーサファクトリクラス)
  #
  # @!attribute [rw] type
  #  @return [FixNum,Symbol] default type of parser (デフォルトのパーサ・タイプ)
  # @!attribute [rw] root
  #  @return [String] root root directory (基準ディレクトリ)
  # @!attribute [rw] enc
  #  @return [String] default character encoding (デフォルトエンコーディング)
  #
  class ParserFactory

    ABST_EXT_NAME = '.*'
    #CURRENT_DIR = FileUtils.pwd
    #puts CURRENT_DIR
    CURRENT_DIR = '.'
    SLASH = '/'
    ENC_UTF8 = 'UTF-8'

    attr_accessor :type
    attr_accessor :root
    attr_accessor :enc

    alias_method :base_type, :type
    alias_method :base_type=, :type=
    alias_method :base_dir, :root
    alias_method :base_dir=, :root=
    alias_method :base_enc, :enc
    alias_method :base_enc=, :enc=

    alias_method :base_encoding, :enc
    alias_method :base_encoding=, :enc=

    #
    # initializer (イニシャライザ)
    # @overload initialize()
    # @overload initialize(root)
    #  @param [String] root root directory (基準ディレクトリ)
    # @overload initialize(root, enc)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルトエンコーディング)
    # @overload initialize(type, root, enc)
    #  @param [FixNum,Symbol] type default type of parser (デフォルトのパーサ・タイプ)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize(*args)
      case args.length
        when 0
          initialize_0
        when 1
          initialize_1(args[0])
        when 2
          initialize_2(args[0], args[1])
        when 3
          initialize_3(args[0],args[1],args[2])
        else
          raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    #
    def initialize_0
      @cache = Hash.new
      @root = CURRENT_DIR
      @enc = ENC_UTF8
    end

    private :initialize_0

    #
    # イニシャライザ
    # @param [String] root root directory (基準ディレクトリ)
    #
    def initialize_1(root)
      @cache = Hash.new
      @root = root
      @enc = ENC_UTF8
    end

    private :initialize_1

    #
    # イニシャライザ
    # @param [String] root root directory (基準ディレクトリ)
    # @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize_2(root, enc)
      @cache = Hash.new
      @root = root
      @enc = enc
    end

    private :initialize_2

    #
    # イニシャライザ
    # @param [FixNum,Symbol] type default type of parser (デフォルトのパーサ・タイプ)
    # @param [String] root root directory (基準ディレクトリ)
    # @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize_3(type , root, enc)
      @cache = Hash.new
      @type = type
      @root = root
      @enc = enc
    end

    private :initialize_3

    #
    # set options (オプションをセットする)
    # @param [Hash] opts option (オプション)
    # @option opts [String] :root root directory (基準ディレクトリ)
    # @option @deprecated opts [String] :base_dir root directory (基準ディレクトリ)
    # @option opts [String] :enc default character encoding (デフォルト文字エンコーディング)
    # @option @deprecated opts [String] :base_enc default character encoding (デフォルト文字エンコーディング)
    # @option opts [FixNum,Symbol] :type default type of parser (デフォルトのパーサ・タイプ)
    # @option @deprecated opts [FixNum | Symbol] :base_type default type of parser (デフォルトのパーサ・タイプ)
    #
    def options=(opts)
      if opts.kind_of?(Hash)
        if opts.include?(:root)
          @root = opts[:root]
        elsif opts.include?(:base_dir)
          @root = opts[:base_dir]
        end
        if opts.include?(:enc)
          @enc = opts[:enc]
        elsif opts.include?(:base_enc)
          @enc = opts[:base_enc]
        end
        if opts.include?(:type)
          @type = opts[:type]
        elsif opts.include?(:base_type)
          @type = opts[:base_type]
        end
      else
        raise ArgumentError
      end
    end

    #
    #@overload link(relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(relative_path)
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link(*args)
      case args.length
        when 1
          link_1(args[0])
        when 2
          if args[0].kind_of?(Fixnum) || args[0].kind_of?(Symbol)
            link_2_n(args[0], args[1])
          elsif args[0].kind_of?(String)
            link_2_s(args[0], args[1])
          else
            raise ArgumentError
          end
        when 3
          link_3(args[0], args[1], args[2])
        else
          raise ArgumentError
      end
    end

    #
    # change relative path to relative url (相対パスを相対URLにする)
    # @param [String] path relative path (相対パス)
    # @return [String] relative url (相対URL)
    #
    def path_to_url(path)
      paths = File.split(path)

      if paths.length == 1
        return File.basename(paths[0], ABST_EXT_NAME)
      else
        if CURRENT_DIR.eql?(paths[0])
          paths.delete_at 0
          paths[paths.length - 1] = File.basename(paths[paths.length - 1], ABST_EXT_NAME)
          return String.new('') << SLASH << paths.join(SLASH)
        else
          paths[paths.length - 1] = File.basename(paths[paths.length - 1], ABST_EXT_NAME)
          return String.new('') << SLASH << paths.join(SLASH)
        end
      end
    end

    private :path_to_url

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser(パーサ)
    #
    def link_3(type, relative_path, enc)

      relative_url = path_to_url(relative_path)

      case type
        when Parser::HTML4, :html4
          html4 = Meteor::Ml::Html4::ParserImpl.new
          html.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = html4
        when Parser::XHTML4, :xhtml4
          xhtml4 = Meteor::Ml::Xhtml4::ParserImpl.new
          xhtml4.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xhtml4
        when Parser::HTML, :html, :html5
          html = Meteor::Ml::Html::ParserImpl.new
          html.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = html
        when Parser::XHTML, :xhtml, :xhtml5
          xhtml = Meteor::Ml::Xhtml::ParserImpl.new
          xhtml.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xhtml
        when Parser::XML, :xml
          xml = Meteor::Ml::Xml::ParserImpl.new
          xml.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xml
      end
    end

    private :link_3

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser(パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_2_n(type, relative_path)

      relative_url = path_to_url(relative_path)

      case type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4, :xhtml4
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html, :html5
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml, :xhtml5
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.read(File.expand_path(relative_path, @root), @enc)
      @cache[relative_url] = ps

    end

    private :link_2_n

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_2_s(relative_path,enc)

      relative_url = path_to_url(relative_path)

      case @type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4, :xhtml4
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.read(File.expand_path(relative_path, @root), enc)
      @cache[relative_url] = ps

    end

    private :link_2_s

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_1(relative_path)

      relative_url = path_to_url(relative_path)

      case @type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
        else
          raise ArgumentError
      end

      ps.read(File.expand_path(relative_path, @root), @enc)
      @cache[relative_url] = ps

    end

    private :link_1

    #
    #@overload parser(key)
    # get parser (パーサを取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload parser(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    # @deprecated
    #@overload parser(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    # @deprecated
    def parser(*args)
      case args.length
        when 1
          parser_1(args[0])
        when 2,3
          link(args)
      end
      #parser_1(key)
    end

    #
    # get parser (パーサを取得する)
    # @param [String] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def parser_1(key)
      @pif = @cache[key.to_s]
      case @pif.doc_type
        when Meteor::Parser::HTML4
          Meteor::Ml::Html4::ParserImpl.new(@pif)
        when Meteor::Parser::XHTML4
          Meteor::Ml::Xhtml4::ParserImpl.new(@pif)
        when Meteor::Parser::HTML
          Meteor::Ml::Html::ParserImpl.new(@pif)
        when Meteor::Parser::XHTML
          Meteor::Ml::Xhtml::ParserImpl.new(@pif)
        when Meteor::Parser::XML
          Meteor::Ml::Xml::ParserImpl.new(@pif)
      end
    end

    private :parser_1

    #
    # get root element (ルート要素を取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def element(key)
      parser_1(key).root_element
    end

    #
    # @overload link_str(type, relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [Fixnum] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload link_str(relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def link_str(*args)
      case args.length
        when 2
          link_str_2(args[0],args[1])
        when 3
          link_str_3(args[0],args[1],args[2])
        else
          raise ArgumentError
      end
    end

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_str_3(type, relative_url, doc)
      case type
        when Parser::HTML4, :html
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4, :xhtml4
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.dcument = doc
      ps.parse
      @cache[relative_url] = ps
    end

    private :link_str_3

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_str_2(relative_url, doc)
      case @type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.document = doc
      ps.parse
      @cache[relative_url] = ps

    end

    private :link_str_2

    alias :paraser_str :link_str

    #
    # set parser (パーサをセットする)
    # @param [String,Symbol] key identifier (キー)
    # @param [Meteor::Parser] ps parser (パーサ)
    #
    def []=(key, ps)
      @cache[key] = ps
    end

    #
    # get parser (パーサを取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def [](key)
      self.parser(key)
    end

  end

  #
  # Element Factory Class (要素ファクトリクラス)
  #
  class ElementFactory

    @@pf = Meteor::ParserFactory.new

    #
    # set options (オプションをセットする)
    # @param [Hash] opts option (オプション)
    # @option opts [String] :root root directory (基準ディレクトリ)
    # @option @deprecated opts [String] :base_dir root directory (基準ディレクトリ)
    # @option opts [String] :enc default character encoding (デフォルト文字エンコーディング)
    # @option @deprecated opts [String] :base_enc default character encoding (デフォルト文字エンコーディング)
    # @option opts [FixNum,Symbol] :type default type of parser (デフォルトのパーサ・タイプ)
    # @option @deprecated opts [FixNum | Symbol] :base_type default type of parser (デフォルトのパーサ・タイプ)
    #
    def self.options=(opts)
      @@pf.options = opts
    end

    #
    #@overload link(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def self.link(*args)
      @@pf.link(*args)
    end

    #
    # @overload link_str(type, relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [Fixnum] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload link_str(relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def self.link_str(*args)
      @@pf.link_str(args)
    end

    #
    # get root element (ルート要素を取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def self.element(key)
      @@pf.element(key)
    end

  end

  module Exception

    #
    # Element Search Exception (要素検索例外)
    #
    # @!attribute [rw] message
    #  @return [String] message (メッセージ)
    #
    class NoSuchElementException

      attr_accessor :message

      #
      # initializer (イニシャライザ)
      # @overload initialize(name)
      #  @param [String,Symbol] name tag name (タグ名)
      # @overload initialize(attr_name,attr_value)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      # @overload initialize(name,attr_name,attr_value)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      # @overload initialize(attr_name1,attr_value1,attr_name2,attr_value2)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名１)
      #  @param [String] attr_value1 attribute value1 (属性値１)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名２)
      #  @param [String] attr_value2 attribute value2 (属性値２)
      # @overload initialize(name,attr_name1,attr_value1,attr_name2,attr_value2)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名１)
      #  @param [String] attr_value1 attribute value1 (属性値１)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名２)
      #  @param [String] attr_value2 attribute value2 (属性値２)
      #
      def initialize(*args)
        case args.length
          when ONE
            initialize_1(args[0])
          when TWO
            initialize_2(args[0], args[1])
          when THREE
            initialize_3(args[0], args[1], args[2])
          when FOUR
            initialize_4(args[0], args[1], args[2], args[3])
          when FIVE
            initialize_5(args[0], args[1], args[2], args[3], args[4])
        end
      end

      def initialize_1(name)
        self.message="element not found : #{name}"
      end

      private :initialize_1

      def initialize_2(attr_name, attr_value)
        self.message="element not found : [#{attr_name}=#{attr_value}]"
      end

      private :initialize_2

      def initialize_3(name, attr_name, attr_value)
        self.message="element not found : #{name}[#{attr_name}=#{attr_value}]"
      end

      private :initialize_3

      def initialize_4(attr_name1, attr_value1, attr_name2, attr_value2)
        self.message="element not found : [#{attr_name1}=#{attr_value1}][#{attr_name2}=#{attr_value2}]"
      end

      private :initialize_4

      def initialize_5(name, attr_name1, attr_value1, attr_name2, attr_value2)
        self.message="element not found : #{name}[#{attr_name1}=#{attr_value1}][#{attr_name2}=#{attr_value2}]"
      end

      private :initialize_5

    end

  end

  module Core

    #
    # Parser Core Class (パーサコアクラス)
    #
    # @!attribute [rw] element_cache
    #  @return [Hash] element cache (要素キャッシュ)
    # @!attribute [rw] doc_type
    #  @return [Fixnum] document type (ドキュメントタイプ)
    # @!attribute [rw] document_hook
    #  @return [String] hook document (フック・ドキュメント)
    # @!attribute [rw] element_hook
    #  @return [Meteor::Element] element (要素)
    #
    class Kernel < Meteor::Parser

      EMPTY = ''
      SPACE = ' '
      DOUBLE_QUATATION = '"'
      TAG_OPEN = '<'
      TAG_OPEN3 = '</'
      #TAG_OPEN4 = '<\\\\/'
      TAG_CLOSE = '>'
      #TAG_CLOSE2 = '\\/>'
      TAG_CLOSE3 = '/>'
      ATTR_EQ = '="'
      #element
      TAG_SEARCH_1_1 = '(|\\s[^<>]*)>(((?!('
      TAG_SEARCH_1_2 = '[^<>]*>)).)*)<\\/'
      TAG_SEARCH_1_3 = '(|\\s[^<>]*)\\/>'
      TAG_SEARCH_1_4 = '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_1_4_2 = '(|\\s[^<>]*)>'

      TAG_SEARCH_NC_1_1 = '(?:|\\s[^<>]*)>((?!('
      TAG_SEARCH_NC_1_2 = '[^<>]*>)).)*<\\/'
      TAG_SEARCH_NC_1_3 = '(?:|\\s[^<>]*)\\/>'
      TAG_SEARCH_NC_1_4 = '(?:\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_NC_1_4_2 = '(?:|\\s[^<>]*)>'

      TAG_SEARCH_2_1 = '(\\s[^<>]*'
      TAG_SEARCH_2_1_2 = '(\\s[^<>]*(?:'
      TAG_SEARCH_2_2 = '"[^<>]*)>(((?!('
      TAG_SEARCH_2_2_2 = '")[^<>]*)>(((?!('
      TAG_SEARCH_2_3 = '"[^<>]*)'
      TAG_SEARCH_2_3_2 = '"[^<>]*)\\/>'
      TAG_SEARCH_2_3_2_2 = '")[^<>]*)\\/>'
      TAG_SEARCH_2_4 = '(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_2_4_2 = '(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))'
      TAG_SEARCH_2_4_2_2 = '")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))'
      TAG_SEARCH_2_4_2_3 = '"'
      TAG_SEARCH_2_4_3 = '"[^<>]*)>'
      TAG_SEARCH_2_4_3_2 = '")[^<>]*)>'
      TAG_SEARCH_2_4_4 = '"[^<>]*>'

      TAG_SEARCH_2_6 = '"[^<>]*'
      TAG_SEARCH_2_7 = '"|'

      TAG_SEARCH_NC_2_1 = '\\s[^<>]*'
      TAG_SEARCH_NC_2_1_2 = '\\s[^<>]*(?:'
      TAG_SEARCH_NC_2_2 = '"[^<>]*>((?!('
      TAG_SEARCH_NC_2_2_2 = '")[^<>]*>((?!('
      TAG_SEARCH_NC_2_3 = '"[^<>]*)'
      TAG_SEARCH_NC_2_3_2 = '"[^<>]*\\/>'
      TAG_SEARCH_NC_2_3_2_2 = '")[^<>]*\\/>'
      TAG_SEARCH_NC_2_4 = '(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_NC_2_4_2 = '(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_NC_2_4_2_2 = '")(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_NC_2_4_2_3 = '"'
      TAG_SEARCH_NC_2_4_3 = '"[^<>]*>'
      TAG_SEARCH_NC_2_4_3_2 = '")[^<>]*>'
      TAG_SEARCH_NC_2_4_4 = '"[^<>]*>'
      TAG_SEARCH_NC_2_6 = '"[^<>]*'
      TAG_SEARCH_NC_2_7 = '"|'

      TAG_SEARCH_3_1 = '<([^<>"]*)\\s[^<>]*'
      TAG_SEARCH_3_1_2 = '<([^<>"]*)\\s([^<>]*'
      TAG_SEARCH_3_1_2_2 = '<([^<>"]*)\\s([^<>]*('

      TAG_SEARCH_3_2 = '"[^<>]*\\/>'
      TAG_SEARCH_3_2_2 = '"[^<>]*)\\/>'
      TAG_SEARCH_3_2_2_2 = '")[^<>]*)\\/>'

      TAG_SEARCH_4_1 = '(\\s[^<>\\/]*)>('
      TAG_SEARCH_4_2 = '.*?<'
      TAG_SEARCH_4_3 = '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_4_4 = '<\\/'
      TAG_SEARCH_4_5 = '.*?<\/'
      TAG_SEARCH_4_6 = '.*?)<\/'
      TAG_SEARCH_4_7 = '"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))('
      TAG_SEARCH_4_7_2 = '")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))('

      TAG_SEARCH_NC_3_1 = '<[^<>"]*\\s[^<>]*'
      TAG_SEARCH_NC_3_1_2 = '<([^<>"]*)\\s(?:[^<>]*'
      TAG_SEARCH_NC_3_1_2_2 = '<([^<>"]*)\\s(?:[^<>]*('
      TAG_SEARCH_NC_3_2 = '"[^<>]*\\/>'
      TAG_SEARCH_NC_3_2_2 = '"[^<>]*)\\/>'
      TAG_SEARCH_NC_3_2_2_2 = '")[^<>]*)\\/>'
      #TAG_SEARCH_NC_4_1 = "(?:\\s[^<>\\/]*)>("
      #TAG_SEARCH_NC_4_2 = ".*?<"
      #TAG_SEARCH_NC_4_3 = "(?:\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      #TAG_SEARCH_NC_4_4 = "<\\/"
      #TAG_SEARCH_NC_4_5 = ".*?<\/"
      #TAG_SEARCH_NC_4_6 = ".*?<\/"
      #TAG_SEARCH_NC_4_7 = "\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
      #TAG_SEARCH_NC_4_7_2 = "\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

      #find
      # E
      PATTERN_FIND_1 = '^([^,\\[\\]#\\.]+)$'
      # #id_attribute_value
      PATTERN_FIND_2_1 = '^#([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # .class_attribute_value
      PATTERN_FIND_2_2 = '^\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # [attribute_name=attribute_value]
      PATTERN_FIND_2_3 = '^\\[([^\\[\\],]+)=([^\\[\\],]+)\\]$'
      # E[attribute_name=attribute_value]
      PATTERN_FIND_3_1 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,\\[\\]]+)=([^,\\[\\]]+)\\]$'
      # E#id_attribute_value
      PATTERN_FIND_3_2 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)#([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # E.class_attribute_value
      PATTERN_FIND_3_3 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # [attribute_name1=attribute_value1][attribute_name2=attribute_value2]
      PATTERN_FIND_4 = '^\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$'
      # E[attribute_name1=attribute_value1][attribute_name2=attribute_value2]
      PATTERN_FIND_5 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$'

      @@pattern_find_1 = Regexp.new(PATTERN_FIND_1)
      @@pattern_find_2_1 = Regexp.new(PATTERN_FIND_2_1)
      @@pattern_find_2_2 = Regexp.new(PATTERN_FIND_2_2)
      @@pattern_find_2_3 = Regexp.new(PATTERN_FIND_2_3)
      @@pattern_find_3_1 = Regexp.new(PATTERN_FIND_3_1)
      @@pattern_find_3_2 = Regexp.new(PATTERN_FIND_3_2)
      @@pattern_find_3_3 = Regexp.new(PATTERN_FIND_3_3)
      @@pattern_find_4 = Regexp.new(PATTERN_FIND_4)
      @@pattern_find_5 = Regexp.new(PATTERN_FIND_5)

      #setAttribute
      SET_ATTR_1 = '="[^"]*"'
      #getAttributeValue
      GET_ATTR_1 = '="([^"]*)"'
      #attributeMap
      GET_ATTRS_MAP = '([^\\s]*)="([^\"]*)"'
      #removeAttribute
      ERASE_ATTR_1 = '="[^"]*"\\s?'

      #cxtag
      #SEARCH_CX_1 = '<!--\\s@'
      #SEARCH_CX_2 = '\\s([^<>]*id="'
      #SEARCH_CX_3 = '\"[^<>]*)-->(((?!(<!--\\s\\/@'
      #SEARCH_CX_4 = ')).)*)<!--\\s\\/@'
      #SEARCH_CX_5 = '\\s-->'
      #SEARCH_CX_6 = '<!--\\s@([^<>]*)\\s[^<>]*id="'

      SEARCH_CX_1 = '<!--\\s@'
      #SEARCH_CX_1 = "<!--\\s@"
      SEARCH_CX_2 = '\\s([^<>]*id="'
      #SEARCH_CX_2 = "\\s([^<>]*id=\""
      SEARCH_CX_3 = '"[^<>]*)-->(((?!(<!--\\s/@'
      #SEARCH_CX_3 = "\"[^<>]*)-->(((?!(<!--\\s/@"
      SEARCH_CX_4 = ')).)*)<!--\\s/@'
      #SEARCH_CX_4 = ")).)*)<!--\\s/@"
      SEARCH_CX_5 = '\\s-->'
      #SEARCH_CX_5 = "\\s-->"
      SEARCH_CX_6 = '<!--\\s@([^<>]*)\\s[^<>]*id="'
      #SEARCH_CX_6 = "<!--\\s@([^<>]*)\\s[^<>]*id=\""

      #setElementToCXTag
      SET_CX_1 = '<!-- @'
      SET_CX_2 = '-->'
      SET_CX_3 = '<!-- /@'
      SET_CX_4 = ' -->'

      #setMonoInfo
      SET_MONO_1 = '\\A[^<>]*\\Z'

      @@pattern_set_mono1 = Regexp.new(SET_MONO_1)

      #clean
      CLEAN_1 = '<!--\\s@[^<>]*\\s[^<>]*(\\s)*-->'
      CLEAN_2 = '<!--\\s\\/@[^<>]*(\\s)*-->'
      #escape
      AND_1 = '&'
      AND_2 = '&amp;'
      AND_3 = 'amp'
      LT_1 = '<'
      LT_2 = '&lt;'
      LT_3 = 'lt'
      GT_1 = '>'
      GT_2 = '&gt;'
      GT_3 = 'gt'
      QO_2 = '&quot;'
      QO_3 = 'quot'
      AP_1 = '\''
      AP_2 = '&apos;'
      AP_3 = 'apos'
      #EN_1 = "\\\\"
      EN_1 = "\\"
      #EN_2 = "\\\\\\\\"
      #DOL_1 = "\\\$"
      #DOL_2 = "\\\\\\$"
      #PLUS_1 = "\\\+"
      #PLUS_2 = "\\\\\\+"

      ESCAPE_ENTITY_REF = String.new('')

      #SUB_REGEX1 = (\\\\*)\\\\([0-9]+)'
      #SUB_REGEX2 = '\\1\\1\\\\\\\\\\2'
      #SUB_REGEX3 = '\\1\\1\\1\\1\\\\\\\\\\\\\\\\\\2'

      #BRAC_OPEN_1 = "\\\("
      #BRAC_OPEN_2 = "\\\\\\("
      #BRAC_CLOSE_1 = "\\\)"
      #BRAC_CLOSE_2 = "\\\\\\)"
      #SBRAC_OPEN_1 = "\\\["
      #SBRAC_OPEN_2 = "\\\\\\["
      #SBRAC_CLOSE_1 = "\\\]"
      #SBRAC_CLOSE_2 = "\\\\\\]"
      #CBRAC_OPEN_1 = "\\\{"
      #CBRAC_OPEN_2 = "\\\\\\{"
      #CBRAC_CLOSE_1 = "\\\}"
      #CBRAC_CLOSE_2 = "\\\\\\}"
      #COMMA_1 = "\\\."
      #COMMA_2 = "\\\\\\."
      #VLINE_1 = "\\\|"
      #VLINE_2 = "\\\\\\|"
      #QMARK_1 = "\\\?"
      #QMARK_2 = "\\\\\\?"
      #ASTERISK_1 = "\\\*"
      #ASTERISK_2 = "\\\\\\*"

      #@@pattern_en = Regexp.new(EN_1)
      #@@pattern_dol = Regexp.new(DOL_1)
      #@@pattern_plus = Regexp.new(PLUS_1)
      #@@pattern_brac_open = Regexp.new(BRAC_OPEN_1)
      #@@pattern_brac_close = Regexp.new(BRAC_CLOSE_1)
      #@@pattern_sbrac_open = Regexp.new(SBRAC_OPEN_1)
      #@@pattern_sbrac_close = Regexp.new(SBRAC_CLOSE_1)
      #@@pattern_cbrac_open = Regexp.new(CBRAC_OPEN_1)
      #@@pattern_cbrac_close = Regexp.new(CBRAC_CLOSE_1)
      #@@pattern_comma = Regexp.new(COMMA_1)
      #@@pattern_vline = Regexp.new(VLINE_1)
      #@@pattern_qmark = Regexp.new(QMARK_1)
      #@@pattern_asterisk = Regexp.new(ASTERISK_1)

      #@@pattern_sub_regex1 = Regexp.new(SUB_REGEX1)

      @@pattern_get_attrs_map = Regexp.new(GET_ATTRS_MAP)

      @@pattern_clean1 = Regexp.new(CLEAN_1)
      @@pattern_clean2 = Regexp.new(CLEAN_2)

      MODE_UTF8 = 'r:UTF-8'
      MODE_BF = 'r:'
      MODE_AF = ':utf-8'

      CSS_ID = 'id'
      CSS_CLASS = 'class'

      attr_accessor :element_cache
      attr_accessor :doc_type
      attr_accessor :document_hook
      attr_accessor :element_hook

      #
      # set document (ドキュメントをセットする)
      #
      # @param [String] doc document (ドキュメント)
      #
      def document=(doc)
        @root.document = doc
      end

      #
      # get document (ドキュメントを取得する)
      # @return [String] document (ドキュメント)
      #
      def document
        @root.document
      end

      #
      # set character encoding (文字エンコーディングをセットする)
      # @param [String] enc character encoding (文字エンコーディング)
      #
      def character_encoding=(enc)
        @root.character_encoding = enc
      end

      #
      # get character encoding (文字エンコーディングを取得する)
      # @return [String] character encoding (文字エンコーディング)
      #
      def character_encoding
        @root.character_encoding
      end

      #
      # get root element (ルート要素を取得する)
      # @return [Meteor::RootElement] root element (ルート要素)
      #
      def root_element
        @root
      end

      #
      # initializer (イニシャライザ)
      #
      def initialize
        #親要素
        #@parent = nil

        #正規表現パターン
        #@pattern = nil
        #ルート要素
        @root = RootElement.new
        @root.parser = self
        #要素キャッシュ
        @element_cache = Hash.new
        #フックドキュメント
        @document_hook = String.new('')

        @error_check = true
      end

      #
      # read file , set in parser (ファイルを読み込み、パーサにセットする)
      # @param [String] file_path absolute path of input file (入力ファイルの絶対パス)
      # @param [String] enc character encoding of input file (入力ファイルの文字コード)
      #
      def read(file_path, enc)

        #try {
        @character_encoding = enc
        #ファイルのオープン
        if ParserFactory::ENC_UTF8.eql?(enc)
          #io = File.open(file_path,MODE_BF << enc)
          io = File.open(file_path, MODE_UTF8)
        else
          io = File.open(file_path, String.new('') << MODE_BF << enc << MODE_AF)
        end

        #読込及び格納
        @root.document = io.read

        parse

        #ファイルのクローズ
        io.close

        return @root.document
      end

      #
      # psrse document (ドキュメントを解析する)
      # @param [String] document document (ドキュメント)
      #
      def parse
      end

      #
      # get element (要素を取得する)
      # @overload element(name)
      #  get element using tag name (要素のタグ名で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @return [Meteor::Element] element(要素)
      # @overload element(name,attrs)
      #  get element using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
      #  @return [Meteor::Element] element (要素)
      # @overload element(attrs)
      #  get element using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
      #  @return [Meteor::Element] element (要素)
      # @overload element(name,attr_name,attr_value)
      #  get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload element(attr_name,attr_value)
      #  get element using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload element(name,attr_name1,attr_value1,attr_name2,attr_value2)
      #  get element using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
      #  @param [String] attr_value1 attribute value1 (属性値1)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
      #  @param [String] attr_value2 attribute value2 (属性値2)
      #  @return [Meteor::Element] element (要素)
      # @overload element(attr_name1,attr_value1,attr_name2,attr_value2)
      #  get element using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
      #  @param [String] attr_value1 attribute value1 (属性値1)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
      #  @param [String] attr_value2 attribute value2 (属性値2)
      #  @return [Meteor::Element] element (要素)
      # @overload element(elm)
      #  mirror element (要素を射影する)
      #  @param [Meteor::Element] elm element (要素)
      #  @return [Meteor::Element] element (要素)
      #
      def element(elm, attrs = nil,*args)
        if !attrs
          if elm.kind_of?(String) || elm.kind_of?(Symbol)
            element_1(elm.to_s)
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end
          elsif elm.kind_of?(Meteor::Element)
            shadow(elm)
          elsif elm.kind_of?(Hash)
            if elm.size == ONE
              element_2(elm.keys[0].to_s, elm.values[0])
              if @elm_
                @element_cache.store(@elm_.object_id, @elm_)
              end
            elsif elm.size == TWO
              element_4(elm.keys[0].to_s, elm.values[0], elm.keys[1].to_s, elm.values[1])
              if @elm_
                @element_cache.store(@elm_.object_id, @elm_)
              end
            else
              raise ArgumentError
            end
          else
            raise ArgumentError
          end
        elsif attrs.kind_of?(Hash)
          if attrs.size == ONE
            element_3(elm.to_s, attrs.keys[0].to_s, attrs.values[0])
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end
          elsif attrs.size == TWO
            element_5(elm.to_s, attrs.keys[0].to_s, attrs.values[0], attrs.keys[1].to_s, attrs.values[1])
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end
          else
            @elm_ = nil
            raise ArgumentError
          end
        elsif attrs.kind_of?(String) || attrs.kind_of?(Symbol)
          case args.length
            when ZERO
              element_2(elm.to_s,attrs.to_s)
              if @elm_
                @element_cache.store(@elm_.object_id, @elm_)
              end
            when ONE
              element_3(elm.to_s, attrs.to_s, args[0])
              if @elm_
                @element_cache.store(@elm_.object_id, @elm_)
              end
            when TWO
              element_4(elm.to_s, attrs.to_s, args[0].to_s,args[1])
              if @elm_
                @element_cache.store(@elm_.object_id, @elm_)
              end
            when THREE
              element_5(elm.to_s, attrs.to_s, args[0],args[1].to_s,args[2])
              if @elm_
                @element_cache.store(@elm_.object_id, @elm_)
              end
            else
              @elm_ = nil
              raise ArgumentError
          end
        else
          @elm_ = nil
          raise ArgumentError
        end
      end

      #
      # get element using tag name (タグ名で検索し、要素を取得する)
      # @param [String,Symbol] name tag name (タグ名)
      # @return [Meteor::Element] element(要素)
      #
      def element_1(name)

        @_name = Regexp.quote(name)

        #要素検索用パターン
        @pattern_cc = "<#{@_name}(|\\s[^<>]*)\\/>|<#{@_name}((?:|\\s[^<>]*))>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        #内容あり要素検索
        @res = @pattern.match(@root.document)

        if @res
          if @res[1]
            element_without_1(name)
          else
            #puts '---element_with_1'
            element_with_1(name)
          end
        #else
        end

        @elm_
      end

      private :element_1

      def element_with_1(name)

        @elm_ = Meteor::Element.new(name)

        unless @on_search
          #puts '--on_search=false'
          #puts @res.to_a
          #属性
          @elm_.attributes = @res[2]
          #内容
          @elm_.mixed_content = @res[3]
          #全体
          @elm_.document = @res[0]
        else
          #puts '--on_search=true'
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
        end
        #内容あり要素検索用パターン
        #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_NC_1_1 << @_name
        #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
        @pattern_cc = "<#{@_name}(|\\s[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @elm_.pattern = @pattern_cc

        @elm_.empty = true

        @elm_.parser = self

        @elm_
      end

      private :element_with_1

      def element_without_1(name)
        #要素
        @elm_ = Meteor::Element.new(name)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_1_3
        #@pattern_cc = "<#{@_name}(|\\s[^<>]*)\\/>"
        @elm_.pattern = @pattern_cc

        @elm_.empty = false

        @elm_.parser = self

        @elm_
      end

      private :element_without_1

      #
      # get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で検索し、要素を取得する)
      # @param [String] name tag name (タグ名)
      # @param [String] attr_name attribute name (属性名)
      # @param [String] attr_value attribute value (属性値)
      # @return [Meteor::Element] element (要素)
      def element_3(name, attr_name, attr_value)

        element_quote_3(name,attr_name,attr_value)

        @pattern_cc_1 = element_pattern_3

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_with_3_2
          @pattern_cc_2 = @pattern_cc

          #puts @res2.captures.length
          #puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            #@pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_3(name)
            else
              element_with_3_1(name)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            #@pattern_cc = @pattern_cc_2
            element_with_3_1(name)
          end
        elsif @res1 && !@res2
          @res = @res1
          #@pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_3(name)
          else
            element_with_3_1(name)
          end
        elsif @res2 && !@res1
          @res = @res2
          #@pattern_cc = @pattern_cc_2
          element_with_3_1(name)
        else
          if @error_check
            puts Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message
          end
          @elm_ = nil
        end

        @elm_
      end

      private :element_3

      def element_pattern_3
        "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>|<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"
      end

      private :element_pattern_3

      def element_quote_3(name,attr_name,attr_value)
        @_name = Regexp.quote(name)
        @_attr_name = Regexp.quote(attr_name)
        @_attr_value = Regexp.quote(attr_value)
      end

      private :element_quote_3

      def element_with_3_1(name)
        #puts  @res.captures.length
        case @res.captures.length
        when FOUR
          #要素
          @elm_ = Meteor::Element.new(name)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = String.new('')<< TAG_OPEN << @_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
          #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_name
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
          @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        when FIVE
          #要素
          @elm_ = Meteor::Element.new(name)
          #属性
          @elm_.attributes = @res[2]
          #内容
          @elm_.mixed_content = @res[3]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = String.new('')<< TAG_OPEN << @_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
          #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_name
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
          @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        when THREE,SIX
          #内容
          @elm_ = Meteor::Element.new(name)
          unless @on_search
            #属性
            @elm_.attributes = @res[1].chop
            #内容
            @elm_.mixed_content = @res[3]
          else
            #属性
            @elm_.attributes = @res[1].chop
            #内容
            @elm_.mixed_content = @res[3]
          end
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self
        end
        @elm_
      end

      private :element_with_3_1

      def element_with_3_2

        element_pattern_with_3_2

        if @sbuf.length == ZERO || @cnt != ZERO
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end

      private :element_with_3_2

      def element_pattern_with_3_2

        #@pattern_cc_1 = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1 << @_attr_value << TAG_SEARCH_2_4_2
        @pattern_cc_1 = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"

        @pattern_cc_1b = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_1_4
        #@pattern_cc_1b = "<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        #@pattern_cc_1_1 = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value << TAG_SEARCH_4_7
        @pattern_cc_1_1 = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = String.new('') << TAG_SEARCH_4_2 << @_name << TAG_SEARCH_4_3
        #@pattern_cc_1_2 = ".*?<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"


        @pattern_cc_2 = String.new('') << TAG_SEARCH_4_4 << @_name << TAG_CLOSE
        #@pattern_cc_2 = String.new('') << "<\\/#{@_name}>"

        @pattern_cc_2_1 = String.new('') << TAG_SEARCH_4_5 << @_name << TAG_CLOSE
        #@pattern_cc_2_1 = ".*?<\\/#{@_name}>"

        @pattern_cc_2_2 = String.new('') << TAG_SEARCH_4_6 << @_name << TAG_CLOSE
        #@pattern_cc_2_2 = ".*?)<\\/#{@_name}>"

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = String.new('')

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf

      end

      private :element_pattern_with_3_2

      def element_without_3(name)
        element_without_3_1(name, TAG_SEARCH_2_3_2)
      end

      private :element_without_3

      def element_without_3_1(name, closer)

        #要素
        @elm_ = Meteor::Element.new(name)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ << @_attr_value << closer
        #@pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}#{closer}"
        @elm_.pattern = @pattern_cc

        @elm_.parser = self

        @elm_
      end

      private :element_without_3_1

      #
      # get element using attribute(name="value") (属性(属性名="属性値")で検索し、要素を取得する)
      # @param [String] attr_name attribute name (属性名)
      # @param [String] attr_value attribute value (属性値)
      # @return [Meteor::Element] element (要素)
      #
      def element_2(attr_name, attr_value)

        element_quote_2(attr_name,attr_value)

        element_pattern_2

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        if @res
          element_3(@res[1], attr_name, attr_value)
        else
          if @error_check
            puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
          end
          @elm_ = nil
        end
#=end

=begin
       @pattern_cc_1 = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>|<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(\\3[^<>]*>)).)*)<\\/\\3>"


        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_with_2_2
          @pattern_cc_2 = @pattern_cc

          #puts @res2.captures.length
          #puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            #@pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_2
            else
              element_with_2_1
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            #@pattern_cc = @pattern_cc_2
            element_with_2_1
          end
        elsif @res1 && !@res2
          @res = @res1
          #@pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_2
          else
            element_with_2_1
          end
        elsif @res2 && !@res1
          @res = @res2
          #@pattern_cc = @pattern_cc_2
          element_with_2_1
        else
          if @error_check
            puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
          end
          @elm_ = nil
        end
=end

        @elm_
      end

      private :element_2

      def element_quote_2(attr_name, attr_value)
        @_attr_name = Regexp.quote(attr_name)
        @_attr_value = Regexp.quote(attr_value)
      end

      private :element_quote_2

      def element_pattern_2

        ##@pattern_cc = String.new('') << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value << TAG_SEARCH_2_4
        #@pattern_cc = String.new('') << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value << TAG_SEARCH_2_4_2_3
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\""
      end

      private :element_pattern_2

=begin
     def element_with_2_1
        #puts @res.captures.length
        case @res.captures.length
          when FOUR
            @_name = @res[1]
            #要素
            @elm_ = Element.new(@_name)
            #属性
            @elm_.attributes = @res[2]
            #内容
            @elm_.mixed_content = @res[3]
            #全体
            @elm_.document = @res[0]
            #内容あり要素検索用パターン
            #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_name
            #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
            @pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>"

            @elm_.pattern = @pattern_cc

            @elm_.empty = true

            @elm_.parser = self

          when FIVE,SEVEN
            @_name = @res[3]
            #要素
            @elm_ = Element.new(@_name)
            #属性
            @elm_.attributes = @res[4]
            #内容
            @elm_.mixed_content = @res[5]
            #全体
            @elm_.document = @res[0]
            #内容あり要素検索用パターン
            #@pattern_cc = String.new()<< TAG_OPEN << @_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_name
            #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
            @pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>"

            @elm_.pattern = @pattern_cc

            @elm_.empty = true

            @elm_.parser = self

          when THREE,SIX
            #puts @res[1]
            #puts @res[3]
            #@_name = @res[1]
            #内容
            @elm_ = Element.new(@_name)
            #属性
            @elm_.attributes = @res[1].chop
            #内容
            @elm_.mixed_content = @res[3]
            #全体
            @elm_.document = @res[0]
            #内容あり要素検索用パターン
            @elm_.pattern = @pattern_cc

            @elm_.empty = true

            @elm_.parser = self
        end
        @elm_
      end

      private :element_with_2_1

      def element_with_2_2

        #@pattern_cc_1 = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1 << @_attr_value << TAG_SEARCH_2_4_2
        @pattern_cc_1 = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = String.new('')

        @cnt = 0

        create_element_pattern_2(2)

        @pattern_cc = @sbuf

        if @sbuf.length == ZERO || @cnt != ZERO
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        #@res
      end

      private :element_with_2_2

      def create_pattern_2(args_cnt)

        #puts @_name

        @pattern_cc_1b = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_1_4

        #@pattern_cc_1_1 = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value << TAG_SEARCH_4_7
        @pattern_cc_1_1 = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = String.new('') << TAG_SEARCH_4_2 << @_name << TAG_SEARCH_4_3

        @pattern_cc_2 = String.new('') << TAG_SEARCH_4_4 << @_name << TAG_CLOSE

        @pattern_cc_2_1 = String.new('') << TAG_SEARCH_4_5 << @_name << TAG_CLOSE

        @pattern_cc_2_2 = String.new('') << TAG_SEARCH_4_6 << @_name << TAG_CLOSE

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)

      end

      def element_without_2
        element_without_2_1(TAG_SEARCH_NC_2_3_2)
      end

      private :element_without_2

      def element_without_2_1(closer)

        #要素
        @elm_ = Element.new(@res[1])
        #属性
        @elm_.attributes = @res[2]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ << @_attr_value << closer
        @elm_.pattern = @pattern_cc

        @elm_.parser = self

        @elm_
      end

      private :element_without_2_1
=end

      #
      # get element using tag name and attribute1,2(name="value") (要素のタグ名と属性1・属性2(属性名="属性値")で検索し、要素を取得する)
      # @param [String] name tag name (タグ名)
      # @param [String] attr_name1 attribute name1 (属性名1)
      # @param [String] attr_value1 attribute value1 (属性値1)
      # @param [String] attr_name2 attribute name2 (属性名2)
      # @param [String] attr_value2 attribute value2 (属性値2)
      # @return [Meteor::Element] element (要素)
      #
      def element_5(name, attr_name1, attr_value1, attr_name2, attr_value2)

        element_quote_5(name, attr_name1, attr_value1, attr_name2, attr_value2)

        @pattern_cc_1 = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)\\/>|<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_with_5_2
          @pattern_cc_2 = @pattern_cc

          #puts @res2.captures.length
          #puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            #@pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_5(name)
            else
              element_with_5_1(name)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            #@pattern_cc = @pattern_cc_2
            element_with_5_1(name)
          end
        elsif @res1 && !@res2
          @res = @res1
          #@pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_5(name)
          else
            element_with_5_1(name)
          end
        elsif @res2 && !@res1
          @res = @res2
          #@pattern_cc = @pattern_cc_2
          element_with_5_1(name)
        else
          if @error_check
            puts Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message
          end
          @elm_ = nil
        end

        @elm_
      end

      private :element_5

      def element_quote_5(name, attr_name1, attr_value1, attr_name2, attr_value2)
        @_name = Regexp.quote(name)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)
      end

      private :element_quote_5

      def element_with_5_1(name)

        #puts @res.captures.length
        case @res.captures.length
        when FOUR
          #要素
          @elm_ = Meteor::Element.new(name)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_2_2 << @_name
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
          @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc
          #
          @elm_.empty = true

          @elm_.parser = self
        when FIVE
          #要素
          @elm_ = Meteor::Element.new(name)
          #属性
          @elm_.attributes = @res[2]
          #内容
          @elm_.mixed_content = @res[3]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_2_2 << @_name
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_name << TAG_CLOSE
          @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc
          #
          @elm_.empty = true

          @elm_.parser = self

        when THREE,SIX
          #要素
          @elm_ = Meteor::Element.new(name)
          #属性
          @elm_.attributes = @res[1].chop
          #要素
          @elm_.mixed_content = @res[3]
          #全体
          @elm_.document = @res[0]
          #要素ありタグ検索用パターン
          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self
        end
        @elm_
      end

      private :element_with_5_1

      def element_with_5_2

        element_pattern_with_5_2

        if @sbuf.length == ZERO || @cnt != ZERO
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end

      private :element_with_5_2

      def element_pattern_with_5_2

        #@pattern_cc_1 = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_4_2_2
        @pattern_cc_1 = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))"

        @pattern_cc_1b = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_1_4
        #@pattern_cc_1b = "<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        #@pattern_cc_1_1 = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value1 << TAG_SEARCH_4_7_2
        @pattern_cc_1_1 = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = String.new('') << TAG_SEARCH_4_2 << @_name << TAG_SEARCH_4_3

        @pattern_cc_2 = String.new('') << TAG_SEARCH_4_4 << @_name << TAG_CLOSE

        @pattern_cc_2_1 = String.new('') << TAG_SEARCH_4_5 << @_name << TAG_CLOSE

        @pattern_cc_2_2 = String.new('') << TAG_SEARCH_4_6 << @_name << TAG_CLOSE

        #@pattern_cc_1_2 = ".*?<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        #
        #@pattern_cc_2 = String.new('') << "<\\/#{@_name}>"
        #
        #@pattern_cc_2_1 = ".*?<\\/#{@_name}>"
        #
        #@pattern_cc_2_2 = ".*?)<\\/#{@_name}>"

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = String.new('')

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf

      end

      private :element_pattern_with_5_2

      def element_without_5(name)
        element_without_5_1(name, TAG_SEARCH_2_3_2_2)
      end

      private :element_without_5

      def element_without_5_1(name, closer)

        #要素
        @elm_ = Meteor::Element.new(name)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << closer
        @pattern_cc = "<#{@_name}(\\s[^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}#{closer}"

        @elm_.pattern = @pattern_cc

        @elm_.parser = self

        @elm_
      end

      private :element_without_5_1

      #
      # get element using attribute1,2(name="value") (属性1・属性2(属性名="属性値")で検索し、要素を取得する)
      # @param [String] attr_name1 attribute name1 (属性名1)
      # @param [String] attr_value1 attribute value1 (属性値1)
      # @param [String] attr_name2 attribute name2 (属性名2)
      # @param [String]attr_value2 attribute value2 (属性値2)
      # @return [Meteor::Element] element (要素)
      #
      def element_4(attr_name1, attr_value1, attr_name2, attr_value2)

        element_quote_4(attr_name1, attr_value1, attr_name2, attr_value2)

        element_pattern_4

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        if @res
          #@elm_ = element_5(@res[1], attr_name1, attr_value1,attr_name2, attr_value2)
          element_5(@res[1], attr_name1, attr_value1, attr_name2, attr_value2)
        else
          if @error_check
            puts Meteor::Exception::NoSuchElementException.new(attr_name1, attr_value1, attr_name2, attr_value2).message
          end
          @elm_ = nil
        end

        @elm_
      end

      private :element_4

      def element_quote_4(attr_name1, attr_value1, attr_name2, attr_value2)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)
      end

      private :element_quote_4

      def element_pattern_4

        #@pattern_cc = String.new('') << TAG_SEARCH_3_1_2_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_4_2_3
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")"

      end

      private :element_pattern_4

      def create_element_pattern
        @position = 0

        while (@res = @pattern.match(@root.document, @position)) || @cnt > ZERO

          if @res

            if @cnt > ZERO

              @position2 = @res.end(0)

              @res = @pattern_2.match(@root.document, @position)

              if @res

                @position = @res.end(0)

                if @position > @position2

                  @sbuf << @pattern_cc_1_2

                  @cnt += 1

                  @position = @position2
                else

                  @cnt -= ONE

                  if @cnt != ZERO
                    @sbuf << @pattern_cc_2_1
                  else
                    @sbuf << @pattern_cc_2_2
                    break
                  end

                end
              else

                @sbuf << @pattern_cc_1_2

                @cnt += 1

                @position = @position2
              end
            else
              @position = @res.end(0)

              @sbuf << @pattern_cc_1_1

              @cnt += ONE
            end
          else

            if @cnt == ZERO
              break
            end

            @res = @pattern_2.match(@root.document, @position)

            if @res

              @cnt -= ONE

              if @cnt != ZERO
                @sbuf << @pattern_cc_2_1
              else
                @sbuf << @pattern_cc_2_2
                break
              end

              @position = @res.end(0)
            else
              break
            end

          end

          @pattern = @pattern_1b
        end
      end

      private :create_element_pattern

=begin
      def create_element_pattern_2(args_cnt)
        @position = 0

        while (@res = @pattern.match(@root.document, @position)) || @cnt > ZERO

          if @res

            if @cnt > ZERO

              @position2 = @res.end(0)

              @res = @pattern_2.match(@root.document, @position)

              if @res

                @position = @res.end(0)

                if @position > @position2

                  @sbuf << @pattern_cc_1_2

                  @cnt += 1

                  @position = @position2
                else

                  @cnt -= ONE

                  if @cnt != ZERO
                    @sbuf << @pattern_cc_2_1
                  else
                    @sbuf << @pattern_cc_2_2
                    break
                  end

                end
              else

                @sbuf << @pattern_cc_1_2

                @cnt += 1

                @position = @position2
              end
            else
              @position = @res.end(0)

              @_name = @res[1]

              create_pattern_2(args_cnt)

              @sbuf << @pattern_cc_1_1

              @cnt += ONE

            end
          else

            if @cnt == ZERO
              break
            end

            @res = @pattern_2.match(@root.document, @position)

            if @res

              @cnt -= ONE

              if @cnt != ZERO
                @sbuf << @pattern_cc_2_1
              else
                @sbuf << @pattern_cc_2_2
                break
              end

              @position = @res.end(0)
            else
              break
            end

          end

          @pattern = @pattern_1b
        end
      end

      private :create_element_pattern_2

      #def create_pattern_2
      #end

      #private :create_pattern_2
=end

      # get elements (要素を取得する)
      # @overload elements(name)
      #  get elements using tag name (要素のタグ名で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @return [Array<Meteor::Element>] element array(要素配列)
      # @overload elements(name,attrs)
      #  get elements using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
      #  @return [Array<Meteor::Element>] element array (要素配列)
      # @overload elements(attrs)
      #  get elements using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
      #  @return [Array<Meteor::Element>] element array (要素配列)
      # @overload elements(name,attr_name,attr_value)
      #  get elements using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      #  @return [Array<Meteor::Element>] element array (要素配列)
      # @overload elements(attr_name,attr_value)
      #  get elements using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      #  @return [Array<Meteor::Element>] element array (要素配列)
      # @overload elements(name,attr_name1,attr_value1,attr_name2,attr_value2)
      #  get elements using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
      #  @param [String] attr_value1 attribute value1 (属性値1)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
      #  @param [String] attr_value2 attribute value2 (属性値2)
      #  @return [Array<Meteor::Element>] element array (要素配列)
      # @overload elements(attr_name1,attr_value1,attr_name2,attr_value2)
      #  get elements using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
      #  @param [String] attr_value1 attribute value1 (属性値1)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
      #  @param [String] attr_value2 attribute value2 (属性値2)
      #  @return [Array<Meteor::Element>] element array (要素配列)
      #
      def elements(elm, attrs = nil,*args)
        if !attrs
          if elm.kind_of?(String)
            elements_(elm)
          elsif elm.kind_of?(Hash)
            if elm.size == ONE
              elements_(elm.keys[0], elm.values[0])
            elsif elm.size == TWO
              elements_(elm.keys[0], elm.values[0], elm.keys[1], elm.values[1])
            else
              raise ArgumentError
            end
          else
            raise ArgumentError
          end
        elsif attrs.kind_of?(Hash)
          if attrs.size == ONE
            elements_(elm, attrs.keys[0], attrs.values[0])
          elsif attrs.size == TWO
            elements_(elm, attrs.keys[0], attrs.values[0], attrs.keys[1], attrs.values[1])
          else
            @elm_ = nil
            raise ArgumentError
          end
        elsif attrs.kind_of?(String)
          case args.length
            when ZERO
              elements_(elm,attrs)
            when ONE
              elements_(elm, attrs, args[0])
            when TWO
              elements_(elm, attrs, args[0],args[1])
            when THREE
              elements_(elm, attrs, args[0],args[1],args[2])
            else
              @elm_ = nil
              raise ArgumentError
          end
        else
          @elm_ = nil
          raise ArgumentError
        end
      end

      def elements_(*args)
        elm_arr = Array.new

        @on_search = true

        case args.size
          when ONE
            @elm_ = element_1(*args)
          when TWO
            @elm_ = element_2(*args)
          when THREE
            @elm_ = element_3(*args)
          when FOUR
            @elm_ = element_4(*args)
          when FIVE
            @elm_ = element_5(*args)
        end

        if !@elm_
          return elm_arr
        end

        @pattern_cc = @elm_.pattern

        #puts @pattern_cc

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @position = 0

        while (@res = @pattern.match(@root.document,@position))
          @position = @res.end(0)
          #puts @res[0]
          #if @res
            case args.size
              when ONE
                if @elm_.empty
                  element_with_1(@elm_.name)
                else
                  element_without_1(@elm_.name)
                end
              when TWO,THREE
                if @elm_.empty
                  element_with_3_1(@elm_.name)
                else
                  element_without_3(@elm_.name)
                end
              when FOUR,FIVE
                if @elm_.empty
                  element_with_5_1(@elm_.name)
                else
                  element_without_5(@elm_.name)
                end
            end

            @elm_.pattern = Regexp.quote(@elm_.document)
            elm_arr << @elm_

            @element_cache.store(@elm_.object_id, @elm_)

          #else
          #  break
          #end
        end
        
        @on_search = false
        
        elm_arr
      end

      #
      # get elements using selector like CSS3 (CSS3のようにセレクタを用いて要素を取得する)
      # CSS3 selector partial support (CSS3セレクタの部分的サポート)
      # @param [String] selector selector (セレクタ)
      # @return [Array<Meteor::Element>] element array (要素配列)
      #
      def find(selector)
        open_count = selector.count('[')

        case open_count
          when ZERO
            if selector.count('#.') == 0
              if @res = @@pattern_find_1.match(selector)
                elements_(@res[1])
              else
                nil
              end
            elsif selector.count('#') == 1
              if  selector[0] == '#'
                if @res = @@pattern_find_2_1.match(selector)
                  elements_(CSS_ID, @res[1])
                else
                  nil
                end
              else
                if @res = @@pattern_find_3_2.match(selector)
                  elements_(@res[1], CSS_ID, @res[2])
                else
                  nil
                end
              end
            elsif selector.count('.') == 1
              if  selector[0] == '.'
                if @res = @@pattern_find_2_2.match(selector)
                  elements_(CSS_CLASS, @res[1])
                else
                  nil
                end
              else
                if @res = @@pattern_find_3_3.match(selector)
                  elements_(@res[1], CSS_CLASS, @res[2])
                else
                  nil
                end
              end
            end
          when ONE
            if selector[0] == '['
              if @res = @@pattern_find_2_3.match(selector)
                elements_(@res[1], @res[2])
              else
                nil
              end
            else
              if @res = @@pattern_find_3_1.match(selector)
                elements_(@res[1], @res[2], @res[3])
              else
                nil
              end
            end
          when 2
            if selector[0] == '['
              if @res = @@pattern_find_4.match(selector)
                elements_(@res[1], @res[2], @res[3], @res[4])
              else
                nil
              end
            else
              if @res = @@pattern_find_5.match(selector)
                elements_(@res[1], @res[2], @res[3], @res[4], @res[5])
              else
                nil
              end
            end
          else
            nil
        end
      end

      #
      # @overload attr(elm,attr)
      #  set attribute of element (要素の属性をセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [Hash<String,String>,Hash<Symbol,String>] attr attribute (属性)
      #  @return [Meteor::Element] element (要素)
      # @overload attr(elm,attr_name,attr_value)
      #  set attribute of element (要素の属性をセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [String,Symbol] attr_name  attribute name (属性名)
      #  @param [String,true,false] attr_value attribute value (属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload attr(elm,attr_name)
      #  get attribute value of element (要素の属性値を取得する)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @return [String] attribute value (属性値)
      #
      def attr(elm, attr,*args)
        if attr.kind_of?(String) || attr.kind_of?(Symbol)
          case args.length
            when ZERO
              get_attr_value(elm, attr.to_s)
            when ONE
              if args[0] != nil
                elm.document_sync = true
                set_attribute_3(elm, attr.to_s,args[0])
              else
                remove_attr(elm, attr.to_s)
              end
          end

        elsif attr.kind_of?(Hash) && attr.size == 1
          if attr.values[0] != nil
            elm.document_sync = true
            set_attribute_3(elm, attr.keys[0].to_s, attr.values[0])
          else
            remove_attr(elm, attr.keys[0].to_s)
          end
        #elsif attrs.kind_of?(Hash) && attrs.size >= 1
        #  elm.document_sync = true
        #  attrs.each{|name,value|
        #    set_attribute_3(elm,name,value)
        #  }
        else
          raise ArgumentError
        end
      end

      #
      # set attribute of element (要素の属性を編集する)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] attr_name  attribute name (属性名)
      # @param [String,true,false] attr_value attribute value (属性値)
      # @return [Meteor::Element] element (要素)
      #
      def set_attribute_3(elm, attr_name, attr_value)
        if !elm.cx
          attr_value = escape(attr_value.to_s)
          #属性群の更新
          edit_attrs_(elm, attr_name, attr_value)
        end
        elm
      end

      private :set_attribute_3

      def edit_attrs_(elm, attr_name, attr_value)

        #属性検索
        #@res = @pattern.match(elm.attributes)

        #検索対象属性の存在判定
        if elm.attributes.include?(String.new(' ') << attr_name << ATTR_EQ)

          @_attr_value = attr_value

          #属性の置換
          @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << SET_ATTR_1)
          #@pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"")

          elm.attributes.sub!(@pattern, String.new('') << attr_name << ATTR_EQ << @_attr_value << DOUBLE_QUATATION)
          #elm.attributes.sub!(@pattern, "#{attr_name}=\"#{@_attr_value}\"")
        else
          #属性文字列の最後に新規の属性を追加する
          @_attr_value = attr_value

          if EMPTY != elm.attributes && EMPTY != elm.attributes.strip
            elm.attributes = String.new('') << SPACE << elm.attributes.strip
          else
            elm.attributes = String.new('')
          end

          elm.attributes << SPACE << attr_name << ATTR_EQ << @_attr_value << DOUBLE_QUATATION
          #elm.attributes << " #{attr_name}=\"#{@_attr_value}\""
        end
      end

      private :edit_attrs_

      #
      # get attribute value of element (要素の属性値を取得する)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] attr_name attribute name (属性名)
      # @return [String] attribute value (属性値)
      #
      def get_attr_value(elm, attr_name)
        get_attr_value_(elm, attr_name)
      end

      private :get_attr_value

      def get_attr_value_(elm, attr_name)

        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << GET_ATTR_1)
        #@pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"([^\"]*)\"")

        @res = @pattern.match(elm.attributes)

        if @res
          unescape(@res[1])
        else
          nil
        end
      end

      private :get_attr_value_

      #
      # @overload attrs(elm,attrs)
      #  @param [Meteor::element] elm element (要素)
      #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
      # @overload attrs(elm)
      #  @param [Meteor::element] elm element (要素)
      #  @return [Hash<String,String>] attribute map (要素マップ)
      #
      def attrs(elm,*args)
        case args.length
          when ZERO
            get_attrs(elm)
          when ONE
            if args[0].kind_of?(Hash)
              if args[0].size == 1
                elm.document_sync = true
                set_attribute_3(elm, args[0].keys[0].to_s, args[0].values[0])
              elsif args[0].size >= 1
                set_attrs(elm, args[0])
              else
                raise ArgumentError
              end
            else
              raise ArgumentError
            end
          else
            raise ArgumentError
        end
      end

      #
      # get attribute map (属性マップを取得する)
      # @param [Meteor::Element] elm element (要素)
      # @return [Hash<String,String>] attribute map (属性マップ)
      #
      def get_attrs(elm)
        attrs = Hash.new

        elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
          attrs.store(a, unescape(b))
        end

        attrs
      end

      private :get_attrs

      #
      # set attribute map  (要素に属性マップをセットする)
      # @param [Meteor::Element] elm element (要素)
      # @param [Hash<String,String>] attr_map attribute map (属性マップ)
      # @return [Meteor::Element] element (要素)
      #
      def set_attrs(elm, attr_map)
        if !elm.cx
          elm.document_sync = true
          attr_map.each do |name, value|
            set_attribute_3(elm, name.to_s, value)
          end
        end
        elm
      end

      private :set_attrs

      #
      # @overload attr_map(elm,attr_map)
      #  set attribute map (属性マップをセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
      #  @return [Meteor::Element] element (要素)
      # @overload attr_map(elm)
      #  get attribute map (属性マップを取得する)
      #  @param [Meteor::Element] elm element (要素)
      #  @return [Meteor::AttributeMap] attribute map (属性マップ)
      #
      def attr_map(elm,*args)
        case args.length
          when ZERO
            get_attr_map(elm)
          when ONE
            #if elm.kind_of?(Meteor::Element) && args[0].kind_of?(Meteor::AttributeMap)
            elm.document_sync = true
            set_attr_map(elm, args[0])
            #end
          else
            raise ArgumentError
        end
      end

      #
      # get attribute map (属性マップを取得する)
      # @param [Meteor::Element] elm element (要素)
      # @return [Meteor::AttributeMap] attribute map (属性マップ)
      #
      def get_attr_map(elm)
        attrs = Meteor::AttributeMap.new

        elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
          attrs.store(a, unescape(b))
        end
        attrs.recordable = true

        attrs
      end

      private :get_attr_map

      #
      # set attribute map  (要素に属性マップをセットする)
      # @param [Meteor::Element] elm element (要素)
      # @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
      # @return [Meteor::Element] element (要素)
      #
      def set_attr_map(elm, attr_map)
        if !elm.cx
          attr_map.map.each do |name, attr|
            if attr_map.changed(name)
              edit_attrs_(elm, name.to_s, attr.value)
            elsif attr_map.removed(name)
              remove_attrs_(elm, name.to_s)
            end
          end
        end
        elm
      end

      private :set_attr_map

      #
      # @overload content(elm,content,entity_ref=true)
      #  set contents of element (要素の内容をセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [String] content content of element (要素の内容)
      #  @param [true,false] entity_ref entity reference flag (エンティティ参照フラグ)
      #  @return [Meteor::Element] element (要素)
      #  @deprecated
      # @overload content(elm,content)
      #  set content of element (要素の内容をセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [String] content content of element (要素の内容)
      #  @return [Meteor::Element] element (要素)
      # @overload content(elm)
      #  get content of element (要素の内容を取得する)
      #  @param [Meteor::Element] elm element (要素)
      #  @return [String] content (内容)
      #
      def content(*args)
        case args.length
          when ONE
            #if args[0].kind_of?(Meteor::Element)
            get_content_1(args[0])
          #else
          #  raise ArgumentError
          #end
          when TWO
            #if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String)
            args[0].document_sync = true
            set_content_2(args[0], args[1].to_s)
            #else
            #  raise ArgumentError
            #end
          when THREE
            args[0].document_sync = true
            set_content_3(args[0], args[1].to_s, args[2])
          else
            raise ArgumentError
        end
      end

      #
      # set content of element (要素の内容をセットする)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] content content of element (要素の内容)
      # @param [true,false] entity_ref entity reference flag (エンティティ参照フラグ)
      # @return [Meteor::Element] element (要素)
      #
      def set_content_3(elm, content, entity_ref=true)

        if entity_ref || !elm.raw_content
          escape_content(content, elm)
        end
        elm.mixed_content = content
        elm
      end

      private :set_content_3

      #
      # set content of element (要素の内容をセットする)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] content content of element (要素の内容)
      # @return [Meteor::Element] element (要素)
      #
      def set_content_2(elm, content)
        #set_content_3(elm, content)
        unless elm.raw_content
          escape_content(content, elm)
        end
        elm.mixed_content = content
        elm
      end

      private :set_content_2

      #
      # get content of element (要素の内容を取得する)
      # @param [Meteor::Element] elm element (要素)
      # @return [String] content (内容)
      #
      def get_content_1(elm)
        if !elm.cx
          if elm.empty
            unescape_content(elm.mixed_content, elm)
          else
            nil
          end
        else
          unescape_content(elm.mixed_content, elm)
        end
      end

      private :get_content_1

      #
      # remove attribute of element (要素の属性を消す)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] attr_name attribute name (属性名)
      # @return [Meteor::Element] element (要素)
      #
      def remove_attr(elm, attr_name)
        if !elm.cx
          elm.document_sync = true
          remove_attrs_(elm, attr_name.to_s)
        end

        elm
      end

      def remove_attrs_(elm, attr_name)
        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << ERASE_ATTR_1)
        #@pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"\\s?")
        #属性の置換
        elm.attributes.sub!(@pattern, EMPTY)
      end

      private :remove_attrs_

      #
      # remove element (要素を消す)
      # @param [Meteor::Element] elm element (要素)
      #
      def remove_element(elm)
        elm.removed = true
        nil
      end

      #
      # get cx(comment extension) tag (CX(コメント拡張)タグを取得する)
      # @overload cxtag(name,id)
      #  get cx(comment extension) tag using tag name and id attribute (要素のタグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String] id id attribute value (ID属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload cxtag(id)
      #  get cx(comment extension) tag using id attribute (ID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
      #  @param [String] id id attribute value (ID属性値)
      #  @return [Meteor::Element] element (要素)
      #
      def cxtag(*args)
        case args.length
          when ONE
            cxtag_1(args[0].to_s)
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end
          when TWO
            cxtag_2(args[0].to_s, args[1].to_s)
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end
          else
            raise ArgumentError
        end
      end

      #
      # get cx(comment extension) tag using tag name and id attribute (要素のタグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
      # @param [String] name tag name (タグ名)
      # @param [String] id id attribute value (ID属性値)
      # @return [Meteor::Element] element (要素)
      #
      def cxtag_2(name, id)

        @_name = Regexp.quote(name)
        @_id = Regexp.quote(id)

        #CXタグ検索用パターン
        #@pattern_cc = String.new('') << SEARCH_CX_1 << @_name << SEARCH_CX_2
        #@pattern_cc << id << SEARCH_CX_3 << @_name << SEARCH_CX_4 << @_name << SEARCH_CX_5
        #@pattern_cc = "<!--\\s@#{tag}\\s([^<>]*id=\"#{id}\"[^<>]*)-->(((?!(<!--\\s\\/@#{tag})).)*)<!--\\s\\/@#{tag}\\s-->"
        @pattern_cc = "<!--\\s@#{@_name}\\s([^<>]*id=\"#{@_id}\"[^<>]*)-->(((?!(<!--\\s/@#{@_name})).)*)<!--\\s/@#{@_name}\\s-->"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        #CXタグ検索
        @res = @pattern.match(@root.document)

        if @res
          #要素
          @elm_ = Meteor::Element.new(name)

          @elm_.cx = true
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #要素検索パターン
          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self
        else
          @elm_ = nil
        end

        @elm_
      end

      private :cxtag_2

      #
      # get cx(comment extension) tag using id attribute (ID属性(id="ID属性値")で検索し、CX(コメント拡張)タグを取得する)
      # @param [String] id id attribute value (ID属性値)
      # @return [Meteor::Element] element (要素)
      #
      def cxtag_1(id)

        @_id = Regexp.quote(id)

        @pattern_cc = String.new('') << SEARCH_CX_6 << @_id << DOUBLE_QUATATION
        #@pattern_cc = "<!--\\s@([^<>]*)\\s[^<>]*id=\"#{@_id}\""

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res
          #@elm_ = cxtag(@res[1],id)
          cxtag(@res[1], id)
        else
          @elm_ = nil
        end

        @elm_
      end

      private :cxtag_1

      #
      # replace element (要素を置換する)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] replace_document string for replacement (置換文字列)
      #
      def replace(elm, replace_document)
        #タグ置換パターン
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        #タグ置換
        @root.document.sub!(@pattern, replace_document)
      end

      private :replace

      def reflect
        #puts @element_cache.size.to_s
        @element_cache.values.each do |item|
          if item.usable
            #puts "#{item.name}:#{item.document}"
            if !item.removed
              if item.copy
                @pattern = Meteor::Core::Util::PatternCache.get(item.pattern)
                @root.document.sub!(@pattern, item.copy.parser.document_hook)
                #item.copy.parser.element_cache.clear
                item.copy = nil
              else
                edit_document_1(item)
                #edit_pattern_(item)
              end
            else
              replace(item, EMPTY)
            end
            item.usable = false
          end
        end
      end

      protected :reflect

      def edit_document_1(elm)
        edit_document_2(elm, TAG_CLOSE3)
      end

      private :edit_document_1

      def edit_document_2(elm, closer)

        #タグ置換
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        @root.document.sub!(@pattern, elm.document)
      end

      private :edit_document_2

      #
      # reflect (反映する)
      #
      def flash

        if self.element_hook
          if self.element_hook.origin.mono
            if self.element_hook.origin.cx
              #@root.hookDocument << SET_CX_1 << @root.element.name << SPACE
              #@root.hookDocument << @root.element.attributes << SET_CX_2
              #@root.hookDocument << @root.element.mixed_content << SET_CX_3
              #@root.hookDocument << @root.element.name << SET_CX_4
              self.document_hook << "<!-- @#{self.element_hook.name} #{self.element_hook.attributes}-->#{self.element_hook.mixed_content}<!-- /@#{self.element_hook.name} -->"

              #self.document_hook << @root.kaigyo_code << "<!-- @#{self.element_hook.name} #{self.element_hook.attributes}-->#{self.element_hook.mixed_content}<!-- /@#{self.element_hook.name} -->"
            else
              #@root.hookDocument << TAG_OPEN << @root.element.name
              #@root.hookDocument << @root.element.attributes << TAG_CLOSE << @root.element.mixed_content
              #@root.hookDocument << TAG_OPEN3 << @root.element.name << TAG_CLOSE
              self.document_hook << "<#{self.element_hook.name}#{self.element_hook.attributes}>#{self.element_hook.mixed_content}</#{self.element_hook.name}>"

              #self.document_hook << @root.kaigyo_code << "<#{self.element_hook.name}#{self.element_hook.attributes}>#{self.element_hook.mixed_content}</#{self.element_hook.name}>"
            end
            self.element_hook = Element.new!(self.element_hook.origin, self)
          else
            reflect
            @_attributes = self.element_hook.attributes

            if self.element_hook.origin.cx
              #@root.hookDocument << SET_CX_1 << @root.element.name << SPACE
              #@root.hookDocument << @_attributes << SET_CX_2
              #@root.hookDocument << @root.document << SET_CX_3
              #@root.hookDocument << @root.element.name << SET_CX_4
              self.document_hook << "<!-- @#{self.element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{self.element_hook.name} -->"

              #self.document_hook << @root.kaigyo_code << "<!-- @#{self.element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{self.element_hook.name} -->"
            else
              #@root.hookDocument << TAG_OPEN << @root.element.name
              #@root.hookDocument << @_attributes << TAG_CLOSE << @root.document
              #@root.hookDocument << TAG_OPEN3 << @root.element.name << TAG_CLOSE
              self.document_hook << "<#{self.element_hook.name}#{@_attributes}>#{@root.document}</#{self.element_hook.name}>"

              #self.document_hook << @root.kaigyo_code << "<#{self.element_hook.name}#{@_attributes}>#{@root.document}</#{self.element_hook.name}>"
            end
            self.element_hook = Element.new!(self.element_hook.origin, self)
          end
        else
          reflect
          @element_cache.clear
          #フック判定がFALSEの場合
          clean
        end
      end

      def clean
        #CX開始タグ置換
        @pattern = @@pattern_clean1
        @root.document.gsub!(@pattern, EMPTY)
        #CX終了タグ置換
        @pattern = @@pattern_clean2
        @root.document.gsub!(@pattern, EMPTY)
        # @root.document << "<!-- Powered by Meteor (C)Yasumasa Ashida -->"
      end

      private :clean

      #
      # mirror element (要素を射影する)
      #
      # @param [Meteor::Element] elm element (要素)
      # @return [Meteor::Element] element (要素)
      #
      def shadow(elm)
        if elm.empty
          #内容あり要素の場合
          set_mono_info(elm)

          pif2 = create(self)

          @elm_ = Element.new!(elm, pif2)

          if !elm.mono
            pif2.root_element.document = String.new(elm.mixed_content)
          else
            pif2.root_element.document = String.new(elm.document)
          end
          pif2.root_element.kaigyo_code = elm.parser.root_element.kaigyo_code

          @elm_
        end
      end

      #private :shadow

      def set_mono_info(elm)

        @res = @@pattern_set_mono1.match(elm.mixed_content)

        if @res
          elm.mono = true
        end
      end

      private :set_mono_info

      def is_match(regex, str)
        if regex.kind_of?(Regexp)
          is_match_r(regex, str)
        elsif regex.kind_of?(Array)
          is_match_a(regex, str)
        elsif regex.kind_of?(String)
          if regex.eql?(str.downcase)
            true
          else
            false
          end
        else
          raise ArgumentError
        end
      end

      private :is_match

      def is_match_r(regex, str)
        if regex.match(str.downcase)
          true
        else
          false
        end
      end

      private :is_match_r

      def is_match_a(regex, str)
        str = str.downcase
        regex.each do |item|
          if item.eql?(str)
            return true
          end
        end
        false
      end

      private :is_match_a

      def is_match_s(regex, str)
        if regex.match(str.downcase)
          true
        else
          false
        end
      end

      private :is_match_s

      def create(pif)
        case pif.doc_type
          when Parser::HTML4
            Meteor::Ml::Html4::ParserImpl.new
          when Parser::XHTML4
            Meteor::Ml::Xhtml4::ParserImpl.new
          when Parser::HTML
            Meteor::Ml::Html::ParserImpl.new
          when Parser::XHTML
            Meteor::Ml::Xhtml::ParserImpl.new
          when Parser::XML
            Meteor::Ml::Xml::ParserImpl.new
          else
            nil
        end
      end

      private :create

    end

    module Util

      #
      # Pattern Cache Class (パターンキャッシュクラス)
      #
      class PatternCache
        @@regex_cache = Hash.new

        ##
        ## intializer (イニシャライザ)
        ##
        #def initialize
        #end


        #
        # get pattern (パターンを取得する)
        # @overload get(regex)
        #  @param [String] regex regular expression (正規表現)
        #  @return [Regexp] pattern (パターン)
        # @overload get(regex,option)
        #  @param [String] regex regular expression (正規表現)
        #  @param [Fixnum] option option of Regex (オプション)
        #  @return [Regexp] pattern (パターン)
        #
        def self.get(*args)
          case args.length
            when ONE
              #get_1(args[0])
              if @@regex_cache[args[0].to_sym]
                @@regex_cache[args[0].to_sym]
              else
                @@regex_cache[args[0].to_sym] = Regexp.new(args[0], Regexp::MULTILINE)
              end
            when TWO
              #get_2(args[0], args[1])
              if @@regex_cache[args[0].to_sym]
                @@regex_cache[args[0].to_sym]
              else
                @@regex_cache[args[0].to_sym] = Regexp.new(args[0], args[1])
              end
            else
              raise ArgumentError
          end
        end

        ##
        ## get pattern (パターンを取得する)
        ## @param [String] regex regular expression (正規表現)
        ## @return [Regexp] pattern (パターン)
        ##
        #def self.get_1(regex)
        #  ##pattern = @@regex_cache[regex]
        #  ##
        #  ##if pattern == nil
        #  #if regex.kind_of?(String)
        #  if !@@regex_cache[regex.to_sym]
        #    #pattern = Regexp.new(regex)
        #    #@@regex_cache[regex] = pattern
        #    @@regex_cache[regex.to_sym] = Regexp.new(regex, Regexp::MULTILINE)
        #  end
        #
        #  #return pattern
        #  @@regex_cache[regex.to_sym]
        #  ##elsif regex.kind_of?(Symbol)
        #  ##  if !@@regex_cache[regex]
        #  ##    @@regex_cache[regex.object_id] = Regexp.new(regex.to_s, Regexp::MULTILINE)
        #  ##  end
        #  ##
        #  ##  @@regex_cache[regex]
        #  #end
        #end

        ##
        ## パターンを取得する
        ## @param [String] regex 正規表現
        ## @param [Fixnum] option オプション
        ## @return [Regexp] パターン
        ##
        #def self.get_2(regex, option)
        #  ##pattern = @@regex_cache[regex]
        #  ##
        #  ##if pattern == nil
        #  #if regex.kind_of?(String)
        #  if !@@regex_cache[regex.to_sym]
        #    #pattern = Regexp.new(regex)
        #    #@@regex_cache[regex] = pattern
        #    @@regex_cache[regex.to_sym] = Regexp.new(regex, option,E_UTF8)
        #  end
        #
        #  #return pattern
        #  @@regex_cache[regex.to_sym]
        #  ##elsif regex.kind_of?(Symbol)
        #  ##  if !@@regex_cache[regex]
        #  ##    @@regex_cache[regex] = Regexp.new(regex.to_s, option,E_UTF8)
        #  ##  end
        #  ##
        #  ##  @@regex_cache[regex]
        #  #end
        #end
      end

    end

  end

  module Ml
    module Html4

      #
      # HTML4 parser (HTMLパーサ)
      #
      class ParserImpl < Meteor::Core::Kernel

        #KAIGYO_CODE = "\r?\n|\r"
        #KAIGYO_CODE = "\r\n|\n|\r"
        KAIGYO_CODE = ["\r\n", "\n", "\r"]
        NBSP_2 = '&nbsp;'
        NBSP_3 = 'nbsp'
        BR_1 = "\r?\n|\r"
        BR_2 = '<br>'

        META = 'META'
        META_S = 'meta'

        #MATCH_TAG = "br|hr|img|input|meta|base"
        @@match_tag = ['br', 'hr', 'img', 'input', 'meta', 'base'] #[Array] 内容のない要素
        #@@match_tag_2 = "textarea|option|pre"
        @@match_tag_2 =['textarea', 'option', 'pre'] #[Array] 改行を<br>に変換する必要のない要素

        @@match_tag_sng = ['texarea', 'select', 'option', 'form', 'fieldset'] #[Array] 入れ子にできない要素

        HTTP_EQUIV = 'http-equiv'
        CONTENT_TYPE = 'Content-Type'
        CONTENT = 'content'

        @@attr_logic = ['disabled', 'readonly', 'checked', 'selected', 'multiple'] #[Array] 論理値で指定する属性
        OPTION = 'option'
        SELECTED = 'selected'
        INPUT = 'input'
        CHECKED = 'checked'
        RADIO = 'radio'
        #DISABLE_ELEMENT = "input|textarea|select|optgroup"
        DISABLE_ELEMENT = ['input', 'textarea', 'select', 'optgroup'] #[Array] disabled属性のある要素
        DISABLED = 'disabled'
        #READONLY_TYPE = "text|password"
        READONLY_TYPE = ['text', 'password'] #[Array] readonly属性のあるinput要素のタイプ
        TEXTAREA = 'textarea'
        READONLY='readonly'
        SELECT = 'select'
        MULTIPLE = 'multiple'

        #@@pattern_option = Regexp.new(OPTION)
        #@@pattern_selected = Regexp.new(SELECTED)
        #@@pattern_input = Regexp.new(INPUT)
        #@@pattern_checked = Regexp.new(CHECKED)
        #@@pattern_radio = Regexp.new(RADIO)
        #@@pattern_disable_element = Regexp.new(DISABLE_ELEMENT)
        #@@pattern_disabled = Regexp.new(DISABLED)
        #@@pattern_readonly_type = Regexp.new(READONLY_TYPE)
        #@@pattern_textarea = Regexp.new(TEXTAREA)
        #@@pattern_readonly = Regexp.new(READONLY)
        #@@pattern_select = Regexp.new(SELECT)
        #@@pattern_multiple = Regexp.new(MULTIPLE)

        SELECTED_M = '\\sselected\\s|\\sselected$|\\sSELECTED\\s|\\sSELECTED$'
        #SELECTED_M = [' selected ',' selected',' SELECTED ',' SELECTED']
        SELECTED_R = 'selected\\s|selected$|SELECTED\\s|SELECTED$'
        CHECKED_M = '\\schecked\\s|\\schecked$|\\sCHECKED\\s|\\sCHECKED$'
        #CHECKED_M = [' checked ',' checked',' CHECKED ',' CHECKED']
        CHECKED_R = 'checked\\s|checked$|CHECKED\\s|CHECKED$'
        DISABLED_M = '\\sdisabled\\s|\\sdisabled$|\\sDISABLED\\s|\\sDISABLED$'
        #DISABLED_M = [' disabled ',' disiabled',' DISABLED ',' DISABLED']
        DISABLED_R = 'disabled\\s|disabled$|DISABLED\\s|DISABLED$'
        READONLY_M = '\\sreadonly\\s|\\sreadonly$|\\sREADONLY\\s|\\sREADONLY$'
        #READONLY_M = [' readonly ',' readonly',' READONLY ',' READONLY']
        READONLY_R = 'readonly\\s|readonly$|READONLY\\s|READONLY$'
        MULTIPLE_M = '\\smultiple\\s|\\smultiple$|\\sMULTIPLE\\s|\\sMULTIPLE$'
        #MULTIPLE_M = [' multiple ',' multiple',' MULTIPLE ',' MULTIPLE']
        MULTIPLE_R = 'multiple\\s|multiple$|MULTIPLE\\s|MULTIPLE$'

        TRUE = 'true'
        FALSE = 'false'

        #@@pattern_true = Regexp.new(TRUE)
        #@@pattern_false = Regexp.new(FALSE)

        TYPE_L = 'type'
        TYPE_U = 'TYPE'

        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt|nbsp);'
        GET_ATTRS_MAP2='\\s(disabled|readonly|checked|selected|multiple)'

        @@pattern_selected_m = Regexp.new(SELECTED_M)
        @@pattern_selected_r = Regexp.new(SELECTED_R)
        @@pattern_checked_m = Regexp.new(CHECKED_M)
        @@pattern_checked_r = Regexp.new(CHECKED_R)
        @@pattern_disabled_m = Regexp.new(DISABLED_M)
        @@pattern_disabled_r = Regexp.new(DISABLED_R)
        @@pattern_readonly_m = Regexp.new(READONLY_M)
        @@pattern_readonly_r = Regexp.new(READONLY_R)
        @@pattern_multiple_m = Regexp.new(MULTIPLE_M)
        @@pattern_multiple_r = Regexp.new(MULTIPLE_R)

        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)
        @@pattern_get_attrs_map2 = Regexp.new(GET_ATTRS_MAP2)

        #@@pattern_@@match_tag = Regexp.new(@@match_tag)
        #@@pattern_@@match_tag2 = Regexp.new(@@match_tag_2)

        TABLE_FOR_ESCAPE_ = {
            '&' => '&amp;',
            '"' => '&quot;',
            '\'' => '&apos;',
            '<' => '&lt;',
            '>' => '&gt;',
            ' ' => '&nbsp;',
        }

        TABLE_FOR_ESCAPE_CONTENT_ = {
            '&' => '&amp;',
            '"' => '&quot;',
            '\'' => '&apos;',
            '<' => '&lt;',
            '>' => '&gt;',
            ' ' => '&nbsp;',
            "\r\n" => '<br>',
            "\r" => '<br>',
            "\n" => '<br>',
        }

        PATTERN_ESCAPE = "[&\"'<> ]"
        PATTERN_ESCAPE_CONTENT = "[&\"'<> \\n]"

        @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
        @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)
        @@pattern_br_2 = Regexp.new(BR_2)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @doc_type = Parser::HTML4
          case args.length
            when ZERO
              #initialize_0
            when ONE
              initialize_1(args[0])
            else
              raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        #def initialize_0
        #end
        #
        #private :initialize_0

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps paser (パーサ)
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.kaigyo_code = ps.root_element.kaigyo_code
        end

        private :initialize_1

        #
        # parse document (ドキュメントを解析する)
        #
        def parse
          analyze_ml
        end

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml
          #content-typeの取得
          analyze_content_type
          #改行コードの取得
          analyze_kaigyo_code

          @res = nil
        end

        private :analyze_ml

        #
        # get content type (コンテントタイプを取得する)
        # @return [String] conent type (コンテントタイプ)
        #
        def content_type
          @root.content_type
        end

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @error_check = false

          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          @error_check = true

          if @elm_
            @root.content_type = @elm_.attr(CONTENT)
          else
            @root.content_type = EMPTY
          end
        end

        private :analyze_content_type

        #
        # analuze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_kaigyo_code
          #改行コード取得

          for a in KAIGYO_CODE
            if @root.document.include?(a)
              @root.kaigyo_code = a
              #puts "kaigyo:" << @root.kaigyo_code
            end
          end

        end

        private :analyze_kaigyo_code

        #
        # get element using tag name (要素のタグ名で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @return [Meteor::Element] element (要素)
        #
        def element_1(name)
          @_name = Regexp.quote(name)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(@@match_tag, name)
            #空要素検索用パターン
            @pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_1_4_2
            #@pattern_cc = "<#{@_name}(|\\s[^<>]*)>"
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            @res = @pattern.match(@root.document)
            if @res
              element_without_1(name)
            else
              if @error_check
                puts Meteor::Exception::NoSuchElementException.new(name).message
              end
              @elm_ = nil
            end
          else
            #内容あり要素検索用パターン
            #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_1_1 << @_name
            #@pattern_cc << TAG_SEARCH_1_2 << @_name << TAG_CLOSE
            @pattern_cc = "<#{@_name}(|\\s[^<>]*)>(((?!(#{tag}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)
            #内容あり要素の場合
            if @res
              element_with_1(name)
            else
              if @error_check
                puts Meteor::Exception::NoSuchElementException.new(name).message
              end
              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_1

        def element_without_1(name)
          @elm_ = Meteor::Element.new(name)
          #属性
          @elm_.attributes = @res[1]
          #空要素検索用パターン
          @elm_.pattern = @pattern_cc

          @elm_.document = @res[0]

          @elm_.parser = self
        end

        private :element_without_1

        #
        # get element using tag name and attribute(name="value") (要素のタグ名、属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @return [Meteor::Element] element (要素)
        #
        def element_3(name, attr_name, attr_value)

          element_quote_3(name, attr_name, attr_value)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(@@match_tag, name)
            #空要素検索パターン
            #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_2_4_3
            @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)
            if @res
              element_without_3(name)
            else
              if @error_check
                puts Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message
              end
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_2_2 << @_name
            #@pattern_cc << TAG_SEARCH_1_2 << @_name << TAG_CLOSE
            @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)

            if !@res && !is_match(@@match_tag_sng, name)
              @res = element_with_3_2
            end

            if @res
              element_with_3_1(name)
            else
              if @error_check
                puts Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message
              end
              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_3

        def element_without_3(name)
          element_without_3_1(name, TAG_SEARCH_2_4_3)
        end

        private :element_without_3

        #
        # get element using attribute(name="value") (属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @return [Meteor::Element] element (要素)
        #
        def element_2(attr_name, attr_value)

          element_quote_2(attr_name, attr_value)

          #@pattern_cc = String.new('') << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value
          #@pattern_cc << TAG_SEARCH_2_4_4
          @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
          @res = @pattern.match(@root.document)

          if @res
            element_3(@res[1], attr_name, attr_value)
          else
            if @error_check
              puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
            end
            @elm_ = nil
          end

          @elm_
        end

        private :element_2

        #
        # get element using tag name and attribute1,2(name="value") (要素のタグ名と属性1・属性2(属性名="属性値")で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @param [String] attr_name1 attribute name1 (属性名1)
        # @param [String] attr_value1 attribute value1 (属性値1)
        # @param [String] attr_name2 attribute name2 (属性名2)
        # @param [String] attr_value2 attribute value2 (属性値2)
        # @return [Meteor::Element] element (要素)
        #
        def element_5(name, attr_name1, attr_value1, attr_name2, attr_value2)

          element_quote_5(name, attr_name1, attr_value1, attr_name2, attr_value2)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(@@match_tag, name)
            #空要素検索パターン
            #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_4_3_2
            @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)

            if @res
              element_without_5(name)
            else
              if @error_check
                puts Meteor::Exception::NoSuchElementException.new(name, attr_name1, attr_value1, attr_name2, attr_value2).message
              end
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            #@pattern_cc = String.new('') << TAG_OPEN << @_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_2_2 << @_name
            #@pattern_cc << TAG_SEARCH_1_2 << @_name << TAG_CLOSE
            @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)

            if !@res && !is_match(@@match_tag_sng, tag)
              @res = element_with_5_2
            end

            if @res
              element_with_5_1(name)
            else
              if @error_check
                puts Meteor::Exception::NoSuchElementException.new(name, attr_name1, attr_value1, attr_name2, attr_value2).message
              end
              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_5

        def element_without_5(name)
          element_without_5_1(name, TAG_SEARCH_2_4_3_2)
        end

        private :element_without_5

        #
        # get element using attribute1,2(name="value") (属性1・属性2(属性名="属性値")で検索し、要素を取得する)
        #
        # @param [String] attr_name1 attribute name1 (属性名1)
        # @param [String] attr_value1 attribute value1 (属性値1)
        # @param [String] attr_name2 attribute name2 (属性名2)
        # @param [String] attr_value2 attribute value2 (属性値2)
        # @return [Meteor::Element] element (要素)
        #
        def element_4(attr_name1, attr_value1, attr_name2, attr_value2)

          element_quote_4(attr_name1, attr_value1, attr_name2, attr_value2)

          #@pattern_cc = String.new('') << TAG_SEARCH_3_1_2_2 << @_attr_name1 << ATTR_EQ << @_attr_value1
          #@pattern_cc << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ << @_attr_value2
          #@pattern_cc << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ << @_attr_value2
          #@pattern_cc << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ << @_attr_value1
          #@pattern_cc << TAG_SEARCH_2_4_3_2
          @pattern_cc = "<([^<>\"]*)\\s([^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

          @res = @pattern.match(@root.document)

          if @res
            element_5(@res[1], attr_name1, attr_value1, attr_name2, attr_value2)
          else
            if @error_check
              puts Meteor::Exception::NoSuchElementException.new(attr_name1, attr_value1, attr_name2, attr_value2).message
            end
            @elm_ = nil
          end

          @elm_
        end

        private :element_4

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_selected_m, @@pattern_selected_r)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_multiple_m, @@pattern_multiple_r)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_disabled_m, @@pattern_disabled_r)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_checked_m, @@pattern_checked_r)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_readonly_m, @@pattern_readonly_r)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def edit_attrs_5(elm, attr_name, attr_value, match_p, replace)

          if true.equal?(attr_value) || is_match(TRUE, attr_value)
            @res = match_p.match(elm.attributes)

            if !@res
              if !EMPTY.eql?(elm.attributes) && !EMPTY.eql?(elm.attributes.strip)
                elm.attributes = String.new('') << SPACE << elm.attributes.strip
              else
                elm.attributes = String.new('')
              end
              elm.attributes << SPACE << attr_name
              #else
            end
          elsif false.equal?(attr_value) || is_match(FALSE, attr_value)
            elm.attributes.sub!(replace, EMPTY)
          end

        end

        private :edit_attrs_5

        def edit_document_1(elm)
          edit_document_2(elm, TAG_CLOSE)
        end

        private :edit_document_1

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            get_attr_value_r(elm, @@pattern_selected_m)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, @@pattern_multiple_m)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, @@pattern_disabled_m)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            get_attr_value_r(elm, @@pattern_checked_m)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, @@pattern_readonly_m)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attr_value_(elm, TYPE_L)
            if !elm.type_value
              elm.type_value = get_attr_value_(elm, TYPE_U)
            end
          end
          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, match_p)

          @res = match_p.match(elm.attributes)

          if @res
            TRUE
          else
            FALSE
          end
        end

        private :get_attr_value_r

        #
        # get attribute map (属性マップを取得する)
        # @param [Meteor::Element] elm element (要素)
        # @return [Hash] attribute map (属性マップ)
        #
        def get_attrs(elm)
          attrs = Hash.new

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(@@pattern_get_attrs_map2) do |a|
            attrs.store(a[0], TRUE)
          end

          attrs
        end

        private :get_attrs

        #
        # get attribute map of element (要素の属性マップを取得する)
        # @param [Meteor::Element] elm element (要素)
        # @return [Meteor::AttributeMap] attribute map (属性マップ)
        #
        def get_attr_map(elm)
          attrs = Meteor::AttributeMap.new

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(@@pattern_get_attrs_map2) do |a|
            attrs.store(a[0], TRUE)
          end

          attrs.recordable = true

          attrs
        end

        private :get_attr_map

        def remove_attrs_(elm, attr_name)
          #検索対象属性の論理型是非判定
          if !is_match(@@attr_logic, attr_name)
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << ERASE_ATTR_1)
            #@pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"\\s?")
            elm.attributes.sub!(@pattern, EMPTY)
          else
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get(attr_name)
            elm.attributes.sub!(@pattern, EMPTY)
          end
        end

        private :remove_attrs_

        def escape(content)
          # 特殊文字の置換
          content = content.gsub(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end

        def escape_content(content, elm)
          # 特殊文字の置換
          content = content.gsub(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)

          content
        end

        private :escape
        private :escape_content

        def unescape(content)
          #特殊文字の置換
          #「<」<-「&lt;」
          #「>」<-「&gt;」
          #「"」<-「&quotl」
          #「 」<-「&nbsp;」
          #「&」<-「&amp;」
          content.gsub(@@pattern_unescape) do
            case $1
              when AND_3
                AND_1
              when QO_3
                DOUBLE_QUATATION
              when AP_3
                AP_1
              when GT_3
                GT_1
              when LT_3
                LT_1
              when NBSP_3
                SPACE
            end
          end

          content
        end

        private :unescape

        def unescape_content(content, elm)
          content_ = unescape(content)

          if elm.cx || !is_match(@@match_tag_2, elm.name)
            if content.include?(BR_2)
              #「<br>」->「¥r?¥n」
              content_.gsub!(@@pattern_br_2, @root.kaigyo_code)
            end
          end

          content_
        end

        private :unescape_content

      end

    end

    module Xhtml4

      #
      # XHTML4 parser (XHTML4パーサ)
      #
      class ParserImpl < Meteor::Core::Kernel

        #KAIGYO_CODE = "\r?\n|\r"
        KAIGYO_CODE = ["\r\n", "\n", "\r"]
        NBSP_2 = '&nbsp;'
        NBSP_3 = 'nbsp'
        BR_1 = "\r?\n|\r"
        BR_2 = '<br/>'
        BR_3 = '<br\\/>'

        META = 'META'
        META_S = 'meta'

        #@@match_tag_2 = "textarea|option|pre"
        @@match_tag_2 = ['textarea', 'option', 'pre'] #[Array] 改行を<br/>に変換する必要のない要素

        @@attr_logic = ['disabled', 'readonly', 'checked', 'selected', 'multiple'] #[Array] 論理値で指定する属性
        OPTION = 'option'
        SELECTED = 'selected'
        INPUT = 'input'
        CHECKED = 'checked'
        RADIO = 'radio'
        #DISABLE_ELEMENT = "input|textarea|select|optgroup"
        DISABLE_ELEMENT = ['input', 'textarea', 'select', 'optgroup'] #[Array] disabled属性のある要素
        DISABLED = 'disabled'
        #READONLY_TYPE = "text|password"
        READONLY_TYPE = ['text', 'password'] #[Array] readonly属性のあるinput要素のタイプ
        TEXTAREA = 'textarea'
        READONLY='readonly'
        SELECT = 'select'
        MULTIPLE = 'multiple'

        #@@pattern_option = Regexp.new(OPTION)
        #@@pattern_selected = Regexp.new(SELECTED)
        #@@pattern_input = Regexp.new(INPUT)
        #@@pattern_checked = Regexp.new(CHECKED)
        #@@pattern_radio = Regexp.new(RADIO)
        #@@pattern_disable_element = Regexp.new(DISABLE_ELEMENT)
        #@@pattern_disabled = Regexp.new(DISABLED)
        #@@pattern_readonly_type = Regexp.new(READONLY_TYPE)
        #@@pattern_textarea = Regexp.new(TEXTAREA)
        #@@pattern_readonly = Regexp.new(READONLY)
        #@@pattern_select = Regexp.new(SELECT)
        #@@pattern_multiple = Regexp.new(MULTIPLE)

        SELECTED_M = '\\sselected="[^"]*"\\s|\\sselected="[^"]*"$'
        SELECTED_M1 = '\\sselected="([^"]*)"\\s|\\sselected="([^"]*)"$'
        SELECTED_R = 'selected="[^"]*"'
        SELECTED_U = 'selected="selected"'
        CHECKED_M = '\\schecked="[^"]*"\\s|\\schecked="[^"]*"$'
        CHECKED_M1 = '\\schecked="([^"]*)"\\s|\\schecked="([^"]*)"$'
        CHECKED_R = 'checked="[^"]*"'
        CHECKED_U = 'checked="checked"'
        DISABLED_M = '\\sdisabled="[^"]*"\\s|\\sdisabled="[^"]*"$'
        DISABLED_M1 = '\\sdisabled="([^"]*)"\\s|\\sdisabled="([^"]*)"$'
        DISABLED_R = 'disabled="[^"]*"'
        DISABLED_U = 'disabled="disabled"'
        READONLY_M = '\\sreadonly="[^"]*"\\s|\\sreadonly="[^"]*"$'
        READONLY_M1 = '\\sreadonly="([^"]*)"\\s|\\sreadonly="([^"]*)"$'
        READONLY_R = 'readonly="[^"]*"'
        READONLY_U = 'readonly="readonly"'
        MULTIPLE_M = '\\smultiple="[^"]*"\\s|\\smultiple="[^"]*"$'
        MULTIPLE_M1 = '\\smultiple="([^"]*)"\\s|\\smultiple="([^"]*)"$'
        MULTIPLE_R = 'multiple="[^"]*"'
        MULTIPLE_U = 'multiple="multiple"'

        HTTP_EQUIV = 'http-equiv'
        CONTENT_TYPE = 'Content-Type'
        CONTENT = 'content'

        TRUE = 'true'
        FALSE = 'false'

        TYPE_L = 'type'
        TYPE_U = 'TYPE'

        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt|nbsp);'

        @@pattern_selected_m = Regexp.new(SELECTED_M)
        @@pattern_selected_m1 = Regexp.new(SELECTED_M1)
        @@pattern_selected_r = Regexp.new(SELECTED_R)
        @@pattern_checked_m = Regexp.new(CHECKED_M)
        @@pattern_checked_m1 = Regexp.new(CHECKED_M1)
        @@pattern_checked_r = Regexp.new(CHECKED_R)
        @@pattern_disabled_m = Regexp.new(DISABLED_M)
        @@pattern_disabled_m1 = Regexp.new(DISABLED_M1)
        @@pattern_disabled_r = Regexp.new(DISABLED_R)
        @@pattern_readonly_m = Regexp.new(READONLY_M)
        @@pattern_readonly_m1 = Regexp.new(READONLY_M1)
        @@pattern_readonly_r = Regexp.new(READONLY_R)
        @@pattern_multiple_m = Regexp.new(MULTIPLE_M)
        @@pattern_multiple_m1 = Regexp.new(MULTIPLE_M1)
        @@pattern_multiple_r = Regexp.new(MULTIPLE_R)

        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)

        @@pattern_br_2 = Regexp.new(BR_3)

        #@@pattern_@@match_tag = Regexp.new(@@match_tag)
        #@@pattern_@@match_tag2 = Regexp.new(@@match_tag_2)

        TABLE_FOR_ESCAPE_ = {
            '&' => '&amp;',
            '"' => '&quot;',
            '\'' => '&apos;',
            '<' => '&lt;',
            '>' => '&gt;',
            ' ' => '&nbsp;',
        }

        TABLE_FOR_ESCAPE_CONTENT_ = {
            '&' => '&amp;',
            '"' => '&quot;',
            '\'' => '&apos;',
            '<' => '&lt;',
            '>' => '&gt;',
            ' ' => '&nbsp;',
            "\r\n" => '<br/>',
            "\r" => '<br/>',
            "\n" => '<br/>',
        }

        PATTERN_ESCAPE = '[&"\'<> ]'
        PATTERN_ESCAPE_CONTENT = '[&"\'<> \\n]'
        @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
        @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @doc_type = Parser::XHTML4
          case args.length
            when ZERO
              #initialize_0
            when ONE
              initialize_1(args[0])
            else
              raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        #def initialize_0
        #end
        #
        #private :initialize_0

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.kaigyo_code = ps.root_element.kaigyo_code
        end

        private :initialize_1

        #
        # parse document (ドキュメントを解析する)
        #
        def parse
          analyze_ml
        end

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml
          #content-typeの取得
          analyze_content_type
          #改行コードの取得
          analyze_kaigyo_code
          @res = nil
        end

        private :analyze_ml

        #
        # get content type (コンテントタイプを取得する)
        # @return [String] content type (コンテントタイプ)
        #
        def content_type
          @root.content_type
        end

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @error_check = false

          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          @error_check = true

          if @elm_
            @root.content_type = @elm_.attr(CONTENT)
          else
            @root.content_type = EMPTY
          end
        end

        private :analyze_content_type

        #
        # analyze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_kaigyo_code
          #改行コード取得

          for a in KAIGYO_CODE
            if @root.document.include?(a)
              @root.kaigyo_code = a
            end
          end
        end

        private :analyze_kaigyo_code

        def edit_attrs_(elm, attr_name, attr_value)

          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_selected_m, @@pattern_selected_r, SELECTED_U)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_multiple_m, @@pattern_multiple_r, MULTIPLE_U)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_disabled_m, @@pattern_disabled_r, DISABLED_U)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            edit_attrs_5(elm, attr_value, @@pattern_checked_m, @@pattern_checked_r, CHECKED_U)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_5(elm, attr_value, @@pattern_readonly_m, @@pattern_readonly_r, READONLY_U)
          else
            super(elm, attr_name, attr_value)
          end

        end

        private :edit_attrs_

        def edit_attrs_5(elm, attr_value, match_p, replace_regex, replace_update)

          #attr_value = escape(attr_value)

          if true.equal?(attr_value) || is_match(TRUE, attr_value)

            @res = match_p.match(elm.attributes)

            if !@res
              #属性文字列の最後に新規の属性を追加する
              if elm.attributes != EMPTY
                elm.attributes = String.new('') << SPACE << elm.attributes.strip
                #else
              end
              elm.attributes << SPACE << replace_update
            else
              #属性の置換
              elm.attributes.gsub!(replace_regex, replace_update)
            end
          elsif false.equal?(attr_value) || is_match(FALSE, attr_value)
            #attr_name属性が存在するなら削除
            #属性の置換
            elm.attributes.gsub!(replace_regex, EMPTY)
          end

        end

        private :edit_attrs_5

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_selected_m1)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_multiple_m1)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_disabled_m1)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            get_attr_value_r(elm, attr_name, @@pattern_checked_m1)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, attr_name, @@pattern_readonly_m1)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attr_value(elm, TYPE_L)
            if !elm.type_value
              elm.type_value = get_attr_value(elm, TYPE_U)
            end
          end
          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, attr_name, match_p)

          @res = match_p.match(elm.attributes)

          if @res
            if @res[1]
              if attr_name == @res[1]
                TRUE
              else
                @res[1]
              end
            elsif @res[2]
              if attr_name == @res[2]
                TRUE
              else
                @res[2]
              end
            elsif @res[3]
              if attr_name == @res[3]
                TRUE
              else
                @res[3]
              end
            elsif @res[4]
              if attr_name == @res[4]
                TRUE
              else
                @res[4]
              end
            end
          else
            FALSE
          end
        end

        private :get_attr_value_r

        #
        # get attribute map (属性マップを取得する)
        # @param [Meteor::Element] elm element (要素)
        # @return [Meteor::AttributeMap] attribute map (属性マップ)
        #
        def get_attr_map(elm)
          attrs = Meteor::AttributeMap.new

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            if is_match(@@attr_logic, a) && a==b
              attrs.store(a, TRUE)
            else
              attrs.store(a, unescape(b))
            end
          end
          attrs.recordable = true

          attrs
        end

        private :get_attr_map

        def escape(content)
          # 特殊文字の置換
          content = content.gsub(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end

        def escape_content(content, elm)
          # 特殊文字の置換
          content = content.gsub(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)

          content
        end

        private :escape
        private :escape_content

        def unescape(content)
          # 特殊文字の置換
          #「<」<-「&lt;」
          #「>」<-「&gt;」
          #「"」<-「&quotl」
          #「 」<-「&nbsp;」
          #「&」<-「&amp;」
          content.gsub(@@pattern_unescape) do
            case $1
              when AND_3
                AND_1
              when QO_3
                DOUBLE_QUATATION
              when AP_3
                AP_1
              when GT_3
                GT_1
              when LT_3
                LT_1
              when NBSP_3
                SPACE
            end
          end

          content
        end

        private :unescape

        def unescape_content(content, elm)
          content_ = unescape(content)

          if (elm.cx || !is_match(@@match_tag_2, elm.name)) && content.include?(BR_2)
              #「<br>」->「¥r?¥n」
              content_.gsub!(@@pattern_br_2, @root.kaigyo_code)
          end

          content_
        end

        private :unescape_content

      end

    end

    module Html

      #
      # HTML parser (HTMLパーサ)
      #
      class ParserImpl < Meteor::Ml::Html4::ParserImpl

        CHARSET = 'charset'
        UTF8 = 'utf-8'

        MATCH_TAG = ['br', 'hr', 'img', 'input', 'meta', 'base', 'embed', 'command', 'keygen'] #[Array] 内容のない要素

        MATCH_TAG_SNG = ['texarea', 'select', 'option', 'form', 'fieldset', 'figure', 'figcaption', 'video', 'audio', 'progress', 'meter', 'time', 'ruby', 'rt', 'rp', 'datalist', 'output'] #[Array] 入れ子にできない要素

        ATTR_LOGIC = ['disabled', 'readonly', 'checked', 'selected', 'multiple', 'required'] #[Array] 論理値で指定する属性

        DISABLE_ELEMENT = ['input', 'textarea', 'select', 'optgroup', 'fieldset'] #[Array] disabled属性のある要素

        REQUIRE_ELEMENT = ['input', 'textarea'] #[Array] required属性のある要素
        REQUIRED = 'required'

        REQUIRED_M = '\\srequired\\s|\\srequired$|\\sREQUIRED\\s|\\sREQUIRED$'
        #REQUIRED_M = [' required ',' required',' REQUIRED ',' REQUIRED']
        REQUIRED_R = 'required\\s|required$|REQUIRED\\s|REQUIRED$'

        @@pattern_required_m = Regexp.new(REQUIRED_M)
        @@pattern_required_r = Regexp.new(REQUIRED_R)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps paser (パーサ)
        #
        def initialize(*args)
          super()
          @@match_tag = MATCH_TAG
          @@match_tag_sng = MATCH_TAG_SNG
          @@attr_logic = ATTR_LOGIC
          @doc_type = Parser::HTML
          case args.length
            when ZERO
              #initialize_0
            when ONE
              initialize_1(args[0])
            else
              raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        #def initialize_0
        #end
        #
        #private :initialize_0

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.charset = ps.root_element.charset
          @root.kaigyo_code = ps.root_element.kaigyo_code
        end

        private :initialize_1

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @error_check = false

          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          @error_check = true

          if @elm_
            @root.content_type = @elm_.attr(CONTENT)
            @root.charset = @elm_.attr(CHARSET)
            if !@root.charset
              @root.charset = UTF8
            end
          else
            @root.content_type = EMPTY
            @root.charset = UTF8
          end
        end

        private :analyze_content_type

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_selected_m, @@pattern_selected_r)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_multiple_m, @@pattern_multiple_r)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_disabled_m, @@pattern_disabled_r)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_checked_m, @@pattern_checked_r)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_readonly_m, @@pattern_readonly_r)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_required_m, @@pattern_required_r)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            get_attr_value_r(elm, @@pattern_selected_m)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, @@pattern_multiple_m)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, @@pattern_disabled_m)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            get_attr_value_r(elm, @@pattern_checked_m)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, @@pattern_readonly_m)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            get_attr_value_r(elm, @@pattern_required_m)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

      end

    end

    module Xhtml

      #
      # XHTML parser (XHTMLパーサ)
      #
      class ParserImpl < Meteor::Ml::Xhtml4::ParserImpl

        CHARSET = 'charset'
        UTF8 = 'utf-8'

        ATTR_LOGIC = ['disabled', 'readonly', 'checked', 'selected', 'multiple', 'required'] #[Array] 論理値で指定する属性

        DISABLE_ELEMENT = ['input', 'textarea', 'select', 'optgroup', 'fieldset'] #[Array] disabled属性のある要素

        REQUIRE_ELEMENT = ['input', 'textarea'] #[Array] required属性のある要素
        REQUIRED = 'required'

        REQUIRED_M = '\\srequired="[^"]*"\\s|\\srequired="[^"]*"$'
        REQUIRED_M1 = '\\srequired="([^"]*)"\\s|\\srequired="([^"]*)"$'
        REQUIRED_R = 'required="[^"]*"'
        REQUIRED_U = 'required="required"'

        @@pattern_required_m = Regexp.new(REQUIRED_M)
        @@pattern_required_m1 = Regexp.new(REQUIRED_M1)
        @@pattern_required_r = Regexp.new(REQUIRED_R)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @@attr_logic = ATTR_LOGIC
          @doc_type = Parser::XHTML
          case args.length
            when ZERO
              #initialize_0
            when ONE
              initialize_1(args[0])
            else
              raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        #def initialize_0
        #end
        #
        #private :initialize_0

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.charset = ps.root_element.charset
          @root.kaigyo_code = ps.root_element.kaigyo_code
        end

        private :initialize_1

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @error_check = false

          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          @error_check = true

          if @elm_
            @root.content_type = @elm_.attr(CONTENT)
            @root.charset = @elm_.attr(CHARSET)
            if !@root.charset
              @root.charset = UTF8
            end
          else
            @root.content_type = EMPTY
            @root.charset = UTF8
          end
        end

        private :analyze_content_type

        def edit_attrs_(elm, attr_name, attr_value)

          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_selected_m, @@pattern_selected_r, SELECTED_U)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_multiple_m, @@pattern_multiple_r, MULTIPLE_U)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_disabled_m, @@pattern_disabled_r, DISABLED_U)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            edit_attrs_5(elm, attr_value, @@pattern_checked_m, @@pattern_checked_r, CHECKED_U)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_5(elm, attr_value, @@pattern_readonly_m, @@pattern_readonly_r, READONLY_U)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_required_m, @@pattern_required_r, REQUIRED_U)
          else
            super(elm, attr_name, attr_value)
          end

        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_selected_m1)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_multiple_m1)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_disabled_m1)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm))
            get_attr_value_r(elm, attr_name, @@pattern_checked_m1)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, attr_name, @@pattern_readonly_m1)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_required_m1)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

      end

    end

    module Xml

      #
      # XML parser (XMLパーサ)
      #
      class ParserImpl < Meteor::Core::Kernel

        #KAIGYO_CODE = "\r?\n|\r"
        KAIGYO_CODE = ["\r\n", "\n", "\r"]

        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt);'

        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)

        TABLE_FOR_ESCAPE_ = {
            '&' => '&amp;',
            '"' => '&quot;',
            '\'' => '&apos;',
            '<' => '&lt;',
            '>' => '&gt;',
        }
        PATTERN_ESCAPE = '[&\"\'<>]'
        @@pattern_escape = Regexp.new(PATTERN_ESCAPE)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @doc_type = Parser::XML
          case args.length
            when ZERO
              #initialize_0
            when ONE
              initialize_1(args[0])
            else
              raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        #def initialize_0
        #end
        #
        #private :initialize_0
        #
        #private :initialize_0

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          ps.document_hook = String.new(ps.document_hook)
        end

        private :initialize_1


        #
        # parse document (ドキュメントを解析する)
        #
        def parse
          analyze_ml
        end

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml
          #改行コードの取得
          analyze_kaigyo_code

          @res = nil
        end

        private :analyze_ml

        #
        # get content type (コンテントタイプを取得する)
        # @return [String] conent type (コンテントタイプ)
        #
        def content_type
          @root.content_type
        end

        #
        # analuze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_kaigyo_code
          #改行コード取得

          for a in KAIGYO_CODE
            if @root.document.include?(a)
              @root.kaigyo_code = a
              #puts "kaigyo:" << @root.kaigyo_code
            end
          end

        end

        private :analyze_kaigyo_code

        def escape(content)
          # 特殊文字の置換
          content = content.gsub(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end

        private :escape

        def escape_content(*args)
          escape(args[0])
        end

        private :escape_content

        def unescape(content)
          # 特殊文字の置換
          #「<」<-「&lt;」
          #「>」<-「&gt;」
          #「"」<-「&quot;」
          #「'」<-「&apos;」
          #「&」<-「&amp;」
          content.gsub(@@pattern_unescape) do
            case $1
              when AND_3
                AND_1
              when QO_3
                DOUBLE_QUATATION
              when AP_3
                AP_1
              when GT_3
                GT_1
              when LT_3
                LT_1
            end
          end

          content
        end

        private :unescape

        def unescape_content(*args)
          unescape(args[0])
        end

        private :unescape_content

      end

    end
  end

end
