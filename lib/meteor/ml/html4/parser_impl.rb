# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Html4
      #
      # HTML4 parser (HTMLパーサ)
      #
      class ParserImpl < Meteor::Core::Kernel
        # KAIGYO_CODE = "\r?\n|\r"
        # KAIGYO_CODE = "\r\n|\n|\r"
        KAIGYO_CODE = ["\r\n", "\n", "\r"]
        BR = "<br>"
        BR_RE = BR

        # @@match_tag = "br|hr|img|input|meta|base"
        #[Array] void elemets (空要素)
        @@match_tag = ["br", "hr", "img", "input", "meta", "base"]
        # @@match_tag_2 = "textarea|option|pre"
        #[Array] elements where line breaks do not need to be converted to <br> (改行を<br>に変換する必要のない要素)
        @@match_tag_2 = ["textarea", "option", "pre"]

        #[Array] non-nestable elements (入れ子にできない要素)
        @@match_tag_nne = ["texarea", "select", "option", "form", "fieldset"]

        #[Array] boolean attributes (論理値で指定する属性)
        @@attr_bool = ["disabled", "readonly", "checked", "selected", "multiple"]

        # DISABLE_ELEMENT = "input|textarea|select|optgroup"
        #[Array] elements with the disabled attribute (disabled属性のある要素)
        DISABLE_ELEMENT = ["input", "textarea", "select", "optgroup"]
        # READONLY_TYPE = "text|password"
        #[Array] the type of an input element with a readonly attribute (readonly属性のあるinput要素のタイプ)
        READONLY_TYPE = ["text", "password"]

        SELECTED_M = "\\sselected\\s|\\sselected$|\\sSELECTED\\s|\\sSELECTED$"
        # SELECTED_M = [' selected ',' selected',' SELECTED ',' SELECTED']
        SELECTED_R = "selected\\s|selected$|SELECTED\\s|SELECTED$"
        CHECKED_M = "\\schecked\\s|\\schecked$|\\sCHECKED\\s|\\sCHECKED$"
        # CHECKED_M = [' checked ',' checked',' CHECKED ',' CHECKED']
        CHECKED_R = "checked\\s|checked$|CHECKED\\s|CHECKED$"
        DISABLED_M = "\\sdisabled\\s|\\sdisabled$|\\sDISABLED\\s|\\sDISABLED$"
        # DISABLED_M = [' disabled ',' disiabled',' DISABLED ',' DISABLED']
        DISABLED_R = "disabled\\s|disabled$|DISABLED\\s|DISABLED$"
        READONLY_M = "\\sreadonly\\s|\\sreadonly$|\\sREADONLY\\s|\\sREADONLY$"
        # READONLY_M = [' readonly ',' readonly',' READONLY ',' READONLY']
        READONLY_R = "readonly\\s|readonly$|READONLY\\s|READONLY$"
        MULTIPLE_M = "\\smultiple\\s|\\smultiple$|\\sMULTIPLE\\s|\\sMULTIPLE$"
        # MULTIPLE_M = [' multiple ',' multiple',' MULTIPLE ',' MULTIPLE']
        MULTIPLE_R = "multiple\\s|multiple$|MULTIPLE\\s|MULTIPLE$"

        # @@pattern_true = Regexp.new("true")
        # @@pattern_false = Regexp.new("false")

        GET_ATTRS_MAP2 = "\\s(disabled|readonly|checked|selected|multiple)"

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

        @@pattern_get_attrs_map2 = Regexp.new(GET_ATTRS_MAP2)

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
          @doc_type = Parser::HTML4
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
        # @param [Meteor::Parser] ps paser (パーサ)
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
        # @return [String] conent type (コンテントタイプ)
        #
        def content_type
          @root.content_type
        end

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @error_check = false

          element_3("meta", "http-equiv", "Content-Type")

          if !@elm_
            element_3("meta", "http-equiv", "Content-Type")
          end

          @error_check = true

          if @elm_
            content = @elm_.attr("content")
            content_arr = content&.split(";")
            @root.content_type = content_arr&.at(0) || ""
            @root.charset = content_arr&.at(1)&.split("=")&.at(1) || ""
          else
            @root.content_type = ""
          end
        end

        protected :analyze_content_type

        #
        # analuze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_newline
          for a in KAIGYO_CODE
            if @root.document.include?(a)
              @root.newline = a
              # puts "kaigyo:" << @root.newline
            end
          end
        end

        protected :analyze_newline

        #
        # get element using tag name (要素のタグ名で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @return [Meteor::Element] element (要素)
        #
        def element_1(name)
          quote_name(name)

          # case of void element (空要素の場合(<->内容あり要素の場合))
          if is_match(@@match_tag, name)
            # void element search pattern (空要素検索用パターン)
            @pattern_cc = String.new("") << "<" << @_name << "(|\\s[^<>]*)>"
            # @pattern_cc = "<#{@_name}(|\\s[^<>]*)>"
            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            @res = @pattern.match(@root.document)
            if @res
              element_void_1(name)
            else
              if @error_check
                puts(Meteor::Exception::NoSuchElementException.new(name).message)
              end

              @elm_ = nil
            end
          else
            # normal element search pattern (内容あり要素検索用パターン()
            # @pattern_cc = String.new('') << "<" << @_name << '(|\\s[^<>]*)>(((?!(' << @_name
            # @pattern_cc << '[^<>]*>)).)*)<\\/' << @_name << '>'
            @pattern_cc = "<#{@_name}(|\\s[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # search of normal element (内容あり要素検索)
            @res = @pattern.match(@root.document)
            # case of normal element (内容あり要素の場合)
            if @res
              @on_search = true
              element_normal_1(name)
            else
              if @error_check
                puts(Meteor::Exception::NoSuchElementException.new(name).message)
              end

              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_1

        def element_void_1(name)
          @elm_ = Meteor::Element.new(name)
          # attribute (属性)
          @elm_.attributes = @res[1]
          # void element search pattern (空要素検索用パターン)
          @elm_.pattern = @pattern_cc

          @elm_.document = @res[0]

          @elm_.parser = self
        end

        private :element_void_1

        #
        # get element using tag name and attribute(name="value") (要素のタグ名、属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] name tag name (タグ名)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @param [true,false] quote quote flag (クオート・フラグ)
        # @return [Meteor::Element] element (要素)
        #
        def element_3(name, attr_name, attr_value, quote = true)
          if quote
            quote_element_3(name, attr_name, attr_value)
          else
            quote_name(name)
          end

          # case of void element (空要素の場合(<->内容あり要素の場合))
          if is_match(@@match_tag, name)
            # void element search pattern (空要素検索パターン)
            # @pattern_cc = String.new('') << "<" << @_name << '(\\s[^<>]*' << @_attr_name << '="'
            # @pattern_cc << @_attr_value << '"[^<>]*)>'
            @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # void element search (空要素検索)
            @res = @pattern.match(@root.document)
            if @res
              element_void_3(name)
            else
              if @error_check
                puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message)
              end

              @elm_ = nil
            end
          else
            # normal element search pattern (内容あり要素検索パターン)
            # @pattern_cc = String.new('') << "<" << @_name << '(\\s[^<>]*' << @_attr_name << '="'
            # @pattern_cc << @_attr_value << '"[^<>]*)>(((?!(' << @_name
            # @pattern_cc << '[^<>]*>)).)*)<\\/' << @_name << '>'
            @pattern_cc = "<#{@_name}(\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # search of normal element (内容あり要素検索)
            @res = @pattern.match(@root.document)

            if !@res && !is_match(@@match_tag_nne, name)
              @res = element_normal_3_2
            end

            if @res
              element_normal_3_1(name)
            else
              if @error_check
                puts(Meteor::Exception::NoSuchElementException.new(name, attr_name, attr_value).message)
              end

              @elm_ = nil
            end
          end

          @elm_
        end

        private :element_3

        def element_void_3(name)
          element_void_3_1(name, "\"[^<>]*)>")
        end

        private :element_void_3

        #
        # get element using attribute(name="value") (属性(属性名="属性値")で検索し、要素を取得する)
        # @param [String] attr_name attribute name (属性名)
        # @param [String] attr_value attribute value (属性値)
        # @return [Meteor::Element] element (要素)
        #
        def element_2(attr_name, attr_value)
          quote_attribute(attr_name, attr_value)

          # @pattern_cc = String.new('') << '<([^<>"]*)\\s[^<>]*' << @_attr_name << '="' << @_attr_value
          # @pattern_cc << '"[^<>]*>'
          @pattern_cc = "<([^<>\"]*)\\s[^<>]*#{@_attr_name}=\"#{@_attr_value}\"[^<>]*>"

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

          @elm_
        end

        private :element_2

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

          # case of void element (空要素の場合(<->内容あり要素の場合))
          if is_match(@@match_tag, name)
            # void element search pattern (空要素検索パターン)
            # @pattern_cc = String.new('') << "<" << @_name << '(\\s[^<>]*(?:' << @_attr_name1 << '="'
            # @pattern_cc << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
            # @pattern_cc << @_attr_value2 << '"|' << @_attr_name2 << '="'
            # @pattern_cc << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
            # @pattern_cc << @_attr_value1 << '")[^<>]*)>'
            @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # void element search (空要素検索)
            @res = @pattern.match(@root.document)

            if @res
              element_void_5(name)
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
            # @pattern_cc = String.new('') << "<" << @_name << '(\\s[^<>]*(?:' << @_attr_name1 << '="'
            # @pattern_cc << @_attr_value1 << '"[^<>]*' << @_attr_name2 << '="'
            # @pattern_cc << @_attr_value2 << '"|' << @_attr_name2 << '="'
            # @pattern_cc << @_attr_value2 << '"[^<>]*' << @_attr_name1 << '="'
            # @pattern_cc << @_attr_value1 << '")[^<>]*)>(((?!(' << @_name
            # @pattern_cc << '[^<>]*>)).)*)<\\/' << @_name << '>'
            @pattern_cc = "<#{@_name}(\\s[^<>]*(?:#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>(((?!(#{@_name}[^<>]*>)).)*)<\\/#{@_name}>"

            @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)
            # search of normal element (内容あり要素検索)
            @res = @pattern.match(@root.document)

            if !@res && !is_match(@@match_tag_nne, tag)
              @res = element_normal_5_2
            end

            if @res
              element_normal_5_1(name)
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

        private :element_5

        def element_void_5(name)
          element_void_5_1(name, "\")[^<>]*)>")
        end

        private :element_void_5

        #
        # get element using attribute1,2(name="value") (属性1・属性2(属性名="属性値")で検索し、要素を取得する)
        #
        # @param [String] attr_name1 attribute name1 (属性名1)
        # @param [String] attr_value1 attribute value1 (属性値1)
        # @param [String] attr_name2 attribute name2 (属性名2)
        # @param [String] attr_value2 attribute value2 (属性値2)
        # @return [Meteor::Element] element (要素)
        #
        def element_4(attr_name1, attr_value1, attr_name2, attr_value2)
          quote_element_4(attr_name1, attr_value1, attr_name2, attr_value2)

          # @pattern_cc = String.new('') << '<([^<>"]*)\\s([^<>]*(' << @_attr_name1 << '="' << @_attr_value1
          # @pattern_cc << '"[^<>]*' << @_attr_name2 << '="' << @_attr_value2
          # @pattern_cc << '"|' << @_attr_name2 << '="' << @_attr_value2
          # @pattern_cc << '"[^<>]*' << @_attr_name1 << '="' << @_attr_value1
          # @pattern_cc << '")[^<>]*)>'
          @pattern_cc = "<([^<>\"]*)\\s([^<>]*(#{@_attr_name1}=\"#{@_attr_value1}\"[^<>]*#{@_attr_name2}=\"#{@_attr_value2}\"|#{@_attr_name2}=\"#{@_attr_value2}\"[^<>]*#{@_attr_name1}=\"#{@_attr_value1}\")[^<>]*)>"

          @pattern = Meteor::Core::Util::PatternCache.get(@pattern_cc)

          @res = @pattern.match(@root.document)

          if @res
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

        def edit_attrs_(elm, attr_name, attr_value)
          if is_match("selected", attr_name) && is_match("option", elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_selected_m, @@pattern_selected_r)
          elsif is_match("multiple", attr_name) && is_match("select", elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_multiple_m, @@pattern_multiple_r)
          elsif is_match("disabled", attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_disabled_m, @@pattern_disabled_r)
          elsif is_match("checked", attr_name) && is_match("input", elm.name) && is_match("radio", get_type(elm))
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_checked_m, @@pattern_checked_r)
          elsif is_match("readonly", attr_name) &&
              (is_match("textarea", elm.name) || (is_match("input", elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            edit_attrs_5(elm, attr_name, attr_value, @@pattern_readonly_m, @@pattern_readonly_r)
          else
            super(elm, attr_name, attr_value)
          end
        end

        private :edit_attrs_

        def edit_attrs_5(elm, attr_name, attr_value, match_p, replace)
          if true.equal?(attr_value) || is_match("true", attr_value)
            @res = match_p.match(elm.attributes)

            if !@res
              if elm.attributes != "" && elm.attributes.strip != ""
                elm.attributes = String.new("") << " " << elm.attributes.strip
              else
                elm.attributes = String.new("")
              end

              elm.attributes << " " << attr_name
              # else
            end
          elsif false.equal?(attr_value) || is_match("false", attr_value)
            elm.attributes.sub!(replace, "")
          end
        end

        private :edit_attrs_5

        def edit_document_1(elm)
          edit_document_2(elm, ">")
        end

        private :edit_document_1

        def get_attr_value_(elm, attr_name)
          if is_match("selected", attr_name) && is_match("option", elm.name)
            get_attr_value_r(elm, @@pattern_selected_m)
          elsif is_match("multiple", attr_name) && is_match("select", elm.name)
            get_attr_value_r(elm, @@pattern_multiple_m)
          elsif is_match("disabled", attr_name) && is_match(DISABLE_ELEMENT, elm.name)
            get_attr_value_r(elm, @@pattern_disabled_m)
          elsif is_match("checked", attr_name) && is_match("input", elm.name) && is_match("radio", get_type(elm))
            get_attr_value_r(elm, @@pattern_checked_m)
          elsif is_match("readonly", attr_name) &&
              (is_match("textarea", elm.name) || (is_match("input", elm.name) && is_match(READONLY_TYPE, get_type(elm))))
            get_attr_value_r(elm, @@pattern_readonly_m)
          else
            super(elm, attr_name)
          end
        end

        private :get_attr_value_

        def get_type(elm)
          if !elm.type_value
            elm.type_value = get_attr_value_(elm, "type")
            if !elm.type_value
              elm.type_value = get_attr_value_(elm, "TYPE")
            end
          end

          elm.type_value
        end

        private :get_type

        def get_attr_value_r(elm, match_p)
          @res = match_p.match(elm.attributes)

          if @res
            "true"
          else
            "false"
          end
        end

        private :get_attr_value_r

        #
        # get attribute map (属性マップを取得する)
        # @param [Meteor::Element] elm element (要素)
        # @return [Hash] attribute map (属性マップ)
        #
        def get_attrs(elm)
          attrs = Hash.new

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(@@pattern_get_attrs_map2) do |a|
            attrs.store(a[0], "true")
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

          elm.attributes.scan(@@pattern_get_attrs_map) do |a, b|
            attrs.store(a, unescape(b))
          end

          elm.attributes.scan(@@pattern_get_attrs_map2) do |a|
            attrs.store(a[0], "true")
          end

          attrs.recordable = true

          attrs
        end

        private :get_attr_map

        def remove_attrs_(elm, attr_name)
          if !is_match(@@attr_bool, attr_name)
            # attribute search pattern (属性検索用パターン)
            @pattern = Meteor::Core::Util::PatternCache.get(String.new("") << attr_name << "=\"[^\"]*\"\\s?")
            # @pattern = Meteor::Core::Util::PatternCache.get("#{attr_name}=\"[^\"]*\"\\s?")
            elm.attributes.sub!(@pattern, "")
          else
            # attribute search pattern (属性検索用パターン)
            @pattern = Meteor::Core::Util::PatternCache.get(attr_name)
            elm.attributes.sub!(@pattern, "")
          end
        end

        private :remove_attrs_
      end
    end
  end
end
