require "English"
require "formula"

# include-what-you-use needs access to headers included with LLVM 3.5, which
# is only present in Xcode version 6.1 or higher.
class Xcode61 < Requirement
  fatal true

  satisfy { MacOS::Xcode.version >= "6.1" }

  def message
    "Xcode 6.1 or newer is required for this package."
  end
end

# This formula provides an easy way to install include-what-you-use, a tool for
# automatically managing include directives within C and C++ projects. It will
# build and install include-what-you-use, symlink it as iwyu, and install a
# Python wrapper to automatically correct includes (fix_include).
class Iwyu < Formula
  # iwyu 0.4 based on clang 3.6
  CLANG_VERSION = "3.6"

  version "0.4"
  homepage "http://include-what-you-use.org"
  url "http://include-what-you-use.org/downloads/" \
      "include-what-you-use-#{version}-x86_64-apple-darwin.tar.gz"
  sha256 "41d7434545cb0c55acd9db0b1b66058ffbe88f3c3b79df4e3f649d54aabbbc7b"

  depends_on Xcode61

  def install
    xcode_maj_min_version = MacOS::Xcode.version[/\A\d+\.\d+/, 0]
    clang_libs = "#{MacOS::Xcode.toolchain_path}/usr/lib/clang/" \
                 "#{xcode_maj_min_version}.0"
    iwyu_clang_path = (lib / "clang")

    iwyu_clang_path.mkpath
    iwyu_clang_path.install_symlink(clang_libs => "#{Iwyu::CLANG_VERSION}.0")

    bin.install("fix_includes.py" => "fix_include")
    bin.install("include-what-you-use")
    bin.install_symlink("include-what-you-use" => "iwyu")
  end

  test do
    # write out a header and a C file relying on transitive dependencies
    (testpath / "demo.h").write("#include <stdio.h>")
    (testpath / "demo.c").write <<-EOS.undent
    #include "demo.h"

    int main(void)
    { printf("hello world"); }
    EOS

    # iwyu exits with a code equal to the number of suggested edits + 2
    fixes = shell_output "iwyu #{testpath}/demo.c 2>&1", 4

    # pass the output to the fixer script and assert that it fixed one file
    results = pipe_output "fix_include", fixes

    assert_match(/IWYU edited 1 file/, results)

    # sigh. they use the status code to signal how many files were edited
    assert_equal 1, $CHILD_STATUS.exitstatus
  end

  def caveats; <<-EOS.undent
    This package will break after an Xcode upgrade. Fixing it is as simple as:
      brew reinstall iwyu
    EOS
  end
end
