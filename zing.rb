class Zing < Formula
  desc "Modern directory jumper with a visual-first TUI"
  homepage "https://github.com/ydah/zing"
  url "https://github.com/ydah/zing/archive/refs/tags/v0.1.1.tar.gz"
  version "0.1.1"
  sha256 "515091dd02bb497cd4c22d80b09737e3b210fe06f6a06306d1d9f9d110231dc5"
  license "MIT"

  depends_on "zig"

  resource "libvaxis" do
    url "https://github.com/rockorager/libvaxis/archive/75035b169e91a51c233f3742161f8eb8eafca659.tar.gz"
    sha256 "41a9c6d9b7c839a4dfea48a8754f4513a07fb49dca53126e65e06597b76ea2a9"
  end

  resource "sqlite-zig" do
    url "https://github.com/vrischmann/zig-sqlite/archive/0b75ba276d34de3141ec1697e3ef7c836d7b38e7.tar.gz"
    sha256 "93d833b75c0a99499f8cfdc01e303ea340e7a47f3349bbac1bb8761c2670e326"
  end

  def install
    stage_dep = lambda do |name, dest|
      rm_r dest if dest.exist?
      dest.mkpath
      resource(name).stage do
        entries = Dir["*"]
        if entries.length == 1 && File.directory?(entries[0])
          dest.install Dir["#{entries[0]}/*"]
        else
          dest.install entries
        end
      end
    end

    stage_dep.call("libvaxis", buildpath/"vendor/libvaxis")
    stage_dep.call("sqlite-zig", buildpath/"vendor/sqlite-zig")
    rm_r buildpath/"vendor/sqlite-zig/src" if (buildpath/"vendor/sqlite-zig/sqlite.zig").exist? &&
      (buildpath/"vendor/sqlite-zig/src").exist?

    # Use vendored deps to avoid network access during build.
    inreplace "build.zig.zon" do |s|
      s.gsub!(%r{\.libvaxis = \.\{.*?\},\n}m, ".libvaxis = .{ .path = \"vendor/libvaxis\" },\n")
      s.gsub!(%r{\.@\"sqlite-zig\" = \.\{.*?\},\n}m, ".@\"sqlite-zig\" = .{ .path = \"vendor/sqlite-zig\" },\n")
    end

    system "zig", "build", "-Doptimize=ReleaseFast", "--prefix", prefix, "install"
    man1.install "zing.1"
  end

  test do
    system "#{bin}/zing", "--help"
  end
end
