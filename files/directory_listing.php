<!DOCTYPE html>
<html>
  <head>
<?php
function set_if_blank(&$var, $value) {
  if (!isset($var)) {
    $var = $value;
  }
}

set_if_blank($PAGE_HEADING,  'Directory Contents');
set_if_blank($PAGE_TITLE,    'My Webpage!');
set_if_blank($FILE_SORT_KEY, 'mtime');
set_if_blank($SKIP_PATTERN,  '/^$/');
?>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">
<?php
if (is_file("{$_SERVER['DOCUMENT_ROOT']}/favicon.ico"))
  echo <<< EOT
    <link rel="icon" href="/favicon.ico" type="image/x-icon">

EOT;
?>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Work+Sans:100,400,700&display=swap">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css">
    <title><?php echo $PAGE_TITLE; ?></title>
    <style>
      body {
        margin: 0 auto;
        margin-left: 15px;
        margin-right: 15px;
        font-family: 'Work Sans', sans-serif;
      }
      h1 {
        text-align: center;
        font-family: 'Work Sans', sans-serif;
        font-size: 300%;
        font-weight: lighter;
      }
      .table td, .table th {
        vertical-align: middle;
      }
    </style>
  </head>
  <body>
    <br />
    <br />
    <div class="row">
      <div class="col-1 col-sm-1 col-md-2 col-lg-2 col-xl-2"></div>
      <div class="col-10 col-sm-10 col-md-8 col-lg-8 col-xl-8">
        <h1 class="text-center">
          <span class="name-text"><?php echo $PAGE_HEADING; ?></span>
        </h1>
      </div>
      <div class="col-1 col-sm-1 col-md-2 col-lg-2 col-xl-2"></div>
    </div>  <!-- .row -->

    <br />

    <div class="row">
      <div class="col-lg-1 col-xl-1"></div>
      <div class="col-12 col-sm-12 col-md-12 col-lg-10 col-xl-10">
        <p class="text-center">
          <table class="table">
            <thead>
              <tr>
<?php
$headers = array('#', 'Filename', 'Size', 'Last Modified');
foreach($headers as $h) {
    echo <<< EOT
                <th scope="col">$h</th>

EOT;
}
?>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th scope="row">1</th>
                <td><a href="../">../</td>
                <td></td>
                <td></td>
              </tr>
<?php
function human_filesize($bytes, $decimals = 2) {
    $bytes_i = intval($bytes);
    $size    = array('B','kB','MB','GB','TB','PB','EB','ZB','YB');
    $factor  = floor((strlen($bytes_i) - 1) / 3);
    return sprintf("%.{$decimals}f ", $bytes_i / pow(1024, $factor)) . @$size[$factor];
}

$stats = array( );
$files = array( );
$dirs  = array( );
foreach(glob("*") as &$fname) {
  if (preg_match($SKIP_PATTERN, $fname))
    continue;
  $stats[$fname] = stat($fname);
  if (is_dir($fname))
    array_push($dirs, $fname);
  else
    array_push($files, $fname);
}

sort($dirs);
usort($files, function($a, $b) use ($stats, $FILE_SORT_KEY) {
  return -(intval($stats[$a][$FILE_SORT_KEY]) <=> intval($stats[$b][$FILE_SORT_KEY]));
});

$all_files = array_merge($dirs, $files);

$count = 2;
foreach ($all_files as &$filename) {
    $file_stats = $stats[$filename];
    if (is_dir($filename)) {
      $filename .= '/';
      $mod_time = '';
    } else {
      $mod_time = strftime('%a %b %d %Y %r %Z', $file_stats['mtime']);
    }

    $fsize = human_filesize($file_stats['size']);
    echo <<< EOT
              <tr>
                <th scope="row">$count</th>
                <td><a href="$filename">$filename</a></td>
                <td>$fsize</td>
                <td>$mod_time</td>
              </tr>

EOT;
    $count++;
}

?>
            </tbody>
          </table>
        </p>
      </div>
      <div class="col-lg-1 col-xl-1"></div>
    </div>  <!-- .row -->
    <!-- The time is <?php echo date("Y-m-d-H:i:s"); ?> -->
  </body>
</html>
