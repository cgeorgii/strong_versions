# frozen_string_literal: true

module StrongVersions
  class Config
    def initialize(path)
      @config = YAML.load_file(path) if File.exist?(path)

      validate_on_failure
    end

    def exceptions
      return [] unless @config

      @config.fetch('ignore', [])
    end

    def on_failure
      return 'raise' unless @config

      @config.fetch('on_failure', 'raise')
    end

    private

    def validate_on_failure
      expected = %w[warn raise]
      strategy = on_failure
      return strategy if expected.include?(strategy)

      raise Bundler::BundlerError,
            I18n.t(
              'strong_versions.errors.unknown_on_failure',
              on_failure: strategy, expected: expected
            )
    end
  end
end
