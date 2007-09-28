#!/usr/bin/env fontforge
# $Id: generate.py 1902 2007-06-21 23:44:12Z apanov $

# script file for FontForge for TTF generation
# usage:
#   mkdir generated
#   chmod +x generate.pe
#   ./generate.pe *.sfd
import fontforge, sys;
required_version = "20070501"

# font generation flags:
#   omit-instructions => do not include TT instructions (for experimental typefaces)
#   opentype          => include OpenType tables
#   glyph-comments    => generate a 'PfEd' table and store glyph comments
#   glyph-colors      => generate a 'PfEd' table and store glyph colors
#   old-kern          => generate old fashioned kern tables.
#   - this one is important because it generates correct kerning tables for legacy 
#     applications
def_gen_flags = ("opentype", "glyph-comments", "glyph-colors", "old-kern")
exp_gen_flags = def_gen_flags + ("omit-instructions",)

if fontforge.version() < required_version:
  print ("Your version of FontForge is too old - %s or newer is required" % (required_version));
# FoundryName is not used in TTF generation
fontforge.setPrefs("FoundryName", "DejaVu");
# first 4 characters of TTFFoundry are used for achVendId
fontforge.setPrefs("TTFFoundry", "DejaVu")
i = 1
while i < len(sys.argv):
  font=fontforge.open(sys.argv[i]);
  gen_flags = def_gen_flags

  # Serif Italic and Serif Bold Italic are experimental
  if font.fontname.rfind("Serif") > -1 and font.fontname.rfind("Italic") > -1:
    gen_flags = exp_gen_flags;
  if font.fontname.rfind("Condensed") > -1:
    gen_flags = exp_gen_flags;
  if font.fontname.rfind("ExtraLight") > -1:
    gen_flags = exp_gen_flags;

  fontname = "generated/" + font.fontname + ".ttf";
  font.generate(fontname,"",gen_flags);
  font.close();
  i += 1;
