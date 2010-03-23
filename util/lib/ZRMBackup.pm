package ZRMBackup;
use strict;
use 5.008;
use warnings FATAL => 'all';

use English qw(-no_match_vars);
use Data::Dumper;

use ProcessLog;

sub new {
  my ( $class, $pl, $backup_dir ) = @_;
  my $self = ();
  $self->{pl} = $pl;
  $self->{backup_dir} = $backup_dir;
  bless $self, $class;

  unless( $self->_load_index() ) {
    return undef;
  }
  return $self;
}

# Returns the backup directory this ZRMBackup object represents
sub backup_dir {
  my ($self) = @_;
  return $self->{backup_dir};
}

# Returns a new ZRMBackup instance
# containing the previous backup's information.
# Can be used to walk back to a full backup for restore purposes.
sub open_last_backup {
  my ($self) = @_;
  return ZRMBackup->new($self->{pl}, $self->last_backup);
};

# Returns ($tar_return_code, $fh_of_tar_errors) in list context;
# and, $tar_return_code in scalar context.
# If there was an error executing tar for some reason,
# then the return code will be undef.
#
# Extract this backup to the specified directory.
# Requires tar to be in path.
sub extract_to {
  my ($self, $xdir) = @_;
  my @args = ("tar","-xzf", $self->backup_dir . "/backup-data", "-C", $xdir);
  my $r = $self->{pl}->x(sub { system(@_) }, @args);
  return wantarray ? ($r->{rcode}, $r->{fh}) : $r->{rcode};
}

## Example indexes
# backup-set=vty02
# backup-date=20100226124001
# mysql-server-os=Linux/Unix
# backup-type=regular
# host=db04
# backup-date-epoch=1267216801
# retention-policy=2W
# mysql-zrm-version=ZRM for MySQL Community Edition - version 2.1
# mysql-version=5.1.34-log
# backup-directory=/backups/vty02/20100226124001
# backup-level=1
# replication=master.info relay-log.info
# incremental=mysql-bin.[0-9]*
# next-binlog=mysql-bin.001958
# last-backup=/backups/vty02/20100226084001
# /backups/vty02/20100226124001/master.info=51fed0d70ab28254380e8416cc210ae0
# /backups/vty02/20100226124001/mysql-bin.001957=1e2ac040fa05c82842d2a94e465f2fdd
# /backups/vty02/20100226124001/relay-log.info=6c90fbf5e00ae833ab2ca0305185dc6c
# backup-size=3.50 MB
# compress=/usr/local/bin/gzip_fast.sh
# backup-size-compressed=0.55 MB
# read-locks-time=00:00:00
# flush-logs-time=00:00:00
# compress-encrypt-time=00:00:00
# backup-time=00:00:02
# backup-status=Backup succeeded
#
#
# backup-set=c2
# backup-date=20100226124502
# mysql-server-os=Linux/Unix
# host=c2s
# backup-date-epoch=1267217102
# retention-policy=2W
# mysql-zrm-version=ZRM for MySQL Community Edition - version 2.0
# mysql-version=5.0.84-percona-highperf-b18-log
# backup-directory=/bk1/backups/c2/20100226124502
# backup-level=1
# incremental=mysql-bin.[0-9]*
# next-binlog=mysql-bin.031414
# last-backup=/bk1/backups/c2/20100226084502
# backup-size=619.61 MB
# compress=/usr/local/bin/gzip_fast.sh
# backup-size-compressed=108.40 MB
# read-locks-time=00:00:00
# flush-logs-time=00:00:00
# compress-encrypt-time=00:03:20
# backup-time=00:01:08
# backup-status=Backup succeeded
#

sub _load_index() {
  my ($self) = @_;
  my $fIdx;
  unless(open $fIdx, "<$self->{backup_dir}/index") {
    return undef;
  }
  $self->{idx} = ();
  while(<$fIdx>) {
    # Newlines will screw up later transformations.
    chomp;
    next if $_ eq ""; # Skip empty lines.
    my ($k, $v) = split(/=/, $_, 2);
    next if ($k eq "");
    $k =~ s/-/_/g;
    next if $k =~ /\//; # File lists are useless to us right now.
    # Convert backup sizes to kilobytes
    # kilos are easier to work with, usually.
    if($k eq "backup_size" or $k eq "backup_size_compressed") {
      $v =~ s/ MB$//;
      $v *= 1024;
    }
    # Normalize backup_status to something more easily tested.
    elsif($k eq "backup_status") {
      if($v eq "Backup succeeded") {
        $v = 1;
      }
      else {
        $v = 0;
      }
    }
    # Convet time keys to seconds for easier manipulation.
    elsif($k =~ /_time$/) {
      my ($h, $m, $s) = split(/:/, $v);
      $v  = $h*3600;
      $v += $m*60;
      $v += $s;
    }
    # Make these a real array.
    elsif($k eq "raw_databases_snapshot" or $k eq "replication") {
      my @t = split(/\s+/, $v);
      $v = \@t;
    }
    $self->{idx}{$k} = $v;
  }
  return 1;
}

# Expose $self->{idx}{$name} as $bk_inst->$name
# For convienience, and, since, this thing is just a wrapper
# around that data.
our $AUTOLOAD;
sub AUTOLOAD {
  my ($self) = @_;
  ref($self) or die("Not an instance of ZRMBackup.");
  my $name = $AUTOLOAD;
  $name =~ s/.*:://;
  $self->{pl}->d("AUTOLOAD:", $name, '->', $self->{idx}{$name});
  if(exists $self->{idx}{$name}) {
    return $self->{idx}{$name};
  }
  return undef;
};

1;