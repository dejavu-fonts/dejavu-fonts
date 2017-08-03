Building
--------

### Prerequisites

To build these fonts, you will need:

* [FontForge][1], installable on Debian through the `fontforge` package:

  ~~~shell
  sudo apt-get install software-properties-common
  sudo add-apt-repository ppa:fontforge/fontforge
  sudo apt-get update
  sudo apt-get install fontforge
  ~~~

  macOS users can install using [Homebrew][2]:

  ~~~shell
  brew install fontforge
  ~~~

  Fedora users should run the following command as root:

  ~~~shell
  yum install fontforge
  ~~~

  See FontForge's [installation docs][3] for more info.


* [Perl][4], with the [`Font::TTF`][5] and [`IO::String`][6] modules
  installed:

  ~~~shell
  cpan Font::TTF IO::String
  ~~~

  Debian users can install this with the `libfont-ttf-perl` package.

  macOS users may need to install as root if they encounter
  permission problems.


* GNU-compatible [Make][7], installable through Debian package `make`.

  macOS users who have installed XCode's CLI utils should already
  have `make` available.


### Generating TrueType files

To generate each font without subsetting:

~~~console
$ make  full-ttf
~~~

To generate each font with only a specific subset of glyphs:
~~~console
$ make  lgc-ttf    # LGC (Latin-Greek-Cyrillic) subset
$ make  sans-ttf   # Generate DejaVuSans only (no serif fonts)
~~~


### Building from source

To generate each TTF file from its source data:

1. Download a copy of the latest Unicode annexes to this project's
   [`resources`](./resources) directory:

   ~~~shell
   wget -P resources \
       http://www.unicode.org/Public/UNIDATA/UnicodeData.txt \
       http://www.unicode.org/Public/UNIDATA/Blocks.txt
   ~~~~

2. Checkout the current fc-lang orthographies from the
   [`fontconfig`][8] repository:

   ~~~shell
   git clone \
     git://anongit.freedesktop.org/git/fontconfig \
     ~/repos/fontconfig
   ~~~

3. Symlink to the appropriate folder:

   ~~~shell
   ln -s ~/repos/fontconfig/fc-lang resources/fc-lang
   ~~~

4. Finally, run `make` with its default target (without any arguments):

   ~~~shell
   make
   ~~~


[1]: https://fontforge.github.io/en-US/
[2]: https://brew.sh/
[3]: http://designwithfontforge.com/en-US/Installing_Fontforge.html
[4]: https://www.perl.org/
[5]: https://metacpan.org/release/Font-TTF/
[6]: https://metacpan.org/pod/IO::String
[7]: http://www.gnu.org/software/make/manual/make.html
[8]: https://wiki.freedesktop.org/www/Software/fontconfig/
