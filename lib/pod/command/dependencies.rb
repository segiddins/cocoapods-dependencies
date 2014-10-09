module Pod
  class Command
    class Dependencies < Command
      self.summary = "Show project's dependency graph."

      self.description = <<-DESC
        Shows the project's dependency graph.
      DESC

      def self.options
        [
          ['--ignore-lockfile', 'whether the lockfile should be ignored when calculating the dependency graph'],
        ].concat(super)
      end

      def initialize(argv)
        @ignore_lockfile = argv.flag?('ignore-lockfile', false)
        super
      end

      def run
        UI.section 'Project Dependencies' do
          STDOUT.puts dependencies.to_yaml
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
          specs = analyzer.analyze(true).specs_by_target.values.flatten(1)
          lockfile = Lockfile.generate(config.podfile, specs)
          pods = lockfile.to_hash['PODS']
        end
      end

    end
  end
end
