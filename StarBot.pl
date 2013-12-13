#!/usr/bin/perl -w

use strict;
use File::Tail;

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
  name => "The sentient StarBound bot.",
)->run;
 
sub connected {
  my $self = shift;
  print "** Connected to $server:$port!\n";
  $SIG{'INT'} = sub {
    my $body = "Control-c detected. Goodbye cruel world!";
    $self->log($body);
    $self->shutdown($body); 
  };
}

sub said {
  my ($self,$message) = @_;
  my $body = $message->{body};
  my $user = $message->{who};

  $self->log("Message caught: $body\n");
  if ($body =~ /^\..*?$/) {
    return  "${user}: I'm sorry I don't understand any commands at the moment.";
  }
  if ($body =~ /$nick/i) {
    return  "${user}: What now?";
  }
}


sub chanjoin {
  my ($self,$message) = @_;
  my $user = $message->{who};
  my $chan = $message->{channel};
  if ($chan ne $channel) {
    return;
  }
  
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
    } else {
      $self->say(channel => $chan, body => "Welcome back $user!");
    }
  }
}

sub watch_log {
  print "Tailing $log_file\n";
  my $tail = File::Tail->new(
    name => $log_file,
    interval => 1,
    debug => 1,
  );
  while(my $line = $tail->read()) {
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
  print "No longer tailing $log_file\n";
}

