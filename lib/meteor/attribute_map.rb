# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # Attribute Map Class (属性マップ クラス)
  #
  class AttributeMap
    #
    # initializer (イニシャライザ)
    # @overload initialize
    # @overload initialize(attr_map)
    #  @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    #
    def initialize(*args)
      case args.length
      when ZERO
        initialize_0
      when ONE
        initialize_1(args[0])
      else
        raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    #
    def initialize_0
      @map = {}
      @recordable = false
    end

    private :initialize_0

    #
    # initializer (イニシャライザ)
    # @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    #
    def initialize_1(attr_map)
      # @map = Marshal.load(Marshal.dump(attr_map.map))
      @map = attr_map.map.dup
      @recordable = attr_map.recordable
    end

    private :initialize_1

    #
    # set a couple of attribute name and attribute value (属性名と属性値を対としてセットする)
    # @param [String,Symbol] name attribute name (属性名)
    # @param [String] value attribute value (属性値)
    #
    def store(name, value)
      if !@map[name]
        attr = Attribute.new
        attr.name = name
        attr.value = value
        if @recordable
          attr.changed = true
          attr.removed = false
        end

        @map[name] = attr
      else
        attr = @map[name]
        if @recordable && attr.value != value
          attr.changed = true
          attr.removed = false
        end

        attr.value = value
      end
    end

    #
    # get attribute name array (属性名配列を取得する)
    # @return [Array] attribute name array (属性名配列)
    #
    def names
      @map.keys
    end

    #
    # get attribute value using attribute name (属性名で属性値を取得する)
    # @param [String,Symbol] name attribute name (属性名)
    # @return [String] attribute value (属性値)
    #
    def fetch(name)
      return unless @map[name] && !@map[name].removed

      @map[name].value
    end

    #
    # delete attribute using attribute name (属性名に対応した属性を削除する)
    # @param name attribute name (属性名)
    #
    def delete(name)
      return unless @recordable && @map[name]

      @map[name].removed = true
      @map[name].changed = false
    end

    #
    # get update flag of attribute using attribute name (属性名で属性の変更フラグを取得する)
    # @return [true,false] update flag of attribute (属性の変更状況)
    #
    def changed(name)
      return unless @map[name]

      @map[name].changed
    end

    #
    # get delete flag of attribute using attribute name (属性名で属性の削除状況を取得する)
    # @return [true,false] delete flag of attribute (属性の削除状況)
    #
    def removed(name)
      return unless @map[name]

      @map[name].removed
    end

    attr_accessor :map, :recordable

    #
    # set a couple of attribute name and attribute value (属性名と属性値を対としてセットする)
    #
    # @param [String,Symbol] name attribute name (属性名)
    # @param [String] value attribute value (属性値)
    #
    def []=(name, value)
      store(name, value)
    end

    #
    # get attribute value using attribute name (属性名で属性値を取得する)
    #
    # @param [String,Symbol] name attribute name (属性名)
    # @return [String] attribute value (属性値)
    #
    def [](name)
      fetch(name)
    end
  end
end
