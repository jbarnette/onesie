require "hoe"

Hoe.plugin :doofus, :isolate, :git

Hoe.spec "onesie" do
  developer "John Barnette", "code@jbarnette.com"

  self.extra_rdoc_files = Dir["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"
  self.testlib          = :minitest

  extra_deps << ["rack", ">= 1.2"]
end
