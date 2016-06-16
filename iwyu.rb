require "English"
require "formula"

# include-what-you-use needs access to headers included with LLVM 3.8, which
# is only present in Xcode version 7.0 or higher.
class Xcode70 < Requirement
  fatal true

  satisfy { MacOS::Xcode.version >= "7.0" }

  def message
    "Xcode 7.0 or newer is required for this package."
  end
end

# This formula provides an easy way to install include-what-you-use, a tool for
# automatically managing include directives within C and C++ projects. It will
# build and install include-what-you-use, symlink it as iwyu, and install a
# Python wrapper to automatically correct includes (fix_include).
class Iwyu < Formula
  # iwyu 0.6 based on clang 3.8
  CLANG_VERSION = "3.8".freeze

  version "0.6"
  homepage "http://include-what-you-use.org"
  url "http://include-what-you-use.org/downloads/" \
      "include-what-you-use-#{version}-x86_64-apple-darwin.tar.gz"
  sha256 "46a7e579ad17441ba8b23fe105400565ff978cc61957c19291563912d1f4638d"

  depends_on Xcode70

  def install
    # include-what-you-use needs lib and include directories one level
    # up from its bindir, but putting them in the homebrew directories
    # results in them getting linked in /usr (interfering with e.g. the
    # /usr/local/include dirs added by gcc).
    #
    # To solve this, we put iwyu in a custom dir and make bin links.
    iwyu_subdir_path = (prefix / "iwyu")
    iwyu_subdir_path.mkpath

    clang_version = `clang --version`.each_line.first
    apple_llvm_version = clang_version[/\AApple LLVM version (\d+(?:\.\d+)+)/, 1]

    clang_libs = "#{MacOS::Xcode.toolchain_path}/usr/lib/clang/#{apple_llvm_version}"
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

    iwyu_bindir.install("bin/fix_includes.py" => "fix_include")
    iwyu_bindir.install("bin/include-what-you-use")
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
