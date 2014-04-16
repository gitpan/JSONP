package JSONP;

use Time::HiRes qw(gettimeofday);
use CGI qw(:cgi -utf8);
use Digest::SHA;
use strict;
use JSON;
use v5.8;
our $VERSION = '0.61';

=head1 NAME

JSONP - a module to build JavaScript Object Notation with Padding web services

=head1 SYNOPSIS

=over 2

=item * under CGI environment:

You can pass the name of instance variable, skipping the I<-E<gt>new> call.
If you prefer, you can use I<-E<gt>new> just passing nothing in I<use>.

	use JSONP 'jsonp';
	$jsonp->run;

	...

	sub yoursubname{
		$j->table->fields($sh->{NAME});
		$j->table->data($sh->fetchall_arrayref);
	}

OR

	use JSONP;

	my $j = JSONP->new;
	$j->run;

	...

	sub yoursubname{
		$j->table->fields($sh->{NAME});
		$j->table->data($sh->fetchall_arrayref);
	}

=item * under mod_perl:

You must declare the instance variable, remember to use I<local our>.

	use JSONP;
	local our $j = JSONP->new;
	$j->run;

	...

	sub yoursubname{
		$j->table->fields($sh->{NAME});
		$j->table->data($sh->fetchall_arrayref);
	}

option setting methods allow for chained calls:

	use JSONP;
	local our $j = JSONP->new;
	$j->aaa('your_session_sub')->login('your_login_sub')->debug->insecure->run;

	...

	sub yoursubname{
		$j->table->fields($sh->{NAME});
		$j->table->data($sh->fetchall_arrayref);
	}

just make sure I<run> it is the last element in chain.

=back

the module will call automatically the sub which name is specified in the req parameter of GET/POST request. JSONP will check if the sub exists in current script namespace by looking in typeglob and only in that case the sub will be called. The built-in policy about function names requires also a name starting by a lowercase letter, followed by up to 31 characters chosen between letters, numbers, and underscores. Since this module is intended to be used by AJAX calls, this will spare you to define routes and mappings between requests and back end code. In your subroutines you will therefore add all the data you want to the JSONP object instance in form of hashmap of any deep and complexity, JSONP will return that data automatically as JSON object with padding (by using the function name passed as 'callback' in GET/POST request, or using simply 'callback' as default) to the calling javascript. Please note that I<params> and I<session> keys on top of JSONP object hierarchy are reserved. See also "I<notation convenience features>" paragraph at the end of the POD.
The jQuery call:

	// note that jQuery will automatically chose a non-clashing callback name when you insert callback=? in request
	$.getJSON(yourwebserverhost + '?req=yoursubname&firstparam=firstvalue&...&callback=?', function(data){
		//your callback code
	});

processed by JSONP, will execute I<yoursubname> in your script if it exists, otherwise will return a JSONP codified error. The default error objext returned by this module in its root level has a boolean "error" flag and an "errors" array where you can put a list of your customized errors. The structure of the elements of the array is of course free so you can adapt it to your needs and frameworks.

you can autovivify the response hash omiting braces

	$jsonp->firstlevelhashvalue('I am a first level hash value');
	$jsonp->first->second('I am a second level hash value');

you can then access hash values either with or without braces notation

	$jsonp->firstlevelhashvalue(5);
	print $jsonp->firstlevelhashvalue; # will print 5

it is equivalent to:

	$jsonp->{firstlevelhashvalue} = 5;
	print $jsonp->{firstlevelhashvalue};

you can even build a tree:

	$jsonp->first->second('hello!'); 
	print $jsonp->first->second; # will print "hello!"

it is the same as: 

	$jsonp->{first}->{second} = 'hello!';
	print $jsonp->{first}->{second};

or (the perl "array rule"):

	$jsonp->{first}{second} = 'hello!';
	print $jsonp->{first}{second};

or even (deference ref):

	$$jsonp{first}{second} = 'hello!';
	print $$jsonp{first}{second};

