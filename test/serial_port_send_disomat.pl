#!D:\bin\perl\perl\bin\perl.exe


package main;
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Win32::SerialPort;
  use Time::HiRes qw(usleep);
  use Data::Dumper;

  $| = 1; #flushing output

  my (%serial, %serial_port);
  $serial{comport} = "com";
  $serial{baud} = 19200;
  $serial{parity} = "even";
  $serial{databits} = 8;
  $serial{stopbits} = 2;
  $serial{timeout} = 1500;

  my @ports = (5);
  my $m_send_weight = 0;
  my $m_send_sign = 0;

  foreach ( @ports ) {
	  eval{ $serial_port{$_} = new Win32::SerialPort($serial{comport}.$_);
			$serial_port{$_}->databits($serial{databits});
			$serial_port{$_}->baudrate($serial{baud});
			$serial_port{$_}->parity($serial{parity});
			$serial_port{$_}->stopbits($serial{stopbits});
			$serial_port{$_}->read_interval(10);
			$serial_port{$_}->read_const_time($serial{timeout});
			$serial_port{$_}->error_msg(1);
			$serial_port{$_}->user_msg(1);
			$serial_port{$_}->write_settings;
			print "create $serial{comport}$_\n";
		};# обработка ошибки
  }	
  
  my $message ;#@message;
  my ($count_in, $string_in);
=comm
  $message[0] = chr(154);#pack "H*", ord(0xDC);
  $message[1] = chr(1);
  $message[2] = chr(53); #567
  $message[3] = chr(54);
  $message[4] = chr(55);
  $message[5] = chr(56); #821
  $message[6] = chr(50);
  $message[7] = chr(49);
  $message[8] = chr(50);
  $message[9] = chr(255);
  $message[10] = chr(199);#pack "H*", ord(0xC3);
=cut

  my $start = pack "c1", 0x02;
  my $end = pack "c1", 0x03;
  my $c = 0;
  
  while (1) {
	foreach (@ports) {
	
		#eval{ ($count_in, $string_in) = $serial_port{$_}->read(100) || die print STDERR "$!"; };# обработка ошибки
		eval{ $string_in = $serial_port{$_}->input || die print STDERR "$!"; };# обработка ошибки
		
		last unless $string_in;

		if( $string_in =~ /(00#EK#\d#\d#\d#\d#*)/ ) {
			if (substr($1, 8, 1) == 0) {
				print "$1   EK $string_in\n";
				#print substr($1, 8, 1)." sign \n";
				$message = $start."00#EK#0#0#0#0#".$end;
				print $message."\n";
				eval{ $serial_port{$_}->write($message) || die print STDERR "$!"; };# обработка ошибки
				$m_send_sign = 0;
			}
		}
		if ( $string_in =~ /(00#TK#*)/ ) {
			#print "$1   TK\n" if $string_in =~ /(00#TK#*)/;
			print "$1   TK\n";
			if ( $c == 5 and $m_send_sign == 0 ) {
				$m_send_weight = 1;
			} elsif ( $m_send_weight == 1 and $m_send_sign == 1 ) {
				$m_send_weight = 0;
			}
		}
		
		
#		print "in m_send_weight | $m_send_weight | m_send_sign | $m_send_sign | " .$string_in."\n\n";
		print "m_send_weight | $m_send_weight | m_send_sign | $m_send_sign\n";

		# messages from disomat bluming 1 py-4
		#$message = "|00#TK#0#0#0#0#0#0#0#0#0#0#0#0#0#0#     0,000#      0,000#";
		
		
#		print $message."\n";

		if ( $m_send_sign == 0 ) {
			my $m = sprintf("%.3f", rand(9));
			$m =~ s/\./,/;
			$message = $start."00#TK#0#0#0#0#0#0#0#0#0#0#$m_send_weight#0#0#0#     ".$m."#      0,000#".$end;
			print $message."\n";
			eval{ $serial_port{$_}->write($message) || die print STDERR "$!"; };# обработка ошибки
		}
		
		$string_in = '';
		$c++;
		$c = 0 if ( $c == 6) ;
		$serial_port{$_}->lookclear; # empty buffers
  }
  usleep(1000*1000); #200 millisecond
 }
=cut
	while (1) {
		my $result = $serial_port->read(6*2 + 5);
		print $result;
		sleep(1);
	}
	
#	eval{ $self->{'serial_port'}->close || die $self->{log}->save(2, "Can't close $self->{comport}"); };# обработка ошибки
#	undef $self->{'serial_port'};
#  }
=comm
  sub transmit {
    my($message) = @_; # ссылка на объект
	my($result, $reg_addr, $value, $hex, %values);

	eval{ $self->{'serial_port'}->write($message) || die $self->{log}->save(2, "Can't send data $self->{comport} $!"); };# обработка ошибки
	unless($@) {
		$result = $self->{'serial_port'}->read($self->{conf}->{quantity}*2 + 5);
		
		for (my $i = 0; $i < (length( $result ) - 5)/2; $i++){
			if ($self->{conf}->{data_format} eq "float" and $i%2 != 1){ #$i%2 проверка на четность
				$hex = substr $result, $i*2+3, 4;
				$value = unpack "f*", reverse $hex;
				$reg_addr = 400001 + $self->{conf}->{start_addr} - 1 + $i;
				$self->{log}->save(4, "[$reg_addr] = $value float \t| hex = ". unpack("H*", $hex));
				$values{$self->{conf}->{start_addr} + $i} = { 'timestamp' => time,
															  'value' => $value,
															};
			}

			if ($self->{conf}->{data_format} eq "int"){
				$hex = substr $result, $i*2+3, 2;
				$value = unpack "n", $hex;
				$reg_addr = 400001 + $self->{conf}->{start_addr} - 1 + $i;
				$self->{log}->save(4, "[$reg_addr] = $value int \t| hex = ". unpack("H*", $hex));
				$values{$self->{conf}->{start_addr} + $i} = { 'timestamp' => time,
															  'value' => $value,
															};
			}
		}
	return (%values);
	}
  }
=cut





