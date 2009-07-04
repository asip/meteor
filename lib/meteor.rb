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
# @version 0.9.2.6
#

module Meteor

  VERSION = "0.9.2.6"

  RUBY_VERSION_1_9_0 = '1.9.0'

  if RUBY_VERSION < RUBY_VERSION_1_9_0 then
    require 'Kconv'
  end

  ZERO = 0
  ONE = 1
  TWO = 2
  THREE = 3
  FOUR = 4
  FIVE = 5
  SIX = 6
  SEVEN = 7

  CONTENT_STR = ':content'

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
          #@arguments = AttributeMap.new(args[0].arguments)
          #@usable = false
          @origin = args[0]
          args[0].copy = self
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
      #@arguments = AttributeMap.new
      @usable = true
    end
    private :initialize_s

    #
    # イニシャライザ
    # @param [Meteor::Element] elm 要素
    #
    def initialize_e(elm)
      #if !elm.origin then
      @name = elm.name
      @attributes = String.new(elm.attributes)
      #@pattern = String.new(elm.pattern)
      @pattern = elm.pattern
      @document = String.new(elm.document)
      @empty = elm.empty
      @cx = elm.cx
      @mono = elm.mono
      #@arguments = AttributeMap.new(elm.arguments)
      @origin = elm
      #else
      #  @name = elm.origin.name
      #  @attributes = String.new(elm.origin.attributes)
      #  @pattern = String.new(elm.origin.pattern)
      #  @document = String.new(elm.origin.document)
      #  @empty = elm.origin.empty
      #  @cx = elm.origin.cx
      #  @mono = elm.origin.mono
      #  @arguments = AttributeMap.new(elm.origin.arguments)
      #  @origin = elm
      #end
      @parser = elm.parser
      @usable = true
    end
    private :initialize_e

    attr_accessor :name #要素名
    attr_accessor :attributes #属性群
    attr_accessor :mixed_content #内容
    attr_accessor :pattern #パターン
    #attr_accessor :document #ドキュメント
    #attr_writer :document
    attr_accessor :document_sync
    attr_accessor :empty #内容存在フラグ
    attr_accessor :cx #コメント拡張タグフラグ
    attr_accessor :mono #子要素存在フラグ
    attr_accessor :parser #パーサ
    attr_accessor :type_value #タイプ属性
    #attr_accessor :arguments #パターン変更用属性マップ
    attr_accessor :usable #有効・無効フラグ
    attr_accessor :origin #原本ポインタ
    attr_accessor :copy #複製ポインタ

    #
    # コピーを作成する
    # @param [Array] args 引数配列
    #
    def self.new!(*args)
      case args.length
        when ONE
          #self.new_1!(args[0])
          args[0].clone
        when TWO
          @obj = args[1].root_element.element
          if @obj then
            @obj.attributes = String.new(args[0].attributes)
            @obj.mixed_content = String.new(args[0].mixed_content)
            #@obj.pattern = String.new(args[0].pattern)
            @obj.document = String.new(args[0].document)
            #@obj.arguments = AttributeMap.new(args[0].arguments)
            @obj
          else
            @obj = self.new(args[0],args[1])
            args[1].root_element.element = @obj
            @obj
          end
      end
    end

    #
    # 複製する 
    #
    def clone
      obj = self.parser.element_cache[self.object_id]
      if obj then
        obj.attributes = String.new(self.attributes)
        obj.mixed_content = String.new(self.mixed_content)
        #obj.pattern = String.new(self.pattern)
        obj.document = String.new(self.document)
        #obj.arguments = AttributeMap.new(self.arguments)
        obj.usable = true
        obj
      else
        obj = self.new(self)
        self.parser.element_cache[self.object_id] = obj
        obj
      end
    end

    #
    # 子要素を取得する
    #
    # @param [Array] args 引数配列
    # @return [Element] 子要素
    #
    def child(*args)
      @parser.element(*args)
    end

    #
    # CX(コメント拡張)タグを取得する
    # 
    # @param [Array] args 引数配列
    # @return [Meteor::Element] 要素
    #
    def cxtag(*args)
      @parser.cxtag(*args)
    end
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
    def attribute_map
      @parser.attribute_map(self)
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
    # 内容をセットする
    #
    # @param [String] value 内容
    #
    def content=(value)
      @parser.content(self,value)
    end

    #
    # 属性を編集するor内容をセットする
    # 
    # @param [String] name 属性の名前
    # @param [String] value 属性の値or内容
    #
    def []=(name,value)
      #if !name.kind_of?(String) || CONTENT_STR != name then
      if CONTENT_STR != name then
        attribute(name,value)
      else
        @parser.content(self,value)
      end
    end

    #
    # 属性の値or内容を取得する
    # 
    # @param [String] name 属性の名前
    # @return [String] 属性の値or内容
    #
    def [](name)
      #if !name.kind_of?(String) || CONTENT_STR != name  then
      if CONTENT_STR != name then
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
    def remove_attribute(*args)
      @parser.remove_attribute(self,*args)
    end

    def document=(doc)
      @document_sync = false
      @document = doc
    end

    def document
      if @document_sync then
        @document_sync = false
        case @parser.doc_type
          when Parser::HTML then
            if @cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = '' << Meteor::Core::Kernel::TAG_OPEN << @name << @attributes << Meteor::Core::Kernel::TAG_CLOSE
              end
            end
          when Parser::XHTML,Parser::XML then
            if @cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = '' << Meteor::Core::Kernel::TAG_OPEN << @name << @attributes << Meteor::Core::Kernel::TAG_CLOSE3
              end
            end
        end
      else
        @document
      end
    end

    #
    # 要素を削除する
    #
    def remove
      @parser.remove_element(self)
    end

    def flush
      @parser.flush
    end

    #
    # フッククラスの処理を実行する
    # @param [Array] args 引数配列
    #
    def execute(*args)
      @parser.execute(self,*args)
    end

  end

  #
  # ルート要素クラス
  #
  class RootElement

    EMPTY = ''

    #
    # イニシャライザ
    #
    def initialize()
      #コンテントタイプ
      #@contentType = ''
      #改行コード
      #@kaigyoCode = ''
      #文字コード
      #@character_encoding=''

      #フックドキュメント
      @hook_document = ''
      #変更可能要素
      #@element = nil
    end

    attr_accessor :content_type
    attr_accessor :kaigyo_code
    attr_accessor :character_encoding
    attr_accessor :document
    attr_accessor :hook_document
    attr_accessor :element
  end

  #
  # 属性マップクラス
  #
  class AttributeMap

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
    # イニシャライザ
    #
    def initialize_0
      @map = Hash.new
      if RUBY_VERSION < RUBY_VERSION_1_9_0
        @names = Array.new
      end
      @recordable = false
    end
    private :initialize_0

    #
    # イニシャライザ
    #
    def initialize_1(attr_map)
      #@map = Marshal.load(Marshal.dump(attrMap.map))
      @map = attr_map.map.dup
      if RUBY_VERSION < RUBY_VERSION_1_9_0
        @names = Array.new(attr_map.names)
      end
      @recordable = attr_map.recordable
    end
    private :initialize_1

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
        if RUBY_VERSION < RUBY_VERSION_1_9_0
          @names << name
        end
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
    # 属性名配列を取得する
    # 
    # @return [Array] 属性名配列
    #
    def names
      if RUBY_VERSION < RUBY_VERSION_1_9_0
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
      if @recordable && @map[name] then
        @map[name].removed = true
        @map[name].changed = false
      end
    end

    #
    # 属性名で属性の変更状況を取得する
    # 
    # @return [TrueClass,FalseClass] 属性の変更状況
    #
    def changed(name)
      if @map[name] then
        @map[name].changed
      end
    end

    #
    # 属性名で属性の削除状況を取得する
    # 
    # @return [TrueClass,FalseClass] 属性の削除状況
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
    HTML = ZERO
    XHTML = ONE
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
        when THREE
          build_3(args[0],args[1],args[2])
        when TWO
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
          html.doc_type = Parser::HTML
          psf.parser = html
        when Parser::XHTML then
          xhtml = Meteor::Core::Xhtml::ParserImpl.new()
          xhtml.read(path, encoding)
          xhtml.doc_type = Parser::XHTML
          psf.parser = xhtml
        when Parser::XML then
          xml = Meteor::Core::Xml::ParserImpl.new()
          xml.read(path, encoding)
          xml.doc_type = Parser::XML
          psf.parser = xml
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
          html.doc_type = Parser::HTML
          psf.parser = html
        when Parser::XHTML then
          xhtml = Meteor::Core::Xhtml::ParserImpl.new()
          xhtml.parse(document)
          xhtml.doc_type = Parser::XHTML
          psf.parser = xhtml
        when Parser::XML then
          xml = Meteor::Core::Xml::ParserImpl.new()
          xml.parse(document)
          xml.doc_type = Parser::XML
          psf.parser = xml
      end

      psf
    end
    #protected :build_2

    #
    # パーサをセットする
    # 
    # @param [Meteor::Parser] パーサ
    #
    def parser=(pif)
      @pif = pif
    end

    #
    # パーサを取得する
    # 
    # @return [Meteor::Parser] パーサ
    #
    def parser

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

      def do_action(elm)
        #内容あり要素の場合
        if elm.empty then
          elm2 = elm.child(elm)
          execute(elm2)
        end
      end

      def execute(elm)
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

      def do_action(elm,list)
        #内容あり要素の場合
        if elm.empty then
          elm2 = elm.child(elm)
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

      def init(elm)
      end
      private :init

      def execute(elm,item)
      end
      private :execute

    end
  end

  module Core

    #
    # パーサコアクラス
    #
    class Kernel < Meteor::Parser

      EMPTY = ''
      SPACE = ' '
      DOUBLE_QUATATION = '"'
      TAG_OPEN = '<'
      TAG_OPEN3 = '</'
      TAG_OPEN4 = '<\\\\/'
      TAG_CLOSE = '>'
      TAG_CLOSE2 = '\\/>'
      TAG_CLOSE3 = '/>'
      ATTR_EQ = '="'
      #element
      #TAG_SEARCH_1_1 = "([^<>]*)>(((?!(<\\/"
      TAG_SEARCH_1_1 = '(\\s?[^<>]*)>(((?!('
      #TAG_SEARCH_1_2 = ")).)*)<\\/";
      TAG_SEARCH_1_2 = '[^<>]*>)).)*)<\\/'
      TAG_SEARCH_1_3 = '(\\s?[^<>]*)\\/>'
      #TAG_SEARCH_1_4 = "([^<>\\/]*)>"
      TAG_SEARCH_1_4 = '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_1_4_2 = '(\\s[^<>]*)>'

      TAG_SEARCH_NC_1_1 = '\\s?[^<>]*>((?!('
      TAG_SEARCH_NC_1_2 = '[^<>]*>)).)*<\\/'
      TAG_SEARCH_NC_1_3 = '\\s?[^<>]*\\/>'
      TAG_SEARCH_NC_1_4 = '(?:\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_NC_1_4_2 = '\\s[^<>]*>'

      #TAG_SEARCH_2_1 = "\\s([^<>]*"
      TAG_SEARCH_2_1 = '(\\s[^<>]*'
      TAG_SEARCH_2_1_2 = '(\\s[^<>]*(?:'
      #TAG_SEARCH_2_2 = "\"[^<>]*)>(((?!(<\\/"
      TAG_SEARCH_2_2 = '"[^<>]*)>(((?!('
      TAG_SEARCH_2_2_2 = '")[^<>]*)>(((?!('
      TAG_SEARCH_2_3 = '"[^<>]*)'
      TAG_SEARCH_2_3_2 = '"[^<>]*)\\/>'
      TAG_SEARCH_2_3_2_2 = '")[^<>]*)\\/>'
      #TAG_SEARCH_2_4 = "\"[^<>\\/]*>"
      TAG_SEARCH_2_4 = '(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      #TAG_SEARCH_2_4_2 = "\"[^<>\\/]*)>"
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
      #TAG_SEARCH_4_3 = "\\s[^<>\\/]*>"
      TAG_SEARCH_4_3 = '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      TAG_SEARCH_4_4 = '<\\/'
      TAG_SEARCH_4_5 = '.*?<\/'
      TAG_SEARCH_4_6 = '.*?)<\/'
      #TAG_SEARCH_4_7 = '\"[^<>\\/]*)>(''
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
      SEARCH_CX_2 = '\\s([^<>]*id="'
      SEARCH_CX_3 = '"[^<>]*)-->(((?!(<!--\\s/@'
      SEARCH_CX_4 = ')).)*)<!--\\s/@'
      SEARCH_CX_5 = '\\s-->'
      SEARCH_CX_6 = '<!--\\s@([^<>]*)\\s[^<>]*id="'

      #setElementToCXTag
      SET_CX_1 = '<!-- @'
      SET_CX_2 = '-->'
      SET_CX_3 = '<!-- /@'
      SET_CX_4 = ' -->'

      #setMonoInfo
      SET_MONO_1 = '\\A[^<>]*\\Z'

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

      #@@pattern_sub_regex1 = Regexp.new(SUB_REGEX1)

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
        if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
          @element_cache = Hash.new()
        else
          @element_cache = Meteor::Core::Util::OrderHash.new
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
        #@sbuf = ''
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

      attr_accessor :element_cache
      attr_accessor :doc_type

      #
      # 文字エンコーディングをセットする
      # 
      # @param [String] enc 文字エンコーディング
      #
      def character_encoding=(enc)
        @root.character_encoding = enc
      end

      #
      # 文字エンコーディングを取得する
      # 
      # @param [String] 文字エンコーディング
      #
      def character_encoding
        @root.character_encoding
      end

      #
      # ルート要素を取得する
      # 
      # @return [Meteor::RootElement] ルート要素
      #
      def root_element
        @root
      end

      #
      # ファイルを読み込み、パーサにセットする
      #
      # @param [String] filePath 入力ファイルの絶対パス
      # @param [String] encoding 入力ファイルの文字コード
      #
      def read(file_path, encoding)

        #try {
        @character_encoding = encoding
        #ファイルのオープン
        if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
          io = File.open(file_path,'r:' << encoding)
          #読込及び格納
          @root.document = io.read
        else
          #読込及び格納
          io = open(file_path,'r')
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
        case @character_encoding
          when 'UTF-8'
            Kconv::UTF8
          when 'ISO-2022-JP'
            Kconv::JIS
          when 'Shift_JIS'
            Kconv::SJIS
          when 'EUC-JP'
            Kconv::EUC
          when 'ASCII'
            Kconv::ASCII
          #when "UTF-16"
          #  return KConv::UTF16
          else
            Kconv::UTF8
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
          when ONE
            if args[0].kind_of?(String) then
              element_1(args[0])
              if @elm_ then
                @element_cache.store(@elm_.object_id,@elm_)
              end
            elsif args[0].kind_of?(Meteor::Element) then
              shadow(args[0])
            else
              raise ArgumentError
            end
          when TWO
            element_2(args[0],args[1])
            if @elm_ then
              @element_cache.store(@elm_.object_id,@elm_)
            end
          when THREE
            element_3(args[0],args[1],args[2])
            if @elm_ then
              @element_cache.store(@elm_.object_id,@elm_)
            end
          when FOUR
            element_4(args[0],args[1],args[2],args[3])
            if @elm_ then
              @element_cache.store(@elm_.object_id,@elm_)
            end
          when FIVE
            element_5(args[0],args[1],args[2],args[3],args[4])
            if @elm_ then
              @element_cache.store(@elm_.object_id,@elm_)
            end
          else
            @elm_ = nil
            raise ArgumentError
        end
      end

      #
      # 要素名で検索し、要素を取得する
      #
      # @param [String] elm_name 要素名
      # @return [Meteor::Element] 要素
      #
      def element_1(elm_name)

        @_elm_name = escape_regex(elm_name)

        #空要素検索用パターン
        @pattern_cc_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_1_3

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        #空要素検索
        @res1 = @pattern.match(@root.document)

        #内容あり要素検索用パターン
        #@pattern_cc_2 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_1_1 << elm_name
        #@pattern_cc_2 << TAG_SEARCH_1_2 << @_elm_name << TAG_CLOSE
        @pattern_cc_2 = "<#{@_elm_name}(\\s?[^<>]*)>(((?!(#{@_elm_name}[^<>]*>)).)*)<\\/#{@_elm_name}>"


        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        #内容あり要素検索
        @res2 = @pattern.match(@root.document)

        if @res1 && @res2 then
          if @res1.end(0) < @res2.end(0) then
            @res = @res1
            @pattern_cc = @pattern_cc_1
            element_without_1(elm_name)
          elsif @res1.end(0) > @res2.end(0)
            @res = @res2
            @pattern_cc = @pattern_cc_2
            element_with_1(elm_name)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          @pattern_cc = @pattern_cc_1
          element_without_1(elm_name)
        elsif !@res1 && @res2 then
          @res = @res2
          @pattern_cc = @pattern_cc_2
          element_with_1(elm_name)
        elsif !@res1 && !@res2 then
          @elm_ = nil
          #raise NoSuchElementException.new(elm_name);
        end

        @elm_
      end
      private :element_1

      def element_with_1(elm_name)

        @elm_ = Element.new(elm_name)
        #属性
        @elm_.attributes = @res[1]
        #内容
        @elm_.mixed_content = @res[2]
        #全体
        @elm_.document = @res[0]

        #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_NC_1_1 << elm_name
        #@pattern_cc << TAG_SEARCH_NC_1_2 << @_elm_name << TAG_CLOSE
        @pattern_cc = "<#{@_elm_name}\\s?[^<>]*>((?!(#{@_elm_name}[^<>]*>)).)*<\\/#{@_elm_name}>"

        #内容あり要素検索用パターン
        @elm_.pattern = @pattern_cc

        @elm_.empty = true

        @elm_.parser = self

        @elm_
      end
      private :element_with_1

      def element_without_1(elm_name)
        #要素
        @elm_ = Element.new(elm_name)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_NC_1_3
        @elm_.pattern = @pattern_cc

        @elm_.empty = false

        @elm_.parser = self

        @elm_
      end
      private :element_without_1

      #
      # 要素名と属性で検索し、要素を取得する
      #
      # @param [String] elm_name  要素名
      # @param [String] attrName 属性名
      # @param [String] attr_value 属性値
      # @return [Meteor::Element] 要素
      #
      def element_3(elm_name,attr_name,attr_value)

        @_elm_name = escape_regex(elm_name)
        @_attr_name = escape_regex(attr_name)
        @_attr_value = escape_regex(attr_value)

        #空要素検索用パターン
        #@pattern_cc_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1 << @_attr_value << TAG_SEARCH_2_3_2
        @pattern_cc_1 = "<#{@_elm_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        #空要素検索
        @res1 = @pattern.match(@root.document)

        #内容あり要素検索パターン
        #@pattern_cc_2 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_2 << @_attr_value << TAG_SEARCH_2_2 << @_elm_name
        #@pattern_cc_2 << TAG_SEARCH_1_2 << @_elm_name << TAG_CLOSE
        @pattern_cc_2 = "<#{@_elm_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_elm_name}[^<>]*>)).)*)<\\/#{@_elm_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        #内容あり要素検索
        @res2 = @pattern.match(@root.document)

        if !@res2 then
          @res2 = element_with_3_2(elm_name)
          @pattern_cc_2 = @pattern_cc
        end

        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
            @res = @res1
            @pattern_cc = @pattern_cc_1
            element_without_3(elm_name)
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            @pattern_cc = @pattern_cc_2
            element_with_3_1(elm_name)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          @pattern_cc = @pattern_cc_1
          element_without_3(elm_name)
        elsif !@res1 && @res2 then
          @res = @res2
          @pattern_cc = @pattern_cc_2
          element_with_3_1(elm_name)
        elsif !@res1 && !@res2 then
          @elm_ = nil
          #raise NoSuchElementException.new(elm_name,attr_name,attr_value);
        end

        #if @elm_ then
        #  @elm_.arguments.store(attr_name, attr_value)
        #  @elm_.arguments.recordable = true
        #end

        @elm_
      end
      private :element_3

      def element_with_3_1(elm_name)

        if @res.captures.length == FOUR then
          #要素
          @elm_ = Element.new(elm_name)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = ''<< TAG_OPEN << @_elm_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
          #@pattern_cc << @_attr_value << TAG_SEARCH_NC_2_2 << @_elm_name
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_elm_name << TAG_CLOSE
          @pattern_cc = "<#{@_elm_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_elm_name}[^<>]*>)).)*<\\/#{@_elm_name}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        elsif @res.captures.length == SIX then
          #内容
          @elm_ = Element.new(elm_name)
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

      def element_with_3_2(elm_name)

        #@pattern_cc_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1 << @_attr_value << TAG_SEARCH_2_4_2
        @pattern_cc_1 = "<#{@_elm_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"

        @pattern_cc_1b = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_1_4

        #@pattern_cc_1_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value << TAG_SEARCH_4_7
        @pattern_cc_1_1 = "<#{@_elm_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_elm_name << TAG_SEARCH_4_3

        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_elm_name << TAG_CLOSE

        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_elm_name << TAG_CLOSE

        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_elm_name << TAG_CLOSE

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = '';

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b);

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf

        if @sbuf.length == ZERO || @cnt != ZERO then
          #  raise NoSuchElementException.new(elm_name,attr_name,attr_value);
          return nil;
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end
      private :element_with_3_2

      def element_without_3(elm_name)
        element_without_3_1(elm_name,TAG_SEARCH_NC_2_3_2)
      end
      private :element_without_3

      def element_without_3_1(elm_name,closer)

        #要素
        @elm_ = Element.new(elm_name)
        #属性
        @elm_.attributes = @res[1];
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        @pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_NC_2_1 << @_attr_name << ATTR_EQ
        @pattern_cc << @_attr_value << closer
        @elm_.pattern = @pattern_cc

        @elm_.parser = self

        @elm_
      end
      private :element_without_3_1

      #
      # 属性(属性名="属性値")で検索し、要素を取得する
      #
      # @param [String] attr_name 属性名
      # @param [String] attr_value 属性値
      # @return [Meteor::Element] 要素
      #
      def element_2(attr_name,attr_value)

        @_attr_name = escape_regex(attr_name)
        @_attr_value = escape_regex(attr_value)

        ##@pattern_cc = '' << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value << TAG_SEARCH_2_4
        #@pattern_cc = '' << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value << TAG_SEARCH_2_4_2_3
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\""

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
          element_3(@res[1], attr_name, attr_value)
        else
          @elm_ = nil
        end

        @elm_
      end
      private :element_2

      #
      # 要素名と属性1・属性2で検索し、要素を取得する
      # 
      # @param [String] elm_name  要素の名前
      # @param [String] attr_name1 属性名1
      # @param [String] attr_value1 属性値2
      # @param [String] attr_name2 属性名2
      # @param [String] attr_value2 属性値2
      # @return [Meteor::Element] 要素
      #
      def element_5(elm_name,attr_name1,attr_value1,attr_name2,attr_value2)

        @_elm_name = escape_regex(elm_name)
        @_attr_name1 = escape_regex(attr_name1)
        @_attr_name2 = escape_regex(attr_name2)
        @_attr_value1 = escape_regex(attr_value1)
        @_attr_value2 = escape_regex(attr_value2)

        #空要素検索用パターン
        #@pattern_cc_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_3_2_2
        @pattern_cc_1 = "<#{@_elm_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)\\/>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        #空要素検索
        @res1 = @pattern.match(@root.document)

        #内容あり要素検索パターン
        #@pattern_cc_2 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_2 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_2 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_2 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_2 << @_attr_value1 << TAG_SEARCH_2_2_2 << @_elm_name
        #@pattern_cc_2 << TAG_SEARCH_1_2 << @_elm_name << TAG_CLOSE
        @pattern_cc_1 = "<#{@_elm_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_elm_name}[^<>]*>)).)*)<\\/#{@_elm_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        #内容あり要素検索
        @res2 = @pattern.match(@root.document)

        if !@res2 then
          @res2 = element_with_5_2(elm_name)
          @pattern_cc_2 = @pattern_cc
        end

        if @res1 && @res2 then
          if @res1.begin(0) < @res2.begin(0) then
            @res = @res1
            @pattern_cc = @pattern_cc_1
            element_without_5(elm_name)
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            @pattern_cc = @pattern_cc_2
            element_with_5_1(elm_name)
          end
        elsif @res1 && !@res2 then
          @res = @res1
          @pattern_cc = @pattern_cc_1
          element_without_5(elm_name)
        elsif !@res1 && @res2 then
          @res = @res2
          @pattern_cc = @pattern_cc_2
          element_with_5_1(elm_name)
        elsif !@res1 && !@res2 then
          @elm_ = nil
          #raise NoSuchElementException.new(elm_name,attr_name1,attr_value1,attr_name2,attr_value2);
        end

        #if @elm_ then
        #  @elm_.arguments.store(attr_name1, attr_value1)
        #  @elm_.arguments.store(attr_name2, attr_value2)
        #  @elm_.arguments.recordable = true
        #end

        @elm_
      end
      private :element_5

      def element_with_5_1(elm_name)

        if @res.captures.length == FOUR then
          #要素
          @elm_ = Element.new(elm_name)
          #属性
          @elm_.attributes = @res[1]
          #内容
          @elm_.mixed_content = @res[2]
          #全体
          @elm_.document = @res[0]
          #内容あり要素検索用パターン
          #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
          #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
          #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_2_2 << @_elm_name
          #@pattern_cc << TAG_SEARCH_NC_1_2 << @_elm_name << TAG_CLOSE
          @pattern_cc = "<#{@_elm_name}\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*>((?!(#{@_elm_name}[^<>]*>)).)*<\\/#{@_elm_name}>"

          @elm_.pattern = @pattern_cc
          #
          @elm_.empty = true

          @elm_.parser = self

        elsif @res.captures.length == SIX then

          @elm_ = Element.new(elm_name)
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

      def element_with_5_2(elm_name)

        #@pattern_cc_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1 << @_attr_value1 << TAG_SEARCH_2_4_2_2
        @pattern_cc_1 = "<#{@_elm_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))"

        @pattern_cc_1b = '' << TAG_OPEN << elm_name << TAG_SEARCH_1_4

        #@pattern_cc_1_1 = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc_1_1 << @_attr_value1 << TAG_SEARCH_4_7_2
        @pattern_cc_1 = "<#{@_elm_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("

        @pattern_cc_1_2 = '' << TAG_SEARCH_4_2 << @_elm_name << TAG_SEARCH_4_3

        @pattern_cc_2 = '' << TAG_SEARCH_4_4 << @_elm_name << TAG_CLOSE

        @pattern_cc_2_1 = '' << TAG_SEARCH_4_5 << @_elm_name << TAG_CLOSE

        @pattern_cc_2_2 = '' << TAG_SEARCH_4_6 << @_elm_name << TAG_CLOSE

        #内容あり要素検索
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = ''

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b);

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf

        if @sbuf.length == ZERO || @cnt != ZERO then
          #  raise NoSuchElementException.new(elm_name,attr_name1,attr_value1,attr_name2,attr_value2);
          return nil
        end

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end
      private :element_with_5_2

      def element_without_5(elm_name)
        element_without_5_1(elm_name,TAG_SEARCH_NC_2_3_2_2);
      end
      private :element_without_5

      def element_without_5_1(elm_name,closer)

        #要素
        @elm_ = Element.new(elm_name)
        #属性
        @elm_.attributes = @res[1]
        #全体
        @elm_.document = @res[0]
        #空要素検索用パターン
        #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_NC_2_1_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_NC_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_NC_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << closer
        @pattern_cc = "<#{@_elm_name}\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}#{closer}"

        @elm_.pattern = @pattern_cc

        @elm_.parser = self

        @elm_
      end
      private :element_without_5_1

      #
      # 属性1・属性2(属性名="属性値")で検索し、要素を取得する
      #
      # @param [String] attr_name1 属性名1
      # @param [String] attr_value1 属性値1
      # @param [String] attr_name2 属性名2
      # @param [String]attr_value2 属性値2
      # @return [Meteor::Element] 要素
      #
      def element_4(attr_name1,attr_value1,attr_name2,attr_value2)

        @_attr_name1 = escape_regex(attr_name1)
        @_attr_name2 = escape_regex(attr_name2)
        @_attr_value1 = escape_regex(attr_value1)
        @_attr_value2 = escape_regex(attr_value2)

        #@pattern_cc = '' << TAG_SEARCH_3_1_2_2 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
        #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
        #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_4_2_3
        @pattern_cc = "<([^<>\"]*)\\s([^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\""

        @pattern = PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res then
          #@elm_ = element_5(@res[1], attr_name1, attr_value1,attr_name2, attr_value2);
          element_5(@res[1], attr_name1, attr_value1,attr_name2, attr_value2);
        else
          @elm_ = nil
        end

        @elm_
      end
      private :element_4

      def create_element_pattern

        if RUBY_VERSION >= RUBY_VERSION_1_9_0 then

          @position = 0

          while (@res = @pattern.match(@root.document,@position)) || @cnt > ZERO

            if @res then

              if @cnt > ZERO then

                @position2 = @res.end(0)

                @res = @pattern_2.match(@root.document,@position)

                if @res then

                  @position = @res.end(0)

                  if @position > @position2 then

                    if @cnt == ZERO then
                      @sbuf << @pattern_cc_1_1
                    else
                      @sbuf << @pattern_cc_1_2
                    end

                    @cnt += 1

                    @position = @position2
                  else

                    @cnt -= ONE

                    if @cnt != ZERO then
                      @sbuf << @pattern_cc_2_1
                    else
                      @sbuf << @pattern_cc_2_2
                    end

                    if @cnt == ZERO then
                      break
                    end
                  end
                else

                  if @cnt == ZERO then
                    @sbuf << @pattern_cc_1_1
                  else
                    @sbuf << @pattern_cc_1_2
                  end

                  @cnt += 1

                  @position = @position2
                end
              else
                @position = @res.end(0)

                if @cnt == ZERO then
                  @sbuf << @pattern_cc_1_1
                else
                  @sbuf << @pattern_cc_1_2
                end

                @cnt += ONE
              end
            else

              @res = @pattern_2.match(@root.document,@position)

              if @res then

                @cnt -= ONE

                if @cnt != ZERO then
                  @sbuf << @pattern_cc_2_1
                else
                  @sbuf << @pattern_cc_2_2
                end

                @position = @res.end(0)
              end

              if @cnt == ZERO then
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

          while (@res = @pattern.match(@rx_document)) || @cnt > ZERO

            if @res then

              if @cnt > ZERO then

                @rx_document2 = @res.post_match

                @res = @pattern_2.match(@rx_document)

                if @res then

                  @rx_document = @res.post_match

                  if @rx_document2.length > @rx_document.length then

                    if @cnt == ZERO then
                      @sbuf << @pattern_cc_1_1
                    else
                      @sbuf << @pattern_cc_1_2
                    end

                    @cnt += ONE

                    @rx_document = @rx_document2
                  else

                    @cnt -= ONE

                    if @cnt != ZERO then
                      @sbuf << @pattern_cc_2_1
                    else
                      @sbuf << @pattern_cc_2_2
                    end

                    if @cnt == ZERO then
                      break
                    end
                  end
                else

                  if @cnt == ZERO then
                    @sbuf << @pattern_cc_1_1
                  else
                    @sbuf << @pattern_cc_1_2
                  end

                  @cnt += ONE

                  @rx_document = @rx_document2
                end
              else
                @rx_document = @res.post_match

                if @cnt == ZERO then
                  @sbuf << @pattern_cc_1_1
                else
                  @sbuf << @pattern_cc_1_2
                end

                @cnt += ONE
              end
            else

              @res = @pattern_2.match(@rx_document)

              if @res then

                @cnt -= ONE

                if @cnt != ZERO then
                  @sbuf << @pattern_cc_2_1
                else
                  @sbuf << @pattern_cc_2_2
                end

                @rx_document = @res.post_match
              end

              if @cnt == ZERO then
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
          #when ONE
          #  get_attribute_value_1(args[0])
          when TWO
            if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String) then
              get_attribute_value_2(args[0],args[1])
              #elsif args[0].kind_of?(String) && args[1].kind_of?(String) then
              #  set_attribute_2(args[0],args[1])
            elsif args[0].kind_of?(Meteor::Element) && args[1].kind_of?(Meteor::AttributeMap) then
              args[0].document_sync = true
              set_attribute_2_m(args[0],args[1])
            else
              raise ArgumentError
            end
          when THREE
            args[0].document_sync = true
            set_attribute_3(args[0],args[1],args[2])
          else
            raise ArgumentError
        end
      end

      #
      # 要素の属性を編集する
      #
      # @param [Meteor::Element] elm 要素
      # @param [String] attr_name  属性名
      # @param [String] attr_value 属性値
      #
      def set_attribute_3(elm,attr_name,attr_value)
        if !elm.cx then
          attr_value = escape(attr_value)
          #属性群の更新
          edit_attributes_(elm,attr_name,attr_value)

          #if !elm.origin then
          #  if elm.arguments.map.include?(attr_name) then
          #    elm.arguments.store(attr_name, attr_value)
          #  end
          #end
        end
        elm
      end
      private :set_attribute_3

      def edit_attributes_(elm,attr_name,attr_value)

        #属性検索
        #@res = @pattern.match(elm.attributes)

        #検索対象属性の存在判定
        if elm.attributes.include?(' ' << attr_name << ATTR_EQ) then

          @_attr_value = attr_value
          ##replace2regex(@_attr_value)
          #if elm.origin then
          #  replace4regex(@_attr_value)
          #else
          #  replace2regex(@_attr_value)
          #end
          #属性の置換
          @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << SET_ATTR_1)

          #elm.attributes.sub!(@pattern,'' << attr_name << ATTR_EQ << @_attr_value << DOUBLE_QUATATION)
          elm.attributes.sub!(@pattern,"#{attr_name}=\"#{@_attr_value}\"")
        else
          #属性文字列の最後に新規の属性を追加する
          @_attr_value = attr_value
          ##replace2regex(@_attr_value)
          #if elm.origin then
          #  replace2regex(@_attr_value)
          #end

          if EMPTY != elm.attributes && EMPTY != elm.attributes.strip then
            elm.attributes = '' << SPACE << elm.attributes.strip
          else
            elm.attributes = ''
          end

          #elm.attributes << SPACE << attr_name << ATTR_EQ << @_attr_value << DOUBLE_QUATATION
          elm.attributes << " #{attr_name}=\"#{@_attr_value}\""
        end

      end
      private :edit_attributes_

      def edit_document_1(elm)
        edit_document_2(elm,TAG_CLOSE3)
      end
      private :edit_document_1

      def edit_document_2(elm,closer)
        if !elm.cx then
          @_attributes = elm.attributes
          #replace2regex(@_attributes)

          if elm.empty then
            #内容あり要素の場合
            @_content = elm.mixed_content
            ##replace2regex(@_content)
            #if elm.origin then
            #  replace4regex(@_content)
            #else
            #  replace2regex(@_content)
            #end

            elm.document = '' << TAG_OPEN << elm.name << @_attributes << TAG_CLOSE << @_content << TAG_OPEN3 << elm.name << TAG_CLOSE
            #elm.document = "<#{elm.name}#{@_attributes}>#{@_content}</#{elm.name}>"
          else
            #空要素の場合
            elm.document = '' << TAG_OPEN << elm.name << @_attributes << closer
          end
        else
          @_content = elm.mixed_content
          #if elm.origin then
          #  replace4regex(@_content)
          #else
          #  replace2regex(@_content)
          #end

          #elm.document = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2
          #elm.document << @_content << SET_CX_3 << elm.name << SET_CX_4
          elm.document = "<!-- @#{elm.name} #{elm.attributes}-->#{@_content}<!-- /@#{elm.name} -->"
        end

        #タグ置換
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        @root.document.sub!(@pattern,elm.document)
      end
      private :edit_document_2

      #def edit_pattern_(elm)
      #
      #  elm.arguments.map.each do |name, attr|
      #    if attr.changed then
      #      @_attr_value = escape_regex(attr.value)
      #      ##replace2regex(@_attr_value)
      #      #@pattern_cc = '' << name << SET_ATTR_1
      #      @pattern_cc = "#{attr.name}=\"[^\"]*\""
      #      @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
      #      #elm.pattern.gsub!(@pattern,'' << name << ATTR_EQ << @_attr_value << DOUBLE_QUATATION)
      #      elm.pattern.sub!(@pattern, "#{attr.name}=\"#{@_attr_value}\"")
      #    elsif attr.removed then
      #      @pattern_cc = '' << name << SET_ATTR_1
      #      #@pattern_cc = "#{attr_name}=\"[^\"]*\""
      #      @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
      #      elm.pattern.gsub!(@pattern, EMPTY)
      #    end
      #  end
      #end
      #private :edit_pattern_

      ##
      ## 要素の属性を編集する
      ##
      ## @param [String] attr_name 属性名
      ## @param [String] attr_value 属性値
      ##
      #def set_attribute_2(attr_name,attr_value)
      #  if @root.element.origin then
      #    set_attribute_3(@root.element, attr_name, attr_value)
      #  end
      #  @root.element
      #end
      #private :set_attribute_2

      #
      # 要素の属性値を取得する
      #
      # @param [Meteor::Element] elm 要素
      # @param [String] attr_name 属性名
      # @return [String] 属性値
      #
      def get_attribute_value_2(elm,attr_name)
        get_attribute_value_(elm,attr_name)
      end
      private :get_attribute_value_2

      def get_attribute_value_(elm,attr_name)

        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << GET_ATTR_1)

        @res = @pattern.match(elm.attributes)

        if @res then
          unescape(@res[1])
        else
          nil
        end
      end
      private :get_attribute_value_

      ##
      ## 要素の属性値を取得する
      ##
      ## @param [String] attr_name 属性名
      ## @return [String] 属性値
      ##
      #def get_attribute_value_1(attr_name)
      #  if @root.element then
      #    get_attribute_value_2(@root.element, attr_name)
      #  else
      #    nil
      #  end
      #end
      #private :get_attribute_value_1

      #
      # 属性マップを取得する
      # 
      # @param [Array] args 引数配列
      # @return [Meteor::AttributeMap] 属性マップ
      #
      def attribute_map(*args)
        case args.length
          when ZERO
            get_attribute_map_0
          when ONE
            get_attribute_map_1(args[0])
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
      def get_attribute_map_1(elm)
        attrs = Meteor::AttributeMap.new

        elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
          attrs.store(a, unescape(b))
        end
        attrs.recordable = true

        attrs
      end
      private :get_attribute_map_1

      #
      # 要素の属性マップを取得する
      # 
      # @return [Meteor::AttributeMap] 属性マップ
      #
      def get_attribute_map_0()
        if @root.element then
          get_attribute_map_1(@root.element)
        else
          nil
        end
      end
      private :get_attribute_map_0

      #
      # 要素の属性を編集する
      # 
      # @param [Meteor::Element] elm 要素
      # @param [Meteor::AttributeMap] attrMap 属性マップ
      #
      def set_attribute_2_m(elm,attr_map)
        if !elm.cx then
          attr_map.map.each do |name, attr|
            if attr_map.changed(name) then
              edit_attributes_(elm, name, attr.value)
            elsif attr_map.removed(name) then
              remove_attributes_(elm, name)
            end
          end
        end
        elm
      end
      private :set_attribute_2_m

      #
      # 要素の内容をセットする or 内容を取得する
      # 
      # @param [Array] args 引数配列
      # @return [String] 内容
      #
      def content(*args)
        case args.length
          when ONE
            #if args[0].kind_of?(Meteor::Element) then
            get_content_1(args[0])
          #elsif args[0].kind_of?(String) then
          #  set_content_1(args[0])
          #else
          #  raise ArgumentError
          #end
          when TWO
            #if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String) then
            args[0].document_sync = true
            set_content_2_s(args[0],args[1])
          #elsif args[0].kind_of?(String) && (args[1].eql?(true) || args[1].eql?(false)) then
          ##elsif args[0].kind_of?(String) && (args[1].kinf_of?(TrueClass) || args[1].kind_of?(FalseClass)) then
          #  set_content_2_b(args[0],args[1])
          #else
          #  raise ArgumentError
          #end
          when THREE
            args[0].document_sync = true
            set_content_3(args[0],args[1],args[2])
          else
            raise ArgumentError
        end
      end

      #
      # 要素の内容をセットする
      #
      # @param [Meteor::Element] elm 要素
      # @param [String] content 要素の内容
      # @param [TrueClass,FalseClass] entityRef エンティティ参照フラグ
      #
      def set_content_3(elm,content,entity_ref=true)

        if entity_ref then
          escape_content(content,elm.name)
        end
        elm.mixed_content = content
        elm
      end
      private :set_content_3

      #
      # 要素の内容を編集する
      # 
      # @param [Meteor::Element] elm 要素
      # @param [String] content 要素の内容
      #
      def set_content_2_s(elm,content)
        #set_content_3(elm, content)
        elm.mixed_content = escape_content(content,elm.name)
        elm
      end
      private :set_content_2_s

      ##
      ## 要素の内容を編集する
      ##
      ## @param [String] content 内容
      ##
      #def set_content_1(content)
      #  if @root.element && @root.element.mono then
      #    set_content_2_s(@root.element, content)
      #  end
      #end
      #private :set_content_1

      ##
      ## 要素の内容を編集する
      ##
      ## @param [String] content 内容
      ## @param [TrueClass,FalseClass] entity_ref エンティティ参照フラグ
      ##
      #def set_content_2_b(content,entity_ref)
      #  if @root.element && @root.element.mono then
      #    set_content_3(@root.element, content, entity_ref)
      #  end
      #
      #  @root.element
      #end
      #private :set_content_2_b

      def get_content_1(elm)
        if !elm.cx then
          if elm.empty then
            unescape_content(elm.mixed_content,elm.name)
          else
            nil
          end
        else
          unescape_content(elm.mixed_content,elm.name)
        end
      end
      private :get_content_1

      #
      # 要素の属性を消す
      # 
      # @param [Array] args 引数配列
      #
      def remove_attribute(*args)
        case args.length
          #when ONE
          #  remove_attribute_1(args[0])
          when TWO
            remove_attribute_2(args[0],args[1])
          else
            raise ArgumentError
        end
      end

      #
      # 要素の属性を消す
      # 
      # @param [Meteor::Element] elm 要素
      # @param [String] attr_name 属性名
      #
      def remove_attribute_2(elm,attr_name)
        if !elm.cx then

          elm.document_sync = true
          remove_attributes_(elm,attr_name)

          #if !elm.origin then
          #  if elm.arguments.map.include?(attr_name) then
          #    elm.arguments.delete(attr_name)
          #  end
          #end

        end

        elm
      end
      private :remove_attribute_2

      def remove_attributes_(elm,attr_name)
        #属性検索用パターン
        @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << ERASE_ATTR_1)
        #属性の置換
        elm.attributes.sub!(@pattern,EMPTY)
      end
      private :remove_attributes_

      ##
      ## 要素の属性を消す
      ##
      ## @param [String] attr_name 属性名
      ##
      #def remove_attribute_1(attr_name)
      #  if @root.element then
      #    remove_attribute_2(@root.element, attr_name)
      #  end
      #
      #  @root.element
      #end
      #private :remove_attribute_1

      #
      # 要素を消す
      # 
      # @param [Meteor::Element] elm 要素
      #
      def remove_element(elm)
        replace(elm,EMPTY)
        elm.usable = false
      end

      #
      # CX(コメント拡張)タグを取得する
      # 
      # @param [Array] args 引数配列
      # @return [Meteor::Element] 要素
      #
      def cxtag(*args)
        case args.length
          when ONE
            cxtag_1(args[0])
            if @elm_ then
              @element_cache.store(@elm_.object_id,@elm_)
            end
          when TWO
            cxtag_2(args[0],args[1])
            if @elm_ then
              @element_cache.store(@elm_.object_id,@elm_)
            end
          else
            raise ArgumentError
        end
      end

      #
      # 要素名とID属性で検索し、CX(コメント拡張)タグを取得する
      # 
      # @param [String] elm_name 要素名
      # @param [String] id ID属性値
      # @return [Meteor::Element] 要素
      #
      def cxtag_2(elm_name,id)

        #CXタグ検索用パターン
        #@pattern_cc = '' << SEARCH_CX_1 << elm_name << SEARCH_CX_2
        #@pattern_cc << id << SEARCH_CX_3 << elm_name << SEARCH_CX_4 << elm_name << SEARCH_CX_5
        #@pattern_cc = "<!--\\s@#{elm_name}\\s([^<>]*id=\"#{id}\"[^<>]*)-->(((?!(<!--\\s\\/@#{elm_name})).)*)<!--\\s\\/@#{elm_name}\\s-->"
        @pattern_cc = "<!--\\s@#{elm_name}\\s([^<>]*id=\"#{id}\"[^<>]*)-->(((?!(<!--\\s/@#{elm_name})).)*)<!--\\s/@#{elm_name}\\s-->"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        #CXタグ検索
        @res = @pattern.match(@root.document)

        if @res then
          #要素
          @elm_ = Element.new(elm_name)

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
          #@elm_ = cxtag(@res[1],id)
          cxtag(@res[1],id)
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
      def replace(elm,replace_document)
        #文字エスケープ
        #if replace_document.size > ZERO && elm.origin && elm.mono then
        #  replace2regex(replace_document)
        #end
        #タグ置換パターン
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        #タグ置換
        @root.document.sub!(@pattern,replace_document)
      end
      private :replace

      def reflect
        #puts @element_cache.size.to_s
        @element_cache.values.each do |item|
          if item.usable then
            #puts "#{item.name}:#{item.document}"
            #if item.name == EMPTY then
            if item.copy then
              #item.document = item.copy.parser.root_element.hook_document
              @pattern = Meteor::Core::Util::PatternCache.get(item.pattern)
              @root.document.sub!(@pattern,item.copy.parser.root_element.hook_document)
              #@root.document.sub!(@pattern,item.document)
              #item.copy.parser.element_cache.clear
              item.copy = nil
            else
              edit_document_1(item)
              #edit_pattern_(item)
            end
            item.usable = false
          end
        end
      end
      protected :reflect

      #
      # 出力する
      #
      def flush

        #puts @root.document
        if @root.element then
          if @root.element.origin.mono then
            if @root.element.origin.cx then
              #@root.hookDocument << SET_CX_1 << @root.element.name << SPACE
              #@root.hookDocument << @root.element.attributes << SET_CX_2
              #@root.hookDocument << @root.element.mixed_content << SET_CX_3
              #@root.hookDocument << @root.element.name << SET_CX_4
              @root.hook_document << "<!-- @#{@root.element.name} #{@root.element.attributes}-->#{@root.element.mixed_content}<!-- /@#{@root.element.name} -->"
              #@root.hook_document << @root.document
            else
              #@root.hookDocument << TAG_OPEN << @root.element.name
              #@root.hookDocument << @root.element.attributes << TAG_CLOSE << @root.element.mixed_content
              #@root.hookDocument << TAG_OPEN3 << @root.element.name << TAG_CLOSE
              @root.hook_document << "<#{@root.element.name}#{@root.element.attributes}>#{@root.element.mixed_content}</#{@root.element.name}>"
              #@root.hook_document << @root.document
            end
            #@root.hook_document << @root.document
            @root.element = Element.new!(@root.element.origin,self)
            #@root.document = String.new(@root.element.document)
          else
            reflect
            @_attributes = @root.element.attributes
            #replace2regex(@_attributes)
            if @root.element.origin.cx then
              #@root.hookDocument << SET_CX_1 << @root.element.name << SPACE
              #@root.hookDocument << @_attributes << SET_CX_2
              #@root.hookDocument << @root.document << SET_CX_3
              #@root.hookDocument << @root.element.name << SET_CX_4
              @root.hook_document << "<!-- @#{@root.element.name} #{@_attributes}-->#{@root.document}<!-- /@#{@root.element.name} -->"
            else
              #@root.hookDocument << TAG_OPEN << @root.element.name
              #@root.hookDocument << @_attributes << TAG_CLOSE << @root.document
              #@root.hookDocument << TAG_OPEN3 << @root.element.name << TAG_CLOSE
              @root.hook_document << "<#{@root.element.name}#{@_attributes}>#{@root.document}</#{@root.element.name}>"
            end
            @root.element = Element.new!(@root.element.origin,self)
          end
          #@root.element.origin.document = @root.hook_document
          #@root.element.origin.name = EMPTY
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
        @root.document.gsub!(@pattern,EMPTY)
        #CX終了タグ置換
        @pattern = @@pattern_clean2
        @root.document.gsub!(@pattern,EMPTY)
        #@root.document << "<!-- Powered by Meteor (C)Yasumasa Ashida -->"
      end
      private :clean

      #
      # 要素をコピーする
      # 
      # @param [Meteor::Element] elm 要素
      # @return [Meteor::Element] 要素
      #
      def shadow(elm)
        if elm.empty then
          #内容あり要素の場合
          set_mono_info(elm)

          pif2 = create(self)

          @elm_ = Element.new!(elm,pif2)

          if !elm.mono then
            pif2.root_element.document = String.new(elm.mixed_content)
          else
            pif2.root_element.document = String.new(elm.document)
          end

          @elm_
        end
      end
      private :shadow

      def set_mono_info(elm)
      end
      private :set_mono_info

      #
      # フッククラスの処理を実行する
      # @param [Array] args 引数配列
      #
      def execute(*args)
        case args.length
          when TWO
            execute_2(args[0],args[1])
          when THREE
            execute_3(args[0],args[1],args[2])
          else
            raise ArgumentError
        end
      end

      def execute_2(elm,hook)
        hook.do_action(elm)
      end
      private :execute_2

      def execute_3(elm,loop,list)
        loop.do_action(elm,list)
      end
      private :execute_3

      #
      # 正規表現対象文字を置換する
      #
      # @param [String] str 入力文字列
      # @return [String] 出力文字列
      #
      def escape_regex(str)
        Regexp.quote(str)
      end
      private :escape_regex

      #def replace2regex(str)
      #  #if str.include?(EN_1) then
      #  #  str.gsub!(@@pattern_sub_regex1,SUB_REGEX2)
      #  #end
      #end
      #private :replace2regex

      #def replace4regex(str)
      #  #if str.include?(EN_1) then
      #  #  str.gsub!(@@pattern_sub_regex1,SUB_REGEX3)
      #  #end
      #end
      #private :replace4regex

      #
      # @param [String] content 入力文字列
      # @return [String] 出力文字列
      #
      def escape(content)
        content
      end
      private :escape

      #
      # @param [String] content 入力文字列
      # @param [String] elm_name 要素名
      # @return [String] 出力文字列
      #
      def escape_content(content,elm_name)
        content
      end
      private :escape_content

      #
      # @param [String] content 入力文字列
      # @return [String] 出力文字列
      #
      def unescape(content)
        content
      end
      private :unescape

      #
      # @param [String] content 入力文字列
      # @param [String] elm_name 要素名
      # @return [String] 出力文字列
      #
      def unescape_content(content,elm_name)
        content
      end
      private :unescape_content

      def is_match(regex,str)
        if regex.kind_of?(Regexp) then
          is_match_r(regex,str)
        elsif regex.kind_of?(Array) then
          is_match_a(regex,str)
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


      def is_match_r(regex,str)
        if regex.match(str.downcase) then
          true
        else
          false
        end
      end
      private :is_match_r

      def is_match_a(regex,str)
        str = str.downcase
        regex.each do |item|
          if item.eql?(str) then
            return true
          end
        end
        return false
      end
      private :is_match_a

      def is_match_s(regex,str)
        if regex.match(str.downcase) then
          true
        else
          false
        end
      end
      private :is_match_s

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

    end

    module Util

      #
      # パターンキャッシュクラス
      #
      class PatternCache
        @@regex_cache = Hash.new

        #
        # イニシャライザ
        #
        def initialize
        end

        def self.get(*args)
          case args.length
            when ONE
              get_1(args[0])
            when TWO
              get_2(args[0], args[1])
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
          #pattern = @@regex_cache[regex]
          #
          #if pattern == nil then
          if regex.kind_of?(String) then
            if !@@regex_cache[regex.to_sym] then
              #pattern = Regexp.new(regex)
              #@@regex_cache[regex] = pattern
              @@regex_cache[regex.to_sym] = Regexp.new(regex, Regexp::MULTILINE)
            end

            #return pattern
            @@regex_cache[regex.to_sym]
          elsif regex.kind_of?(Symbol) then
            if !@@regex_cache[regex] then
              @@regex_cache[regex] = Regexp.new(regex.to_s, Regexp::MULTILINE)
            end

            @@regex_cache[regex]
          end
        end

        #
        # パターンを取得する
        # @param [String] regex 正規表現
        # @return [Regexp] パターン
        #
        def self.get_2(regex, option)
          #pattern = @@regex_cache[regex]
          #
          #if pattern == nil then
          if regex.kind_of?(String) then
            if !@@regex_cache[regex.to_sym] then
              #pattern = Regexp.new(regex)
              #@@regex_cache[regex] = pattern
              @@regex_cache[regex.to_sym] = Regexp.new(regex, option)
            end

            #return pattern
            @@regex_cache[regex.to_sym]
          elsif regex.kind_of?(Symbol) then
            if !@@regex_cache[regex] then
              @@regex_cache[regex] = Regexp.new(regex.to_s, option)
            end

            @@regex_cache[regex]
          end
        end
      end

      if RUBY_VERSION < RUBY_VERSION_1_9_0 then
        class OrderHash < Hash

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
            elsif yield(key)
            end
          end

          #superとして、Hash#[]=を呼び出す

          def []=(key, value)
            store(key, value)
          end

          def each
            @keys.each do |k|
              arr_tmp = Array.new
              arr_tmp << k
              arr_tmp << self[k]
              yield(arr_tmp)
            end
            return self
          end

          def each_pair
            @keys.each do |k|
              yield(k, self[k])
            end
            return self
          end

          def map
            arr_tmp = Array.new
            @keys.each do |k|
              arg_arr = Array.new
              arg_arr << k
              arg_arr << self[k]
              arr_tmp << yield(arg_arr)
            end
            return arr_tmp
          end

          def sort_hash(&block)
            if block_given?
              arr_tmp = self.sort(&block)
            elsif arr_tmp = self.sort
            end
            hash_tmp = OrderHash.new
            arr_tmp.each do |item|
              hash_tmp[item[0]] = item[1]
            end
            return hash_tmp
          end
        end
      end
    end

    module Html
      #
      # HTMLパーサ
      #
      class ParserImpl < Meteor::Core::Kernel

        #KAIGYO_CODE = "\r?\n|\r"
        #KAIGYO_CODE = "\r\n|\n|\r"
        KAIGYO_CODE = ["\r\n","\n","\r"]
        NBSP_2 = '&nbsp;'
        NBSP_3 = 'nbsp'
        BR_1 = "\r?\n|\r"
        BR_2 = '<br>'

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

        if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
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
          @@pattern_br_2 = Regexp.new(BR_2)
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

        GET_ATTRS_MAP2='\\s(disabled|readonly|checked|selected|multiple)'
        @@pattern_get_attrs_map2 = Regexp.new(GET_ATTRS_MAP2)

        #
        # イニシャライザ
        # 
        # @param [Array] args 引数配列
        #
        def initialize(*args)
          super(args)
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
          @root.hook_document = String.new(ps.root_element.hook_document)
          #@root.hook = ps.root_element.hook
          #@root.mono_hook = ps.root_element.mono_hook
          @root.content_type = String.new(ps.content_type);
          @root.kaigyo_code = ps.root_element.kaigyo_code
          @doc_type = ps.doc_type
        end
        private :initialize_1

        #
        # ドキュメントをパーサにセットする
        # 
        # @param [String] document ドキュメント
        #
        def parse(document)
          @root.document = document
          analyze_ml()
        end

        #
        # ファイルを読み込み、パーサにセットする
        # 
        # @param [String] filePath ファイルパス
        # @param [String] encoding エンコーディング
        #
        def read(file_path,encoding)
          super(file_path,encoding)
          analyze_ml()
        end

        #
        # ドキュメントをパースする
        #
        def analyze_ml()
          #content-typeの取得
          analyze_content_type()
          #改行コードの取得
          analyze_kaigyo_code()

          @res = nil
        end
        private :analyze_ml

        # コンテントタイプを取得する
        # 
        # @return [Streing]コンテントタイプ
        #
        def content_type
          @root.content_type
        end

        #
        # ドキュメントをパースし、コンテントタイプをセットする
        #
        def analyze_content_type
          element(META_S,HTTP_EQUIV,CONTENT_TYPE)

          if !@elm_ then
            element(META,HTTP_EQUIV,CONTENT_TYPE)
          end

          if @elm_ then
            @root.content_type = @elm_.attribute(CONTENT)
          else
            @root.content_type = EMPTY
          end
        end
        private :analyze_content_type

        #
        # ドキュメントをパースし、改行コードをセットする
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
        # 要素名で検索し、要素を取得する
        # 
        # @param [String] elm_name 要素名
        # @return [Meteor::Element] 要素
        #
        def element_1(elm_name)
          @_elm_name = escape_regex(elm_name)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(MATCH_TAG,elm_name) then
            #空要素検索用パターン
            @pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_1_4_2
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            @res = @pattern.match(@root.document)
            if @res then
              element_without_1(elm_name)
            else
              @elm_ = nil
            end
          else
            #内容あり要素検索用パターン
            #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_1_1 << elm_name
            #@pattern_cc << TAG_SEARCH_1_2 << @_elm_name << TAG_CLOSE
            @pattern_cc = "<#{elm_name}(\\s?[^<>]*)>(((?!(#{elm_name}[^<>]*>)).)*)<\\/#{elm_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)
            #内容あり要素の場合
            if @res then
              element_with_1(elm_name)
            else
              @elm_ = nil
            end
          end

          @elm_
        end
        private :element_1

        def element_without_1(elm_name)
          @elm_ = Element.new(elm_name)
          #属性
          @elm_.attributes = @res[1]
          #空要素検索用パターン
          @elm_.pattern = @pattern_cc

          @elm_.document = @res[0]

          @elm_.parser = self
        end
        private :element_without_1

        #
        # 要素名、属性(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] elm_name 要素名
        # @param [String] attr_name 属性名
        # @param [String] attr_value 属性値
        # @return [Meteor::Element] 要素
        #
        def element_3(elm_name,attr_name,attr_value)

          @_elm_name = escape_regex(elm_name)
          @_attr_name = escape_regex(attr_name)
          @_attr_value = escape_regex(attr_value)
          #空要素の場合(<->内容あり要素の場合)
          if is_match(MATCH_TAG,elm_name) then
            #空要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_2_4_3
            @pattern_cc = "<#{@_elm_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)
            if @res then
              element_without_3(elm_name)
            else
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1 << @_attr_name << ATTR_EQ
            #@pattern_cc << @_attr_value << TAG_SEARCH_2_2 << @_elm_name
            #@pattern_cc << TAG_SEARCH_1_2 << @_elm_name << TAG_CLOSE
            @pattern_cc = "<#{@_elm_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_elm_name}[^<>]*>)).)*)<\\/#{@_elm_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)

            if !@res then
              @res = element_with_3_2(elm_name)
            end

            if @res then
              element_with_3_1(elm_name)
            else
              @elm_ = nil
            end
          end

          #if @elm_ then
          #  @elm_.arguments.store(attr_name, attr_value)
          #  @elm_.arguments.recordable = true
          #end

          @elm_
        end
        private :element_3

        def element_without_3(elm_name)
          element_without_3_1(elm_name,TAG_SEARCH_NC_2_4_3)
        end
        private :element_without_3

        #
        # 属性(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] attr_name 属性名
        # @param [String] attr_value 属性値
        # @return [Meteor::Element] 要素
        #
        def element_2(attr_name,attr_value)
          @_attr_name = escape_regex(attr_name)
          @_attr_value = escape_regex(attr_value)

          #@pattern_cc = '' << TAG_SEARCH_3_1 << @_attr_name << ATTR_EQ << @_attr_value
          #@pattern_cc << TAG_SEARCH_2_4_4
          @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
          @res = @pattern.match(@root.document)

          if @res then
            element_3(@res[1],attr_name,attr_value)
          else
            @elm_ = nil
          end

          @elm_
        end
        private :element_2

        #
        # 要素名と属性1・属性2(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] elm_name 要素名
        # @param attr_name1 属性名1
        # @param attr_value1 属性値1
        # @param attr_name2 属性名2
        # @param attr_value2 属性値2
        # @return [Meteor::Element] 要素
        #
        def element_5(elm_name,attr_name1,attr_value1,attr_name2,attr_value2)

          @_elm_name = escape_regex(elm_name)
          @_attr_name1 = escape_regex(attr_name1)
          @_attr_value1 = escape_regex(attr_value1)
          @_attr_name2 = escape_regex(attr_name2)
          @_attr_value2 = escape_regex(attr_value2)

          #空要素の場合(<->内容あり要素の場合)
          if is_match(MATCH_TAG,elm_name) then
            #空要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_4_3_2
            @pattern_cc = "<#{@_elm_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #空要素検索
            @res = @pattern.match(@root.document)

            if @res then
              element_without_5(elm_name)
            else
              @elm_ = nil
            end
          else
            #内容あり要素検索パターン
            #@pattern_cc = '' << TAG_OPEN << @_elm_name << TAG_SEARCH_2_1_2 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ
            #@pattern_cc << @_attr_value2 << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ
            #@pattern_cc << @_attr_value1 << TAG_SEARCH_2_2_2 << @_elm_name
            #@pattern_cc << TAG_SEARCH_1_2 << @_elm_name << TAG_CLOSE
            @pattern_cc = "<#{@_elm_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_elm_name}[^<>]*>)).)*)<\\/#{@_elm_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            #内容あり要素検索
            @res = @pattern.match(@root.document)

            if !@res then
              @res = element_with_5_2(elm_name)
            end

            if @res then
              element_with_5_1(elm_name)
            else
              @elm_ = nil
            end
          end

          #if @elm_ then
          #  @elm_.arguments.store(attr_name1, attr_value1)
          #  @elm_.arguments.store(attr_name2, attr_value2)
          #  @elm_.arguments.recordable = true
          #end

          @elm_
        end
        private :element_5

        def element_without_5(elm_name)
          element_without_5_1(elm_name,TAG_SEARCH_NC_2_4_3_2)
        end
        private :element_without_5

        #
        # 属性1・属性2(属性名="属性値")で検索し、要素を取得する
        # 
        # @param [String] attr_name1 属性名1
        # @param [String] attr_value1 属性値1
        # @param [String] attr_name2 属性名2
        # @param [String] attr_value2 属性値2
        # @return [Meteor::Element] 要素
        #
        def element_4(attr_name1,attr_value1,attr_name2,attr_value2)
          @_attr_name1 = escape_regex(attr_name1)
          @_attr_value1 = escape_regex(attr_value1)
          @_attr_name2 = escape_regex(attr_name2)
          @_attr_value2 = escape_regex(attr_value2)

          #@pattern_cc = '' << TAG_SEARCH_3_1_2_2 << @_attr_name1 << ATTR_EQ << @_attr_value1
          #@pattern_cc << TAG_SEARCH_2_6 << @_attr_name2 << ATTR_EQ << @_attr_value2
          #@pattern_cc << TAG_SEARCH_2_7 << @_attr_name2 << ATTR_EQ << @_attr_value2
          #@pattern_cc << TAG_SEARCH_2_6 << @_attr_name1 << ATTR_EQ << @_attr_value1
          #@pattern_cc << TAG_SEARCH_2_4_3_2
          @pattern_cc = "<([^<>\"]*)\\s([^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

          @pattern = PatternCache.get(@pattern_cc)

          @res = @pattern.match(@root.document)

          if @res then
            element_5(@res[1],attr_name1,attr_value1,attr_name2,attr_value2)
          else
            @elm_ = nil
          end

          @elm_
        end
        private :element_4

        def edit_attributes_(elm,attr_name,attr_value)
          if is_match(SELECTED, attr_name) && is_match(OPTION,elm.name) then
            edit_attributes_5(elm,attr_name,attr_value,@@pattern_selected_m,@@pattern_selected_r)
            #edit_attributes_5(elm,attr_name,attr_value,SELECTED_M,@@pattern_selected_r)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT,elm.name)
            edit_attributes_5(elm,attr_name,attr_value,@@pattern_multiple_m,@@pattern_multiple_r)
            #edit_attributes_5(elm,attr_name,attr_value,MULTIPLE_M,@@pattern_multiple_r)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            edit_attributes_5(elm,attr_name,attr_value,@@pattern_disabled_m,@@pattern_disabled_r)
            #edit_attributes_5(elm,attr_name,attr_value,DISABLED_M,@@pattern_disabled_r)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT,elm.name) && is_match(RADIO, get_type(elm)) then
            edit_attributes_5(elm,attr_name,attr_value,@@pattern_checked_m,@@pattern_checked_r)
            #edit_attributes_5(elm,attr_name,attr_value,CHECKED_M,@@pattern_checked_r)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA,elm.name) || (is_match(INPUT,elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            edit_attributes_5(elm,attr_name,attr_value,@@pattern_readonly_m,@@pattern_readonly_r)
            #edit_attributes_5(elm,attr_name,attr_value,READONLY_M,@@pattern_readonly_r)
          else
            super(elm,attr_name,attr_value)
          end
        end
        private :edit_attributes_

        def edit_attributes_5(elm,attr_name,attr_value,match_p,replace)

          if is_match(TRUE, attr_value) then
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
          elsif is_match(FALSE, attr_value) then
            elm.attributes.sub!(replace,EMPTY)
          end

        end
        private :edit_attributes_5

        def edit_document_1(elm)
          edit_document_2(elm,TAG_CLOSE)
        end
        private :edit_document_1

        def get_attribute_value_(elm,attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION,elm.name) then
            get_attribute_value_2_r(elm,@@pattern_selected_m)
            #get_attribute_value_2_r(elm,SELECTED_M)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT,elm.name)
            get_attribute_value_2_r(elm,@@pattern_multiple_m)
            #get_attribute_value_2_r(elm,MULTIPLE_M)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            get_attribute_value_2_r(elm,@@pattern_disabled_m)
            #get_attribute_value_2_r(elm,DISABLED_M)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT,elm.name) && is_match(RADIO, get_type(elm)) then
            get_attribute_value_2_r(elm,@@pattern_checked_m)
            #get_attribute_value_2_r(elm,CHECKED_M)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA,elm.name) || (is_match(INPUT,elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            get_attribute_value_2_r(elm,@@pattern_readonly_m)
            #get_attribute_value_2_r(elm,READONLY_M)
          else
            super(elm,attr_name)
          end
        end
        private :get_attribute_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attribute_value_(elm, TYPE_L)
            if !elm.type_value then
              elm.type_value = get_attribute_value_(elm, TYPE_U)
            end
          end
          elm.type_value
        end
        private :get_type

        def get_attribute_value_2_r(elm,match_p)

          @res = match_p.match(elm.attributes)

          if @res then
            TRUE
          else
            FALSE
          end
        end
        private :get_attribute_value_2_r

        #
        # 要素の属性マップを取得する
        # 
        # @param [Meteor::Element] elm 要素
        # @return [Meteor::AttributeMap] 属性マップ
        #
        def get_attribute_map_1(elm)
          attrs = Meteor::AttributeMap.new

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(@@pattern_get_attrs_map2) do |a|
            attrs.store(a, TRUE)
          end

          attrs.recordable = true

          attrs
        end
        private :get_attribute_map_1

        def remove_attributes_(elm,attr_name)
          #検索対象属性の論理型是非判定
          if !is_match(ATTR_LOGIC,attr_name) then
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get('' << attr_name << ERASE_ATTR_1)
            elm.attributes.sub!(@pattern, EMPTY)
          else
            #属性検索用パターン
            @pattern = Meteor::Core::Util::PatternCache.get(attr_name)
            elm.attributes.sub!(@pattern, EMPTY)
            #end
          end
        end
        private :remove_attributes_

        def set_mono_info(elm)

          @res = @@pattern_set_mono1.match(elm.mixed_content)

          if @res then
            elm.mono = true
            if elm.cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              elm.document = "<!-- @#{elm.name} #{elm.attributes} -->#{elm.mixed_content}<!-- /@#{elm.name} -->"
            else
              if elm.empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                elm.document = "<#{elm.name}#{elm.attributes}>#{elm.mixed_content}</#{elm.name}>"
              else
                elm.document = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE
              end
            end
            #elm.document = @pattern_cc
          end
        end
        private :set_mono_info

        def escape(content)
          #特殊文字の置換
          if RUBY_VERSION < RUBY_VERSION_1_9_0 then
            #「&」->「&amp;」
            if content.include?(AND_1) then
              content.gsub!(@@pattern_and_1,AND_2)
            end
            #「<」->「&lt;」
            if content.include?(LT_1) then
              content.gsub!(@@pattern_lt_1,LT_2)
            end
            #「>」->「&gt;」
            if content.include?(GT_1) then
              content.gsub!(@@pattern_gt_1,GT_2)
            end
            #「"」->「&quotl」
            if content.include?(DOUBLE_QUATATION) then
              content.gsub!(@@pattern_dq_1,QO_2)
            end
            #「 」->「&nbsp;」
            if content.include?(SPACE) then
              content.gsub!(@@pattern_space_1,NBSP_2)
            end
          else
            content.gsub!(@@pattern_escape, TABLE_FOR_ESCAPE_)
          end
          content
        end
        private :escape

        def escape_content(content,elm_name)
          if RUBY_VERSION < RUBY_VERSION_1_9_0 then
            content = escape(content)

            if !is_match(MATCH_TAG_2,elm_name) then
              #「¥r?¥n」->「<br>」
              content.gsub!(@@pattern_br_1, BR_2)
            end
          else
            content.gsub!(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)
          end

          content
        end
        private :escape_content

        def unescape(content)
          #特殊文字の置換
          #「<」<-「&lt;」
          #if content.include?(LT_2) then
          #  content.gsub!(@@pattern_lt_2,LT_1)
          #end
          #「>」<-「&gt;」
          #if content.include?(GT_2) then
          #  content.gsub!(@@pattern_gt_2,GT_1)
          #end
          #「"」<-「&quotl」
          #if content.include?(QO_2) then
          #  content.gsub!(@@pattern_dq_2,DOUBLE_QUATATION)
          #end
          #「 」<-「&nbsp;」
          #if content.include?(NBSP_2) then
          #  content.gsub!(@@pattern_space_2,SPACE)
          #end
          #「&」<-「&amp;」
          #if content.include?(AND_2) then
          #  content.gsub!(@@pattern_and_2,AND_1)
          #end
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

        def unescape_content(content,elm_name)
          content_ = unescape(content)

          if !is_match(MATCH_TAG_2,elm_name) then
            #「<br>」->「¥r?¥n」
            if content.include?(BR_2) then
              content_.gsub!(@@pattern_br_2, @root.kaigyo_code)
            end
          end

          content_
        end
        private :unescape_content

      end
    end

    module Xhtml

      #
      # XHTMLパーサ
      #
      class ParserImpl < Meteor::Core::Kernel

        #KAIGYO_CODE = "\r?\n|\r"
        KAIGYO_CODE = ["\r\n","\n","\r"]
        NBSP_2 = '&nbsp;'
        NBSP_3 = 'nbsp'
        BR_1 = "\r?\n|\r"
        BR_2 = '<br/>'
        BR_3 = '<br\\/>'

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

        if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
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

          PATTERN_ESCAPE = '[&"\'<> ]'
          PATTERN_ESCAPE_CONTENT = '[&"\'<> \\n]'
          @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
          @@pattern_escape_content = Regexp.new(PATTERN_ESCAPE_CONTENT)
          @@pattern_br_2 = Regexp.new(BR_3)
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
            when ZERO
              initialize_0
            when ONE
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
          @root.hook_document = String.new(ps.root_element.hook_document)
          @root.content_type = String.new(ps.content_type)
          @root.kaigyo_code = ps.root_element.kaigyo_code
          @doc_type = ps.doc_type
        end
        private :initialize_1

        #
        # ドキュメントをパーサにセットする
        # 
        # @param [String] document ドキュメント
        #
        def parse(document)
          @root.document = document
          analyze_ml()
        end

        #
        # ファイルを読み込み、パーサにセットする
        # 
        # @param file_path ファイルパス
        # @param encoding エンコーディング
        #
        def read(file_path,encoding)
          super(file_path,encoding)
          analyze_ml()
        end

        #
        # ドキュメントをパースする
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
        # コンテントタイプを取得する
        # 
        # @return [String] コンテントタイプ
        #
        def content_type()
          @root.content_type
        end

        #
        # ドキュメントをパースし、コンテントタイプをセットする
        #
        def analyze_content_type
          element(META_S,HTTP_EQUIV,CONTENT_TYPE)

          if !@elm_ then
            element(META,HTTP_EQUIV,CONTENT_TYPE)
          end

          if @elm_ then
            @root.content_type = @elm_.attribute(CONTENT)
          else
            @root.content_type = EMPTY
          end
        end
        private :analyze_content_type

        #
        # ドキュメントをパースし、改行コードをセットする
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

        def edit_attributes_(elm,attr_name,attr_value)

          if is_match(SELECTED, attr_name) && is_match(OPTION,elm.name) then
            edit_attributes_5(elm,attr_value,@@pattern_selected_m,@@pattern_selected_r,SELECTED_U)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT,elm.name)
            edit_attributes_5(elm,attr_value,@@pattern_multiple_m,@@pattern_multiple_r,MULTIPLE_U)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            edit_attributes_5(elm,attr_value,@@pattern_disabled_m,@@pattern_disabled_r,DISABLED_U)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT,elm.name) && is_match(RADIO,get_type(elm)) then
            edit_attributes_5(elm,attr_value,@@pattern_checked_m,@@pattern_checked_r,CHECKED_U)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA,elm.name) || (is_match(INPUT,elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            edit_attributes_5(elm,attr_value,@@pattern_readonly_m,@@pattern_readonly_r,READONLY_U)
          else
            super(elm,attr_name,attr_value)
          end

        end
        private :edit_attributes_

        def edit_attributes_5(elm,attr_value,match_p,replace_regex,replace_update)

          #attr_value = escape(attr_value)

          if is_match(TRUE,attr_value) then

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
              elm.attributes.gsub!(replace_regex,replace_update)
            end
          elsif is_match(FALSE,attr_value) then
            #attr_name属性が存在するなら削除
            #属性の置換
            elm.attributes.gsub!(replace_regex, EMPTY)
          end

        end
        private :edit_attributes_5

        def get_attribute_value_(elm,attr_name)
          if is_match(SELECTED, attr_name) && is_match(OPTION,elm.name)  then
            get_attribute_value_2_r(elm,attr_name,@@pattern_selected_m1)
          elsif is_match(MULTIPLE, attr_name) && is_match(SELECT,elm.name)
            get_attribute_value_2_r(elm,attr_name,@@pattern_multiple_m1)
          elsif is_match(DISABLED, attr_name) && is_match(DISABLE_ELEMENT, elm.name) then
            get_attribute_value_2_r(elm,attr_name,@@pattern_disabled_m1)
          elsif is_match(CHECKED, attr_name) && is_match(INPUT,elm.name) && is_match(RADIO, get_type(elm)) then
            get_attribute_value_2_r(elm,attr_name,@@pattern_checked_m1)
          elsif is_match(READONLY, attr_name) && (is_match(TEXTAREA,elm.name) || (is_match(INPUT,elm.name) && is_match(READONLY_TYPE, get_type(elm)))) then
            get_attribute_value_2_r(elm,attr_name,@@pattern_readonly_m1)
          else
            super(elm,attr_name)
          end
        end
        private :get_attribute_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attribute_value_2(elm, TYPE_L)
            if !elm.type_value then
              elm.type_value = get_attribute_value_2(elm, TYPE_U)
            end
          end
          elm.type_value
        end
        private :get_type

        def get_attribute_value_2_r(elm,attr_name,match_p)

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
        private :get_attribute_value_2_r

        #
        # 属性マップを取得する
        # 
        # @param [Meteor::Element] elm 要素
        # @return [Meteor::AttributeMap] 属性マップ
        #
        def get_attribute_map_1(elm)
          attrs = Meteor::AttributeMap.new

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            if is_match(ATTR_LOGIC, a) && a==b then
              attrs.store(a, TRUE)
            else
              attrs.store(a, unescape(b))
            end
          end
          attrs.recordable = true

          attrs
        end
        private :get_attribute_map_1

        def set_mono_info(elm)

          @res = @@pattern_set_mono1.match(elm.mixed_content)

          if @res then
            elm.mono = true
            if elm.cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              elm.document = "<!-- @#{elm.name} #{elm.attributes} -->#{elm.mixed_content}<!-- /@#{elm.name} -->"
            else
              if elm.empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                elm.document = "<#{elm.name}#{elm.attributes}>#{elm.mixed_content}</#{elm.name}>"
              else
                elm.document = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE3
              end
            end
            #elm.document = @pattern_cc
          end
        end
        private :set_mono_info

        def escape(content)
          #特殊文字の置換
          if RUBY_VERSION < RUBY_VERSION_1_9_0 then
            #「&」->「&amp;」
            if content.include?(AND_1) then
              content.gsub!(@@pattern_and_1,AND_2)
            end
            #「<」->「&lt;」
            if content.include?(LT_1) then
              content.gsub!(@@pattern_lt_1,LT_2)
            end
            #「>」->「&gt;」
            if content.include?(GT_1) then
              content.gsub!(@@pattern_gt_1,GT_2)
            end
            #「"」->「&quotl」
            if content.include?(DOUBLE_QUATATION) then
              content.gsub!(@@pattern_dq_1,QO_2)
            end
            #「'」->「&apos;」
            if content.include?(AP_1) then
              content.gsub!(@@pattern_ap_1,AP_2)
            end
            #「 」->「&nbsp;」
            if content.include?(SPACE) then
              content.gsub!(@@pattern_space_1,NBSP_2)
            end
          else
            content.gsub!(@@pattern_escape,TABLE_FOR_ESCAPE_)
          end

          content
        end
        private :escape

        def escape_content(content,elm_name)

          if RUBY_VERSION < RUBY_VERSION_1_9_0 then
            content = escape(content)

            if !is_match(MATCH_TAG_2,elm_name) then
              #「¥r?¥n」->「<br>」
              content.gsub!(@@pattern_br_1, BR_2)
            end
          else
            content.gsub!(@@pattern_escape_content, TABLE_FOR_ESCAPE_CONTENT_)
          end
          content
        end
        private :escape_content

        def unescape(content)
          #特殊文字の置換
          #「<」<-「&lt;」
          #if content.include?(LT_2) then
          #  content.gsub!(@@pattern_lt_2,LT_1)
          #end
          #「>」<-「&gt;」
          #if content.include?(GT_2) then
          #  content.gsub!(@@pattern_gt_2,GT_1)
          #end
          #「"」<-「&quotl」
          #if content.include?(QO_2) then
          #  content.gsub!(@@pattern_dq_2,DOUBLE_QUATATION)
          #end
          #「 」<-「&nbsp;」
          #if content.include?(NBSP_2) then
          #  content.gsub!(@@pattern_space_2,SPACE)
          #end
          #「&」<-「&amp;」
          #if content.include?(AND_2) then
          #  content.gsub!(@@pattern_and_2,AND_1)
          #end
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

          #content
        end
        private :unescape

        def unescape_content(content,elm_name)
          content_ = unescape(content)

          if !is_match(MATCH_TAG_2,elm_name) then
            #「<br>」->「¥r?¥n」
            if content.include?(BR_2) then
              content_.gsub!(@@pattern_br_2, @root.kaigyo_code)
            end
          end

          content_
        end
        private :unescape_content

      end
    end

    module Xml

      #
      # XMLパーサ
      #
      class ParserImpl < Meteor::Core::Kernel

        if RUBY_VERSION >= RUBY_VERSION_1_9_0 then
          TABLE_FOR_ESCAPE_ = {
                  '&' => '&amp;',
                  '"' => '&quot;',
                  '\'' => '&apos;',
                  '<' => '&lt;',
                  '>' => '&gt;',
                  }
          PATTERN_ESCAPE = '[&\"\'<>]'
          @@pattern_escape = Regexp.new(PATTERN_ESCAPE)
        else
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
        end



        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt);'
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
            when ZERO
              initialize_0
            when ONE
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
          @root.hook_document = String.new(ps.root_element.hook_document)
          @doc_type = ps.doc_type
        end
        private :initialize_1

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
        # @param file_path ファイルパス
        # @param encoding エンコーディング
        #
        def read(file_path,encoding)
          super(file_path, encoding)
        end

        # コンテントタイプを取得する
        # 
        # @return [Streing]コンテントタイプ
        #
        def content_type()
          @root.content_type
        end

        def set_mono_info(elm)

          @res = @@pattern_set_mono1.match(elm.mixed_content)

          if @res then
            elm.mono = true
            if elm.cx then
              #@pattern_cc = '' << SET_CX_1 << elm.name << SPACE << elm.attributes << SET_CX_2 << elm.mixed_content << SET_CX_3 << elm.name << SET_CX_4
              @pattern_cc = "<!-- @#{elm.name} #{elm.attributes} -->#{elm.mixed_content}<!-- /@#{elm.name} -->"
            else
              if elm.empty then
                #@pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE << elm.mixed_content << TAG_OPEN3 << elm.name << TAG_CLOSE
                @pattern_cc = "<#{elm.name}#{elm.attributes}>#{elm.mixed_content}</#{elm.name}>"
              else
                @pattern_cc = '' << TAG_OPEN << elm.name << elm.attributes << TAG_CLOSE3
              end
            end
            elm.document = @pattern_cc
          end
        end
        private :set_mono_info

        def escape(content)
          #特殊文字の置換
          if RUBY_VERSION < RUBY_VERSION_1_9_0 then
            #「&」->「&amp;」
            if content.include?(AND_1) then
              content.gsub!(@@pattern_and_1,AND_2)
            end
            #「<」->「&lt;」
            if content.include?(LT_1) then
              content.gsub!(@@pattern_lt_1,LT_2)
            end
            #「>」->「&gt;」
            if content.include?(GT_1) then
              content.gsub!(@@pattern_gt_1,GT_2)
            end
            #「"」->「&quot;」
            if content.include?(DOUBLE_QUATATION) then
              content.gsub!(@@pattern_dq_1,QO_2)
            end
            #「'」->「&apos;」
            if content.include?(AP_1) then
              content.gsub!(@@pattern_ap_1,AP_2)
            end
          else
            content.gsub!(@@pattern_escape,TABLE_FOR_ESCAPE_)
          end

          content
        end
        private :escape

        def escape_content(content,elm_name)
          escape(content)
        end
        private :escape_content

        def unescape(content)
          #特殊文字の置換
          #if RUBY_VERSION < RUBY_VERSION_1_9_0 then
          #  #「<」<-「&lt;」
          #  if content.include?(LT_2) then
          #    content.gsub!(@@pattern_lt_2,LT_1)
          #  end
          #  #「>」<-「&gt;」
          #  if content.include?(GT_2) then
          #    content.gsub!(@@pattern_gt_2,GT_1)
          #  end
          #  #「"」<-「&quot;」
          #  if content.include?(QO_2) then
          #    content.gsub!(@@pattern_dq_2,DOUBLE_QUATATION)
          #  end
          #  #「'」<-「&apos;」
          #  if content.include?(AP_2) then
          #    content.gsub!(@@pattern_ap_2,AP_1)
          #  end
          #  #「&」<-「&amp;」
          #  if content.include?(AND_2) then
          #    content.gsub!(@@pattern_and_2,AND_1)
          #  end
          #else
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
          #end

          #content
        end
        private :unescape

        def unescape_content(content,elm_name)
          unescape(content)
        end
        private :unescape_content

      end
    end
  end
end