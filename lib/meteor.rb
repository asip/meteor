# -* coding: UTF-8 -*-
# Meteor -  A lightweight (X)HTML & XML parser
#
# Copyright (C) 2008 Yasumasa Ashida.
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
# @version 0.9.0.7
#
if RUBY_VERSION < '1.9.0' then
  require 'kconv'
end


module Meteor

  VERSION = "0.9.0.7"
  
  #
  # 要素クラス
  #
  class Element

    #
    # イニシャライザ
    # @param [Array] args 引数配列
    #
    def initialize(*args)
      case args.length
      when 1
        if args[0].kind_of?(String) then
          initialize_s(args[0])
        elsif args[0].kind_of?(Meteor::Element)
          initialize_e(args[0])
        else
          raise ArgumentError
        end
      else
        raise ArgumentError
      end
    end

    #
    # イニシャライザ
    # @param [String] name タグ名
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
      @arguments = AttributeMap.new
    end

    #
    # イニシャライザ
    # @param [Meteor::Element] elm 要素
    #
    def initialize_e(elm)
      @name = elm.name
      @attributes = String.new(elm.attributes)
      @mixed_content = String.new(elm.mixed_content)
      @pattern = String.new(elm.pattern)
      @document = String.new(elm.document)
      @empty = elm.empty
      @cx = elm.cx
      @mono = elm.mono
      @parent = elm.parent
      @parser = elm.parser
      @arguments = AttributeMap.new(elm.arguments)
    end
    
    attr_accessor :name
    attr_accessor :attributes
    attr_accessor :mixed_content
    attr_accessor :pattern
    attr_accessor :document
    attr_accessor :empty
    attr_accessor :cx
    attr_accessor :mono
    attr_accessor :parent
    attr_accessor :parser
    attr_accessor :type_value
    attr_accessor :arguments
    
    #
    # 属性を編集する or 属性の値を取得する
    # 
    # @param [Array] args 引数配列
    # @return [String] 属性値
    #
    def attribute(*args)
      @parser.attribute(self,*args)
    end

    #
    # 属性マップを取得する
    # 
    # @return [Meteor::AttributeMap] 属性マップ
    #
    def attributeMap
      @parser.attributeMap(self)
    end
    
    #
    # 内容をセットする or 内容を取得する
    # 
    # @param [Array] args 引数配列
    # @return [String] 内容
    #
    def content(*args)
      @parser.content(self,*args)
    end

    #
    # 属性を編集するor内容をセットする
    # 
    # @param [String] name 属性の名前
    # @param [String] value 属性の値or内容
    #
    def []=(name,value)
      if !name.kind_of?(String) || name != ':content' then
        attribute(name,value)
      else
        content(value)
      end
    end

    #
    # 属性の値or内容を取得する
    # 
    # @param [String] name 属性の名前
    # @return [String] 属性の値or内容
    #
    def [](name)
      if !name.kind_of?(String) || name != ':content' then
        attribute(name)
      else
        content()
      end
    end
    
    #
    # 属性を削除する
    # 
    # @param args 引数配列
    #
    def removeAttribute(*args)
      @parser.removeAttribute(self,*args)
    end
    
    #
    # 要素を削除する
    #
    def remove
      @parser.removeElement(self)
    end
    
  end

  #
  # ルート要素クラス
  #
  class RootElement

    #
    # イニシャライザ
    #
    def initialize()
      #コンテントタイプ
      @contentType = ''
      #改行コード
      @kaigyoCode = ''
      #文字コード
      @characterEncoding=''

      #フックドキュメント
      @hookDocument =''
      #フック判定フラグ
      #@hook = false
      #単一要素フック判定フラグ
      #@monoHook = false
      #要素
      #@element = nil
      #変更可能要素
      #@mutableElement = nil
    end

    attr_accessor :contentType
    attr_accessor :kaigyoCode
    attr_accessor :characterEncoding
    attr_accessor :hookDocument
    attr_accessor :hook;
    attr_accessor :monoHook
    attr_accessor :element
    attr_accessor :mutableElement
    attr_accessor :document 
  end

  #
  # 属性マップクラス
  #
  class AttributeMap
    
    def initialize(*args)
      case args.length
      when 0
        initialize_0
      when 1
        initialize_1(args[0])
      else
        raise ArgumentError
      end
    end
    
    #
    # イニシャライザ
    #
    def initialize_0
      @map = Hash.new
      if RUBY_VERSION < '1.9.0'
        @names = Array.new
      end
      @recordable = false
    end

    #
    # イニシャライザ
    #
    def initialize_1(attrMap)
      #@map = Marshal.load(Marshal.dump(attrMap.map))
      @map = attrMap.map.dup
      if RUBY_VERSION < '1.9.0'
        @names = Array.new(attrMap.names)
      end
      @recordable = attrMap.recordable
    end
    
    #
    # 属性名と属性値を対としてセットする
    # 
    # @param [String] name 属性名
    # @param [String] value 属性値
    #
    def store(name,value)

      if !@map[name] then
        attr = Attribute.new
        attr.name = name
        attr.value = value
        if @recordable then
          attr.changed = true
          attr.removed = false
        end
        @map[name] = attr
        if RUBY_VERSION < "1.9.0"
          @names << name
        end
      else
        attr = @map[name]
        if @recordable && attr.value != value then
          attr.changed = true
          attr.removed = false
        end
        attr.value = value
        #@map[name] = attr
      end
    end

    #
    # 属性名配列を取得する
    # 
    # @return [Array] 属性名配列
    #
    def names
      if RUBY_VERSION < "1.9.0"
        @names
      else
        @map.keys
      end
    end

    #
    # 属性名で属性値を取得する
    # 
    # @param [String] name 属性名
    # @return [String] 属性値
    #
    def fetch(name)
      if @map[name] && !@map[name].removed then
        @map[name].value
      end
    end

    #
    # 属性名に対応した属性を削除する
    #
    # @param name 属性名
    #
    def delete(name)
      if @map[name] && @recordable then
        @map[name].removed = true
        @map[name].changed = false
      end
    end
    
    #
    # 属性名で属性の変更状況を取得する
    # 
    # @return [TrueClass][FalseClass] 属性の変更状況
    #
    def changed(name)
      if @map[name] then
        @map[name].changed
      end
    end

    #
    # 属性名で属性の削除状況を取得する
    # 
    # @return [TrueClass][FalseClass] 属性の削除状況
    #
    def removed(name)
      if @map[name] then
        @map[name].removed
      end
    end
    
    attr_accessor :map
    attr_accessor :recordable

    #
    # 属性名と属性値を対としてセットする
    # 
    # @param [String] name 属性名
    # @param [String] value 属性値
    #
    def [](name,value)
      store(name,value)
    end

    #
    # 属性名で属性値を取得する
    # 
    # @param [String] name 属性名
    # @return [String] 属性値
    #
    def [](name)
      fetch(name)
    end
  end

  #
  # 属性クラス
  #
  class Attribute

    #
    # イニシャライザ
    #
    def initialize
      #@name = nil
      #@value = nil
      #@changed = false
      #@removed = false
    end

    attr_accessor :name
    attr_accessor :value
    attr_accessor :changed
    attr_accessor :removed

  end

  #
  # パーサ共通クラス
  #
  class Parser
    HTML = 0
    XHTML = 1
    XML = 2
  end

  #
  # パーサファクトリクラス
  #
  class ParserFactory

    #
    # パーサファクトリを生成する
    # 
    # @param [Array] args 引数配列
    # @return [Meteor::ParserFactory] パーサファクトリ
    #
    def self.build(*args)
      case args.length
      when 3
        build_3(args[0],args[1],args[2])
      when 2
        build_2(args[0],args[1])
      else
        raise ArgumentError
      end
    end

    #
    # パーサファクトリを生成する
    # 
    # @param [Fixnum] type パーサのタイプ
    # @param [String] path ファイルパス
    # @param [String] encoding エンコーディング
    # @return [Meteor::ParserFactory] パーサファクトリ
    #
    def self.build_3(type,path,encoding)
      psf = ParserFactory.new

      case type
      when Parser::HTML then
        html = Meteor::Core::Html::ParserImpl.new()
        html.read(path, encoding)
        psf.setParser(html)
      when Parser::XHTML then
        xhtml = Meteor::Core::Xhtml::ParserImpl.new()
        xhtml.read(path, encoding)
        psf.setParser(xhtml)
      when Parser::XML then
        xml = Meteor::Core::Xml::ParserImpl.new()
        xml.read(path, encoding)
        psf.setParser(xml)
      end
      
      psf
    end
    #protected :build_3
    
    #
    # パーサファクトリを生成する
    # 
    # @param [Fixnum] type パーサのタイプ
    # @param [String] document ドキュメント
    # @return [Meteor::ParserFactory] パーサファクトリ
    #
    def self.build_2(type,document)
      psf = ParserFactory.new

      case type
      when Parser::HTML then
        html = Meteor::Core::Html::ParserImpl.new()
        html.parse(document)
        psf.setParser(html)
      when Parser::XHTML then
        xhtml = Meteor::Core::Xhtml::ParserImpl.new()
        xhtml.parse(document)
        psf.setParser(xhtml)
      when Parser::XML then
        xml = Meteor::Core::Xml::ParserImpl.new()
        xml.parse(document)
        psf.setParser(xml)
      end

      psf
    end
    #protected :build_2
    
    #
    # パーサをセットする
    # 
    # @param [Meteor::Parser] パーサ
    #
    def setParser(pif)
      @pif = pif
    end

    #
    # パーサを取得する
    # 
    # @return [Meteor::Parser] パーサ
    #
    def getParser

      if @pif.instance_of?(Meteor::Core::Html::ParserImpl) then
        Meteor::Core::Html::ParserImpl.new(@pif)
      elsif @pif.instance_of?(Meteor::Core::Xhtml::ParserImpl) then
        Meteor::Core::Xhtml::ParserImpl.new(@pif)
      elsif @pif.instance_of?(Meteor::Core::Xml::ParserImpl) then
        Meteor::Core::Xml::ParserImpl.new(@pif)
      end
    end

  end

  module Hook

    #
    # フッククラス
    #
    class Hooker

      #
      # イニシャライザ
      #
      def initialize
      end

      def doAction(elm,pif)
        #内容あり要素の場合
        if elm.empty then
          pif2 = pif.child(elm)
          execute(pif2)
          pif2.flush
        end
      end

      def execute(pif)
      end
    end

    #
    # ループフッククラス
    #
    class Looper

      #
      # イニシャライザ
      #
      def initialize
      end

      def doAction(elm,pif,list)
        #内容あり要素の場合
        if elm.empty then
          pif2 = pif.child(elm)

          list.each { |item|
            if pif2.rootElement.hook then
              pif2.rootElement.document = elm.mixed_content
            #elsif pif2.rootElement.monoHook then
            end
            execute(pif2,item)
          }
          pif2.flush
        end
      end

      def execute(pif,item)
      end
    end
  end

  module Core

    #
    # パーサコアクラス
    #
    class Kernel < Meteor::Parser

      EMPTY = ''
      SPACE = " "
      DOUBLE_QUATATION = "\""
      TAG_OPEN = "<"
      TAG_OPEN3 = "</"
      TAG_OPEN4 = "<\\\\/"
      TAG_CLOSE = ">"
      TAG_CLOSE2 = "\\/>"
      TAG_CLOSE3 = "/>"
      ATTR_EQ = "=\""
      #element
      #TAG_SEARCH_1_1 = "([^<>]*)>(((?!(<\\/"
      TAG_SEARCH_1_1 = "(\\s?[^<>]*)>(((?!("
      #TAG_SEARCH_1_2 = ")).)*)<\\/";
      TAG_SEARCH_1_2 = "[^<>]*>)).)*)<\\/"
      TAG_SEARCH_1_3 = "(\\s?[^<>]*)\\/>"
      #TAG_SEARCH_1_4 = "([^<>\\/]*)>"
      TAG_SEARCH_1_4 = "(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      TAG_SEARCH_1_4_2 = "(\\s[^<>]*)>"
      
      TAG_SEARCH_NC_1_1 = "\\s?[^<>]*>((?!("
      TAG_SEARCH_NC_1_2 = "[^<>]*>)).)*<\\/"
      TAG_SEARCH_NC_1_3 = "\\s?[^<>]*\\/>"
      TAG_SEARCH_NC_1_4 = "(?:\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      TAG_SEARCH_NC_1_4_2 = "\\s[^<>]*>"
      
      #TAG_SEARCH_2_1 = "\\s([^<>]*"
      TAG_SEARCH_2_1 = "(\\s[^<>]*"
      TAG_SEARCH_2_1_2 = "(\\s[^<>]*(?:"
      #TAG_SEARCH_2_2 = "\"[^<>]*)>(((?!(<\\/"
      TAG_SEARCH_2_2 = "\"[^<>]*)>(((?!("
      TAG_SEARCH_2_2_2 = "\")[^<>]*)>(((?!("
      TAG_SEARCH_2_3 = "\"[^<>]*)"
      TAG_SEARCH_2_3_2 = "\"[^<>]*)\\/>"
      TAG_SEARCH_2_3_2_2 = "\")[^<>]*)\\/>"
      #TAG_SEARCH_2_4 = "\"[^<>\\/]*>"
      TAG_SEARCH_2_4 = "(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      #TAG_SEARCH_2_4_2 = "\"[^<>\\/]*)>"
      TAG_SEARCH_2_4_2 = "(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"
      TAG_SEARCH_2_4_2_2 = "\")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))"
      TAG_SEARCH_2_4_2_3 = "\""
      TAG_SEARCH_2_4_3 = "\"[^<>]*)>"
      TAG_SEARCH_2_4_3_2 = "\")[^<>]*)>"
      TAG_SEARCH_2_4_4 = "\"[^<>]*>"

      TAG_SEARCH_2_6 = "\"[^<>]*"
      TAG_SEARCH_2_7 = "\"|"

      TAG_SEARCH_NC_2_1 = "\\s[^<>]*"
      TAG_SEARCH_NC_2_1_2 = "\\s[^<>]*(?:"
      TAG_SEARCH_NC_2_2 = "\"[^<>]*>((?!("
      TAG_SEARCH_NC_2_2_2 = "\")[^<>]*>((?!("
      TAG_SEARCH_NC_2_3 = "\"[^<>]*)"
      TAG_SEARCH_NC_2_3_2 = "\"[^<>]*\\/>"
      TAG_SEARCH_NC_2_3_2_2 = "\")[^<>]*\\/>"
      TAG_SEARCH_NC_2_4 = "(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      TAG_SEARCH_NC_2_4_2 = "(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      TAG_SEARCH_NC_2_4_2_2 = "\")(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      TAG_SEARCH_NC_2_4_2_3 = "\""
      TAG_SEARCH_NC_2_4_3 = "\"[^<>]*>"
      TAG_SEARCH_NC_2_4_3_2 = "\")[^<>]*>"
      TAG_SEARCH_NC_2_4_4 = "\"[^<>]*>"
      TAG_SEARCH_NC_2_6 = "\"[^<>]*"
      TAG_SEARCH_NC_2_7 = "\"|"
      
      TAG_SEARCH_3_1 = "<([^<>\"]*)\\s[^<>]*"
      TAG_SEARCH_3_1_2 = "<([^<>\"]*)\\s([^<>]*"
      TAG_SEARCH_3_1_2_2 = "<([^<>\"]*)\\s([^<>]*("

      TAG_SEARCH_3_2 = "\"[^<>]*\\/>"
      TAG_SEARCH_3_2_2 = "\"[^<>]*)\\/>"
      TAG_SEARCH_3_2_2_2 = "\")[^<>]*)\\/>"

      TAG_SEARCH_4_1 = "(\\s[^<>\\/]*)>("
      TAG_SEARCH_4_2 = ".*?<"
      #TAG_SEARCH_4_3 = "\\s[^<>\\/]*>"
      TAG_SEARCH_4_3 = "(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      TAG_SEARCH_4_4 = "<\\/"
      TAG_SEARCH_4_5 = ".*?<\/"
      TAG_SEARCH_4_6 = ".*?)<\/"
      #TAG_SEARCH_4_7 = "\"[^<>\\/]*)>("
      TAG_SEARCH_4_7 = "\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
      TAG_SEARCH_4_7_2 = "\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

      TAG_SEARCH_NC_3_1 = "<[^<>\"]*\\s[^<>]*"
      TAG_SEARCH_NC_3_1_2 = "<([^<>\"]*)\\s(?:[^<>]*"
      TAG_SEARCH_NC_3_1_2_2 = "<([^<>\"]*)\\s(?:[^<>]*("
      TAG_SEARCH_NC_3_2 = "\"[^<>]*\\/>"
      TAG_SEARCH_NC_3_2_2 = "\"[^<>]*)\\/>"
      TAG_SEARCH_NC_3_2_2_2 = "\")[^<>]*)\\/>"
      #TAG_SEARCH_NC_4_1 = "(?:\\s[^<>\\/]*)>("
      #TAG_SEARCH_NC_4_2 = ".*?<"
      #TAG_SEARCH_NC_4_3 = "(?:\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
      #TAG_SEARCH_NC_4_4 = "<\\/"
      #TAG_SEARCH_NC_4_5 = ".*?<\/"
      #TAG_SEARCH_NC_4_6 = ".*?<\/"
      #TAG_SEARCH_NC_4_7 = "\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
      #TAG_SEARCH_NC_4_7_2 = "\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
      
      #setAttribute
      SET_ATTR_1 = "=\"[^\"]*\""
      #getAttributeValue
      GET_ATTR_1 = "=\"([^\"]*)\""
      #attributeMap
      #todo
      GET_ATTRS_MAP = "([^\\s]*)=\"([^\"]*)\""
      #removeAttribute
      ERASE_ATTR_1 = "=\"[^\"]*\"\\s"

      #cxtag
      SEARCH_CX_1 = "<!--\\s@"
      SEARCH_CX_2 = "\\s([^<>]*id=\""
      SEARCH_CX_3 = "\"[^<>]*)-->(((?!(<!--\\s\\/@"
      SEARCH_CX_4 = ")).)*)<!--\\s\\/@"
      SEARCH_CX_5 = "\\s-->"
      SEARCH_CX_6 = "<!--\\s@([^<>]*)\\s[^<>]*id=\""

      #setElementToCXTag
      SET_CX_1 = "<!-- @"
      SET_CX_2 = "-->"
      SET_CX_3 = "<!-- /@"
      SET_CX_4 = " -->"

      #setMonoInfo
      SET_MONO_1 = "\\A[^<>]*\\Z"

      #clean
      CLEAN_1 = "<!--\\s@[^<>]*\\s[^<>]*(\\s)*-->"
      CLEAN_2 = "<!--\\s\\/@[^<>]*(\\s)*-->"
      #escape
      AND_1 = '&'
      AND_2 = '&amp;'
      LT_1 = '<'
      LT_2 = '&lt;'
      GT_1 = '>'
      GT_2 = '&gt;'
      QO_2 = '&quot;'
      AP_1 = '\''
      AP_2 = '&apos;'
      #EN_1 = "\\\\"
      EN_1 = "\\"
      #EN_2 = "\\\\\\\\"
      #DOL_1 = "\\\$"
      #DOL_2 = "\\\\\\$"
      #PLUS_1 = "\\\+"
      #PLUS_2 = "\\\\\\+"
      
      ESCAPE_ENTITY_REF = ''
      
      SUB_REGEX1 = "(\\\\*)\\\\([0-9]+)"
      SUB_REGEX2 = "\\1\\1\\\\\\\\\\2"
      SUB_REGEX3 = "\\1\\1\\1\\1\\\\\\\\\\\\\\\\\\2"
      
      @@pattern_get_attrs_map = Regexp.new(GET_ATTRS_MAP)

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
      
      @@pattern_sub_regex1 = Regexp.new(SUB_REGEX1)
      
      @@pattern_clean1 = Regexp.new(CLEAN_1)
      @@pattern_clean2 = Regexp.new(CLEAN_2)


      #
      # イニシャライザ
      # @param [Array] args 引数配列
      #
      def initialize(*args)
        #親要素
        #@parent = nil;

        #正規表現パターン
        #@pattern = nil
        #ルート要素
        @root = RootElement.new
        if RUBY_VERSION >= '1.9.0' then
          @e_cache = Hash.new()
        else
          @e_cache = Meteor::Core::Util::OrderHash.new
        end
        #@res = nil
        #@_attributes = nil
        #@_mixed_content = nil
        #@pattern_cc = nil
        #@pattern_cc_1 = nil
        #@pattern_cc_1b = nil
        #@pattern_cc_1_1 = nil
        #@pattern_cc_1_2 = nil
        #@pattern_cc_2 = nil
        #@pattern_cc_2_1 = nil
        #@pattern_cc_2_2 = nil
        #@pattern_2 = nil
        #@pattern_1 = nil
        #@pattern_1b = nil
        #@cnt = 0
        #@position = 0
        #@position2 = 0
        #@_elmName = nil
        #@_attrName = nil
        #@_attrValue = nil
        #@_attrName1 = nil
        #@_attrValue1 = nil
        #@_attrName2 = nil
        #@_attrValue2 = nil

        #@sbuf = nil;
        #@rx_document = nil;
        #@rx_document2 = nil;
      end

      #
      # ドキュメントをセットする
      # 
      # @param [String] doc ドキュメント
      #
      def document=(doc)
        @root.document = doc
      end

      #
      # ドキュメントを取得する
      # 
      # @return [String] ドキュメント
      #
      def document
        @root.document
      end

      attr_accessor :parent

      #
      # フックフラグをセットする
      # 
      # @param [TrueClass][FalseClass] hook フックフラグ
      #
      #def hook=(hook)
      #  @root.hook = hook
      #end

      #
      # フックフラグを取得する
      # 
      # @return [TrueClass][FalseClass] フックフラグ
      #
      #def hook
      #  @root.hook
      #end

      #
      # 単一要素フックフラグをセットする
      # 
      # @pamam [TrueClass][FalseClass] hook 単一要素フックフラグ
      #
      #def monoHook=(hook)
      #  @root.monoHook = hook
      #end

      #
      # 単一要素フックフラグを取得する
      # 
      # @return [TrueClass][FalseClass] 単一要素フックフラグ
      #
      #def monoHook
      #  @root.monoHook
      #end

      #
      # フックドキュメントをセットする
      # 
      # @param [String] hookDocument フックドキュメント
      #
      #def hookDocument=(hookDocument)
      #  @root.hookDocument = hookDocument
      #end

      #
      # フックドキュメントを取得する
      # 
      # @return [String] フックドキュメント
      #
      #def hookDocument
      #  @root.hookDocument
      #end

      #
      # 文字エンコーディングをセットする
      # 
      # @param [String] enc 文字エンコーディング
      #
      def characterEncoding=(enc)
        @root.characterEncoding = enc
      end

      #
      # 文字エンコーディングを取得する
      # 
      # @param [String] 文字エンコーディング
      #
      def characterEncoding
        @root.characterEncoding
      end

      #
      # ルート要素を取得する
      # 
      # @return [Meteor::RootElement] ルート要素
      #
      def rootElement
        @root
      end

      #
      # ファイルを読み込み、パーサにセットする
      #
      # @param [String] filePath 入力ファイルの絶対パス
      # @param [String] encoding 入力ファイルの文字コード
      #
      def read(filePath, encoding)

        #try {
        @characterEncoding = encoding
        #ファイルのオープン
        if RUBY_VERSION >= '1.9.0' then
          io = File.open(filePath,'r:' << encoding)
          #読込及び格納
          @root.document = io.read
        else
          #読込及び格納
          io = open(filePath,'r')
          @root.document = io.read
          @root.document = @root.document.kconv(get_encoding(), Kconv.guess(@root.document))
        end

        #ファイルのクローズ
        io.close

        #@root.document = str

        #} catch (FileNotFoundException e) {
        #FileNotFoundException時の処理
        #e.printStackTrace();
        #@document = EMPTY;
        #} catch (Exception e) {
        #    //上記以外の例外時の処理
        #    e.printStackTrace();
        #    this.setDocument(EMPTY);
        #}

      end

      def get_encoding()
        case @characterEncoding
        when "UTF-8"
          Kconv::UTF8
        when "ISO-2022-JP"
          Kconv::JIS
        when "Shift_JIS"
          Kconv::SJIS
        when "EUC-JP"
          Kconv::EUC
        when "ASCII"
          Kconv::ASCII
          #when "UTF-16"
          #  return KConv::UTF16
        else
          KConv::UTF8
        end
      end
      private :get_encoding

      #
      # 要素を取得する
      # 
      # @param [Array] args 引数配列
      # @return [Meteor::Element] 要素
      #
      def element(*args)
        case args.length
        when 1
          element_1(args[0])
        when 2
          element_2(args[0],args[1])
        when 3
          element_3(args[0],args[1],args[2])
        when 4
          element_4(args[0],args[1],args[2],args[3])
        when 5
          element_5(args[0],args[1],args[2],args[3],args[4])
        else
          raise ArgumentError
        end
      end

      #
      # 要素名で検索し、要素を取得する
      #
      # @param [String] elmName 要素名
      # @return [Meteor::Element] 要素
      #
      def element_1(elmName)

        @_elmName = escapeRegex(elmName)
        
        #空要素検索用パターン
        @pattern_cc_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_1_3

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        #空要素検索
        @res1 = @pattern.match(@root.document)
        
        #内容あり要素検索用パターン
        @pattern_cc_2 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_1_1 << elmName
        @pattern_cc_2 << TAG_SEARCH_1_2 << @_elmName << TAG_CLOSE

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        #内容あり要素検索
        @res2 = @pattern.match(@root.document)
        
        if @res1 && @res2 then
          if @res1.end(0) < @res2.end(0) then
            @res = @res1
            @pattern_cc = @pattern_cc_1
            @elm_ = elementWithoutContent_1(elmName)
          elsif @res1.end(0) > @res2.end(0)
            @res = @res2
            @pattern_cc = @pattern_cc_2
            @elm_ = elementWithContent_1(elmName)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          @pattern_cc = @pattern_cc_1
          @elm_ = elementWithoutContent_1(elmName)
        elsif !@res1 && @res2 then
          @res = @res2
          @pattern_cc = @pattern_cc_2
          @elm_ = elementWithContent_1(elmName)
        elsif !@res1 && !@res2 then
          @elm_ = nil
          #raise NoSuchElementException.new(elmName);
        end
        
        @elm_
      end
      private :element_1

      def elementWithContent_1(elmName)

        @elm_ = Element.new(elmName)
        #属性
        @elm_.attributes = @res[1]
        #内容
        @elm_.mixed_content = @res[2]
        #全体
        @elm_.document = @res[0]
        
        @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_NC_1_1 << elmName
        @pattern_cc << TAG_SEARCH_NC_1_2 << @_elmName << TAG_CLOSE
        
        #内容あり要素検索用パターン
        @elm_.pattern = @pattern_cc
        
        @elm_.empty = true
        
        @elm_.parser = self

        @elm_
      end
      private :elementWithContent_1

      def elementWithoutContent_1(elmName)
        #要素
        @elm_ = Element.new(elmName)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_NC_1_3
        @elm_.pattern = @pattern_cc
        
        @elm_.empty = false
        
        @elm_.parser = self

        @elm_
      end
      private :elementWithoutContent_1

      #
      # 要素名と属性で検索し、要素を取得する
      #
      # @param [String] elmName  要素名
      # @param [String] attrName 属性名
      # @param [String] attrValue 属性値
      # @return [Meteor::Element] 要素
      #
      def element_3(elmName,attrName,attrValue)

        @_elmName = escapeRegex(elmName)
        @_attrName = escapeRegex(attrName)
        @_attrValue = escapeRegex(attrValue)

        #空要素検索用パターン
        @pattern_cc_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1 << @_attrName << ATTR_EQ
        @pattern_cc_1 << @_attrValue << TAG_SEARCH_2_3_2
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        #空要素検索
        @res1 = @pattern.match(@root.document)
        
        #内容あり要素検索パターン
        @pattern_cc_2 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1 << @_attrName << ATTR_EQ
        @pattern_cc_2 << @_attrValue << TAG_SEARCH_2_2 << @_elmName
        @pattern_cc_2 << TAG_SEARCH_1_2 << @_elmName << TAG_CLOSE
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        #内容あり要素検索
        @res2 = @pattern.match(@root.document)
        
        if !@res2 then
          @res2 = elementWithContent_3_2(elmName)
          @pattern_cc_2 = @pattern_cc
        end
        
        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
            @res = @res1
            @pattern_cc = @pattern_cc_1
            elementWithoutContent_3(elmName)
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            @pattern_cc = @pattern_cc_2
            elementWithContent_3_1(elmName)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          @pattern_cc = @pattern_cc_1
          elementWithoutContent_3(elmName)
        elsif !@res1 && @res2 then
          @res = @res2
          @pattern_cc = @pattern_cc_2
          elementWithContent_3_1(elmName)
        elsif !@res1 && !@res2 then
          @elm_ = nil
          #raise NoSuchElementException.new(elmName,attrName,attrValue);
        end
        
        if @elm_ then
          @elm_.arguments.store(attrName, attrValue)
          @elm_.arguments.recordable = true
        end
        
        @elm_
      end
      private :element_3

      def elementWithContent_3_1(elmName)
          
        if @res.captures.length == 4 then
          #要素
          @elm_ = Element.new(elmName)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          @pattern_cc = ''<< TAG_OPEN << @_elmName << TAG_SEARCH_NC_2_1 << @_attrName << ATTR_EQ
          @pattern_cc << @_attrValue << TAG_SEARCH_NC_2_2 << @_elmName
          @pattern_cc << TAG_SEARCH_NC_1_2 << @_elmName << TAG_CLOSE
          @elm_.pattern = @pattern_cc
          
          @elm_.empty = true
          
          @elm_.parser = self
          
        elsif @res.captures.length == 6 then
          #内容
          @elm_ = Element.new(elmName)
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
      end
      private :elementWithContent_3_1
      
      def elementWithContent_3_2(elmName)
        @cnt = 0

        @pattern_cc_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1 << @_attrName << ATTR_EQ
        @pattern_cc_1 << @_attrValue << TAG_SEARCH_2_4_2
        
        @pattern_cc_1b = '' << TAG_OPEN << @_elmName << TAG_SEARCH_1_4
        
        @pattern_cc_1_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1 << @_attrName << ATTR_EQ
        @pattern_cc_1_1 << @_attrValue << TAG_SEARCH_4_7
        
        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_elmName << TAG_SEARCH_4_3
        
        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_elmName << TAG_CLOSE
        
        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_elmName << TAG_CLOSE
        
        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_elmName << TAG_CLOSE
        
        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        
        @sbuf = '';
        
        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b);
        
        create_element_pattern
        
        @pattern_cc = @sbuf
        
        if @sbuf.length == 0 || @cnt != 0 then
          #  raise NoSuchElementException.new(elmName,attrName,attrValue);
          return nil;
        end
        
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)
        
        @res
      end
      private :elementWithContent_3_2
      
      def elementWithoutContent_3(elmName)
        elementWithoutContent_3_1(elmName,TAG_SEARCH_NC_2_3_2)
      end
      private :elementWithoutContent_3
      
      def elementWithoutContent_3_1(elmName,closer)
        
        #要素
        @elm_ = Element.new(elmName)
        #属性
        @elm_.attributes = @res[1];
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_NC_2_1 << @_attrName << ATTR_EQ
        @pattern_cc << @_attrValue << closer
        @elm_.pattern = @pattern_cc
        
        @elm_.parser = self
      end
      private :elementWithoutContent_3_1
      
      #
      # 属性(属性名="属性値")で検索し、要素を取得する
      #
      # @param [String] attrName 属性名
      # @param [String] attrValue 属性値
      # @return [Meteor::Element] 要素
      #
      def element_2(attrName,attrValue)
        
        @_attrName = escapeRegex(attrName)
        @_attrValue = escapeRegex(attrValue)
        
        #@pattern_cc = '' << TAG_SEARCH_3_1 << @_attrName << ATTR_EQ << @_attrValue << TAG_SEARCH_2_4
        @pattern_cc = '' << TAG_SEARCH_3_1 << @_attrName << ATTR_EQ << @_attrValue << TAG_SEARCH_2_4_2_3
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        
        @res = @pattern.match(@root.document)
        
        if @res then
          @elm_ = element_3(@res[1], attrName, attrValue)
        else
          @elm_ = nil
        end
        
        @elm_
      end
      private :element_2
      
      #
      # 要素名と属性1・属性2で検索し、要素を取得する
      # 
      # @param [String] elmName  要素の名前
      # @param [String] attrName1 属性名1
      # @param [String] attrValue1 属性値2
      # @param [String] attrName2 属性名2
      # @param [String] attrValue2 属性値2
      # @return [Meteor::Element] 要素
      #
      def element_5(elmName,attrName1,attrValue1,attrName2,attrValue2)

        @_elmName = escapeRegex(elmName)
        @_attrName1 = escapeRegex(attrName1)
        @_attrName2 = escapeRegex(attrName2)
        @_attrValue1 = escapeRegex(attrValue1)
        @_attrValue2 = escapeRegex(attrValue2)

        #空要素検索用パターン
        @pattern_cc_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1_2 << @_attrName1 << ATTR_EQ
        @pattern_cc_1 << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
        @pattern_cc_1 << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
        @pattern_cc_1 << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
        @pattern_cc_1 << @_attrValue1 << TAG_SEARCH_2_3_2_2
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        #空要素検索
        @res1 = @pattern.match(@root.document)
        
        #内容あり要素検索パターン
        @pattern_cc_2 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1_2 << @_attrName1 << ATTR_EQ
        @pattern_cc_2 << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
        @pattern_cc_2 << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
        @pattern_cc_2 << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
        @pattern_cc_2 << @_attrValue1 << TAG_SEARCH_2_2_2 << @_elmName
        @pattern_cc_2 << TAG_SEARCH_1_2 << @_elmName << TAG_CLOSE
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        #内容あり要素検索
        @res2 = @pattern.match(@root.document)
        
        if !@res2 then
          @res2 = elementWithContent_5_2(elmName)
          @pattern_cc_2 = @pattern_cc
        end
        
        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
            @res = @res1
            @pattern_cc = @pattern_cc_1
            elementWithoutContent_5(elmName)
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            @pattern_cc = @pattern_cc_2
            elementWithContent_5_1(elmName)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          @pattern_cc = @pattern_cc_1
          elementWithoutContent_5(elmName)
        elsif !@res1 && @res2 then
          @res = @res2
          @pattern_cc = @pattern_cc_2
          elementWithContent_5_1(elmName)
        elsif !@res1 && !@res2 then
          @elm_ = nil
          #raise NoSuchElementException.new(elmName,attrName1,attrValue1,attrName2,attrValue2);
        end
        
        if @elm_ then
          @elm_.arguments.store(attrName1, attrValue1)
          @elm_.arguments.store(attrName2, attrValue2)
          @elm_.arguments.recordable = true
        end
        
        @elm_
      end
      private :element_5
      
      def elementWithContent_5_1(elmName)
        
        if @res.captures.length == 4 then
          #要素
          @elm_ = Element.new(elmName)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_NC_2_1_2 << @_attrName1 << ATTR_EQ
          @pattern_cc << @_attrValue1 << TAG_SEARCH_NC_2_6 << @_attrName2 << ATTR_EQ
          @pattern_cc << @_attrValue2 << TAG_SEARCH_NC_2_7 << @_attrName2 << ATTR_EQ
          @pattern_cc << @_attrValue2 << TAG_SEARCH_NC_2_6 << @_attrName1 << ATTR_EQ
          @pattern_cc << @_attrValue1 << TAG_SEARCH_NC_2_2_2 << @_elmName
          @pattern_cc << TAG_SEARCH_NC_1_2 << @_elmName << TAG_CLOSE
          @elm_.pattern = @pattern_cc
          #
          @elm_.empty = true
          
          @elm_.parser = self
          
        elsif @res.captures.length == 6 then
          
          @elm_ = Element.new(elmName)
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
      end
      private :elementWithContent_5_1
      
      def elementWithContent_5_2(elmName)
        @cnt = 0
        
        @pattern_cc_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1_2 << @_attrName1 << ATTR_EQ
        @pattern_cc_1 << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
        @pattern_cc_1 << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
        @pattern_cc_1 << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
        @pattern_cc_1 << @_attrValue1 << TAG_SEARCH_2_4_2_2
        
        @pattern_cc_1b = '' << TAG_OPEN << elmName << TAG_SEARCH_1_4
        
        @pattern_cc_1_1 = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1_2 << @_attrName1 << ATTR_EQ
        @pattern_cc_1_1 << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
        @pattern_cc_1_1 << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
        @pattern_cc_1_1 << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
        @pattern_cc_1_1 << @_attrValue1 << TAG_SEARCH_4_7_2
        
        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_elmName << TAG_SEARCH_4_3
        
        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_elmName << TAG_CLOSE
        
        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_elmName << TAG_CLOSE
        
        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_elmName << TAG_CLOSE
        
        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        
        @sbuf = ''
        
        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b);
        
        create_element_pattern
        
        @pattern_cc = @sbuf
        
        if @sbuf.length == 0 || @cnt != 0 then
          #  raise NoSuchElementException.new(elmName,attrName1,attrValue1,attrName2,attrValue2);
          return nil
        end
        
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)
        
        @res
      end
      private :elementWithContent_5_2
      
      def elementWithoutContent_5(elmName)
        elementWithoutContent_5_1(elmName,TAG_SEARCH_NC_2_3_2_2);
      end
      private :elementWithoutContent_5

      def elementWithoutContent_5_1(elmName,closer)

        #要素
        @elm_ = Element.new(elmName)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_NC_2_1_2 << @_attrName1 << ATTR_EQ
        @pattern_cc << @_attrValue1 << TAG_SEARCH_NC_2_6 << @_attrName2 << ATTR_EQ
        @pattern_cc << @_attrValue2 << TAG_SEARCH_NC_2_7 << @_attrName2 << ATTR_EQ
        @pattern_cc << @_attrValue2 << TAG_SEARCH_NC_2_6 << @_attrName1 << ATTR_EQ
        @pattern_cc << @_attrValue1 << closer
        @elm_.pattern = @pattern_cc
        
        @elm_.parser = self
      end
      private :elementWithoutContent_5_1

      #
      # 属性1・属性2(属性名="属性値")で検索し、要素を取得する
      #
      # @param [String] attrName1 属性名1
      # @param [String] attrValue1 属性値1
      # @param [String] attrName2 属性名2
      # @param [String]attrValue2 属性値2
      # @return [Meteor::Element] 要素
      #
      def element_4(attrName1,attrValue1,attrName2,attrValue2)

        @_attrName1 = escapeRegex(attrName1)
        @_attrName2 = escapeRegex(attrName2)
        @_attrValue1 = escapeRegex(attrValue1)
        @_attrValue2 = escapeRegex(attrValue2)

        @pattern_cc = '' << TAG_SEARCH_3_1_2_2 << @_attrName1 << ATTR_EQ
        @pattern_cc << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
        @pattern_cc << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
        @pattern_cc << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
        @pattern_cc << @_attrValue1 << TAG_SEARCH_2_4_2_3

        @pattern = PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
          @elm_ = element_5(@res[1], attrName1, attrValue1,attrName2, attrValue2);
        else
          @elm_ = nil
        end

        @elm_
      end
      private :element_4

      def create_element_pattern    

        if RUBY_VERSION >= '1.9.0' then

          @position = 0

          while (@res = @pattern.match(@root.document,@position)) || @cnt > 0

            if @res then

              if @cnt > 0 then

                @position2 = @res.end(0)

                @res = @pattern_2.match(@root.document,@position)

                if @res then

                  @position = @res.end(0)

                  if @position > @position2 then

                    if @cnt == 0 then
                      @sbuf << @pattern_cc_1_1
                    else
                      @sbuf << @pattern_cc_1_2
                    end

                    @cnt << 1

                    @position = @position2
                  else

                    @cnt -= 1

                    if @cnt != 0 then
                      @sbuf << @pattern_cc_2_1
                    else
                      @sbuf << @pattern_cc_2_2
                    end

                    if @cnt == 0 then
                      break
                    end
                  end
                else

                  if @cnt == 0 then
                    @sbuf << @pattern_cc_1_1
                  else
                    @sbuf << @pattern_cc_1_2
                  end

                  @cnt += 1

                  @position = @position2
                end
              else
                @position = @res.end(0)

                if @cnt == 0 then
                  @sbuf << @pattern_cc_1_1
                else
                  @sbuf << @pattern_cc_1_2
                end

                @cnt += 1
              end
            else

              @res = @pattern_2.match(@root.document,@position)

              if @res then

                @cnt -= 1

                if @cnt != 0 then
                  @sbuf << @pattern_cc_2_1
                else
                  @sbuf << @pattern_cc_2_2
                end

                @position = @res.end(0)
              end

              if @cnt == 0 then
                break
              end

              if !@res then
                break
              end
            end

            @pattern = @pattern_1b
          end
        else

          @rx_document = @root.document

          while (@res = @pattern.match(@rx_document)) || @cnt > 0

            if @res then

              if @cnt > 0 then

                @rx_document2 = @res.post_match

                @res = @pattern_2.match(@rx_document)

                if @res then

                  @rx_document = @res.post_match

                  if @rx_document2.length > @rx_document.length then

                    if @cnt == 0 then
                      @sbuf << @pattern_cc_1_1
                    else
                      @sbuf << @pattern_cc_1_2
                    end

                    @cnt += 1

                    @rx_document = @rx_document2
                  else

                    @cnt -= 1

                    if @cnt != 0 then
                      @sbuf << @pattern_cc_2_1
                    else
                      @sbuf << @pattern_cc_2_2
                    end

                    if @cnt == 0 then
                      break
                    end
                  end
                else

                  if @cnt == 0 then
                    @sbuf << @pattern_cc_1_1
                  else
                    @sbuf << @pattern_cc_1_2
                  end

                  @cnt += 1

                  @rx_document = @rx_document2
                end
              else
                @rx_document = @res.post_match

                if @cnt == 0 then
                  @sbuf << @pattern_cc_1_1
                else
                  @sbuf << @pattern_cc_1_2
                end

                @cnt += 1
              end
            else

              @res = @pattern_2.match(@rx_document)

              if @res then

                @cnt -= 1

                if @cnt != 0 then
                  @sbuf << @pattern_cc_2_1
                else
                  @sbuf << @pattern_cc_2_2
                end

                @rx_document = @res.post_match
              end

              if @cnt == 0 then
                break
              end

              if !@res then
                break
              end
            end

            @pattern = @pattern_1b
          end
        end
      end
      private :create_element_pattern

      #
      # 要素の属性をセットする or 属性の値を取得する
      # 
      # @param [Array] args 引数配列
      # @return [String] 属性値
      #
      def attribute(*args)
        case args.length
        when 1
          getAttributeValue_1(args[0])
        when 2
          if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String) then
            getAttributeValue_2(args[0],args[1])
          elsif args[0].kind_of?(String) && args[1].kind_of?(String) then
            setAttribute_2(args[0],args[1])
          elsif args[0].kind_of?(Meteor::Element) && args[1].kind_of?(Meteor::AttributeMap) then
            setAttribute_2_m(args[0],args[1])
          else
            raise ArgumentError
          end
        when 3
          setAttribute_3(args[0],args[1],args[2])
        else
          raise ArgumentError
        end
      end
      
      #
      # 要素の属性を編集する
      #
      # @param [Meteor::Element] elm 要素
      # @param [String] attrName  属性名
      # @param [String] attrValue 属性値
      #
      def setAttribute_3(elm,attrName,attrValue)
        if !elm.cx then
          attrValue = escape(attrValue)
          #属性群の更新
          editAttributes_(elm,attrName,attrValue)
          
          if !elm.parent then
            if elm.arguments.map.include?(attrName) then
              elm.arguments.store(attrName, attrValue)
            end
            
            @e_cache.store(elm.object_id, elm)
          end
        end
        elm
      end
      private :setAttribute_3

      def editAttributes_(elm,attrName,attrValue)

        #属性検索
        #@res = @pattern.match(elm.attributes)

        #検索対象属性の存在判定
        #if @res then
        if elm.attributes.include?(' ' << attrName << ATTR_EQ) then
          
          @_attrValue = attrValue
          #replace2Regex(@_attrValue)
          if elm.parser.rootElement.hook || elm.parser.rootElement.monoHook then
            replace4Regex(@_attrValue)
          else
            replace2Regex(@_attrValue)
          end
          #属性の置換
          @pattern = Meteor::Core::Util::PatternCache.get('' << attrName << SET_ATTR_1)
          elm.attributes.sub!(@pattern,'' << attrName << ATTR_EQ << @_attrValue << DOUBLE_QUATATION)
        else
          #属性文字列の最後に新規の属性を追加する
          @_attrValue = attrValue
          #replace2Regex(@_attrValue)
          if elm.parser.rootElement.hook || elm.parser.rootElement.monoHook then
            replace2Regex(@_attrValue)
          end
          
          if EMPTY != elm.attributes && EMPTY != elm.attributes.strip then
            elm.attributes = '' << SPACE << elm.attributes.strip
          else
            elm.attributes = ''
          end

          elm.attributes << SPACE << attrName << ATTR_EQ << @_attrValue << DOUBLE_QUATATION
        end
        
      end
      private :editAttributes_

      def editDocument_1(elm)
        editDocument_2(elm,TAG_CLOSE3)
      end
      private :editDocument_1

      def editDocument_2(elm,closer)
        if !elm.cx then
          @_attributes = elm.attributes
          replace2Regex(@_attributes)
          
          if elm.empty then
            #内容あり要素の場合
            @_content = elm.mixed_content
            #replace2Regex(@_content)
            if elm.parser.rootElement.hook || elm.parser.rootElement.monoHook then
              replace4Regex(@_content)
            else
              replace2Regex(@_content)
            end
            
            #タグ検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
            @root.document.sub!(@pattern,'' << TAG_OPEN << elm.name << @_attributes << TAG_CLOSE << @_content << TAG_OPEN3 << elm.name << TAG_CLOSE)
            #@root.document.sub!(@pattern,"<#{elm.name}#{@_attributes}>#{@_content}</#{elm.name}>")
          else
            #空要素の場合
            #タグ置換用パターン
            @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
            @root.document.sub!(@pattern,'' << TAG_OPEN << elm.name << @_attributes << closer)
          end
        else
          @_content = elm.mixed_content
          if elm.parser.rootElement.hook || elm.parser.rootElement.monoHook then
            replace4Regex(@_content)
          else
            replace2Regex(@_content)
          end
          
          @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
          
          #タグ置換
          @pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2
          @pattern_cc << @_content << SET_CX_3 << elm.name << SET_CX_4
          #@pattern_cc = "<!-- @#{elm.name} #{elm.attributes}-->#{@_content}<!-- /@#{elm.name} -->"
          @root.document.sub!(@pattern,@pattern_cc)
        end
      end
      private :editDocument_2

      def editPattern_(elm)
          
        elm.arguments.map.each{ |name,attr|
          
          if attr.changed then
            @_attrValue = escapeRegex(attr.value)
            #replace2Regex(@_attrValue)  
            @pattern_cc = '' << name << SET_ATTR_1
            #@pattern_cc = "#{attrName}=\"[^\"]*\""
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            elm.pattern.gsub!(@pattern,'' << name << ATTR_EQ << @_attrValue << DOUBLE_QUATATION)
            #elm.pattern.sub!(@pattern,"#{attrName}=\"#{@_attrValue}\"")
          elsif attr.removed then
            @pattern_cc = '' << name << SET_ATTR_1
            #@pattern_cc = "#{attrName}=\"[^\"]*\""
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            elm.pattern.gsub!(@pattern,EMPTY)
          end
        }
      end
      private :editPattern_

      #
      # 要素の属性を編集する
      # 
      # @param [String] attrName 属性名
      # @param [String] attrValue 属性値
      #
      def setAttribute_2(attrName,attrValue)
        if @root.hook || @root.monoHook then
          setAttribute_3(@root.mutableElement, attrName, attrValue)
        end
        @root.mutableElement
      end
      private :setAttribute_2
      
      #
      # 要素の属性値を取得する
      #
      # @param [Meteor::Element] elm 要素
      # @param [String] attrName 属性名
      # @return [String] 属性値
      #
      def getAttributeValue_2(elm,attrName)
        getAttributeValue_(elm,attrName)
      end
      private :getAttributeValue_2

      def getAttributeValue_(elm,attrName)

        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get('' << attrName << GET_ATTR_1)

        @res = @pattern.match(elm.attributes)

        if @res then
          unescape(@res[1])
        else
          nil
        end
      end
      private :getAttributeValue_
      
      #
      # 要素の属性値を取得する
      # 
      # @param [String] attrName 属性名
      # @return [String] 属性値
      #
      def getAttributeValue_1(attrName)
        if @root.hook || @root.monoHook then
          getAttributeValue_2(@root.mutableElement, attrName)
        else
          nil
        end
      end
      private :getAttributeValue_1
      
      #
      # 属性マップを取得する
      # 
      # @param [Array] args 引数配列
      # @return [Meteor::AttributeMap] 属性マップ
      #
      def attributeMap(*args)
        case args.length
        when 0
          getAttributeMap_0
        when 1
          getAttributeMap_1(args[0])
        else
          raise ArgumentError
        end
      end

      #
      # 属性マップを取得する
      # 
      # @param [Meteor::Element] elm 要素
      # @return [Meteor::AttributeMap] 属性マップ
      #
      def getAttributeMap_1(elm)
        attrs = Meteor::AttributeMap.new

        elm.attributes.scan(@@pattern_get_attrs_map){ |a,b|
          attrs.store(a,unescape(b))
        }
        attrs.recordable = true

        attrs
      end
      private :getAttributeMap_1
      
      #
      # 要素の属性マップを取得する
      # 
      # @return [Meteor::AttributeMap] 属性マップ
      #
      def getAttributeMap_0()
        if @root.hook || @root.monoHook then
          getAttributeMap_1(@root.mutableElement)
        else
          nil
        end
      end
      private :getAttributeMap_0
      
      #
      # 要素の属性を編集する
      # 
      # @param [Meteor::Element] elm 要素
      # @param [Meteor::AttributeMap] attrMap 属性マップ
      #
      def setAttribute_2_m(elm,attrMap)
        if !elm.cx then
          attrMap.map.each{|name,attr|
            if attrMap.changed(name) then
              editAttributes_(elm,name,attr.value)
            elsif attrMap.removed(name) then
              removeAttributes_(elm,name)
            end
          }
          
          if !elm.parent then
            @e_cache.store(elm.object_id,elm)
          end
        end
        elm
      end
      private :setAttribute_2_m
 
      #
      # 要素の内容をセットする or 内容を取得する
      # 
      # @param [Array] args 引数配列
      # @return [String] 内容
      #
      def content(*args)
        case args.length
        when 1
          if args[0].kind_of?(Meteor::Element) then
            getContent_1(args[0])
          elsif args[0].kind_of?(String) then
            setContent_1(args[0])
          end
        when 2
          if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String) then
            setContent_2_s(args[0],args[1])
          elsif args[0].kind_of?(String) && (args[1].kind_of?(TrueClass) || args[1].kind_of?(FalseClsss)) then
            setContent_2_b(args[0],args[1])
          else
            raise ArgumentError
          end
        when 3
          setContent_3(args[0],args[1],args[2])
        else
          raise ArgumentError
        end
      end
      
      #
      # 要素の内容をセットする
      #
      # @param [Meteor::Element] elm 要素
      # @param [String] mixed_content 要素の内容
      # @param [TrueClass][FalseClass] entityRef エンティティ参照フラグ
      #
      def setContent_3(elm,content,entityRef=true)

        if entityRef then
          content = escapeContent(content,elm.name)
        end
        
        elm.mixed_content = content
        
        if !elm.parent then
          @e_cache.store(elm.object_id,elm)
        end

        elm
      end
      private :setContent_3

      #
      # 要素の内容を編集する
      # 
      # @param [Meteor::Element] 要素
      # @param [String] mixed_content 要素の内容
      #
      def setContent_2_s(elm,content)
        setContent_3(elm, content)
      end
      private :setContent_2_s
      
      #
      # 要素の内容を編集する
      # 
      # @param [String] mixed_content 内容
      #
      def setContent_1(content)
        if @root.monoHook then
          setContent_2_s(@root.mutableElement, content)
        end
      end
      private :setContent_1
      
      #
      # 要素の内容を編集する
      # 
      # @param [String] mixed_content 内容
      # @param [TrueClass][FalseClass] entityRef エンティティ参照フラグ
      #
      def setContent_2_b(content,entityRef)
        if @root.monoHook then
          setContent_3(@root.mutableElement, content, entityRef)
        end

        elm
      end
      private :setContent_2_b
      
      def getContent_1(elm)
        if !elm.cx then
          if elm.empty then
            unescapeContent(elm.mixed_content,elm.name)
          end
        else
          nil
        end
      end
      private :getContent_1
      
      #
      # 要素の属性を消す
      # 
      # @param [Array] args 引数配列
      #
      def removeAttribute(*args)
        case args.length
        when 1
          removeAttribute_1(args[0])
        when 2
          removeAttribute_2(args[0],args[1])
        else
          raise ArgumentError
        end
      end

      #
      # 要素の属性を消す
      # 
      # @param [Meteor::Element] elm 要素
      # @param [String] attrName 属性名
      #
      def removeAttribute_2(elm,attrName)
        if !elm.cx then

          removeAttributes_(elm,attrName)

          if !elm.parent then
            if elm.arguments.map.include?(attrName) then
              elm.arguments.delete(attrName)
            end
            
            @e_cache.store(elm.object_id,elm)
          end
        end

        elm
      end
      private :removeAttribute_2

      def removeAttributes_(elm,attrName)
        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get('' << attrName << ERASE_ATTR_1)
        #属性の置換
        elm.attributes.sub!(@pattern,EMPTY)
      end
      private :removeAttributes_
      
      #
      # 要素の属性を消す
      # 
      # @param [String] attrName 属性名
      #
      def removeAttribute_1(attrName)
        if @root.hook || @root.monoHook then
          removeAttribute_2(@root.mutableElement, attrName)
        end

        @root.mutableElement
      end
      private :removeAttribute_1
      
      #
      # 要素を消す
      # 
      # @param [Meteor::Element] elm 要素
      #
      def removeElement(elm)
          replace(elm,EMPTY)
          @e_cache.delete(elm.object_id)
      end

      #
      # CX(コメント拡張)タグを取得する
      # 
      # @param [Array] args 引数配列
      # @return [Meteor::Element] 要素
      #
      def cxtag(*args)
        case args.length
        when 1
          cxtag_1(args[0])
        when 2
          cxtag_2(args[0],args[1])
        else
          raise ArgumentError
        end
      end

      #
      # 要素名とID属性で検索し、CX(コメント拡張)タグを取得する
      # 
      # @param [String] elmName 要素名
      # @param [String] id ID属性値
      # @return [Meteor::Element] 要素
      #
      def cxtag_2(elmName,id)

        #CXタグ検索用パターン
        @pattern_cc = '' << SEARCH_CX_1 << elmName << SEARCH_CX_2
        @pattern_cc << id << SEARCH_CX_3 << elmName << SEARCH_CX_4 << elmName << SEARCH_CX_5

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        #CXタグ検索
        @res = @pattern.match(@root.document)

        if @res then
          #要素
          @elm_ = Element.new(elmName)

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
      # ID属性で検索し、CX(コメント拡張)タグを取得する
      # 
      # @param [String] id ID属性値
      # @return [Meteor::Element] 要素
      #
      def cxtag_1(id)

        @pattern_cc = '' << SEARCH_CX_6 << id << DOUBLE_QUATATION

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
          @elm_ = cxtag(@res[1],id)
        else
          @elm_ = nil
        end

        @elm_
      end
      private :cxtag_1

      #
      # 要素を置換する
      # 
      # @param [Meteor::Element] elm 要素
      # @param [String] replaceDocument 置換文字列
      #
      def replace(elm,replaceDocument)
        #文字エスケープ
        if replaceDocument.size > 0 && elm.parent && elm.mono then
          replace2Regex(replaceDocument)
        end
        #タグ置換パターン
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        #タグ置換
        @root.document.sub!(@pattern,replaceDocument)
      end
      
      def reflect()
        
        @e_cache.values.each { |item|
          editDocument_1(item)
          editPattern_(item)
        }
        @e_cache.clear
      end
      protected :reflect
      
      #
      # 出力する
      #
      def print
        reflect()
        
        if @root.hook then
          @_attributes = @root.mutableElement.attributes
          replace2Regex(@_attributes)
          if @root.element.cx then
            #@root.hookDocument << SET_CX_1 << @root.mutableElement.name << SPACE
            #@root.hookDocument << @_attributes << SET_CX_2
            #@root.hookDocument << @root.document << SET_CX_3
            #@root.hookDocument << @root.mutableElement.name << SET_CX_4
            @root.hookDocument << "<!-- @#{@root.mutableElement.name} #{@_attributes}-->#{@root.document}<!-- /@#{@root.mutableElement.name} -->"
          else
            #@root.hookDocument << TAG_OPEN << @root.mutableElement.name
            #@root.hookDocument << @_attributes << TAG_CLOSE << @root.document
            #@root.hookDocument << TAG_OPEN3 << @root.mutableElement.name << TAG_CLOSE
            @root.hookDocument << "<#{@root.mutableElement.name}#{@_attributes}>#{@root.document}</#{@root.mutableElement.name}>"
          end
          @root.mutableElement = Element.new(@root.element)
          @root.document = String.new(@root.element.mixed_content)
        else
          if @root.monoHook then
            if @root.element.cx then
              #@root.hookDocument << SET_CX_1 << @root.mutableElement.name << SPACE
              #@root.hookDocument << @root.mutableElement.attributes << SET_CX_2
              #@root.hookDocument << @root.mutableElement.mixed_content << SET_CX_3
              #@root.hookDocument << @root.mutableElement.name << SET_CX_4
              @root.hookDocument << "<!-- @#{@root.mutableElement.name} #{@root.mutableElement.attributes}-->#{@root.mutableElement.mixed_content}<!-- /@#{@root.mutableElement.name} -->"
            else
              #@root.hookDocument << TAG_OPEN << @root.mutableElement.name
              #@root.hookDocument << @root.mutableElement.attributes << TAG_CLOSE << @root.mutableElement.mixed_content
              #@root.hookDocument << TAG_OPEN3 << @root.mutableElement.name << TAG_CLOSE
              @root.hookDocument << "<#{@root.mutableElement.name}#{@root.mutableElement.attributes}>#{@root.mutableElement.mixed_content}</#{@root.mutableElement.name}>"
            end
            @root.mutableElement = Element.new(@root.element)
          else
            #フック判定がFALSEの場合
            clean
          end
        end
      end
      
      def clean
        #CX開始タグ置換
        @pattern = @@pattern_clean1
        @root.document.gsub!(@pattern,EMPTY)
        #CX終了タグ置換
        @pattern = @@pattern_clean2
        @root.document.gsub!(@pattern,EMPTY)
        #@root.document = @root.document << "<!-- Powered by Meteor (C)Yasumasa Ashida -->"
      end
      private :clean
      
      #
      # 子パーサを取得する
      # 
      # @param [Meteor::Element] elm 要素
      # @return [Meteor::Parser] 子パーサ
      #
      def child(elm)
        if elm.empty then
          #内容あり要素の場合
          setMonoInfo(elm)
          
          pif2 = create(self)
          
          elm.parent=true
          pif2.parent = self
          pif2.rootElement.element = elm
          pif2.rootElement.mutableElement = Element.new(elm)
          pif2.rootElement.kaigyoCode = @root.kaigyoCode
          
          if elm.mono then
            pif2.rootElement.monoHook = true
            
            pif2
          else
            pif2.rootElement.document = String.new(elm.mixed_content)
            pif2.rootElement.hook = true
            
            pif2
          end
        end
      end
      
      def setMonoInfo(elm)
      end
      private :setMonoInfo
      
      #
      # 反映する
      #
      def flush
        if @root.hook || @root.monoHook then
          if @root.element then
            @parent.reflect
            @parent.replace(@root.element, @root.hookDocument)
          end
        end
      end

      #
      #
      #
      def execute(*args)
        case args.length
        when 1
          execute_2(args[0],args[1])
        when 2
          execute_3(args[0],args[1],args[2])
        else
          raise ArgumentError
        end
      end
      
      def execute_2(elm,hook)
        hook.doAction(elm, self)
      end
      private :execute_2
      
      def execute_3(elm,loop,list)
        loop.doAction(elm, this, list)
      end
      private :execute_3
      
      #
      # 正規表現対象文字を置換する
      #
      # @param [String] element 入力文字列
      # @return [String] 出力文字列
      #
      def escapeRegex(element)
        ##「\」->[\\]
        #element.gsub!(@@pattern_en,EN_2)
        ##「$」->「\$」
        #element.gsub!(@@pattern_dol,DOL_2)
        ##「+」->「\+」
        #element.gsub!(@@pattern_plus,PLUS_2)
        #todo
        ##「(」->「\(」
        #element.gsub!(@@pattern_brac_open,BRAC_OPEN_2)
        ##「)」->「\)」
        #element.gsub!(@@pattern_brac_close,BRAC_CLOSE_2)
        ##「[」->「\[」
        #element.gsub!(@@pattern_sbrac_open,SBRAC_OPEN_2)
        ##「]」->「\]」
        #element.gsub!(@@pattern_sbrac_close,SBRAC_CLOSE_2)
        ##「{」->「\{」
        #element.gsub!(@@pattern_cbrac_open,CBRAC_OPEN_2)
        ##「}」->「\}」
        #element.gsub!(@@pattern_cbrac_close,CBRAC_CLOSE_2)
        ##「.」->「\.」
        #element.gsub!(@@pattern_comma,COMMA_2)
        ##「|」->「\|」
        #element.gsub!(@@pattern_vline,VLINE_2)
        ##「?」->「\?」
        #element.gsub!(@@pattern_qmark,QMARK_2)
        ##「*」->「\*」
        #element.gsub!(@@pattern_asterisk,ASTERISK_2)
        Regexp.quote(element)

      end
      private :escapeRegex
      
      def replace2Regex(element)
        if element.include?(EN_1) then
          element.gsub!(@@pattern_sub_regex1,SUB_REGEX2)
        end
      end
      private :replace2Regex
      
      def replace4Regex(element)
        if element.include?(EN_1) then
          element.gsub!(@@pattern_sub_regex1,SUB_REGEX3)
        end
      end
      private :replace4Regex
      
      #
      # @param [String] element 入力文字列
      # @return [String] 出力文字列
      #
      def escape(element)
        element;
      end
      private :escape

      #
      # @param [String] element 入力文字列
      # @param [String] elmName 要素名
      # @return [String] 出力文字列
      #
      def escapeContent(element,elmName)
        element
      end
      private :escapeContent

      #
      # @param [String] element 入力文字列
      # @return [String] 出力文字列
      #
      def unescape(element)
        element;
      end
      private :unescape

      #
      # @param [String] element 入力文字列
      # @param [String] elmName 要素名
      # @return [String] 出力文字列
      #
      def unescapeContent(element,elmName)
        element;
      end
      private :unescapeContent

      def isMatch(regex,str)
        if regex.kind_of?(Regexp) then
          if regex.match(str.downcase) then
            true
          else
            false
          end
        elsif regex.kind_of?(Array) then
          str = str.downcase
          regex.each { |item|
            if item.eql?(str) then
              return true
            end
          }
          return false
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
      private :isMatch


      def create(pif)
        if pif.instance_of?(Meteor::Core::Html::ParserImpl) then
          pif = Meteor::Core::Html::ParserImpl.new
        elsif pif.instance_of?(Meteor::Core::Xhtml::ParserImpl) then
          pif = Meteor::Core::Xhtml::ParserImpl.new
        elsif pif.instance_of?(Meteor::Core::Xml::ParserImpl) then
          pif = Meteor::Core::Xml::ParserImpl.new
        else
          pif = nil
        end

      end
      private :create
      
      #
      # 要素の属性or内容をセットする
      # @param [String] name 属性名
      # @param [String] value 属性値or内容
      #
      def []=(name,value)
        if !name.kind_of?(String)|| name != ':content' then
          attribute(name,value)
        else
          content(value)
        end
      end
      
      #
      # 要素の属性値or内容を取得する
      # @param [String] name 属性名
      # @return [String] 属性値or内容
      #
      def [](name)  
        if !name.kind_of?(String)|| name != ':content' then
          attribute(name)
        else
          content()
        end
      end
    end

    module Util

      #
      # パターンキャッシュクラス
      #
      class PatternCache
        @@regexCache = Hash.new

        #
        # イニシャライザ
        #
        def initialize
        end
        
        def self.get(*args)
          case args.length
          when 1
            get_1(args[0])
          when 2
            get_2(args[0],args[1])
          else
            raise ArgumentError
          end
        end
        
        #
        # パターンを取得する
        # @param [String] regex 正規表現
        # @return [Regexp] パターン
        #
        def self.get_1(regex)
          #pattern = @@regexCache[regex]
          #
          #if pattern == nil then
          if regex.kind_of?(String) then
            if !@@regexCache[regex.to_sym] then
              #pattern = Regexp.new(regex)
              #@@regexCache[regex] = pattern
              @@regexCache[regex.to_sym] = Regexp.new(regex,Regexp::MULTILINE)
            end
            
            #return pattern
            @@regexCache[regex.to_sym]
          elsif regex.kind_of?(Symbol) then
            if !@@regexCache[regex] then
              @@regexCache[regex] = Regexp.new(regex.to_s,Regexp::MULTILINE)
            end
            
            @@regexCache[regex]
          end 
        end
        
        #
        # パターンを取得する
        # @param [String] regex 正規表現
        # @return [Regexp] パターン
        #
        def self.get_2(regex,option)
          #pattern = @@regexCache[regex]
          #
          #if pattern == nil then
          if regex.kind_of?(String) then
            if !@@regexCache[regex.to_sym] then
              #pattern = Regexp.new(regex)
              #@@regexCache[regex] = pattern
              @@regexCache[regex.to_sym] = Regexp.new(regex,option)
            end
            
            #return pattern
            @@regexCache[regex.to_sym]
          elsif regex.kind_of?(Symbol) then
            if !@@regexCache[regex] then
              @@regexCache[regex] = Regexp.new(regex.to_s,option)
            end
            
            @@regexCache[regex]
          end 
        end
      end
      
      class OrderHash <Hash
        
        def initialize
          @keys = Array.new
          @values = Array.new
        end
        
        attr_accessor :keys
        attr_accessor :values
        
        def store(key, value)
          super(key, value)
          unless @keys.include?(key)
            @keys << key
            @values << value
          end
        end
        
        def clear
          @keys.clear
          @values.clear
          super
        end
        
        def delete(key)
          if @keys.include?(key)
            @keys.delete(key)
            @values.delete(fetch(key))
            super(key)
          elsif
            yield(key)
          end
        end
        
        #superとして、Hash#[]=を呼び出す
        def []=(key, value)
          store(key, value)
        end
        
        def each
          @keys.each{|k|
            arr_tmp = Array.new
            arr_tmp << k
            arr_tmp << self[k]
            yield(arr_tmp)
          }
          return self
        end
        
        def each_pair
          @keys.each{|k|
            yield(k, self[k])
          }
          return self
        end
        
        def map
          arr_tmp = Array.new
          @keys.each{|k|
            arg_arr = Array.new
            arg_arr << k
            arg_arr << self[k]
            arr_tmp << yield(arg_arr)
          }
          return arr_tmp
        end
        
        def sort_hash(&block)
          if block_given?
            arr_tmp = self.sort(&block)
          elsif
            arr_tmp = self.sort
          end
          hash_tmp = OrderHash.new
          arr_tmp.each{|item|
            hash_tmp[item[0]] = item[1]
          }
          return hash_tmp
        end
      end
    end

    module Html
      #
      # HTMLパーサ
      #
      class ParserImpl < Meteor::Core::Kernel

        KAIGYO_CODE = "(\r?\n|\r)"
        NBSP_2 = '&nbsp;'
        BR_1 = "\r?\n|\r"
        BR_2 = "<br>"

        META = 'META'
        META_S = 'meta'

        #MATCH_TAG = "br|hr|img|input|meta|base"
        MATCH_TAG = ['br','hr','img','input','meta','base']
        #MATCH_TAG_2 = "textarea|option|pre"
        MATCH_TAG_2 =['textarea','option','pre']
        
        HTTP_EQUIV = 'http-equiv'
        CONTENT_TYPE = 'Content-Type'
        CONTENT = 'content'

        ATTR_LOGIC = ['disabled','readonly','checked','selected','multiple']
        OPTION = 'option'
        SELECTED = 'selected'
        INPUT = 'input'
        CHECKED = 'checked'
        RADIO = 'radio'
        #DISABLE_ELEMENT = "input|textarea|select|optgroup"
        DISABLE_ELEMENT = ['input','textarea','select','optgroup']
        DISABLED = 'disabled'
        #READONLY_TYPE = "text|password"
        READONLY_TYPE = ['text','password']
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

        SELECTED_M = "\\sselected\\s|\\sselected$|\\sSELECTED\\s|\\sSELECTED$"
        #SELECTED_M = [' selected ',' selected',' SELECTED ',' SELECTED']
        SELECTED_R = "selected\\s|selected$|SELECTED\\s|SELECTED$"
        CHECKED_M = "\\schecked\\s|\\schecked$|\\sCHECKED\\s|\\sCHECKED$"
        #CHECKED_M = [' checked ',' checked',' CHECKED ',' CHECKED']
        CHECKED_R = "checked\\s|checked$|CHECKED\\s|CHECKED$"
        DISABLED_M = "\\sdisabled\\s|\\sdisabled$|\\sDISABLED\\s|\\sDISABLED$"
        #DISABLED_M = [' disabled ',' disiabled',' DISABLED ',' DISABLED']
        DISABLED_R = "disabled\\s|disabled$|DISABLED\\s|DISABLED$"
        READONLY_M = "\\sreadonly\\s|\\sreadonly$|\\sREADONLY\\s|\\sREADONLY$"
        #READONLY_M = [' readonly ',' readonly',' READONLY ',' READONLY']
        READONLY_R = "readonly\\s|readonly$|READONLY\\s|READONLY$"
        MULTIPLE_M = "\\smultiple\\s|\\smultiple$|\\sMULTIPLE\\s|\\sMULTIPLE$"
        #MULTIPLE_M = [' multiple ',' multiple',' MULTIPLE ',' MULTIPLE']
        MULTIPLE_R = "multiple\\s|multiple$|MULTIPLE\\s|MULTIPLE$"

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

        TRUE = 'true'
        FALSE = 'false'

        #@@pattern_true = Regexp.new(TRUE)
        #@@pattern_false = Regexp.new(FALSE)
        
        TYPE_L = 'type'
        TYPE_U = 'TYPE'
        
        if RUBY_VERSION >= '1.9.0' then
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
            "\n" => '<br>',
          }
          
          PATTERN_ESCAPE = "[&\"'<> ]"
          PATTERN_ESCAPE_CONTENT = "[&\"'<> \\n]"
          
          @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
          @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)  
        else
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
        end
        
        
        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt|nbsp);'
        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)
        
        #@@pattern_match_tag = Regexp.new(MATCH_TAG)
        @@pattern_set_mono1 = Regexp.new(SET_MONO_1)
        #@@pattern_match_tag2 = Regexp.new(MATCH_TAG_2)

        GET_ATTRS_MAP2="\\s(disabled|readonly|checked|selected|multiple)"
        @@pattern_get_attrs_map2 = Regexp.new(GET_ATTRS_MAP2)
        
        #
        # イニシャライザ
        # 
        # @param [Array] args 引数配列
        #
        def initialize(*args)
          super(args)
          case args.length
          when 0
            initialize_0
          when 1
            initialize_1(args[0])
          else
            raise ArgumentError
          end
        end

        #
        # イニシャライザ
        #
        def initialize_0
        end
        private :initialize_0

        #
        # イニシャライザ
        # @param [Meteor::Parser] ps パーサ
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          @root.hookDocument = String.new(ps.rootElement.hookDocument)
          @root.hook = ps.rootElement.hook
          @root.monoHook = ps.rootElement.monoHook
          @root.contentType = String.new(ps.contentType);
        end
        private :initialize_1

        #
        # ドキュメントをパーサにセットする
        # 
        # @param [String] document ドキュメント
        #
        def parse(document)
          @root.document = document
          analyzeML()
        end

        #
        # ファイルを読み込み、パーサにセットする
        # 
        # @param [String] filePath ファイルパス
        # @param [String] encoding エンコーディング
        #
        def read(filePath,encoding)
          super(filePath,encoding)
          analyzeML()
        end

        #
        # ドキュメントをパースする
        #
        def analyzeML()
          #content-typeの取得
          analyzeContentType()
          #改行コードの取得
          analyzeKaigyoCode()

          @res = nil
        end
        private :analyzeML

        # コンテントタイプを取得する
        # 
        # @return [Streing]コンテントタイプ
        #
        def contentType()
          @root.contentType
        end

        #
        # ドキュメントをパースし、コンテントタイプをセットする
        #
        def analyzeContentType()
          @elm_ = element(META_S,HTTP_EQUIV,CONTENT_TYPE)

          if !@elm_ then
            @elm_ = element(META,HTTP_EQUIV,CONTENT_TYPE)
          end

          if @elm_ then
            @root.contentType = @elm_.attribute(CONTENT)
          else
            @root.contentType = EMPTY
          end
        end
        private :analyzeContentType

        #
        # ドキュメントをパースし、改行コードをセットする
        #
        def analyzeKaigyoCode()
          #改行コード取得
          @pattern = Regexp.new(KAIGYO_CODE)
          @res = @pattern.match(@root.document)

          if @res then
            @root.kaigyoCode = @res[1]
          end
        end
        private :analyzeKaigyoCode

        #
        # 要素名で検索し、要素を取得する
        # 
        # @param [String] elmName 要素名
        # @return [Meteor::Element] 要素
        #
        def element_1(elmName)
          @_elmName = escapeRegex(elmName)

          #空要素の場合(<->内容あり要素の場合)
          if isMatch(MATCH_TAG,elmName) then
            #空要素検索用パターン
            @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_1_4_2
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            @res = @pattern.match(@root.document)
            if @res then
              elementWithoutContent_1(elmName)
            else
              @elm_ = nil
            end
          else
            #内容あり要素検索用パターン
            @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_1_1 << elmName
            @pattern_cc << TAG_SEARCH_1_2 << @_elmName << TAG_CLOSE

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)
            #内容あり要素の場合
            if @res then
              elementWithContent_1(elmName)
            else
              @elm_ = nil
            end
          end

          @elm_
        end
        private :element_1

        def elementWithoutContent_1(elmName)
          @elm_ = Element.new(elmName)
          #属性
          @elm_.attributes = @res[1]
          #空要素検索用パターン
          @elm_.pattern = @pattern_cc
          
          @elm_.document = @res[0]
          
          @elm.parser = self
        end
        private :elementWithoutContent_1

        #
        # 要素名、属性(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] elmName 要素名
        # @param [String] attrName 属性名
        # @param [String] attrValue 属性値
        # @return [Meteor::Element] 要素
        #
        def element_3(elmName,attrName,attrValue)

          @_elmName = escapeRegex(elmName)
          @_attrName = escapeRegex(attrName)
          @_attrValue = escapeRegex(attrValue)
          #空要素の場合(<->内容あり要素の場合)
          if isMatch(MATCH_TAG,elmName) then
            #空要素検索パターン
            @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1 << @_attrName << ATTR_EQ
            @pattern_cc << @_attrValue << TAG_SEARCH_2_4_3
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)
            if @res then
              elementWithoutContent_3(elmName)
            else
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1 << @_attrName << ATTR_EQ
            @pattern_cc << @_attrValue << TAG_SEARCH_2_2 << @_elmName
            @pattern_cc << TAG_SEARCH_1_2 << @_elmName << TAG_CLOSE
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)
            
            if !@res then
              @res = elementWithContent_3_2(elmName)
            end
            
            if @res then
              elementWithContent_3_1(elmName)
            else
              @elm_ = nil
            end
          end

          if @elm_ then
            @elm_.arguments.store(attrName, attrValue)
            @elm_.arguments.recordable = true
          end
          
          @elm_
        end
        private :element_3

        def elementWithoutContent_3(elmName)
          elementWithoutContent_3_1(elmName,TAG_SEARCH_NC_2_4_3)
        end
        private :elementWithoutContent_3

        #
        # 属性(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] attrName 属性名
        # @param [String] attrValue 属性値
        # @return [Meteor::Element] 要素
        #
        def element_2(attrName,attrValue)
          @_attrName = escapeRegex(attrName)
          @_attrValue = escapeRegex(attrValue)

          @pattern_cc = '' << TAG_SEARCH_3_1 << @_attrName << ATTR_EQ << @_attrValue
          @pattern_cc << TAG_SEARCH_2_4_4
          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
          @res = @pattern.match(@root.document)

          if @res then
            @elm_ = element_3(@res[1],attrName,attrValue)
          else
            @elm_ = nil
          end

          @elm_
        end
        private :element_2

        #
        # 要素名と属性1・属性2(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] elmName 要素名
        # @param attrName1 属性名1
        # @param attrValue1 属性値1
        # @param attrName2 属性名2
        # @param attrValue2 属性値2
        # @return [Meteor::Element] 要素
        #
        def element_5(elmName,attrName1,attrValue1,attrName2,attrValue2)

          @_elmName = escapeRegex(elmName)
          @_attrName1 = escapeRegex(attrName1)
          @_attrValue1 = escapeRegex(attrValue1)
          @_attrName2 = escapeRegex(attrName2)
          @_attrValue2 = escapeRegex(attrValue2)

          #空要素の場合(<->内容あり要素の場合)
          if isMatch(MATCH_TAG,elmName) then
            #空要素検索パターン
            @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1_2 << @_attrName1 << ATTR_EQ
            @pattern_cc << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
            @pattern_cc << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
            @pattern_cc << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
            @pattern_cc << @_attrValue1 << TAG_SEARCH_2_4_3_2
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)
            
            if @res then
              elementWithoutContent_5(elmName)
            else
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            @pattern_cc = '' << TAG_OPEN << @_elmName << TAG_SEARCH_2_1_2 << @_attrName1 << ATTR_EQ
            @pattern_cc << @_attrValue1 << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ
            @pattern_cc << @_attrValue2 << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ
            @pattern_cc << @_attrValue2 << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ
            @pattern_cc << @_attrValue1 << TAG_SEARCH_2_2_2 << @_elmName
            @pattern_cc << TAG_SEARCH_1_2 << @_elmName << TAG_CLOSE
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)
            
            if !@res then
              @res = elementWithContent_5_2(elmName)
            end
            
            if @res then
              elementWithContent_5_1(elmName)
            else
              @elm_ = nil
            end
          end

          if @elm_ then
            @elm_.arguments.store(attrName1, attrValue1)
            @elm_.arguments.store(attrName2, attrValue2)
            @elm_.arguments.recordable = true
          end
          
          @elm_
        end
        private :element_5
        
        def elementWithoutContent_5(elmName)
          elementWithoutContent_5_1(elmName,TAG_SEARCH_NC_2_4_3_2)
        end
        private :elementWithoutContent_5

        #
        # 属性1・属性2(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] attrName1 属性名1
        # @param [String] attrValue1 属性値1
        # @param [String] attrName2 属性名2
        # @param [String] attrValue2 属性値2
        # @return [Meteor::Element] 要素
        #
        def element_4(attrName1,attrValue1,attrName2,attrValue2)
          @_attrName1 = escapeRegex(attrName1)
          @_attrValue1 = escapeRegex(attrValue1)
          @_attrName2 = escapeRegex(attrName2)
          @_attrValue2 = escapeRegex(attrValue2)

          @pattern_cc = '' << TAG_SEARCH_3_1_2_2 << @_attrName1 << ATTR_EQ << @_attrValue1
          @pattern_cc << TAG_SEARCH_2_6 << @_attrName2 << ATTR_EQ << @_attrValue2
          @pattern_cc << TAG_SEARCH_2_7 << @_attrName2 << ATTR_EQ << @_attrValue2
          @pattern_cc << TAG_SEARCH_2_6 << @_attrName1 << ATTR_EQ << @_attrValue1
          @pattern_cc << TAG_SEARCH_2_4_3_2

          @pattern = Patterncache.get(@pattern_cc)

          @res = @pattern.match(@root.document)

          if @res then
            @elm_ = element_5(@res[1],attrName1,attrValue1,attrName2,attrValue2)
          else
            @elm_ = nil
          end

          @elm_
        end
        private :element_4

        def editAttributes_(elm,attrName,attrValue)
          if isMatch(SELECTED, attrName) && isMatch(OPTION,elm.name) then
            editAttributes_5(elm,attrName,attrValue,@@pattern_selected_m,@@pattern_selected_r)
            #editAttributes_5(elm,attrName,attrValue,SELECTED_M,@@pattern_selected_r)
          elsif isMatch(MULTIPLE, attrName) && isMatch(SELECT,elm.name)
            editAttributes_5(elm,attrName,attrValue,@@pattern_multiple_m,@@pattern_multiple_r)
            #editAttributes_5(elm,attrName,attrValue,MULTIPLE_M,@@pattern_multiple_r)
          elsif isMatch(DISABLED, attrName) && isMatch(DISABLE_ELEMENT, elm.name) then
            editAttributes_5(elm,attrName,attrValue,@@pattern_disabled_m,@@pattern_disabled_r)
            #editAttributes_5(elm,attrName,attrValue,DISABLED_M,@@pattern_disabled_r)
          elsif isMatch(CHECKED, attrName) && isMatch(INPUT,elm.name) && isMatch(RADIO, getType(elm)) then
            editAttributes_5(elm,attrName,attrValue,@@pattern_checked_m,@@pattern_checked_r)
            #editAttributes_5(elm,attrName,attrValue,CHECKED_M,@@pattern_checked_r)
          elsif isMatch(READONLY, attrName) && (isMatch(TEXTAREA,elm.name) || (isMatch(INPUT,elm.name) && isMatch(READONLY_TYPE, getType(elm)))) then
            editAttributes_5(elm,attrName,attrValue,@@pattern_readonly_m,@@pattern_readonly_r)
            #editAttributes_5(elm,attrName,attrValue,READONLY_M,@@pattern_readonly_r)
          else
            super(elm,attrName,attrValue)
          end
        end
        private :editAttributes_

        def editAttributes_5(elm,attrName,attrValue,match_p,replace)
          #attrValue = escape(attrValue)

          if isMatch(TRUE, attrValue) then
            @res = match_p.match(elm.attributes)

            if !@res then
            #if elm.attributes.include?(match_p[0]) || elm.attributes.rindex(match_p[1],elm.attributes.length - 1) == 0 || elm.attributes.include?(match_p[2]) || elm.attributes.rindex(match_p[3],elm.attributes.length - 1) == 0
              if !EMPTY.eql?(elm.attributes) && !EMPTY.eql?(elm.attributes.strip) then
                elm.attributes = '' << SPACE << elm.attributes.strip
              else
                elm.attributes = ''
              end
              elm.attributes << SPACE << attrName
              #else
            end
          elsif isMatch(FALSE, attrValue) then
            elm.attributes.sub!(replace,EMPTY)
          end

        end
        private :editAttributes_5

        def editDocument_1(elm)
          editDocument_2(elm,TAG_CLOSE)
        end
        private :editDocument_1

        def getAttributeValue_(elm,attrName)
          if isMatch(SELECTED, attrName) && isMatch(OPTION,elm.name) then
            getAttributeValue_2_r(elm,@@pattern_selected_m)
            #getAttributeValue_2_r(elm,SELECTED_M)
          elsif isMatch(MULTIPLE, attrName) && isMatch(SELECT,elm.name)
            getAttributeValue_2_r(elm,@@pattern_multiple_m)
            #getAttributeValue_2_r(elm,MULTIPLE_M)
          elsif isMatch(DISABLED, attrName) && isMatch(DISABLE_ELEMENT, elm.name) then
            getAttributeValue_2_r(elm,@@pattern_disabled_m)
            #getAttributeValue_2_r(elm,DISABLED_M)
          elsif isMatch(CHECKED, attrName) && isMatch(INPUT,elm.name) && isMatch(RADIO, getType(elm)) then
            getAttributeValue_2_r(elm,@@pattern_checked_m)
            #getAttributeValue_2_r(elm,CHECKED_M)
          elsif isMatch(READONLY, attrName) && (isMatch(TEXTAREA,elm.name) || (isMatch(INPUT,elm.name) && isMatch(READONLY_TYPE, getType(elm)))) then
            getAttributeValue_2_r(elm,@@pattern_readonly_m)
            #getAttributeValue_2_r(elm,READONLY_M)
          else
            super(elm,attrName)
          end
        end
        private :getAttributeValue_

        def getType(elm)
          if !elm.type_value
            elm.type_value = getAttributeValue_(elm, TYPE_L)
            if !elm.type_value then
              elm.type_value = getAttributeValue_(elm, TYPE_U)
            end
          end
          elm.type_value
        end
        private :getType
        
        def getAttributeValue_2_r(elm,match_p)
          
          @res = match_p.match(elm.attributes)

          if @res then
          #if elm.attributes.include?(match_p[0]) || elm.attributes.rindex(match_p[1],elm.attributes.length - 1) == 0 || elm.attributes.include?(match_p[2]) || elm.attributes.rindex(match_p[3],elm.attributes.length - 1) == 0 then
            TRUE
          else
            FALSE
          end
        end
        private :getAttributeValue_2_r
        
        #
        # 要素の属性マップを取得する
        # 
        # @param [Meteor::Element] elm 要素
        # @return [Meteor::AttributeMap] 属性マップ
        #
        def getAttributeMap_1(elm)
          attrs = Meteor::AttributeMap.new
          
          elm.attributes.scan(@@pattern_get_attrs_map){ |a,b|
            attrs.store(a,unescape(b))
          }
          
          elm.attributes.scan(@@pattern_get_attrs_map2){ |a|
            attrs.store(a, TRUE)
          }
          
          attrs.recordable = true
          
          attrs
        end
        private :getAttributeMap_1

        def removeAttributes_(elm,attrName)
          #検索対象属性の論理型是非判定
          if !isMatch(ATTR_LOGIC,attrName) then
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get('' << attrName << ERASE_ATTR_1)
            elm.attributes.sub!(@pattern, EMPTY)
          else
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get(attrName)  
            elm.attributes.sub!(@pattern, EMPTY)
            #end
          end
        end
        private :removeAttributes_

        def setMonoInfo(elm)

          @res = @@pattern_set_mono1.match(elm.mixed_content)

          if @res then
            elm.mono = true
            if elm.cx then
              @pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
            else
              if elm.empty then
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
              else
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE
              end
            end
            elm.document = @pattern_cc
          end
        end
        private :setMonoInfo

        def escape(element)
          #特殊文字の置換
          if RUBY_VERSION < '1.9.0' then
            #「&」->「&amp;」
            if element.include?(AND_1) then
              element.gsub!(@@pattern_and_1,AND_2)
            end
            #「<」->「&lt;」
            if element.include?(LT_1) then
              element.gsub!(@@pattern_lt_1,LT_2)
            end
            #「>」->「&gt;」
            if element.include?(GT_1) then
              element.gsub!(@@pattern_gt_1,GT_2)
            end
            #「"」->「&quotl」
            if element.include?(DOUBLE_QUATATION) then
              element.gsub!(@@pattern_dq_1,QO_2)
            end
            #「 」->「&nbsp;」
            if element.include?(SPACE) then
              element.gsub!(@@pattern_space_1,NBSP_2)
            end
          else
            element.gsub!(@@pattern_escape, TABLE_FOR_ESCAPE_)
          end
          element
        end
        private :escape

        def escapeContent(element,elmName)
          if RUBY_VERSION < '1.9.0' then
            element = escape(element)
            
            if !isMatch(MATCH_TAG_2,elmName) then
              #「¥r?¥n」->「<br>」
              element.gsub!(@@pattern_br_1, BR_2)
            end
          else
            element.gsub!(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)
          end
          
          element
        end
        private :escapeContent

        def unescape(element)
          #特殊文字の置換
          #「<」<-「&lt;」
          #if element.include?(LT_2) then
          #  element.gsub!(@@pattern_lt_2,LT_1)
          #end
          #「>」<-「&gt;」
          #if element.include?(GT_2) then
          #  element.gsub!(@@pattern_gt_2,GT_1)
          #end
          #「"」<-「&quotl」
          #if element.include?(QO_2) then
          #  element.gsub!(@@pattern_dq_2,DOUBLE_QUATATION)
          #end
          #「 」<-「&nbsp;」
          #if element.include?(NBSP_2) then
          #  element.gsub!(@@pattern_space_2,SPACE)
          #end
          #「&」<-「&amp;」
          #if element.include?(AND_2) then
          #  element.gsub!(@@pattern_and_2,AND_1)
          #end
          element.gsub!(@@pattern_unescape){
            case $1
            when 'amp' then '&'
            when 'quot' then '"'
            when 'apos' then '\''
            when 'gt' then '>'
            when 'lt' then '<'
            when 'nbsp' then ' '
            end
          }
          
          element
        end
        private :unescape

        def unescapeContent(element,elmName)
          element = unescape(element)

          if !isMatch(@@pattern_match_tag2,elmName) then
            #「<br>」->「¥r?¥n」
            if element.include?(BR_2) then
              element.gsub!(@@pattern_br_2, @root.kaigyoCode)
            end
          end

          element
        end
        private :unescapeContent

      end
    end

    module Xhtml

      #
      # XHTMLパーサ
      #
      class ParserImpl < Meteor::Core::Kernel

        KAIGYO_CODE = "(\r?\n|\r)"
        NBSP_2 = '&nbsp;'
        BR_1 = "\r?\n|\r"
        BR_2 = '<br/>'
        BR_3 = "<br\\/>"

        META = 'META'
        META_S = 'meta'

        #MATCH_TAG_2 = "textarea|option|pre"
        MATCH_TAG_2 = ['textarea','option','pre']
        
        ATTR_LOGIC = ['disabled','readonly','checked','selected','multiple']
        OPTION = 'option'
        SELECTED = 'selected'
        INPUT = 'input'
        CHECKED = 'checked'
        RADIO = 'radio'
        #DISABLE_ELEMENT = "input|textarea|select|optgroup"
        DISABLE_ELEMENT = ['input','textarea','select','optgroup']
        DISABLED = 'disabled'
        #READONLY_TYPE = "text|password"
        READONLY_TYPE = ['text','password']
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
        
        SELECTED_M = "\\sselected=\"[^\"]*\"\\s|\\sselected=\"[^\"]*\"$"
        SELECTED_M1 = "\\sselected=\"([^\"]*)\"\\s|\\sselected=\"([^\"]*)\"$"
        SELECTED_R = "selected=\"[^\"]*\""
        SELECTED_U = "selected=\"selected\""
        CHECKED_M = "\\schecked=\"[^\"]*\"\\s|\\schecked=\"[^\"]*\"$"
        CHECKED_M1 = "\\schecked=\"([^\"]*)\"\\s|\\schecked=\"([^\"]*)\"$"
        CHECKED_R = "checked=\"[^\"]*\""
        CHECKED_U = "checked=\"checked\""
        DISABLED_M = "\\sdisabled=\"[^\"]*\"\\s|\\sdisabled=\"[^\"]*\"$"
        DISABLED_M1 = "\\sdisabled=\"([^\"]*)\"\\s|\\sdisabled=\"([^\"]*)\"$"
        DISABLED_R = "disabled=\"[^\"]*\""
        DISABLED_U = "disabled=\"disabled\""
        READONLY_M = "\\sreadonly=\"[^\"]*\"\\s|\\sreadonly=\"[^\"]*\"$"
        READONLY_M1 = "\\sreadonly=\"([^\"]*)\"\\s|\\sreadonly=\"([^\"]*)\"$"
        READONLY_R = "readonly=\"[^\"]*\""
        READONLY_U = "readonly=\"readonly\""
        MULTIPLE_M = "\\smultiple=\"[^\"]*\"\\s|\\smultiple=\"[^\"]*\"$"
        MULTIPLE_M1 = "\\smultiple=\"([^\"]*)\"\\s|\\smultiple=\"([^\"]*)\"$"
        MULTIPLE_R = "multiple=\"[^\"]*\""
        MULTIPLE_U = "multiple=\"multiple\""

        HTTP_EQUIV = 'http-equiv'
        CONTENT_TYPE = 'Content-Type'
        CONTENT = 'content'

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

        TRUE = 'true'
        FALSE = 'false'

        TYPE_L = 'type'
        TYPE_U = 'TYPE'

        if RUBY_VERSION >= '1.9.0' then 
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
            "\n" => '<br/>',
          }
          
          PATTERN_ESCAPE = "[&\"'<> ]"
          PATTERN_ESCAPE_CONTENT = "[&\"'<> \\n]"
          @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
          @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)
          
        else
          
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
          
        end
        
        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt|nbsp);'
        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)
        
        #@@pattern_match_tag = Regexp.new(MATCH_TAG)
        @@pattern_set_mono1 = Regexp.new(SET_MONO_1)
        #@@pattern_match_tag2 = Regexp.new(MATCH_TAG_2)

        #
        # イニシャライザ
        # @param [Array] args 引数配列
        #
        def initialize(*args)
          super(args)
          case args.length
          when 0
            initialize_0
          when 1
            initialize_1(args[0])
          else
            raise ArgumentError
          end
        end

        #
        # イニシャライザ
        #
        def initialize_0
        end
        private :initialize_0

        #
        # イニシャライザ
        # 
        # @param [Meteor::Parser] ps パーサ
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          @root.hookDocument = String.new(ps.rootElement.hookDocument)
          @root.hook = ps.rootElement.hook
          @root.monoHook = ps.rootElement.monoHook
          @root.contentType = String.new(ps.contentType);
        end
        private :initialize_1

        #
        # ドキュメントをパーサにセットする
        # 
        # @param [String] document ドキュメント
        #
        def parse(document)
          @root.document = document
          analyzeML()
        end

        #
        # ファイルを読み込み、パーサにセットする
        # 
        # @param filePath ファイルパス
        # @param encoding エンコーディング
        #
        def read(filePath,encoding)
          super(filePath,encoding)
          analyzeML()
        end

        #
        # ドキュメントをパースする
        #
        def analyzeML()
          #mixed_content-typeの取得
          analyzeContentType()
          #改行コードの取得
          analyzeKaigyoCode()
          @res = nil
        end
        private :analyzeML

        #
        # コンテントタイプを取得する
        # 
        # @return [String] コンテントタイプ
        #
        def contentType()
          @root.contentType
        end

        #
        # ドキュメントをパースし、コンテントタイプをセットする
        #
        def analyzeContentType()
          @elm_ = element(META_S,HTTP_EQUIV,CONTENT_TYPE)
          
          if !@elm_ then
            @elm_ = element(META,HTTP_EQUIV,CONTENT_TYPE)
          end
          
          if @elm_ then
            @root.contentType = @elm_.attribute(CONTENT)
          else
            @root.contentType = EMPTY
          end
        end
        private :analyzeContentType

        #
        # ドキュメントをパースし、改行コードをセットする
        #
        def analyzeKaigyoCode()
          #改行コード取得
          @pattern = Regexp.new(KAIGYO_CODE)
          @res = @pattern.match(@root.document)

          if @res then
            @root.kaigyoCode = @res[1]
          end
        end
        private :analyzeKaigyoCode

        def editAttributes_(elm,attrName,attrValue)

          if isMatch(SELECTED, attrName) && isMatch(OPTION,elm.name) then
            editAttributes_5(elm,attrValue,@@pattern_selected_m,@@pattern_selected_r,SELECTED_U)
          elsif isMatch(MULTIPLE, attrName) && isMatch(SELECT,elm.name)
            editAttributes_5(elm,attrValue,@@pattern_multiple_m,@@pattern_multiple_r,MULTIPLE_U)
          elsif isMatch(DISABLED, attrName) && isMatch(DISABLE_ELEMENT, elm.name) then
            editAttributes_5(elm,attrValue,@@pattern_disabled_m,@@pattern_disabled_r,DISABLED_U)
          elsif isMatch(CHECKED, attrName) && isMatch(INPUT,elm.name) && isMatch(RADIO,getType(elm)) then
            editAttributes_5(elm,attrValue,@@pattern_checked_m,@@pattern_checked_r,CHECKED_U)
          elsif isMatch(READONLY, attrName) && (isMatch(TEXTAREA,elm.name) || (isMatch(INPUT,elm.name) && isMatch(READONLY_TYPE, getType(elm)))) then
            editAttributes_5(elm,attrValue,@@pattern_readonly_m,@@pattern_readonly_r,READONLY_U)
          else
            super(elm,attrName,attrValue)
          end

        end
        private :editAttributes_

        def editAttributes_5(elm,attrValue,match_p,replaceRegex,replaceUpdate)

          #attrValue = escape(attrValue)

          if isMatch(TRUE,attrValue) then

            @res = match_p.match(elm.attributes)

            if !@res then
              #属性文字列の最後に新規の属性を追加する
              if elm.attributes != EMPTY then
                elm.attributes = '' << SPACE << elm.attributes.strip
                #else
              end
              elm.attributes << SPACE << replaceUpdate
            else
              #属性の置換
              elm.attributes.gsub!(replaceRegex,replaceUpdate)
            end
          elsif isMatch(FALSE,attrValue) then
            #attrName属性が存在するなら削除
            #属性の置換
            elm.attributes.gsub!(replaceRegex, EMPTY)
          end
          
        end
        private :editAttributes_5
        
        def getAttributeValue_(elm,attrName)
          if isMatch(SELECTED, attrName) && isMatch(OPTION,elm.name)  then
            getAttributeValue_2_r(elm,attrName,@@pattern_selected_m1)
          elsif isMatch(MULTIPLE, attrName) && isMatch(SELECT,elm.name)
            getAttributeValue_2_r(elm,attrName,@@pattern_multiple_m1)
          elsif isMatch(DISABLED, attrName) && isMatch(DISABLE_ELEMENT, elm.name) then
            getAttributeValue_2_r(elm,attrName,@@pattern_disabled_m1)
          elsif isMatch(CHECKED, attrName) && isMatch(INPUT,elm.name) && isMatch(RADIO, getType(elm)) then
            getAttributeValue_2_r(elm,attrName,@@pattern_checked_m1)
          elsif isMatch(READONLY, attrName) && (isMatch(TEXTAREA,elm.name) || (isMatch(INPUT,elm.name) && isMatch(READONLY_TYPE, getType(elm)))) then
            getAttributeValue_2_r(elm,attrName,@@pattern_readonly_m1)
          else
            super(elm,attrName)
          end
        end
        private :getAttributeValue_

        def getType(elm)
          if !elm.type_value
            elm.type_value = getAttributeValue_2(elm, TYPE_L)
            if !elm.type_value then
              elm.type_value = getAttributeValue_2(elm, TYPE_U)
            end
          end
          elm.type_value
        end
        private :getType
        
        def getAttributeValue_2_r(elm,attrName,match_p)
          
          @res = match_p.match(elm.attributes)

          if @res then
            if @res[1] then
              if attrName == @res[1] then
                TRUE
              else
                @res[1]
              end
            elsif @res[2] then
              if attrName == @res[2] then
                TRUE
              else
                @res[2]
              end
            elsif @res[3] then
              if attrName == @res[3] then
                TRUE
              else
                @res[3]
              end
            elsif @res[4] then
              if attrName == @res[4] then
                TRUE
              else
                @res[4]
              end
            end
          else
            FALSE
          end
        end
        private :getAttributeValue_2_r
        
        #
        # 属性マップを取得する
        # 
        # @param [Meteor::Element] elm 要素
        # @return [Meteor::AttributeMap] 属性マップ
        #
        def getAttributeMap_1(elm)
          attrs = Meteor::AttributeMap.new
          
          elm.attributes.scan(@@pattern_get_attrs_map){ |a,b|
            if isMatch(ATTR_LOGIC,a) && a==b then
              attrs.store(a,TRUE)
            else
              attrs.store(a,unescape(b))
            end  
          }
          attrs.recordable = true
          
          attrs
        end
        private :getAttributeMap_1
        
        def setMonoInfo(elm)

          @res = @@pattern_set_mono1.match(elm.mixed_content)

          if @res then
            elm.mono = true
            if elm.cx then
              @pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
            else
              if elm.empty then
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
              else
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE3
              end
            end
            elm.document = @pattern_cc
          end
        end
        private :setMonoInfo

        def escape(element)
          #特殊文字の置換
          if RUBY_VERSION < '1.9.0' then
            #「&」->「&amp;」
            if element.include?(AND_1) then
              element.gsub!(@@pattern_and_1,AND_2)
            end
            #「<」->「&lt;」
            if element.include?(LT_1) then
              element.gsub!(@@pattern_lt_1,LT_2)
            end
            #「>」->「&gt;」
            if element.include?(GT_1) then
              element.gsub!(@@pattern_gt_1,GT_2)
            end
            #「"」->「&quotl」
            if element.include?(DOUBLE_QUATATION) then
              element.gsub!(@@pattern_dq_1,QO_2)
            end
             #「'」->「&apos;」
            if element.include?(AP_1) then
              element.gsub!(@@pattern_ap_1,AP_2)
            end
            #「 」->「&nbsp;」
            if element.include?(SPACE) then
              element.gsub!(@@pattern_space_1,NBSP_2)
            end
          else
            element.gsub!(@@pattern_escape,TABLE_FOR_ESCAPE_)
          end
            
          element
        end
        private :escape

        def escapeContent(element,elmName)
          
          if RUBY_VERSION < '1.9.0' then
            element = escape(element)
            
            if !isMatch(MATCH_TAG_2,elmName) then
              #「¥r?¥n」->「<br>」
              element.gsub!(@@pattern_br_1, BR_2)
            end
          else
            element.gsub!(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)
          end
          element
        end
        private :escapeContent

        def unescape(element)
          #特殊文字の置換
          #「<」<-「&lt;」
          #if element.include?(LT_2) then
          #  element.gsub!(@@pattern_lt_2,LT_1)
          #end
          #「>」<-「&gt;」
          #if element.include?(GT_2) then
          #  element.gsub!(@@pattern_gt_2,GT_1)
          #end
          #「"」<-「&quotl」
          #if element.include?(QO_2) then
          #  element.gsub!(@@pattern_dq_2,DOUBLE_QUATATION)
          #end
          #「 」<-「&nbsp;」
          #if element.include?(NBSP_2) then
          #  element.gsub!(@@pattern_space_2,SPACE)
          #end
          #「&」<-「&amp;」
          #if element.include?(AND_2) then
          #  element.gsub!(@@pattern_and_2,AND_1)
          #end
          element.gsub!(@@pattern_unescape){
            case $1
            when 'amp' then '&'
            when 'quot' then '"'
            when 'apos' then '\''
            when 'gt' then '>'
            when 'lt' then '<'
            when 'nbsp' then ' '
            end
          }
          
          element
        end
        private :unescape

        def unescapeContent(element,elmName)
          element = unescape(element)

          if !isMatch(MATCH_TAG_2,elmName) then
            #「<br>」->「¥r?¥n」
            if element.include?(BR_2) then
              element.gsub!(@@pattern_br_2, @root.kaigyoCode)
            end
          end

          element
        end
        private :unescapeContent

      end
    end

    module Xml

      #
      # XMLパーサ
      #
      class ParserImpl < Meteor::Core::Kernel

        TABLE_FOR_ESCAPE_ = {
          '&' => '&amp;',
          '"' => '&quot;',
          '\'' => '&apos;',
          '<' => '&lt;',
          '>' => '&gt;',
        }
        
        PATTERN_ESCAPE = "[&\"'<>]"
        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt);'
        
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
        
        @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)
        
        @@pattern_set_mono1 = Regexp.new(SET_MONO_1)

        #
        # イニシャライザ
        # 
        # @param [Array] args 引数配列
        #
        def initialize(*args)
          super(args)

          case args.length
          when 0
            initialize_0
          when 1
            initialize_1(args[0])
          else
            raise ArgumentError
          end
        end

        #
        # イニシャライザ
        #
        def initialize_0
        end

        #
        # イニシャライザ
        # 
        # @param [Meteor::Parser] ps パーサ
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          @root.hookDocument = String.new(ps.rootElement.hookDocument)
          @root.hook = ps.rootElement.hook
          @root.monoHook = ps.rootElement.monoHook
          @root.contentType = String.new(ps.contentType);
        end

        #
        # ドキュメントをパーサにセットする
        # 
        # @param [String] document ドキュメント
        #
        def parse(document)
          @root.document = document
        end

        #
        # ファイルを読み込み、パーサにセットする
        # 
        # @param filePath ファイルパス
        # @param encoding エンコーディング
        #
        def read(filePath,encoding)
          super(filePath, encoding)
        end
        
        # コンテントタイプを取得する
        # 
        # @return [Streing]コンテントタイプ
        #
        def contentType()
          @root.contentType
        end
        
        def setMonoInfo(elm)

          @res = @@pattern_set_mono1.match(elm.mixed_content)

          if @res then
            elm.mono = true
            if elm.cx then
              @pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
            else
              if elm.empty then
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
              else
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE3
              end
            end
            elm.document = @pattern_cc
          end
        end
        private :setMonoInfo

        def escape(element)
          #特殊文字の置換
          if RUBY_VERSION < '1.9.0' then
            #「&」->「&amp;」
            if element.include?(AND_1) then
              element.gsub!(@@pattern_and_1,AND_2)
            end
            #「<」->「&lt;」
            if element.include?(LT_1) then
              element.gsub!(@@pattern_lt_1,LT_2)
            end
            #「>」->「&gt;」
            if element.include?(GT_1) then
              element.gsub!(@@pattern_gt_1,GT_2)
            end
            #「"」->「&quot;」
            if element.include?(DOUBLE_QUATATION) then
              element.gsub!(@@pattern_dq_1,QO_2)
            end
            #「'」->「&apos;」
            if element.include?(AP_1) then
              element.gsub!(@@pattern_ap_1,AP_2)
            end
          else
            element.gsub!(@@pattern_escape,TABLE_FOR_ESCAPE_)
          end

          element
        end
        private :escape

        def escapeContent(element,elmName)
          escape(element)
        end
        private :escapeContent

        def unescape(element)
          #特殊文字の置換
          #if RUBY_VERSION < '1.9.0' then
          #  #「<」<-「&lt;」
          #  if element.include?(LT_2) then
          #    element.gsub!(@@pattern_lt_2,LT_1)
          #  end
          #  #「>」<-「&gt;」
          #  if element.include?(GT_2) then
          #    element.gsub!(@@pattern_gt_2,GT_1)
          #  end
          #  #「"」<-「&quot;」
          #  if element.include?(QO_2) then
          #    element.gsub!(@@pattern_dq_2,DOUBLE_QUATATION)
          #  end
          #  #「'」<-「&apos;」
          #  if element.include?(AP_2) then
          #    element.gsub!(@@pattern_ap_2,AP_1)
          #  end
          #  #「&」<-「&amp;」
          #  if element.include?(AND_2) then
          #    element.gsub!(@@pattern_and_2,AND_1)
          #  end
          #else
          element.gsub!(@@pattern_unescape){
            case $1
            when 'amp' then '&'
            when 'quot' then '"'
            when 'apos' then '\''
            when 'gt' then '>'
            when 'lt' then '<'
            end
          }
          #end
            
          element
        end
        private :unescape

        def unescapeContent(element,elmName)
          unescape(element)
        end
        private :unescapeContent

      end
    end
  end
end