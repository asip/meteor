# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Ml
    module Xml
      #
      # XML parser (XMLパーサ)
      #
      class ParserImpl < Meteor::Core::Kernel
        TABLE_FOR_ESCAPE_ = {
          '&' => '&amp;',
          '"' => '&quot;',
          "'" => '&apos;',
          '<' => '&lt;',
          '>' => '&gt;'
        }.freeze

        PATTERN_ESCAPE = "[&\\\"'<>]"

        PATTERN_UNESCAPE = '&(amp|quot|apos|gt|lt);'

        RE_ESCAPE = Regexp.new(PATTERN_ESCAPE)
        RE_UNESCAPE = Regexp.new(PATTERN_UNESCAPE)

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
          ps.document_hook = String.new(ps.document_hook)
          @root.content_type = String.new(ps.root_element.content_type)
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
        def analyze_content_type
          @root.content_type = 'text/xml'
        end

        private :analyze_content_type

        def escape(content)
          # replace special character (特殊文字の置換)
          content.gsub(RE_ESCAPE, TABLE_FOR_ESCAPE_)
        end

        private :escape

        def escape_content(*args)
          escape(args[0])
        end

        private :escape_content

        def unescape(content) # rubocop:disable Metrics/MethodLength
          # replace special character (特殊文字の置換)
          # 「<」<-「&lt;」
          # 「>」<-「&gt;」
          # 「"」<-「&quot;」
          # 「'」<-「&apos;」
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
