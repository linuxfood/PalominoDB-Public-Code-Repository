# Copyright (c) 2009-2010, PalominoDB, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
# 
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
# 
#   * Neither the name of PalominoDB, Inc. nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
package AutoIncrement;
use strict;
use warnings FATAL => 'all';
use ProcessLog;
use Exporter;
use MysqlSlave;
use Carp;
use FailoverPlugin;
our @ISA = qw(FailoverPlugin);

sub pre_verification {
  my ($self, $pri_dsn, $fail_dsn) = @_;

  my $pri_s = MysqlSlave->new($pri_dsn);
  my $fail_s = MysqlSlave->new($fail_dsn);
  if($pri_s->auto_inc_off() == $fail_s->auto_inc_off()) {
    $::PLOG->e($pri_dsn->get('h'), 'auto_increment_offset:', $pri_s->auto_inc_off());
    $::PLOG->e($fail_dsn->get('h'), 'auto_increment_offset:', $fail_s->auto_inc_off());
    if($FailoverPlugin::force) {
      $::PLOG->i('Continuing due to --force being passed.');
    }
    croak('Failed pre-verification check: auto_increment_offset') unless($FailoverPlugin::force);
  }
  else {
    $::PLOG->m($pri_dsn->get('h'), 'auto_increment_offset:', $pri_s->auto_inc_off());
    $::PLOG->m($fail_dsn->get('h'), 'auto_increment_offset:', $fail_s->auto_inc_off());
  }
}

1;
