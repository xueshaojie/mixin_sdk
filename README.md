# MixinSdk

Ruby版本的MixinApi

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'mixin_sdk'
```

And then execute:
``` ruby
$ gem install mixin_sdk
```

## Usage
如果使用rails可以放到 config/initializers/mixin_sdk.rb

```ruby
  MixinSdk.configuration do |config|
    config.client_id = your_client_id
    config.session_id = your_session_id
    config.private_key = your_private_key
    config.pin_token = your_pin_token
  end
```

如果不是rails中
```ruby
  require 'mixin_sdk'

  MixinSdk.configuration do |config|
    config.client_id = your_client_id
    config.session_id = your_session_id
    config.private_key = your_private_key
    config.pin_token = your_pin_token
  end
```
使用示例 get方法的示例
```ruby
  def read_profile
    MixinSdk.mixin("get", "me")
  end

  def update_profile
    MixinSdk.mixin("get", "assets")
  end
```
使用示例 post方法的示例
```ruby
  def update_profile
    options = {
      full_name: "价格提醒助手"
    }.to_json
    MixinSdk.mixin("post", "me", options)
  end

  def tran_to_user
    options = {
      asset_id: "965e5c6e-434c-3fa9-b780-c50f43cd955c",
      opponent_id: "c4d975b4-36ee-4ff5-8e08-13a86d495904",
      amount: "1",
      pin: MixinSdk.encrypt_pin("123456"), # pin_code = "123456"
      trace_id: SecureRandom.uuid,
      memo: "transfer"
    }.to_json
    MixinSdk.mixin("post", "transfers", options)
  end
```

  需要结合Mixin的开发文档来使用。例如，查看接口名称、请求类型、参数。
## References
  [Mixin开发文档](https://developers.mixin.one/api)
  [mixin_bot(ruby)](https://github.com/an-lee/mixin_bot)
  [mixin-node (nodejs)](https://github.com/virushuo/mixin-node)
## License

  [MIT License](https://opensource.org/licenses/MIT).
