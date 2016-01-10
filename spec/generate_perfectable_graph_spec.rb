require "minitest/autorun"

class DimacsGraph
  attr_reader :file
  attr_reader :output_dir
  attr_reader :line_count
  attr_reader :problem_node_count
  attr_reader :problem_arc_count

  def self.parse(graph_file, output_dir)
    parser = self.new
    parser.parse graph_file, output_dir
    parser
  end

  def initialize
  end

  def increment_line_count
    @line_count ||= 0
    @line_count += 1
  end

  def parse(graph_file, output_dir)
    @file       = graph_file
    @output_dir = output_dir

    File.open(file) do |f|
      f.each_line do |line|
        increment_line_count

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
          raise "Unrecognized line (@ #{line_count}): #{line} in input file [#{file}]"
        end
      end
    end

    validate_parsed_file # can throw exceptions
    merge_output_files
  end

  def process_arc_line(line)
    # TODO:
    # - validate format of line
    # - fail if source or dest node #s are greater than problem line node count
    # - open up node line output file if not open
    # - open up arc line output file if not open
    # - add original arc line to output arc list (s -> d), with original weight w
    # - if source node (s) hasn't been seen as an augmented node already:
    #   - do not add s to the output node source list (because it is a dest)
    #   - add a high-cost arc from source (s) to augmented dest (s+n): s -> s+n
    # - if dest node (d) hasn't been seen as an augmented node (d+n) already:
    #   - add d to the output node source list as an augmented node (d+n)
    #   - add a high-cost arc from augmented node (d+n) to original dest node (d): d+n -> d
    # - add an arc from augmented source (d+n) to augmented dest (s+n): d+n -> s+n, with weight w
  end

  def node_output_path
    File.join(output_dir, "node_output.txt")
  end

  def node_output_file
    @node_output_file ||= File.open(node_output_path, 'w')
  end

  def process_node_line(line)
    raise "Invalid node line at line #{line_count}: [#{line}]" unless line =~ /^n\s+(\d+)\s*$/i
    node_id = $1.to_i
    raise "Node id exceeds node count (#{problem_node_count}) at line #{line_count}: [#{line}]" unless node_id <= problem_node_count
    node_output_file.puts "n #{node_id}"
  end

  def process_comment_line(line)
    # TODO:
    # - open up problem definition / comments file if necessary
    # - handle comment lines by writing them to the problem/comment line file
  end

  def seen_problem_line?
    !!@seen_problem_line
  end

  def process_problem_line(line)
    raise "Multiple problem lines seen at line #{line_count}: [#{line}]" if seen_problem_line?
    raise "Invalid problem line: [#{line}]" unless line =~ /^p\s+asn\s+(\d+)\s+(\d+)\s*$/i
    @problem_node_count, @problem_arc_count = $1.to_i, $2.to_i
    @seen_problem_line = true

    # TODO:
    # - open up problem definition / comments file if necessary
    # - write the future correct problem line
  end

  def validate_parsed_file
    # TODO: exactly one problem line with correct value
    # TODO: final node counts
    # TODO: final arc counts
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
    @basedir = '/tmp'
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
