# -* coding: UTF-8 -*-
# Meteor -  A lightweight (X)HTML(5) & XML parser
#
# Copyright (C) 2008-2013 Yasumasa Ashida.
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
# @version 0.9.7.6
#

module Meteor

  VERSION = '0.9.7.6'

  RUBY_VERSION_1_9_0 = '1.9.0'

  if RUBY_VERSION < RUBY_VERSION_1_9_0 then
    require 'Kconv'
    #E_UTF8 = 'UTF8'
    $KCODE = 'UTF8'
  end

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
  HTML5 = TWO
  XHTML5 = THREE
  XML = FOUR

  #
  # Element Class (要素クラス)
  #
  class Element

    attr_accessor :name #[String] tag name (要素名)
    attr_accessor :attributes #[String] attributes (属性群)
    attr_accessor :mixed_content #[String] content (内容)
    attr_accessor :pattern #[String] pattern (パターン)
    attr_accessor :document_sync #[true,false] document update flag (ドキュメント更新フラグ)
    attr_accessor :empty #[true,false] content empty flag (内容存在フラグ)
    attr_accessor :cx #[true,false] comment extension tag flag (コメント拡張タグフラグ)
    attr_accessor :mono #[true,false] child element existance flag (子要素存在フラグ)
    attr_accessor :parser #[Meteor::Parser] parser(パーサ)
    attr_accessor :type_value #[String] タイプ属性
    attr_accessor :usable #[true,false] usable flag (有効・無効フラグ)
    attr_accessor :origin #[Meteor::Element] original pointer (原本ポインタ)
    attr_accessor :copy #[Meteor::Element] copy pointer (複製ポインタ)
    attr_accessor :removed #[true,false] delete flag (削除フラグ)

    #
    # initializer (イニシャライザ)
    # @overload initialize(tag)
    #  @param [String] tag tag name (タグ名)
    # @overload initialize(elm)
    #  @param [Meteor::Element] elm element (要素)
    # @overload initialize(elm,ps)
    #  @param [Meteor::Element] elm element (要素)
    #  @param [Meteor::Parser] ps parser (パーサ)
    #
    def initialize(*args)
      case args.length
        when ONE
          if args[0].kind_of?(String) then
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
    # @param [String] tag tag name (タグ名)
    #
    def initialize_s(tag)
      @name = tag
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
          if @obj then
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
      if obj then
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
      if @document_sync then
        @document_sync = false
        case @parser.doc_type
          when Parser::HTML, Parser::HTML5 then
            if @cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = '' << Meteor::Core::Kernel::TAG_OPEN << @name << @attributes << Meteor::Core::Kernel::TAG_CLOSE
                #@document = "<#{@name}#{@attributes}>"
              end
            end
          when Parser::XHTML, Parser::XHTML5, Parser::XML then
            if @cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = '' << Meteor::Core::Kernel::TAG_OPEN << @name << @attributes << Meteor::Core::Kernel::TAG_CLOSE3
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
    #  @return [Meteor::Element,NilClass] element (要素)
    # @overload element(tag)
    #  get element using tag name (要素のタグ名で要素を取得する)
    #  @param [String] tag tag name (タグ名)
    #  @return [Meteor::Element] 要素
    # @overload element(tag,attrs)
    #  get element using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String] tag tag name (タグ名)
    #  @param [Hash] attrs attribute map (属性マップ)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attrs)
    #  get element using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [Hash] attrs attribute map (属性マップ)
    #  @return [Meteor::Element] 要素
    # @overload element(tag,attr_name,attr_value)
    #  get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
    #  @param [String] tag  tag name (タグ名)
    #  @param [String] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attr_name,attr_value)
    #  get element using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
    #  @param [String] attr_name 属性名
    #  @param [String] attr_value 属性値
    #  @return [Meteor::Element] 要素
    # @overload element(tag,attr_name1,attr_value1,attr_name2,attr_value2)
    #  get element using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String] tag  tag name (タグ名)
    #  @param [String] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attr_name1,attr_value1,attr_name2,attr_value2)
    #  get element using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String] attr_name1 属性名1
    #  @param [String] attr_value1 属性値1
    #  @param [String] attr_name2 属性名2
    #  @param [String] attr_value2 属性値2
    #  @return [Meteor::Element] 要素
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
    # get child element using selector like css3(CSS3のようにセレクタを用いて子要素を取得する)
    # CSS3 selector partial support (CSS3セレクタの部分的サポート)
    # @param selector [String] selector (セレクタ)
    # @return [Meteor::Element] element (要素)
    #
    def find(selector)
      @parser.find(selector)
    end

    alias :css :find

    #
    # get cx(comment extension) tag (CX(コメント拡張)タグを取得する)
    # @overload cxtag(tag,id)
    #  要素のタグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する
    #  @param [String] tag タグ名
    #  @param [String] id ID属性値
    #  @return [Meteor::Element] 要素
    # @overload cxtag(id)
    #  ID属性(id="ID属性値")でCX(コメント拡張)タグを取得する
    #  @param [String] id ID属性値
    #  @return [Meteor::Element] 要素
    #
    def cxtag(*args)
      @parser.cxtag(*args)
    end

    #
    # @overload attr(attr)
    #  set attribute of element (要素の属性をセットする)
    #  @param [Hash] attr attribute (属性)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload attr(attr_name,attr_value)
    #  set attribute of element (要素の属性をセットする)
    #  @param [String] attr_name attribute name (属性名)
    #  @param [String,true,false] attr_value attribute value (属性値)
    #  @return [Meteor::Element] element (要素)
    # @overload attr(attr_name)
    #  get attribute value of element (要素の属性値を取得する)
    #  @param [String] attr_name attribute name (属性名)
    #  @return [String] attribute value (属性値)
    #
    def attr(attrs,*args)
      @parser.attr(self, attrs,*args)
    end

    #
    # set attribute of element (要素の属性をセットする)
    # @param [Hash] attr attribute (属性)
    # @return [Meteor::Element] element (要素)
    #
    def attr=(attr)
      @parser.attr(self,attr)
    end

    #
    # set attribute map (要素マップをセットする)
    # @params [Hash] attr_map attributes (属性マップ)
    # @return [Meteor::Element] element (要素)
    def attrs=(attrs)
      @parser.attrs(self,attrs)
    end

    #
    # get attribute map (属性マップを取得する)
    # @return [Hash] attribute map (属性マップ)
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
    # @overload content(content)
    #  set content of element (要素の内容をセットする)
    #  @param [String] content content of element (要素の内容)
    #  @return [Meteor::Element] element (要素)
    # @overload content()
    #  get content of element (要素の内容を取得する)
    #  @return [String] content (内容)
    #
    def content(*args)
      @parser.content(self, *args)
    end

    #
    # set content of element (要素の内容をセットする)
    # @param [String] value content (要素の内容)
    # @return [Meteor::Element] element (要素)
    #
    def content=(value)
      @parser.content(self, value)
    end

    #
    # set attribute (属性をセットする)
    # @param [String] name attribute name (属性の名前)
    # @param [String] value attribute value (属性の値)
    # @return [Meteor::Element] element (要素)
    #
    def []=(name, value)
      @parser.attr(self, name, value)
    end

    #
    # get attribute value (属性の値を取得する)
    # @param [String] name attribute name (属性の名前)
    # @return [String] attribute value (属性の値)
    #
    def [](name)
      @parser.attr(self, name)
    end

    #
    # remove attribute of element (要素の属性を消す)
    # @param [String] attr_name attribute name (属性名)
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
    def flush
      @parser.flush
    end

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
  class RootElement < Element

    EMPTY = ''

    ##
    ## イニシャライザ
    ##
    #def initialize()
    #  #コンテントタイプ
    #  #@contentType = ''
    #  #改行コード
    #  #@kaigyoCode = ''
    #  #文字コード
    #  #@character_encoding=''
    #end

    attr_accessor :content_type #[String] content type (コンテントタイプ)
    attr_accessor :kaigyo_code #[String] newline (改行コード)
    attr_accessor :charset #[String] charset (文字コード)
    attr_accessor :character_encoding #[String] character encoding (文字エンコーディング)
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
    # @param [String] name attribute name (属性名)
    # @param [String] value attribute value (属性値)
    #
    def store(name, value)

      if !@map[name] then
        attr = Attribute.new
        attr.name = name
        attr.value = value
        if @recordable then
          attr.changed = true
          attr.removed = false
        end
        @map[name] = attr
      else
        attr = @map[name]
        if @recordable && attr.value != value then
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

    private :initialize_0
    private :initialize_1

    #
    # get attribute value using attribute name (属性名で属性値を取得する)
    # @param [String] name attribute name (属性名)
    # @return [String] attribute value (属性値)
    #
    def fetch(name)
      if @map[name] && !@map[name].removed then
        @map[name].value
      end
    end

    #
    # delete attribute using attribute name (属性名に対応した属性を削除する)
    # @param name attribute name (属性名)
    #
    def delete(name)
      if @recordable && @map[name] then
        @map[name].removed = true
        @map[name].changed = false
      end
    end

    #
    # get update flag of attribute using attribute name (属性名で属性の変更フラグを取得する)
    # @return [true,false] update flag of attribute (属性の変更状況)
    #
    def changed(name)
      if @map[name] then
        @map[name].changed
      end
    end

    #
    # get delete flag of attribute using attribute name (属性名で属性の削除状況を取得する)
    # @return [true,false] delete flag of attribute (属性の削除状況)
    #
    def removed(name)
      if @map[name] then
        @map[name].removed
      end
    end

    attr_accessor :map
    attr_accessor :recordable

    #
    # set a couple of attribute name and attribute value (属性名と属性値を対としてセットする)
    # 
    # @param [String] name attribute name (属性名)
    # @param [String] value attribute value (属性値)
    #
    def []=(name, value)
      store(name, value)
    end

    #
    # get attribute value using attribute name (属性名で属性値を取得する)
    # 
    # @param [String] name attribute name (属性名)
    # @return [String] attribute value (属性値)
    #
    def [](name)
      fetch(name)
    end
  end

  if RUBY_VERSION < RUBY_VERSION_1_9_0 then
    class AttributeMap
      #
      # initializer (イニシャライザ)
      #
      def initialize_0
        @map = Hash.new
        @names = Array.new
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
        @names = Array.new(attr_map.names)
        @recordable = attr_map.recordable
      end

      private :initialize_1

      #
      # set a couple of attribute name and attribute value (属性名と属性値を対としてセットする)
      # @param [String] name attribute name (属性名)
      # @param [String] value attribute value (属性値)
      #
      def store(name, value)

        if !@map[name] then
          attr = Attribute.new
          attr.name = name
          attr.value = value
          if @recordable then
            attr.changed = true
            attr.removed = false
          end
          @map[name] = attr
          @names << name
        else
          attr = @map[name]
          if @recordable && attr.value != value then
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
        @names
      end
    end
  end

  #
  # Attribute class (属性クラス)
  #
  class Attribute

    #
    # initializer (イニシャライザ)
    #
    def initialize
      #@name = nil
      #@value = nil
      #@changed = false
      #@removed = false
    end

    attr_accessor :name #[String] attribute name (名前)
    attr_accessor :value #[String] attribute value (値)
    attr_accessor :changed #[true,false] update flag (更新フラグ)
    attr_accessor :removed #[true,false] delete flag (削除フラグ)

  end

  #
  # Parser Class (パーサ共通クラス)
  #
  class Parser
    HTML = ZERO
    XHTML = ONE
    HTML5 = TWO
    XHTML5 = THREE
    XML = FOUR
  end

  #
  # Parser Factory Class (パーサファクトリクラス)
  #
  class ParserFactory

    ABST_EXT_NAME = '.*'
    #CURRENT_DIR = FileUtils.pwd
    #puts CURRENT_DIR
    CURRENT_DIR = '.'
    SLASH = '/'
    ENC_UTF8 = 'UTF-8'

    attr_accessor :type #[FixNum] default type of parser (デフォルトのパーサ・タイプ)
    attr_accessor :root #[String] root root directory (基準ディレクトリ)
    attr_accessor :enc #[String] default character encoding (デフォルトエンコーディング)

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
    #  @param [FixNum] type default type of parser (デフォルトのパーサ・タイプ)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize(*args)
      case args.length
        when 0 then
          initialize_0
        when 1 then
          initialize_1(args[0])
        when 2 then
          initialize_2(args[0], args[1])
        when 3 then
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
    # @paeam [FixNum] bs_type default type of parser (デフォルトのパーサ・タイプ)
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
    # @option opts [FixNum] :type default type of parser (デフォルトのパーサ・タイプ)
    # @option @deprecated opts [FixNum] :base_type default type of parser (デフォルトのパーサ・タイプ)
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
    #@overload bind(relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload bind(relative_path)
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload bind(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload bind(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def bind(*args)
      case args.length
        when 1 then
          bind_1(args[0])
        when 2 then
          if args[0].kind_of?(Fixnum)
            bind_2_n(args[0], args[1])
          elsif args[0].kind_of?(String)
            bind_2_s(args[0], args[1])
          else
            raise ArgumentError
          end
        when 3 then
          bind_3(args[0], args[1], args[2])
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

      if paths.length == 1 then
        return File.basename(paths[0], ABST_EXT_NAME)
      else
        if CURRENT_DIR.eql?(paths[0]) then
          paths.delete_at 0
          paths[paths.length - 1] = File.basename(paths[paths.length - 1], ABST_EXT_NAME)
          return paths.join(SLASH)
        else
          paths[paths.length - 1] = File.basename(paths[paths.length - 1], ABST_EXT_NAME)
          return paths.join(SLASH)
        end
      end
    end

    private :path_to_url

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser(パーサ)
    #
    def bind_3(type, relative_path, enc)

      relative_url = path_to_url(relative_path)

      case type
        when Parser::HTML then
          html = Meteor::Ml::Html::ParserImpl.new()
          html.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = html
        when Parser::XHTML then
          xhtml = Meteor::Ml::Xhtml::ParserImpl.new()
          xhtml.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xhtml
        when Parser::HTML5 then
          html5 = Meteor::Ml::Html5::ParserImpl.new()
          html5.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = html5
        when Parser::XHTML5 then
          xhtml5 = Meteor::Ml::Xhtml5::ParserImpl.new()
          xhtml5.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xhtml5
        when Parser::XML then
          xml = Meteor::Ml::Xml::ParserImpl.new()
          xml.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xml
      end
    end

    private :bind_3

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser(パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def bind_2_n(type, relative_path)

      relative_url = path_to_url(relative_path)

      case type
        when Parser::HTML then
          ps = Meteor::Ml::Html::ParserImpl.new()
        when Parser::XHTML then
          ps = Meteor::Ml::Xhtml::ParserImpl.new()
        when Parser::HTML5 then
          ps = Meteor::Ml::Html5::ParserImpl.new()
        when Parser::XHTML5 then
          ps = Meteor::Ml::Xhtml5::ParserImpl.new()
        when Parser::XML then
          ps = Meteor::Ml::Xml::ParserImpl.new()
      end

      ps.read(File.expand_path(relative_path, @root), @enc)
      @cache[relative_url] = ps

    end

    private :bind_2_n

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def bind_2_s(relative_path,enc)

      relative_url = path_to_url(relative_path)

      case @type
        when Parser::HTML then
          ps = Meteor::Ml::Html::ParserImpl.new()
        when Parser::XHTML then
          ps = Meteor::Ml::Xhtml::ParserImpl.new()
        when Parser::HTML5 then
          ps = Meteor::Ml::Html5::ParserImpl.new()
        when Parser::XHTML5 then
          ps = Meteor::Ml::Xhtml5::ParserImpl.new()
        when Parser::XML then
          ps = Meteor::Ml::Xml::ParserImpl.new()
      end

      ps.read(File.expand_path(relative_path, @root), enc)
      @cache[relative_url] = ps

    end

    private :bind_2_s

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def bind_1(relative_path)

      relative_url = path_to_url(relative_path)

      case @type
        when Parser::HTML then
          ps = Meteor::Ml::Html::ParserImpl.new()
        when Parser::XHTML then
          ps = Meteor::Ml::Xhtml::ParserImpl.new()
        when Parser::HTML5 then
          ps = Meteor::Ml::Html5::ParserImpl.new()
        when Parser::XHTML5 then
          ps = Meteor::Ml::Xhtml5::ParserImpl.new()
        when Parser::XML then
          ps = Meteor::Ml::Xml::ParserImpl.new()
        else
          raise ArgumentError
      end

      ps.read(File.expand_path(relative_path, @root), @enc)
      @cache[relative_url] = ps

    end

    private :bind_1

    #
    #@overload parser(key)
    # get parser (パーサを取得する)
    # @param [String] key identifier (キー)
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
        when 1 then
          parser_1(args[0])
        when 2,3 then
          bind(args)
      end
      #parser_1(key)
    end

    #
    # get parser (パーサを取得する)
    # @param [String] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def parser_1(key)
      @pif = @cache[key]

      if Meteor::Parser::HTML == @pif.doc_type then
        Meteor::Ml::Html::ParserImpl.new(@pif)
      elsif Meteor::Parser::XHTML == @pif.doc_type then
        Meteor::Ml::Xhtml::ParserImpl.new(@pif)
      elsif Meteor::Parser::HTML5 == @pif.doc_type then
        Meteor::Ml::Html5::ParserImpl.new(@pif)
      elsif Meteor::Parser::XHTML5 == @pif.doc_type then
        Meteor::Ml::Xhtml5::ParserImpl.new(@pif)
      elsif Meteor::Parser::XML == @pif.doc_type then
        Meteor::Ml::Xml::ParserImpl.new(@pif)
      end
    end

    private :parser_1

    #
    # get root element (ルート要素を取得する)
    # @param [String] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def element(key)
      parser_1(key).root_element
    end


    # @overload bind_str(type, relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [Fixnum] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload bind_str(relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def bind_str(*args)
      case args.length
        when 2 then
          bind_str_2(args[0],args[1])
        when 3 then
          bind_str_3(args[0],args[1],args[2])
        else
          raise ArgumentError
      end
    end

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def bind_str_3(type, relative_url, doc)
      case type
        when Parser::HTML then
          ps = Meteor::Ml::Html::ParserImpl.new()
        when Parser::XHTML then
          ps = Meteor::Ml::Xhtml::ParserImpl.new()
        when Parser::HTML5 then
          ps = Meteor::Ml::Html5::ParserImpl.new()
        when Parser::XHTML5 then
          ps = Meteor::Ml::Xhtml5::ParserImpl.new()
        when Parser::XML then
          ps = Meteor::Ml::Xml::ParserImpl.new()
      end

      ps.dcument = doc
      ps.parse
      @cache[relative_url] = ps
    end

    private :bind_str_3

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def bind_str_2(relative_url, doc)
      case @type
        when Parser::HTML then
          ps = Meteor::Ml::Html::ParserImpl.new()
        when Parser::XHTML then
          ps = Meteor::Ml::Xhtml::ParserImpl.new()
        when Parser::HTML5 then
          ps = Meteor::Ml::Html5::ParserImpl.new()
        when Parser::XHTML5 then
          ps = Meteor::Ml::Xhtml5::ParserImpl.new()
        when Parser::XML then
          ps = Meteor::Ml::Xml::ParserImpl.new()
      end

      ps.document = doc
      ps.parse
      @cache[relative_url] = ps

    end

    private :bind_str_2

    alias :paraser_str :bind_str

    #
    # set parser (パーサをセットする)
    # @param [String] key identifier (キー)
    # @param [Meteor::Parser] ps parser (パーサ)
    #
    def []=(key, ps)
      @cache[key] = ps
    end

    #
    # get parser (パーサを取得する)
    # @param [String] key identifier (キー)
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
    # @option opts [String] :base_dir base directory (基準ディレクトリ)
    # @option opts [String] :base_enc default character encoding (デフォルト文字エンコーディング)
    # @option opts [FixNum] :base_type default type of parser (デフォルトのパーサ・タイプ)
    #
    def self.options=(opts)
      @@pf.options = opts
    end

    #
    #@overload bind(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload bind(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def self.bind(*args)
      @@pf.bind(*args)
    end

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] document document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def self.bind_str(type, relative_url, document)
      @@pf.bind_str(type,relative_url,document)
    end

    #
    # get root element (ルート要素を取得する)
    # @param [String] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def self.element(key)
      @@pf.element(key)
    end

  end

  module Hook

    #
    # Hook Class (フッククラス)
    #
    class Hooker

      #
      # initializer (イニシャライザ)
      #
      def initialize
      end

      def do_action(elm)
        #内容あり要素の場合
        if elm.empty then
          elm2 = elm.child()
          execute(elm2)
        end
      end

      #def execute(elm)
      #end
      #private :execute
    end

    #
    # Lopp Hook Class (ループフッククラス)
    #
    class Looper

      #
      # initializer (イニシャライザ)
      #
      def initialize
      end

      def do_action(elm, list)
        #内容あり要素の場合
        if elm.empty then
          elm2 = elm.child()
          init(elm2)
          list.each do |item|
            if  !elm2.mono then
              elm2.parser.root_element.document = elm.mixed_content
            end
            execute(elm2, item)
            elm2.flush
          end
        end
      end

      #def init(elm)
      #end
      #private :init

      #def execute(elm,item)
      #end
      #private :execute

    end
  end

  module Exception

    #
    # Element Search Exception (要素検索例外)
    #
    class NoSuchElementException

      attr_accessor :message #[String] message (メッセージ)

      #
      # initializer (イニシャライザ)
      # @overload initialize(tag)
      #  @param [String] tag tag name (タグ名)
      # @overload initialize(attr_name,attr_value)
      #  @param [String] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      # @overload initialize(tag,attr_name,attr_value)
      #  @param [String] tag tag name (タグ名)
      #  @param [String] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      # @overload initialize(attr_name1,attr_value1,attr_name2,attr_value2)
      #  @param [String] attr_name1 attribute name1 (属性名１)
      #  @param [String] attr_value1 attribute value1 (属性値１)
      #  @param [String] attr_name2 attribute name2 (属性名２)
      #  @param [String] attr_value2 attribute value2 (属性値２)
      # @overload initialize(tag,attr_name1,attr_value1,attr_name2,attr_value2)
      #  @param [String] tag tag name (タグ名)
      #  @param [String] attr_name1 attribute name1 (属性名１)
      #  @param [String] attr_value1 attribute value1 (属性値１)
      #  @param [String] attr_name2 attribute name2 (属性名２)
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

      def initialize_1(tag)
        self.message="element not found : #{tag}"
      end

      private :initialize_1

      def initialize_2(attr_name, attr_value)
        self.message="element not found : [#{attr_name}=#{attr_value}]"
      end

      private :initialize_2

      def initialize_3(tag, attr_name, attr_value)
        self.message="element not found : #{tag}[#{attr_name}=#{attr_value}]"
      end

      private :initialize_3

      def initialize_4(attr_name1, attr_value1, attr_name2, attr_value2)
        self.message="element not found : [#{attr_name1}=#{attr_value1}][#{attr_name2}=#{attr_value2}]"
      end

      private :initialize_4

      def initialize_5(tag, attr_name1, attr_value1, attr_name2, attr_value2)
        self.message="element not found : #{tag}[#{attr_name1}=#{attr_value1}][#{attr_name2}=#{attr_value2}]"
      end

      private :initialize_5

    end

  end

  module Core

    #
    # Parser Core Class (パーサコアクラス)
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
      PATTERN_FIND_1 = '^([^,\\[\\]#\\.]+)$'
      PATTERN_FIND_2_1 = '^#([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      PATTERN_FIND_2_2 = '^\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      PATTERN_FIND_2_3 = '^\\[([^\\[\\],]+)=([^\\[\\],]+)\\]$'
      PATTERN_FIND_3_1 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,\\[\\]]+)=([^,\\[\\]]+)\\]$'
      PATTERN_FIND_3_2 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)#([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      PATTERN_FIND_3_3 = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      PATTERN_FIND_4 = '^\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$'
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

      ESCAPE_ENTITY_REF = ''

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
        @element_cache = Hash.new()
        #フックドキュメント
        @document_hook = ''
      end

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

      attr_accessor :element_cache #[Hash] element cache (要素キャッシュ)
      attr_accessor :doc_type #[Fixnum] document type (ドキュメントタイプ)
      attr_accessor :document_hook  #[String] hook document (フック・ドキュメント)
      attr_accessor :element_hook #[Meteor::Element] element (要素)

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
      # read file , set in parser (ファイルを読み込み、パーサにセットする)
      # @param [String] file_path absolute path of input file (入力ファイルの絶対パス)
      # @param [String] enc character encoding of input file (入力ファイルの文字コード)
      #
      def read(file_path, enc)

        #try {
        @character_encoding = enc
        #ファイルのオープン
        if ParserFactory::ENC_UTF8.eql?(enc) then
          #io = File.open(file_path,MODE_BF << enc)
          io = File.open(file_path, MODE_UTF8)
        else
          io = File.open(file_path, '' << MODE_BF << enc << MODE_AF)
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
      # @overload element(tag)
      #  get element using tag name (要素のタグ名で要素を取得する)
      #  @param [String] tag tag name (タグ名)
      #  @return [Meteor::Element] element(要素)
      # @overload element(tag,attrs)
      #  要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する
      #  @param [String] tag  タグ名
      #  @param [Hash] attrs 属性マップ
      #  @return [Meteor::Element] 要素
      # @overload element(attrs)
      #  get element using tag name and attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [Hash] attrs attribute map (属性マップ)
      #  @return [Meteor::Element] element (要素)
      # @overload element(tag,attr_name,attr_value)
      #  get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
      #  @param [String] tag  tag name (タグ名)
      #  @param [String] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload element(attr_name,attr_value)
      #  get element using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
      #  @param [String] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload element(tag,attr_name1,attr_value1,attr_name2,attr_value2)
      #  get element using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String] tag tag name (タグ名)
      #  @param [String] attr_name1 attribute name1 (属性名1)
      #  @param [String] attr_value1 attribute value1 (属性値1)
      #  @param [String] attr_name2 attribute name2 (属性名2)
      #  @param [String] attr_value2 attribute value2 (属性値2)
      #  @return [Meteor::Element] element (要素)
      # @overload element(attr_name1,attr_value1,attr_name2,attr_value2)
      #  get element using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
      #  @param [String] attr_name1 attribute name1 (属性名1)
      #  @param [String] attr_value1 attribute value1 (属性値1)
      #  @param [String] attr_name2 attribute name2 (属性名2)
      #  @param [String] attr_value2 attribute value2 (属性値2)
      #  @return [Meteor::Element] element (要素)
      # @overload element(elm)
      #  mirror element (要素を射影する)
      #  @param [Meteor::Element] elm element (要素)
      #  @return [Meteor::Element] element (要素)
      #
      def element(elm, attrs = nil,*args)
        if !attrs
          if elm.kind_of?(String)
            element_1(elm)
            if @elm_ then
              @element_cache.store(@elm_.object_id, @elm_)
            end
          elsif elm.kind_of?(Meteor::Element)
            shadow(elm)
          elsif elm.kind_of?(Hash)
            if elm.size == ONE
              element_2(elm.keys[0], elm.values[0])
              if @elm_ then
                @element_cache.store(@elm_.object_id, @elm_)
              end
            elsif elm.size == TWO
              element_4(elm.keys[0], elm.values[0], elm.keys[1], elm.values[1])
              if @elm_ then
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
            element_3(elm, attrs.keys[0], attrs.values[0])
            if @elm_ then
              @element_cache.store(@elm_.object_id, @elm_)
            end
          elsif attrs.size == TWO
            element_5(elm, attrs.keys[0], attrs.values[0], attrs.keys[1], attrs.values[1])
            if @elm_ then
              @element_cache.store(@elm_.object_id, @elm_)
            end
          else
            @elm_ = nil
            raise ArgumentError
          end
        elsif attrs.kind_of?(String)
          case args.length
            when ZERO
              element_2(elm,attrs)
              if @elm_ then
                @element_cache.store(@elm_.object_id, @elm_)
              end
            when ONE
              element_3(elm, attrs, args[0])
              if @elm_ then
                @element_cache.store(@elm_.object_id, @elm_)
              end
            when TWO
              element_4(elm, attrs, args[0],args[1])
              if @elm_ then
                @element_cache.store(@elm_.object_id, @elm_)
              end
            when THREE
              element_5(elm, attrs, args[0],args[1],args[2])
              if @elm_ then
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
      # get element using selector like CSS3 (CSS3のようにセレクタを用いて要素を取得する)
      # CSS3 selector partial support (CSS3セレクタの部分的サポート)
      # @param [String] selector selector (セレクタ)
      # @return [Meteor::Element] element (要素)
      #
      def find(selector)
        #puts selector
        if @res = @@pattern_find_1.match(selector) then
          element_1(@res[1])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_2_1.match(selector) then
          element_2(CSS_ID, @res[1])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_3_1.match(selector) then
          element_3(@res[1], @res[2], @res[3])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_3_2.match(selector) then
          element_3(@res[1], CSS_ID, @res[2])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_3_3.match(selector) then
          element_3(@res[1], CSS_CLASS, @res[2])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_5.match(selector) then
          element_5(@res[1], @res[2], @res[3], @res[4], @res[5])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_2_3.match(selector) then
          element_2(@res[1], @res[2])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_4.match(selector) then
          element_4(@res[1], @res[2], @res[3], @res[4])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        elsif @res = @@pattern_find_2_2.match(selector) then
          element_2(CSS_CLASS, @res[1])
          if @elm_ then
            @element_cache.store(@elm_.object_id, @elm_)
          end
        else
          nil
        end
      end

      #
      # get element using tag name (タグ名で検索し、要素を取得する)
      # @param [String] tag tag name (タグ名)
      # @return [Meteor::Element] element(要素)
      #
      def element_1(tag)

        @_tag = Regexp.quote(tag)

        #要素検索用パターン
        @pattern_cc = "<#{@_tag}(|\\s[^<>]*)\\/>|<#{@_tag}((?:|\\s[^<>]*))>(((?!(#{@_tag}[^<>]*>)).)*)<\\/#{@_tag}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        #内容あり要素検索
        @res = @pattern.match(@root.document)

        if @res
          if @res[1]
            element_without_1(tag)
          else
            element_with_1(tag)
          end
        else

        end

        @elm_
      end

      private :element_1

      def element_with_1(tag)

        @elm_ = Meteor::Element.new(tag)
        #属性
        @elm_.attributes = @res[2]
        #内容
        @elm_.mixed_content = @res[3]
        #全体
        @elm_.document = @res[0]

        #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_1_1 << @_tag
        #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
        @pattern_cc = "<#{@_tag}(?:|\\s[^<>]*)>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

        #内容あり要素検索用パターン
        @elm_.pattern = @pattern_cc

        @elm_.empty = true

        @elm_.parser = self

        @elm_
      end

      private :element_with_1

      def element_without_1(tag)
        #要素
        @elm_ = Meteor::Element.new(tag)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_1_3
        #@pattern_cc = "<#{@_tag}(?:|\\s[^<>]*)\\/>"
        @elm_.pattern = @pattern_cc

        @elm_.empty = false

        @elm_.parser = self

        @elm_
      end

      private :element_without_1

      #
      # get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で検索し、要素を取得する)
      # @param [String] tag  tag name (タグ名)
      # @param [String] attrName attribute name (属性名)
      # @param [String] attr_value attribute value (属性値)
      # @return [Meteor::Element] element (要素)
      def element_3(tag, attr_name, attr_value)

        @_tag = Regexp.quote(tag)
        @_attr_name = Regexp.quote(attr_name)
        @_attr_value = Regexp.quote(attr_value)


        @pattern_cc_1 = "<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>|<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_tag}[^<>]*>)).)*)<\\/#{@_tag}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1 then
          @res2 = element_with_3_2
          @pattern_cc_2 = @pattern_cc

          #puts @res2.captures.length
          #puts @res2.regexp.to_s
        end

        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
            @res = @res1
            #@pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_3(tag)
            else
              element_with_3_1(tag)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            #@pattern_cc = @pattern_cc_2
            element_with_3_1(tag)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          #@pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_3(tag)
          else
            element_with_3_1(tag)
          end
        elsif @res2 && !@res1 then
          @res = @res2
          #@pattern_cc = @pattern_cc_2
          element_with_3_1(tag)
        else
          puts Meteor::Exception::NoSuchElementException.new(tag, attr_name, attr_value).message
          @elm_ = nil
        end

        @elm_
      end

      private :element_3

      def element_with_3_1(tag)
        case @res.captures.length
        when FOUR
          #要素
          @elm_ = Meteor::Element.new(tag)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = ''<< TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
          #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_tag
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
          @pattern_cc = "<#{@_tag}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        when FIVE
          #要素
          @elm_ = Meteor::Element.new(tag)
          #属性
          @elm_.attributes = @res[2]
          #内容
          @elm_.mixed_content = @res[3]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = ''<< TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
          #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_tag
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
          @pattern_cc = "<#{@_tag}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        when THREE,SIX
          #内容
          @elm_ = Meteor::Element.new(tag)
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

      private :element_with_3_1

      def element_with_3_2

        #@pattern_cc_1 = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1 << @_attr_value << TAG_SEARCH_2_4_2
        @pattern_cc_1 = "<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"

        @pattern_cc_1b = '' << TAG_OPEN << @_tag << TAG_SEARCH_1_4
        #@pattern_cc_1b = "<#{@_tag}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        #@pattern_cc_1_1 = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value << TAG_SEARCH_4_7
        @pattern_cc_1_1 = "<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_tag << TAG_SEARCH_4_3
        #@pattern_cc_1_2 = ".*?<#{@_tag}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"


        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_tag << TAG_CLOSE
        #@pattern_cc_2 = '' << "<\\/#{@_tag}>"

        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_tag << TAG_CLOSE
        #@pattern_cc_2_1 = ".*?<\\/#{@_tag}>"

        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_tag << TAG_CLOSE
        #@pattern_cc_2_2 = ".*?)<\\/#{@_tag}>"

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = ''

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf

        if @sbuf.length == ZERO || @cnt != ZERO then
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end

      private :element_with_3_2

      def element_without_3(tag)
        element_without_3_1(tag, TAG_SEARCH_NC_2_3_2)
      end

      private :element_without_3

      def element_without_3_1(tag, closer)

        #要素
        @elm_ = Meteor::Element.new(tag)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ << @_attr_value << closer
        #@pattern_cc = "<#{@_tag}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}#{closer}"
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
        @_attr_name = Regexp.quote(attr_name)
        @_attr_value = Regexp.quote(attr_value)
