package O2CMS::Template::Taglibs::O2CMS::Page;

# Defines tag interface for the slots. The actual implementation resides at O2CMS::Publisher::

use strict;

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  $params{pageRenderer} = $params{parser}->getProperty('pageRenderer');
  die "No page-renderer supplied" unless ref $params{pageRenderer};

  my $obj = bless \%params, $package;

  my %methods = (
    slot         => 'prefix',
    slotChildren => 'postfix',
    slotString   => '',
    slotImage    => '',
    slotObject   => '',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub slot {
  my ($obj, %params) = @_;
  my $html = $obj->{pageRenderer}->renderSlot(%params);
  return $html;
}
#----------------------------------------------------
sub slotChildren {
  my ($obj, %params) = @_;
  my $html = $obj->{pageRenderer}->renderSlotChildren(%params);
  return $html;
}
#----------------------------------------------------
sub slotString {
  my ($obj, %params) = @_;
  return $obj->{pageRenderer}->renderObjectString(%params);
}
#----------------------------------------------------
sub slotObject {
  my ($obj, %params) = @_;
  return '<div style="background:#808080">objectdrop</div>';
}
#----------------------------------------------------
sub slotImage {
  my ($obj, %params) = @_;
  return $obj->{pageRenderer}->renderObjectImage(%params);
}
#----------------------------------------------------
1;