you can freely interleave above listed styles in order to access to elements of JSONP object. As usual, respect I<_private> variables if you don't know what you are doing.

DONT'T DO THIS! :

	$jsonp->first(5);
	$jsonp->first->second('something'); # Internal Server Error here

=head1 VERSION

	0.61

=head1 DESCRIPTION

The purpose of JSONP is to give an easy and fast way to build JSON only web services that can be used even from a different domain from which one they are hosted on. It is supplied only the object interface: this module does not export any symbol, apart the optional pointer to its own instance in the CGI environment.
Once you have the instance of JSONP, you can build a response hash tree, containing whatever data structure, that will be automatically sent back as JSON object to the calling page. The built-in automatic cookie session keeping uses a secure SHA256 to build the session key. The related cookie is HttpOnly, Secure (only SSL) and with path set way down the one of current script (keep the authentication script in the root of your scripts path to share session among all scripts). For high trusted intranet environments a method to disable the Secure flag has been supplied. The automatically built cookie key will be long exactly 64 chars (hex format). 
You have to provide the string name or sub ref (the module accepts either way) of your own I<aaa> and I<login> functions. The AAA (aaa) function will get called upon every request with the session key (retrieved from session cookie or newly created for brand new sessions) as argument. That way you will be free to implement routines for authentication, authorization, access, and session tracking that most suit your needs, together with rules for user/groups to access the methods you expose. Your AAA function must return the session string (if you previously saved it, read on) if a valid session exists under the given key. A return value evaluated as false by perl will result in a 'forbidden' response (you can add as much errors as you want in the I<errors> array of response object). If you want you can check the invoked method under the req parameter (see query method) in order to implement your own access policies. The AAA function will be called a second time just before the response to client will be sent out, with the session key as first argument, and a serialized string of the B<session> branch as second (as you would have modified it inside your called function). This way if your AAA function gets called with only one paramenter it is the begin of the request cycle, and you have to retrieve and check the session saved in your storage of chose (memcached, database, whatever), if it gets called with two arguments you can save the updated session object (already serialized as UTF-8 JSON) to the storage under the given key. The B<session> key of JSONP object will be reserved for session tracking, everything you will save in that branch will be passed serialized to your AAA function right before the response to client. It will be also populated after the serialized string you will return from your AAA function at the beginning of the cycle. The login function will get called with the current session key (from cookie or newly created) as parameter, you can retrieve the username and password passed by the query method, as all other parameters. This way you will be free to give whatever name you like to those two parameters.
So if you need to add a method/call/feature to your application you have only to add a sub with same name you will pass under I<req> parameter.

=head2 METHODS

=cut

sub import{
	my ($self, $name) = @_;
	return if $ENV{MOD_PERL};
	return unless $name;
	die 'not valid variable name' unless $name =~ /^[a-z][0-9a-zA-Z_]{1,31}$/;
	my $symbol = caller() . '::' . $name;
	{
		no strict 'refs';
		*$symbol = \JSONP->new;
	}
}

=head3 new

class constructor, it does not accept any parameter by user. The options have to be set by calling correspondant methods (see below)

=cut

sub new{
	my ($class) = @_;
	my $self = {};
	$self->{_json} = JSON->new;
	$self->{_json}->utf8->allow_nonref->allow_blessed->convert_blessed;
	#$self->{_mod_perl} = defined $ENV{MOD_PERL};
	#$ENV{PATH} = '' if $self->{_taint_mode} = ${^TAINT};
	bless $self, $class;
}

=head3 run

executes the subroutine specified by req paramenter, if it exists, and returns the JSON output object to the calling browser. This have to be the last method called from JSONP object, because it will call the requested function and return the set object as JSON one.

=cut

