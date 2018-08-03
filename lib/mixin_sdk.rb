require "mixin_sdk/version"
require 'securerandom'
require 'digest'
require 'jwt'
require 'json'
require 'httparty'
require 'openssl'

module MixinSdk

  class Configuration
    attr_accessor :client_id, :session_id, :private_key

    def initialize
      @client_id = ''
      @session_id = ''
      @private_key = ''
    end
  end

  class << self

    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def jwt_token(method_name, uri, body)
      # client_id = "5aa450de-f6cb-48db-****-************"
      # session_id = "5a0b6221-6f2d-4bc6-****-************"
      # rsa_private = OpenSSL::PKey::RSA.new File.read 'lib/rsa.key'
      now_time = Time.now.to_i
      sign = method_name == "POST" ? "POST/#{uri}#{body}" : "GET/#{uri}"
      payload = {
        uid: configuration.client_id,
        sid: configuration.session_id,
        iat: now_time,
        exp: now_time + 3600,
        jti: SecureRandom.uuid,
        sig: Digest::SHA256.hexdigest(sign)
      }
      rsa_private = OpenSSL::PKey::RSA.new(configuration.private_key)
      JWT.encode(payload, rsa_private, 'RS512')
    end

    def mixin(method_type, method_name, body = '')
      method_type = method_type.upcase
      return p "没有此请求类型" unless ["GET", "POST"].include?(method_type)

      url = 'https://api.mixin.one/' + method_name
      token = jwt_token(method_type, method_name, body == '' ? '' : body)

      if method_type == "GET"
        result = HTTParty.get(url, headers:{'Authorization' => 'Bearer ' + token, 'Content-Type' => 'application/json'})
      else
        result = HTTParty.post(url, headers:{'Authorization' => 'Bearer '+ token, 'Content-Type' => 'application/json'}, body: body)
      end
      response = result.parsed_response
      response["error"] ? response["error"]["description"] : response["data"]
    end

    # get方法的示例
    def read_profile
      mixin("get", "me")
    end

    # post方法的示例
    def update_profile
      options = {
        full_name: "价格提醒助手"
      }.to_json
      mixin("post", "me", options)
    end

  end

end
