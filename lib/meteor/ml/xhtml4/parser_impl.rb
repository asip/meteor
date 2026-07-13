# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Xhtml4
      #
      # XHTML4 parser (XHTML4パーサ)
      #
      class ParserImpl < Meteor::Core::Kernel # rubocop:disable Metrics/ClassLength
        # NEWLINE = "\r?\n|\r"
        NEWLINE = ["\r\n", "\n", "\r"].freeze
        BR = '<br/>'
        BR_RE = '<br\\/>'

        # MATCH_TAG_TWO = "textarea|option|pre"
        # [Array] elements where line breaks do not need to be converted to <br> (改行を<br/>に変換する必要のない要素)
        MATCH_TAG_TWO = %w[textarea option pre].freeze

        # [Array] boolean attributes (論理値で指定する属性)
        ATTR_BOOL = %w[disabled readonly checked selected multiple].freeze

        # DISABLE_ELEMENT = "input|textarea|select|optgroup"
        # [Array] element with disablled attribute (disabled属性のある要素)
        DISABLE_ELEMENT = %w[input textarea select optgroup].freeze
        # READONLY_TYPE = "text|password"
        # [Array] the type of an input element with a readonly attribute (readonly属性のあるinput要素のタイプ)
        READONLY_TYPE = %w[text password].freeze

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

        RE_SELECTED_M = Regexp.new(SELECTED_M)
        RE_SELECTED_M1 = Regexp.new(SELECTED_M1)
        RE_SELECTED_R = Regexp.new(SELECTED_R)
        RE_CHECKED_M = Regexp.new(CHECKED_M)
        RE_CHECKED_M1 = Regexp.new(CHECKED_M1)
        RE_CHECKED_R = Regexp.new(CHECKED_R)
        RE_DISABLED_M = Regexp.new(DISABLED_M)
        RE_DISABLED_M1 = Regexp.new(DISABLED_M1)
        RE_DISABLED_R = Regexp.new(DISABLED_R)
        RE_READONLY_M = Regexp.new(READONLY_M)
        RE_READONLY_M1 = Regexp.new(READONLY_M1)
        RE_READONLY_R = Regexp.new(READONLY_R)
        RE_MULTIPLE_M = Regexp.new(MULTIPLE_M)
        RE_MULTIPLE_M1 = Regexp.new(MULTIPLE_M1)
        RE_MULTIPLE_R = Regexp.new(MULTIPLE_R)

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
          @doc_type = Parser::XHTML4
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
        # parse document (ドキュメントを解析する)
        #
        def parse
          analyze_ml
        end

        protected :parse

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml
          analyze_content_type
          analyze_newline
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
        def analyze_content_type # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          @error_check = false

          element_three('meta', 'http-equiv', 'Content-Type')

          element_three('meta', 'http-equiv', 'Content-Type') unless @elm_

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

        private :analyze_content_type

        #
        # analyze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_newline
          NEWLINE.each do |a|
            @root.newline = a if @root.document.include?(a)
          end
        end

        private :analyze_newline

        def edit_attrs_(elm, attr_name, attr_value) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          if match?('selected', attr_name) && match?('option', elm.name)
            edit_attrs_five(elm, attr_value, RE_SELECTED_M, RE_SELECTED_R, SELECTED_U)
          elsif match?('multiple', attr_name) && match?('select', elm.name)
            edit_attrs_five(elm, attr_value, RE_MULTIPLE_M, RE_MULTIPLE_R, MULTIPLE_U)
          elsif match?('disabled', attr_name) && match?(DISABLE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_value, RE_DISABLED_M, RE_DISABLED_R, DISABLED_U)
          elsif match?('checked', attr_name) && match?('input', elm.name) && match?('radio', get_type(elm))
            edit_attrs_five(elm, attr_value, RE_CHECKED_M, RE_CHECKED_R, CHECKED_U)
          elsif match?('readonly', attr_name) &&
                (match?('textarea',
                        elm.name) || (match?('input', elm.name) && match?(READONLY_TYPE, get_type(elm))))
            edit_attrs_five(elm, attr_value, RE_READONLY_M, RE_READONLY_R, READONLY_U)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def edit_attrs_five(elm, attr_value, match_p, replace_regex, replace_update) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity
          # attr_value = escape(attr_value)

          if true.equal?(attr_value) || match?('true', attr_value)
            @res = match_p.match(elm.attributes)

            if !@res
              # add an attribute to attributes (属性文字列の最後に新規の属性を追加する)
              if elm.attributes != ''
                elm.attributes = String.new('') << ' ' << elm.attributes.strip
                # else
              end

              elm.attributes << ' ' << replace_update
            else
              # replace attribute (属性の置換)
              elm.attributes.gsub!(replace_regex, replace_update)
            end
          elsif false.equal?(attr_value) || match?('false', attr_value)
            # delete if attribute_name attrubute exeists (attr_name属性が存在するなら削除)
            # replace attribute (属性の置換)
            elm.attributes.gsub!(replace_regex, '')
          end
        end

        private :edit_attrs_five

        def get_attr_value_(elm, attr_name) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          if match?('selected', attr_name) && match?('option', elm.name)
            get_attr_value_r(elm, attr_name, RE_SELECTED_M1)
          elsif match?('multiple', attr_name) && match?('select', elm.name)
            get_attr_value_r(elm, attr_name, RE_MULTIPLE_M1)
          elsif match?('diabled', attr_name) && match?(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, RE_DISABLED_M1)
          elsif match?('checked', attr_name) && match?('input', elm.name) && match?('radio', get_type(elm))
            get_attr_value_r(elm, attr_name, RE_CHECKED_M1)
          elsif match?('readonly', attr_name) &&
                (match?('textarea',
                        elm.name) || (match?('input', elm.name) && match?(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, attr_name, RE_READONLY_M1)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          unless elm.type_value
            elm.type_value = get_attr_value(elm, 'type')
            elm.type_value = get_attr_value(elm, 'TYPE') unless elm.type_value
          end

          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, attr_name, match_p) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          @res = match_p.match(elm.attributes)

          if @res
            if @res[1]
              if attr_name == @res[1]
                'true'
              else
                @res[1]
              end
            elsif @res[2]
              if attr_name == @res[2]
                'true'
              else
                @res[2]
              end
            elsif @res[3]
              if attr_name == @res[3]
                'true'
              else
                @res[3]
              end
            elsif @res[4]
              if attr_name == @res[4]
                'true'
              else
                @res[4]
              end
            end
          else
            'false'
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

          elm.attributes.scan(RE_GET_ATTRS_MAP) do |a, b|
            if match?(ATTR_BOOL, a) && a == b
              attrs.store(a, 'true')
            else
              attrs.store(a, unescape(b))
            end
          end

          attrs.recordable = true

          attrs
        end

        private :get_attr_map
      end
    end
  end
end