sub run{
	my $self = shift;
	die "you have to provide an AAA function" unless $self->{_aaa_sub};
	my $r = CGI->new;
	$self->{params} = $r->Vars;
	my $req = $self->{params}->{req};
	$req =~ /^([a-z][0-9a-zA-Z_]{1,31})$/; $req = $1;
	my $sid = $r->cookie('sid');
	my $header = {-type => 'application/javascript', -charset => 'UTF-8'};
	unless ( $sid ) {
		my $h = Digest::SHA->new(256);
		my @us = gettimeofday;
		$h->add(@us, map($r->http($_) , $r->http() )) if	$self->{_insecure_session};
		$h->add(@us, map($r->https($_), $r->https())) unless	$self->{_insecure_session};
		$sid = $h->hexdigest;
		my $current_path = $r->url(-absolute=>1);
		$current_path =~ s|/[^/]*$||;
		my $cookie = {
			-name		=> 'sid',
			-value		=> $sid,
			-path		=> $current_path,
			-secure		=> !$self->{_insecure_session},
			-httponly	=> 1 
		};
		$cookie->{-expires} = "+$$self{_session_expiration}s" if $self->{_session_expiration};
		$header->{-cookie} = $r->cookie($cookie); 
	}

	my $map = caller() . '::' . $req;
	my $session = $self->{_aaa_sub}->($sid);
	$self->{session} = $self->{_json}->pretty($self->{_debug})->decode($session || '{}');
	$self->_rebuild_session($self->{session});
	if ($session && defined &$map || \&$map == $self->{_login_sub}) {
		eval {
			no strict 'refs';
			&$map($sid);
		};
		$self->{debug}->{eval} = $@ if $self->{_debug};
		$self->{_aaa_sub}->($sid, $self->{_json}->pretty($self->{_debug})->encode($self->{session}));
	}
	else{
		$self->{error} = 1;
		push @{$self->{errors}}, 'forbidden';
	}

	print $r->header($header);
	my $callback = $self->{params}->{callback} || 'callback';
	print "$callback(" unless $self->{_plain_json};
	print $self->{_json}->pretty($self->{_debug})->encode($self);
	print ')' unless $self->{_plain_json};
}

=head3 debug

call this method before to call C<run> to enable debug mode in a test environment, basically this one will output pretty printed JSON instead of "compressed" one. You can pass a switch to this method (that will be parsed as bool) to set it I<on> or I<off>. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true. Example:

    $j->debug->run;

is the same as:
    
    $j->debug(1)->run;

=cut

sub debug{
	my ($self, $switch) = @_;
    $switch = 1 unless defined $switch;
    $switch = !!$switch;
	$self->{_debug} = $switch;
	$self;
}

=head3 insecure

call this method if you are going to deploy the script under plain http protocol instead of https. This method can be useful during testing of your application. You can pass a switch to this method (that will parsed as bool) to set it on or off. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true.

=cut

sub insecure{
	my ($self, $switch) = @_;
    $switch = 1 unless defined $switch;
    $switch = !!$switch;
	$self->{_insecure_session} = $switch;
	$self;
}

=head3 set_session_expiration

call this method with desired expiration time for cookie in B<seconds>, the default behavior is to keep the cookie until the end of session (until the browser is closed).

=cut

sub set_session_expiration{
	my ($self, $expiration) = @_;
	$self->{_session_expiration} = $expiration;
	$self;
}

=head3 query

call this method to retrieve a named parameter, $jsonp->query(paramenter_name) will return the value of paramenter_name from query string. The method called without arguments returns all parameters in hash form

=cut

sub query{
	my ($self, $param) = @_;
	$param ? $self->{params}->{$param} : $self->{params};
}

=head3 plain_json

call this function to enable output in simple JSON format (not enclosed within jquery_callback_name()... ). Do this only when your script is on the same domain of static content. This method can be useful also during testing of your application. You can pass a switch to this method (that will parsed as bool) to set it on or off. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true. 

=cut

sub plain_json{
	my ($self, $switch) = @_;
    $switch = 1 unless defined $switch;
    $switch = !!$switch;
	$self->{_plain_json} = $switch;
	$self;
}

=head3 aaa

