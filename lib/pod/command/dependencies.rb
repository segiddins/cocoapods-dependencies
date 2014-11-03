module Pod
  class Command
    class Dependencies < Command
      self.summary = "Show project's dependency graph."

      self.description = <<-DESC
        Shows the project's dependency graph.
      DESC

      def self.options
        [
          ['--ignore-lockfile', 'Whether the lockfile should be ignored when calculating the dependency graph'],
          ['--repo-update', 'Fetch external podspecs and run `pod repo update` before calculating the dependency graph'],
        ].concat(super)
      end

      def self.arguments
        [
          CLAide::Argument.new('PODSPEC', false)
        ].concat(super)
      end

      def initialize(argv)
        @podspec_name = argv.shift_argument
        @ignore_lockfile = argv.flag?('ignore-lockfile', false)
        @repo_update = argv.flag?('repo-update', false)
        super
      end

      def validate!
        super
        if @podspec_name
          require 'pathname'
          path = Pathname.new(@podspec_name)
          if path.exist?
            @podspec = Specification.from_file(path)
          else
            @podspec = SourcesManager.
              search(Dependency.new(@podspec_name)).
              specification.
              subspec_by_name(@podspec_name)
          end
        end
      end

      def run
        UI.title 'Dependencies' do
          require 'yaml'
          UI.puts dependencies.to_yaml
        end
      end

      def dependencies
        @dependencies ||= begin
          analyzer = Installer::Analyzer.new(
            sandbox,
            podfile,
            @ignore_lockfile ? nil : config.lockfile
          )

          integrate_targets = config.integrate_targets
          config.integrate_targets = false
          specs = analyzer.analyze(@repo_update).specs_by_target.values.flatten(1)
          config.integrate_targets = integrate_targets

          lockfile = Lockfile.generate(podfile, specs)
          pods = lockfile.to_hash['PODS']
        end
      end

      def podfile
        @podfile ||= begin
          if podspec = @podspec
            platform = podspec.available_platforms.first
            platform_name, platform_version = platform.name, platform.deployment_target.to_s
            sources = SourcesManager.all.map(&:url)
            Podfile.new do
              sources.each { |s| source s }
              platform platform_name, platform_version
              pod podspec.name
            end
          else
            verify_podfile_exists!
            config.podfile
          end
        end
      end

      def sandbox
        if @podspec
          require 'tmpdir'
          Sandbox.new(Dir.mktmpdir)
        else
          config.sandbox
        end
      end

    end
  end
end
