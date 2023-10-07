#!/usr/bin/perl

use strict;
use warnings FATAL => qw(all);

use feature 'signatures';
no warnings 'experimental::signatures';

use utf8;
use open qw( :std :encoding(UTF-8) );

use File::Basename qw(basename dirname);
use List::Util qw(first);
use Getopt::Long;

use Data::Dumper;

my $dirname = dirname(__FILE__);
my $COLOR_FILE="$dirname/catppuccin-dark-code.tmuxtheme";
my $HOME = $ENV{HOME};

sub read_colors {
   my $colors = {};
   open(FH, '<', $COLOR_FILE) or die $!;
   while(<FH>){
      $colors->{$1} = $2 if m/thm_(.+)="(.+)"/;
   }
   return $colors;
}

my $C = {
   bg => "#303030",
   fg => "#808080",
   bg2 => "#403d3d",
   fg2 => "#969696",
   cyan => "#89dceb",
   black => "#181825",
   gray => "#808080",
   magenta => "#cba6f7",
   pink => "#f5c2e7",
   red => "#800000",
   green => "#5f875f",
   yellow => "#f9e2af",
   blue => "#13385c",
   light_orange => "#d7875f",
   orange => "#d75f00",
   black4 => "#585b70",
};
# read_colors();

my $icons = {
   user => "",
   host => "󰒋",
   time => "",
   dir => "",
   shell => "",
   lang => "󰗊",
   session => "",
   # left_sep => "",
   # right_sep => "",
   left_sep => "",
   right_sep => "",
   left_sep_thin => "",
   right_sep_thin => "",
   circle_left_sep => "",
   circle_right_sep => "",
   circle_left_sep_thin => "",
   circle_right_sep_thin => "",
   slash => "",
};

sub color($fg, $bg, $no) {
   $fg //= 'fg'; $bg //= 'bg'; $no //= 0;
   
   my $no_str = $no
      ? ",nobold,nounderscore,noitalics"
      : "";
   return sprintf("#[fg=%s,bg=%s%s]", $C->{$fg}, $C->{$bg}, $no_str);
}

sub stop_font {
   return color(undef, undef, 1)
}

sub build_data($data) {
   my $str = "";
   my $elements = $data->{e};
   for my $i (0..$#{$elements}) {
      my $e = $elements->[$i];
      my $spec = $data->{$i} // {};

      my $fg = $spec->{fg} // $data->{fg} // 'fg';
      my $bg = $spec->{bg} // $data->{bg} // 'bg';
      my $no = $spec->{no} // 0;
      my $color = color($fg, $bg, $no);

      $str .= $color;
      $str .= $e;
   }
   return $str;
}

