# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # Parser Factory Class (パーサ・ファクトリ クラス)
  #
  # @!attribute [rw] type
  #  @return [Integer,Symbol] default type of parser (デフォルトのパーサ・タイプ)
  # @!attribute [rw] root
  #  @return [String] root root directory (基準ディレクトリ)
  # @!attribute [rw] enc
  #  @return [String] default character encoding (デフォルトエンコーディング)
  #
  class Parsers
    attr_accessor :type, :root, :enc

    alias base_type type
    alias base_type= type=
    alias base_dir root
    alias base_dir= root=
    alias base_enc enc
    alias base_enc= enc=

    alias base_encoding enc
    alias base_encoding= enc=

    #
    # initializer (イニシャライザ)
    # @overload initialize()
    # @overload initialize(root)
    #  @param [String] root root directory (基準ディレクトリ)
    # @overload initialize(root, enc)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルトエンコーディング)
    # @overload initialize(type, root, enc)
    #  @param [Integer,Symbol] type default type of parser (デフォルトのパーサ・タイプ)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize(*args)
      case args.length
      when 0
        initialize_zero
      when 1
        initialize_one(args[0])
      when 2
        initialize_two(args[0], args[1])
      when 3
        initialize_three(args[0], args[1], args[2])
      else
        raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    #
    def initialize_zero
      initialize_two
    end

    private :initialize_zero

    #
    # initializer (イニシャライザ)
    # @param [String] root root directory (基準ディレクトリ)
    #
    def initialize_one(root)
      initialize_two(root)
    end

    private :initialize_one

    #
    # initializer (イニシャライザ)
    # @param [String] root root directory (基準ディレクトリ)
    # @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize_two(root = '.', enc = 'UTF-8')
      @cache = {}
      @root = root
      @enc = enc
    end

    private :initialize_two

    #
    # initializer (イニシャライザ)
    # @param [Integer,Symbol] type default type of parser (デフォルトのパーサ・タイプ)
    # @param [String] root root directory (基準ディレクトリ)
    # @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize_three(type, root = '.', enc = 'UTF-8')
      @cache = {}
      @type = type
      @root = root
      @enc = enc
    end

    private :initialize_three

    #
    # set options (オプションをセットする)
    # @param [Hash] opts option (オプション)
    # @option opts [String] :root root directory (基準ディレクトリ)
    # @option @deprecated opts [String] :base_dir root directory (基準ディレクトリ)
    # @option opts [String] :enc default character encoding (デフォルト文字エンコーディング)
    # @option @deprecated opts [String] :base_enc default character encoding (デフォルト文字エンコーディング)
    # @option opts [Integer,Symbol] :type default type of parser (デフォルトのパーサ・タイプ)
    # @option @deprecated opts [Integer | Symbol] :base_type default type of parser (デフォルトのパーサ・タイプ)
    #
    def options=(opts)
      raise ArgumentError unless opts.is_a?(Hash)

      if opts.include?(:root)
        @root = opts[:root]
      elsif opts.include?(:base_dir)
        @root = opts[:base_dir]
      end

      if opts.include?(:enc)
        @enc = opts[:enc]
      elsif opts.include?(:base_enc)
        @enc = opts[:base_enc]
      end

      if opts.include?(:type)
        @type = opts[:type]
      elsif opts.include?(:base_type)
        @type = opts[:base_type]
      end
    end

    #
    # @overload add(relative_path,enc)
    # add parser (パーサを追加する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    # @overload add(relative_path)
    # add parser (パーサを追加する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    # @overload add(type,relative_path,enc)
    # add parser (パーサを追加する)
    # @param [Integer,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    # @overload add(type,relative_path)
    # add parser (パーサを追加する)
    # @param [Integer,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def add(*args)
      case args.length
      when 1
        add_file_one(args[0])
      when 2
        if args[0].is_a?(Integer) || args[0].is_a?(Symbol)
          add_file_two_n(args[0], args[1])
        elsif args[0].is_a?(String)
          add_file_two_s(args[0], args[1])
        else
          raise ArgumentError
        end
      when 3
        add_file_three(args[0], args[1], args[2])
      else
        raise ArgumentError
      end
    end

    alias link add

    #
    # change relative path to relative url (相対パスを相対URLにする)
    # @param [String] path relative path (相対パス)
    # @return [String] relative url (相対URL)
    #
    def path_to_url(path)
      paths = File.split(path)

      if paths.length == 1
        File.basename(paths[0], '.*')
      elsif paths[0] == '.'
        paths.delete_at(0)
        paths[paths.length - 1] = File.basename(paths[paths.length - 1], '.*')
        String.new('') << '/' << paths.join('/')
      else
        paths[paths.length - 1] = File.basename(paths[paths.length - 1], '.*')
        String.new('') << '/' << paths.join('/')
      end
    end

    private :path_to_url

    #
    # add parser (パーサを追加する)
    # @param [Integer,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser(パーサ)
    #
    def add_file_three(type, relative_path, enc = 'UTF-8')
      relative_url = path_to_url(relative_path)

      add_template_three(type, relative_url,
                         Meteor::Core::Util::FileReader.read(File.expand_path(relative_path, @root), enc))
    end

    private :add_file_three

    #
    # add parser (パーサを追加する)
    # @param [Integer,Symbol] type type of parser(パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def add_file_two_n(type, relative_path)
      add_file_three(type, relative_path, @enc)
    end

    private :add_file_two_n

    #
    # add parser (パーサを追加する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def add_file_two_s(relative_path, enc)
      add_file_three(@type, relative_path, enc)
    end

    private :add_file_two_s

    #
    # add parser (パーサを追加する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def add_file_one(relative_path)
      add_file_three(@type, relative_path, @enc)
    end

    private :add_file_one

    #
    # @overload add_template(type, relative_url, doc)
    #  add parser (パーサを追加する)
    #  @param [Integer,Symbol] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload add_template(relative_url, doc)
    #  add parser (パーサを追加する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def add_template(*args)
      case args.length
      when 2
        add_template_two(args[0], args[1])
      when 3
        add_template_three(args[0], args[1], args[2])
      else
        raise ArgumentError
      end
    end

    #
    # add parser (パーサを追加する)
    # @param [Integer,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def add_template_three(type, relative_url, doc)
      ps = new_parser(type)
      ps.document = doc

      @cache[relative_url] = ps
    end

    private :add_template_three

    #
    # add parser (パーサを追加する)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def add_template_two(relative_url, doc)
      add_template_three(@type, relative_url, doc)
    end

    private :add_template_two

    alias link_str add_template
    alias add_str add_template
    alias parser_str add_template

    #
    # @overload parser(key)
    # get parser (パーサを取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    # @overload parser(type,relative_path,enc)
    # add parser (パーサを追加する)
    # @param [Integer] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    # @deprecated
    # @overload parser(type,relative_path)
    # add parser (パーサを追加する)
    # @param [Integer] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    # @deprecated
    def parser(*args)
      case args.length
      when 1
        parser_one(args[0])
      when 2, 3
        add(args)
      end
      # parser_one(key)
    end

    #
    # get parser (パーサを取得する)
    # @param [String] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def parser_one(key)
      @pif = @cache[key.to_s]
      case @pif.doc_type
      when Meteor::Parser::HTML
        Meteor::Ml::Html::ParserImpl.new(@pif)
      when Meteor::Parser::XML
        Meteor::Ml::Xml::ParserImpl.new(@pif)
      when Meteor::Parser::XHTML
        Meteor::Ml::Xhtml::ParserImpl.new(@pif)
      when Meteor::Parser::HTML4
        Meteor::Ml::Html4::ParserImpl.new(@pif)
      when Meteor::Parser::XHTML4
        Meteor::Ml::Xhtml4::ParserImpl.new(@pif)
      end
    end

    private :parser_one

    #
    # get root element (ルート要素を取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def element(key)
      parser_one(key).root_element
    end

    def new_parser(type)
      case type
      when Parser::HTML, :html
        Meteor::Ml::Html::ParserImpl.new
      when Parser::XML, :xml
        Meteor::Ml::Xml::ParserImpl.new
      when Parser::XHTML, :xhtml
        Meteor::Ml::Xhtml::ParserImpl.new
      when Parser::HTML4, :html4
        Meteor::Ml::Html4::ParserImpl.new
      when Parser::XHTML4, :xhtml4
        Meteor::Ml::Xhtml4::ParserImpl.new
      else
        raise ArgumentError
      end
    end

    private :new_parser

    #
    # set parser (パーサをセットする)
    # @param [String,Symbol] key identifier (キー)
    # @param [Meteor::Parser] ps parser (パーサ)
    #
    def []=(key, ps)
      @cache[key] = ps
    end

    #
    # get parser (パーサを取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def [](key)
      parser(key)
    end
  end

  #
  # Parser Factory Class (パーサ・ファクトリ クラス)
  #
  ParserFactory = Parsers
end
