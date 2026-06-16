# frozen_string_literal: true

# Injects the DASHBOARD_SCRIPTS loader into Chatwoot by automating the super_admin
# panel over HTTP (Chatwoot exposes no API for installation configs; they are
# super-admin only). Credentials are passed transiently and never stored.
#
# Returns { ok: true } or { error: '...' }. Never raises — a failure here must not
# break the Chatwoot integration setup (the script can still be pasted manually).
class Accounts::Apps::Chatwoots::InjectDashboardScript
  CONFIG_NAME = 'DASHBOARD_SCRIPTS'

  def self.call(chatwoot:, super_admin_email:, super_admin_password:, script:)
    new(chatwoot, super_admin_email, super_admin_password, script).call
  end

  def initialize(chatwoot, email, password, script)
    @base = chatwoot.chatwoot_endpoint_url
    @email = email
    @password = password
    @script = script
    @cookies = {}
  end

  def call
    return { error: 'missing_credentials' } if @email.blank? || @password.blank?

    csrf = csrf_from('/super_admin/sign_in')
    return { error: 'sign_in_unreachable' } if csrf.blank?

    sign_in(csrf)
    config_id = find_config_id
    return { error: 'config_not_found' } if config_id.blank?

    edit_csrf = csrf_from("/super_admin/installation_configs/#{config_id}/edit")
    return { error: 'unauthorized' } if edit_csrf.blank?

    update(config_id, edit_csrf)
  rescue StandardError => e
    Rails.logger.error("InjectDashboardScript failed: #{e.message}")
    { error: e.message }
  end

  private

  def conn
    @conn ||= Faraday.new(url: @base)
  end

  def merge_cookies(response)
    Array(response.headers['set-cookie']).each do |header|
      header.split(/,(?=[^;]+=)/).each do |part|
        name, value = part.split(';').first.to_s.strip.split('=', 2)
        @cookies[name] = value if name.present? && value
      end
    end
  end

  def cookie_header
    @cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
  end

  def csrf_from(path)
    response = conn.get(path) { |r| r.headers['Cookie'] = cookie_header }
    merge_cookies(response)
    response.body[/name="csrf-token" content="([^"]+)"/, 1] ||
      response.body[/name="authenticity_token"[^>]*value="([^"]+)"/, 1]
  end

  def sign_in(csrf)
    response = conn.post('/super_admin/sign_in') do |r|
      r.headers['Cookie'] = cookie_header
      r.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      r.body = URI.encode_www_form('super_admin[email]' => @email, 'super_admin[password]' => @password,
                                   'authenticity_token' => csrf)
    end
    merge_cookies(response)
  end

  def find_config_id
    response = conn.get("/super_admin/installation_configs?search=#{CONFIG_NAME}") do |r|
      r.headers['Cookie'] = cookie_header
    end
    merge_cookies(response)
    response.body[%r{installation_configs/(\d+)/edit}, 1] || response.body[%r{installation_configs/(\d+)}, 1]
  end

  def update(config_id, csrf)
    response = conn.post("/super_admin/installation_configs/#{config_id}") do |r|
      r.headers['Cookie'] = cookie_header
      r.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      r.body = URI.encode_www_form('_method' => 'patch', 'authenticity_token' => csrf,
                                   'installation_config[name]' => CONFIG_NAME,
                                   'installation_config[value]' => @script)
    end
    [200, 302].include?(response.status) ? { ok: true } : { error: "update_failed_#{response.status}" }
  end
end
