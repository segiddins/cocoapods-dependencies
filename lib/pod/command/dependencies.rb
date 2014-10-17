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

      def initialize(argv)
        @ignore_lockfile = argv.flag?('ignore-lockfile', false)
        @repo_update = argv.flag?('repo-update', false)
        super
      end

      def run
        UI.title 'Project Dependencies' do
          UI.puts dependencies.to_yaml
        end
      end

      def dependencies
        @dependencies ||= begin
          verify_podfile_exists!
          analyzer = Installer::Analyzer.new(
            config.sandbox,
            config.podfile,
            @ignore_lockfile ? nil : config.lockfile
          )
          config.integrate_targets.tap do |it|
            config.integrate_targets = false
            specs = analyzer.analyze(@repo_update).specs_by_target.values.flatten(1)
            config.integrate_targets = it
          end
          lockfile = Lockfile.generate(config.podfile, specs)
          pods = lockfile.to_hash['PODS']
        end
      end

    end
  end
end
