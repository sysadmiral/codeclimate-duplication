require 'spec_helper'
require 'cc/engine/analyzers/python/main'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

RSpec.describe CC::Engine::Analyzers::Python::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue for identical code" do
      create_source_file("foo.py", <<-EOJS)
print("Hello", "python")
print("Hello", "python")
print("Hello", "python")
      EOJS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Identical code found in 2 other locations (mass = 6)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(1_600_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} }
      ])
      expect(json["content"]["body"]).to match /This issue has a mass of 6/
      expect(json["fingerprint"]).to eq("3f3d34361bcaef98839d9da6ca9fcee4")
    end

    it "prints an issue for similar code" do
      create_source_file("foo.py", <<-EOJS)
print("Hello", "python")
print("Hello It's me", "python")
print("Hello from the other side", "python")
      EOJS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Similar code")
      expect(json["description"]).to eq("Similar code found in 2 other locations (mass = 6)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(1_600_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} }
      ])
      expect(json["content"]["body"]).to match /This issue has a mass of 6/
      expect(json["fingerprint"]).to eq("019118ceed60bf40b35aad581aae1b02")
    end


    it "skips unparsable files" do
      create_source_file("foo.py", <<-EOPY)
        ---
      EOPY

      expect {
        expect(run_engine(engine_conf)).to eq("")
      }.to output(/Skipping file/).to_stderr
    end
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      "config" => {
        "languages" => {
          "python" => {
            "mass_threshold" => 4
          }
        }
      }
    })
  end
end
