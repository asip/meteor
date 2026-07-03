# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Html
      #
      # HTML parser (HTMLパーサ)
      #
      class ParserImpl < Meteor::Ml::Html4::ParserImpl
        # [Array] void elements (空要素)
        MATCH_TAG = %w[br hr img input meta base embed command keygen].freeze

        # [Array] non-nestable elements (入れ子にできない要素)
        MATCH_TAG_NNE = %w[
          texarea
          select
          option
          form
          fieldset
          figure
          figcaption
          video
          audio
          progress
          meter
          time
          ruby
          rt
          rp
          datalist
          output
        ].freeze

        # [Array] boolean attributes (論理値で指定する属性)
        ATTR_BOOL = %w[disabled readonly checked selected multiple required].freeze

        # [Array] elements with the disabled attribute (disabled属性のある要素)
        DISABLE_ELEMENT = %w[input textarea select optgroup fieldset].freeze

        # [Array] elements with the required attribute (required属性のある要素)
        REQUIRE_ELEMENT = %w[input textarea].freeze

        REQUIRED_M = '\\srequired\\s|\\srequired$|\\sREQUIRED\\s|\\sREQUIRED$'
        # REQUIRED_M = [' required ',' required',' REQUIRED ',' REQUIRED']
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
          @@match_tag_nne = MATCH_TAG_NNE
          @@attr_bool = ATTR_BOOL
          @doc_type = Parser::HTML
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
            edit_attrs_five(elm, attr_name, attr_value, @@pattern_selected_m, @@pattern_selected_r)
          elsif is_match('multiple', attr_name) && is_match('select', elm.name)
            edit_attrs_five(elm, attr_name, attr_value, @@pattern_multiple_m, @@pattern_multiple_r)
          elsif is_match('disabled', attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_name, attr_value, @@pattern_disabled_m, @@pattern_disabled_r)
          elsif is_match('checked', attr_name) && is_match('input', elm.name) && is_match('radio', get_type(elm))
            edit_attrs_five(elm, attr_name, attr_value, @@pattern_checked_m, @@pattern_checked_r)
          elsif is_match('readonly', attr_name) &&
                (is_match('textarea',
                          elm.name) || (is_match('input', elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_five(elm, attr_name, attr_value, @@pattern_readonly_m, @@pattern_readonly_r)
          elsif is_match('required', attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_name, attr_value, @@pattern_required_m, @@pattern_required_r)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
          if is_match('selected', attr_name) && is_match('option', elm.name)
            get_attr_value_r(elm, @@pattern_selected_m)
          elsif is_match('multiple', attr_name) && is_match('select', elm.name)
            get_attr_value_r(elm, @@pattern_multiple_m)
          elsif is_match('disabled', attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, @@pattern_disabled_m)
          elsif is_match('checked', attr_name) && is_match('input', elm.name) && is_match('radio', get_type(elm))
            get_attr_value_r(elm, @@pattern_checked_m)
          elsif is_match('readonly', attr_name) &&
                (is_match('textarea',
                          elm.name) || (is_match('input', elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, @@pattern_readonly_m)
          elsif is_match('required', attr_name) && is_match(REQUIRE_ELEMENT, elm.name)
            get_attr_value_r(elm, @@pattern_required_m)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_
      end
    end
  end
end
