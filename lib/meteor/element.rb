# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  #
  # Element Class (要素クラス)
  #
  # @!attribute [rw] name
  #  @return [String] tag name (要素名)
  # @!attribute [rw] attributes
  #  @return [String] attributes (属性群)
  # @!attribute [rw] mixed_content
  #  @return [String] content (内容)
  # @!attribute [rw] raw_content
  #  @return [false,true] entity ref flag of content (内容のエンティティ参照フラグ)
  # @!attribute [rw] pattern
  #  @return [String] pattern (パターン)
  # @!attribute [rw] document_sync
  #  @return [true,false] document update flag (ドキュメント更新フラグ)
  # @!attribute [rw] empty
  #  @return [true,false] content empty flag (内容存在フラグ)
  # @!attribute [rw] cx
  #  @return [true,false] comment extension tag flag (コメント拡張タグフラグ)
  # @!attribute [rw] mono
  #  @return [true,false] child element existance flag (子要素存在フラグ)
  # @!attribute [rw] parser
  #  @return [Meteor::Parser] parser(パーサ)
  # @!attribute [rw] type_value
  #  @return [String] type (タイプ属性)
  # @!attribute [rw] usable
  #  @return [true,false] usable flag (有効・無効フラグ)
  # @!attribute [rw] origin
  #  @return [Meteor::Element] original pointer (原本ポインタ)
  # @!attribute [rw] copy
  #  @return [Meteor::Element] copy pointer (複製ポインタ)
  # @!attribute [rw] removed
  #  @return [true,false] deletion flag (削除フラグ)
  #
  class Element
    attr_accessor :name
    attr_accessor :attributes
    attr_accessor :mixed_content
    attr_accessor :raw_content
    attr_accessor :pattern
    attr_accessor :document_sync
    attr_accessor :empty
    attr_accessor :cx
    attr_accessor :mono
    attr_accessor :parser
    attr_accessor :type_value
    attr_accessor :usable
    attr_accessor :origin
    attr_accessor :copy
    attr_accessor :removed

    alias :tag :name
    alias :tag= :name=

    #
    # initializer (イニシャライザ)
    # @overload initialize(name)
    #  @param [String,Symbol] name tag name (タグ名)
    # @overload initialize(elm)
    #  @param [Meteor::Element] elm element (要素)
    # @overload initialize(elm,ps)
    #  @param [Meteor::Element] elm element (要素)
    #  @param [Meteor::Parser] ps parser (パーサ)
    #
    def initialize(*args)
      case args.length
        when Meteor::ONE
          if args[0].kind_of?(String)
            initialize_s(args[0])
          elsif args[0].kind_of?(Meteor::Element)
            initialize_e(args[0])
          else
            raise ArgumentError
          end
        when Meteor::TWO
          @name = args[0].name
          @attributes = String.new(args[0].attributes)
          @mixed_content = String.new(args[0].mixed_content)
          # @pattern = String.new(args[0].pattern)
          @pattern = args[0].pattern
          @document = String.new(args[0].document)
          @empty = args[0].empty
          @cx = args[0].cx
          @mono = args[0].mono
          @parser = args[1]
          # @usable = false
          @origin = args[0]
          args[0].copy = self
        when Meteor::ZERO
        else
          raise ArgumentError
      end
    end

    #
    # initializer (イニシャライザ)
    # @param [String] name tag name (タグ名)
    #
    def initialize_s(name)
      @name = name
      # @attributes = nil
      # @mixed_content = nil
      # @pattern = nil
      # @document = nil
      # @parser=nil
      # @empty = false
      # @cx = false
      # @mono = false
      # @parent = false
      @usable = true
    end

    private :initialize_s

    #
    # initializer (イニシャライザ)
    # @param [Meteor::Element] elm element (要素)
    #
    def initialize_e(elm)
      @name = elm.name
      @attributes = String.new(elm.attributes)
      # @pattern = String.new(elm.pattern)
      @pattern = elm.pattern
      @document = String.new(elm.document)
      @empty = elm.empty
      @cx = elm.cx
      @mono = elm.mono
      @origin = elm
      @parser = elm.parser
      @usable = true
    end

    private :initialize_e

    #
    # make copy (コピーを作成する)
    # @overload new!(elm,ps)
    #  @param [Meteor::Element] elm element (要素)
    #  @param [Meteor::Parser] ps parser (パーサ)
    #  @return [Meteor::Element] element (要素)
    #
    def self.new!(*args)
      case args.length
        when Meteor::TWO
          @obj = args[1].element_hook
          if @obj
            @obj.attributes = String.new(args[0].attributes)
            @obj.mixed_content = String.new(args[0].mixed_content)
            # @obj.pattern = String.new(args[0].pattern)
            @obj.document = String.new(args[0].document)
            @obj
          else
            @obj = self.new(args[0], args[1])
            args[1].element_hook = @obj
            @obj
          end
        else
          raise ArgumentError
      end
    end

    #
    # clone (複製する)
    # @return [Meteor::Element] element (要素)
    #
    def clone
      obj = self.parser.element_cache[self.object_id]
      if obj
        obj.attributes = String.new(self.attributes)
        obj.mixed_content = String.new(self.mixed_content)
        # obj.pattern = String.new(self.pattern)
        obj.document = String.new(self.document)
        obj.usable = true
        obj
      else
        obj = self.new(self)
        self.parser.element_cache[self.object_id] = obj
        obj
      end
    end

    #
    # set document (ドキュメントをセットする)
    # @param [String] doc document (ドキュメント)
    #
    def document=(doc)
      @document_sync = false
      @document = doc
    end

    #
    # get document (ドキュメントを取得する)
    # @return [String] document (ドキュメント)
    #
    def document
      if @document_sync
        @document_sync = false
        case @parser.doc_type
          when Parser::HTML, Parser::HTML4
            if @cx
              # @pattern_cc = String.new('') << '<!-- @' << elm.name << ' ' << elm.attributes << '-->' << elm.mixed_content << '<!-- /@' << elm.name << ' -->'
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty
                # @pattern_cc = String.new('') << "<" << elm.name << elm.attributes << '>' << elm.mixed_content << '</' << elm.name << '>'
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = String.new('') << "<" << @name << @attributes << '>'
                # @document = "<#{@name}#{@attributes}>"
              end
            end
          when Parser::XHTML, Parser::XHTML4, Parser::XML
            if @cx
              # @pattern_cc = String.new('') << '<!-- @' << elm.name << ' ' << elm.attributes << '-->' << elm.mixed_content << '<!-- /@' << elm.name << ' -->'
              @document = "<!-- @#{@name} #{@attributes} -->#{@mixed_content}<!-- /@#{@name} -->"
            else
              if @empty
                # @pattern_cc = String.new('') << "<" << elm.name << elm.attributes << '>' << elm.mixed_content << '</' << elm.name << '>'
                @document = "<#{@name}#{@attributes}>#{@mixed_content}</#{@name}>"
              else
                @document = String.new('') << "<" << @name << @attributes << '/>'
                # @document = "<#{@name}#{@attributes}/>"
              end
            end
        end
      else
        @document
      end
    end

    #
    # get element (要素を取得する)
    # @overload element()
    #  get element (要素を取得する)
    #  @return [Meteor::Element] element (要素)
    # @overload element(name)
    #  get element using tag name (要素のタグ名で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @return [Meteor::Element] element (要素)
    # @overload element(name,attrs)
    #  get element using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attrs)
    #  get element using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Meteor::Element] element(要素)
    # @overload element(name,attr_name,attr_value)
    #  get element using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attr_name,attr_value)
    #  get element using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name 属性名
    #  @param [String] attr_value 属性値
    #  @return [Meteor::Element] element (要素)
    # @overload element(name,attr_name1,attr_value1,attr_name2,attr_value2)
    #  get element using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Meteor::Element] element (要素)
    # @overload element(attr_name1,attr_value1,attr_name2,attr_value2)
    #  get element using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name1 属性名1
    #  @param [String] attr_value1 属性値1
    #  @param [String,Symbol] attr_name2 属性名2
    #  @param [String] attr_value2 属性値2
    #  @return [Meteor::Element] element(要素)
    # @overload element(elm)
    #  mirror element (要素を射影する)
    #  @param [Meteor::Element] elm element(要素)
    #  @return [Meteor::Element] element(要素)
    #
    def element(elm = nil, attrs = nil,*args)
      # case args.length
      # when ZERO
      if !elm && !attrs
        @parser.element(self)
      else
        @parser.element(elm, attrs, *args)
      end
    end

    alias :child :element

    #
    # get elements (要素を取得する)
    # @overload elements(name)
    #  get elements using tag name (要素のタグ名で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @return [Array<Meteor::Element>] element array(要素配列)
    # @overload elements(name,attrs)
    #  get elements using tag name and attribute map (要素のタグ名と属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(attrs)
    #  get elements using attribute map (属性(属性名="属性値")あるいは属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(name,attr_name,attr_value)
    #  get elements using tag name and attribute(name="value") (要素のタグ名と属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(attr_name,attr_value)
    #  get elements using attribute(name="value") (属性(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String] attr_value attribute value (属性値)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(name,attr_name1,attr_value1,attr_name2,attr_value2)
    #  get elements using tag name and attribute1,2(name="value") (要素のタグ名と属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    # @overload elements(attr_name1,attr_value1,attr_name2,attr_value2)
    #  get elements using attribute1,2(name="value") (属性１・属性２(属性名="属性値")で要素を取得する)
    #  @param [String,Symbol] attr_name1 attribute name1 (属性名1)
    #  @param [String] attr_value1 attribute value1 (属性値1)
    #  @param [String,Symbol] attr_name2 attribute name2 (属性名2)
    #  @param [String] attr_value2 attribute value2 (属性値2)
    #  @return [Array<Meteor::Element>] element array (要素配列)
    #
    def elements(*args)
      @parser.elements(*args)
    end

    #
    # get (child) elements using selector like css3(CSS3のようにセレクタを用いて(子)要素を取得する)
    # CSS3 selector partial support (CSS3セレクタの部分的サポート)
    # @param selector [String] selector (セレクタ)
    # @return [Array<Meteor::Element>] element (要素)
    #
    def find(selector)
      @parser.find(selector)
    end

    alias :css :find

    #
    # get cx(comment extension) tag (CX(コメント拡張)タグを取得する)
    # @overload cxtag(name,id)
    #  get cx(comment extension) tag using tag name and id attribute (タグ名とID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
    #  @param [String,Symbol] name tag name (タグ名)
    #  @param [String] id id attribute value (ID属性値)
    #  @return [Meteor::Element] element(要素)
    # @overload cxtag(id)
    #  get cx(comment extension) tag using id attribute (ID属性(id="ID属性値")でCX(コメント拡張)タグを取得する)
    #  @param [String] id id attribute value (ID属性値)
    #  @return [Meteor::Element] element (要素)
    #
    def cxtag(*args)
      @parser.cxtag(*args)
    end

    #
    # @overload attr(attr)
    #  set attribute of element (要素の属性をセットする)
    #  @param [Hash<String,String>,Hash<Symbol,String>] attr attribute (属性)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload attr(attr_name,attr_value)
    #  set attribute of element (要素の属性をセットする)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @param [String,true,false] attr_value attribute value (属性値)
    #  @return [Meteor::Element] element (要素)
    # @overload attr(attr_name)
    #  get attribute value of element (要素の属性値を取得する)
    #  @param [String,Symbol] attr_name attribute name (属性名)
    #  @return [String] attribute value (属性値)
    #
    def attr(attrs,*args)
      @parser.attr(self, attrs,*args)
    end

    #
    # set attribute of element (要素の属性をセットする)
    # @param [Hash<String,String>,Hash<Symbol,String>] attr attribute (属性)
    # @return [Meteor::Element] element (要素)
    #
    def attr=(attr)
      @parser.attr(self,attr)
    end

    #
    # set attribute map (要素マップをセットする)
    # @param [Hash<String,String>,Hash<Symbol,String>] attrs attribute map (属性マップ)
    # @return [Meteor::Element] element (要素)
    def attrs=(attrs)
      @parser.attrs(self, attrs)
    end

    #
    # get attribute map (属性マップを取得する)
    # @return [Hash<String,String>,Hash<Symbol,String>] attribute map (属性マップ)
    #
    def attrs
      @parser.attrs(self)
    end

    #
    # @overload attr_map(attr_map)
    #  set attribute map (属性マップをセットする)
    #  @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload attr_map()
    #  get attribute map (属性マップを取得する)
    #  @return [Meteor::AttributeMap] attribute map (属性マップ)
    #
    def attr_map(*args)
      @parser.attr_map(self, *args)
    end

    #
    # set attribute map (属性マップをセットする)
    # @param [Meteor::AttributeMap] attr_map attribute map (属性マップ)
    # @return [Meteor::Element] element (要素)
    #
    def attr_map=(attr_map)
      @parser.attr_map(self, attr_map)
    end

    #
    # @overload content(content,entity_ref=true)
    #  set content of element (要素の内容をセットする)
    #  @param [String] content content of element (要素の内容)
    #  @param [true,false] entity_ref entity reference flag (エンティティ参照フラグ)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload content(content)
    #  set content of element (要素の内容をセットする)
    #  @param [String] content content of element (要素の内容)
    #  @return [Meteor::Element] element (要素)
    #  @deprecated
    # @overload content()
    #  get content of element (要素の内容を取得する)
    #  @return [String] content (内容)
    #
    def content(*args)
      @parser.content(self, *args)
    end

    alias :text :content

    #
    # set content of element (要素の内容をセットする)
    # @param [String] value content (要素の内容)
    # @return [Meteor::Element] element (要素)
    #
    def content=(value)
      @parser.content(self, value)
    end

    alias :text= :content=

    #
    # set attribute (属性をセットする)
    # @param [String,Symbol] name attribute name (属性の名前)
    # @param [String] value attribute value (属性の値)
    # @return [Meteor::Element] element (要素)
    #
    def []=(name, value)
      if value != nil
        @parser.attr(self, name, value)
      else
        @parser.remove_attr(self, name)
      end
    end

    #
    # get attribute value (属性の値を取得する)
    # @param [String,Symbol] name attribute name (属性の名前)
    # @return [String] attribute value (属性の値)
    #
    def [](name)
      @parser.attr(self, name)
    end

    #
    # remove attribute of element (要素の属性を消す)
    # @param [String,Symbol] attr_name attribute name (属性名)
    # @return [Meteor::Element] element (要素)
    #
    def remove_attr(attr_name)
      @parser.remove_attr(self, attr_name)
    end

    #
    # remove element (要素を削除する)
    #
    def remove
      @parser.remove_element(self)
    end

    #
    # reflect (反映する)
    #
    def flash
      @parser.flash
    end

    alias :flush :flash

    #
    # @overload execute(hook)
    #  run action of Hooker (Hookerクラスの処理を実行する)
    #  @param [Meteor::Hook::Hooker] hook Hooker object (Hookerオブジェクト)
    # @overload execute(loop,list)
    #  run action of Looper (Looperクラスの処理を実行する)
    #  @param [Meteor::Hook::Looper] loop Looper object (Looperオブジェクト)
    #  @param [Array] list 配列
    #
    def execute(*args)
      @parser.execute(self, *args)
    end
  end
end
