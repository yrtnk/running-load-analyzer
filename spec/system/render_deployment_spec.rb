require "rails_helper"

RSpec.describe "Render deployment configuration" do
  describe "render.yaml" do
    let(:render_yaml_path) { Rails.root.join("render.yaml") }
    let(:render_config) { YAML.safe_load(render_yaml_path.read) }

    it "exists" do
      expect(render_yaml_path).to exist
    end

    it "defines a web service" do
      web_service = render_config["services"].find { |s| s["type"] == "web" }
      expect(web_service).to be_present
    end

    it "defines a database" do
      expect(render_config["databases"]).to be_present
    end

    it "sets DATABASE_URL from the database" do
      web_service = render_config["services"].find { |s| s["type"] == "web" }
      db_url_env = web_service["envVars"].find { |e| e["key"] == "DATABASE_URL" }
      expect(db_url_env).to be_present
      expect(db_url_env["fromDatabase"]).to be_present
    end

    it "marks RAILS_MASTER_KEY as sync: false (must be set manually)" do
      web_service = render_config["services"].find { |s| s["type"] == "web" }
      master_key_env = web_service["envVars"].find { |e| e["key"] == "RAILS_MASTER_KEY" }
      expect(master_key_env).to be_present
      expect(master_key_env["sync"]).to be false
    end
  end

  describe "bin/render-build.sh" do
    let(:build_script_path) { Rails.root.join("bin/render-build.sh") }

    it "exists" do
      expect(build_script_path).to exist
    end

    it "is executable" do
      expect(File.executable?(build_script_path)).to be true
    end

    it "runs db:migrate" do
      expect(build_script_path.read).to include("db:migrate")
    end

    it "runs assets:precompile" do
      expect(build_script_path.read).to include("assets:precompile")
    end
  end

  describe "Procfile" do
    let(:procfile_path) { Rails.root.join("Procfile") }

    it "exists" do
      expect(procfile_path).to exist
    end

    it "defines the web process with puma" do
      expect(procfile_path.read).to match(/^web:.*puma/)
    end
  end

  describe "database.yml production config" do
    let(:db_config) { YAML.safe_load(Rails.root.join("config/database.yml").read, permitted_classes: [], permitted_symbols: [], aliases: true) }

    it "uses DATABASE_URL for production" do
      expect(db_config["production"]["url"]).to include("DATABASE_URL")
    end
  end
end
