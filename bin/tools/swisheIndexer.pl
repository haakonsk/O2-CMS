use strict;

use O2 qw($context);

$context->getSingleton('O2CMS::Search::ObjectIndexer')->index();
