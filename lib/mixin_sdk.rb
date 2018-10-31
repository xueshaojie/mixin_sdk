require "mixin_sdk/version"
require 'securerandom'
require 'digest'
require 'jwt'
require 'jose'
require 'json'
require 'httparty'
require 'openssl'
require 'base64'

module MixinSdk

  class Configuration
    attr_accessor :client_id, :session_id, :private_key, :pin_token

    def initialize
      @client_id = ''
      @session_id = ''
      @private_key = ''
      @pin_token = ''
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

    def encrypt_pin(pin_code)
      pin_token = Base64.decode64(configuration.pin_token)
      private_key = OpenSSL::PKey::RSA.new(configuration.private_key)
      aes_key = JOSE::JWA::PKCS1::rsaes_oaep_decrypt('SHA256', pin_token, private_key, configuration.session_id)
      now_time = Time.now.to_i
      zero_time = now_time % 0x100
      one_time = (now_time % 0x10000) >> 8
      two_time = (now_time % 0x1000000) >> 16
      three_time = (now_time % 0x100000000) >> 24
      time_string = zero_time.chr + one_time.chr + two_time.chr + three_time.chr + "\0\0\0\0"
      encrypt_content = pin_code + time_string + time_string
      pad_count = 16 - encrypt_content.length % 16

      if pad_count > 0
        padded_content = encrypt_content + pad_count.chr * pad_count
      else
        padded_content = encrypt_content
      end

      alg = "AES-256-CBC"
      aes = OpenSSL::Cipher.new(alg)
      iv = OpenSSL::Cipher.new(alg).random_iv
      aes.encrypt
      aes.key = aes_key
      aes.iv = iv
      cipher = aes.update(padded_content)
      msg = iv + cipher
      return Base64.strict_encode64 msg
    end

    def decrypt_pin(msg)
      msg = Base64.strict_decode64 msg
      pin_token = Base64.decode64(configuration.pin_token)
      private_key = OpenSSL::PKey::RSA.new(configuration.private_key)
      iv = msg[0..15]
      cipher = msg[16..47]
      aes_key = JOSE::JWA::PKCS1::rsaes_oaep_decrypt('SHA256', pin_token, private_key, configuration.session_id)
      alg = "AES-256-CBC"
      decode_cipher = OpenSSL::Cipher.new(alg)
      decode_cipher.decrypt
      decode_cipher.iv = iv
      decode_cipher.key = aes_key
      plain = decode_cipher.update(cipher)
      return plain
    end
    
  end

end