sub get_tmux_output($cmd, $keys) {
   open(my $out, '-|', @$cmd);
   binmode($out, ":encoding(UTF-8)");
   my $res = [];
   while (<$out>) {
      chomp $_;
      my @vals = split '\|', $_;
      my %hash = map {$keys->[$_], $vals[$_]} (0..$#vals);
      push @$res, \%hash;
   }
   close $out;
   return $res;
}

my $cmd_icons = {
   'perl' => ' ',
   'sh' => ' ',
   'bash' => ' ',
   'zsh' => ' ',
   'vim' => ' ',
   'projects.pl' => ' ',
   'viman' => ' ',
   'perlman' => ' ',
};

sub get_dir($path) {
   return if $path eq $HOME;
   my $dir = basename($path);
   return get_short_name($dir);
}

sub get_short_name($name) {
   my ($s_name, $ext) = $name =~ m|^(.+)\.(\w+)$|;
   $s_name //= $name;
   $ext //= "";

   if (length $s_name > 6) {
      (my $seps = $s_name) =~ s/\w//g;
      $s_name = substr $s_name, 0, 6 if length $seps == 0;
   }

   if (length $s_name > 6) {
      $s_name =~ s/(\w+)/substr $1, 0, 2/ge;
      $s_name =~ s/(\s)+/$1/g;
   }

   if ($ext) {
      $s_name = sprintf('%s.%s',
         substr($s_name, 0, 5 - length($ext)),
         $ext );
   } else {
      $s_name = substr $s_name, 0, 6;
   };
   
   return $s_name;
}

my $inverse_color = {
   bg => 'fg',
   bg2 => 'fg2',
   light_orange => 'bg',
};

sub get_main_color($index, $active_index, $len) {
   my $color = $index % 2 == 0 
      ? 'bg'
      : 'bg2';
   $color = 'light_orange' if $index == $active_index;
   $color = 'bg' if $index > $len;
   return $color;
}

sub get_chain_color($index, $active_index, $len) {
   my $bg_color = get_main_color($index, $active_index, $len);
   my $fg_color = $inverse_color->{$bg_color};
   
   return ($bg_color, $fg_color);
}

sub reverse_data($data) {
   $data->{e} = [reverse @{$data->{e}}];
   my $l = $#{$data->{e}};

   my %cache = ();
   for my $k (keys %$data) {
      next if $k !~ /^\d+/;
      my $new_k = $l - $k;

      $cache{$new_k} = $data->{$new_k} if exists $data->{$new_k};
      $data->{$new_k} = delete $cache{$k} // $data->{$k};
   }
}

sub build_chain($chain, $active_index, $dir) {
   my $build_data = {};
   my $e = [];
   my $c = 0;
   my $separator = $dir ? $icons->{right_sep} : $icons->{left_sep};

   my $l = $#{$chain};

   $chain = [reverse @$chain] if $dir;
   $active_index = $l - $active_index if $dir;

   for my $i (0..$l) {
      my $element = $chain->[$i];
      push @$e, $element;
      my ($bg, $fg) = get_chain_color($i, $active_index, $l);
      $build_data->{$c} = {bg => $bg, fg => $fg};
      $c++;
      
      my $is_close = ($i == $l && $i % 2 == 0 && $i != $active_index);
      if ($is_close) {
         push @$e, $dir ? $icons->{right_sep_thin} : $icons->{left_sep_thin};
      } else {
         push @$e, $separator;
      }
      my ($bg_next, $fg_next) = get_chain_color($i+1, $active_index, $l);
      $build_data->{$c} = {bg => $bg_next, fg => $bg} if !$is_close;
      $build_data->{$c} = {bg => $bg, fg => $fg} if $is_close;
      $c++;
   }
   $build_data->{e} = $e;

   reverse_data($build_data) if $dir;

   push @{$build_data->{e}}, stop_font();
   return $build_data;
}

sub dive_process($ppid, $stop_arr) {
   my $request = `ps --ppid $ppid -o pid=,cmd=`;
   return if ! $request;
   chomp $request;

   my ($pid, $cmd) = $request =~ m/(\d+) (.+)/;
   # print Dumper {pid => $pid, cmd => $cmd};
   for my $p (@$stop_arr) {
      my @matches = ($cmd =~ $p);
      return [@matches] if @matches > 0;
   }
   return dive_process($pid, $stop_arr);
}

my $stop_process_search = [
   qr/(vim) .+/,
   qr/(projects.pl) -m projects/,
   qr#/(viman) (.+)#,
   qr#/(perlman) (.+)#,
];

sub build_title($w, $dir) {
   my $extracted = dive_process($w->{pid}, $stop_process_search) // [$w->{cmd}];
   my $cmd_name = shift @$extracted;

   my $cmd_arg = shift @$extracted // "";
   $cmd_arg = $w->{name} if grep /^$cmd_name$/, ('projects.pl', 'vim');

   my $cmd_arg_short = get_short_name($cmd_arg) if $cmd_arg;
   my $icon = $cmd_icons->{$cmd_name} // "";

   my @res = ();
   push @res, ' ' . $icon if $icon;
   push @res, $cmd_arg_short if $cmd_arg_short;
   push @res, $dir if $dir && grep /^$cmd_name$/, ('zsh', 'bash');
   return join '', @res;
}

sub windows {
   my $request = `tmux display-message -p '#{active_window_index}|#S'`;
   chomp $request;
   my ($active_w, $active_s) = split(/\|/, $request, 2);
   # print Dumper {cur_i => $active_w, cur_s => $active_s};
   my $filter = " -f\"#{==:#S,$active_s}\"";
   my $tmux_cmd = [q(tmux list-panes -a -F "#I|#W|#{pane_current_command}|#{pane_current_path}|#{pane_pid}") . $filter];

   # print Dumper $tmux_cmd;
   my $panes = get_tmux_output(
      $tmux_cmd,
      [qw(index name cmd path pid)],
   );
   
   my $active_w_i = 0;
   my $chain = [];
   my $win_title = [];
   my $cur_window = first {$_->{index} == $active_w} @$panes;
   
   my $last_path = '';

   for my $i (0..$#{$panes}) {
      my $p = $panes->[$i];

      my $dir = get_dir($p->{path}) if $p->{path} ne $last_path;
      $last_path = $p->{path};

      my $title = build_title($p, $dir) // "";
      push @$win_title, $title;

      if ($i == $#{$panes} || $p->{index} != $panes->[$i+1]{index}) {
         push @$chain, join( $icons->{slash}, @$win_title );
         $win_title = [];
         $active_w_i = $#{$chain} if $p->{index} == $active_w;
      }
   }
   return build_data(build_chain($chain, $active_w_i, 0));
}

my $session_icons = {
   'workspace' => ' ',
   'Obsidian Vault' => ' ',
   'db' => ' ',
   'dotfiles' => ' ',
   'books' => ' ',
};

sub sessions {
   my $cur_index = `tmux display-message -p '#{session_id}'`;
   chomp $cur_index;

   my $sessions = get_tmux_output(
      [q(tmux list-sessions -F "#S|#{session_id}|#{session_windows}")],
      [qw(name id nr_window)],
   );

   my $cur_i = 0;
   my $chain = [];
   # my $cur_session = first {$_->{index} == $cur_index} @$sessions;

   for my $i (0..$#{$sessions}) {

      my $s = $sessions->[$i];

      $cur_i = $i if $s->{id} eq $cur_index;

      my @e = ('');
      my $icon = $session_icons->{$s->{name}} // "";
      push @e, $icon if $icon; 
      my $name = get_short_name($s->{name}) // "" if ! $icon;
      push @e, $name if $name;
      push @e, $s->{nr_window};
      push @$chain, join(' ', @e);
   }
   return build_data(build_chain($chain, $cur_i, 1));
}

sub language {

   my $language = uc `cat \$XDG_CACHE_HOME/windows_events/lang`;
   chomp $language;
   my $e = [$icons->{circle_left_sep}, $language, $icons->{circle_right_sep}];
   
   my $main_color = $language eq 'RU'
      ? 'orange'
      : 'green';

   my $build_data = {
      e => $e,
      1 => {fg => 'bg', bg => $main_color},
      fg => $main_color,
   };

   # local lang_fg_color="#{?#{==:$language,ru},#[fg=$thm_orange],#[fg=$thm_green]}"
   # local lang_bg_color="#{?#{==:$language,ru},#[bg=$thm_orange],#[bg=$thm_green]}"
   # readonly show_lang="$lang_fg_color#[bg=$thm_bg]$right_separator#[fg=$thm_bg]$lang_bg_color$language$lang_fg_color#[bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg] "
   
   return build_data($build_data);
}

sub status_left {
   my $l = windows();
   my $m = middle();
   my $r = sessions();
   printf "%s#[align=centre]%s#[align=right]%s", $l, $m, $r;   
}

sub middle {
   my @a = (language());
   return join(' ', @a);
}

sub status_right {
   print ""
}

my $WINDOW_STATUS_FORMAT     = ["$icons->{left_sep_thin}"  ,'#I ', '#W', stop_font()];
my $WINDOW_STATUS_FORMAT_CUR = ["$icons->{left_sep}"       ,'#I ', '#W', "$icons->{left_sep}", stop_font()];

sub window_status_format {
   my $data = {
      e => $WINDOW_STATUS_FORMAT,
      2 => {fg => 'gray'},
   };

   print build_data($data);
}

sub window_status_current_format {
   my $data = {
      e => $WINDOW_STATUS_FORMAT_CUR,
      3 => {fg => 'light_orange', bg => 'bg'},
      bg => 'light_orange',
      fg => 'bg'
   };

   print build_data($data) . "\n";
}

sub main {
   GetOptions(
      "status-left" => \&status_left,
      "status-right" => \&status_right,
      "window-status-format" => \&window_status_format,
      "window-status-current-format" => \&window_status_current_format,
      "windows" => \&windows,
      "sessions" => \&sessions,
      "middle" => \&middle,
   ) or die
      +<<~ "USAGE";
      Get tmux option
      usage: $0
            --status-left
            --status-right
            --window-status-format
            --window-status-current-format
      USAGE
}

main();

