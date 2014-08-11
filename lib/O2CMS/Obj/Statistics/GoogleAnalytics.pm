package O2CMS::Obj::Statistics::GoogleAnalytics;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-----------------------------------------------------------------------------
sub canMove {
  return 1;
}
#-----------------------------------------------------------------------------
sub getSiteId {
  my ($obj) = @_;
  return $obj->getMetaParentId();
}
#-----------------------------------------------------------------------------
sub setSiteId {
  "Why is this being called?";
}
#-----------------------------------------------------------------------------
sub getSite {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getSiteId() );
}
#-----------------------------------------------------------------------------
sub getJavascript {
  my ($obj) = @_;
  if (!$obj->getModelValue('javascript') && $obj->getAnalyticsId()) {
    $obj->setJavascript("<script src=\"http://www.google-analytics.com/urchin.js\" type=\"text/javascript\"></script>
<script type=\"text/javascript\">
  _uacct = \"" . $obj->getAnalyticsId() . "\";
  urchinTracker();
</script>");
    $obj->save();
  }
  return $obj->getModelValue('javascript');
}
#-----------------------------------------------------------------------------
sub isCachable {
  return 1;
}
#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
1;
