module Pod
  class Command
    class Dependencies < Command
      self.summary = "Show project's dependency graph."

      self.description = <<-DESC
        Shows the project's dependency graph.
      DESC

      def run
        verify_podfile_exists!
        UI.section 'Project Dependencies' do
          STDOUT.puts dependencies.to_yaml
        end
      end

      def dependencies
        @dependencies ||= begin
          podfile = config.podfile
          resolver = Resolver.new(config.sandbox, podfile, config.lockfile.dependencies)
          specs = resolver.resolve.values.flatten(1).uniq
          lockfile = Lockfile.generate(podfile, specs)
          pods = lockfile.to_hash['PODS']
        end
      end

    end
  end
end
