# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Xhtml
      #
      # XHTML parser (XHTMLパーサ)
      #
      class ParserImpl < Meteor::Ml::Xhtml4::ParserImpl
        # [Array] boolean attributes (論理値で指定する属性)
        ATTR_BOOL = %w[disabled readonly checked selected multiple required].freeze

        # [Array] elements with the disabled attribute (disabled属性のある要素)
        DISABLE_ELEMENT = %w[input textarea select optgroup fieldset].freeze

        # [Array] elements with a readonly attribute (required属性のある要素)
        REQUIRE_ELEMENT = %w[input textarea].freeze

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
          @@attr_bool = ATTR_BOOL
          @doc_type = Parser::XHTML
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
        def initialize_one(ps)
          @root.document = String.new(ps.document)
          self.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.charset = ps.root_element.charset
          @root.newline = ps.root_element.newline
        end

        private :initialize_one

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @error_check = false

          element_three('meta', 'charset', '[a-zA-Z-]+', false)

          element_three('meta', 'charset', '[a-zA-Z-]+', false) unless @elm_

          @error_check = true

          if @elm_
            @root.charset = @elm_.attr('charset')
            @root.charset = 'utf-8' unless @root.charset
          else
            @root.charset = 'utf-8'
          end

          @root.content_type = 'text/html'
        end

        private :analyze_content_type

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match('selected', attr_name) && is_match('option', elm.name)
            edit_attrs_five(elm, attr_value, @@pattern_selected_m, @@pattern_selected_r, SELECTED_U)
          elsif is_match('multiple', attr_name) && is_match('select', elm.name)
            edit_attrs_five(elm, attr_value, @@pattern_multiple_m, @@pattern_multiple_r, MULTIPLE_U)
          elsif is_match('disabled', attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_value, @@pattern_disabled_m, @@pattern_disabled_r, DISABLED_U)
          elsif is_match('checked', attr_name) && is_match('input', elm.name) && is_match('radio', get_type(elm))
            edit_attrs_five(elm, attr_value, @@pattern_checked_m, @@pattern_checked_r, CHECKED_U)
          elsif is_match('readonly', attr_name) &&
                (is_match('textarea',
                          elm.name) || (is_match('input', elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_five(elm, attr_value, @@pattern_readonly_m, @@pattern_readonly_r, READONLY_U)
          elsif is_match('required', attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_value, @@pattern_required_m, @@pattern_required_r, REQUIRED_U)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
          if is_match('selected', attr_name) && is_match('option', elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_selected_m1)
          elsif is_match('multiple', attr_name) && is_match('select', elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_multiple_m1)
          elsif is_match('disabled', attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_disabled_m1)
          elsif is_match('checked', attr_name) && is_match('input', elm.name) && is_match('radio', get_type(elm))
            get_attr_value_r(elm, attr_name, @@pattern_checked_m1)
          elsif is_match('readonly', attr_name) &&
                (is_match('textarea',
                          elm.name) || (is_match('input', elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, attr_name, @@pattern_readonly_m1)
          elsif is_match('required', attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            get_attr_value_r(elm, attr_name, @@pattern_required_m1)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_
      end
    end
  end
end