pass to this method the reference (or the name, either way will work) of the function under you will manage AAA stuff, like session check, tracking and expiration, and ACL to exposed methods

=cut

sub aaa{
	my ($self, $sub) = @_;
	if (ref $sub eq 'CODE') {
		$self->{_aaa_sub} = $sub;
	}
	else {
		my $map = caller() . '::' . $sub;
		{
			no strict 'refs';
			die "given AAA function does not exist" unless defined &$map;
			$self->{_aaa_sub} = \&$map;
		}
	}
	$self;
}

=head3 login

pass to this method the reference (or the name, either way will work) of the function under you will manage the login process. The function will be called with the current session key (from cookie or automatically created). It will be your own business to save the key-value pair to the storage you choose (database, memcached, NoSQL, and so on). It is advised to keep the initial value associated with the key void, as the serialized I<session> branch of JSONP object will be automatically passed to your aaa function at the end or request cycle, so you should save it from that place. If you want to access/modify the session value do it through the I<session> branch via I<$jsonp-E<gt>session-E<gt>whatever(value)> or I<$jsonp-E<gt>{session}{whatever} = value> or I<$jsonp-E<gt>{session}-E<gt>{whatever} = value> calls.

=cut

sub login{
	my ($self, $sub) = @_;
	if (ref $sub eq 'CODE') {
		$self->{_login_sub} = $sub;
	}
	else {
		my $map = caller() . '::' . $sub;
		{
			no strict 'refs';
			die "given login function does not exist" unless defined &$map;
			$self->{_login_sub} = \&$map;
		}
	}
	$self;
}

sub _rebuild_session{
	my ($self, $node) = @_;
	return unless ref $node eq 'HASH';
	bless $node, ref $self;
	$self->_rebuild_session($node->{$_}) for keys %$node;
}

sub TO_JSON{
	my $self = shift;
	my $output = {};
	for(keys %{$self}){
		next if $_ !~ /^[a-z]/;
		#next if $_ eq 'session';
		$output->{$_} = $self->{$_};
	}
	return $output;
}

# avoid calling AUTOLOAD on destroy
DESTROY{}

AUTOLOAD{
	my $classname =  ref $_[0];
	our $AUTOLOAD =~ /^${classname}::([a-zA-Z][a-zA-Z0-9_]*)$/;
	my $key = $1;
	die "illegal key name, must be of ([a-zA-Z][a-zA-Z0-9_]* form\n$AUTOLOAD" unless $key;
	{
		no strict 'refs';
		*{$AUTOLOAD} = sub{$_[1] ? ($_[0]->{$key} = $_[1]) : ($_[0]->{$key} ? $_[0]->{$key} : ($_[0]->{$key} = bless {}, $classname));};
	}
	goto &$AUTOLOAD;
}

=head1 NOTES

=head2 NOTATION CONVENIENCE FEATURES

In order to achieve autovivification notation shortcut, this module does not make use of perlfilter but does rather some gimmick with AUTOLOAD. Because of this, when you are using the convenience shortcut notation you cannot use all the names of public methods of this module (such I<new>, I<import>, I<run>, and others previously listed on this document) as hash keys, and you must always use use hash keys beginning with a lowercase letter. You can still set/access hash branches of whatever name using the brace notation. It is nonetheless highly discouraged the usage of underscore beginning keys through brace notation, at least at the top level of response hash hierarchy, in order to avoid possible clashes with private variable members of this very module.

=head2 MINIMAL REQUIREMENTS

this module requires at least perl 5.8

=head2 DEPENDENCIES

JSON is the only non-core module used by this one, use of JSON::XS is strongly advised for the sake of performance. JSON::XS is been loaded transparently by JSON module when installed.

=head1 SECURITY

Remember to always:

=over 4

=item 1. use taint mode

=item 2. use parametrized queries to access databases via DBI

=item 3. avoid as much as possible I<qx>, I<system>, I<exec>, and so on

=item 4. use SSL when you are keeping track of sessions

=back

=cut

1;
