package O2CMS::Obj::Feed::Rss::Item;

sub new {
  my ($pkg, %init) = @_;
  return bless({%init}, $pkg);
}

sub getTitle {
  my ($obj) = @_;
  return $obj->{title};
}

sub getLink {
  my ($obj) = @_;
  return $obj->{link};
}

sub getDescription {
  my ($obj) = @_;
  return $obj->{description};
}

sub getAuthor {
  my ($obj) = @_;
  return $obj->{author};
}

sub getPubDate {
  my ($obj) = @_;
  return $obj->{pubDate};
}

sub getCategory {
  my ($obj) = @_;
  return $obj->{category};
}

1;
