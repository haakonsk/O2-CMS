package O2CMS::Backend::Gui::Site::LinkChecker;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $config);

#----------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $obj->display(
    'init.html',
    site         => $context->getObjectById( $obj->getParam('siteId') ),
    hasRunBefore => -e $config->get('o2.customerRoot') . '/var/templates/Site/LinkChecker/' . $obj->_getTemplate( $obj->getParam('siteId') ),
    template     => $obj->_getTemplate(),
  );
}
#----------------------------------------------------------------------
sub showPreviousCheck {
  my ($obj) = @_;
  my $template = $obj->_getTemplate( $obj->getParam('siteId') );
  $obj->display($template);
}
#----------------------------------------------------------------------
sub checkLinks {
  my ($obj) = @_;

  # Untie stdout
  if (!$obj->getParam('isCron')) {
    print "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n"; # Standards compliance mode (to make fixed positioning work in IE7)
    $cgi->output();
    $cgi->killBuffer();
    $| = 1; # Turn off Perl's buffering of the html.
  }

  $obj->getLang->setResourcePath('o2.Site.LinkChecker');

  require LWP::UserAgent;
  require HTML::LinkExtor;

  $obj->{numCheckedUrls}  = 0;
  $obj->{numUrlsToCheck}  = 0;
  $obj->{numMissingLinks} = 0;
  $obj->{site}            = $obj->getObjectByParam('siteId');
  $obj->{ua}              = LWP::UserAgent->new();
  $obj->{ua}->timeout(10); # Timeout after 10 seconds

  $obj->{extractor} = HTML::LinkExtor->new(); # undef, $obj->{site}->getUrl());
  my $html = "<html>
  <head>
    <title>Link checker</title>
    <link rel='stylesheet' type='text/css' href='/css/defaultStyle.css' />
    <script type='text/javascript' src='/js/ajax.js'></script>
    <script type='text/javascript' src='/js/htmlToDom.js'></script>
    <script type='text/javascript' src='/js/o2escape.js'></script>
    <script type='text/javascript'>
      function scroll()
      {
        if (document.body.scrollTop) {
          document.body.scrollTop = document.body.scrollHeight;
        }
        else {
          document.documentElement.scrollTop = document.documentElement.scrollHeight; // Different scrolling in standards compliance mode...
        }
      }
      function setLocale(locale) {
        document.getElementById('locale').innerHTML = locale;
        var statusTable = document.getElementById('status');
        var tr = document.createElement('tr');
        var td = document.createElement('td');
        td.setAttribute('colSpan', 6);
        td.style.textAlign  = 'center';
        td.style.background = '#ffddbb';
        var text = document.createTextNode(locale);
        td.appendChild(text);
        tr.appendChild(td);
        statusTable.appendChild(tr);
      }
      function setNumLinksFollowed(num) {
        document.getElementById('numLinksFollowed').innerHTML = num;
      }
      function setNumLinksFound(num) {
        document.getElementById('numLinksFound').innerHTML = num;
      }
      function setPercentFollowed(percentage) {
        document.getElementById('percentFollowed').innerHTML = percentage;
      }
      function setNumMissingLinks(num) {
        document.getElementById('numMissingLinks').innerHTML = num;
      }
      function setMemoryUsage(value) {
        document.getElementById('memoryUsage').innerHTML = value;
      }
      function setProcessorUsage(value) {
        document.getElementById('processorUsage').innerHTML = value;
      }
      function addTableRow(rowClass, responseCode, status, url, displayUrl, parentUrl, editLink, displayParentUrl, contentType)
      {
        var row, cell, text, link;

        var table = document.getElementById('status');
        row  = document.createElement('tr');
        row.setAttribute('className', rowClass);
        row.setAttribute('class',     rowClass);

        cell = document.createElement('td');
        cell.setAttribute('className', 'numeric responseCode');
        cell.setAttribute('class',     'numeric responseCode');
        text = document.createTextNode(responseCode);
        cell.appendChild(text);
        row.appendChild(cell);

        cell = document.createElement('td');
        cell.setAttribute('className', 'status');
        cell.setAttribute('class',     'status');
        text = document.createTextNode(status);
        cell.appendChild(text);
        row.appendChild(cell);

        cell = document.createElement('td');
        link = document.createElement('a');
        link.setAttribute('href',   url);
        link.setAttribute('title',  url);
        link.setAttribute('target', '_blank');
        text = document.createTextNode(displayUrl);
        link.appendChild(text);
        cell.appendChild(link);
        row.appendChild(cell);

        cell = document.createElement('td');
        link = document.createElement('a');
        link.setAttribute('href',   parentUrl);
        link.setAttribute('title',  parentUrl);
        link.setAttribute('target', '_blank');
        text = document.createTextNode(displayParentUrl);
        link.appendChild(text);
        cell.appendChild(link);
        row.appendChild(cell);

        cell = document.createElement('td');
        cell.setAttribute('className', 'editLink');
        cell.setAttribute('class',     'editLink');
        link = document.createElement('a');
        link.setAttribute('href', 'javascript: ' + editLink);
//        link.setAttribute('onClick', editLink);
        var img = document.createElement('img');
        img.src = '/images/system/edit_16.gif';
        img.style.border = 0;
        if (editLink) {
          link.appendChild(img);
          cell.appendChild(link);
        }
        row.appendChild(cell);

        cell = document.createElement('td');
        cell.setAttribute('className', 'contentType');
        cell.setAttribute('class',     'contentType');
        text = document.createTextNode(contentType);
        cell.appendChild(text);
        row.appendChild(cell);

        table.appendChild(row);
      }
      function hideOkRows() {
        var statusTable = document.getElementById('status');
        var rows = statusTable.getElementsByTagName('tr');
        for (var i = rows.length-1; i >= 0; i--) {
          var row = rows[i];
          if (row.className == 'ok') {
            row.parentNode.removeChild(row);
          }
        }
        scripts = document.body.getElementsByTagName('script');
        for (var i = scripts.length-1; i >= 0; i--) {
          var script = scripts[i];
          script.parentNode.removeChild(script);
        }
      }
      function showReport() {
        document.getElementById('progressTable').className     = 'report';
        document.getElementById('linksFoundRow').style.display = 'none';
        document.getElementById('percentageRow').style.display = 'none';
        document.getElementById('localeRow').style.display     = 'none';
      }
      function saveHtml() {
        o2.ajax.call({
          setDispatcherPath : 'o2cms',
          setClass          : 'Site-LinkChecker',
          setMethod         : 'saveHtml',
          setParams         : 'body=' + escape(document.body.innerHTML) + '&style=' + escape(document.getElementById('style').innerHTML) + '&isAjaxRequest=1&siteId=" . $obj->getParam('siteId') . "',
          handler           : 'htmlSaved',
          method            : 'post'
        });
      }
      function htmlSaved() {
        // That's nice...
      }
    </script>
    <style id='style'>
      .status th {
        background:url(/images/system/header_background_1px_not_active.gif) repeat-x;
        height:25px;
        padding:6px;
        font-size:11px;
        color:#6f6f6f;
        font-weight:bold;
      }
      td {
        white-space: nowrap;
      }
      table.progress {
        position: fixed;
        right: 1px;
        top: 1px;
        background: white;
        border: 1px solid black;
        z-index: 3;
      }
      table.report {
        position: static;
        margin: 0 0 20px 20px;
        border: none;
        font-weight: bold;
      }
      p.dummy {
        visibility: hidden;
        margin: 0;
        padding: 0;
        height: 20px;
      }
      td.numeric {
        text-align: right;
      }
      td.editLink {
        text-align: center;
      }
      tr.ok td.status {
        color: green;
      }
      tr.redirect td.status {
        color: orange;
      }
      tr.notFound td.status {
        color: red;
        font-weight: bold;
      }
      tr.badRequest td.status {
        color: #ff8800;
        font-weight: bold;
      }
      tr.notFoundOrTimeout td.status {
        color: red;
        font-weight: bold;
      }
      tr.unknown td.status {
        color: #ff00ff;
        font-weight: bold;
      }
      td.responseCode,
      td.contentType {
        color: #999999;
      }
    </style>
  </head>
  <body>
    <table class='progress' id='progressTable'>
      <tr>
        <td>" . $obj->getLang()->getString('lblNumLinksFollowed') . ":</td>
        <td class='numeric' id='numLinksFollowed' colspan='2'>0</td>
      </tr>
      <tr id='linksFoundRow'>
        <td>" . $obj->getLang()->getString('lblNumLinksFound') . ":</td>
        <td class='numeric' id='numLinksFound' colspan='2'>0</td>
      </tr>
      <tr id='percentageRow'>
        <td>" . $obj->getLang()->getString('lblPercentageOfLinksFollowed') . ":</td>
        <td class='numeric' id='percentFollowed'>0</td>
        <td>%</td>
      </tr>
      <tr>
        <td>" . $obj->getLang()->getString('lblNumFaultyLinks') . ":</td>
        <td class='numeric' id='numMissingLinks' colspan='2'>0</td>
      </tr>
      <tr id='localeRow'>
        <td>" . $obj->getLang()->getString('lblLocale') . ":</td>
        <td id='locale' colspan='2'></td>
      </tr>
    </table>
    <table class='status'>
      <tbody id='status'>
        <tr class='header' id='statusHeader'>
          <th colspan='2' class='status'>" . $obj->getLang()->getString('headerStatus') . "</th>
          <th class='url'>" . $obj->getLang()->getString('headerUrl') . "</th>
          <th class='url'>" . $obj->getLang()->getString('headerParentPage') . "</th>
          <th class='editButton'>" . $obj->getLang()->getString('headerEdit') . "</th>
          <th class='contentType'>" . $obj->getLang()->getString('headerContentType') . "</th>
        </tr>";
  print $html;
  print "\n    </tbody>\n    </table>\n";
  my $baseUrl = $obj->{site}->getUrl();
  foreach my $locale ($obj->{site}->getAvailableLocales()) {

    $obj->{checkedUrls} = {};
    $obj->{urlsToCheck} = {};

    # Switch to the correct locale
    $obj->{locale} = $locale;

    print "<script type='text/javascript'>setLocale('$locale');</script>";

    my @links = ( $baseUrl );
    $obj->{checkedUrls}->{$baseUrl} = 1;
    $obj->{numCheckedUrls}++;
    $obj->{urlsToCheck}->{$baseUrl} = $baseUrl;
    $obj->{numUrlsToCheck}++;
    while (@links) {
      @links = $obj->_checkLinks( @links );
    }
  }
  print "\n    <script type='text/javascript'>hideOkRows(); showReport(); saveHtml();</script>\n  </body>\n</html>\n";
}
#----------------------------------------------------------------------
sub _getUrlsFromLink {
  my ($obj, $url) = @_;

  $url   =   $url =~ m{ [?] }xms   ?   "$url&forceLocale=$obj->{locale}"   :   "$url?forceLocale=$obj->{locale}";
  my ($parentWebDirectory) = $url =~ m{ \A ([^?]* /) [^/]* \z }xms;

  my @urls;
  my $response = $obj->{ua}->get($url);
  $obj->{extractor}->parse( $response->content() );
  my @links = $obj->{extractor}->links();
  foreach my $linkArray (@links) {
    my @element = @{$linkArray};
    my $tagname = shift @element;
    while (@element) {
      my ($attribute, $_url) = splice(@element, 0, 2);
#      $_url = $_url->as_string();
      next if $_url =~ m{ \A mailto }xms;
      next if $_url =~ m{ \# \z }xms; # XXX Remove
      $_url = $obj->_getCompleteUrl($_url, $parentWebDirectory);
      $_url =~ s{ \# .* \z }{}xms; # Remove part of url after '#'
      next if substr( $_url, 0, length($obj->{site}->getUrl()) ) ne $obj->{site}->getUrl();
      next if $obj->{urlsToCheck}->{$_url};
      next if $obj->{checkedUrls}->{$_url}; # ...
      next if $_url =~ m{ User-Locale/setLocale }xms;
      $obj->{numUrlsToCheck}++;
      $obj->{urlsToCheck}->{$_url} = $url;
      push @urls, $_url;
    }
  }
  return @urls;
}
#----------------------------------------------------------------------
sub _getCompleteUrl {
  my ($obj, $url, $parentWebDirectory) = @_;
  return $url if $url =~ m{ \A https?:// }xms;                             # Already complete
  return $obj->{site}->getUrl() . substr($url, 1) if $url =~ m{ \A / }xms; # Absolute
  # Relative
  my $serverUrl = $obj->{site}->getUrl();
  $url = "$parentWebDirectory$url";
  my ($urlWithoutServer) = $url =~ m{ \A $serverUrl (.*) \z }xms;
  my @urlParts = split /\//, $urlWithoutServer;
  my $i = 0;
  while (1) {
    my $part = $urlParts[$i];
    if ($part && $part ne '..' && $urlParts[$i+1] eq '..') {
      splice @urlParts, $i, 2;
      $i = -1; # Start over
    }
    last if $i >= @urlParts;
    $i++;
  }
  $url = $serverUrl . join('/', @urlParts);
  return $url;
}
#----------------------------------------------------------------------
sub _checkLinks {
  my ($obj, @links) = @_;

  my @moreLinks;
  foreach my $url (@links) {
    my $response     = $obj->{ua}->head($url);
    my $responseCode = $response->code();
    my $contentType  = $response->header('content-type');
    my ($status, $className);
    if ($responseCode eq '200') {
      $status    = 'OK';
      $className = 'ok';
    }
    elsif ($responseCode =~ m{ \A 3\d\d \z }xms) {
      $obj->{numMissingLinks}++;
      $status    = $obj->getLang()->getString('statusRedirect');
      $className = 'redirect';
    }
    elsif ($responseCode eq '400') {
      $obj->{numMissingLinks}++;
      $status    = $obj->getLang()->getString('statusMalformedUrl');
      $className = 'badRequest';
    }
    elsif ($responseCode =~ m{ \A 4\d\d \z }xms) {
      $obj->{numMissingLinks}++;
      $status    = $obj->getLang()->getString('statusMissing');
      $className = 'notFound';
    }
    elsif ($responseCode =~ m{ \A 5\d\d \z }xms) {
      $obj->{numMissingLinks}++;
      $status    = $obj->getLang()->getString('statusMissingOrTimeout');
      $className = 'notFoundOrTimeout';
    }
    else {
      $status    = $obj->getLang()->getString('statusUnknown');
      $className = 'unknown';
    }
    $obj->_printLine($className, $responseCode, $status, $url, $obj->{urlsToCheck}->{$url}, $contentType);
    $obj->{checkedUrls}->{$url} = 1;
    $obj->{numCheckedUrls}++;

    if ($contentType =~ m{ \A text/html }xms) {
      push @moreLinks, $obj->_getUrlsFromLink($url);
    }
  }
  return @moreLinks;
}
#----------------------------------------------------------------------
sub _printLine {
  my ($obj, $className, $responseCode, $status, $url, $parentUrl, $contentType) = @_;

  $obj->{editLinks} = {} unless $obj->{editLinks};
  if (!$obj->{editLinks}->{$parentUrl}) {
    $obj->{editLinks}->{$parentUrl} = $obj->_getEditLink($parentUrl);
  }

  $contentType =~ s{ ; .* \z }{}xms;

  my $maxLength = 53;
  $parentUrl          =   $obj->{urlsToCheck}->{$url};

  my $editLink           =   $obj->{editLinks}->{$parentUrl};
  my $displayUrl         =   length($url)       > $maxLength   ?   substr($url,       0, $maxLength-3) . '...'   :   $url;
  my $displayParentUrl   =   length($parentUrl) > $maxLength   ?   substr($parentUrl, 0, $maxLength-3) . '...'   :   $parentUrl;

  my $numLinksFollowed = $obj->{numCheckedUrls}; # scalar keys %{$obj->{checkedUrls}};
#  if ($numLinksFollowed > 10) {
#    print "  </body>\n</html>";
#    exit;
##    use Data::Dumper; die Dumper(keys %{$obj->{urlsToCheck}});
#  }
  my $numLinksFound    = $obj->{numUrlsToCheck}; # scalar keys %{$obj->{urlsToCheck}};
  my $percentFollowed  = $numLinksFound == 0   ?   0   :   100 * $numLinksFollowed / $numLinksFound;
  require O2::Util::Math;
  my $math = O2::Util::Math->new();
  $percentFollowed = $math->nearest(0.1, $percentFollowed);

  print "<script type='text/javascript'>
  addTableRow('$className', '$responseCode', '$status', '$url', '$displayUrl', '$parentUrl', \"$editLink\", '$displayParentUrl', '$contentType');
  scroll();
  setNumLinksFollowed( $numLinksFollowed       );
  setNumLinksFound(    $numLinksFound          );
  setPercentFollowed(  $percentFollowed        );
  setNumMissingLinks(  $obj->{numMissingLinks} );
</script>
";
}
#----------------------------------------------------------------------
sub saveHtml {
  my ($obj) = @_;

  my ($seconds, $minutes, $hours, $monthDay, $month, $year, @dummy) = localtime();
  $year += 1900;
  $month++;
  $month    = "0$month"    if $month    < 10;
  $monthDay = "0$monthDay" if $monthDay < 10;
  $hours    = "0$hours"    if $hours    < 10;
  $minutes  = "0$minutes"  if $minutes  < 10;
  $seconds  = "0$seconds"  if $seconds  < 10;

  my $body  = $obj->getParam('body');
  my $style = $obj->getParam('style');
  my $html = "<html>
  <head>
    <title>Link Checker</title>
    <link rel='stylesheet' type='text/css' href='/css/defaultStyle.css' />
    <style type='text/css'>
      $style
    </style>
  </head>
  <body>
    <h1>" . $obj->getLang()->getString('o2.Site.LinkChecker.previousLinkCheck') . " ($year-$month-$monthDay $hours:$minutes:$seconds)</h1>
    $body
  </body>
</html>";
  $html =~ s{ \n\n+ }{\n}xmsg; # Remove empty lines

  my $dir = $config->get('o2.customerRoot') . '/var/templates/Site/LinkChecker';
  my $filename = "$dir/" . $obj->_getTemplate( $obj->getParam('siteId') );
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->mkPath($dir);
  $fileMgr->writeFile($filename, $html);

  return 1;
}
#----------------------------------------------------------------------
sub _getTemplate {
  my ($obj, $siteId) = @_;
  return "previousCheck$siteId.html";
}
#----------------------------------------------------------------------
sub _getEditLink {
  my ($obj, $url) = @_;
  require O2CMS::Publisher::UrlMapper;
  $obj->{urlMapper} = O2CMS::Publisher::UrlMapper->new() unless $obj->{urlMapper};
  my $editLinkObject;
  eval {
    $editLinkObject = $obj->{urlMapper}->resolveUrl($url);
  };
  return '' unless $editLinkObject;
  my $contentObject = $context->getObjectById( $editLinkObject->getContentObjectId() );
  my $metaClassName = $contentObject->getMetaClassName();
  my $id            = $contentObject->getId();
  my $metaName      = $contentObject->getMetaName();
  $metaClassName =~ s{ \' }{&apos;}xmsg;
  $metaClassName =~ s{ \" }{&quot;}xmsg;
  $metaName      =~ s{ \' }{&apos;}xmsg;
  $metaName      =~ s{ \" }{&quot;}xmsg;
  return "top.openObject('$metaClassName', $id, '$metaName');";
}
#----------------------------------------------------------------------
1;
