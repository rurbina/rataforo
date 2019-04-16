# rataforo
Web forum software written as a FastCGI app in Perl.

## what?
Yes, a web forum software not written in s_php_aghetti. Very small, fast and capable. Self-contained, so you can just drop it into your nginx-based server with just a couple of proxy locations.

## how?
`plackup rataforo.pl`

It uses Perl, along with SQLite for database. SQLite should serve most purposes, but a PostgreSQL addon is on the horizon. SQLite and PostgreSQL are similar enough, it's a very simple upgrade if/when needed.

If you need any more help, feel free to drop by https://rataforo.ml/boards/support

## why?
Web forums still have a place in the web. Perl-based means you don't require Php; most cheap/free web hosting services offer Php, but most really cheap virtual servers are bare bones and this will offer a footprint of ~20MB.

