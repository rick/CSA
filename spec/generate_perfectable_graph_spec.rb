require "minitest/autorun"
require "tmpdir"

class DimacsGraph
  attr_reader :file, :output_dir, :current_line, :line_count
  attr_reader :problem_node_count, :problem_arc_count
  attr_reader :final_node_count, :final_arc_count
  attr_reader :seen_nodes, :seen_arcs

  def self.parse(graph_file, output_dir)
    parser = self.new
    parser.parse graph_file, output_dir
    parser
  end

  def initialize
  end

  def parse(graph_file, output_dir)
    @file       = graph_file
    @output_dir = output_dir

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

    validate_parsed_file # can throw exceptions
    merge_output_files
  end

  def line_error(message)
    raise "#{message} at [#{file}:#{line_count}]: [#{current_line}]"
  end

  def track_line(line)
    @current_line = line
    @line_count ||= 0
    @line_count += 1
  end

  def process_problem_line(line)
    line_error "Multiple problem lines seen" if seen_problem_line?
    line_error "Invalid problem line" unless line =~ /^p\s+asn\s+(\d+)\s+(\d+)\s*$/i

    @problem_node_count, @problem_arc_count = $1.to_i, $2.to_i
    @seen_problem_line = true

    output_problem
  end

  def output_problem
    @final_node_count = 2 * problem_node_count
    @final_arc_count  = 2 * problem_arc_count + problem_node_count
    problem_output_file.puts "p asn #{final_node_count} #{final_arc_count}"
  end

  def problem_output_file
    @problem_output_file ||= File.open(problem_output_path, 'w')
  end

  def problem_output_path
    File.join(output_dir, "problem_output.txt")
  end

  def seen_problem_line?
    !!@seen_problem_line
  end

  def process_comment_line(line)
    problem_output_file.puts line
  end

  def process_node_line(line)
    line_error "Invalid node line" unless line =~ /^n\s+(\d+)\s*$/i
    node_id = $1.to_i
    line_error "Node id exceeds node count (#{problem_node_count})" unless node_id <= problem_node_count
    output_node node_id
  end

  def output_node(node_id)
    register_seen_node node_id
    node_output_file.puts "n #{node_id}"
  end

  def node_output_file
    @node_output_file ||= File.open(node_output_path, 'w')
  end

  def node_output_path
    File.join(output_dir, "node_output.txt")
  end

  def register_seen_node(node_id)
    @seen_nodes ||= 0
    @seen_nodes += 1
  end

  def process_arc_line(line)
    line_error "Invalid arc line" unless match = %r{^a\s+(\d+)\s+(\d+)\s+([0-9.]+)\s*$}.match(line)
    source, dest, weight = match[1].to_i, match[2].to_i, match[3]
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

  def high_cost
    1000000
  end

  def augmented_node(node_id, &block)
    return if is_known_augmented_node? node_id
    register_seen_node node_id
    register_augmented_node node_id
    yield if block_given?
  end

  def is_known_augmented_node?(node_id)
    known_augmented_nodes.has_key?(node_id)
  end

  def register_augmented_node(node_id)
    known_augmented_nodes[node_id] = true
  end

  def known_augmented_nodes
    @known_augmented_nodes ||= {}
  end

  def output_arc(source, dest, weight)
    register_seen_arc source, dest, weight
    arc_output_file.puts "a #{source} #{dest} #{weight}"
  end

  def register_seen_arc(source, dest, weight)
    @seen_arcs ||= 0
    @seen_arcs += 1
  end

  def arc_output_file
    @arc_output_file ||= File.open(arc_output_path, 'w')
  end

  def arc_output_path
    File.join(output_dir, "arc_output.txt")
  end

  def validate_parsed_file
    raise "No problem line found" unless seen_problem_line?
    raise "Seen node count [#{seen_nodes}] does not match computed [#{final_node_count}]" unless seen_nodes == final_node_count
    raise "Seen node count [#{seen_arcs}] does not match computed [#{final_arc_count}]" unless seen_arcs == final_arc_count
  end

  def merge_output_files
    # TODO:
    # - close output files
    # - merge problem+comments, node line, arc line files into one output file
    # - return output file name
  end
end

def fixture_file(path)
  File.expand_path(File.join(File.dirname(__FILE__), "fixtures", path))
end

describe "parsing a DIMACS assignment problem graph file" do
  before do
    @basedir = Dir.mktmpdir
  end

  it "fails if the specified file cannot be read" do
    assert_raises(Errno::ENOENT) do
      parser = DimacsGraph.parse "/non/existent/file", @basedir
    end
  end

  it "fails if the file does not have a problem line" do
    assert_raises do
      parser = DimacsGraph.parse fixture_file("no-problem-line.txt"), @basedir
    end
  end

  it "fails if the file does not have an assignment problem line" do
    assert_raises do
      parser = DimacsGraph.parse fixture_file("invalid-problem-line.txt"), @basedir
    end
  end

  it "fails if the file contains an unrecognizeable line" do
    assert_raises do
      parser = DimacsGraph.parse fixture_file("unrecognizeable-line.txt"), @basedir
    end
  end

  it "fails if the file does not have the number of arcs listed in the problem line" do
    assert_raises do
      parser = DimacsGraph.parse fixture_file("arc-count-too-low.txt"), @basedir
    end

    assert_raises do
      parser = DimacsGraph.parse fixture_file("arc-count-too-high.txt"), @basedir
    end
  end

  it "fails if the file does not mention all the nodes listed in the problem line" do
    assert_raises do
      parser = DimacsGraph.parse fixture_file("node-count-too-low.txt"), @basedir
    end

    assert_raises do
      parser = DimacsGraph.parse fixture_file("node-count-too-high.txt"), @basedir
    end
  end

  it "fails if the file mentions a node higher than the count in the problem line" do
    assert_raises do
      parser = DimacsGraph.parse fixture_file("node-with-index-too-high-on-node-list.txt"), @basedir
    end

    assert_raises do
      parser = DimacsGraph.parse fixture_file("node-with-index-too-high-on-arc-list.txt"), @basedir
    end
  end

  it "can return the correct number of nodes from the file's problem line" do
    parser = DimacsGraph.parse fixture_file("10-node-graph.txt"), @basedir
    assert_equal 10, parser.problem_node_count
  end

  # it "can return the correct number of arcs from the file's problem line" do
  #   parser = DimacsGraph.parse
  #   assert_equal 20, parser.problem_arc_count
  # end
end

describe "writing a DIMACS file for an augmented graph with perfect matching" do
  it "generates the correct file"
  # TODO: there probably has to be some sorting or something to make this work right
end
