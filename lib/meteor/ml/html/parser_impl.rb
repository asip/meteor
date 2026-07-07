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

        RE_REQUIRED_M = Regexp.new(REQUIRED_M)
        RE_REQUIRED_R = Regexp.new(REQUIRED_R)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps paser (パーサ)
        #
        def initialize(*args)
          super()
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
          elsif match?('required', attr_name) && match?(REQUIRE_ELEMENT, elm.name)
            edit_attrs_five(elm, attr_name, attr_value, RE_REQUIRED_M, RE_REQUIRED_R)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def get_attr_value_(elm, attr_name)
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
          elsif match?('required', attr_name) && match?(REQUIRE_ELEMENT, elm.name)
            get_attr_value_r(elm, RE_REQUIRED_M)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_
      end
    end
  end
end
