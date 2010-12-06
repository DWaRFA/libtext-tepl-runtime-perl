use strict;
use warnings;
use Test::Base;
use Text::Tepl::Runtime;

Text::Tepl::Runtime::modifier(':test:' => sub{
    my($list, $s) = @_;
    $s =~ s{hoge}{HOGE}g;
    return $s;
});

Text::Tepl::Runtime::modifier(':t0:' => sub { $_[1] . "t0" });
Text::Tepl::Runtime::modifier(':t1:' => sub { $_[1] . "t1" });
Text::Tepl::Runtime::modifier(':t2:' => sub { $_[1] . "t2" });

plan tests => 1 * blocks;

filters {
    input => [qw(eval filter)],
    expected => [qw(eval)],
};

run_is 'input' => 'expected';

__END__

=== test
--- input
[':test:'], 'foo hoge bar hoge baz'
--- expected
'foo HOGE bar HOGE baz'

=== t0:t1:t2
--- input
[':t0:', ':t1:', ':t2:'], q{}
--- expected
't0t1t2'

=== default *
--- input
['*'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;&lt;tag/&gt;&quot;&#39;&#92;   }
. qq{&amp;amp;&amp;lt;&amp;gt;&amp;quot;\n}
. qq{&amp;#39;&amp;nbsp;&amp;#32;}

=== xmlall
--- input
['xmlall'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;&lt;tag/&gt;&quot;&#39;&#92;   }
. qq{&amp;amp;&amp;lt;&amp;gt;&amp;quot;\n}
. qq{&amp;#39;&amp;nbsp;&amp;#32;}

=== xml
--- input
['xml'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;&lt;tag/&gt;&quot;&#39;&#92;   }
. qq{&amp;&lt;&gt;&quot;\n}
. qq{&#39;&#160;&#32;}

=== html
--- input
['html'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;&lt;tag/&gt;&quot;&#39;&#92;   }
. qq{&amp;&lt;&gt;&quot;\n}
. qq{&#39;&nbsp;&#32;}

=== text
--- input
['text'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;&lt;tag/&gt;&quot;&#39;&#92;   }
. qq{&amp;&lt;&gt;&quot;\n}
. qq{&#39;&nbsp;&#32;}

=== uri
--- input
['uri'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;%3Ctag/%3E%22%27%5C%20%20%20}
. qq{&amp;&amp;lt;&amp;gt;&amp;quot;%0A}
. qq{&amp;#39;&amp;nbsp;&amp;#32;}

=== url
--- input
['url'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;%3Ctag/%3E%22%27%5C%20%20%20}
. qq{&amp;&amp;lt;&amp;gt;&amp;quot;%0A}
. qq{&amp;#39;&amp;nbsp;&amp;#32;}

=== js
--- input
['js'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{\\x26\\x3ctag\\x2f\\x3e\\x22\\x27\\x5c   }
. qq{\\x26amp;\\x26lt;\\x26gt;\\x26quot;\\n}
. qq{\\x26#39;\\x26nbsp;\\x26#32;}

=== asis
--- input
['asis'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}

=== raw
--- input
['raw'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}

=== cdata
--- input
['cdata'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{<![CDATA[&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;]]>}

=== erase_tag
--- input
['erase_tag'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}

=== squash_space
--- input
['squash_space'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&<tag/>"'\\ &amp;&lt;&gt;&quot; &#39;&nbsp;&#32;}

=== link
--- input
['link'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}

=== nl2br
--- input
['nl2br'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;<br />\n&#39;&nbsp;&#32;}

=== erase_tag:html
--- input
['erase_tag', 'html'], qq{&<tag/>"'\\   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}
--- expected
qq{&amp;&quot;&#39;&#92;   &amp;&lt;&gt;&quot;\n&#39;&nbsp;&#32;}

=== erase_tag:link
--- input
['erase_tag', 'link'], q{abc <a href="hoge">http://hoge/</a> }
. q{http://<a href="ftp://fuga">fuga</a>/?a=%51&amp;b=1#p32 ...}
--- expected
q{abc <a href="http://hoge/">http://hoge/</a> }
. q{<a href="http://fuga/?a=%51&amp;b=1#p32">http://fuga/?a=%51&amp;b=1#p32</a> ...}

=== tag:a
--- input
['tag', 'a'], href => "hoge.html?a=1&b=2", rel => "nofollow"
--- expected
q{<a href="hoge.html?a=1&amp;b=2" rel="nofollow">}

=== tag:input
--- input
['tag', 'input'], name => 'a', type => 'text', value => 'a<b&c'
--- expected
q{<input name="a" type="text" value="a&lt;b&amp;c" />}

=== etag:a
--- input
['etag', 'a']
--- expected
q{</a>}

