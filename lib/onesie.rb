require "rack/request"

# For any request path that doesn't match <tt>options[:path]</tt>,
# immediately redirect to <tt>#{options[:path]}/#/#{request-path}</tt>
# after dropping the original request path in the session. For any
# request that comes in, matches <tt>options[:path]</tt>, and has a
# request-path in the session, rewrite the request to match the path
# info in the session, remove the session copy, and allow the app to
# route/handle as normal.

class Onesie

  # Duh.
  VERSION = "1.0.0"

  attr_reader :except, :only, :path

  # Create a new instance of this middleware. +app+ (required) is the
  # Rack application we're wrapping. Valid +options+:
  #
  #     :except  # An Array of prefix strings or Regexps to ignore.
  #     :log     # A lambda for logging, takes one message arg.
  #     :only    # An array of prefix strings or Regexps to require.
  #     :path    # The correct path for the one-page app. Default: "/"

  def initialize app, options = {}
    @app    = app
    @except = Array(options[:except]).map { |e| regexpify e }
    @log    = options[:log]
    @only   = Array(options[:only]).map   { |o| regexpify o }
    @path   = options[:path] || "/"

    if FalseClass === @log
      @log = lambda { |m| }
    elsif !@log
      if defined? Rails
        @log = lambda { |m| Rails.logger.info "  [Onesie] #{m}" }
      else
        @log = lambda { |m| puts "[Onesie] #{m}" }
      end
    end
  end

  def call env
    request = Rack::Request.new env
    session = env["rack.session"]

    session.delete "onesie.path" if /onesie.clear/ =~ env["REQUEST_URI"]

    allowed = only.empty? || only.any? { |o| o =~ request.path_info }
    denied  = except.any? { |e| e =~ request.path_info }

    return @app.call env if request.xhr? || !allowed || denied

    if request.path_info == @path
      path = session.delete("onesie.path") || "/"
      old_path_info = request.path_info

      env["PATH_INFO"] = env["onesie.path"] = path
      env["REQUEST_URI"].sub!(/^#{old_path_info}/, path)

      @log.call "actual path is #{path}"
      return @app.call env
    end

    session["onesie.path"] = dest = request.path_info
    request.path_info = @path
    request.path_info << "/" unless "/" == request.path_info[-1, 1]

    dest = request.url + "##{dest}"
    @log.call "redirecting to #{dest}"

    [302, { "Location" => dest }, "Redirecting."]
  end

  protected

  def regexpify thing
    Regexp === thing ? thing : /^#{Regexp.escape thing}/
  end
end
