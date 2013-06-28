#!/usr/bin/perl

if ($ARGV[0] eq "-h" | $ARGV[0] eq "-?") {
  print "convert a state sequence into an observation sequence given a map state-obs\n";	
  print "usage: ./annotate.perl originaltext < stateseq > originaltext-annot.html\n\n";	
	exit;	
}

print <<END;
<html>
<head>
<style type="text/css">
pre lang2 {
  background-color: IndianRed;
}
pre lang3 {
	background-color: DarkSeaGreen ;
}
pre lang4 {
  background-color: LightSkyBlue;
}
pre lang5 {
  background-color: LemonChiffon;
}
pre lang1 {
  background-color: white;
}
pre lang6 {
  background-color: Thistle;
}
pre lang7 {
  background-color: Olive;
}
pre lang8 {
  background-color: DarkOrchid;
}
</style>
</head>
<body>
<div style="font: Helvetica 12pt;border: 1px solid black;background-color: Silver">
<pre>
END

%color=();
%lang=();

%tokens=();
$totk=0;
while(defined($l=<STDIN>)) {
  $l=~s/[\n\r]//g;
  @p=split('\t',$l);
	$clr=$p[$#p-1];
  my ($ln,$start,$end) = $p[2] =~ /(\d+)\:(\d+)\-(\d+)/;
	$tokens{$ln}{$start}{$end}=$clr;
	$color{$clr}="lang$clr";
	$lang{$clr}=$p[$#p];
	$totk++;
}

for my $li(keys %lang) {
	print " <lang$li> $lang{$li} </lang$li>";
}
print " (Tot. tokens: $totk)</pre></div><div style='background-color: white'><pre>\n";


$ln=1;
for my $l(`cat $ARGV[0]`) {
	$l=~s/[\n\r]//g;
	
	@ltxt=split('',$l);
	$pstart=1;
	for my $start (sort {$a <=>$b} keys %{$tokens{$ln}}) {
		for my $end (sort {$a <=>$b} keys %{$tokens{$ln}{$start}}) {
			$class=$tokens{$ln}{$start}{$end};
			if ($pstart<$start){
			  $pretok=join('',@ltxt[($pstart)..($start-2)]);
				print "<$color{$class}>" if ($pretok =~ /\s+/);
				print $pretok;
				print "<$color{$class}>" if ($pretok =~ /\s+/);
			}
			$token=join('',@ltxt[($start-1)..($end-1)]);
			if ($class>1) {
				print "<$color{$class}>$token</$color{$class}>";
			} else {
				print $token;
			}
			$pstart=$end;
		}
	}	
	print join('',@ltxt[($pstart)..$#ltxt]);

	print "\n";
	$ln++;
}

print <<END;
</pre>
</div>
</body>
</html>
END
