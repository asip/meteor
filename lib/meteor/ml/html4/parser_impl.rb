# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Html4
      #
      # HTML4 parser (HTMLパーサ)
      #
      class ParserImpl < Meteor::Core::Kernel # rubocop:disable Metrics/ClassLength
        BR = '<br>'
        BR_RE = BR

        # MATCH_TAG = "br|hr|img|input|meta|base"

        # [Array] void elemets (空要素)
        MATCH_TAG = %w[br hr img input meta base].freeze

        # MATCH_TAG_TWO = "textarea|option|pre"

        # [Array] elements where line breaks do not need to be converted to <br> (改行を<br>に変換する必要のない要素)
        MATCH_TAG_TWO = %w[textarea option pre].freeze

        # [Array] non-nestable elements (入れ子にできない要素)
        MATCH_TAG_NNE = %w[texarea select option form fieldset].freeze

        # [Array] boolean attributes (論理値で指定する属性)
        ATTR_BOOL = %w[disabled readonly checked selected multiple].freeze

        # DISABLE_ELEMENT = "input|textarea|select|optgroup"

        # [Array] elements with the disabled attribute (disabled属性のある要素)
        DISABLE_ELEMENT = %w[input textarea select optgroup].freeze

        # READONLY_TYPE = "text|password"

        # [Array] the type of an input element with a readonly attribute (readonly属性のあるinput要素のタイプ)
        READONLY_TYPE = %w[text password].freeze

        SELECTED_M = '\\sselected\\s|\\sselected$|\\sSELECTED\\s|\\sSELECTED$'
        # SELECTED_M = [' selected ',' selected',' SELECTED ',' SELECTED']
        SELECTED_R = 'selected\\s|selected$|SELECTED\\s|SELECTED$'
        CHECKED_M = '\\schecked\\s|\\schecked$|\\sCHECKED\\s|\\sCHECKED$'
        # CHECKED_M = [' checked ',' checked',' CHECKED ',' CHECKED']
        CHECKED_R = 'checked\\s|checked$|CHECKED\\s|CHECKED$'
        DISABLED_M = '\\sdisabled\\s|\\sdisabled$|\\sDISABLED\\s|\\sDISABLED$'
        # DISABLED_M = [' disabled ',' disiabled',' DISABLED ',' DISABLED']
        DISABLED_R = 'disabled\\s|disabled$|DISABLED\\s|DISABLED$'
        READONLY_M = '\\sreadonly\\s|\\sreadonly$|\\sREADONLY\\s|\\sREADONLY$'
        # READONLY_M = [' readonly ',' readonly',' READONLY ',' READONLY']
        READONLY_R = 'readonly\\s|readonly$|READONLY\\s|READONLY$'
        MULTIPLE_M = '\\smultiple\\s|\\smultiple$|\\sMULTIPLE\\s|\\sMULTIPLE$'
        # MULTIPLE_M = [' multiple ',' multiple',' MULTIPLE ',' MULTIPLE']
        MULTIPLE_R = 'multiple\\s|multiple$|MULTIPLE\\s|MULTIPLE$'

        # RE_TRUE = Regexp.new("true")
        # RE_FALSE = Regexp.new("false")

        GET_ATTRS_MAP2 = '\\s(disabled|readonly|checked|selected|multiple)'

        RE_SELECTED_M = Regexp.new(SELECTED_M)
        RE_SELECTED_R = Regexp.new(SELECTED_R)
        RE_CHECKED_M = Regexp.new(CHECKED_M)
        RE_CHECKED_R = Regexp.new(CHECKED_R)
        RE_DISABLED_M = Regexp.new(DISABLED_M)
        RE_DISABLED_R = Regexp.new(DISABLED_R)
        RE_READONLY_M = Regexp.new(READONLY_M)
        RE_READONLY_R = Regexp.new(READONLY_R)
        RE_MULTIPLE_M = Regexp.new(MULTIPLE_M)
        RE_MULTIPLE_R = Regexp.new(MULTIPLE_R)
        RE_GET_ATTRS_MAP2 = Regexp.new(GET_ATTRS_MAP2)

        # RE_MATCH_TAG = Regexp.new(MATCH_TAG)
        # RE_MATCH_TAG_TWO = Regexp.new(MATCH_TAG_TWO)

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
            # initialize_zero
          when ONE
            initialize_one(args[0])
          else
            raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        # def initialize_zero
        # end
        #
        # private :initialize_zero

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize_one(ps) # rubocop:disable Naming/MethodParameterName
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.charset = ps.root_element.charset
          @root.newline = ps.root_element.newline
        end

        private :initialize_one

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml
          super
          analyze_content_type
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
        def analyze_content_type # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          @error_check = false

          element_three('meta', 'http-equiv', 'Content-Type')

          @error_check = true

          if @elm_
            content = @elm_.attr('content')
            content_arr = content&.split(';')
            @root.content_type = content_arr&.at(0) || ''
            @root.charset = content_arr&.at(1)&.split('=')&.at(1) || ''
          else
            @root.content_type = ''
          end
        end

        protected :analyze_content_type

        #
        # get element using tag name (要素のタグ名で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @return [Meteor::Element] element (要素)
        #
        def element_one(name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity
          quote_name(name)

          # case of void element (空要素の場合(<->内容あり要素の場合))
          if match?(MATCH_TAG, name)
            # void element search pattern (空要素検索用パターン)
            @pattern_cc = String.new('') << '<' << @_name << '(|\\s[^<>]*)>'
            # @pattern_cc = "<#{@_name}(|\\s[^<>]*)>"
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            @res = @pattern.match(@root.document)
            if @res
              element_void_one(name)
            else
              puts(Meteor::Exception::NoSuchElementException.new(name).message) if @error_check

              @elm_ = nil
            end
          else
            # normal element search pattern (内容あり要素検索用パターン()
            @pattern_cc = "<#{@_name}(|\\s[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # search of normal element (内容あり要素検索)
            @res = @pattern.match(@root.document)
            # case of normal element (内容あり要素の場合)
            if @res
              @on_search = true
              element_normal_one(name)
            else
              puts(Meteor::Exception::NoSuchElementException.new(name).message) if @error_check

              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_one

        def element_void_one(name)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[1]
          # void element search pattern (空要素検索用パターン)
          @elm_.pattern = @pattern_cc

          @elm_.document = @res[0]

          @elm_.parser = self
        end

        private :element_void_one

        #
        # get element using tag name and attribute(name="value") (要素のタグ名、属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @param [true,false] quote quote flag (クオート・フラグ)
        # @return [Meteor::Element] element (要素)
        #
        def element_three(name, attr_name, attr_value, quote = true) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity,Style/OptionalBooleanParameter
          if quote
            quote_element_three(name, attr_name, attr_value)
          else
            quote_name(name)
          end

          # case of void element (空要素の場合(<->内容あり要素の場合))
          if match?(MATCH_TAG, name)
            # void element search pattern (空要素検索パターン)
            @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # void element search (空要素検索)
            @res = @pattern.match(@root.document)
            if @res
              element_void_three(name)
            else
              puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message) if @error_check

              @elm_ = nil
            end
          else
            # normal element search pattern (内容あり要素検索パターン)
            @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # search of normal element (内容あり要素検索)
            @res = @pattern.match(@root.document)

            @res = element_normal_three_two if !@res && !match?(MATCH_TAG_NNE, name)

            if @res
              element_normal_three_one(name)
            else
              puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message) if @error_check

              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_three

        def element_void_three(name)
          element_void_three_one(name, '"[^<>]*)>')
        end

        private :element_void_three

        #
        # get element using attribute(name="value") (属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @return [Meteor::Element] element (要素)
        #
        def element_two(attr_name, attr_value) # rubocop:disable Metrics/MethodLength
          quote_attribute(attr_name, attr_value)

          @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
          @res = @pattern.match(@root.document)

          if @res
            element_three(@res[1], attr_name, attr_value)
          else
            puts(Meteor::Exception::NoSuchElementException.new(attr_name, attr_value).message) if @error_check

            @elm_ = nil
          end

          @elm_
        end

        private :element_two

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

          # case of void element (空要素の場合(<->内容あり要素の場合))
          if match?(MATCH_TAG, name)
            # void element search pattern (空要素検索パターン)
            @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>" # rubocop:disable Layout/LineLength

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # void element search (空要素検索)
            @res = @pattern.match(@root.document)

            if @res
              element_void_five(name)
            else
              if @error_check
                puts(
                  Meteor::Exception::NoSuchElementException
                    .new(name, attr_name1, attr_value1, attr_name2, attr_value2)
                    .message
                )
              end

              @elm_ = nil
            end
          else
            # normal element search pattern (内容あり要素検索パターン)
            @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>" # rubocop:disable Layout/LineLength

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # search of normal element (内容あり要素検索)
            @res = @pattern.match(@root.document)

            @res = element_normal_five_two if !@res && !match?(MATCH_TAG_NNE, name)

            if @res
              element_normal_five_one(name)
            else
              if @error_check
                puts(
                  Meteor::Exception::NoSuchElementException
                    .new(name, attr_name1, attr_value1, attr_name2, attr_value2)
                    .message
                )
              end

              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_five

        def element_void_five(name)
          element_void_five_one(name, '")[^<>]*)>')
        end

        private :element_void_five

        #
        # get element using attribute1,2(name="value") (属性1・属性2(属性名="属性値")で検索し、要素を取得する)
        #
        # @param [String] attr_name1 attribute name1 (属性名1)
        # @param [String] attr_value1 attribute value1 (属性値1)
        # @param [String] attr_name2 attribute name2 (属性名2)
        # @param [String] attr_value2 attribute value2 (属性値2)
        # @return [Meteor::Element] element (要素)
        #
        def element_four(attr_name1, attr_value1, attr_name2, attr_value2) # rubocop:disable Metrics/MethodLength
          quote_element_four(attr_name1, attr_value1, attr_name2, attr_value2)

          @pattern_cc = "<([^<>\"]*)\\s([^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>" # rubocop:disable Layout/LineLength

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

          @res = @pattern.match(@root.document)

          if @res
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

        def edit_attrs_(elm, attr_name, attr_value) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          if match?('selected', attr_name) && match?('option', elm.name)
            edit_attrs_five(elm, attr_name, attr_value, RE_SELECTED_M, RE_SELECTED_R)
          elsif match?('multiple', attr_name) && match?('select', elm.name)
            edit_attrs_five(elm, attr_name, attr_value, RE_MULTIPLE_M, RE_MULTIPLE_R)
          elsif match?('disabled', attr_name) && match?(DISABLE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_name, attr_value, RE_DISABLED_M, RE_DISABLED_R)
          elsif match?('checked', attr_name) && match?('input', elm.name) && match?('radio', get_type(elm))
            edit_attrs_five(elm, attr_name, attr_value, RE_CHECKED_M, RE_CHECKED_R)
          elsif match?('readonly', attr_name) &&
                (match?('textarea',
                        elm.name) || (match?('input', elm.name) && match?(READONLY_TYPE, get_type(elm))))
            edit_attrs_five(elm, attr_name, attr_value, RE_READONLY_M, RE_READONLY_R)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def edit_attrs_five(elm, attr_name, attr_value, match_p, replace) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          if true.equal?(attr_value) || match?('true', attr_value)
            @res = match_p.match(elm.attributes)

            unless @res
              elm.attributes = if elm.attributes != '' && elm.attributes.strip != ''
                                 String.new('') << ' ' << elm.attributes.strip
                               else
                                 String.new('')
                               end

              elm.attributes << ' ' << attr_name
              # else
            end
          elsif false.equal?(attr_value) || match?('false', attr_value)
            elm.attributes.sub!(replace, '')
          end
        end

        private :edit_attrs_five

        def edit_document_one(elm)
          edit_document_two(elm, '>')
        end

        private :edit_document_one

        def get_attr_value_(elm, attr_name) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          if match?('selected', attr_name) && match?('option', elm.name)
            get_attr_value_r(elm, RE_SELECTED_M)
          elsif match?('multiple', attr_name) && match?('select', elm.name)
            get_attr_value_r(elm, RE_MULTIPLE_M)
          elsif match?('disabled', attr_name) && match?(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, RE_DISABLED_M)
          elsif match?('checked', attr_name) && match?('input', elm.name) && match?('radio', get_type(elm))
            get_attr_value_r(elm, RE_CHECKED_M)
          elsif match?('readonly', attr_name) &&
                (match?('textarea',
                        elm.name) || (match?('input', elm.name) && match?(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, RE_READONLY_M)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          unless elm.type_value
            elm.type_value = get_attr_value_(elm, 'type')
            elm.type_value = get_attr_value_(elm, 'TYPE') unless elm.type_value
          end

          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, match_p)
          @res = match_p.match(elm.attributes)

          if @res
            'true'
          else
            'false'
          end
        end

        private :get_attr_value_r

        #
        # get attribute map (属性マップを取得する)
        # @param [Meteor::Element] elm element (要素)
        # @return [Hash] attribute map (属性マップ)
        #
        def get_attrs(elm)
          attrs = {}

          elm.attributes.scan(RE_GET_ATTRS_MAP) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(RE_GET_ATTRS_MAP2) do |a|
            attrs.store(a[0], 'true')
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

          elm.attributes.scan(RE_GET_ATTRS_MAP) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(RE_GET_ATTRS_MAP2) do |a|
            attrs.store(a[0], 'true')
          end

          attrs.recordable = true

          attrs
        end

        private :get_attr_map

        def remove_attrs_(elm, attr_name)
          @pattern = if !match?(ATTR_BOOL, attr_name)
                       # attribute search pattern (属性検索用パターン)
                       Meteor::Core::Util::PatternCache.get(String.new('') << attr_name << '="[^"]*"\\s?')
                     # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"\\s?")
                     else
                       # attribute search pattern (属性検索用パターン)
                       Meteor::Core::Util::PatternCache.get(attr_name)
                     end
          elm.attributes.sub!(@pattern, '')
        end

        private :remove_attrs_
      end
    end
  end
end
