use strict;
use warnings;
use Test::Base tests => 15;

BEGIN {
    use_ok 'Text::Tepl::Runtime';
}

can_ok 'Text::Tepl::Runtime', 'filter';
can_ok 'Text::Tepl::Runtime', 'default_modifier';
can_ok 'Text::Tepl::Runtime', 'modifier';

can_ok __PACKAGE__, 'filter';

ok ! eval {__PACKAGE__->can('default_modifier') }, '! export default_modifier';
ok ! eval {__PACKAGE__->can('modifier') }, '! export default';

Text::Tepl::Runtime->import('default_modifier', 'modifier');
can_ok __PACKAGE__, 'default_modifier';
can_ok __PACKAGE__, 'modifier';

my @modifier_list = modifier();
is_deeply
    [sort @modifier_list],
    [sort qw(
        * xmlall htmlall text xml html js uri url asis raw
        cdata erase_tag link squash_space nl2br tag stag etag
    )],
    'modifier list';

is default_modifier(), modifier(q{*}), 'default modifier';

my $code = sub {};
modifier(':test:' => $code);
is modifier(':test:'), $code, 'insert modifier';

my $code2 = sub {};
my $code3 = modifier(':test:' => $code2);
is $code3, $code, 'old modifier';
is modifier(':test:'), $code2, 'replace modifier';

modifier(':test:', undef);
my @with_test_list = grep { $_ eq ':test:' } modifier();
ok @with_test_list == 0, 'delete modifier';

