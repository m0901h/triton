{ fetchurl, stdenv, texinfo, perl, perlPackages
, groff, libxml2, libxslt, gnused, opensp
, docbook_xml_dtd_43
, makeWrapper }:

let
  version = "0.8.8";
in
stdenv.mkDerivation rec {
  name = "docbook2X-${version}";
  
  src = fetchurl {
    url = "mirror://sourceforge/docbook2x/docbook2x/${version}/${name}.tar.gz";
    sha256 = "0ifwzk99rzjws0ixzimbvs83x6cxqk1xzmg84wa1p7bs6rypaxs0";
  };

  # This patch makes sure that `docbook2texi --to-stdout' actually
  # writes its output to stdout instead of creating a file.
  patches = [ ./db2x_texixml-to-stdout.patch ];

  buildInputs = [ perl texinfo groff libxml2 libxslt makeWrapper opensp ]
    ++ (with perlPackages; [ XMLSAX XMLParser XMLNamespaceSupport ]);

  postConfigure = ''
    # Broken substitution is used for `perl/config.pl', which leaves literal
    # `$prefix' in it.
    substituteInPlace "perl/config.pl"       \
      --replace '${"\$" + "{prefix}"}' "$out"
  '';

  postInstall = ''
    perlPrograms="db2x_manxml db2x_texixml db2x_xsltproc
                  docbook2man docbook2texi";
    for i in $perlPrograms
    do
      # XXX: We work around the fact that `wrapProgram' doesn't support
      # spaces below by inserting escaped backslashes.
      wrapProgram $out/bin/$i --prefix PERL5LIB :			\
        "${perlPackages.XMLSAX}/lib/perl5/site_perl:${perlPackages.XMLParser}/lib/perl5/site_perl" \
	--prefix PERL5LIB : "${perlPackages.XMLSAXBase}/lib/perl5/site_perl" \
	--prefix PERL5LIB :	"${perlPackages.XMLNamespaceSupport}/lib/perl5/site_perl" \
	--prefix XML_CATALOG_FILES "\ " \
	  "$out/share/docbook2X/dtd/catalog.xml\ $out/share/docbook2X/xslt/catalog.xml\ ${docbook_xml_dtd_43}/xml/dtd/docbook/catalog.xml"
    done

    wrapProgram $out/bin/sgml2xml-isoent --prefix PATH : \
      "${gnused}/bin"
  '';

  meta = with stdenv.lib; {
    longDescription = ''
      docbook2X is a software package that converts DocBook documents
      into the traditional Unix man page format and the GNU Texinfo
      format.
    '';
    license = licenses.mit;
    homepage = http://docbook2x.sourceforge.net/;
    platforms = platforms.all;
  };
}
