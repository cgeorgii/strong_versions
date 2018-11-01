# frozen_string_literal: true

module StrongVersions
  class Dependency
    attr_reader :name, :errors

    def initialize(dependency)
      @dependency = dependency
      @name = dependency.name
      @errors = []

      versions.each do |operator, version|
        validate_version(operator, version)
      end
    end

    def valid?
      @errors.empty?
    end

    private

    def versions
      @dependency.requirements_list.map do |requirement|
        parse_version(requirement)
      end
    end

    def parse_version(requirement)
      operator, version_obj = Gem::Requirement.parse(requirement)
      if version_obj.respond_to?(:version)
        # Ruby >= 2.3.0: `version_obj` is a `Gem::Version`
        [operator, version_obj.version]
      else
        # Ruby < 2.3.0: `version_obj` is a `String`
        [operator, version_obj]
      end
    end

    def validate_version(operator, version)
      return if path_source?
      return if any_valid?

      check_pessimistic(operator)
      check_valid_version(version)
    end

    def check_pessimistic(operator)
      return if pessimistic?(operator)

      @errors << { type: :operator, value: operator }
    end

    def check_valid_version(version)
      return if valid_version?(version)

      version = I18n.t('version_not_specified') if version == '0'
      @errors << { type: :version, value: version }
    end

    def pessimistic?(operator)
      operator == '~>'
    end

    def valid_version?(version)
      return true if version =~ /^[1-9][0-9]*\.\d+$/ # major.minor, e.g. "2.5"
      return true if version =~ /^0\.\d+\.\d+$/ # 0.minor.patch, e.g. "0.1.8"

      false
    end

    def any_valid?
      versions.any? do |operator, version|
        pessimistic?(operator) && valid_version?(version)
      end
    end

    def path_source?
      # Bundler::Source::Git inherits from Bundler::Source::Path so git sources
      # will also return `true`.
      @dependency.source.is_a?(Bundler::Source::Path)
    end

    def pessimistic_with_upper_bound?(operator)
      any_pessimistic? && %w[< <=].include?(operator)
    end

    def any_pessimistic?
      versions.any? do |_version, operator|
        %w[< <= ~>].include?(operator)
      end
    end
  end
end
