#!/usr/bin/perl

sub cat_ { 
	local *F; 
	open F, $_[0] or return; 
	my @l = <F>; 
	wantarray() ? @l : join '', @l 
}
sub output { 
	my $f = shift; 
	local *F; 
	open F, ">$f" or die "output in file $f failed: $!\n"; 
	print F foreach @_; 1 
}
  
if (@ARGV != 2) {
	die "Usage: bat2sh.pl <input .bat file> <output .sh file>\n";
}
my @contents = cat_($ARGV[0]);

foreach my $line (@contents) {
	# rem -> #
	$line =~ s/rem /# /i;
	# move -> mv
	$line =~ s/^\s*move\b/mv/;
	# del -> rm
	$line =~ s/^\s*del\b/rm/;
	# dos eol to unix eol
	$line =~ s/\r\n/\n/;
	# set
	$line =~ s/^\s*set //i;
	# \ -> /
	$line =~ s/\\/\//g;
	# copy -> cp
	if ($line =~ m/^\s*copy\b/ig){
		$line =~ s/^\s*copy\b/cp/ig;
		$line =~ s/\n//; #remove eol
		$line .= " ./\n";
	}
	# %varName% -> $varName
	while ($line =~ m/(%\w*%)/ig){
		my $word = "\$" . substr($1, 1, -1);
		$line =~ s/(%\w*%)/$word/ig;
	}
	# if ERRORLEVEL 1 goto ERROR -> if [ "$?" = "1" ]; then sub_error fi
	if ($line =~ m/^\s*if\s*ERRORLEVEL\s*1\s*goto\s*(\w*)\s*$/ig){
		$line = "if [ \"\$?\" = \"1\" ]; then \n	exit 1\nfi\n";
	}
}
my $line = "#!/bin/sh\n\n\n";
unshift @contents, $line;

output $ARGV[1], @contents;