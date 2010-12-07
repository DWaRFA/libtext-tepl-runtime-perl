package Text::Tepl::Runtime;
use strict;
use warnings;
use Carp qw(croak);
use base qw(Exporter);

# $Id$
use version; our $VERSION = '0.002';

our @EXPORT = qw(filter);
our @EXPORT_OK = qw(modifier default_modifier);

my %MODIFIER;

default_modifier(\&_modifier_xmlall);

modifier(xmlall => \&_modifier_xmlall);
modifier(htmlall => \&_modifier_xmlall);
modifier(text => \&_modifier_html);
modifier(html => \&_modifier_html);
modifier(xml => \&_modifier_xml);
modifier(uri => \&_modifier_uri);
modifier(url => \&_modifier_uri);
modifier(js => \&_modifier_js);
modifier(raw => \&_modifier_raw);
modifier(asis => \&_modifier_raw);
modifier(cdata => \&_modifier_cdata);
modifier('link' => \&_modifier_link);
modifier(nl2br => \&_modifier_nl2br);
modifier(squash_space => \&_modifier_squash_space);
modifier(erase_tag => \&_modifier_erase_tag);
modifier(stag => \&_modifier_stag);
modifier(tag => \&_modifier_stag);
modifier(etag => \&_modifier_etag);

my %ATTRIBUTE_URI = map { $_ => 1 } qw(
    action background cite classid codebase data href
    longdesc profile src usemap xmlns
);

my %ELEMENT_EMPTY = map { $_ => 1 } qw(
    area base basefont br col frame hr img input
    isindex link meta param
);

# see http://d.hatena.ne.jp/ockeghem/20070519/1179592129
# see http://subtech.g.hatena.ne.jp/mala/20100222/1266843093

