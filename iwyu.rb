require 'English'
require 'formula'

# This formula provides an easy way to install include-what-you-use, a tool for
# automatically managing include directives within C and C++ projects. It will
# build and install include-what-you-use, symlink it as iwyu, and install a
# Python wrapper to automatically correct includes (fix_include).
class Iwyu < Formula
  CLANG_VERSION = '3.5'

  homepage 'https://code.google.com/p/include-what-you-use/'
  url 'http://include-what-you-use.googlecode.com/svn/tags/clang_' +
      "#{Iwyu::CLANG_VERSION}", revision: '590'
  version '0.3'

  depends_on 'cmake' => :build
  depends_on 'llvm' => [:build, 'with-clang']

  def install
    clang_path = "#{HOMEBREW_PREFIX}/Cellar/llvm/#{Iwyu::CLANG_VERSION}.0/"

    system 'cmake', "-DLLVM_PATH=#{clang_path}",
           "-DCMAKE_CXX_FLAGS='-stdlib=libc++'",
           "-DCMAKE_EXE_LINKER_FLAGS='-stdlib=libc++'",
           "-DCMAKE_INSTALL_PREFIX=#{prefix}/",
           buildpath, *std_cmake_args
    system 'make', 'install'

    bin.install('fix_includes.py' => 'fix_include')
    bin.install_symlink('include-what-you-use' => 'iwyu')
    prefix.install_symlink "#{clang_path}/lib"
  end

  test do
    # write out a header and a C file relying on transitive dependencies
    (testpath / 'demo.h').write('#include <stdio.h>')
    (testpath / 'demo.c').write <<-EOS.undent
    #include "demo.h"

    int main(void)
    { printf("hello world"); }
    EOS

    # iwyu always exits with status 1 so assert that and capture output
    fixes = shell_output "iwyu #{testpath}/demo.c 2>&1", 1

    # pass the output to the fixer script and assert that it fixed one file
    results = pipe_output 'fix_include', fixes

    assert_match /IWYU edited 1 file/, results

    # sigh. they use the status code to signal how many files were edited
    assert_equal 1, $CHILD_STATUS.exitstatus
  end
end
