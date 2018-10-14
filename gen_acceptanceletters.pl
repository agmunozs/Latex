#!/usr/bin/env perl
# Author: Jeff Turmelle (jeff@iri.columbia.edu)
# with minimum modifications from Angel G Munoz
#
# Parse a CSV for
# Email, Title, First, Second, Position, Institution, Country, Paid
#
# Only parameter is the input CSV file
#
# Send an email with an attached PDF to all the entries in the CSV file
# message.txt will be the contents of the letter.
#
#

# use MIME::QuotedPrint;
use MIME::Lite;
#use Net::SMTP_auth;
use Mail::Sendmail;
# use Email::MIME::Creator;
use Text::CSV;

use strict;
use warnings;

# Read the message.txt file
open my $fh, 'acceptanceletter_Canicula_English.tex' or die "Can't open file $!";
#open my $fh, 'acceptanceletter_Canicula_English_noscholarship.tex' or die "Can't open file $!";
read $fh, my $file_content, -s $fh;
close $fh;

# Open the CSV File
my $csvfile = shift;
open(my $FD, "<", $csvfile) or die "can't open $csvfile: ";

# Create the CSV Parser
my $CSV = Text::CSV->new( {diag_verbose => 1, auto_diag => 1} );

# Setup the SMTP server for the MIME
# MIME::Lite->send('smtp', 'mail.iri.columbia.edu',
#         Timeout=>60,
#         Debug => 1 );
MIME::Lite->send('sendmail', "/usr/sbin/sendmail -t -oi -oem",
        Timeout=>60),
        Debug => 1 );

# Setup the Mail Parameters
my $from = "Angel G. Munoz <agmunoz\@iri.columbia.edu>";
my $cc   = "Pamela Jordan <pamela\@iri.columbia.edu>";
my $subject = "Acceptance Letter for the Guatemala Workshop";

# Parse each row of the CSV file and send the individual an email with the PDF file
while (<$FD>) {
    chomp;                     # remove end of line chars
    if ( my $status = $CSV->parse($_) ) {
	my ($email, $title, $first, $last, $position, $institute, $country, $paid) = $CSV->fields;
	my ($uid, @rest) = split(/@/, $email);


	my $msgbody = $file_content;
	$msgbody =~ s/SOMEBODY/$first $last/g;
  $msgbody =~ s/INSTITUTE/$institute/g;
  $msgbody =~ s/COUNTRY/$country/g;
  $msgbody =~ s/INSTITUTION/$paid/g;

	# latex creation
	open file1, "> $uid.tex";
	print file1 $msgbody;
	close file1;

	system("pdflatex $uid.tex");

  #system("mail -s $subject $email < $uid.pdf")
	my $emailmsg = MIME::Lite->new(To => $email,
				       From => $from,
               CC => $cc,
				       Subject => $subject,
				       Type => 'multipart/mixed');

	$emailmsg->attach(Type => 'application/pdf',
			  Path => "$uid.pdf",
			  Filename => "Invitation.pdf");

	$emailmsg->send();
    }
}

close($FD);
