# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # Attribute class (属性クラス)
  #
  # @!attribute [rw] name
  #  @return [String,Symbol] attribute name (名前)
  # @!attribute [rw] value
  #  @return [String] attribute value (値)
  # @!attribute [rw] changed
  #  @return [true,false] update flag (更新フラグ)
  # @!attribute [rw] removed
  #  @return [true,false] deletion flag (削除フラグ)
  #
  class Attribute
    attr_accessor :name, :value, :changed, :removed

    ##
    ## initializer (イニシャライザ)
    ##
    # def initialize
    #   @name = nil
    #   @value = nil
    #   @changed = false
    #   @removed = false
    # end
  end
end
