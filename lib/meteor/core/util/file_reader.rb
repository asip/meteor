module Meteor
  module Core
    module Util
      #
      # FileReader Class (ファイル・リーダー クラス)
      #
      class FileReader
        #
        # read file (ファイルを読み込む)
        # @param [String] file_path absolute path of input file (入力ファイルの絶対パス)
        # @param [String] enc character encoding of input file (入力ファイルの文字コード)
        #
        def self.read(file_path, enc)
          mode = if enc == "UTF-8"
            # String.new("") << "r:" << enc
            "r:UTF-8"
          else
            String.new("") << "r:" << enc << ":utf-8"
          end

          # open file (ファイルのオープン)
          io = File.open(file_path, mode)

          # load (読込)
          data = io.read

          # close file (ファイルのクローズ)
          io.close

          data
        end
      end
    end
  end
end
