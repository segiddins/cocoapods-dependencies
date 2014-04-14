module Pod
  class Command
    class Spec
      class Dependencies < Spec
        self.summary = "Short description of cocoapods-dependencies."

        self.description = <<-DESC
          Longer description of cocoapods-dependencies.
        DESC

        self.arguments = 'NAME'

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          help! "A Pod name is required." unless @name
        end

        def run
          path = get_path_of_spec(@name)
          spec = Specification.from_file(path)
          UI.puts "Hello #{spec.name}"
        end
      end
    end
  end
end
