#!/usr/bin/env perl

use 5.014;

use WWW::Mechanize;
use List::MoreUtils qw(uniq);


# feed me a url like this!
my $url = "http://g.e-hentai.org/g/625292/90f4783078/";

my $secret = "g.e-hentai.org/s";
my $secret2 = "ehgt.org/g";

print "~> ";
while (<>) {

    chomp;
    $url = $_;

    my $mech = WWW::Mechanize->new();

    $mech->get($url);

    my $pglist_ref = $mech->find_all_links( url_regex => qr/\?p=(\d+)/);

    my $pglist_max = ( uniq( reverse
                               sort { urlcmp1($a, $b) }
                                 map { $_->url_abs() } @$pglist_ref ) )[-1];

    my @pglist = ();
    my $max = ($pglist_max =~ qr/\?p=(\d+)/)[0];

    my $wait_t = $max*0.18 + 0.5;

    say "[-] wait time -> $wait_t";

    for my $idx (0 .. $max) {
        push @pglist, $url."?p=$idx";
    }

    say "page list:";
    for (@pglist) {
        say "(´・ω・｀) や" . $_;
    }

    open PG, ">", "page.html";
    for (@pglist) {
        $mech->get($_);

        my $ref = $mech->find_all_links(
                        url_regex => qr/($secret)\/([\d\w]{10})\/(\d+-\d+)/);

        my @queue = ( uniq( reverse sort { urlcmp2($a, $b) }
                map { $_->url_abs() } @$ref ) );

        for (@queue) {
            say "[+] getting $_";

            $mech->get($_);
            my @imgs = $mech->find_all_images();
            if (@imgs) {
                my $img = ( grep {!/$secret2/} map { $_->url_abs() } @imgs )[0];
                say PG "<img src=\"$img\" /><br />";
            }
            else {
                say "[-] can't get img!! QQ";
                sleep 2;
            }

            # sleep, be a nice guy!
            select undef, undef, undef, $wait_t;
        }
    }

    system("open page.html");
    close PG;

    say "[+] done ^q^";
    print "-> ";

}

sub urlcmp1 {
    my ($a, $b) = @_;
    my $d1 = ($a =~ qr/\?p=(\d+)/)[0];
    my $d2 = ($b =~ qr/\?p=(\d+)/)[0];
    return $d1 < $d2;
}

sub urlcmp2 {
    my ($a, $b) = @_;
    my $d1 = ($a =~ qr/($secret\/[\d\w]{10}\/\d+-)(\d+)/)[1];
    my $d2 = ($b =~ qr/($secret\/[\d\w]{10}\/\d+-)(\d+)/)[1];
    return $d1 < $d2;
}

