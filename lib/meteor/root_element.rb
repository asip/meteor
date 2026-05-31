# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # root element class (ルート要素クラス)
  #
  # @!attribute [rw] content_type
  #  @return [String] content type (コンテントタイプ)
  # @!attribute [rw] kaigyo_code
  #  @return [String] newline (改行コード)
  # @!attribute [rw] charset
  #  @return [String] charset (文字コード)
  # @!attribute [rw] character_encoding
  #  @return [String] character encoding (文字エンコーディング)
  #
  class RootElement < Element
    attr_accessor :content_type
    attr_accessor :kaigyo_code
    attr_accessor :charset
    attr_accessor :character_encoding
    # attr_accessor :document #[String] document (ドキュメント)
  end
end
