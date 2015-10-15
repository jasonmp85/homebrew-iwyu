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
    # include-what-you-use needs lib and include directories one level
    # up from its bindir, but putting them in the homebrew directories
    # results in them getting linked in /usr (interfering with e.g. the
    # /usr/local/include dirs added by gcc).
    #
    # To solve this, we put iwyu in a custom dir and make bin links.
    iwyu_subdir_path = (prefix / "iwyu")
    iwyu_subdir_path.mkpath

    xcode_maj_min_version = MacOS::Xcode.version[/\A\d+\.\d+/, 0]
    clang_libs = "#{MacOS::Xcode.toolchain_path}/usr/lib/clang/" \
                 "#{xcode_maj_min_version}.0"
    cpp_includes = "#{MacOS::Xcode.toolchain_path}/usr/include/c++"

    iwyu_bindir = (iwyu_subdir_path / "bin")
    iwyu_libdir = (iwyu_subdir_path / "lib")
    iwyu_includes = (iwyu_subdir_path / "include")

    iwyu_bindir.mkpath
    iwyu_libdir.mkpath
    iwyu_includes.mkpath

    iwyu_clang_lib_path = (iwyu_libdir / "clang")
    iwyu_clang_lib_path.mkpath
    iwyu_clang_lib_path.install_symlink(clang_libs => "#{Iwyu::CLANG_VERSION}.0")

    iwyu_includes.install_symlink(cpp_includes => "c++")

    iwyu_bindir.install("fix_includes.py" => "fix_include")
    iwyu_bindir.install("include-what-you-use")
    iwyu_bindir.install_symlink("include-what-you-use" => "iwyu")

    bin.install_symlink Dir["#{iwyu_bindir}/*"]
  end

  test do
    # write out a header and a C++ file relying on transitive dependencies
    (testpath / "demo.hpp").write <<-EOS.undent
    #include <stdio.h>
    #include <stdarg.h>
    #include <locale>
    EOS

    (testpath / "demo.cpp").write <<-EOS.undent
    #include "demo.hpp"

    int main(void)
    { printf("hello world"); }
    EOS

    # iwyu exits with a code equal to the number of suggested edits + 2
    fixes = shell_output "iwyu #{testpath}/demo.cpp 2>&1", 6
    assert_not_match(/file not found/, fixes)

    # pass the output to the fixer script and assert that it fixed two files
    results = pipe_output "fix_include", fixes
    assert_match(/IWYU edited 2 files/, results)

    # sigh. they use the status code to signal how many files were edited
    assert_equal 2, $CHILD_STATUS.exitstatus
  end

  def caveats; <<-EOS.undent
    This package will break after an Xcode upgrade. Fixing it is as simple as:
      brew reinstall iwyu
    EOS
  end
end
