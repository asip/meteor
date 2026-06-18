# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Xml
      #
      # XML parser (XMLパーサ)
      #
      class ParserImpl < Meteor::Core::Kernel
        # KAIGYO_CODE = "\r?\n|\r"
        KAIGYO_CODE = ["\r\n", "\n", "\r"]

        TABLE_FOR_ESCAPE_ = {
          "&" => "&amp;",
          "\"" => "&quot;",
          "'" => "&apos;",
          "<" => "&lt;",
          ">" => "&gt;"
        }

        PATTERN_ESCAPE = "[&\\\"'<>]"
        @@pattern_escape = Regexp.new(PATTERN_ESCAPE)

        PATTERN_UNESCAPE = "&(amp|quot|apos|gt|lt);"
        @@pattern_unescape = Regexp.new(PATTERN_UNESCAPE)

        #
        # initializer (イニシャライザ)
        # @overload initialize
        # @overload initialize(ps)
        #  @param [Meteor::Parser] ps parser (パーサ)
        #
        def initialize(*args)
          super()
          @doc_type = Parser::XML
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
          ps.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
          @root.kaigyo_code = ps.root_element.kaigyo_code
        end

        private :initialize_1

        #
        # parse document (ドキュメントを解析する)
        #
        def parse
          analyze_ml
        end

        #
        # analyze document (ドキュメントをパースする)
        #
        def analyze_ml
          analyze_kaigyo_code
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
        # analuze document , set newline (ドキュメントをパースし、改行コードをセットする)
        #
        def analyze_kaigyo_code
          for a in KAIGYO_CODE
            if @root.document.include?(a)
              @root.kaigyo_code = a
              # puts "kaigyo:" << @root.kaigyo_code
            end
          end
        end

        private :analyze_kaigyo_code

        #
        # analyze document , set content type (ドキュメントをパースし、コンテントタイプをセットする)
        #
        def analyze_content_type
          @root.content_type = "text/xml"
        end

        private :analyze_content_type

        def escape(content)
          # replace special character (特殊文字の置換)
          content = content.gsub(@@pattern_escape, TABLE_FOR_ESCAPE_)

          content
        end

        private :escape

        def escape_content(*args)
          escape(args[0])
        end

        private :escape_content

        def unescape(content)
          # replace special character (特殊文字の置換)
          # 「<」<-「&lt;」
          # 「>」<-「&gt;」
          # 「"」<-「&quot;」
          # 「'」<-「&apos;」
          # 「&」<-「&amp;」
          content.gsub(@@pattern_unescape) do
            case $1
            when "amp"
              "&"
            when "quot"
              "\""
            when "apos"
              "'"
            when "gt"
              ">"
            when "lt"
              "<"
            end
          end

          content
        end

        private :unescape

        def unescape_content(*args)
          unescape(args[0])
        end

        private :unescape_content
      end
    end
  end
end
