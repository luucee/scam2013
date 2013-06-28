#!/usr/bin/perl

$dir=$ARGV[0];

# filter out big and small files
@csources=();
@patches=();
@text=();
for my $l(`cat listfiles-linuxkernel.txt`) {
	($sz,$fl)=$l=~/\s*(\d+) ([^\s]+)/;
	if ($sz>30 && $sz<100) {
		push @csources, $fl;
	}
}

$cmd="find $dir -name 'patch*.txt' -exec wc -l {} \\;";
for my $l(`$cmd`) {
	($sz,$fl)=$l=~/\s*(\d+) ([^\s]+)/;
	if ($sz>2 && $sz<100) {
		push @patches, $fl;
	}
}

$cmd="find $dir -name 'comments*.txt' -exec wc -l {} \\;";
for my $l(`$cmd`) {
	($sz,$fl)=$l=~/\s*(\d+) ([^\s]+)/;
	if ($sz>1 && $sz<100) {
	
		push @text, $fl;
	}
}

$ci=0+int(rand($#csources+1));
$ti1=0+int(rand($#text+1));
$ti2=0+int(rand($#text+1));
$ti3=0+int(rand($#text+1));
$pi=0+int(rand($#patches+1));

print `cat $text[$ti1]`;
print " CCODDS ";
print `cat $csources[$ci] | ./stripcomments.perl`;
print " CCODDE ";
print `cat $text[$ti2]`;
print " PPODDS ";
print `cat $patches[$pi]`;
print " PPODDE ";
print `cat $text[$ti3]`;

