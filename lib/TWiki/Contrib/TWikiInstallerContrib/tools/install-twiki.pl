#!/usr/bin/perl -w
# Copyright 2005,2006 Will Norris.  All Rights Reserved.
# License: GPL
use strict;
++$|;

# this simple script performs an installation (local or remote) of foswiki
# through the following two step procedure:
#   1. copy the foswiki-install script to a cgi directory on a server
#      * (you can specify a path to perl, in case your perl is in a weird place or you want to use a perl accelerator) - all perl references will be patched during the install process
#      * (you can specify a cgi script extension if that's a requirement on the server) - everything is configured for the script extension and all script filenames have the extension appended during the installation process
#   2. fetch the foswiki-install page, thereby performing the installation
#      * (installation can be customised by overriding values in the html form (FoswikiFor kernel extension perl WikiAdmin WIKIWEBMASTER force))
#      * after the installation, foswiki-install disables itself
#         * (currently, it deletes itself, though i'd probably prefer to have it change its permissions (but for some reason that didn't work when i tried it))

use Getopt::Long qw( :config bundling auto_version );
use Pod::Usage;
use File::Basename qw( basename );
use URI;
use LWP::Simple qw();
use IO::File;
use POSIX qw( tmpnam );
use Data::Dumper qw( Dumper );
use FindBin;

$main::VERSION = '0.70';
my $Config = {
    kernel => 'LATEST',
    force => 0,
# HELP OPTIONS
    agent => basename( $0 ) . '/' . $main::VERSION,
    verbose => 0,
    help => 0,
    man => 0,
    debug => 0,
};
Getopt::Long::Configure( 'bundling' );
my $result = GetOptions( $Config,
			 'url=s', 'dir=s', 'FoswikiFor=s', 'kernel=s', 'extension=s@',	# FoswikiFor|Personality(Module) ?
			 'perl=s', 'WikiAdmin=s', 'WIKIWEBMASTER=s', 'force|f',
			 'verbose', 'help|?', 'man', 'debug', 'agent=s',
			 );
pod2usage( 1 ) if $Config->{help};
pod2usage({ -exitval => 1, -verbose => 2 }) if $Config->{man};
print Dumper( $Config ) if $Config->{debug};

################################################################################

# check required parameters
my $requiredParameterError = 0;
foreach my $p (qw( url dir ))
{
    $requiredParameterError = 1, warn qq{required parameter "$p" not specified\n} unless $Config->{ $p };
}
exit if $requiredParameterError;

################################################################################

( $Config->{scriptName} ) = $Config->{url} =~ m|.*/(.*(\..*)?)$|;
( $Config->{scriptSuffix} ) = $Config->{scriptName} =~ m|(\..*)$|;
$Config->{scriptSuffix} ||= '';

exit ( PushRemoteFoswikiInstall({ %$Config }) == 0 );

################################################################################

sub logSystem
{
    print STDERR "logSystem: ", Dumper( \@_ ) if $Config->{debug};
    system( @_ );
}

################################################################################

sub PushRemoteFoswikiInstall
{
    my $parms = shift;
    print STDERR "PushRemoteFoswikiInstall: ", Dumper( $parms ) if $parms->{debug};

    die "no url?" unless $parms->{url};
    die "no dir?" unless $parms->{dir};

    open( SCRIPT, '<', "$FindBin::Bin/../foswiki-install" ) or die $!;
    local $/ = undef;
    my $script = <SCRIPT>;
    close SCRIPT;

    # TODO: pick new variable name for $name
    my ( $name, $fh );
    do { $name = tmpnam() }
    until $fh = IO::File->new($name, O_RDWR|O_CREAT|O_EXCL);

    chmod 0755, $name;
    $script =~ s|/usr/bin/perl|$Config->{perl}| if $Config->{perl};
    print $fh $script;

    logSystem( qq{scp -q $name $parms->{dir}/$Config->{scriptName}} );
#    die "Error uploading install script: $!" if $!;

    unlink $name;

    my $urlInstallWithConfig = URI->new( $parms->{url} );
    my $urlParameters = { install => 'install' };
    # add optional parameters
    map { $urlParameters->{$_} = $Config->{$_} if $Config->{$_} } 
    	qw( FoswikiFor kernel extension perl WikiAdmin WIKIWEBMASTER force );
    $urlInstallWithConfig->query_form( $urlParameters );
    $Config->{debug} && print "\n$urlInstallWithConfig\n";

    if ( defined ( my $report = LWP::Simple::get( $urlInstallWithConfig ) ) )
    {
	open( REPORT, '>', 'install-report.html' ) or die $!;
	print REPORT $report;
	close REPORT;
	return 1;
    }
    else
    {
	print "ERROR installing $urlInstallWithConfig\n";
	return 0;
    }
}

################################################################################

__DATA__
=head1 NAME

install-foswwiki.pl - fully automated network Foswiki command-line installation frontend

Copyright 2005,2006, 2010 Will Norris.  All Rights Reserved.

=head1 SYNOPSIS

install-foswiki.pl -url -dir [-kernel] -force|-f [-extension ...]* [-report|-noreport] [-verbose] [-debug] [-help] [-man]

=head1 OPTIONS

=over 8

=item B<-FoswikiFor [FoswikiFor]>				FoswikiFor* filename (only .zip supported atm)

=item B<-url >						url of foswiki-install script to run (this is where foswiki-install is copied to); can include an extension on the script name (eg, .cgi)

=item B<-dir >						filepath to the directory where the script is installed to (related to its url, above)

=item B<-kernel [kernel|LATEST]>			

=item B<-extension>					name of plugin, contrib, or addon to install (eg, SpreadSheetPlugin, TwistyContrib, GetAWebAddon)

=item B<-WikiAdmin>

=item B<-WIKIWEBMASTER>

=item B<-verbose>					show the babblings of the machine

=item B<-debug>						even more output

=item B<-help>, B<-?>

=item B<-man>


=back

=head1 EXAMPLES

time bin/install-foswiki.pl \
    --FoswikiFor=http://personalities.foswiki.org/Foswiki01x00x09.zip \
	--dir=$ACCOUNT@`hostname`:~/public_html/cgi-bin \
	--url=http://`hostname`/~$ACCOUNT/cgi-bin/foswiki-install.cgi \
	--extension=CpanContrib


=head1 DESCRIPTION

B<install-foswiki.pl> ...


=head2 SEE ALSO

  http://foswiki.org/Extensions/FoswikiInstallerContrib

=cut
