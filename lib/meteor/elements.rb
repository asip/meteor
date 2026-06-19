# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # Elements Class (要素ファクトリ クラス)
  #
  class Elements
    @@pf = Meteor::Parsers.new

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
    def self.options=(opts)
      @@pf.options = opts
    end

    #
    #@overload add(type,relative_path,enc)
    # generate parser (パーサを作成する)
    # @param [Integer] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    #@overload add(type,relative_path)
    # generate parser (パーサを作成する)
    # @param [Integer] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def self.add(*args)
      @@pf.add(*args)
    end

    #
    # @overload add_str(type, relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [Integer] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload add_str(relative_url, doc)
    #  generate parser (パーサを作成する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def self.add_str(*args)
      @@pf.add_str(args)
    end

    class << self
      alias_method :link, :add
      alias_method :link_str, :add_str
    end

    #
    # get root element (ルート要素を取得する)
    # @param [String,Symbol] key identifier (キー)
    # @return [Meteor::RootElement] root element (ルート要素)
    #
    def self.get(key)
      @@pf.element(key)
    end

    class << self
      alias_method :element, :get
    end
  end

  #
  # Elements Class (要素ファクトリ クラス)
  #
  Elements = Elements
end
