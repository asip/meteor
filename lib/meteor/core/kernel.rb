# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Core
    # Parser Core Class (パーサ・コア クラス)
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
      # find
      # E
      PATTERN_FIND_1 = "^([^,\\[\\]#\\.]+)$"
      # # id_attribute_value
      PATTERN_FIND_2_1 = "^#([^\\.,\\[\\]#][^,\\[\\]#]*)$"
      # .class_attribute_value
      PATTERN_FIND_2_2 = "^\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$"
      # [attribute_name=attribute_value]
      PATTERN_FIND_2_3 = "^\\[([^\\[\\],]+)=([^\\[\\],]+)\\]$"
      # E[attribute_name=attribute_value]
      PATTERN_FIND_3_1 = "^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,\\[\\]]+)=([^,\\[\\]]+)\\]$"
      # E# id_attribute_value
      PATTERN_FIND_3_2 = "^([^\\.,\\[\\]#][^,\\[\\]#]+)#([^\\.,\\[\\]#][^,\\[\\]#]*)$"
      # E.class_attribute_value
      PATTERN_FIND_3_3 = "^([^\\.,\\[\\]#][^,\\[\\]#]+)\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$"
      # [attribute_name1=attribute_value1][attribute_name2=attribute_value2]
      PATTERN_FIND_4 = "^\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$"
      # E[attribute_name1=attribute_value1][attribute_name2=attribute_value2]
      PATTERN_FIND_5 = "^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$"

      @@pattern_find_1 = Regexp.new(PATTERN_FIND_1)
      @@pattern_find_2_1 = Regexp.new(PATTERN_FIND_2_1)
      @@pattern_find_2_2 = Regexp.new(PATTERN_FIND_2_2)
      @@pattern_find_2_3 = Regexp.new(PATTERN_FIND_2_3)
      @@pattern_find_3_1 = Regexp.new(PATTERN_FIND_3_1)
      @@pattern_find_3_2 = Regexp.new(PATTERN_FIND_3_2)
      @@pattern_find_3_3 = Regexp.new(PATTERN_FIND_3_3)
      @@pattern_find_4 = Regexp.new(PATTERN_FIND_4)
      @@pattern_find_5 = Regexp.new(PATTERN_FIND_5)

      @@pattern_set_mono1 = Regexp.new("\\A[^<>]*\\Z")

      @@pattern_get_attrs_map = Regexp.new("([^\\s]*)=\"([^\\\"]*)\"")

      @@pattern_clean1 = Regexp.new("<!--\\s@[^<>]*\\s[^<>]*(\\s)*-->")
      @@pattern_clean2 = Regexp.new("<!--\\s\\/@[^<>]*(\\s)*-->")

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
        # parent element (親要素)
        # @parent = nil

        # pattern (正規表現パターン)
        # @pattern = nil
        # root element (ルート要素)
        @root = RootElement.new
        @root.parser = self
        # element cache (要素キャッシュ)
        @element_cache = Hash.new
        # document hook (フック・ドキュメント)
        @document_hook = String.new("")

        @error_check = true
      end

      #
      # read file , set in parser (ファイルを読み込み、パーサにセットする)
      # @param [String] file_path absolute path of input file (入力ファイルの絶対パス)
      # @param [String] enc character encoding of input file (入力ファイルの文字コード)
      #
      def read(file_path, enc)

        # try {
        @character_encoding = enc
        # open file (ファイルのオープン)
        if "UTF-8".eql?(enc)
          # io = File.open(file_path,"r:" << enc)
          io = File.open(file_path, "r:UTF-8")
        else
          io = File.open(file_path, String.new("") << "r:" << enc << ":utf-8")
        end

        # load and save (読込及び格納)
        @root.document = io.read

        parse

        # close file (ファイルのクローズ)
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
      def element(elm, attrs = nil, *args)
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
            element_2(elm.to_s, attrs.to_s)
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end

          when ONE
            element_3(elm.to_s, attrs.to_s, args[0])
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end

          when TWO
            element_4(elm.to_s, attrs.to_s, args[0].to_s, args[1])
            if @elm_
              @element_cache.store(@elm_.object_id, @elm_)
            end

          when THREE
            element_5(elm.to_s, attrs.to_s, args[0], args[1].to_s, args[2])
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

        # element search pattern (要素検索用パターン)
        @pattern_cc = "<#{@_name}(|\\s[^<>]*)\\/>|<#{@_name}((?:|\\s[^<>]*))>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        # search of element with content (内容あり要素検索)
        @res = @pattern.match(@root.document)

        if @res
          if @res[1]
            element_without_1(name)
          else
            # puts '---element_with_1'
            element_with_1(name)
          end
          # else
        end

        @elm_
      end

      private :element_1

      def element_with_1(name)
        @elm_ = Meteor::Element.new(name)

        unless @on_search
          # puts '--on_search=false'
          # puts @res.to_a
          # attribute (属性)
          @elm_.attributes = @res[2]
          # content (内容)
          @elm_.mixed_content = @res[3]
          # document (全体)
          @elm_.document = @res[0]
        else
          # puts '--on_search=true'
          # attribute (属性)
          @elm_.attributes = @res[1]
          # content (内容)
          @elm_.mixed_content = @res[2]
          # document (全体)
          @elm_.document = @res[0]
        end
        # search pattern of element with content (内容あり要素検索用パターン)
        # @pattern_cc = String.new('') << "<" << @_name << '(?:|\\s[^<>]*)>((?!(' << @_name
        # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
        @pattern_cc = "<#{@_name}(|\\s[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @elm_.pattern = @pattern_cc
        @elm_.empty = true
        @elm_.parser = self

        @elm_
      end

      private :element_with_1

      def element_without_1(name)
        # element (要素)
        @elm_ = Meteor::Element.new(name)
        # attribute (属性)
        @elm_.attributes = @res[1]
        # document (全体)
        @elm_.document = @res[0]
        # void element search pattern (空要素検索用パターン)
        @pattern_cc = String.new("") << "<" << @_name << "(|\\s[^<>]*)\\/>"
        # @pattern_cc = "<#{@_name}(|\\s[^<>]*)\\/>"
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
      # @param [true,false] quote flag (クオート・フラグ)
      # @return [Meteor::Element] element (要素)
      def element_3(name, attr_name, attr_value, quote = true)
        if quote
          quote_element_3(name, attr_name, attr_value)
        else
          quote_name(name)
        end

        @pattern_cc_1 = element_pattern_3

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_with_3_2
          @pattern_cc_2 = @pattern_cc

          # puts @res2.captures.length
          # puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            # @pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_3(name)
            else
              element_with_3_1(name)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            # @pattern_cc = @pattern_cc_2
            element_with_3_1(name)
          end
        elsif @res1 && !@res2
          @res = @res1
          # @pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_3(name)
          else
            element_with_3_1(name)
          end
        elsif @res2 && !@res1
          @res = @res2
          # @pattern_cc = @pattern_cc_2
          element_with_3_1(name)
        else
          if @error_check
            puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message)
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

      def quote_element_3(name, attr_name, attr_value)
        quote_name(name)
        quote_attribute(attr_name, attr_value)
      end

      private :quote_element_3

      def element_with_3_1(name)
        # puts  @res.captures.length
        case @res.captures.length
        when FOUR
          # 要素
          @elm_ = Meteor::Element.new(name)
          # 属性
          @elm_.attributes = @res[1]
          # 内容
          @elm_.mixed_content = @res[2]
          # 全体
          @elm_.document = @res[0]
          # 内容あり要素検索用パターン
          # @pattern_cc = String.new('')<< "<" << @_name << '\\s[^<>]*' << @_attr_name << '="'
          # @pattern_cc << @_attr_value << '"[^<>]*>((?!(' << @_name
          # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
          @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        when FIVE
          # element (要素)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[2]
          # content (内容)
          @elm_.mixed_content = @res[3]
          # document (全体)
          @elm_.document = @res[0]
          # search pattern of element with content (内容あり要素検索用パターン)
          # @pattern_cc = String.new('')<< "<" << @_name << '\\s[^<>]*' << @_attr_name << '="'
          # @pattern_cc << @_attr_value << '"[^<>]*>((?!(' << @_name
          # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
          @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc

          @elm_.empty = true

          @elm_.parser = self

        when THREE, SIX
          # element (要素)
          @elm_ = Meteor::Element.new(name)
          unless @on_search
            # attribute (属性)
            @elm_.attributes = @res[1].chop
            # content (内容)
            @elm_.mixed_content = @res[3]
          else
            # attribute (属性)
            @elm_.attributes = @res[1].chop
            # content (内容)
            @elm_.mixed_content = @res[3]
          end
          # document (全体)
          @elm_.document = @res[0]
          # search pattern of element with content (内容あり要素検索用パターン)
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
        # @pattern_cc_1 = String.new('') << "<" << @_name << '(\\s[^<>]*' << @_attr_name << '="'
        # @pattern_cc_1 << @_attr_value << '(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))'
        @pattern_cc_1 = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"
        @pattern_cc_1b = String.new("") << "<" << @_name << "(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        # @pattern_cc_1b = "<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        # @pattern_cc_1_1 = String.new('') << "<" << @_name << '(\\s[^<>]*' << @_attr_name << '="'
        # @pattern_cc_1_1 << @_attr_value << '"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))('
        @pattern_cc_1_1 = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
        @pattern_cc_1_2 = String.new("") << ".*?<" << @_name << "(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        # @pattern_cc_1_2 = ".*?<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        @pattern_cc_2 = String.new("") << "<\\/" << @_name << ">"
        # @pattern_cc_2 = String.new('') << "<\\/#{@_name}>"
        @pattern_cc_2_1 = String.new("") << ".*?<\\/" << @_name << ">"
        # @pattern_cc_2_1 = ".*?<\\/#{@_name}>"
        @pattern_cc_2_2 = String.new("") << ".*?)<\\/" << @_name << ">"
        # @pattern_cc_2_2 = ".*?)<\\/#{@_name}>"

        # search of element with content (内容あり要素検索)
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = String.new("")

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf
      end

      private :element_pattern_with_3_2

      def element_without_3(name)
        element_without_3_1(name, "\"[^<>]*)\\/>")
      end

      private :element_without_3

      def element_without_3_1(name, closer)
        # element (要素)
        @elm_ = Meteor::Element.new(name)
        # attribute (属性)
        @elm_.attributes = @res[1]
        # document (全体)
        @elm_.document = @res[0]
        # pattern (空要素検索用パターン)
        @pattern_cc = String.new("") << "<" << @_name << "(\\s[^<>]*" << @_attr_name << "=\"" << @_attr_value << closer
        # @pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}#{closer}"
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

        quote_attribute(attr_name, attr_value)

        element_pattern_2

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        if @res
          element_3(@res[1], attr_name, attr_value)
        else
          if @error_check
            puts(Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message)
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

          # puts @res2.captures.length
          # puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            # @pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_2
            else
              element_with_2_1
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            # @pattern_cc = @pattern_cc_2
            element_with_2_1
          end
        elsif @res1 && !@res2
          @res = @res1
          # @pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_2
          else
            element_with_2_1
          end
        elsif @res2 && !@res1
          @res = @res2
          # @pattern_cc = @pattern_cc_2
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

      def quote_name(name)
        @_name = Regexp.quote(name)
      end

      private :quote_name

      def quote_attribute(attr_name, attr_value)
        @_attr_name = Regexp.quote(attr_name)
        @_attr_value = Regexp.quote(attr_value)
      end

      private :quote_attribute

      def element_pattern_2
        # # @pattern_cc = String.new('') << '<([^<>"]*)\\s[^<>]*' << @_attr_name << '="' << @_attr_value << '(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        # @pattern_cc = String.new('') << '<([^<>"]*)\\s[^<>]*' << @_attr_name << '="' << @_attr_value << '"'
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\""
      end

      private :element_pattern_2

