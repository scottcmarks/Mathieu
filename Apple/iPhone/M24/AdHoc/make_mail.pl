$svn_log = `svn log --limit 1 /Sandboxes/Mathieu`;

$svn_log =~ /^r([0-9]+) /m;

$ver = $1;

$mp = "Sporadic_Games_Ad_Hoc_Provisioning_Profile.mobileprovision";

$ipa = "SporadicM24.ipa";

$sendmail = "/usr/sbin/sendmail" ;

$from = "scott\@magnolia-heights.com";

$to = "Scott.C.Marks\@gmail.com";

$subject = "SporadicM24 AdHoc distribution based on repo ver $ver";

print "$subject\n";

open( MAIL, "|$sendmail -oi -t" );

print MAIL "From: $from\n";

print MAIL "To: $to\n";

print MAIL "Subject: $subject\n";

print MAIL "\n",
      "Start iTunes and connect your iPhone.\n",
      "\n",
      `uuencode $mp $mp`,
      "\n",
      "Drag-and-drop the mobileprovision to iTunes.\n",
      "\n",
      "\n",
      `uuencode $ipa $ipa`,
      "\n",
      "Double-click on the ipa.\n" ;

close( MAIL );
