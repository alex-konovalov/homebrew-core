class Gap < Formula
  desc "System for computational discrete algebra"
  homepage "https://www.gap-system.org/"
  url "https://www.gap-system.org/pub/gap/gap-4.10/tar.bz2/gap-4.10.0.tar.bz2"
  version "4.10.0"
  sha256 "2dc71364b7418d16f8b99ca914971996fa4416294fa3ae8fb336c873c946abb6"

  depends_on "gmp"
  depends_on "readline"

  def install
    # Remove some unused files
    rm Dir["bin/*.bat", "bin/*.ico", "bin/*.bmp", "bin/cygwin.ver"]

    # XXX:  Currently there is no `install` target in `Makefile`.
    #   According to the manual installation instructions in
    #
    #     https://github.com/gap-system/gap/blob/master/INSTALL.md
    #
    #   the compiled "bundle" is intended to be used "as is," and there is
    #   no instructions for how to remove the source and other unnecessary
    #   files after compilation.  Moreover, the content of the
    #   subdirectories with special names, such as `bin` and `lib`, is not
    #   suitable for merging with the content of the corresponding
    #   subdirectories of `/usr/local`.  The easiest temporary solution seems
    #   to be to drop the compiled bundle into `<prefix>/libexec` and to
    #   create a symlink `<prefix>/bin/gap` to the startup script.
    #   This use of `libexec` seems to contradict Linux Filesystem Hierarchy
    #   Standard, but is recommended in Homebrew's "Formula Cookbook."

    libexec.install Dir["*"]

    # GAP does not support "make install" so it has to be compiled in place

    cd libexec do
      args = %W[--prefix=#{libexec} --with-gmp=system]
      system "./configure", *args
      system "make"
    end
    
    # Create a symlink `bin/gap` from the `gap` binary
    bin.install_symlink libexec/"gap" => "gap"

    ohai "Building included packages. Please be patient, it may take a while"
    cd libexec/"pkg" do
      # NOTE: This script will build most of the packages that require
      # compilation. It is known to produce a number of warnings and 
      # error messages, possibly failing to build several packages.
      system "../bin/BuildPackages.sh --with-gaproot=#{libexec}"
    end

  end

  test do
    (testpath/"test_input.g").write <<~EOS
      Print(Factorial(3), "\\n");
      Print(IsDocumentedWord("IsGroup"), "\\n");
      Print(IsDocumentedWord("MakeGAPDocDoc"), "\\n");
      QUIT;
    EOS
    test_output = shell_output("#{bin}/gap -b test_input.g")
    expected_output =
      <<-EOS.undent
        6
        true
        true
      EOS
    assert_equal expected_output, test_output
  end
end
