# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Core
    # Parser Core Class (パーサ・コア クラス)
    #
    # @!attribute [rw] element_cache
    #  @return [Hash] element cache (要素キャッシュ)
    # @!attribute [rw] doc_type
    #  @return [Integer] document type (ドキュメントタイプ)
    # @!attribute [rw] document_hook
    #  @return [String] hook document (フック・ドキュメント)
    # @!attribute [rw] element_hook
    #  @return [Meteor::Element] element (要素)
    #
    class Kernel < Meteor::Parser # rubocop:disable Metrics/ClassLength
      # find
      # E
      PATTERN_FIND_ONE = '^([^,\\[\\]#\\.]+)$'
      # # id_attribute_value
      PATTERN_FIND_TWO_ONE = '^#([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # .class_attribute_value
      PATTERN_FIND_TWO_TWO = '^\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # [attribute_name=attribute_value]
      PATTERN_FIND_TWO_THREE = '^\\[([^\\[\\],]+)=([^\\[\\],]+)\\]$'
      # E[attribute_name=attribute_value]
      PATTERN_FIND_THREE_ONE = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,\\[\\]]+)=([^,\\[\\]]+)\\]$'
      # E# id_attribute_value
      PATTERN_FIND_THREE_TWO = '^([^\\.,\\[\\]#][^,\\[\\]#]+)#([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # E.class_attribute_value
      PATTERN_FIND_THREE_THREE = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\.([^\\.,\\[\\]#][^,\\[\\]#]*)$'
      # [attribute_name1=attribute_value1][attribute_name2=attribute_value2]
      PATTERN_FIND_FOUR = '^\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$'
      # E[attribute_name1=attribute_value1][attribute_name2=attribute_value2]
      PATTERN_FIND_FIVE = '^([^\\.,\\[\\]#][^,\\[\\]#]+)\\[([^,]+)=([^,]+)\\]\\[([^,]+)=([^,]+)\\]$'

      RE_FIND_ONE = Regexp.new(PATTERN_FIND_ONE)
      RE_FIND_TWO_ONE = Regexp.new(PATTERN_FIND_TWO_ONE)
      RE_FIND_TWO_TWO = Regexp.new(PATTERN_FIND_TWO_TWO)
      RE_FIND_TWO_THREE = Regexp.new(PATTERN_FIND_TWO_THREE)
      RE_FIND_THREE_ONE = Regexp.new(PATTERN_FIND_THREE_ONE)
      RE_FIND_THREE_TWO = Regexp.new(PATTERN_FIND_THREE_TWO)
      RE_FIND_THREE_THREE = Regexp.new(PATTERN_FIND_THREE_THREE)
      RE_FIND_FOUR = Regexp.new(PATTERN_FIND_FOUR)
      RE_FIND_FIVE = Regexp.new(PATTERN_FIND_FIVE)

      RE_CHILDLESS = Regexp.new('\\A[^<>]*\\Z')

      RE_GET_ATTRS_MAP = Regexp.new('([^\\s]*)="([^\"]*)"')

      RE_CLEAN_ONE = Regexp.new('<!--\\s@[^<>]*\\s[^<>]*(\\s)*-->')
      RE_CLEAN_TWO = Regexp.new('<!--\\s\\/@[^<>]*(\\s)*-->')

      BR = '<br>'
      BR_RE = BR

      TABLE_FOR_ESCAPE_ = {
        '&' => '&amp;',
        '"' => '&quot;',
        "'" => '&apos;',
        '<' => '&lt;',
        '>' => '&gt;',
        ' ' => '&nbsp;'
      }.freeze

      TABLE_FOR_ESCAPE_CONTENT_ = {
        '&' => '&amp;',
        '"' => '&quot;',
        "'" => '&apos;',
        '<' => '&lt;',
        '>' => '&gt;',
        ' ' => '&nbsp;',
        "\r\n" => BR,
        "\r" => BR,
        "\n" => BR
      }.freeze

      PATTERN_ESCAPE = "[&\"'<> ]"
      PATTERN_ESCAPE_CONTENT = "[&\"'<> \\n]"
      RE_ESCAPE = Regexp.new(PATTERN_ESCAPE)
      RE_ESCAPE_CONTENT = Regexp.new(PATTERN_ESCAPE_CONTENT)

      PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt|nbsp);'
      RE_UNESCAPE = Regexp.new(PATTERN_UNESCAPE)
      RE_BR_TWO = Regexp.new(BR_RE)

      attr_accessor :element_cache, :doc_type, :document_hook, :element_hook

      #
      # set document (ドキュメントをセットする)
      #
      # @param [String] doc document (ドキュメント)
      #
      def document=(doc)
        @root.document = doc

        parse
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
      def enc=(enc)
        @root.enc = enc
      end

      alias character_encoding= enc=

      #
      # get character encoding (文字エンコーディングを取得する)
      # @return [String] character encoding (文字エンコーディング)
      #
      def enc
        @root.enc
      end

      alias character_encoding enc

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
        super
        # parent element (親要素)
        # @parent = nil

        # pattern (正規表現パターン)
        # @pattern = nil
        # root element (ルート要素)
        @root = RootElement.new
        @root.parser = self
        # element cache (要素キャッシュ)
        @element_cache = {}
        # document hook (フック・ドキュメント)
        @document_hook = String.new('')

        @error_check = true
      end

      #
      # read file , set in parser (ファイルを読み込み、パーサにセットする)
      # @param [String] file_path absolute path of input file (入力ファイルの絶対パス)
      # @param [String] enc character encoding of input file (入力ファイルの文字コード)
      #
      def read(file_path, enc)
        self.enc = enc

        self.document = Meteor::Core::Util::FileReader.read(file_path, enc)

        @root.document
      end

      #
      # parse document (ドキュメントを解析する)
      # @param [String] document document (ドキュメント)
      #
      def parse; end

      protected :parse

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
      def element(elm, attrs = nil, *args) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        if !attrs
          case elm
          when String, Symbol
            element_one(elm.to_s)
            @element_cache.store(@elm_.object_id, @elm_) if @elm_
          when Meteor::Element
            shadow(elm)
          when Hash
            if elm.size == ONE
              element_two(elm.keys[0].to_s, elm.values[0])
              @element_cache.store(@elm_.object_id, @elm_) if @elm_
            elsif elm.size == TWO
              element_four(elm.keys[0].to_s, elm.values[0], elm.keys[1].to_s, elm.values[1])
              @element_cache.store(@elm_.object_id, @elm_) if @elm_
            else
              raise ArgumentError
            end
          else
            raise ArgumentError
          end
        elsif attrs.is_a?(Hash)
          if attrs.size == ONE
            element_three(elm.to_s, attrs.keys[0].to_s, attrs.values[0])
            @element_cache.store(@elm_.object_id, @elm_) if @elm_
          elsif attrs.size == TWO
            element_five(elm.to_s, attrs.keys[0].to_s, attrs.values[0], attrs.keys[1].to_s, attrs.values[1])
            @element_cache.store(@elm_.object_id, @elm_) if @elm_
          else
            @elm_ = nil
            raise ArgumentError
          end
        elsif attrs.is_a?(String) || attrs.is_a?(Symbol)
          case args.length
          when ZERO
            element_two(elm.to_s, attrs.to_s)
            @element_cache.store(@elm_.object_id, @elm_) if @elm_

          when ONE
            element_three(elm.to_s, attrs.to_s, args[0])
            @element_cache.store(@elm_.object_id, @elm_) if @elm_
          when TWO
            element_four(elm.to_s, attrs.to_s, args[0].to_s, args[1])
            @element_cache.store(@elm_.object_id, @elm_) if @elm_
          when THREE
            element_five(elm.to_s, attrs.to_s, args[0], args[1].to_s, args[2])
            @element_cache.store(@elm_.object_id, @elm_) if @elm_
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
      def element_one(name) # rubocop:disable Metrics/MethodLength
        quote_name(name)

        # element search pattern (要素検索用パターン)
        @pattern_cc = "<#{@_name}(|\\s[^<>]*)\\/>|<#{@_name}((?:|\\s[^<>]*))>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        # search of normal element (内容あり要素検索)
        @res = @pattern.match(@root.document)

        if @res
          if @res[1]
            element_void_one(name)
          else
            # puts '---element_normal_one'
            element_normal_one(name)
          end
          # else
        end

        @elm_
      end

      private :element_one

      def element_normal_one(name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @elm_ = Meteor::Element.new(name)

        if @on_search
          # puts '--on_search=true'
          # attribute (属性)
          @elm_.attributes = @res[1]
          # content (内容)
          @elm_.mixed_content = @res[2]
          # document (全体)
        else
          # puts '--on_search=false'
          # puts @res.to_a
          # attribute (属性)
          @elm_.attributes = @res[2]
          # content (内容)
          @elm_.mixed_content = @res[3]
          # document (全体)
        end
        @elm_.document = @res[0]
        # normal element search pattern (内容あり要素検索用パターン)
        @pattern_cc = "<#{@_name}(|\\s[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

        @elm_.pattern = @pattern_cc
        @elm_.normal = true
        @elm_.parser = self

        @elm_
      end

      private :element_normal_one

      def element_void_one(name)
        # element (要素)
        @elm_ = Meteor::Element.new(name)
        # attribute (属性)
        @elm_.attributes = @res[1]
        # document (全体)
        @elm_.document = @res[0]
        # void element search pattern (空要素検索用パターン)
        @pattern_cc = String.new('') << '<' << @_name << '(|\\s[^<>]*)\\/>'
        # @pattern_cc = "<#{@_name}(|\\s[^<>]*)\\/>"
        @elm_.pattern = @pattern_cc

        @elm_.normal = false

        @elm_.parser = self

        @elm_
      end

      private :element_void_one

      #
      # get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で検索し、要素を取得する)
      # @param [String] name tag name (タグ名)
      # @param [String] attr_name attribute name (属性名)
      # @param [String] attr_value attribute value (属性値)
      # @param [true,false] quote flag (クオート・フラグ)
      # @return [Meteor::Element] element (要素)
      def element_three(name, attr_name, attr_value, quote = true) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity,Style/OptionalBooleanParameter
        if quote
          quote_element_three(name, attr_name, attr_value)
        else
          quote_name(name)
        end

        @pattern_cc_one = element_pattern_three

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_one)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_normal_three_two
          @pattern_cc_two = @pattern_cc

          # puts @res2.captures.length
          # puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            # @pattern_cc = @pattern_cc_one
            if @res[1]
              element_void_three(name)
            else
              element_normal_three_one(name)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            # @pattern_cc = @pattern_cc_two
            element_normal_three_one(name)
          end
        elsif @res1 && !@res2
          @res = @res1
          # @pattern_cc = @pattern_cc_one
          if @res[1]
            element_void_three(name)
          else
            element_normal_three_one(name)
          end
        elsif @res2 && !@res1
          @res = @res2
          # @pattern_cc = @pattern_cc_two
          element_normal_three_one(name)
        else
          puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message) if @error_check

          @elm_ = nil
        end

        @elm_
      end

      private :element_three

      def element_pattern_three
        "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>|<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength
      end

      private :element_pattern_three

      def quote_element_three(name, attr_name, attr_value)
        quote_name(name)
        quote_attribute(attr_name, attr_value)
      end

      private :quote_element_three

      def element_normal_three_one(name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        # puts  @res.captures.length
        case @res.captures.length
        when FOUR
          # element (要素)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[1]
          # content (内容)
          @elm_.mixed_content = @res[2]
          # document (全体)
          @elm_.document = @res[0]
          # normal element search pattern (内容あり要素検索用パターン)
          @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength

          @elm_.pattern = @pattern_cc

          @elm_.normal = true

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
          # normal element search pattern (内容あり要素検索用パターン)
          @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>" # rubocop:disable Layout/LineLength

          @elm_.pattern = @pattern_cc

          @elm_.normal = true

          @elm_.parser = self

        when THREE, SIX
          # element (要素)
          @elm_ = Meteor::Element.new(name)
          @elm_.attributes = @res[1].chop
          # if @on_search
          # # attribute (属性)
          # # content (内容)
          # else
          #   # attribute (属性)
          #   # content (内容)
          # end
          @elm_.mixed_content = @res[3]
          # document (全体)
          @elm_.document = @res[0]
          #  normal element search pattern (内容あり要素検索用パターン)
          @elm_.pattern = @pattern_cc

          @elm_.normal = true

          @elm_.parser = self
        end

        @elm_
      end

      private :element_normal_three_one

      def element_normal_three_two
        element_pattern_normal_three_two

        return nil if @sbuf.length == ZERO || @cnt != ZERO

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end

      private :element_normal_three_two

      def element_pattern_normal_three_two # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @pattern_cc_one = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))" # rubocop:disable Layout/LineLength
        @pattern_cc_oneb = String.new('') << '<' << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        # @pattern_cc_oneb = "<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        @pattern_cc_one_one = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))(" # rubocop:disable Layout/LineLength
        @pattern_cc_one_two = String.new('') << '.*?<' << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        # @pattern_cc_one_two = ".*?<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        @pattern_cc_two = String.new('') << '<\\/' << @_name << '>'
        # @pattern_cc_two = String.new('') << "<\\/#{@_name}>"
        @pattern_cc_two_one = String.new('') << '.*?<\\/' << @_name << '>'
        # @pattern_cc_two_one = ".*?<\\/#{@_name}>"
        @pattern_cc_two_two = String.new('') << '.*?)<\\/' << @_name << '>'
        # @pattern_cc_two_two = ".*?)<\\/#{@_name}>"

        # search of normal element (内容あり要素検索)
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_one)

        @sbuf = String.new('')

        @pattern_two = Meteor::Core::Util::PatternCache.get(@pattern_cc_two)
        @pattern_oneb = Meteor::Core::Util::PatternCache.get(@pattern_cc_oneb)

        @cnt = 0

        create_element_pattern

        @pattern_cc = @sbuf
      end

      private :element_pattern_normal_three_two

      def element_void_three(name)
        element_void_three_one(name, '"[^<>]*)\\/>')
      end

      private :element_void_three

      def element_void_three_one(name, closer)
        # element (要素)
        @elm_ = Meteor::Element.new(name)
        # attribute (属性)
        @elm_.attributes = @res[1]
        # document (全体)
        @elm_.document = @res[0]
        # pattern (空要素検索用パターン)
        @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}#{closer}"
        @elm_.pattern = @pattern_cc
        @elm_.parser = self

        @elm_
      end

      private :element_void_three_one

      #
      # get element using attribute(name="value") (属性(属性名="属性値")で検索し、要素を取得する)
      # @param [String] attr_name attribute name (属性名)
      # @param [String] attr_value attribute value (属性値)
      # @return [Meteor::Element] element (要素)
      #
      def element_two(attr_name, attr_value) # rubocop:disable Metrics/MethodLength
        quote_attribute(attr_name, attr_value)

        element_pattern_two

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        if @res
          element_three(@res[1], attr_name, attr_value)
        else
          puts(Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message) if @error_check

          @elm_ = nil
        end

        #         @pattern_cc_one = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)\\/>|<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(\\3[^<>]*>)).)*)<\\/\\3>" # rubocop:disable Layout/LineLength
        #
        #         @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_one)
        #         @res1 = @pattern.match(@root.document)
        #
        #         if @res1 && @res1[1] || !@res1
        #           @res2 = element_normal_two_two
        #           @pattern_cc_two = @pattern_cc
        #
        #           # puts @res2.captures.length
        #           # puts @res2.regexp.to_s
        #         end
        #
        #         if @res1 && @res2
        #           if @res1.begin(0) < @res2.begin(0)
        #             @res = @res1
        #             # @pattern_cc = @pattern_cc_one
        #             if @res[1]
        #               element_void_two
        #             else
        #               element_normal_two_one
        #             end
        #           elsif @res1.begin(0) > @res2.begin(0)
        #             @res = @res2
        #             # @pattern_cc = @pattern_cc_two
        #             element_normal_two_one
        #           end
        #         elsif @res1 && !@res2
        #           @res = @res1
        #           # @pattern_cc = @pattern_cc_one
        #           if @res[1]
        #             element_void_two
        #           else
        #             element_normal_two_one
        #           end
        #         elsif @res2 && !@res1
        #           @res = @res2
        #           # @pattern_cc = @pattern_cc_two
        #           element_normal_two_one
        #         else
        #           if @error_check
        #             puts Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message
        #           end
        #           @elm_ = nil
        #         end

        @elm_
      end

      private :element_two

      def quote_name(name)
        @_name = Regexp.quote(name)
      end

      private :quote_name

      def quote_attribute(attr_name, attr_value)
        @_attr_name = Regexp.quote(attr_name)
        @_attr_value = Regexp.quote(attr_value)
      end

      private :quote_attribute

      def element_pattern_two
        ## @pattern_cc = String.new('') << '<([^<>"]*)\\s[^<>]*'
        ##  << @_attr_name << '="' << @_attr_value << '(?:[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\""
      end

      private :element_pattern_two

      #       def element_normal_two_one
      #         # puts @res.captures.length
      #         case @res.captures.length
      #           when FOUR
      #             @_name = @res[1]
      #             # eleement (要素)
      #             @elm_ = Element.new(@_name)
      #             # attribute (属性)
      #             @elm_.attributes = @res[2]
      #             # content (内容)
      #             @elm_.mixed_content = @res[3]
      #             # document (全体)
      #             @elm_.document = @res[0]
      #             # pattern (内容あり要素検索用パターン)
      #             @ pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>" # rubocop:disable Layout/LineLength
      #
      #             @elm_.pattern = @pattern_cc
      #             @elm_.normal = true
      #             @elm_.parser = self
      #           when FIVE,SEVEN
      #             @_name = @res[3]
      #             # element (要素)
      #             @elm_ = Element.new(@_name)
      #             # attribute (属性)
      #             @elm_.attributes = @res[4]
      #             # content (内容)
      #             @elm_.mixed_content = @res[5]
      #             # document (全体)
      #             @elm_.document = @res[0]
      #             # pattern (内容あり要素検索用パターン)
      #             @pattern_cc = "<#{@_name}\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>((?!(#{@_name}[^<>]*>)).)*<\\/#{@_name}>" # rubocop:disable Layout/LineLength
      #
      #             @elm_.pattern = @pattern_cc
      #             @elm_.normal = true
      #             @elm_.parser = self
      #           when THREE,SIX
      #             # puts @res[1]
      #             # puts @res[3]
      #             # @_name = @res[1]
      #             # element (要素)
      #             @elm_ = Element.new(@_name)
      #             # attribute (属性)
      #             @elm_.attributes = @res[1].chop
      #             # content (内容)
      #             @elm_.mixed_content = @res[3]
      #             # document (全体)
      #             @elm_.document = @res[0]
      #             # pattern (内容あり要素検索用パターン)
      #             @elm_.pattern = @pattern_cc
      #
      #             @elm_.normal = true
      #             @elm_.parser = self
      #         end
      #         @elm_
      #       end
      #
      #       private :element_normal_two_one
      #
      #       def element_normal_two_two
      #         @pattern_cc_one = "<([^<>\"]*)(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}(?:[^<>\\/]*>|(?:(?!([^<>]*\\/>))[^<>]*>)))" # rubocop:disable Layout/LineLength
      #
      #         # search of normal element (内容あり要素検索)
      #         @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_one)
      #         @sbuf = String.new('')
      #
      #         @cnt = 0
      #
      #         create_element_pattern_two(2)
      #
      #         @pattern_cc = @sbuf
      #
      #         if @sbuf.length == ZERO || @cnt != ZERO
      #           return nil
      #         end
      #
      #         @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
      #         @res = @pattern.match(@root.document)
      #       end
      #
      #       private :element_normal_two_two
      #
      #       def create_pattern_two(args_cnt)
      #         @pattern_cc_oneb = String.new('') << "<" << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      #
      #         @pattern_cc_one_one = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))(" # rubocop:disable Layout/LineLength
      #         @pattern_cc_one_two = String.new('') << '.*?<' << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
      #         @pattern_cc_two = String.new('') << '<\\/' << @_name << '>'
      #         @pattern_cc_two_one = String.new('') << '.*?<\/' << @_name << '>'
      #         @pattern_cc_two_two = String.new('') << '.*?)<\/' << @_name << '>'
      #
      #         @pattern_two = Meteor::Core::Util::PatternCache.get(@pattern_cc_two)
      #         @pattern_oneb = Meteor::Core::Util::PatternCache.get(@pattern_cc_oneb)
      #       end
      #
      #       def element_void_two
      #         element_void_two_one('"[^<>]*\\/>')
      #       end
      #
      #       private :element_void_two
      #
      #       def element_void_two_one(closer)
      #         # element (要素)
      #         @elm_ = Element.new(@res[1])
      #         # attribute (属性)
      #         @elm_.attributes = @res[2]
      #         # document (全体)
      #         @elm_.document = @res[0]
      #         # void element search pattern (空要素検索用パターン)
      #         @pattern_cc = String.new('') << "<" << @_name << '\\s[^<>]*' << @_attr_name << '="' << @_attr_value << closer # rubocop:disable Layout/LineLength
      #         @elm_.pattern = @pattern_cc
      #         @elm_.parser = self
      #
      #         @elm_
      #       end
      #
      #       private :element_void_two_one

      #
      # get element using tag name and attribute1,2(name="value") (要素のタグ名と属性1・属性2(属性名="属性値")で検索し、要素を取得する)
      # @param [String] name tag name (タグ名)
      # @param [String] attr_name1 attribute name1 (属性名1)
      # @param [String] attr_value1 attribute value1 (属性値1)
      # @param [String] attr_name2 attribute name2 (属性名2)
      # @param [String] attr_value2 attribute value2 (属性値2)
      # @return [Meteor::Element] element (要素)
      #
      def element_five(name, attr_name1, attr_value1, attr_name2, attr_value2) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        quote_element_five(name, attr_name1, attr_value1, attr_name2, attr_value2)

        @pattern_cc_one = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)\\/>|<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_one)
        @res1 = @pattern.match(@root.document)

        if @res1 && @res1[1] || !@res1
          @res2 = element_normal_five_two
          @pattern_cc_two = @pattern_cc

          # puts @res2.captures.length
          # puts @res2.regexp.to_s
        end

        if @res1 && @res2
          if @res1.begin(0) < @res2.begin(0)
            @res = @res1
            # @pattern_cc = @pattern_cc_one
            if @res[1]
              element_void_five(name)
            else
              element_normal_five_one(name)
            end
          elsif @res1.begin(0) > @res2.begin(0)
            @res = @res2
            # @pattern_cc = @pattern_cc_two
            element_normal_five_one(name)
          end
        elsif @res1 && !@res2
          @res = @res1
          # @pattern_cc = @pattern_cc_one
          if @res[1]
            element_void_five(name)
          else
            element_normal_five_one(name)
          end
        elsif @res2 && !@res1
          @res = @res2
          # @pattern_cc = @pattern_cc_two
          element_normal_five_one(name)
        else
          puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message) if @error_check

          @elm_ = nil
        end

        @elm_
      end

      private :element_five

      def quote_element_five(name, attr_name1, attr_value1, attr_name2, attr_value2)
        quote_name(name)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)
      end

      private :quote_element_five

      def element_normal_five_one(name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
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
          @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength

          @elm_.pattern = @pattern_cc
          @elm_.normal = true
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
          @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength

          @elm_.pattern = @pattern_cc
          @elm_.normal = true
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
          # normal element search pattern (要素ありタグ検索用パターン)
          @elm_.pattern = @pattern_cc

          @elm_.normal = true
          @elm_.parser = self
        end

        @elm_
      end

      private :element_normal_five_one

      def element_normal_five_two
        element_pattern_normal_five_two

        return nil if @sbuf.length == ZERO || @cnt != ZERO

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        @res
      end

      private :element_normal_five_two

      def element_pattern_normal_five_two # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @pattern_cc_one = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")([^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>)))" # rubocop:disable Layout/LineLength
        @pattern_cc_oneb = String.new('') << '<' << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        # @pattern_cc_oneb = "<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"

        @pattern_cc_one_one = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")(?:[^<>\\/]*>|(?!([^<>]*\\/>))[^<>]*>))(" # rubocop:disable Layout/LineLength
        @pattern_cc_one_two = String.new('') << '.*?<' << @_name << '(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))'
        @pattern_cc_two = String.new('') << '<\\/' << @_name << '>'
        @pattern_cc_two_one = String.new('') << '.*?<\\/' << @_name << '>'
        @pattern_cc_two_two = String.new('') << '.*?)<\\/' << @_name << '>'

        # @pattern_cc_one_two = ".*?<#{@_name}(\\s[^<>\\/]*>|((?!([^<>]*\\/>))[^<>]*>))"
        # @pattern_cc_two = String.new('') << "<\\/#{@_name}>"
        # @pattern_cc_two_one = ".*?<\\/#{@_name}>"
        # @pattern_cc_two_two = ".*?)<\\/#{@_name}>"

        # search of normal element (内容あり要素検索)
        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc_one)

        @sbuf = String.new('')

        @pattern_two = Meteor::Core::Util::PatternCache.get(@pattern_cc_two)
        @pattern_oneb = Meteor::Core::Util::PatternCache.get(@pattern_cc_oneb)
        @cnt = 0

        create_element_pattern
        @pattern_cc = @sbuf
      end

      private :element_pattern_normal_five_two

      def element_void_five(name)
        element_void_five_one(name, '")[^<>]*)\\/>')
      end

      private :element_void_five

      def element_void_five_one(name, closer)
        # element (要素)
        @elm_ = Meteor::Element.new(name)
        # attribute (属性)
        @elm_.attributes = @res[1]
        # document (全体)
        @elm_.document = @res[0]
        # pattern (空要素検索用パターン)
        @pattern_cc = "<#{@_name}(\\s[^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}#{closer}" # rubocop:disable Layout/LineLength
        @elm_.pattern = @pattern_cc
        @elm_.parser = self

        @elm_
      end

      private :element_void_five_one

      #
      # get element using attribute1,2(name="value") (属性1・属性2(属性名="属性値")で検索し、要素を取得する)
      # @param [String] attr_name1 attribute name1 (属性名1)
      # @param [String] attr_value1 attribute value1 (属性値1)
      # @param [String] attr_name2 attribute name2 (属性名2)
      # @param [String]attr_value2 attribute value2 (属性値2)
      # @return [Meteor::Element] element (要素)
      #
      def element_four(attr_name1, attr_value1, attr_name2, attr_value2) # rubocop:disable Metrics/MethodLength
        quote_element_four(attr_name1, attr_value1, attr_name2, attr_value2)

        element_pattern_four

        @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
        @res = @pattern.match(@root.document)

        if @res
          # @elm_ = element_five(@res[1], attr_name1, attr_value1,attr_name2, attr_value2)
          element_five(@res[1], attr_name1, attr_value1, attr_name2, attr_value2)
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

      private :element_four

      def quote_element_four(attr_name1, attr_value1, attr_name2, attr_value2)
        @_attr_name1 = Regexp.quote(attr_name1)
        @_attr_name2 = Regexp.quote(attr_name2)
        @_attr_value1 = Regexp.quote(attr_value1)
        @_attr_value2 = Regexp.quote(attr_value2)
      end

      private :quote_element_four

      def element_pattern_four
        @pattern_cc = "<([^<>\"]*)\\s[^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")" # rubocop:disable Layout/LineLength
      end

      private :element_pattern_four

      def create_element_pattern # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        @position = 0

        while (@res = @pattern.match(@root.document, @position)) || @cnt > ZERO
          if @res
            if @cnt > ZERO
              @position2 = @res.end(0)
              @res = @pattern_two.match(@root.document, @position)

              if @res # rubocop:disable Metrics/BlockNesting
                @position = @res.end(0)

                if @position > @position2 # rubocop:disable Metrics/BlockNesting
                  @sbuf << @pattern_cc_one_two
                  @cnt += 1
                  @position = @position2
                else
                  @cnt -= ONE

                  if @cnt != ZERO # rubocop:disable Metrics/BlockNesting
                    @sbuf << @pattern_cc_two_one
                  else
                    @sbuf << @pattern_cc_two_two
                    break
                  end
                end
              else
                @sbuf << @pattern_cc_one_two
                @cnt += 1
                @position = @position2
              end
            else
              @position = @res.end(0)
              @sbuf << @pattern_cc_one_one
              @cnt += ONE
            end
          else
            break if @cnt == ZERO

            @res = @pattern_two.match(@root.document, @position)

            break unless @res

            @cnt -= ONE

            if @cnt != ZERO
              @sbuf << @pattern_cc_two_one
            else
              @sbuf << @pattern_cc_two_two
              break
            end

            @position = @res.end(0)
          end

          @pattern = @pattern_oneb
        end
      end

      private :create_element_pattern

      #       def create_element_pattern_two(args_cnt)
      #         @position = 0
      #
      #         while (@res = @pattern.match(@root.document, @position)) || @cnt > ZERO
      #           if @res
      #             if @cnt > ZERO
      #               @position2 = @res.end(0)
      #               @res = @pattern_two.match(@root.document, @position)
      #
      #               if @res
      #                 @position = @res.end(0)
      #
      #                 if @position > @position2
      #                   @sbuf << @pattern_cc_one_two
      #                   @cnt += 1
      #                   @position = @position2
      #                 else
      #                   @cnt -= ONE
      #
      #                   if @cnt != ZERO
      #                     @sbuf << @pattern_cc_two_one
      #                   else
      #                     @sbuf << @pattern_cc_two_two
      #                     break
      #                   end
      #                 end
      #               else
      #                 @sbuf << @pattern_cc_one_two
      #                 @cnt += 1
      #                 @position = @position2
      #               end
      #             else
      #               @position = @res.end(0)
      #               @_name = @res[1]
      #
      #               create_pattern_two(args_cnt)
      #
      #               @sbuf << @pattern_cc_one_one
      #               @cnt += ONE
      #             end
      #           else
      #             if @cnt == ZERO
      #               break
      #             end
      #
      #             @res = @pattern_two.match(@root.document, @position)
      #
      #             if @res
      #               @cnt -= ONE
      #
      #               if @cnt != ZERO
      #                 @sbuf << @pattern_cc_two_one
      #               else
      #                 @sbuf << @pattern_cc_two_two
      #                 break
      #               end
      #
      #               @position = @res.end(0)
      #             else
      #               break
      #             end
      #           end
      #
      #           @pattern = @pattern_oneb
      #         end
      #       end
      #
      #       private :create_element_pattern_two
      #
      #       # def create_pattern_two
      #       # end
      #
      #       # private :create_pattern_two

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
      def elements(elm, attrs = nil, *args) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        if !attrs
          if elm.is_a?(String)
            elements_(elm)
          elsif elm.is_a?(Hash)
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
        elsif attrs.is_a?(Hash)
          if attrs.size == ONE
            elements_(elm, attrs.keys[0], attrs.values[0])
          elsif attrs.size == TWO
            elements_(elm, attrs.keys[0], attrs.values[0], attrs.keys[1], attrs.values[1])
          else
            @elm_ = nil
            raise ArgumentError
          end
        elsif attrs.is_a?(String)
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

      def elements_(*args) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        elm_arr = []

        @on_search = true

        case args.size
        when ONE
          @elm_ = element_one(*args)
        when TWO
          @elm_ = element_two(*args)
        when THREE
          @elm_ = element_three(*args)
        when FOUR
          @elm_ = element_four(*args)
        when FIVE
          @elm_ = element_five(*args)
        end

        return elm_arr unless @elm_

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
            if @elm_.normal
              element_normal_one(@elm_.name)
            else
              element_void_one(@elm_.name)
            end

          when TWO, THREE
            if @elm_.normal
              element_normal_three_one(@elm_.name)
            else
              element_void_three(@elm_.name)
            end

          when FOUR, FIVE
            if @elm_.normal
              element_normal_five_one(@elm_.name)
            else
              element_void_five(@elm_.name)
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
      def find(selector) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        open_count = selector.count('[')

        case open_count
        when ZERO
          if selector.count('#.').zero?
            elements_(@res[1]) if (@res = RE_FIND_ONE.match(selector))
          elsif selector.count('#') == 1
            if selector[0] == '#'
              elements_('id', @res[1]) if (@res = RE_FIND_TWO_ONE.match(selector))
            elsif (@res = RE_FIND_THREE_TWO.match(selector))
              elements_(@res[1], 'id', @res[2])
            end
          elsif selector.count('.') == 1
            if selector[0] == '.'
              elements_('class', @res[1]) if (@res = RE_FIND_TWO_TWO.match(selector))
            elsif (@res = RE_FIND_THREE_THREE.match(selector))
              elements_(@res[1], 'class', @res[2])
            end
          end

        when ONE
          if selector[0] == '['
            elements_(@res[1], @res[2]) if (@res = RE_FIND_TWO_THREE.match(selector))
          elsif (@res = RE_FIND_THREE_ONE.match(selector))
            elements_(@res[1], @res[2], @res[3])
          end
        when 2
          if selector[0] == '['
            elements_(@res[1], @res[2], @res[3], @res[4]) if (@res = RE_FIND_FOUR.match(selector))
          elsif (@res = RE_FIND_FIVE.match(selector))
            elements_(@res[1], @res[2], @res[3], @res[4], @res[5])
          end
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
      def attr(elm, attr, *args) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        if attr.is_a?(String) || attr.is_a?(Symbol)
          case args.length
          when ZERO
            get_attr_value(elm, attr.to_s)
          when ONE
            if !args[0].nil?
              elm.document_sync = true
              set_attribute_three(elm, attr.to_s, args[0])
            else
              remove_attr(elm, attr.to_s)
            end
          end
        elsif attr.is_a?(Hash) && attr.size == 1
          if !attr.values[0].nil?
            elm.document_sync = true
            set_attribute_three(elm, attr.keys[0].to_s, attr.values[0])
          else
            remove_attr(elm, attr.keys[0].to_s)
          end
          # elsif attrs.is_a?(Hash) && attrs.size >= 1
          #  elm.document_sync = true
          #  attrs.each{|name,value|
          #    set_attribute_three(elm,name,value)
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
      def set_attribute_three(elm, attr_name, attr_value)
        unless elm.cx
          attr_value = escape(attr_value.to_s)
          # update attributes (属性群の更新)
          edit_attrs_(elm, attr_name, attr_value)
        end

        elm
      end

      private :set_attribute_three

      def edit_attrs_(elm, attr_name, attr_value) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        # attribute search (属性検索)
        # @res = @pattern.match(elm.attributes)

        # Attribute existence check (属性の存在判定)
        @_attr_value = attr_value
        if elm.attributes.include?(String.new(' ') << attr_name << '="')

          # replace attribute (属性の置換)
          @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << '="[^"]*"')
          # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"")

          # elm.attributes.sub!(@pattern, "#{attr_name}=\"#{@_attr_value}\"")
          elm.attributes.sub!(@pattern, String.new('') << attr_name << '="' << @_attr_value << '"')
        else
          # add an attribute to attrubutes (属性文字列の最後に新規の属性を追加する)

          elm.attributes = if elm.attributes != '' && elm.attributes.strip != ''
                             String.new('') << ' ' << elm.attributes.strip
                           else
                             String.new('')
                           end

          elm.attributes << ' ' << attr_name << '="' << @_attr_value << '"'
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
        @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << '="([^"]*)"')
        # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"([^\"]*)\"")

        @res = @pattern.match(elm.attributes)

        return unless @res

        unescape(@res[1])
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
      def attrs(elm, *args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        case args.length
        when ZERO
          get_attrs(elm)
        when ONE
          raise ArgumentError unless args[0].is_a?(Hash)

          if args[0].size == 1
            elm.document_sync = true
            set_attribute_three(elm, args[0].keys[0].to_s, args[0].values[0])
          elsif args[0].size >= 1
            set_attrs(elm, args[0])
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
        attrs = {}

        elm.attributes.scan(RE_GET_ATTRS_MAP) do |a, b|
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
        unless elm.cx
          elm.document_sync = true
          attr_map.each do |name, value|
            set_attribute_three(elm, name.to_s, value)
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
          # if elm.is_a?(Meteor::Element) && args[0].is_a?(Meteor::AttributeMap)
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

        elm.attributes.scan(RE_GET_ATTRS_MAP) do |a, b|
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
        unless elm.cx
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
      def content(*args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        case args.length
        when ONE
          # if args[0].is_a?(Meteor::Element)
          get_content_one(args[0])
          # else
          #  raise ArgumentError
          # end
        when TWO
          # if args[0].is_a?(Meteor::Element) && args[1].is_a?(String)
          args[0].document_sync = true
          set_content_two(args[0], args[1].to_s)
          # else
          #  raise ArgumentError
          # end
        when THREE
          args[0].document_sync = true
          set_content_three(args[0], args[1].to_s, args[2])
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
      def set_content_three(elm, content, entity_ref = true) # rubocop:disable Style/OptionalBooleanParameter
        escape_content(content, elm) if entity_ref || !elm.raw_content

        elm.mixed_content = content
        elm
      end

      private :set_content_three

      #
      # set content of element (要素の内容をセットする)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] content content of element (要素の内容)
      # @return [Meteor::Element] element (要素)
      #
      def set_content_two(elm, content)
        # set_content_three(elm, content)
        escape_content(content, elm) unless elm.raw_content

        elm.mixed_content = content
        elm
      end

      private :set_content_two

      #
      # get content of element (要素の内容を取得する)
      # @param [Meteor::Element] elm element (要素)
      # @return [String] content (内容)
      #
      def get_content_one(elm)
        if !elm.cx
          unescape_content(elm.mixed_content, elm) if elm.normal
        else
          unescape_content(elm.mixed_content, elm)
        end
      end

      private :get_content_one

      #
      # remove attribute of element (要素の属性を消す)
      # @param [Meteor::Element] elm element (要素)
      # @param [String] attr_name attribute name (属性名)
      # @return [Meteor::Element] element (要素)
      #
      def remove_attr(elm, attr_name)
        unless elm.cx
          elm.document_sync = true
          remove_attrs_(elm, attr_name.to_s)
        end

        elm
      end

      def remove_attrs_(elm, attr_name)
        # attribute search pattern (属性検索用パターン)
        @pattern = Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << '="[^"]*"\\s?')
        # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"\\s?")
        # replace attrubute (属性の置換)
        elm.attributes.sub!(@pattern, '')
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
          cxtag_one(args[0].to_s)
          @element_cache.store(@elm_.object_id, @elm_) if @elm_
        when TWO
          cxtag_two(args[0].to_s, args[1].to_s)
          @element_cache.store(@elm_.object_id, @elm_) if @elm_
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
      def cxtag_two(name, id) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        quote_name(name)
        @_id = Regexp.quote(id)

        # CX tag search pattern (CXタグ検索用パターン)
        # @pattern_cc = "<!--\\s@#{@_name}\\s([^<>]*id=\"#{@_id}\"[^<>]*)-->(((?!(<!--\\s\\/@#{@_name})).)*)<!--\\s\\/@#{@_name}\\s-->" # rubocop:disable Layout/LineLength
        @pattern_cc = "<!--\\s@#{@_name}\\s([^<>]*id=\"#{@_id}\"[^<>]*)-->(((?!(<!--\\s/@#{@_name})).)*)<!--\\s/@#{@_name}\\s-->" # rubocop:disable Layout/LineLength

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

          @elm_.normal = true

          @elm_.parser = self
        else
          @elm_ = nil
        end

        @elm_
      end

      private :cxtag_two

      #
      # get cx(comment extension) tag using id attribute (ID属性(id="ID属性値")で検索し、CX(コメント拡張)タグを取得する)
      # @param [String] id id attribute value (ID属性値)
      # @return [Meteor::Element] element (要素)
      #
      def cxtag_one(id)
        @_id = Regexp.quote(id)

        @pattern_cc = String.new('') << '<!--\\s@([^<>]*)\\s[^<>]*id="' << @_id << '"'
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

      private :cxtag_one

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

      def reflect # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        # puts @element_cache.size.to_s
        @element_cache.each_value do |item|
          next unless item.usable

          # puts "#{item.name}:#{item.document}"
          if !item.removed
            if item.copy
              @pattern = Meteor::Core::Util::PatternCache.get(item.pattern)
              @root.document.sub!(@pattern, item.copy.parser.document_hook)
              # item.copy.parser.element_cache.clear
              item.copy = nil
            else
              edit_document_one(item)
              # edit_pattern_(item)
            end
          else
            replace(item, '')
          end

          item.usable = false
        end
      end

      protected :reflect

      def edit_document_one(elm)
        edit_document_two(elm, '/>')
      end

      private :edit_document_one

      def edit_document_two(elm, _closer)
        # replace tag (タグ置換)
        @pattern = Meteor::Core::Util::PatternCache.get(elm.pattern)
        @root.document.sub!(@pattern, elm.document)
      end

      private :edit_document_two

      #
      # reflect (反映する)
      #
      def flash # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity
        if element_hook
          if element_hook.origin.childless
            if element_hook.origin.cx
              document_hook <<
                "<!-- @#{element_hook.name} #{element_hook.attributes}-->#{element_hook.mixed_content}<!-- /@#{element_hook.name} -->" # rubocop:disable Layout/LineLength

              # self.document_hook << @root.newline <<
              # "<!-- @#{self.element_hook.name} #{self.element_hook.attributes}-->#{self.element_hook.mixed_content}<!-- /@#{self.element_hook.name} -->" # rubocop:disable Layout/LineLength
            else
              document_hook <<
                "<#{element_hook.name}#{element_hook.attributes}>#{element_hook.mixed_content}</#{element_hook.name}>"

              # self.document_hook << @root.newline <<
              # "<#{self.element_hook.name}#{self.element_hook.attributes}>#{self.element_hook.mixed_content}</#{self.element_hook.name}>" # rubocop:disable Layout/LineLength
            end

          else
            reflect
            @_attributes = element_hook.attributes

            if element_hook.origin.cx
              document_hook <<
                "<!-- @#{element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{element_hook.name} -->"

              # self.document_hook << @root.newline << "<!-- @#{element_hook.name} #{@_attributes}-->#{@root.document}<!-- /@#{element_hook.name} -->" # rubocop:disable Layout/LineLength
            else
              document_hook <<
                "<#{element_hook.name}#{@_attributes}>#{@root.document}</#{element_hook.name}>"

              # document_hook << @root.newline << "<#{element_hook.name}#{@_attributes}>#{@root.document}</#{element_hook.name}>" # rubocop:disable Layout/LineLength
            end

          end
          self.element_hook = element_hook.origin.clone(self)
        else
          reflect
          @element_cache.clear
          clean
        end
      end

      def clean
        # replace CX start tag (CX開始タグ置換)
        @pattern = RE_CLEAN_ONE
        @root.document.gsub!(@pattern, '')
        # rplace CX end tag (CX終了タグ置換)
        @pattern = RE_CLEAN_TWO
        @root.document.gsub!(@pattern, '')
        # @root.document << "<!-- Powered by Meteor (C)Yasumasa Ashida -->"
      end

      private :clean

      #
      # mirror element (要素を射影する)
      #
      # @param [Meteor::Element] elm element (要素)
      # @return [Meteor::Element] element (要素)
      #
      def shadow(elm) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        return unless elm.normal

        # case of normal element (内容あり要素の場合)
        self.childless = elm

        pif2 = self.class.new(self)

        @elm_ = elm.clone(pif2)

        pif2.root_element.document = if !elm.childless
                                       String.new(elm.mixed_content)
                                     else
                                       String.new(elm.document)
                                     end

        pif2.root_element.newline = elm.parser.root_element.newline

        @elm_
      end

      # private :shadow

      def childless=(elm)
        @res = RE_CHILDLESS.match(elm.mixed_content)

        elm.childless = true if @res
      end

      private :childless=

      def match?(regex, str)
        case regex
        when Regexp
          match_r?(regex, str)
        when Array
          match_a?(regex, str)
        when String
          match_s?(regex, str)
        else
          raise ArgumentError
        end
      end

      private :match?

      def match_r?(regex, str)
        if regex.match(str.downcase)
          true
        else
          false
        end
      end

      private :match_r?

      def match_a?(regex, str)
        str = str.downcase
        regex.each do |item|
          return true if item == str
        end

        false
      end

      private :match_a?

      def match_s?(regex, str)
        regex == str.downcase
      end

      private :match_s?

      def escape(content)
        # replace special character (特殊文字の置換)
        content.gsub(RE_ESCAPE, TABLE_FOR_ESCAPE_)
      end

      def escape_content(content, _elm)
        # replace special character (特殊文字の置換)
        content.gsub(RE_ESCAPE_CONTENT, TABLE_FOR_ESCAPE_CONTENT_)
      end

      private :escape
      private :escape_content

      def unescape(content) # rubocop:disable Metrics/MethodLength
        # replace special character (特殊文字の置換)
        # 「<」<-「&lt;」
        # 「>」<-「&gt;」
        # 「"」<-「&quotl」
        # 「 」<-「&nbsp;」
        # 「&」<-「&amp;」
        content.gsub(RE_UNESCAPE) do
          case ::Regexp.last_match(1) # rubocop:disable Style/HashLikeCase
          when 'amp'
            '&'
          when 'quot'
            '"'
          when 'apos'
            "'"
          when 'gt'
            '>'
          when 'lt'
            '<'
          when 'nbsp'
            ' '
          end
        end

        content
      end

      private :unescape

      def br_to_newline(content)
        return unless (elm.cx || !match?(MATCH_TAG_TWO, elm.name)) && content.include?(BR)

        # 「<br>」->「¥r?¥n」
        content.gsub!(RE_BR_TWO, @root.newline)
      end

      private :br_to_newline

      def unescape_content(content, _elm)
        content_ = unescape(content)

        br_to_newline(content_)

        content_
      end

      private :unescape_content
    end
  end
end
