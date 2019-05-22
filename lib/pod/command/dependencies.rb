module Pod
  class Command
    class Dependencies < Command
      include Command::ProjectDirectory

      self.summary = "Show project's dependency graph."

      self.description = <<-DESC
        Shows the project's dependency graph.
      DESC

      def self.options
        [
          ['--ignore-lockfile', 'Whether the lockfile should be ignored when calculating the dependency graph'],
          ['--repo-update', 'Fetch external podspecs and run `pod repo update` before calculating the dependency graph'],
          ['--graphviz', 'Outputs the dependency graph in Graphviz format to <podspec name>.gv or Podfile.gv'],
          ['--image', 'Outputs the dependency graph as an image to <podspec name>.png or Podfile.png'],
          ['--use-podfile-targets', 'Uses targets from the Podfile'],
          ['--ranksep', 'If you use --image command this command will be useful. The gives desired rank separation, in inches. Example --ranksep==.75, default .75'],
          ['--nodesep', 'It is same as [--ranksep] command. Minimum space between two adjacent nodes in the same rank, in inches.Example --nodesep==.25, default .25'],
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
        @produce_graphviz_output = argv.flag?('graphviz', false)
        @produce_image_output = argv.flag?('image', false)
        @use_podfile_targets = argv.flag?('use-podfile-targets', false)
        @ranksep = argv.option('ranksep', '0.75')
        @nodesep = argv.option('nodesep', '0.25')
        super
      end

      def validate!
        super
        if @podspec_name
          require 'pathname'
          path = Pathname.new(@podspec_name)
          if path.file?
            @podspec = Specification.from_file(path)
          else
            sets = Config.
              instance.
              sources_manager.
              search(Dependency.new(@podspec_name))
            spec = sets && sets.specification
            @podspec = spec && spec.subspec_by_name(@podspec_name)
            raise Informative, "Cannot find `#{@podspec_name}`." unless @podspec
          end
        end
        if (@produce_image_output || @produce_graphviz_output) && Executable.which('dot').nil?
          raise Informative, 'GraphViz must be installed and `dot` must be in ' \
            '$PATH to produce image or graphviz output.'
        end
      end

      def run
        require 'yaml'
        UI.title "Calculating dependencies" do
          dependencies
        end
        graphviz_image_output if @produce_image_output
        graphviz_dot_output if @produce_graphviz_output
        yaml_output
      end

      def dependencies
        @dependencies ||= begin
          lockfile = config.lockfile unless @ignore_lockfile || @podspec

          if !lockfile || @repo_update
            analyzer = Installer::Analyzer.new(
              sandbox,
              podfile,
              lockfile
            )

            specs = config.with_changes(skip_repo_update: !@repo_update) do
              analyzer.analyze(@repo_update || @podspec).specs_by_target.values.flatten(1)
            end

            lockfile = Lockfile.generate(podfile, specs, {})
          end

          lockfile.to_hash['PODS']
        end
      end

      def podfile
        @podfile ||= begin
          if podspec = @podspec
            platform = podspec.available_platforms.first
            platform_name = platform.name
            platform_version = platform.deployment_target.to_s
            source_urls = Config.instance.sources_manager.all.map(&:url).compact
            Podfile.new do
              install! 'cocoapods', integrate_targets: false, warn_for_multiple_pod_sources: false
              source_urls.each { |u| source(u) }
              platform platform_name, platform_version
              pod podspec.name, podspec: podspec.defined_in_file
              target 'Dependencies'
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

      def graphviz_data
        @graphviz ||= begin
          require 'graphviz'
          graph = GraphViz::new(output_file_basename, :type => :digraph, :ranksep => @ranksep, :nodesep => @nodesep)

          if @use_podfile_targets
            unless @podspec
              podfile.target_definitions.values.each do |target|
                target_node = graph.add_node(target.name.to_s)
                if target.dependencies
                  target.dependencies.each do |dependency|
                    pod_node = graph.add_node(dependency.name.to_s)
                    graph.add_edge(target_node, pod_node)
                  end
                end
              end
            end
          else
            root = graph.add_node(output_file_basename)
            unless @podspec
              podfile_dependencies.each do |pod|
                pod_node = graph.add_node(pod)
                graph.add_edge(root, pod_node)
              end
            end
          end

          pod_to_dependencies.each do |pod, dependencies|
            pod_node = graph.add_node(sanitized_pod_name(pod))
            dependencies.each do |dependency|
              dep_node = graph.add_node(sanitized_pod_name(dependency))
              graph.add_edge(pod_node, dep_node)
            end
          end

          graph
        end
      end

      # Truncates the input string after a pod's name removing version requirements, etc.
      def sanitized_pod_name(name)
        Pod::Dependency.from_string(name).name
      end

      # Returns a Set of Strings of the names of dependencies specified in the Podfile.
      def podfile_dependencies
        Set.new(podfile.target_definitions.values.map { |t| t.dependencies.map { |d| d.name } }.flatten)
      end

      # Returns a [String: [String]] containing resolved mappings from the name of a pod to an array of the names of its dependencies.
      def pod_to_dependencies
        dependencies.map { |d| d.is_a?(Hash) ? d : { d => [] } }.reduce({}) { |combined, individual| combined.merge!(individual) }
      end

      # Basename to use for output files.
      def output_file_basename
        return 'Podfile' unless @podspec_name
        File.basename(@podspec_name, File.extname(@podspec_name))
      end

      def yaml_output
        UI.title 'Dependencies' do
          UI.puts YAMLHelper.convert(dependencies)
        end
      end

      def graphviz_image_output
        graphviz_data.output( :png => "#{output_file_basename}.png")
      end

      def graphviz_dot_output
        graphviz_data.output( :dot => "#{output_file_basename}.gv")
      end

    end
  end
end
