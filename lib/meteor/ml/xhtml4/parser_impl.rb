# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Xhtml4
      #
      # XHTML4 parser (XHTML4パーサ)
      #
      class ParserImpl < Meteor::Core::Kernel
        # KAIGYO_CODE = "\r?\n|\r"
        KAIGYO_CODE = ["\r\n", "\n", "\r"].freeze
        BR = '<br/>'
        BR_RE = '<br\\/>'

        # @@match_tag_2 = "textarea|option|pre"
        # [Array] elements where line breaks do not need to be converted to <br> (改行を<br/>に変換する必要のない要素)
        @@match_tag_2 = %w[textarea option pre]

        # [Array] boolean attributes (論理値で指定する属性)
        @@attr_bool = %w[disabled readonly checked selected multiple]

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

        # @@pattern_match_tag = Regexp.new(@@match_tag)
        # @@pattern_match_tag2 = Regexp.new(@@match_tag_2)

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
            # initialize_0
          when ONE
            initialize_1(args[0])
          else
            raise ArgumentError
          end
        end

        #
        # initializer (イニシャライザ)
        #
        # def initialize_0
        # end
        #
        # private :initialize_0

        #
        # initializer (イニシャライザ)
        # @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize_1(ps)
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.charset = ps.root_element.charset
          @root.newline = ps.root_element.newline
        end

        private :initialize_1

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
        def analyze_content_type
          @error_check = false

          element_3('meta', 'http-equiv', 'Content-Type')

          element_3('meta', 'http-equiv', 'Content-Type') unless @elm_

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
          KAIGYO_CODE.each do |a|
            @root.newline = a if @root.document.include?(a)
          end
        end

        private :analyze_newline

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match('selected', attr_name) && is_match('option', elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_selected_m, @@pattern_selected_r, SELECTED_U)
          elsif is_match('multiple', attr_name) && is_match('select', elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_multiple_m, @@pattern_multiple_r, MULTIPLE_U)
          elsif is_match('disabled', attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_value, @@pattern_disabled_m, @@pattern_disabled_r, DISABLED_U)
          elsif is_match('checked', attr_name) && is_match('input', elm.name) && is_match('radio', get_type(elm))
            edit_attrs_5(elm, attr_value, @@pattern_checked_m, @@pattern_checked_r, CHECKED_U)
          elsif is_match('readonly', attr_name) &&
                (is_match('textarea',
                          elm.name) || (is_match('input', elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_5(elm, attr_value, @@pattern_readonly_m, @@pattern_readonly_r, READONLY_U)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def edit_attrs_5(elm, attr_value, match_p, replace_regex, replace_update)
          # attr_value = escape(attr_value)

          if true.equal?(attr_value) || is_match('true', attr_value)
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
          elsif false.equal?(attr_value) || is_match('false', attr_value)
            # delete if attribute_name attrubute exeists (attr_name属性が存在するなら削除)
            # replace attribute (属性の置換)
            elm.attributes.gsub!(replace_regex, '')
          end
        end

        private :edit_attrs_5

        def get_attr_value_(elm, attr_name)
          if is_match('selected', attr_name) && is_match('option', elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_selected_m1)
          elsif is_match('multiple', attr_name) && is_match('select', elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_multiple_m1)
          elsif is_match('diabled', attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_disabled_m1)
          elsif is_match('checked', attr_name) && is_match('input', elm.name) && is_match('radio', get_type(elm))
            get_attr_value_r(elm, attr_name, @@pattern_checked_m1)
          elsif is_match('readonly', attr_name) &&
                (is_match('textarea',
                          elm.name) || (is_match('input', elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, attr_name, @@pattern_readonly_m1)
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

        def get_attr_value_r(elm, attr_name, match_p)
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

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            if is_match(@@attr_bool, a) && a == b
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
