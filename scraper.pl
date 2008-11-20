#!/usr/bin/env perl
use strict;
use warnings;
use Web::Scraper;
use URI;
use URI::Escape;
use Data::Dumper;

my $page = 0;
my $entry_per_page = 10;
my $max = 440;
#my $max = 100;

my $message_count = 0;
my $words = {};

while ($page < $max) {
    my $url = "http://find.teacup.com/bbssearch?query=viagra&encode=Shift_JIS&limit=$entry_per_page&offset=$page";
    print "$url\n";

    my $uri = URI->new($url);
    my $scraper = scraper {
        process '//dt[@class="contentsKijititle"]/a', 'link[]' => '@href';
    };
    my $result = $scraper->scrape($uri);

    foreach my $url (@{ $result->{link} }) {
        $scraper = scraper {
            process '/html/body/table[2]/tr/td/table/tr/td/font/b', 'title' => 'TEXT';
            process '/html/body/table[2]/tr/td/table/tr/td/b/a', 'user' => 'TEXT';
            process '/html/body/table[2]/tr/td/table[2]/tr/td[2]/tt/font/a', 'link[]' => {
                'text' => sub {
                    my $text = $_->as_text();
                    my @words = split ' ', $text;
                    [@words];
                },
                'url' => sub {
                    $url = URI->new($_->attr('href'))->query;
                    $url =~ s/^M=JU&JUR=(.*)$/$1/;
                    uri_unescape($url);
                },
            };
        };
        $result = $scraper->scrape($url);

        foreach my $link (@{ $result->{link} }) {
            foreach my $word (@{ $link->{text} }) {
                if ($words->{$word}) {
                    $words->{$word}++;
                } else {
                    $words->{$word} = 1;
                }
            }
        }
        $message_count++;
    }
    $page += $entry_per_page;
}


print Dumper {
    messages => $message_count,
    words => $words
};