#=begin
        ##@pattern_cc = '' << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value << TAG_SEARCH_2_4
        #@pattern_cc = '' << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value << TAG_SEARCH_2_4_2_3
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\""

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
          element_3(@res[1], attr_name, attr_value)
        else
          puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
          @elm_ = nil
        end
#=end

=begin
       @pattern_cc_1 = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>|<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(\\3[^<>]*>)).)*)<\\/\\3>"


        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1 then
          @res2 = element_with_2_2
          @pattern_cc_2 = @pattern_cc

          #puts @res2.captures.length
          #puts @res2.regexp.to_s
        end

        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
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
        elsif @res1 && !@res2 then
          @res = @res1
          #@pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_2
          else
            element_with_2_1
          end
        elsif @res2 && !@res1 then
          @res = @res2
          #@pattern_cc = @pattern_cc_2
          element_with_2_1
        else
          puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
          @elm_ = nil
        end
=end

        @elm_
      end

      private :element_2

=begin
     def element_with_2_1()
        #puts @res.captures.length
        case @res.captures.length
          when FOUR
            @_tag = @res[1]
            #要素
            @elm_ = Element.new(@_tag)
            #属性
            @elm_.attributes = @res[2]
            #内容
            @elm_.mixed_content = @res[3]
            #全体
            @elm_.document = @res[0]
            #内容あり要素検索用パターン
            #@pattern_cc = ''<< TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_tag
            #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
            @pattern_cc = "<#{@_tag}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

            @elm_.pattern = @pattern_cc

            @elm_.empty = true

            @elm_.parser = self

          when FIVE,SEVEN
            @_tag = @res[3]
            #要素
            @elm_ = Element.new(@_tag)
            #属性
            @elm_.attributes = @res[4]
            #内容
            @elm_.mixed_content = @res[5]
            #全体
            @elm_.document = @res[0]
            #内容あり要素検索用パターン
            #@pattern_cc = ''<< TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_tag
            #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
            @pattern_cc = "<#{@_tag}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

            @elm_.pattern = @pattern_cc

            @elm_.empty = true

            @elm_.parser = self

          when THREE,SIX
            #puts @res[1]
            #puts @res[3]
            #@_tag = @res[1]
            #内容
            @elm_ = Element.new(@_tag)
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

        #@pattern_cc_1 = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1 << @_attr_value << TAG_SEARCH_2_4_2
        @pattern_cc_1 = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = ''

        @cnt = 0

        create_element_pattern_2(2)

        @pattern_cc = @sbuf

        if @sbuf.length == ZERO || @cnt != ZERO then
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        #@res
      end

      private :element_with_2_2

      def create_pattern_2(args_cnt)

        #puts @_tag

        @pattern_cc_1b = '' << TAG_OPEN << @_tag << TAG_SEARCH_1_4

        #@pattern_cc_1_1 = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value << TAG_SEARCH_4_7
        @pattern_cc_1_1 = "<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_tag << TAG_SEARCH_4_3

        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_tag << TAG_CLOSE

        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_tag << TAG_CLOSE

        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_tag << TAG_CLOSE

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
        @pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ << @_attr_value << closer
        @elm_.pattern = @pattern_cc

        @elm_.parser = self

        @elm_
      end

      private :element_without_2_1
