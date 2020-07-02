# 次の仕様を満たす、SimpleModelモジュールを作成してください
#
# 1. include されたクラスがattr_accessorを使用すると、以下の追加動作を行う
#   1. 作成したアクセサのreaderメソッドは、通常通りの動作を行う
#   2. 作成したアクセサのwriterメソッドは、通常に加え以下の動作を行う
#     1. 何らかの方法で、writerメソッドを利用した値の書き込み履歴を記憶する
#     2. いずれかのwriterメソッド経由で更新をした履歴がある場合、 `true` を返すメソッド `changed?` を作成する
#     3. 個別のwriterメソッド経由で更新した履歴を取得できるメソッド、 `ATTR_changed?` を作成する
#       1. 例として、`attr_accessor :name, :desc`　とした時、このオブジェクトに対して `obj.name = 'hoge` という操作を行ったとする
#       2. `obj.name_changed?` は `true` を返すが、 `obj.desc_changed?` は `false` を返す
#       3. 参考として、この時 `obj.changed?` は `true` を返す
# 2. initializeメソッドはハッシュを受け取り、attr_accessorで作成したアトリビュートと同名のキーがあれば、自動でインスタンス変数に記録する
#   1. ただし、この動作をwriterメソッドの履歴に残してはいけない
# 3. 履歴がある場合、すべての操作履歴を放棄し、値も初期状態に戻す `restore!` メソッドを作成する

module SimpleModel
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def attr_accessor(*args)
      args.each do |arg|
        # 初期設定用に通常の動作のwriterを設定
        define_method "old_#{arg.to_s}=" do |writer_arg|
          instance_variable_set("@#{arg.to_s}", writer_arg)
        end

        # 履歴を残すカスタマイズしたwriter
        define_method "#{arg.to_s}=" do |writer_arg|
          instance_variable_set("@#{arg.to_s}", writer_arg)
          @changed = true
          @attr_changed[arg] = true
        end

        # 通常と同じreader
        define_method "#{arg.to_s}" do
          instance_variable_get("@#{arg.to_s}")
        end

        # 各変数が変更されたかどうかのメソッド
        define_method "#{arg.to_s}_changed?" do
          @attr_changed[arg]
        end
      end
    end
  end

  def initialize(arg_hash)
    @changed = false

    # 各インスタンス変数に初期値設定
    arg_hash.each do |k, v|
      send("old_#{k.to_s}=", v)
    end

    # 初期値保存
    @initial_values = {}.tap do |hash|
      arg_hash.each do |k, v|
        hash[k] = v
      end
    end

    # 各変数の変更状態を保持する変数を初期化
    @attr_changed = {}.tap do |hash|
      arg_hash.keys.each do |key|
        hash[key] = false
      end
    end
  end

  def changed?
    @changed
  end

  def restore!
    # 初期値に戻す
    @initial_values.each do |key, value|
      instance_variable_set("@#{key.to_s}", value)
    end

    # 履歴を戻す
    @changed = false
    @attr_changed = {}.tap do |hash|
      hash.keys.each do |key|
        hash[key] = false
      end
    end
  end
end