=begin
      def element_with_2_1
        # puts @res.captures.length
        case @res.captures.length
          when FOUR
            @_name = @res[1]
            # eleement (要素)
            @elm_ = Element.new(@_name)
            # attribute (属性)
            @elm_.attributes = @res[2]
            # content (内容)
            @elm_.mixed_content = @res[3]
            # document (全体)
            @elm_.document = @res[0]
            # pattern (内容あり要素検索用パターン)
            # @pattern_cc = String.new('') << "<" << @_name << '\\s[^<>]*' << @_attr_name << '="'
            # @pattern_cc << @_attr_value << '"[^<>]*>((?!(' << @_name
            # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
            @ pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>"

            @elm_.pattern = @pattern_cc
            @elm_.empty = true
            @elm_.parser = self
          when FIVE,SEVEN
            @_name = @res[3]
            # element (要素)
            @elm_ = Element.new(@_name)
            # attribute (属性)
            @elm_.attributes = @res[4]
            # content (内容)
            @elm_.mixed_content = @res[5]
            # document (全体)
            @elm_.document = @res[0]
            # pattern (内容あり要素検索用パターン)
            # @pattern_cc = String.new()<< "<" << @_name << '\\s[^<>]*' << @_attr_name << '="'
            # @pattern_cc << @_attr_value << '"[^<>]*>((?!(' << @_name
            # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
            @pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>"

            @elm_.pattern = @pattern_cc
            @elm_.empty = true
            @elm_.parser = self
          when THREE,SIX
            # puts @res[1]
            # puts @res[3]
            # @_name = @res[1]
            # element (要素)
            @elm_ = Element.new(@_name)
            # attribute (属性)
            @elm_.attributes = @res[1].chop
            # content (内容)
            @elm_.mixed_content = @res[3]
            # document (全体)
            @elm_.document = @res[0]
            # pattern (内容あり要素検索用パターン)
            @elm_.pattern = @pattern_cc

            @elm_.empty = true
            @elm_.parser = self
        end
        @elm_
      end

      private :element_with_2_1

      def element_with_2_2
        # @pattern_cc_1 = String.new('') << "<" << @_name << '(\\s[^<>]*' << @_attr_name << '="'
        # @pattern_cc_1 << @_attr_value << '(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))'
        @pattern_cc_1 = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))"

        # search of element with content (内容あり要素検索)
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
      end

      private :element_with_2_2

      def create_pattern_2(args_cnt)
        @pattern_cc_1b = String.new('') << "<" << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'

        # @pattern_cc_1_1 = String.new('') << "<" << @_name << '(\\s[^<>]*' << @_attr_name << '="'
        # @pattern_cc_1_1 << @_attr_value << '"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))('
        @pattern_cc_1_1 = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
        @pattern_cc_1_2 = String.new('') << '.*?<' << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        @pattern_cc_2 = String.new('') << '<\\/' << @_name << '>'
        @pattern_cc_2_1 = String.new('') << '.*?<\/' << @_name << '>'
        @pattern_cc_2_2 = String.new('') << '.*?)<\/' << @_name << '>'

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)
      end

      def element_without_2
        element_without_2_1('"[^<>]*\\/>')
      end

      private :element_without_2

      def element_without_2_1(closer)
        # element (要素)
        @elm_ = Element.new(@res[1])
        # attribute (属性)
        @elm_.attributes = @res[2]
        # document (全体)
        @elm_.document = @res[0]
        # void element search pattern (空要素検索用パターン)
        @pattern_cc = String.new('') << "<" << @_name << '\\s[^<>]*' << @_attr_name << '="' << @_attr_value << closer
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

        quote_element_5(name, attr_name1, attr_value1, attr_name2, attr_value2)

        @pattern_cc_1 = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)\\/>|<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_with_5_2
          @pattern_cc_2 = @pattern_cc

          # puts @res2.captures.length
          # puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            # @pattern_cc = @pattern_cc_1
            if @res[1]
              element_without_5(name)
            else
              element_with_5_1(name)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            # @pattern_cc = @pattern_cc_2
            element_with_5_1(name)
          end
        elsif @res1 && !@res2
          @res = @res1
          # @pattern_cc = @pattern_cc_1
          if @res[1]
            element_without_5(name)
          else
            element_with_5_1(name)
          end
        elsif @res2 && !@res1
          @res = @res2
          # @pattern_cc = @pattern_cc_2
          element_with_5_1(name)
        else
          if @error_check
            puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message)
          end

          @elm_ = nil
        end

        @elm_
      end

      private :element_5

      def quote_element_5(name, attr_name1, attr_value1, attr_name2, attr_value2)
        @_name = Regexp.quote(name)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)
      end

      private :quote_element_5

      def element_with_5_1(name)

        # puts @res.captures.length
        case @res.captures.length
        when FOUR
          # eleemnt (要素)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[1]
          # content (内容)
          @elm_.mixed_content = @res[2]
          # document (全体)
          @elm_.document = @res[0]
          # pattern (内容あり要素検索用パターン)
          # @pattern_cc = String.new('') << "<" << @_name << '\\s[^<>]*(?:' << @_attr_name1 << '="'
          # @pattern_cc << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
          # @pattern_cc << @_attr_value2 << '"|' << @_attr_name2 << '="'
          # @pattern_cc << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
          # @pattern_cc << @_attr_value1 << '")[^<>]*>((?!(' << @_name
          # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
          @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc
          @elm_.empty = true
          @elm_.parser = self
        when FIVE
          # element (要素)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[2]
          # content (内容)
          @elm_.mixed_content = @res[3]
          # documement (全体)
          @elm_.document = @res[0]
          # pattern (内容あり要素検索用パターン)
          # @pattern_cc = String.new('') << "<" << @_name << '\\s[^<>]*(?:' << @_attr_name1 << '="'
          # @pattern_cc << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
          # @pattern_cc << @_attr_value2 << '"|' << @_attr_name2 << '="'
          # @pattern_cc << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
          # @pattern_cc << @_attr_value1 << '")[^<>]*>((?!(' << @_name
          # @pattern_cc << '[^<>]*>)).)*<\\/' << @_name << '>'
          @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

          @elm_.pattern = @pattern_cc
          @elm_.empty = true
          @elm_.parser = self

        when THREE, SIX
          # element (要素)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[1].chop
          # content (内容)
          @elm_.mixed_content = @res[3]
          # document (全体)
          @elm_.document = @res[0]
          # search pattern of element with content (要素ありタグ検索用パターン)
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

        # @pattern_cc_1 = String.new('') << "<" << @_name << '(\\s[^<>]*(?:' << @_attr_name1 << '="'
        # @pattern_cc_1 << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
        # @pattern_cc_1 << @_attr_value2 << '"|' << @_attr_name2 << '="'
        # @pattern_cc_1 << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
        # @pattern_cc_1 << @_attr_value1 << '")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))'
        @pattern_cc_1 = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))"
        @pattern_cc_1b = String.new("") << "<" << @_name << "(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        # @pattern_cc_1b = "<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        # @pattern_cc_1_1 = String.new('') << "<" << @_name << '(\\s[^<>]*(?:' << @_attr_name1 << '="'
        # @pattern_cc_1_1 << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
        # @pattern_cc_1_1 << @_attr_value2 << '"|' << @_attr_name2 << '="'
        # @pattern_cc_1_1 << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
        # @pattern_cc_1_1 << @_attr_value1 << '")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))('
        @pattern_cc_1_1 = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))("
        @pattern_cc_1_2 = String.new("") << ".*?<" << @_name << "(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        @pattern_cc_2 = String.new("") << "<\\/" << @_name << ">"
        @pattern_cc_2_1 = String.new("") << ".*?<\\/" << @_name << ">"
        @pattern_cc_2_2 = String.new("") << ".*?)<\\/" << @_name << ">"

        # @pattern_cc_1_2 = ".*?<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        # @pattern_cc_2 = String.new('') << "<\\/#{@_name}>"
        # @pattern_cc_2_1 = ".*?<\\/#{@_name}>"
        # @pattern_cc_2_2 = ".*?)<\\/#{@_name}>"

        # search of element with content (内容あり要素検索)
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_1)

        @sbuf = String.new("")

        @pattern_2 = Meteor::Core::Util::PatternCache.get(@pattern_cc_2)
        @pattern_1b = Meteor::Core::Util::PatternCache.get(@pattern_cc_1b)
        @cnt = 0

        create_element_pattern
        @pattern_cc = @sbuf
      end

      private :element_pattern_with_5_2

      def element_without_5(name)
        element_without_5_1(name, "\")[^<>]*)\\/>")
      end

      private :element_without_5

      def element_without_5_1(name, closer)
        # element (要素)
        @elm_ = Meteor::Element.new(name)
        # attribute (属性)
        @elm_.attributes = @res[1]
        # document (全体)
        @elm_.document = @res[0]
        # pattern (空要素検索用パターン)
        # @pattern_cc = String.new('') << "<" << @_name << '\\s[^<>]*(?:' << @_attr_name1 << '="'
        # @pattern_cc << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
        # @pattern_cc << @_attr_value2 << '"|' << @_attr_name2 << '="'
        # @pattern_cc << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
        # @pattern_cc << @_attr_value1 << closer
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

        quote_element_4(attr_name1, attr_value1, attr_name2, attr_value2)

        element_pattern_4

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        if @res
          # @elm_ = element_5(@res[1], attr_name1, attr_value1,attr_name2, attr_value2)
          element_5(@res[1], attr_name1, attr_value1, attr_name2, attr_value2)
        else
          if @error_check
            puts(
              Meteor::Exception::NoSuchElementException.new(attr_name1, attr_value1, attr_name2, attr_value2).message
            )
          end

          @elm_ = nil
        end

        @elm_
      end

      private :element_4

      def quote_element_4(attr_name1, attr_value1, attr_name2, attr_value2)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)
      end

      private :quote_element_4

      def element_pattern_4

        # @pattern_cc = String.new('') << '<([^<>"]*)\\s([^<>]*(' << @_attr_name1 << '="'
        # @pattern_cc << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
        # @pattern_cc << @_attr_value2 << '"|' << @_attr_name2 << '="'
        # @pattern_cc << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
        # @pattern_cc << @_attr_value1 << '"'
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

      # def create_pattern_2
      # end

      # private :create_pattern_2
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
      def elements(elm, attrs = nil, *args)
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
            elements_(elm, attrs)
          when ONE
            elements_(elm, attrs, args[0])
          when TWO
            elements_(elm, attrs, args[0], args[1])
          when THREE
            elements_(elm, attrs, args[0], args[1], args[2])
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

        # puts @pattern_cc

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @position = 0

        while (@res = @pattern.match(@root.document, @position))
          @position = @res.end(0)
          # puts @res[0]
          # if @res
          case args.size
          when ONE
            if @elm_.empty
              element_with_1(@elm_.name)
            else
              element_without_1(@elm_.name)
            end

          when TWO, THREE
            if @elm_.empty
              element_with_3_1(@elm_.name)
            else
              element_without_3(@elm_.name)
            end

          when FOUR, FIVE
            if @elm_.empty
              element_with_5_1(@elm_.name)
            else
              element_without_5(@elm_.name)
            end
          end

          @elm_.pattern = Regexp.quote(@elm_.document)
          elm_arr << @elm_

          @element_cache.store(@elm_.object_id, @elm_)

          # else
          #  break
          # end
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
        open_count = selector.count("[")

        case open_count
        when ZERO
          if selector.count("#.") == 0
            if @res = @@pattern_find_1.match(selector)
              elements_(@res[1])
            else
              nil
            end
          elsif selector.count("#") == 1
            if selector[0] == "#"
              if @res = @@pattern_find_2_1.match(selector)
                elements_("id", @res[1])
              else
                nil
              end
            else
              if @res = @@pattern_find_3_2.match(selector)
                elements_(@res[1], "id", @res[2])
              else
                nil
              end
            end
          elsif selector.count(".") == 1
            if selector[0] == "."
              if @res = @@pattern_find_2_2.match(selector)
                elements_("class", @res[1])
              else
                nil
              end
            else
              if @res = @@pattern_find_3_3.match(selector)
                elements_(@res[1], "class", @res[2])
              else
                nil
              end
            end
          end

        when ONE
          if selector[0] == "["
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
          if selector[0] == "["
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
      def attr(elm, attr, *args)
        if attr.kind_of?(String) || attr.kind_of?(Symbol)
          case args.length
          when ZERO
            get_attr_value(elm, attr.to_s)
          when ONE
            if args[0] != nil
              elm.document_sync = true
              set_attribute_3(elm, attr.to_s, args[0])
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
          # elsif attrs.kind_of?(Hash) && attrs.size >= 1
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
          # update attributes (属性群の更新)
          edit_attrs_(elm, attr_name, attr_value)
        end

        elm
      end

      private :set_attribute_3

      def edit_attrs_(elm, attr_name, attr_value)

        # attribute search (属性検索)
        # @res = @pattern.match(elm.attributes)

        #  (検索対象属性の存在判定)
        if elm.attributes.include?(String.new(" ") << attr_name << "=\"")
          @_attr_value = attr_value

          # replace attribute (属性の置換)
          @pattern = Meteor::Core::Util::PatternCache.get(String.new("") << attr_name << "=\"[^\"]*\"")
          # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"")

          elm.attributes.sub!(@pattern, String.new("") << attr_name << "=\"" << @_attr_value << "\"")
          # elm.attributes.sub!(@pattern, "#{attr_name}=\"#{@_attr_value}\"")
        else
          # add an attribute to attrubutes (属性文字列の最後に新規の属性を追加する)
          @_attr_value = attr_value

          if "" != elm.attributes && "" != elm.attributes.strip
            elm.attributes = String.new("") << " " << elm.attributes.strip
          else
            elm.attributes = String.new("")
          end

          elm.attributes << " " << attr_name << "=\"" << @_attr_value << "\""
          # elm.attributes << " #{attr_name}=\"#{@_attr_value}\""
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

        # attribute search pattern (属性検索用パターン)
        @pattern = Meteor::Core::Util::PatternCache.get(String.new("") << attr_name << "=\"([^\"]*)\"")
        # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"([^\"]*)\"")

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
      def attrs(elm, *args)
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
      def attr_map(elm, *args)
        case args.length
        when ZERO
          get_attr_map(elm)
        when ONE
          # if elm.kind_of?(Meteor::Element) && args[0].kind_of?(Meteor::AttributeMap)
          elm.document_sync = true
          set_attr_map(elm, args[0])
          # end
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
          # if args[0].kind_of?(Meteor::Element)
          get_content_1(args[0])
          # else
          #  raise ArgumentError
          # end
        when TWO
          # if args[0].kind_of?(Meteor::Element) && args[1].kind_of?(String)
          args[0].document_sync = true
          set_content_2(args[0], args[1].to_s)
          # else
          #  raise ArgumentError
          # end
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
      def set_content_3(elm, content, entity_ref = true)

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
        # set_content_3(elm, content)
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
        # attribute search pattern (属性検索用パターン)
        @pattern = Meteor::Core::Util::PatternCache.get(String.new("") << attr_name << "=\"[^\"]*\"\\s?")
        # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"\\s?")
        # replace attrubute (属性の置換)
        elm.attributes.sub!(@pattern, "")
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

        # CX tag search pattern  (CXタグ検索用パターン)
        # @pattern_cc = String.new('') << "<!--\\s@" << @_name << '\\s([^<>]*id="'
        # @pattern_cc << id << '"[^<>]*)-->(((?!(<!--\\s/@' << @_name << ")).)*)<!--\\s/@" << @_name << "\\s-->"
        # @pattern_cc = "<!--\\s@#{tag}\\s([^<>]*id=\"#{id}\"[^<>]*)-->(((?!(<!--\\s\\/@#{tag})).)*)<!--\\s\\/@#{tag}\\s-->"
        @pattern_cc = "<!--\\s@#{@_name}\\s([^<>]*id=\"#{@_id}\"[^<>]*)-->(((?!(<!--\\s/@#{@_name})).)*)<!--\\s/@#{@_name}\\s-->"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        # CX tag search (CXタグ検索)
        @res = @pattern.match(@root.document)

        if @res
          # element (要素)
          @elm_ = Meteor::Element.new(name)

          @elm_.cx = true
          # attrubute (属性)
          @elm_.attributes = @res[1]
          # content (内容)
          @elm_.mixed_content = @res[2]
          # document (全体)
          @elm_.document = @res[0]
          # pattren (要素検索パターン)
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

        @pattern_cc = String.new("") << "<!--\\s@([^<>]*)\\s[^<>]*id=\"" << @_id << "\""
        # @pattern_cc = "<!--\\s@([^<>]*)\\s[^<>]*id=\"#{@_id}\""

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

        @res = @pattern.match(@root.document)

        if @res
          # @elm_ = cxtag(@res[1],id)
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
        # tag replacement pattern (タグ置換パターン)
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        # replace tag (タグ置換)
        @root.document.sub!(@pattern, replace_document)
      end

      private :replace

      def reflect
        # puts @element_cache.size.to_s
        @element_cache.values.each do |item|
          if item.usable
            # puts "#{item.name}:#{item.document}"
            if !item.removed
              if item.copy
                @pattern = Meteor::Core::Util::PatternCache.get(item.pattern)
                @root.document.sub!(@pattern, item.copy.parser.document_hook)
                # item.copy.parser.element_cache.clear
                item.copy = nil
              else
                edit_document_1(item)
                # edit_pattern_(item)
              end
            else
              replace(item, "")
            end

            item.usable = false
          end
        end
      end

      protected :reflect

      def edit_document_1(elm)
        edit_document_2(elm, "/>")
      end

      private :edit_document_1

      def edit_document_2(elm, closer)

        # replace tag (タグ置換)
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
              # @root.hookDocument << '<!-- @' << @root.element.name << ' '
              # @root.hookDocument << @root.element.attributes << '-->'
              # @root.hookDocument << @root.element.mixed_content << '<!-- /@'
              # @root.hookDocument << @root.element.name << ' -->'
              self.document_hook <<
                "<!-- @#{self.element_hook.name} #{self.element_hook.attributes}-->#{self.element_hook.mixed_content}<!-- /@#{self.element_hook.name} -->"

              # self.document_hook << @root.kaigyo_code << "<!-- @#{self.element_hook.name} #{self.element_hook.attributes}-->#{self.element_hook.mixed_content}<!-- /@#{self.element_hook.name} -->"
            else
              # @root.hookDocument << "<" << @root.element.name
              # @root.hookDocument << @root.element.attributes << '>' << @root.element.mixed_content
              # @root.hookDocument << '</' << @root.element.name << '>'
              self.document_hook <<
                "<#{self.element_hook.name}#{self.element_hook.attributes}>#{self.element_hook.mixed_content}</#{self.element_hook.name}>"

              # self.document_hook << @root.kaigyo_code << "<#{self.element_hook.name}#{self.element_hook.attributes}>#{self.element_hook.mixed_content}</#{self.element_hook.name}>"
            end

            self.element_hook = Element.new!(self.element_hook.origin, self)
          else
            reflect
            @_attributes = self.element_hook.attributes

            if self.element_hook.origin.cx
              # @root.hookDocument << '<!-- @' << @root.element.name << ' '
              # @root.hookDocument << @_attributes << '-->'
              # @root.hookDocument << @root.document << '<!-- /@'
              # @root.hookDocument << @root.element.name << ' -->'
              self.document_hook <<
                "<!-- @#{self.element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{self.element_hook.name} -->"

              # self.document_hook << @root.kaigyo_code << "<!-- @#{self.element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{self.element_hook.name} -->"
            else
              # @root.hookDocument << "<" << @root.element.name
              # @root.hookDocument << @_attributes << '>' << @root.document
              # @root.hookDocument << '</' << @root.element.name << '>'
              self.document_hook <<
                "<#{self.element_hook.name}#{@_attributes}>#{@root.document}</#{self.element_hook.name}>"

              # self.document_hook << @root.kaigyo_code << "<#{self.element_hook.name}#{@_attributes}>#{@root.document}</#{self.element_hook.name}>"
            end

            self.element_hook = Element.new!(self.element_hook.origin, self)
          end
        else
          reflect
          @element_cache.clear
          # フック判定が"false"の場合
          clean
        end
      end

      def clean
        # replace CX start tag (CX開始タグ置換)
        @pattern = @@pattern_clean1
        @root.document.gsub!(@pattern, "")
        # rplace CX end tag (CX終了タグ置換)
        @pattern = @@pattern_clean2
        @root.document.gsub!(@pattern, "")
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
          # case of element with content (内容あり要素の場合)
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

      # private :shadow

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
        when Parser::HTML
          Meteor::Ml::Html::ParserImpl.new
        when Parser::XML
          Meteor::Ml::Xml::ParserImpl.new
        when Parser::XHTML
          Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::HTML4
          Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4
          Meteor::Ml::Xhtml4::ParserImpl.new
        else
          nil
        end
      end

      private :create
    end
  end
end
