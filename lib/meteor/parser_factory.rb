# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # Parser Factory Class (パーサ・ファクトリ クラス)
  #
  # @!attribute [rw] type
  #  @return [FixNum,Symbol] default type of parser (デフォルトのパーサ・タイプ)
  # @!attribute [rw] root
  #  @return [String] root root directory (基準ディレクトリ)
  # @!attribute [rw] enc
  #  @return [String] default character encoding (デフォルトエンコーディング)
  #
  class ParserFactory
    attr_accessor :type
    attr_accessor :root
    attr_accessor :enc

    alias_method :base_type, :type
    alias_method :base_type=, :type=
    alias_method :base_dir, :root
    alias_method :base_dir=, :root=
    alias_method :base_enc, :enc
    alias_method :base_enc=, :enc=

    alias_method :base_encoding, :enc
    alias_method :base_encoding=, :enc=

    #
    # initializer (イニシャライザ)
    # @overload initialize()
    # @overload initialize(root)
    #  @param [String] root root directory (基準ディレクトリ)
    # @overload initialize(root, enc)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルトエンコーディング)
    # @overload initialize(type, root, enc)
    #  @param [FixNum,Symbol] type default type of parser (デフォルトのパーサ・タイプ)
    #  @param [String] root root directory (基準ディレクトリ)
    #  @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize(*args)
      case args.length
        when 0
          initialize_0
        when 1
          initialize_1(args[0])
        when 2
          initialize_2(args[0], args[1])
        when 3
          initialize_3(args[0],args[1],args[2])
        else
          raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    #
    def initialize_0
      @cache = Hash.new
      @root = "."
      @enc = "UTF-8"
    end

    private :initialize_0

    #
    # イニシャライザ
    # @param [String] root root directory (基準ディレクトリ)
    #
    def initialize_1(root)
      @cache = Hash.new
      @root = root
      @enc = "UTF-8"
    end

    private :initialize_1

    #
    # イニシャライザ
    # @param [String] root root directory (基準ディレクトリ)
    # @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize_2(root, enc)
      @cache = Hash.new
      @root = root
      @enc = enc
    end

    private :initialize_2

    #
    # イニシャライザ
    # @param [FixNum,Symbol] type default type of parser (デフォルトのパーサ・タイプ)
    # @param [String] root root directory (基準ディレクトリ)
    # @param [String] enc default character encoding (デフォルト文字エンコーディング)
    #
    def initialize_3(type , root, enc)
      @cache = Hash.new
      @type = type
      @root = root
      @enc = enc
    end

    private :initialize_3

    #
    # set options (オプションをセットする)
    # @param [Hash] opts option (オプション)
    # @option opts [String] :root root directory (基準ディレクトリ)
    # @option @deprecated opts [String] :base_dir root directory (基準ディレクトリ)
    # @option opts [String] :enc default character encoding (デフォルト文字エンコーディング)
    # @option @deprecated opts [String] :base_enc default character encoding (デフォルト文字エンコーディング)
    # @option opts [FixNum,Symbol] :type default type of parser (デフォルトのパーサ・タイプ)
    # @option @deprecated opts [FixNum | Symbol] :base_type default type of parser (デフォルトのパーサ・タイプ)
    #
    def options=(opts)
      if opts.kind_of?(Hash)
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
      else
        raise ArgumentError
      end
    end

    #
    #@overload link(relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(relative_path)
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload link(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link(*args)
      case args.length
        when 1
          link_1(args[0])
        when 2
          if args[0].kind_of?(Fixnum) || args[0].kind_of?(Symbol)
            link_2_n(args[0], args[1])
          elsif args[0].kind_of?(String)
            link_2_s(args[0], args[1])
          else
            raise ArgumentError
          end
        when 3
          link_3(args[0], args[1], args[2])
        else
          raise ArgumentError
      end
    end

    #
    # change relative path to relative url (相対パスを相対URLにする)
    # @param [String] path relative path (相対パス)
    # @return [String] relative url (相対URL)
    #
    def path_to_url(path)
      paths = File.split(path)

      if paths.length == 1
        return File.basename(paths[0], '.*')
      else
        if ".".eql?(paths[0])
          paths.delete_at 0
          paths[paths.length - 1] = File.basename(paths[paths.length - 1], '.*')
          return String.new('') << "/" << paths.join("/")
        else
          paths[paths.length - 1] = File.basename(paths[paths.length - 1], '.*')
          return String.new('') << "/" << paths.join("/")
        end
      end
    end

    private :path_to_url

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser(パーサ)
    #
    def link_3(type, relative_path, enc)

      relative_url = path_to_url(relative_path)

      case type
        when Parser::HTML4, :html4
          html4 = Meteor::Ml::Html4::ParserImpl.new
          html.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = html4
        when Parser::XHTML4, :xhtml4
          xhtml4 = Meteor::Ml::Xhtml4::ParserImpl.new
          xhtml4.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xhtml4
        when Parser::HTML, :html, :html5
          html = Meteor::Ml::Html::ParserImpl.new
          html.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = html
        when Parser::XHTML, :xhtml, :xhtml5
          xhtml = Meteor::Ml::Xhtml::ParserImpl.new
          xhtml.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xhtml
        when Parser::XML, :xml
          xml = Meteor::Ml::Xml::ParserImpl.new
          xml.read(File.expand_path(relative_path, @root), enc)
          @cache[relative_url] = xml
      end
    end

    private :link_3

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser(パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_2_n(type, relative_path)

      relative_url = path_to_url(relative_path)

      case type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4, :xhtml4
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html, :html5
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml, :xhtml5
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.read(File.expand_path(relative_path, @root), @enc)
      @cache[relative_url] = ps

    end

    private :link_2_n

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (文字エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_2_s(relative_path,enc)

      relative_url = path_to_url(relative_path)

      case @type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4, :xhtml4
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.read(File.expand_path(relative_path, @root), enc)
      @cache[relative_url] = ps

    end

    private :link_2_s

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_1(relative_path)

      relative_url = path_to_url(relative_path)

      case @type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
        else
          raise ArgumentError
      end

      ps.read(File.expand_path(relative_path, @root), @enc)
      @cache[relative_url] = ps

    end

    private :link_1

    #
    #@overload parser(key)
    # get parser (パーサを取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload parser(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    # @deprecated
    #@overload parser(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Fixnum] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    # @deprecated
    def parser(*args)
      case args.length
        when 1
          parser_1(args[0])
        when 2,3
          link(args)
      end
      # parser_1(key)
    end

    #
    # get parser (パーサを取得する)
    # @param [String] key identifier (キー)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def parser_1(key)
      @pif = @cache[key.to_s]
      case @pif.doc_type
        when Meteor::Parser::HTML4
          Meteor::Ml::Html4::ParserImpl.new(@pif)
        when Meteor::Parser::XHTML4
          Meteor::Ml::Xhtml4::ParserImpl.new(@pif)
        when Meteor::Parser::HTML
          Meteor::Ml::Html::ParserImpl.new(@pif)
        when Meteor::Parser::XHTML
          Meteor::Ml::Xhtml::ParserImpl.new(@pif)
        when Meteor::Parser::XML
          Meteor::Ml::Xml::ParserImpl.new(@pif)
      end
    end

    private :parser_1

    #
    # get root element (ルート要素を取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def element(key)
      parser_1(key).root_element
    end

    #
    # @overload link_str(type, relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [Fixnum] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload link_str(relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def link_str(*args)
      case args.length
        when 2
          link_str_2(args[0],args[1])
        when 3
          link_str_3(args[0],args[1],args[2])
        else
          raise ArgumentError
      end
    end

    #
    # generate parser (パーサを作成する)
    # @param [Fixnum,Symbol] type type of parser (パーサ・タイプ)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_str_3(type, relative_url, doc)
      case type
        when Parser::HTML4, :html
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML4, :xhtml4
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.dcument = doc
      ps.parse
      @cache[relative_url] = ps
    end

    private :link_str_3

    #
    # generate parser (パーサを作成する)
    # @param [String] relative_url relative URL (相対URL)
    # @param [String] doc document (ドキュメント)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def link_str_2(relative_url, doc)
      case @type
        when Parser::HTML4, :html4
          ps = Meteor::Ml::Html4::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml4::ParserImpl.new
        when Parser::HTML, :html
          ps = Meteor::Ml::Html::ParserImpl.new
        when Parser::XHTML, :xhtml
          ps = Meteor::Ml::Xhtml::ParserImpl.new
        when Parser::XML, :xml
          ps = Meteor::Ml::Xml::ParserImpl.new
      end

      ps.document = doc
      ps.parse
      @cache[relative_url] = ps
    end

    private :link_str_2

    alias :paraser_str :link_str

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
      self.parser(key)
    end
  end
end
