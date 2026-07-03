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
    # @option opts [Integer,Symbol] :type default type of parser (デフォルトのパーサ・タイプ)
    # @option @deprecated opts [Integer | Symbol] :base_type default type of parser (デフォルトのパーサ・タイプ)
    #
    def self.options=(opts)
      @@pf.options = opts
    end

    #
    # @overload add(type,relative_path,enc)
    # add parser (パーサを追加する)
    # @param [Integer] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @param [String] enc character encoding (エンコーディング)
    # @return [Meteor::Parser] parser (パーサ)
    # @overload add(type,relative_path)
    # add parser (パーサを追加する)
    # @param [Integer] type type of parser (パーサ・タイプ)
    # @param [String] relative_path relative file path (相対ファイルパス)
    # @return [Meteor::Parser] parser (パーサ)
    #
    def self.add(*args)
      @@pf.add(*args)
    end

    #
    # @overload add_template(type, relative_url, doc)
    #  add parser (パーサを追加する)
    #  @param [Integer] type type of parser (パーサ・タイプ)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    # @overload add_template(relative_url, doc)
    #  add parser (パーサを追加する)
    #  @param [String] relative_url relative URL (相対URL)
    #  @param [String] doc document (ドキュメント)
    #  @return [Meteor::Parser] parser (パーサ)
    #
    def self.add_template(*args)
      @@pf.add_template(args)
    end

    class << self
      alias link add
      alias add_str add_template
      alias link_str add_template
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
      alias element get
    end
  end

  #
  # Elements Class (要素ファクトリ クラス)
  #
  ElementFactory = Elements
end