my %XML_SPECIAL = (
    q{&} => '&amp;', q{<} => '&lt;', q{>} => '&gt;',
    q{"} => '&quot;', q{'} => '&#39;', q{\\} => '&#92;',
);

my %JS_SPECIAL = (
    q{'} => q{\\x27}, q{"} => q{\\x22}, q{\\} => q{\\x5c},
    q{/} => q{\\x2f}, q{<} => q{\\x3c}, q{>} => q{\\x3e}, q{&} => q{\\x26},
    "\x0d" => q{\\r}, "\x0a" => q{\\n},
);

my $ESCAPE_XML_PATTERN = qr{
    (?:([<>"'\\])
    | \&(?: (?: (amp|gt|lt|quot|\#(?:[0-9]{1,5}|x[0-9A-Fa-f]{2,4}))
            |   ([A-Za-z_][A-Za-z0-9_]*)
            );
        )?
    )
}msx;

my %ENTITY = (
    nbsp => 160, iexcl => 161, cent => 162, pound => 163, curren => 164,
    yen => 165, brvbar => 166, sect => 167, uml => 168, copy => 169,
    ordf => 170, laquo => 171, not => 172, shy => 173, reg => 174, macr => 175,
    deg => 176, plusmn => 177, sup2 => 178, sup3 => 179, acute => 180,
    micro => 181, para => 182, middot => 183, cedil => 184, sup1 => 185,
    ordm => 186, raquo => 187, frac14 => 188, frac12 => 189, frac34 => 190,
    iquest => 191, Agrave => 192, Aacute => 193, Acirc => 194, Atilde => 195,
    Auml => 196, Aring => 197, AElig => 198, Ccedil => 199, Egrave => 200,
    Eacute => 201, Ecirc => 202, Euml => 203, Igrave => 204, Iacute => 205,
    Icirc => 206, Iuml => 207, ETH => 208, Ntilde => 209, Ograve => 210,
    Oacute => 211, Ocirc => 212, Otilde => 213, Ouml => 214, times => 215,
    Oslash => 216, Ugrave => 217, Uacute => 218, Ucirc => 219, Uuml => 220,
    Yacute => 221, THORN => 222, szlig => 223, agrave => 224, aacute => 225,
    acirc => 226, atilde => 227, auml => 228, aring => 229, aelig => 230,
    ccedil => 231, egrave => 232, eacute => 233, ecirc => 234, euml => 235,
    igrave => 236, iacute => 237, icirc => 238, iuml => 239, eth => 240,
    ntilde => 241, ograve => 242, oacute => 243, ocirc => 244, otilde => 245,
    ouml => 246, divide => 247, oslash => 248, ugrave => 249, uacute => 250,
    ucirc => 251, uuml => 252, yacute => 253, thorn => 254, yuml => 255,
    OElig => 338, oelig => 339, Scaron => 352, scaron => 353, Yuml => 376,
    circ => 710, tilde => 732, ensp => 8194, emsp => 8195, thinsp => 8201,
    zwnj => 8204, zwj => 8205, lrm => 8206, rlm => 8207, ndash => 8211,
    mdash => 8212, lsquo => 8216, rsquo => 8217, sbquo => 8218, ldquo => 8220,
    rdquo => 8221, bdquo => 8222, dagger => 8224, Dagger => 8225,
    permil => 8240, lsaquo => 8249, rsaquo => 8250, euro => 8364, fnof => 402,
    Alpha => 913, Beta => 914, Gamma => 915, Delta => 916, Epsilon => 917,
    Zeta => 918, Eta => 919, Theta => 920, Iota => 921, Kappa => 922,
    Lambda => 923, Mu => 924, Nu => 925, Xi => 926, Omicron => 927, Pi => 928,
    Rho => 929, Sigma => 931, Tau => 932, Upsilon => 933, Phi => 934,
    Chi => 935, Psi => 936, Omega => 937, alpha => 945, beta => 946,
    gamma => 947, delta => 948, epsilon => 949, zeta => 950, eta => 951,
    theta => 952, iota => 953, kappa => 954, lambda => 955, mu => 956, nu => 957,
    xi => 958, omicron => 959, pi => 960, rho => 961, sigmaf => 962,
    sigma => 963, tau => 964, upsilon => 965, phi => 966, chi => 967,
    psi => 968, omega => 969, thetasym => 977, upsih => 978, piv => 982,
    bull => 8226, hellip => 8230, prime => 8242, Prime => 8243, oline => 8254,
    frasl => 8260, weierp => 8472, image => 8465, real => 8476, trade => 8482,
    alefsym => 8501, larr => 8592, uarr => 8593, rarr => 8594, darr => 8595,
    harr => 8596, crarr => 8629, lArr => 8656, uArr => 8657, rArr => 8658,
    dArr => 8659, hArr => 8660, forall => 8704, part => 8706, exist => 8707,
    empty => 8709, nabla => 8711, isin => 8712, notin => 8713, ni => 8715,
    prod => 8719, sum => 8721, minus => 8722, lowast => 8727, radic => 8730,
    prop => 8733, infin => 8734, ang => 8736, and => 8743, or => 8744,
    cap => 8745, cup => 8746, int => 8747, there4 => 8756, sim => 8764,
    cong => 8773, asymp => 8776, ne => 8800, equiv => 8801, le => 8804,
    ge => 8805, sub => 8834, sup => 8835, nsub => 8836, sube => 8838,
    supe => 8839, oplus => 8853, otimes => 8855, perp => 8869, sdot => 8901,
    lceil => 8968, rceil => 8969, lfloor => 8970, rfloor => 8971, lang => 9001,
    rang => 9002, loz => 9674, spades => 9824, clubs => 9827, hearts => 9829,
    diams => 9830,
);

sub filter {
    my($list, @x) = @_;
    if (! ref $list || ref $list eq 'CODE') {
        $list = [$list];
    }
    $list = [@{$list}];
    while (my $modifier = shift @{$list}) {
        @x = (ref $modifier eq 'CODE' ? $modifier
        : ref $MODIFIER{$modifier} eq 'CODE' ? $MODIFIER{$modifier}
        : croak "Undefined modifier '$modifier' called."
        )->($list, @x);
    }
    return wantarray ? @x : $x[0];
}

sub default_modifier { return modifier(q{*}, @_); }

sub modifier {
    my(@arg) = @_;
    return keys %MODIFIER if ! @arg;
    my $name = shift @arg;
    if (! @arg) {
        return $MODIFIER{$name};
    }
    elsif (! defined $arg[0]) {
        return delete $MODIFIER{$name};
    }
    elsif (ref($arg[0]) eq 'CODE') {
        (my($old), $MODIFIER{$name}) = ($MODIFIER{$name}, $arg[0]);
        return $old;
    }
    else {
        croak 'invalid modifier arguments.';
    }
}

sub _modifier_xmlall {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{([<>"'&\\])}{ $XML_SPECIAL{$1} }msxge;
    return $s;
}

sub _modifier_uri {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{
        (?: (\%([0-9A-Fa-f]{2})?)
        |   (&(?:amp;)?)
        |   ([^a-zA-Z0-9_\-.=+\$,:\@/;?\#])
        )
    }{
          $2 ? $1
        : $1 ? '%25'
        : $3 ? '&amp;'
        : sprintf '%%%02X', ord $4
    }egmosx;
    return $s;
}

sub _modifier_js {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{(['"\\/&<>\r\n])}{ $JS_SPECIAL{$1} }egmosx;
    return $s;
}

sub _modifier_raw {
    my($list, @arg) = @_;
    return join q{}, @arg;
}

sub _modifier_xml {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{$ESCAPE_XML_PATTERN}{
          $1 ? $XML_SPECIAL{$1}
        : $2 ? qq{\&$2;}
        : $3 ? (exists $ENTITY{$3} ? "\&\#$ENTITY{$3};" : qq{\&$3;})
        : q{&amp;}
    }egmosx;
    return $s;
}

sub _modifier_html {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{$ESCAPE_XML_PATTERN}{
          $1 ? $XML_SPECIAL{$1}
        : $2 ? qq{\&$2;}
        : $3 ? (exists $ENTITY{$3} ? qq{\&$3;} : qq{\&amp;$3;})
        : q{&amp;}
    }egmosx;
    return $s;
}

sub _modifier_erase_tag {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{<[^>]*?>}{}gmosx;
    return $s;
}

sub _modifier_squash_space {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{[\x00-\x20\x7f]+}{\x20}msxg;
    return $s;
}

sub _modifier_nl2br {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{(?:(<[^>]*>)|((?:\r\n?|\n)))}{ $1 || qq{<br />\n} }egmosx;
    return $s;
}

sub _modifier_link {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    $s =~ s{(?:(<[^>]*>)|(\bhttps?://[A-Za-z0-9_\-.=+\$,&\%:\@/;?\#]+))}{
        $1 || q{<a href="} . _modifier_uri(['uri'], $2) . q{">}
            . _modifier_html(['html'], $2) . q{</a>}
    }egmosx;
    return $s;
}

sub _modifier_cdata {
    my($list, @arg) = @_;
    my $s = join q{}, @arg;
    if ($s =~ /[&<>"]/msx) {
        $s = q{<![CDATA[} . $s . q{]]>};
    }
    return $s;
}

sub _modifier_stag {
    my($list, @attr) = @_;
    my $tag = shift @{$list};
    my $s = qq{<$tag};
    for (0 .. -1 + int @attr / 2) {
        my $i = $_ * 2;
        my($name, $value) = @attr[$i, $i + 1];
        $value = $ATTRIBUTE_URI{lc $name}
            ? _modifier_uri(['uri'], $value)
            : _modifier_xmlall(['xmlall'], $value);
        $s .= qq{ $name="$value"};
    }
    if ($ELEMENT_EMPTY{lc $tag}) {
        $s .= q{ /};
    }
    return $s . q{>};
}

sub _modifier_etag {
    my($list) = @_;
    return q{</} . (shift @{$list}) . q{>};
}

1;

__END__

=pod

=head1 NAME

Text::Tepl::Runtime - The runtime filters for Text::Tepl.

=head1 VERSION

0.002

=head1 SYNOPSIS

    use Text::Tepl;
    use Text::Tepl::Runtime qw(filter modifier default_modifier);
    my $eperl_document = join q{}, <DATA>;
    print Text::Tepl::call($eperl_document);
    # code reference modifier.
    filter([sub{
        my($list, @arg) = @_;
        my $s = join q{}, @arg;
        $s =~ y/f/F/;
        return $s;
    }], "0123456789abcdef");
    # same as Text::Tepl::call(q{<?pl:foo:bar @_ ?>}, $text);
    # same as filter(['bar'], filter(['foo'], $text));
    filter(['foo', 'bar'], $text);
    # add modifier
    modifier(ucfirst => sub{
        my($list, $s) = @_;
        $s =~ s{\b(\w+)}{ ucfirst $1 }msxge;
        return $s;
    });
    # delete modifier
    modifier(abspath => undef);
    # replace default modifier
    default_modifier(modifier('asis'));
    #
    __DATA__
    <?pl:xmlall qq{escape &<>"'} ?>.
    <?pl:xml    qq{escape &<>"'} ?>.
    <?pl:html   qq{escape &<>"'} ?>.
    <?pl:raw    qq{unchange &<>"'} ?>.

    <?pl:xmlall qq{escape &amp; &lt; &gt; &quot; &#39;} ?>.
    <?pl:xml    qq{unchange &amp; &lt; &gt; &quot; &#39;} ?>.
    <?pl:html   qq{unchange &amp; &lt; &gt; &quot; &#39;} ?>.
    <?pl:raw    qq{unchange &amp; &lt; &gt; &quot; &#39;} ?>.

    <?pl:xmlall qq{escape &nbsp; escape &UNDEF;} ?>.
    <?pl:xml    qq{numeric &nbsp; unchange &UNDEF;} ?>.
    <?pl:html   qq{unchange &nbsp; escape &UNDEF;} ?>.
    <?pl:raw    qq{unchange &nbsp; unchange &UNDEF;} ?>.

    <?pl:uri    Encode::encode('UTF-8', $uri) ?>

    <?pl:cdata qq{unchange &<>"' &amp; &lt; &gt; &quot; &#39;} ?>.
    <?pl:link qq{http://hoge/a=A&b=B fuga} ?>.
    <?pl:tag:input type => 'text', name => 'a', value => 'a' ?>.
    <?pl:stag:a href => 'http://foo/', title => 'foo web site' ?>.
    <?pl:etag:a ?>.
    <?pl:erase_tag qq{<b>hoge</b>} ?>.
    <?pl:nl2br qq{hoge\n\nfuga\n} ?>.
    <?pl:squash_space qq{hoge\n\n\n\n\n\n\n\n\n     fuga} ?>.

=head1 DESCRIPTION

This module provides you useful filters for Text::Tepl.

=head1 MODIFIERS

=over

=item C<< :xmlall :htmlall >>

These are the default modifiers. These substitute special
characters for XML and Javascript:

    & to &amp;
    < to &lt;
    > to &gt;
    " to &quot;
    ' to &#39;
    \ to &#92;

=item C<< :xml >>

Replaces special characters except for consisting name entities
or number entities. This replaces name entities to number entities. 

=item C<< :html :text >>

Replace special characters except for consisting name entities
or number entities.

=item C<< :uri :url >>

Perform uri-encoding. You should encode your URI to proper
character encoding before pass to this modifier.

    <?pl:uri Encode::encode('UTF-8', $uri->as_string) ?>

=item C<< :js >>

Escapes for javascript string.

    & to \x26
    < to \x3c
    > to \x3e
    " to \x22
    ' to \x27
    \ to \\
    / to \x2f
    \n to \\n
    \r to \\r

=item C<< :asis :raw >>

Passes a string as-is without any escapes.

=item C<< :cdata >>

Put strings in the cdata-section.

=item C<< :link >>

Creates a-href tags.

=item C<< :erase_tag >>

Erase any tags.

=item C<< :nl2br >>

Add br-element before newline character.

=item C<< :squash_space >>

Squashes spaces.

=item C<< :tag :stag :etag >>

Creates stag or etag.

=back

=head1 SUBROUTINES

=over

=item C<< filter(\@list, @arg); >>

Applies modifiers chain as C<$list>.

    filter(['foo', 'bar'], @arg);
    # is same as
    filter(['bar'], filter(['foo'], @arg));

=item C<< modifier(modifier_name => sub{}); >>

Registers, eliminates, and lists modifiers.

    # get list of modifiers name
    @modifier_list = Text::Tepl::Runtime::modifier;
    # register or change modifier
    Text::Tepl::Runtime::modifier(upcase => sub{
        my($list, @arg) = @_; # $list is the modifier list
        return uc(join q{}, @arg);
    });
    # delete modifier
    Text::Tepl::Runtime::modifier(upcase);

=item C<< default_modifier(sub{}); >>

Changes default modifier another one.

    Text::Tepl::Runtime::default_modifier(
        Text::Tepl::Runtime::modifier('raw')
    );

=back

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

L<Text::Tepl>
L<http://www.smarty.net/manual/en/language.modifiers.php>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
