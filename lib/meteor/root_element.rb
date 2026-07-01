# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # root element class (ルート要素クラス)
  #
  # @!attribute [rw] content_type
  #  @return [String] content type (コンテントタイプ)
  # @!attribute [rw] newline
  #  @return [String] newline (改行コード)
  # @!attribute [rw] charset
  #  @return [String] charset (文字コード)
  # @!attribute [rw] enc
  #  @return [String] character encoding (文字エンコーディング)
  #
  class RootElement < Element
    attr_accessor :content_type
    attr_accessor :newline
    attr_accessor :charset
    attr_accessor :enc
    # attr_accessor :document #[String] document (ドキュメント)

    alias_method :character_encoding, :enc
    alias_method :character_encoding=, :enc=

    alias_method :kaigyo_code, :newline
    alias_method :kaigyo_code=, :newline=
  end
end