=end

      #
      # get element using tag name and attribute1,2(name="value") (要素のタグ名と属性1・属性2(属性名="属性値")で検索し、要素を取得する)
      # @param [String] tag  tag name (タグ名)
      # @param [String] attr_name1 attribute name1 (属性名1)
      # @param [String] attr_value1 attribute value1 (属性値1)
      # @param [String] attr_name2 attribute name2 (属性名2)
      # @param [String] attr_value2 attribute value2 (属性値2)
      # @return [Meteor::Element] element (要素)
      #
      def element_5(tag, attr_name1, attr_value1, attr_name2, attr_value2)

        @_tag = Regexp.quote(tag)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)


        @pattern_cc_1 = "<#{@_tag}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)\\/>|<#{@_tag}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_tag}[^<>]*>)).)*)<\\/#{@_tag}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1 then
          @res2 = element_with_5_2
          @pattern_cc_2 = @pattern_cc

          #puts @res2.captures.length
          #puts @res2.regexp.to_s
        end

        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
            @res = @res1
            #@pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_5(tag)
            else
              element_with_5_1(tag)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            #@pattern_cc = @pattern_cc_2
            element_with_5_1(tag)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          #@pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_5(tag)
          else
            element_with_5_1(tag)
          end
        elsif @res2 && !@res1 then
          @res = @res2
          #@pattern_cc = @pattern_cc_2
          element_with_5_1(tag)
        else
          puts Meteor::Exception::NoSuchElementException.new(tag, attr_name, attr_value).message
          @elm_ = nil
        end

        @elm_
      end

      private :element_5

      def element_with_5_1(tag)

        #puts @res.captures.length
        case @res.captures.length
        when FOUR
          #要素
          @elm_ = Meteor::Element.new(tag)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_2_2 << @_tag
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
          @pattern_cc = "<#{@_tag}\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

          @elm_.pattern = @pattern_cc
          #
          @elm_.empty = true

          @elm_.parser = self
        when FIVE
          #要素
          @elm_ = Meteor::Element.new(tag)
          #属性
          @elm_.attributes = @res[2]
          #内容
          @elm_.mixed_content = @res[3]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_2_2 << @_tag
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_tag << TAG_CLOSE
          @pattern_cc = "<#{@_tag}\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*>((?!(#{@_tag}[^<>]*>)).)*<\\/#{@_tag}>"

          @elm_.pattern = @pattern_cc
          #
          @elm_.empty = true

          @elm_.parser = self

        when THREE,SIX
          #要素
          @elm_ = Meteor::Element.new(tag)
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

        #@pattern_cc_1 = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_4_2_2
        @pattern_cc_1 = "<#{@_tag}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))"

        @pattern_cc_1b = '' << TAG_OPEN << @_tag << TAG_SEARCH_1_4
        #@pattern_cc_1b = "<#{@_tag}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        #@pattern_cc_1_1 = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value1 << TAG_SEARCH_4_7_2
        @pattern_cc_1_1 = "<#{@_tag}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_tag << TAG_SEARCH_4_3

        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_tag << TAG_CLOSE

        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_tag << TAG_CLOSE

        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_tag << TAG_CLOSE

        #@pattern_cc_1_2 = ".*?<#{@_tag}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        #
        #@pattern_cc_2 = '' << "<\\/#{@_tag}>"
        #
        #@pattern_cc_2_1 = ".*?<\\/#{@_tag}>"
        #
        #@pattern_cc_2_2 = ".*?)<\\/#{@_tag}>"

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = ''

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf

        if @sbuf.length == ZERO || @cnt != ZERO then
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end

      private :element_with_5_2

      def element_without_5(tag)
        element_without_5_1(tag, TAG_SEARCH_NC_2_3_2_2)
      end

      private :element_without_5

      def element_without_5_1(tag, closer)

        #要素
        @elm_ = Meteor::Element.new(tag)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << closer
        @pattern_cc = "<#{@_tag}\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}#{closer}"

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

        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)

        #@pattern_cc = '' << TAG_SEARCH_3_1_2_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_4_2_3
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
          #@elm_ = element_5(@res[1], attr_name1, attr_value1,attr_name2, attr_value2)
          element_5(@res[1], attr_name1, attr_value1, attr_name2, attr_value2)
        else
          puts Meteor::Exception::NoSuchElementException.new(attr_name1, attr_value1, attr_name2, attr_value2).message
          @elm_ = nil
        end

        @elm_
      end

      private :element_4

      def create_element_pattern
        @position = 0

        while (@res = @pattern.match(@root.document, @position)) || @cnt > ZERO

          if @res then

            if @cnt > ZERO then

              @position2 = @res.end(0)

              @res = @pattern_2.match(@root.document, @position)

              if @res then

                @position = @res.end(0)

                if @position > @position2 then

                  @sbuf << @pattern_cc_1_2

                  @cnt += 1

                  @position = @position2
                else

                  @cnt -= ONE

                  if @cnt != ZERO then
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

            if @cnt == ZERO then
              break
            end

            @res = @pattern_2.match(@root.document, @position)

            if @res then

              @cnt -= ONE

              if @cnt != ZERO then
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

          if @res then

            if @cnt > ZERO then

              @position2 = @res.end(0)

              @res = @pattern_2.match(@root.document, @position)

              if @res then

                @position = @res.end(0)

                if @position > @position2 then

                  @sbuf << @pattern_cc_1_2

                  @cnt += 1

                  @position = @position2
                else

                  @cnt -= ONE

                  if @cnt != ZERO then
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

              @_tag = @res[1]

              create_pattern_2(args_cnt)

              @sbuf << @pattern_cc_1_1

              @cnt += ONE

            end
          else

            if @cnt == ZERO then
              break
            end

            @res = @pattern_2.match(@root.document, @position)

            if @res then

              @cnt -= ONE

              if @cnt != ZERO then
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

      #
      # @overload attr(elm,attr)
      #  set attribute of element (要素の属性をセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [Hash] attr attribute (属性)
      #  @return [Meteor::Element] element (要素)
      # @overload attr(elm,attr_name,attr_value)
      #  set attribute of element (要素の属性をセットする)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [String] attr_name  attribute name (属性名)
      #  @param [String,true,false] attr_value attribute value (属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload attr(elm,attr_name)
      #  get attribute value of element (要素の属性値を取得する)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [String] attr_name attribute name (属性名)
      #  @return [String] attribute value (属性値)
      #
      def attr(elm, attr,*args)
        if attr.kind_of?(String)
          case args.length
            when ZERO
              get_attr_value(elm, attr)
            when ONE
              elm.document_sync = true
              set_attribute_3(elm, attr,args[0])
          end

        elsif attr.kind_of?(Hash) && attr.size == 1
          elm.document_sync = true
          set_attribute_3(elm, attr.keys[0], attr.values[0])
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
        if !elm.cx then
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
        if elm.attributes.include?(' ' << attr_name << ATTR_EQ) then

          @_attr_value = attr_value

          #属性の置換
          @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << SET_ATTR_1)
          #@pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"")

          elm.attributes.sub!(@pattern,'' << attr_name << ATTR_EQ << @_attr_value << DOUBLE_QUATATION)
          #elm.attributes.sub!(@pattern, "#{attr_name}=\"#{@_attr_value}\"")
        else
          #属性文字列の最後に新規の属性を追加する
          @_attr_value = attr_value

          if EMPTY != elm.attributes && EMPTY != elm.attributes.strip then
            elm.attributes = '' << SPACE << elm.attributes.strip
          else
            elm.attributes = ''
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
        @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << GET_ATTR_1)
        #@pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"([^\"]*)\"")

        @res = @pattern.match(elm.attributes)

        if @res then
          unescape(@res[1])
        else
          nil
        end
      end

      private :get_attr_value_

      #
      # @overload attrs(elm,attrs)
      #  @param
      #
      # @overload attrs(elm)
      #
      def attrs(elm,*args)
        case args.length
          when ZERO
            get_attrs(elm)
          when ONE
            if args[0].kind_of?(Hash)
              if args[0].size == 1
                elm.document_sync = true
                set_attribute_3(elm, args[0].keys[0], args[0].values[0])
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
      # @return [Hash] attribute map (属性マップ)
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
      # @param [Hash] attr_map attribute map (属性マップ)
      # @return [Meteor::Element] element (要素)
      #
      def set_attrs(elm, attr_map)
        if !elm.cx then
          elm.document_sync = true
          attr_map.each do |name, value|
            set_attribute_3(elm, name, value)
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
            #if elm.kind_of?(Meteor::Element) && args[0].kind_of?(Meteor::AttributeMap) then
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
        if !elm.cx then
          attr_map.map.each do |name, attr|
            if attr_map.changed(name) then
              edit_attrs_(elm, name, attr.value)
            elsif attr_map.removed(name) then
              remove_attrs_(elm, name)
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
            #if args[0].kind_of?(Meteor::Element) then
            get_content_1(args[0])
          #else
          #  raise ArgumentError
          #end
          when TWO
            #if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String) then
            args[0].document_sync = true
            set_content_2(args[0], args[1])
          #else
          #  raise ArgumentError
          #end
          when THREE
            args[0].document_sync = true
            set_content_3(args[0], args[1], args[2])
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

        if entity_ref then
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
        elm.mixed_content = escape_content(content, elm)
        elm
      end

      private :set_content_2

      #
      # get content of element (要素の内容を取得する)
      # @param [Meteor::Element] elm element (要素)
      # @return [String] content (内容)
      #
      def get_content_1(elm)
        if !elm.cx then
          if elm.empty then
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
        if !elm.cx then
          elm.document_sync = true
          remove_attrs_(elm, attr_name)
        end

        elm
      end

      private :remove_attr

      def remove_attrs_(elm, attr_name)
        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << ERASE_ATTR_1)
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
      # @overload cxtag(tag,id)
      #  get cx(comment extension) tag using tag name and id attribute (要素のタグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
      #  @param [String] tag tag name (タグ名)
      #  @param [String] id value of id attribute (ID属性値)
      #  @return [Meteor::Element] element (要素)
      # @overload cxtag(id)
      #  get cx(comment extension) tag using id attribute (ID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
      #  @param [String] id value of id attribute (ID属性値)
      #  @return [Meteor::Element] element (要素)
      #
      def cxtag(*args)
        case args.length
          when ONE
            cxtag_1(args[0])
            if @elm_ then
              @element_cache.store(@elm_.object_id, @elm_)
            end
          when TWO
            cxtag_2(args[0], args[1])
            if @elm_ then
              @element_cache.store(@elm_.object_id, @elm_)
            end
          else
            raise ArgumentError
        end
      end

      #
      # get cx(comment extension) tag using tag name and id attribute (要素のタグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
      # @param [String] tag tag name (タグ名)
      # @param [String] id value of id attribute (ID属性値)
      # @return [Meteor::Element] element (要素)
      #
      def cxtag_2(tag, id)

        @_tag = Regexp.quote(tag)
        @_id = Regexp.quote(id)

        #CXタグ検索用パターン
        #@pattern_cc = '' << SEARCH_CX_1 << @_tag << SEARCH_CX_2
        #@pattern_cc << id << SEARCH_CX_3 << @_tag << SEARCH_CX_4 << @_tag << SEARCH_CX_5
        #@pattern_cc = "<!--\\s@#{tag}\\s([^<>]*id=\"#{id}\"[^<>]*)-->(((?!(<!--\\s\\/@#{tag})).)*)<!--\\s\\/@#{tag}\\s-->"
        @pattern_cc = "<!--\\s@#{@_tag}\\s([^<>]*id=\"#{@_id}\"[^<>]*)-->(((?!(<!--\\s/@#{@_tag})).)*)<!--\\s/@#{@_tag}\\s-->"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        #CXタグ検索
        @res = @pattern.match(@root.document)

        if @res then
          #要素
          @elm_ = Meteor::Element.new(tag)

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
      # @param [String] id value of id attribute (ID属性値)
      # @return [Meteor::Element] element (要素)
      #
      def cxtag_1(id)

        @_id = Regexp.quote(id)

        @pattern_cc = '' << SEARCH_CX_6 << @_id << DOUBLE_QUATATION
        #@pattern_cc = "<!--\\s@([^<>]*)\\s[^<>]*id=\"#{@_id}\""

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
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
      # @param [String] replaceDocument string for replacement (置換文字列)
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
          if item.usable then
            #puts "#{item.name}:#{item.document}"
            if !item.removed then
              if item.copy then
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
        #if !elm.cx then
        #  @_attributes = elm.attributes
        #
        #  if elm.empty then
        #    #内容あり要素の場合
        #    @_content = elm.mixed_content
        #
        #    elm.document = '' << TAG_OPEN << elm.name << @_attributes << TAG_CLOSE << @_content << TAG_OPEN3 << elm.name << TAG_CLOSE
        #    #elm.document = "<#{elm.name}#{@_attributes}>#{@_content}</#{elm.name}>"
        #  else
        #    #空要素の場合
        #    elm.document = '' << TAG_OPEN << elm.name << @_attributes << closer
        #    #elm.document = "<#{elm.name}#{@_attributes}#{closer}"
        #  end
        #else
        #  @_content = elm.mixed_content
        #
        #  #elm.document = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2
        #  #elm.document << @_content << SET_CX_3 << elm.name << SET_CX_4
        #  elm.document = "<!-- @#{elm.name} #{elm.attributes}-->#{@_content}<!-- /@#{elm.name} -->"
        #end

        #タグ置換
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        @root.document.sub!(@pattern, elm.document)
      end

      private :edit_document_2

      #
      # reflect (反映する)
      #
      def flush

        if self.element_hook then
          if self.element_hook.origin.mono then
            if self.element_hook.origin.cx then
              #@root.hookDocument << SET_CX_1 << @root.element.name << SPACE
              #@root.hookDocument << @root.element.attributes << SET_CX_2
              #@root.hookDocument << @root.element.mixed_content << SET_CX_3
              #@root.hookDocument << @root.element.name << SET_CX_4
              self.document_hook << "<!-- @#{self.element_hook.name} #{self.element_hook.attributes}-->#{self.element_hook.mixed_content}<!-- /@#{self.element_hook.name} -->"
            else
              #@root.hookDocument << TAG_OPEN << @root.element.name
              #@root.hookDocument << @root.element.attributes << TAG_CLOSE << @root.element.mixed_content
              #@root.hookDocument << TAG_OPEN3 << @root.element.name << TAG_CLOSE
              self.document_hook << "<#{self.element_hook.name}#{self.element_hook.attributes}>#{self.element_hook.mixed_content}</#{self.element_hook.name}>"
            end
            self.element_hook = Element.new!(self.element_hook.origin, self)
          else
            reflect
            @_attributes = self.element_hook.attributes

            if self.element_hook.origin.cx then
              #@root.hookDocument << SET_CX_1 << @root.element.name << SPACE
              #@root.hookDocument << @_attributes << SET_CX_2
              #@root.hookDocument << @root.document << SET_CX_3
              #@root.hookDocument << @root.element.name << SET_CX_4
              self.document_hook << "<!-- @#{self.element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{self.element_hook.name} -->"
            else
              #@root.hookDocument << TAG_OPEN << @root.element.name
              #@root.hookDocument << @_attributes << TAG_CLOSE << @root.document
              #@root.hookDocument << TAG_OPEN3 << @root.element.name << TAG_CLOSE
              self.document_hook << "<#{self.element_hook.name}#{@_attributes}>#{@root.document}</#{self.element_hook.name}>"
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
        #@root.document << "<!-- Powered by Meteor (C)Yasumasa Ashida -->"
      end

      private :clean

      #
      # mirror element 要素を射影する
      # 
      # @param [Meteor::Element] elm element (要素)
      # @return [Meteor::Element] element (要素)
      #
      def shadow(elm)
        if elm.empty then
          #内容あり要素の場合
          set_mono_info(elm)

          pif2 = create(self)

          @elm_ = Element.new!(elm, pif2)

          if !elm.mono then
            pif2.root_element.document = String.new(elm.mixed_content)
          else
            pif2.root_element.document = String.new(elm.document)
          end

          @elm_
        end
      end

      #private :shadow

      def set_mono_info(elm)

        @res = @@pattern_set_mono1.match(elm.mixed_content)

        if @res then
          elm.mono = true
        end
      end

      private :set_mono_info

      #
      # @overload execute(elm,hook)
      #  run action of Hooker (Hookerクラスの処理を実行する)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [Meteor::Hook::Hooker] hook Hooker object (Hookerオブジェクト)
      # @overload execute(elm,loop,list)
      #  run action of Looper (Looperクラスの処理を実行する)
      #  @param [Meteor::Element] elm element (要素)
      #  @param [Meteor::Element::Looper] loop Looper object (Looperオブジェクト)
      #  @param [Array] array(配列)
      #
      def execute(*args)
        case args.length
          when TWO
            execute_2(args[0], args[1])
          when THREE
            execute_3(args[0], args[1], args[2])
          else
            raise ArgumentError
        end
      end

      def execute_2(elm, hook)
        hook.do_action(elm)
      end

      private :execute_2

      def execute_3(elm, loop, list)
        loop.do_action(elm, list)
      end

      private :execute_3

      def is_match(regex, str)
        if regex.kind_of?(Regexp) then
          is_match_r(regex, str)
        elsif regex.kind_of?(Array) then
          is_match_a(regex, str)
        elsif regex.kind_of?(String) then
          if regex.eql?(str.downcase) then
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
        if regex.match(str.downcase) then
          true
        else
          false
        end
      end

      private :is_match_r

      def is_match_a(regex, str)
        str = str.downcase
        regex.each do |item|
          if item.eql?(str) then
            return true
          end
        end
        false
      end

      private :is_match_a

      def is_match_s(regex, str)
        if regex.match(str.downcase) then
          true
        else
          false
        end
      end

      private :is_match_s

      def create(pif)
        case pif.doc_type
          when Parser::HTML then
            Meteor::Ml::Html::ParserImpl.new
          when Parser::XHTML then
            Meteor::Ml::Xhtml::ParserImpl.new
          when Parser::HTML5 then
            Meteor::Ml::Html5::ParserImpl.new
          when Parser::XHTML5 then
            Meteor::Ml::Xhtml5::ParserImpl.new
          when Parser::XML then
            Meteor::Ml::Xml::ParserImpl.new
          else
            nil
        end
      end

      private :create

    end

    if RUBY_VERSION < RUBY_VERSION_1_9_0 then
      class Kernel
        MODE = 'r'

        #
        # read file , set in parser (ファイルを読み込み、パーサにセットする)
        # @param [String] file_path absolute path of input file (入力ファイルの絶対パス)
        # @param [String] enc character encoding of input file (入力ファイルの文字コード)
        #
        def read(file_path, enc)

          #try {
          @character_encoding = enc
          #ファイルのオープン

          #読込及び格納
          io = open(file_path, MODE)
          @root.document = io.read
          #@root.document = @root.document.kconv(get_encoding(), Kconv.guess(@root.document))
          enc = Kconv.guess(@root.document)
          #enc = get_encoding
          if !Kconv::UTF8.equal?(enc) then
            @root.document = @root.document.kconv(Kconv::UTF8, enc)
          end

          parse

          #ファイルのクローズ
          io.close

          return root.document
        end

        def create_element_pattern
          @rx_document = @root.document

          while (@res = @pattern.match(@rx_document)) || @cnt > ZERO

            if @res then

              if @cnt > ZERO then

                @rx_document2 = @res.post_match

                @res = @pattern_2.match(@rx_document)

                if @res then

                  @rx_document = @res.post_match

                  if @rx_document2.length > @rx_document.length then

                    @sbuf << @pattern_cc_1_2

                    @cnt += ONE

                    @rx_document = @rx_document2
                  else

                    @cnt -= ONE

                    if @cnt != ZERO then
                      @sbuf << @pattern_cc_2_1
                    else
                      @sbuf << @pattern_cc_2_2
                      break
                    end

                  end
                else

                  @sbuf << @pattern_cc_1_2

                  @cnt += ONE

                  @rx_document = @rx_document2
                end
              else
                @rx_document = @res.post_match

                @sbuf << @pattern_cc_1_1

                @cnt += ONE
              end
            else

              if @cnt == ZERO then
                break
              end

              @res = @pattern_2.match(@rx_document)

              if @res then

                @cnt -= ONE

                if @cnt != ZERO then
                  @sbuf << @pattern_cc_2_1
                else
                  @sbuf << @pattern_cc_2_2
                  break
                end

                @rx_document = @res.post_match
              else
                break
              end

            end

            @pattern = @pattern_1b
          end
        end
      end
    end

    module Util

      #
      # Pattern Cache Class (パターンキャッシュクラス)
      #
      class PatternCache
        @@regex_cache = Hash.new

        #
        # intializer (イニシャライザ)
        #
        def initialize
        end


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
              if @@regex_cache[args[0].to_sym] then
                @@regex_cache[args[0].to_sym]
              else
                @@regex_cache[args[0].to_sym] = Regexp.new(args[0], Regexp::MULTILINE)
              end
            when TWO
              #get_2(args[0], args[1])
              if @@regex_cache[args[0].to_sym] then
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
        #  ##if pattern == nil then
        #  #if regex.kind_of?(String) then
        #  if !@@regex_cache[regex.to_sym] then
        #    #pattern = Regexp.new(regex)
        #    #@@regex_cache[regex] = pattern
        #    if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
        #      @@regex_cache[regex.to_sym] = Regexp.new(regex, Regexp::MULTILINE)
        #    else
        #      @@regex_cache[regex.to_sym] = Regexp.new(regex, Regexp::MULTILINE,E_UTF8)
        #    end
        #  end
        #
        #  #return pattern
        #  @@regex_cache[regex.to_sym]
        #  ##elsif regex.kind_of?(Symbol) then
        #  ##  if !@@regex_cache[regex] then
        #  ##    if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
        #  ##      @@regex_cache[regex.object_id] = Regexp.new(regex.to_s, Regexp::MULTILINE)
        #  ##    else
        #  ##      @@regex_cache[regex.object_id] = Regexp.new(regex.to_s, Regexp::MULTILINE,E_UTF8)
        #  ##    end
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
        #  ##if pattern == nil then
        #  #if regex.kind_of?(String) then
        #  if !@@regex_cache[regex.to_sym] then
        #    #pattern = Regexp.new(regex)
        #    #@@regex_cache[regex] = pattern
        #    @@regex_cache[regex.to_sym] = Regexp.new(regex, option,E_UTF8)
        #  end
        #
        #  #return pattern
        #  @@regex_cache[regex.to_sym]
        #  ##elsif regex.kind_of?(Symbol) then
        #  ##  if !@@regex_cache[regex] then
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
    module Html

      #
      # HTML parser (HTMLパーサ)
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

        #if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
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
        #end

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @doc_type = Parser::HTML
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
        end

        private :initialize_0

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
          analyze_ml()
        end

        #
        # read file , set in parser (ファイルを読み込み、パーサにセットする)
        # @param [String] filePath file path (ファイルパス)
        # @param [String] enc character encoding (エンコーディング)
        #
        #def read(file_path, enc)
        #  super(file_path, enc)
        #end

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml()
          #content-typeの取得
          analyze_content_type()
          #改行コードの取得
          analyze_kaigyo_code()

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
          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_ then
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          if @elm_ then
            @root.content_type = @elm_.attr(CONTENT)
          else
            @root.content_type = EMPTY
          end
        end

        private :analyze_content_type

        #
        # analuze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_kaigyo_code()
          #改行コード取得
          #@pattern = Regexp.new(KAIGYO_CODE)
          #@res = @pattern.match(@root.document)

          #if @res then
          #  @root.kaigyo_code = @res[0]
          #  puts "test"
          #  puts @res[0]
          #end

          for a in KAIGYO_CODE
            if @root.document.include?(a) then
              @root.kaigyo_code = a
            end
          end

        end

        private :analyze_kaigyo_code

        #
        # get element using tag name (要素のタグ名で検索し、要素を取得する)
        # @param [String] tag tag name (タグ名)
        # @return [Meteor::Element] element (要素)
        #
        def element_1(tag)
          @_tag = Regexp.quote(tag)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(@@match_tag, tag) then
            #空要素検索用パターン
            @pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_1_4_2
            #@pattern_cc = "<#{@_tag}(|\\s[^<>]*)>"
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            @res = @pattern.match(@root.document)
            if @res then
              element_without_1(tag)
            else
              puts Meteor::Exception::NoSuchElementException.new(tag).message
              @elm_ = nil
            end
          else
            #内容あり要素検索用パターン
            #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_1_1 << tag
            #@pattern_cc << TAG_SEARCH_1_2 << @_tag << TAG_CLOSE
            @pattern_cc = "<#{tag}(|\\s[^<>]*)>(((?!(#{tag}[^<>]*>)).)*)<\\/#{tag}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)
            #内容あり要素の場合
            if @res then
              element_with_1(tag)
            else
              puts Meteor::Exception::NoSuchElementException.new(tag).message
              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_1

        def element_without_1(tag)
          @elm_ = Meteor::Element.new(tag)
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
        # @param [String] tag tag name (タグ名)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @return [Meteor::Element] element (要素)
        #
        def element_3(tag, attr_name, attr_value)

          @_tag = Regexp.quote(tag)
          @_attr_name = Regexp.quote(attr_name)
          @_attr_value = Regexp.quote(attr_value)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(@@match_tag, tag) then
            #空要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_2_4_3
            @pattern_cc = "<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)
            if @res then
              element_without_3(tag)
            else
              puts Meteor::Exception::NoSuchElementException.new(tag, attr_name, attr_value).message
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_2_2 << @_tag
            #@pattern_cc << TAG_SEARCH_1_2 << @_tag << TAG_CLOSE
            @pattern_cc = "<#{@_tag}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_tag}[^<>]*>)).)*)<\\/#{@_tag}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)

            if !@res && !is_match(@@match_tag_sng, tag) then
              @res = element_with_3_2
            end

            if @res then
              element_with_3_1(tag)
            else
              puts Meteor::Exception::NoSuchElementException.new(tag, attr_name, attr_value).message
              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_3

        def element_without_3(tag)
          element_without_3_1(tag, TAG_SEARCH_NC_2_4_3)
        end

        private :element_without_3

        #
        # get element using attribute(name="value") (属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @return [Meteor::Element] element (要素)
        #
        def element_2(attr_name, attr_value)
          @_attr_name = Regexp.quote(attr_name)
          @_attr_value = Regexp.quote(attr_value)

          #@pattern_cc = '' << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value
          #@pattern_cc << TAG_SEARCH_2_4_4
          @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
          @res = @pattern.match(@root.document)

          if @res then
            element_3(@res[1], attr_name, attr_value)
          else
            puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
            @elm_ = nil
          end

          @elm_
        end

        private :element_2

        #
        # get element using tag name and attribute1,2(name="value") (要素のタグ名と属性1・属性2(属性名="属性値")で検索し、要素を取得する)
        # @param [String] tag tag name (タグ名)
        # @param [String] attr_name1 attribute name1 (属性名1)
        # @param [String] attr_value1 attribute value1 (属性値1)
        # @param [String] attr_name2 attribute name2 (属性名2)
        # @param [String] attr_value2 attribute value2 (属性値2)
        # @return [Meteor::Element] element (要素)
        #
        def element_5(tag, attr_name1, attr_value1, attr_name2, attr_value2)

          @_tag = Regexp.quote(tag)
          @_attr_name1 = Regexp.quote(attr_name1)
          @_attr_value1 = Regexp.quote(attr_value1)
          @_attr_name2 = Regexp.quote(attr_name2)
          @_attr_value2 = Regexp.quote(attr_value2)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(@@match_tag, tag) then
            #空要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_4_3_2
            @pattern_cc = "<#{@_tag}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)

            if @res then
              element_without_5(tag)
            else
              puts Meteor::Exception::NoSuchElementException.new(tag, attr_name1, attr_value1, attr_name2, attr_value2).message
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_tag << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_2_2 << @_tag
            #@pattern_cc << TAG_SEARCH_1_2 << @_tag << TAG_CLOSE
            @pattern_cc = "<#{@_tag}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_tag}[^<>]*>)).)*)<\\/#{@_tag}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)

            if !@res && !is_match(@@match_tag_sng, tag) then
              @res = element_with_5_2
            end

            if @res then
              element_with_5_1(tag)
            else
              puts Meteor::Exception::NoSuchElementException.new(tag, attr_name1, attr_value1, attr_name2, attr_value2).message
              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_5

        def element_without_5(tag)
          element_without_5_1(tag, TAG_SEARCH_NC_2_4_3_2)
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
          @_attr_name1 = Regexp.quote(attr_name1)
          @_attr_value1 = Regexp.quote(attr_value1)
          @_attr_name2 = Regexp.quote(attr_name2)
          @_attr_value2 = Regexp.quote(attr_value2)

          #@pattern_cc = '' << TAG_SEARCH_3_1_2_2 << @_attr_name1 << ATTR_EQ << @_attr_value1
          #@pattern_cc << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ << @_attr_value2
          #@pattern_cc << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ << @_attr_value2
          #@pattern_cc << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ << @_attr_value1
          #@pattern_cc << TAG_SEARCH_2_4_3_2
          @pattern_cc = "<([^<>\"]*)\\s([^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

          @res = @pattern.match(@root.document)

          if @res then
            element_5(@res[1], attr_name1, attr_value1, attr_name2, attr_value2)
          else
            puts Meteor::Exception::NoSuchElementException.new(attr_name1, attr_value1, attr_name2, attr_value2).message
            @elm_ = nil
          end

          @elm_
        end

        private :element_4

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_selected_m, @@pattern_selected_r)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_multiple_m, @@pattern_multiple_r)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_disabled_m, @@pattern_disabled_r)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_checked_m, @@pattern_checked_r)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_readonly_m, @@pattern_readonly_r)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def edit_attrs_5(elm, attr_name, attr_value, match_p, replace)

          if true.equal?(attr_value) || is_match(TRUE, attr_value) then
            @res = match_p.match(elm.attributes)

            if !@res then
              if !EMPTY.eql?(elm.attributes) && !EMPTY.eql?(elm.attributes.strip) then
                elm.attributes = '' << SPACE << elm.attributes.strip
              else
                elm.attributes = ''
              end
              elm.attributes << SPACE << attr_name
              #else
            end
          elsif false.equal?(attr_value) || is_match(FALSE, attr_value) then
            elm.attributes.sub!(replace, EMPTY)
          end

        end

        private :edit_attrs_5

        def edit_document_1(elm)
          edit_document_2(elm, TAG_CLOSE)
        end

        private :edit_document_1

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            get_attr_value_r(elm, @@pattern_selected_m)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, @@pattern_multiple_m)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            get_attr_value_r(elm, @@pattern_disabled_m)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            get_attr_value_r(elm, @@pattern_checked_m)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            get_attr_value_r(elm, @@pattern_readonly_m)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attr_value_(elm, TYPE_L)
            if !elm.type_value then
              elm.type_value = get_attr_value_(elm, TYPE_U)
            end
          end
          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, match_p)

          @res = match_p.match(elm.attributes)

          if @res then
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
          if !is_match(@@attr_logic, attr_name) then
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << ERASE_ATTR_1)
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
          #特殊文字の置換
          content.gsub!(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end

        def escape_content(content, elm)
          content.gsub!(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)

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
              when AND_3 then
                AND_1
              when QO_3 then
                DOUBLE_QUATATION
              when AP_3 then
                AP_1
              when GT_3 then
                GT_1
              when LT_3 then
                LT_1
              when NBSP_3 then
                SPACE
            end
          end
        end

        private :unescape

        def unescape_content(content, elm)
          content_ = unescape(content)

          if elm.cx || !is_match(@@match_tag_2, elm.name) then
            #「<br>」->「¥r?¥n」
            if content.include?(BR_2) then
              content_.gsub!(@@pattern_br_2, @root.kaigyo_code)
            end
          end

          content_
        end

        private :unescape_content

      end

      if RUBY_VERSION < RUBY_VERSION_1_9_0 then
        class ParserImpl
          @@pattern_and_1 = Regexp.new(AND_1)
          @@pattern_lt_1 = Regexp.new(LT_1)
          @@pattern_gt_1 = Regexp.new(GT_1)
          @@pattern_dq_1 = Regexp.new(DOUBLE_QUATATION)
          @@pattern_space_1 = Regexp.new(SPACE)
          @@pattern_br_1 = Regexp.new(BR_1)
          @@pattern_lt_2 = Regexp.new(LT_2)
          @@pattern_gt_2 = Regexp.new(GT_2)
          @@pattern_dq_2 = Regexp.new(QO_2)
          @@pattern_space_2 = Regexp.new(NBSP_2)
          @@pattern_and_2 = Regexp.new(AND_2)
          @@pattern_br_2 = Regexp.new(BR_2)

          def escape(content)
            #特殊文字の置換
            #「&」->「&amp;」
            if content.include?(AND_1) then
              content.gsub!(@@pattern_and_1, AND_2)
            end
            #「<」->「&lt;」
            if content.include?(LT_1) then
              content.gsub!(@@pattern_lt_1, LT_2)
            end
            #「>」->「&gt;」
            if content.include?(GT_1) then
              content.gsub!(@@pattern_gt_1, GT_2)
            end
            #「"」->「&quotl」
            if content.include?(DOUBLE_QUATATION) then
              content.gsub!(@@pattern_dq_1, QO_2)
            end
            #「 」->「&nbsp;」
            if content.include?(SPACE) then
              content.gsub!(@@pattern_space_1, NBSP_2)
            end

            content
          end

          def escape_content(content, elm)
            content = escape(content)

            if elm.cx || !is_match(@@match_tag_2, elm.name) then
              #「¥r?¥n」->「<br>」
              content.gsub!(@@pattern_br_1, BR_2)
            end

            content
          end
        end
      #else
      #  class ParserImpl
      #    #if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
      #    TABLE_FOR_ESCAPE_ = {
      #        '&' => '&amp;',
      #        '"' => '&quot;',
      #        '\'' => '&apos;',
      #        '<' => '&lt;',
      #        '>' => '&gt;',
      #        ' ' => '&nbsp;',
      #    }
      #
      #    TABLE_FOR_ESCAPE_CONTENT_ = {
      #        '&' => '&amp;',
      #        '"' => '&quot;',
      #        '\'' => '&apos;',
      #        '<' => '&lt;',
      #        '>' => '&gt;',
      #        ' ' => '&nbsp;',
      #        "\r\n" => '<br>',
      #        "\r" => '<br>',
      #        "\n" => '<br>',
      #    }
      #
      #    PATTERN_ESCAPE = "[&\"'<> ]"
      #    PATTERN_ESCAPE_CONTENT = "[&\"'<> \\n]"
      #
      #    @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
      #    @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)
      #    @@pattern_br_2 = Regexp.new(BR_2)
      #    #end
      #  end
      end

    end

    module Xhtml

      #
      # XHTML parser (XHTMLパーサ)
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

        #if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
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
        #end

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @doc_type = Parser::XHTML
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
        end

        private :initialize_0

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
          analyze_ml()
        end

        #
        # read file , set in parser (ファイルを読み込み、パーサにセットする)
        # @param file_path file path (ファイルパス)
        # @param enc character encoding (エンコーディング)
        #
        #def read(file_path, enc)
        #  super(file_path, enc)
        #end

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml()
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
        def content_type()
          @root.content_type
        end

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_ then
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          if @elm_ then
            @root.content_type = @elm_.attr(CONTENT)
          else
            @root.content_type = EMPTY
          end
        end

        private :analyze_content_type

        #
        # analyze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_kaigyo_code()
          #改行コード取得
          #@pattern = Regexp.new(KAIGYO_CODE)
          #@res = @pattern.match(@root.document)

          #if @res then
          #  @root.kaigyo_code = @res[0]
          #end

          for a in KAIGYO_CODE
            if @root.document.include?(a) then
              @root.kaigyo_code = a
            end
          end
        end

        private :analyze_kaigyo_code

        def edit_attrs_(elm, attr_name, attr_value)

          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            edit_attrs_5(elm, attr_value, @@pattern_selected_m, @@pattern_selected_r, SELECTED_U)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_multiple_m, @@pattern_multiple_r, MULTIPLE_U)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            edit_attrs_5(elm, attr_value, @@pattern_disabled_m, @@pattern_disabled_r, DISABLED_U)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            edit_attrs_5(elm, attr_value, @@pattern_checked_m, @@pattern_checked_r, CHECKED_U)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            edit_attrs_5(elm, attr_value, @@pattern_readonly_m, @@pattern_readonly_r, READONLY_U)
          else
            super(elm, attr_name, attr_value)
          end

        end

        private :edit_attrs_

        def edit_attrs_5(elm, attr_value, match_p, replace_regex, replace_update)

          #attr_value = escape(attr_value)

          if true.equal?(attr_value) || is_match(TRUE, attr_value) then

            @res = match_p.match(elm.attributes)

            if !@res then
              #属性文字列の最後に新規の属性を追加する
              if elm.attributes != EMPTY then
                elm.attributes = '' << SPACE << elm.attributes.strip
                #else
              end
              elm.attributes << SPACE << replace_update
            else
              #属性の置換
              elm.attributes.gsub!(replace_regex, replace_update)
            end
          elsif false.equal?(attr_value) || is_match(FALSE, attr_value) then
            #attr_name属性が存在するなら削除
            #属性の置換
            elm.attributes.gsub!(replace_regex, EMPTY)
          end

        end

        private :edit_attrs_5

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            get_attr_value_r(elm, attr_name, @@pattern_selected_m1)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_multiple_m1)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            get_attr_value_r(elm, attr_name, @@pattern_disabled_m1)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            get_attr_value_r(elm, attr_name, @@pattern_checked_m1)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            get_attr_value_r(elm, attr_name, @@pattern_readonly_m1)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attr_value(elm, TYPE_L)
            if !elm.type_value then
              elm.type_value = get_attr_value(elm, TYPE_U)
            end
          end
          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, attr_name, match_p)

          @res = match_p.match(elm.attributes)

          if @res then
            if @res[1] then
              if attr_name == @res[1] then
                TRUE
              else
                @res[1]
              end
            elsif @res[2] then
              if attr_name == @res[2] then
                TRUE
              else
                @res[2]
              end
            elsif @res[3] then
              if attr_name == @res[3] then
                TRUE
              else
                @res[3]
              end
            elsif @res[4] then
              if attr_name == @res[4] then
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
            if is_match(@@attr_logic, a) && a==b then
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
          #特殊文字の置換
          content.gsub!(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end

        def escape_content(content, elm)
          content.gsub!(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)

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
              when AND_3 then
                AND_1
              when QO_3 then
                DOUBLE_QUATATION
              when AP_3 then
                AP_1
              when GT_3 then
                GT_1
              when LT_3 then
                LT_1
              when NBSP_3 then
                SPACE
            end
          end
        end

        private :unescape

        def unescape_content(content, elm)
          content_ = unescape(content)

          if elm.cx || !is_match(@@match_tag_2, elm.name) then
            #「<br>」->「¥r?¥n」
            if content.include?(BR_2) then
              content_.gsub!(@@pattern_br_2, @root.kaigyo_code)
            end
          end

          content_
        end

        private :unescape_content

      end

      if RUBY_VERSION < RUBY_VERSION_1_9_0 then
        class ParserImpl
          @@pattern_and_1 = Regexp.new(AND_1)
          @@pattern_lt_1 = Regexp.new(LT_1)
          @@pattern_gt_1 = Regexp.new(GT_1)
          @@pattern_dq_1 = Regexp.new(DOUBLE_QUATATION)
          @@pattern_ap_1 = Regexp.new(AP_1)
          @@pattern_space_1 = Regexp.new(SPACE)
          @@pattern_br_1 = Regexp.new(BR_1)
          @@pattern_lt_2 = Regexp.new(LT_2)
          @@pattern_gt_2 = Regexp.new(GT_2)
          @@pattern_dq_2 = Regexp.new(QO_2)
          @@pattern_ap_2 = Regexp.new(AP_2)
          @@pattern_space_2 = Regexp.new(NBSP_2)
          @@pattern_and_2 = Regexp.new(AND_2)
          @@pattern_br_2 = Regexp.new(BR_3)

          def escape(content)
            #特殊文字の置換
            #「&」->「&amp;」
            if content.include?(AND_1) then
              content.gsub!(@@pattern_and_1, AND_2)
            end
            #「<」->「&lt;」
            if content.include?(LT_1) then
              content.gsub!(@@pattern_lt_1, LT_2)
            end
            #「>」->「&gt;」
            if content.include?(GT_1) then
              content.gsub!(@@pattern_gt_1, GT_2)
            end
            #「"」->「&quotl」
            if content.include?(DOUBLE_QUATATION) then
              content.gsub!(@@pattern_dq_1, QO_2)
            end
            #「'」->「&apos;」
            if content.include?(AP_1) then
              content.gsub!(@@pattern_ap_1, AP_2)
            end
            #「 」->「&nbsp;」
            if content.include?(SPACE) then
              content.gsub!(@@pattern_space_1, NBSP_2)
            end

            content
          end

          def escape_content(content, elm)
            content = escape(content)

            if elm.cx || !is_match(@@match_tag_2, elm.name) then
              #「¥r?¥n」->「<br>」
              content.gsub!(@@pattern_br_1, BR_2)
            end

            content
          end

        end
      #else
      #  class ParserImpl
      #    #if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
      #    TABLE_FOR_ESCAPE_ = {
      #        '&' => '&amp;',
      #        '"' => '&quot;',
      #        '\'' => '&apos;',
      #        '<' => '&lt;',
      #        '>' => '&gt;',
      #        ' ' => '&nbsp;',
      #    }
      #
      #    TABLE_FOR_ESCAPE_CONTENT_ = {
      #        '&' => '&amp;',
      #        '"' => '&quot;',
      #        '\'' => '&apos;',
      #        '<' => '&lt;',
      #        '>' => '&gt;',
      #        ' ' => '&nbsp;',
      #        "\r\n" => '<br/>',
      #        "\r" => '<br/>',
      #        "\n" => '<br/>',
      #    }
      #
      #    PATTERN_ESCAPE = '[&"\'<> ]'
      #    PATTERN_ESCAPE_CONTENT = '[&"\'<> \\n]'
      #    @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
      #    @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)
      #    #end
      #  end
      end
    end

    module Html5

      #
      # HTML5 parser (HTML5パーサ)
      #
      class ParserImpl < Meteor::Ml::Html::ParserImpl

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
          @doc_type = Parser::HTML5
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
          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_ then
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          if @elm_ then
            @root.content_type = @elm_.attr(CONTENT)
            @root.charset = @elm_.attr(CHARSET)
            if !@root.charset then
              @root.charset = UTF8
            end
          else
            @root.content_type = EMPTY
            @root.charset = UTF8
          end
        end

        private :analyze_content_type

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_selected_m, @@pattern_selected_r)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_multiple_m, @@pattern_multiple_r)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_disabled_m, @@pattern_disabled_r)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_checked_m, @@pattern_checked_r)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_readonly_m, @@pattern_readonly_r)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name) then
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_required_m, @@pattern_required_r)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            get_attr_value_r(elm, @@pattern_selected_m)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, @@pattern_multiple_m)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            get_attr_value_r(elm, @@pattern_disabled_m)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            get_attr_value_r(elm, @@pattern_checked_m)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            get_attr_value_r(elm, @@pattern_readonly_m)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name) then
            get_attr_value_r(elm, @@pattern_required_m)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

      end

    end

    module Xhtml5

      #
      # XHTML5 parser (XHTML5パーサ)
      #
      class ParserImpl < Meteor::Ml::Xhtml::ParserImpl

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
          @doc_type = Parser::XHTML5
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
          element_3(META_S, HTTP_EQUIV, CONTENT_TYPE)

          if !@elm_ then
            element_3(META, HTTP_EQUIV, CONTENT_TYPE)
          end

          if @elm_ then
            @root.content_type = @elm_.attr(CONTENT)
            @root.charset = @elm_.attr(CHARSET)
            if !@root.charset then
              @root.charset = UTF8
            end
          else
            @root.content_type = EMPTY
            @root.charset = UTF8
          end
        end

        private :analyze_content_type

        def edit_attrs_(elm, attr_name, attr_value)

          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            edit_attrs_5(elm, attr_value, @@pattern_selected_m, @@pattern_selected_r, SELECTED_U)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_multiple_m, @@pattern_multiple_r, MULTIPLE_U)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            edit_attrs_5(elm, attr_value, @@pattern_disabled_m, @@pattern_disabled_r, DISABLED_U)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            edit_attrs_5(elm, attr_value, @@pattern_checked_m, @@pattern_checked_r, CHECKED_U)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            edit_attrs_5(elm, attr_value, @@pattern_readonly_m, @@pattern_readonly_r, READONLY_U)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name) then
            edit_attrs_5(elm, attr_value, @@pattern_required_m, @@pattern_required_r, REQUIRED_U)
          else
            super(elm, attr_name, attr_value)
          end

        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION, elm.name) then
            get_attr_value_r(elm, attr_name, @@pattern_selected_m1)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_multiple_m1)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            get_attr_value_r(elm, attr_name, @@pattern_disabled_m1)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT, elm.name) && is_match(RADIO, get_type(elm)) then
            get_attr_value_r(elm, attr_name, @@pattern_checked_m1)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA, elm.name) || (is_match(INPUT, elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            get_attr_value_r(elm, attr_name, @@pattern_readonly_m1)
          elsif is_match(REQUIRED, attr_name) && is_match(REQUIRE_ELEMENT, elm.name) then
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

        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt);'

        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)

        #if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
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
        end

        private :initialize_0

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
        # set document in parser (ドキュメントをパーサにセットする)
        # @param [String] document document (ドキュメント)
        #
        #def parse(document)
        #  @root.document = document
        #end

        #
        # read file , set in parser (ファイルを読み込み、パーサにセットする)
        # @param file_path file path (ファイルパス)
        # @param enc character encoding (エンコーディング)
        #
        #def read(file_path, enc)
        #  super(file_path, enc)
        #end

        # get content type (コンテントタイプを取得する)
        # @return [Streing] content type (コンテントタイプ)
        #
        def content_type()
          @root.content_type
        end


        def escape(content)
          #特殊文字の置換
          content.gsub!(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end


        private :escape

        def escape_content(*args)
          escape(args[0])
        end

        private :escape_content

        def unescape(content)
          #特殊文字の置換
          #「<」<-「&lt;」
          #「>」<-「&gt;」
          #「"」<-「&quot;」
          #「'」<-「&apos;」
          #「&」<-「&amp;」
          content.gsub(@@pattern_unescape) do
            case $1
              when AND_3 then
                AND_1
              when QO_3 then
                DOUBLE_QUATATION
              when AP_3 then
                AP_1
              when GT_3 then
                GT_1
              when LT_3 then
                LT_1
            end
          end
        end

        private :unescape

        def unescape_content(*args)
          unescape(args[0])
        end

        private :unescape_content

      end

      if RUBY_VERSION < RUBY_VERSION_1_9_0 then
        class ParserImpl
          @@pattern_and_1 = Regexp.new(AND_1)
          @@pattern_lt_1 = Regexp.new(LT_1)
          @@pattern_gt_1 = Regexp.new(GT_1)
          @@pattern_dq_1 = Regexp.new(DOUBLE_QUATATION)
          @@pattern_ap_1 = Regexp.new(AP_1)
          @@pattern_lt_2 = Regexp.new(LT_2)
          @@pattern_gt_2 = Regexp.new(GT_2)
          @@pattern_dq_2 = Regexp.new(QO_2)
          @@pattern_ap_2 = Regexp.new(AP_2)
          @@pattern_and_2 = Regexp.new(AND_2)

          def escape(content)
            #特殊文字の置換
            #「&」->「&amp;」
            if content.include?(AND_1) then
              content.gsub!(@@pattern_and_1, AND_2)
            end
            #「<」->「&lt;」
            if content.include?(LT_1) then
              content.gsub!(@@pattern_lt_1, LT_2)
            end
            #「>」->「&gt;」
            if content.include?(GT_1) then
              content.gsub!(@@pattern_gt_1, GT_2)
            end
            #「"」->「&quot;」
            if content.include?(DOUBLE_QUATATION) then
              content.gsub!(@@pattern_dq_1, QO_2)
            end
            #「'」->「&apos;」
            if content.include?(AP_1) then
              content.gsub!(@@pattern_ap_1, AP_2)
            end

            content
          end
        end
      #else
      #  class ParserImpl
      #    #if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
      #    TABLE_FOR_ESCAPE_ = {
      #        '&' => '&amp;',
      #        '"' => '&quot;',
      #        '\'' => '&apos;',
      #        '<' => '&lt;',
      #        '>' => '&gt;',
      #    }
      #    PATTERN_ESCAPE = '[&\"\'<>]'
      #    @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
      #
      #    #end
      #  end
      end
    end
  end

end