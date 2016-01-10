require "minitest/autorun"
require "tmpdir"

class DimacsGraph
  attr_reader :file, :output_dir, :current_line, :line_count
  attr_reader :problem_node_count, :problem_arc_count
  attr_reader :final_node_count, :final_arc_count
  attr_reader :seen_nodes, :seen_arcs
  attr_reader :results_path

  # Process a DimacsGraph file and generate an augmented graph file.
  def self.process(graph_file, output_dir)
    processor = self.new
    processor.process graph_file, output_dir
    processor
  end

  # Create an instance of the Dimacs Graph processor class; no arguments necessary.
  def initialize
  end

  # Process the graph data located in the `graph_file` file, using `output_dir`
  # as a workspace, and for storage of the final augmented graph file.
  #
  # Returns the path to the augmented graph file.
  def process(graph_file, output_dir)
    raise ArgumentError, "process expects a graph file and an output path" unless graph_file && output_dir
    @file, @output_dir = graph_file, output_dir

    File.open(file) do |f|
      f.each_line do |line|
        track_line line

        case line
        when /^a\s+/i
          process_arc_line line
        when /^n\s+/i
          process_node_line line
        when /^c\s+/i
          process_comment_line line
        when /^p\s+/i
          process_problem_line line
        else
          line_error "Unrecognized line"
        end
      end
    end

    validate_processed_file # can throw exceptions
    merge_output_files
  end

  # Raise an error message, including the current line and line offset on the
  # input graph file.
  def line_error(message)
    raise "#{message} at [#{file}:#{line_count}]: [#{current_line}]"
  end

  # Keep track of the current line in the graph input file (for error message generation).
  def track_line(line)
    @current_line = line
    @line_count ||= 0
    @line_count += 1
  end

  # Handle a "problem line" from the input graph file.
  def process_problem_line(line)
    line_error "Multiple problem lines seen" if seen_problem_line?
    line_error "Invalid problem line" unless line =~ /^p\s+asn\s+(\d+)\s+(\d+)\s*$/i

    @problem_node_count, @problem_arc_count = $1.to_i, $2.to_i
    @seen_problem_line = true

    output_problem
  end

  # Output a "problem line" to the problem output working file.
  def output_problem
    @final_node_count = 2 * problem_node_count
    @final_arc_count  = 2 * problem_arc_count + problem_node_count
    problem_output_file.puts "p asn #{final_node_count} #{final_arc_count}"
  end

  # Return the file handle for the problem output working file.
  def problem_output_file
    @problem_output_file ||= File.open(problem_output_path, 'w')
  end

  # Return the location of the problem output working file (accumulates problem line + comment lines).
  def problem_output_path
    File.join(output_dir, "problem_output.txt")
  end

  # Have we already seen a problem line in this input file?
  def seen_problem_line?
    !!@seen_problem_line
  end

  # Handle a "comment line" from the input graph file.
  def process_comment_line(line)
    problem_output_file.puts line
  end

  # Handle a "node line" from the input graph file.
  def process_node_line(line)
    line_error "Invalid node line" unless line =~ /^n\s+(\d+)\s*$/i
    node_id = $1.to_i
    line_error "Node line seen before problem line" unless problem_node_count
    line_error "Node id exceeds node count (#{problem_node_count})" unless node_id <= problem_node_count
    output_node node_id
  end

  # Output a "node line" to the node output working file.
  def output_node(node_id)
    register_seen_node node_id
    node_output_file.puts "n #{node_id}"
  end

  # Return the file handle for the node output working file.
  def node_output_file
    @node_output_file ||= File.open(node_output_path, 'w')
  end

  # Return the location of the node output working file (accumulates node lines).
  def node_output_path
    File.join(output_dir, "node_output.txt")
  end

  # Register that we have seen a new node.
  #
  # (Currently only tracks node counts, but could track individual nodes.)
  def register_seen_node(node_id)
    @seen_nodes ||= 0
    @seen_nodes += 1
  end

  # Handle an "arc line" from the input graph file.
  def process_arc_line(line)
    line_error "Invalid arc line" unless match = %r{^a\s+(\d+)\s+(\d+)\s+([0-9.]+)\s*$}.match(line)
    source, dest, weight = match[1].to_i, match[2].to_i, match[3]
    line_error "Arc line seen before problem line" unless problem_node_count
    line_error "Source node is outside max node range (#{problem_node_count})" if source > problem_node_count
    line_error "Destination node is outside max node range (#{problem_node_count})" if dest > problem_node_count

    # add original arc line to output arc list (s -> d), with original weight w
    output_arc source, dest, weight

    # if source has not been mirrored as an augmented node yet
    augmented_node(source + problem_node_count) do # add (source+n) as a known augmented node
      # do not add (source+n) to the output node source list (because it is only a destination)
      # add a high-cost arc from source to augmented source: source -> source + n
      output_arc source, source + problem_node_count, high_cost
    end

    # if dest has not been mirrored as an augmented node yet
    augmented_node(dest + problem_node_count) do  # add (dest+n) as a known augmented node
      # add (dest+n) to the output source list
      output_node dest + problem_node_count

      # add a high-cost arc from augmented node (d+n) to original dest node (d): d+n -> d
      output_arc dest + problem_node_count, dest, high_cost
    end

    # add an arc from augmented source (dest+n) to augmented dest (source+n)
    output_arc dest + problem_node_count, source + problem_node_count, weight
  end

  # What do we output for a high cost node?
  #
  # TODO: this should be configurable by the caller
  def high_cost
    1000000000
  end

  # Allow registering new "augmented nodes".
  #
  # If the provided `node_id` has already been seen as an augmented node, then do nothing;
  # otherwise, track that this is an augmented node, and also run the provided block.
  def augmented_node(node_id, &block)
    return if is_known_augmented_node? node_id
    register_seen_node node_id
    register_augmented_node node_id
    yield if block_given?
  end

  # Has this `node_id` been seen before, as an augmented node?
  def is_known_augmented_node?(node_id)
    known_augmented_nodes.has_key?(node_id)
  end

  # Mark that this `node_id` has been seen before as an augmented node.
  def register_augmented_node(node_id)
    known_augmented_nodes[node_id] = true
  end

  # Return the `Hash` of known augmented nodes.
  def known_augmented_nodes
    @known_augmented_nodes ||= {}
  end

  # Output an "arc line" to the arc output working file.
  def output_arc(source, dest, weight)
    register_seen_arc source, dest, weight
    arc_output_file.puts "a #{source} #{dest} #{weight}"
  end

  # Mark that we have seen a new arc.
  #
  # (Currently only tracks arc counts, but could track individual arcs.)
  def register_seen_arc(source, dest, weight)
    @seen_arcs ||= 0
    @seen_arcs += 1
  end

  # Return the file handle for the arc output working file.
  def arc_output_file
    @arc_output_file ||= File.open(arc_output_path, 'w')
  end

  # Return the location of the arc output working file (accumulated arc lines).
  def arc_output_path
    File.join(output_dir, "arc_output.txt")
  end

  # Verify that the fully processed graph input file is well-formed.
  #
  # Raises RuntimeError when graph file is found to be invalid.
  def validate_processed_file
    raise "No problem line found" unless seen_problem_line?
    raise "Seen node count [#{seen_nodes}] does not match computed [#{final_node_count}]" unless seen_nodes == final_node_count
    raise "Seen node count [#{seen_arcs}] does not match computed [#{final_arc_count}]" unless seen_arcs == final_arc_count
  end

  # Close all open output files.
  def close_output_files
    problem_output_file.close
    node_output_file.close
    arc_output_file.close
  end

  # Merge working files into final augmented graph file.
  def merge_output_files
    @results_path = File.join(output_dir, "augmented_graph.txt")
    close_output_files
    system "cat #{problem_output_path} #{node_output_path} #{arc_output_path} > #{results_path}" # NOTE: not particularly portable
    results_path
  end
