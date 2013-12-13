#!/usr/bin/perl -w

use strict;

package StarBot;
use base 'Bot::BasicBot';

my $nick = 'StarBot';
my $server = 'localhost';
my $port = 6667;
my $channel = '#starbound';
my $log_file = '/home/cnaude/StarBound/linux64/startup.log';
my %seen = ();

print "** Connecting to $server:$port as $nick\n";
StarBot->new(
  server => $server,
  port => $port,
  channels => [$channel],
  nick => $nick,
  alt_nicks => ["${nick}1"],
  username => $nick,
  name => "Who am I?",
)->run;
 
sub connected {
  my $self = shift;
  print "** Connected to $server:$port!\n";
}

sub said {
  my ($self,$message) = @_;
  my $body = $message->{body};
  my $user = $message->{who};

  $self->log("Message caught: $body\n");
  if ($body =~ /^\..*?$/) {
    return  "${user}: I'm sorry I don't understand any commands at the moment.";
  }
}


sub chanjoin {
  my ($self,$message) = @_;
  my $user = $message->{who};
  my $chan = $message->{channel};
  
  $self->log("** User $user has joined $chan");
  if ($user =~ /$nick/i) {
    $self->log("** Forking log_watch started.");
    $self->forkit({ channel => $chan, run => \&watch_log, arguments => [ $self ],
    });
    $self->log("** Forking log_watch done.");
  } else {
    if (!exists $seen{$user}) {
      $seen{$user} = time;
      $self->say(channel => $chan, body => "Welcome $user! Chat is currently game to IRC only at the moment.");
    }
  }
}

sub watch_log {
  my $self = shift;
  open (TAIL, "tail -f -n0 $log_file|");
  while (my $line = <TAIL>) {
    chomp($line);
    my $body = "";
    if ($line =~ /^Info:  <(\w+)> (.*?)$/) {
      $body = "[SB]<${1}> ${2}";
    }
    if ($line =~ /^Info: Client <\d+> <User: (.*?)> disconnected$/) {
      $body = "[SB]${1} has left the game.";
    }
    if ($line =~ /^Info: Client <\d+> <User: (.*?)> connected$/) {
      $body = "[SB]${1} has joined the game.";
    }
    if ($body) {
      print "$body\n";
    }
  }
  close TAIL;
}

$SIG{'INT'} = sub { StarBot->shutdown };