end

#
# Tests
#

# Return the path to a named fixture file.
def fixture_file(name)
  File.expand_path(File.join(File.dirname(__FILE__), "fixtures", name))
end

# Return a normalized version of a graph file, suitable for test comparison.
def normalize_graph_file(contents)
  contents.lines.map {|l| l.chomp.gsub(/\s+/, ' ') }.sort.join("\n")
end

describe "parsing a DIMACS assignment problem graph file" do
  before do
    @basedir = Dir.mktmpdir
  end

  it "fails if the specified file cannot be read" do
    assert_raises(Errno::ENOENT) do
      process = DimacsGraph.process "/non/existent/file", @basedir
    end
  end

  it "fails if the file does not have a problem line" do
    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("no-problem-line.txt"), @basedir
    end
  end

  it "fails if the file does not have an assignment problem line" do
    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("invalid-problem-line.txt"), @basedir
    end
  end

  it "fails if the file contains an unrecognizeable line" do
    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("unrecognizeable-line.txt"), @basedir
    end
  end

  it "fails if the file does not have the number of arcs listed in the problem line" do
    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("arc-count-too-low.txt"), @basedir
    end

    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("arc-count-too-high.txt"), @basedir
    end
  end

  it "fails if the file does not mention all the nodes listed in the problem line" do
    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("node-count-too-low.txt"), @basedir
    end

    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("node-count-too-high.txt"), @basedir
    end
  end

  it "fails if the file mentions a node higher than the count in the problem line" do
    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("node-with-index-too-high-on-node-list.txt"), @basedir
    end

    assert_raises RuntimeError do
      process = DimacsGraph.process fixture_file("node-with-index-too-high-on-arc-list.txt"), @basedir
    end
  end

  it "can return the correct number of nodes from the file's problem line" do
    process = DimacsGraph.process fixture_file("10-node-graph.txt"), @basedir
    assert_equal 10, process.problem_node_count
  end

  it "can return the correct number of arcs from the file's problem line" do
    process = DimacsGraph.process fixture_file("10-node-graph.txt"), @basedir
    assert_equal 20, process.problem_arc_count
  end

  it "generates the correct file" do
    [ "3-node-graph", "5-node-fan-graph", "10-node-graph" ].each do |path|
      input_file    = fixture_file("#{path}.txt")
      expected_file = fixture_file("#{path}-augmented.txt")

      process = DimacsGraph.process input_file, @basedir
      expected = normalize_graph_file(File.read(expected_file))
      actual   = normalize_graph_file(File.read(process.results_path))
      assert_equal expected, actual,
        "Result path did not match. Input file [#{input_file}], " +
        "expected file [#{expected_file}], output file [#{process.results_path}]\n" +
        "\n\noutput:\n\n#{File.read(process.results_path)}"
    end
  end
end
